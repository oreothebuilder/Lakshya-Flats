import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/student_profile_model.dart';
import '../models/bill_model.dart';
import '../models/complaint_model.dart';
import '../models/broadcast_notice_model.dart';
import '../models/user_role_model.dart';
import '../models/building_model.dart';
import '../models/staff_model.dart';
import '../models/admin_todo_model.dart';
import '../models/expense_bucket_model.dart';
import '../models/expense_model.dart';
import '../models/personal_todo_model.dart';
import 'email_service.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _usersRef => _db.collection('users');
  CollectionReference get _managementRef => _db.collection('management_users');
  CollectionReference get _billsRef => _db.collection('bills');
  CollectionReference get _paymentsRef => _db.collection('payments');
  CollectionReference get _messMenuRef => _db.collection('mess_menu');
  CollectionReference get _complaintsRef => _db.collection('complaints');
  CollectionReference get _noticesRef => _db.collection('broadcast_notifications');
  CollectionReference get _draftsRef => _db.collection('onboarding_drafts');
  CollectionReference get _buildingsRef => _db.collection('buildings');
  CollectionReference get _staffRef => _db.collection('staff');
  CollectionReference get _adminTodosRef => _db.collection('admin_todos');
  CollectionReference get _expenseBucketsRef => _db.collection('expense_buckets');
  CollectionReference get _expensesRef => _db.collection('expenses');

  // =========================================================================
  // 1. STUDENT PROFILES & DIRECTORY
  // =========================================================================

  Future<void> saveStudentProfile(String uid, Map<String, dynamic> data) async {
    await _usersRef.doc(uid).set({
      'role': 'student',
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Permanently delete a student profile, personal notes subcollection,
  /// and optionally associated bills from Firestore
  Future<void> deleteStudentProfile(String studentId, {bool deleteBills = true}) async {
    // 1. Delete personal notes subcollection
    try {
      final notesSnap = await _usersRef.doc(studentId).collection('personal_notes').get();
      for (final doc in notesSnap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("deleteStudentProfile personal_notes cleanup notice: $e");
    }

    // 2. Delete associated student bills if requested
    if (deleteBills) {
      try {
        final billsSnap = await _billsRef.where('studentId', isEqualTo: studentId).get();
        for (final doc in billsSnap.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("deleteStudentProfile bills cleanup notice: $e");
      }
    }

    // 3. Delete student user profile document
    await _usersRef.doc(studentId).delete();
  }

  Future<DocumentSnapshot> getStudentProfile(String uid) async {
    return await _usersRef.doc(uid).get();
  }

  Stream<DocumentSnapshot> getStudentProfileStream(String uid) {
    return _usersRef.doc(uid).snapshots();
  }

  Stream<List<StudentProfile>> getStudentsStream({String? buildingFilter}) {
    try {
      Query query = _usersRef;
      if (buildingFilter != null && buildingFilter != 'All Buildings') {
        query = query.where('building', isEqualTo: buildingFilter);
      }
      return query.snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) => StudentProfile.fromFirestore(doc)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }).handleError((err) {
        debugPrint("getStudentsStream error: $err");
        return <StudentProfile>[];
      });
    } catch (e) {
      debugPrint("getStudentsStream error: $e");
      return Stream.value(<StudentProfile>[]);
    }
  }

  // =========================================================================
  // 2. BILLS & PAYMENT COLLECTION
  // =========================================================================

  Future<DocumentReference> issueBill(Map<String, dynamic> billData) async {
    return await _billsRef.add({
      ...billData,
      'paidAmount': billData['paidAmount'] ?? 0.0,
      'status': billData['status'] ?? 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordPayment({
    required String billId,
    required double paymentAmount,
    required String paymentMode,
    String? transactionRef,
    String? notes,
  }) async {
    final billDoc = await _billsRef.doc(billId).get();
    if (!billDoc.exists) return;

    final billData = billDoc.data() as Map<String, dynamic>;
    final currentPaid = (billData['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final totalAmount = (billData['amount'] as num?)?.toDouble() ?? 0.0;
    final newPaid = currentPaid + paymentAmount;
    final newStatus = newPaid >= totalAmount ? 'Paid' : 'Pending';

    // Update bill
    final updatePayload = <String, dynamic>{
      'paidAmount': newPaid,
      'status': newStatus,
      'lastPaymentAt': FieldValue.serverTimestamp(),
      'paymentMethod': paymentMode,
      'paymentMode': paymentMode,
    };
    if (transactionRef != null && transactionRef.isNotEmpty) {
      updatePayload['transactionRef'] = transactionRef;
    }
    if (newStatus == 'Paid') {
      updatePayload['paidDate'] = DateTime.now().toIso8601String();
    }
    await _billsRef.doc(billId).update(updatePayload);

    // Record receipt
    await _paymentsRef.add({
      'billId': billId,
      'studentId': billData['studentId'],
      'studentName': billData['studentName'],
      'building': billData['building'],
      'room': billData['room'],
      'billType': billData['billType'],
      'amount': paymentAmount,
      'paymentMode': paymentMode,
      'paymentMethod': paymentMode,
      'transactionRef': transactionRef ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      'notes': notes,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  /// Permanently delete a bill by ID and any related payment receipts
  Future<void> deleteBill(String billId) async {
    try {
      await _billsRef.doc(billId).delete();
      final paymentsSnap = await _paymentsRef.where('billId', isEqualTo: billId).get();
      for (final doc in paymentsSnap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("deleteBill error: $e");
    }
  }

  /// Purge all dummy/mock bills (like INV-DEP-101) from Firestore database permanently
  Future<void> purgeDummyBills() async {
    try {
      final snaps = await _billsRef.get();
      for (final doc in snaps.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final inv = (data['invoiceNo']?.toString() ?? '').toLowerCase().trim();
        final id = doc.id.toLowerCase().trim();
        final billingMonth = (data['billingMonth']?.toString() ?? '').toLowerCase().trim();
        if (inv == 'inv-dep-101' ||
            inv.startsWith('inv-hst-10') ||
            inv.startsWith('inv-util-30') ||
            id.startsWith('fb-') ||
            billingMonth == 'admission deposit') {
          await doc.reference.delete();
          debugPrint("Purged dummy bill: ${doc.id} ($inv)");
        }
      }
    } catch (e) {
      debugPrint("purgeDummyBills error: $e");
    }
  }

  Stream<List<BillModel>> getBillsStream({String? buildingFilter, String? statusFilter}) {
    try {
      Query query = _billsRef;
      if (buildingFilter != null && buildingFilter != 'All Buildings') {
        query = query.where('building', isEqualTo: buildingFilter);
      }
      if (statusFilter != null && statusFilter != 'All Dues') {
        query = query.where('status', isEqualTo: statusFilter);
      }
      return query.snapshots().map((snapshot) {
        final list = <BillModel>[];
        for (final doc in snapshot.docs) {
          final b = BillModel.fromFirestore(doc);
          final inv = b.invoiceNo.toLowerCase().trim();
          final billingMonth = b.billingMonth.toLowerCase().trim();
          final id = b.id.toLowerCase().trim();
          if (inv == 'inv-dep-101' ||
              inv.startsWith('inv-hst-10') ||
              inv.startsWith('inv-util-30') ||
              id.startsWith('fb-') ||
              billingMonth == 'admission deposit') {
            doc.reference.delete().catchError((_) {});
            continue;
          }
          list.add(b);
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }).handleError((err) {
        debugPrint("Firestore getBillsStream error: $err");
        return <BillModel>[];
      });
    } catch (e) {
      debugPrint("Firestore not ready: $e");
      return Stream.value(<BillModel>[]);
    }
  }

  Stream<List<BillModel>> getStudentBillsStream(String studentId, {String? phone}) {
    try {
      if (studentId.isEmpty && (phone == null || phone.isEmpty)) {
        return Stream.value(<BillModel>[]);
      }
      return _billsRef.snapshots().map((snapshot) {
        final list = <BillModel>[];
        for (final doc in snapshot.docs) {
          final b = BillModel.fromFirestore(doc);
          final inv = b.invoiceNo.toLowerCase().trim();
          final billingMonth = b.billingMonth.toLowerCase().trim();
          final id = b.id.toLowerCase().trim();
          if (inv == 'inv-dep-101' ||
              inv.startsWith('inv-hst-10') ||
              inv.startsWith('inv-util-30') ||
              id.startsWith('fb-') ||
              billingMonth == 'admission deposit') {
            doc.reference.delete().catchError((_) {});
            continue;
          }
          final matchStudent = studentId.isNotEmpty && (b.studentId == studentId || b.id == studentId);
          final matchPhone = phone != null && phone.isNotEmpty && b.phone.isNotEmpty && b.phone == phone;
          if (matchStudent || matchPhone) {
            list.add(b);
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }).handleError((err) {
        debugPrint("getStudentBillsStream error: $err");
        return <BillModel>[];
      });
    } catch (e) {
      debugPrint("getStudentBillsStream error: $e");
      return Stream.value(<BillModel>[]);
    }
  }

  // =========================================================================
  // 3. COMPLAINTS & TICKETS
  // =========================================================================

  Future<DocumentReference> addComplaint(Map<String, dynamic> complaintData) async {
    final status = ComplaintModel.normalizeStatus(complaintData['status']?.toString());
    return await _complaintsRef.add({
      ...complaintData,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status,
    });
  }

  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? remarks,
    ComplaintModel? complaint,
  }) async {
    final normalizedStatus = ComplaintModel.normalizeStatus(status);
    final updateData = <String, dynamic>{
      'status': normalizedStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (remarks != null && remarks.trim().isNotEmpty) {
      updateData['adminRemarks'] = remarks.trim();
    }
    if (normalizedStatus == ComplaintModel.statusResolved) {
      updateData['resolvedAt'] = FieldValue.serverTimestamp();
    } else {
      updateData['resolvedAt'] = null;
    }

    await _complaintsRef.doc(complaintId).update(updateData);

    // If status is 'Under execution' or 'Resolved', dispatch student notification!
    if (normalizedStatus == ComplaintModel.statusUnderExecution ||
        normalizedStatus == ComplaintModel.statusResolved) {
      try {
        ComplaintModel ticket;
        if (complaint != null) {
          ticket = complaint;
        } else {
          final doc = await _complaintsRef.doc(complaintId).get();
          ticket = ComplaintModel.fromFirestore(doc);
        }

        await _dispatchTicketStatusNotification(
          ticket: ticket,
          newStatus: normalizedStatus,
          remarks: remarks?.trim(),
        );
      } catch (e) {
        debugPrint("Error dispatching ticket notification: $e");
      }
    }
  }

  /// Sends both an in-app student notification and an email notification (if available)
  /// when a ticket transitions to 'Under execution' or 'Resolved'.
  Future<void> _dispatchTicketStatusNotification({
    required ComplaintModel ticket,
    required String newStatus,
    String? remarks,
  }) async {
    final isResolved = newStatus == ComplaintModel.statusResolved;
    final roomStr = ticket.room.isNotEmpty ? " (Room ${ticket.room})" : "";
    final buildingStr = ticket.building.isNotEmpty ? " • ${ticket.building}" : "";

    final title = isResolved
        ? "Ticket Resolved: ${ticket.title}"
        : "Ticket Under Execution: ${ticket.title}";

    final message = isResolved
        ? "Your maintenance ticket for \"${ticket.title}\" (${ticket.category}$roomStr$buildingStr) has been marked as resolved by administration.${remarks != null && remarks.isNotEmpty ? '\n\nResolution Note: $remarks' : ''}"
        : "Your maintenance ticket for \"${ticket.title}\" (${ticket.category}$roomStr$buildingStr) is now under execution by our maintenance team.${remarks != null && remarks.isNotEmpty ? '\n\nAdmin Note: $remarks' : ''}";

    // 1. Dispatch In-App Notification
    await sendStudentNotification(
      studentId: ticket.studentId,
      studentName: ticket.studentName,
      title: title,
      message: message,
      category: "Maintenance",
      targetBuilding: ticket.building,
      targetRoom: ticket.room,
      metadata: {
        'ticketId': ticket.id,
        'status': newStatus,
        'category': ticket.category,
        'remarks': remarks ?? '',
      },
    );

    // 2. Fetch student email if missing from ticket
    String targetEmail = ticket.studentEmail.trim();
    if (targetEmail.isEmpty && ticket.studentId.isNotEmpty) {
      try {
        final userDoc = await _usersRef.doc(ticket.studentId).get();
        if (userDoc.exists) {
          final uData = userDoc.data() as Map<String, dynamic>?;
          targetEmail = (uData?['email'] ?? '').toString().trim();
        }
      } catch (e) {
        debugPrint("Could not fetch student email for ticket notification: $e");
      }
    }

    // 3. Dispatch Email Notification if valid email found
    if (targetEmail.isNotEmpty && targetEmail.contains('@')) {
      try {
        EmailService().sendTicketStatusEmail(
          studentEmail: targetEmail,
          studentName: ticket.studentName,
          ticketId: ticket.id,
          ticketTitle: ticket.title,
          category: ticket.category,
          status: newStatus,
          building: ticket.building,
          room: ticket.room,
          remarks: remarks,
        );
      } catch (e) {
        debugPrint("Email delivery notice for ticket update: $e");
      }
    }
  }

  Stream<List<ComplaintModel>> getComplaintsStream({String? statusFilter, String? buildingFilter}) {
    try {
      Query query = _complaintsRef;
      if (buildingFilter != null && buildingFilter != 'All Buildings' && buildingFilter.isNotEmpty) {
        query = query.where('building', isEqualTo: buildingFilter);
      }
      return query.snapshots().map((snapshot) {
        var list = snapshot.docs.map((doc) => ComplaintModel.fromFirestore(doc)).toList();
        if (statusFilter != null && statusFilter != 'All' && statusFilter.isNotEmpty) {
          final target = ComplaintModel.normalizeStatus(statusFilter);
          list = list.where((c) => c.status == target).toList();
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }).handleError((err) {
        debugPrint("getComplaintsStream error: $err");
        return <ComplaintModel>[];
      });
    } catch (e) {
      debugPrint("getComplaintsStream catch error: $e");
      return Stream.value(<ComplaintModel>[]);
    }
  }

  Stream<List<ComplaintModel>> getStudentComplaintsStream(String studentId, {String? studentName}) {
    try {
      if (studentId.isEmpty && (studentName == null || studentName.isEmpty)) {
        return Stream.value(<ComplaintModel>[]);
      }
      return _complaintsRef.snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((doc) => ComplaintModel.fromFirestore(doc))
            .where((c) {
              if (studentId.isNotEmpty && (c.studentId == studentId || c.id == studentId)) return true;
              if (studentName != null && studentName.isNotEmpty && c.studentName.toLowerCase() == studentName.toLowerCase()) return true;
              return false;
            })
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }).handleError((err) {
        debugPrint("getStudentComplaintsStream error: $err");
        return <ComplaintModel>[];
      });
    } catch (e) {
      debugPrint("getStudentComplaintsStream catch error: $e");
      return Stream.value(<ComplaintModel>[]);
    }
  }

  // =========================================================================
  // 4. BROADCAST NOTIFICATIONS
  // =========================================================================

  Future<DocumentReference> addNotification(Map<String, dynamic> noticeData) async {
    return await _noticesRef.add({
      ...noticeData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sends a targeted notification to a specific student
  Future<void> sendStudentNotification({
    required String studentId,
    required String title,
    required String message,
    String category = 'Payment',
    String? targetBuilding,
    String? targetRoom,
    String? studentName,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'message': message,
      'category': category,
      'targetAudience': 'Individual Student',
      'targetStudentId': studentId,
      'targetStudentName': studentName ?? '',
      'targetBuilding': targetBuilding,
      'targetRoom': targetRoom,
      'priority': 'High',
      'senderName': 'Hostel Administration',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };
    if (metadata != null) {
      payload['metadata'] = metadata;
    }

    // 1. Add to general broadcast/notifications collection
    await _noticesRef.add(payload);

    // 2. Also write to student's specific subcollection: users/{studentId}/notifications
    if (studentId.isNotEmpty) {
      try {
        await _usersRef.doc(studentId).collection('notifications').add(payload);
      } catch (e) {
        debugPrint("Notice writing to student subcollection error: $e");
      }
    }
  }

  Stream<List<BroadcastNoticeModel>> getNotificationsStream() {
    return _noticesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BroadcastNoticeModel.fromFirestore(doc)).toList();
    });
  }

  /// Live stream of notifications for a specific student
  Stream<List<Map<String, dynamic>>> getStudentNotificationsStream(String studentId) {
    if (studentId.isEmpty) {
      return Stream.value(<Map<String, dynamic>>[]);
    }
    return _usersRef
        .doc(studentId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    }).handleError((e) {
      debugPrint("getStudentNotificationsStream error: $e");
      return <Map<String, dynamic>>[];
    });
  }

  /// Mark single notification as read
  Future<void> markNotificationAsRead(String studentId, String notificationId) async {
    if (studentId.isEmpty || notificationId.isEmpty) return;
    try {
      await _usersRef
          .doc(studentId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint("markNotificationAsRead error: $e");
    }
  }

  /// Mark all notifications as read for a student
  Future<void> markAllNotificationsAsRead(String studentId) async {
    if (studentId.isEmpty) return;
    try {
      final snap = await _usersRef
          .doc(studentId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("markAllNotificationsAsRead error: $e");
    }
  }

  // =========================================================================
  // 5. ONBOARDING DRAFTS PERSISTENCE
  // =========================================================================

  Future<void> saveDraftToCloud(String draftId, Map<String, dynamic> draftData) async {
    await _draftsRef.doc(draftId).set({
      ...draftData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDraftFromCloud(String draftId) async {
    try {
      await _draftsRef.doc(draftId).delete();
    } catch (e) {
      debugPrint("deleteDraftFromCloud error: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getDraftsStream() {
    try {
      return _draftsRef.snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        return list;
      }).handleError((err) {
        debugPrint("getDraftsStream error: $err");
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      debugPrint("getDraftsStream error: $e");
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  // =========================================================================
  // 6. MANAGEMENT USERS & MESS MENU
  // =========================================================================

  Future<void> saveManagementUser(String uid, Map<String, dynamic> data) async {
    // If setting role as admin, enforce the rule: maximum 2 admins allowed
    if (data['role'] == 'admin') {
      final adminDocs = await _managementRef.where('role', isEqualTo: 'admin').get();
      final existingAdminUids = adminDocs.docs.map((d) => d.id).toSet();
      if (!existingAdminUids.contains(uid) && existingAdminUids.length >= 2) {
        throw Exception("Maximum limit of 2 Administrators has already been reached.");
      }
    }

    await _managementRef.doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getManagementUser(String uid) async {
    return await _managementRef.doc(uid).get();
  }

  /// Resolve an AppUser by checking staff/admin collection first, then student users collection
  Future<AppUser?> getAppUser(String uid, {String? emailHint}) async {
    try {
      // 1. Check management_users collection
      final mgmtDoc = await _managementRef.doc(uid).get();
      if (mgmtDoc.exists && mgmtDoc.data() != null) {
        return AppUser.fromFirestore(
          uid: uid,
          data: mgmtDoc.data() as Map<String, dynamic>,
          fallbackRole: AppRole.management,
        );
      }

      // Check by email in management_users if document was saved with a custom ID
      if (emailHint != null && emailHint.isNotEmpty) {
        final query = await _managementRef.where('email', isEqualTo: emailHint.toLowerCase().trim()).limit(1).get();
        if (query.docs.isNotEmpty) {
          return AppUser.fromFirestore(
            uid: uid,
            data: query.docs.first.data() as Map<String, dynamic>,
            fallbackRole: AppRole.management,
          );
        }
      }

      // 2. Check users (students) collection by uid
      final userDoc = await _usersRef.doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return AppUser.fromFirestore(
          uid: uid,
          data: userDoc.data() as Map<String, dynamic>,
          fallbackRole: AppRole.student,
        );
      }

      // Check by email in users collection
      if (emailHint != null && emailHint.isNotEmpty) {
        final query = await _usersRef.where('email', isEqualTo: emailHint.toLowerCase().trim()).limit(1).get();
        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          return AppUser.fromFirestore(
            uid: uid,
            data: doc.data() as Map<String, dynamic>,
            fallbackRole: AppRole.student,
          );
        }
      }

      // 3. Fallback: If email is primary admin (sudhansu1906), auto-bootstrap admin profile
      if (emailHint != null && isPrimaryAdminEmail(emailHint)) {
        await bootstrapPrimaryAdmin(uid, emailHint);
        return AppUser(
          uid: uid,
          email: emailHint,
          fullName: "Sudhanshu (Super Admin)",
          role: AppRole.admin,
        );
      }

      return null;
    } catch (e) {
      debugPrint("getAppUser error: $e");
      return null;
    }
  }

  /// Checks if given email or identifier is the primary admin
  bool isPrimaryAdminEmail(String identifier) {
    final clean = identifier.toLowerCase().trim();
    return clean == "sudhansu1906@gmail.com" ||
        clean == "sudhansu1906" ||
        clean.startsWith("sudhansu1906@");
  }

  /// Bootstrap the primary admin account in Firestore
  Future<void> bootstrapPrimaryAdmin(String uid, String email) async {
    try {
      await _managementRef.doc(uid).set({
        'uid': uid,
        'email': email.toLowerCase().trim(),
        'fullName': 'Sudhanshu',
        'role': 'admin',
        'status': 'Active',
        'isPrimaryAdmin': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("bootstrapPrimaryAdmin error: $e");
    }
  }

  /// Find student profile by Registration Number or Email
  Future<Map<String, dynamic>?> findStudentByRegNoOrEmail(String identifier) async {
    final clean = identifier.trim();
    if (clean.isEmpty) return null;

    try {
      // 1. Check registration number
      final regQuery = await _usersRef.where('registrationNumber', isEqualTo: clean).limit(1).get();
      if (regQuery.docs.isNotEmpty) {
        return {
          'id': regQuery.docs.first.id,
          ...regQuery.docs.first.data() as Map<String, dynamic>,
        };
      }

      // Also check case-insensitively / fallback field 'regNo'
      final regNoQuery = await _usersRef.where('regNo', isEqualTo: clean).limit(1).get();
      if (regNoQuery.docs.isNotEmpty) {
        return {
          'id': regNoQuery.docs.first.id,
          ...regNoQuery.docs.first.data() as Map<String, dynamic>,
        };
      }

      // 2. Check email
      final emailQuery = await _usersRef.where('email', isEqualTo: clean.toLowerCase()).limit(1).get();
      if (emailQuery.docs.isNotEmpty) {
        return {
          'id': emailQuery.docs.first.id,
          ...emailQuery.docs.first.data() as Map<String, dynamic>,
        };
      }
    } catch (e) {
      debugPrint("findStudentByRegNoOrEmail error: $e");
    }
    return null;
  }

  Future<void> updateMessMenu(String day, Map<String, dynamic> dayMenuData) async {
    await _messMenuRef.doc(day.toLowerCase()).set({
      ...dayMenuData,
      'day': day,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getMessMenuStream() {
    return _messMenuRef.snapshots();
  }

  // =========================================================================
  // 7. STUDENT PROFILE EXTENSIONS (NOTES, AMENITIES, EMERGENCY, DOCS)
  // =========================================================================

  /// Send a personal note/message to a student (visible in chat by admin & student)
  Future<DocumentReference> sendPersonalNote(String studentId, Map<String, dynamic> noteData) async {
    final noteDoc = await _usersRef.doc(studentId).collection('personal_notes').add({
      ...noteData,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Also append to main student record notes array for summary & quick lookup
    final noteText = noteData['text']?.toString() ?? '';
    if (noteText.isNotEmpty) {
      try {
        await _usersRef.doc(studentId).update({
          'notes': FieldValue.arrayUnion([noteText]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Error updating student notes array: $e");
      }
    }

    return noteDoc;
  }

  /// Stream of personal notes between admin and student ordered chronologically
  Stream<QuerySnapshot> getPersonalNotesStream(String studentId) {
    return _usersRef
        .doc(studentId)
        .collection('personal_notes')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Update room amenities / inventory provided to student
  Future<void> updateStudentAmenities(String studentId, List<String> inventory) async {
    await _usersRef.doc(studentId).set({
      'inventory': inventory,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update guardian / emergency contact details
  Future<void> updateStudentEmergencyContact(
    String studentId, {
    required String name,
    required String relationship,
    required String phone,
  }) async {
    await _usersRef.doc(studentId).set({
      'guardianName': name,
      'guardianRelationship': relationship,
      'guardianPhone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update document URLs (college ID, govt ID, rent agreement, etc.)
  Future<void> updateStudentDocuments(String studentId, Map<String, dynamic> docData) async {
    await _usersRef.doc(studentId).set({
      ...docData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update custom student profile fields (bed number, phone, email, etc.)
  Future<void> updateStudentProfileFields(String studentId, Map<String, dynamic> fields) async {
    await _usersRef.doc(studentId).set({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =========================================================================
  // 8. BUILDINGS MANAGEMENT & OCCUPANCY
  // =========================================================================

  /// Stream of all buildings. If the collection is empty, returns the default catalog
  /// and kicks off background seeding so Firestore is populated seamlessly.
  Stream<List<BuildingModel>> getBuildingsStream() {
    return _buildingsRef.snapshots().asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Automatically seed default buildings if Firestore collection has no documents
        try {
          await seedDefaultBuildings();
        } catch (e) {
          debugPrint("seedDefaultBuildings error: $e");
        }
        return BuildingModel.defaultBuildings;
      }
      final list = snapshot.docs.map((doc) => BuildingModel.fromFirestore(doc)).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    }).handleError((err) {
      debugPrint("getBuildingsStream error: $err");
      return BuildingModel.defaultBuildings;
    });
  }

  /// Explicitly seed the 8 default properties if the collection has no documents
  Future<void> seedDefaultBuildings() async {
    try {
      final existing = await _buildingsRef.limit(1).get();
      if (existing.docs.isNotEmpty) return;

      final batch = _db.batch();
      for (final b in BuildingModel.defaultBuildings) {
        final doc = _buildingsRef.doc(b.id);
        batch.set(doc, b.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint("Default 8 buildings seeded successfully into Firestore.");
    } catch (e) {
      debugPrint("seedDefaultBuildings exception: $e");
    }
  }

  /// Add a new building
  Future<DocumentReference> addBuilding(BuildingModel building) async {
    return await _buildingsRef.add({
      ...building.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing building
  Future<void> updateBuilding(String id, Map<String, dynamic> data) async {
    await _buildingsRef.doc(id).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Delete a building
  Future<void> deleteBuilding(String id) async {
    await _buildingsRef.doc(id).delete();
  }

  // =========================================================================
  // 9. STAFF MANAGEMENT & ONBOARDING
  // =========================================================================

  /// Stream of all staff members. Strictly returns database records without dummy seeding.
  Stream<List<StaffModel>> getStaffStream() {
    return _staffRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => StaffModel.fromFirestore(doc)).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    }).handleError((err) {
      debugPrint("getStaffStream error: $err");
      return <StaffModel>[];
    });
  }

  /// No-op: Dummy seeding is explicitly disabled. Staff profiles are created manually by admin.
  Future<void> seedDefaultStaff() async {
    // Disabled: Dummy data is not seeded.
  }

  /// Generate next sequential Staff ID like STF-101, STF-102...
  Future<String> generateNextStaffId() async {
    try {
      final snapshot = await _staffRef.get();
      int highest = 100;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final sid = data['staffId']?.toString() ?? '';
        final match = RegExp(r'STF-(\d+)').firstMatch(sid);
        if (match != null) {
          final num = int.tryParse(match.group(1)!) ?? 0;
          if (num > highest) highest = num;
        }
      }
      return 'STF-${highest + 1}';
    } catch (e) {
      return 'STF-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  /// Onboard a new staff member
  Future<void> onboardStaff(StaffModel staff) async {
    await _staffRef.doc(staff.id).set({
      ...staff.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Also register in management_users if email is present
    if (staff.email.isNotEmpty) {
      try {
        await _managementRef.doc(staff.id).set({
          'uid': staff.id,
          'email': staff.email.toLowerCase().trim(),
          'fullName': staff.name,
          'name': staff.name,
          'phone': staff.phone,
          'role': 'management',
          'designation': staff.designation,
          'staffId': staff.staffId,
          'assignedBuildings': staff.assignedBuildings,
          'status': staff.status,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("onboardStaff sync to management_users notice: $e");
      }
    }
  }

  /// Update existing staff record
  Future<void> updateStaff(String id, Map<String, dynamic> data) async {
    await _staffRef.doc(id).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Sync to management_users
    try {
      await _managementRef.doc(id).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("updateStaff sync to management_users notice: $e");
    }
  }

  /// Delete a staff member
  Future<void> deleteStaff(String id) async {
    await _staffRef.doc(id).delete();
    try {
      await _managementRef.doc(id).delete();
    } catch (e) {
      debugPrint("deleteStaff cleanup notice: $e");
    }
  }

  // =========================================================================
  // 10. ADMIN TO-DO LIST
  // =========================================================================

  /// Stream of all admin todos
  Stream<List<AdminTodoModel>> getAdminTodosStream() {
    return _adminTodosRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => AdminTodoModel.fromFirestore(doc)).toList();
      // Sort: incomplete first, then by priority / creation date
      list.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    }).handleError((err) {
      debugPrint("getAdminTodosStream error: $err");
      return <AdminTodoModel>[];
    });
  }

  /// Seed default admin todos if empty (deprecated)
  Future<void> seedDefaultAdminTodos() async {
    // Deprecated: automatic dummy seeding removed to ensure clean live data
  }

  /// Add a new admin todo
  Future<DocumentReference> addAdminTodo(AdminTodoModel todo) async {
    return await _adminTodosRef.add({
      ...todo.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle completion of admin todo
  Future<void> toggleAdminTodo(String id, bool isCompleted) async {
    await _adminTodosRef.doc(id).update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update admin todo
  Future<void> updateAdminTodo(String id, Map<String, dynamic> data) async {
    await _adminTodosRef.doc(id).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Delete admin todo
  Future<void> deleteAdminTodo(String id) async {
    await _adminTodosRef.doc(id).delete();
  }

  // =========================================================================
  // 11. EXPENSE TRACKER & BUCKETS
  // =========================================================================

  /// Stream of all expense categories/buckets
  Stream<List<ExpenseBucketModel>> getExpenseBucketsStream() {
    return _expenseBucketsRef.snapshots().asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        try {
          await seedDefaultExpenseBuckets();
        } catch (e) {
          debugPrint("seedDefaultExpenseBuckets error: $e");
        }
        return ExpenseBucketModel.defaultBuckets;
      }

      final list = snapshot.docs.map((doc) => ExpenseBucketModel.fromFirestore(doc)).toList();

      // Sort: keep default buckets ordered by predefined list, custom ones by creation date
      final defaultIds = ExpenseBucketModel.defaultBuckets.map((b) => b.id).toList();
      list.sort((a, b) {
        final aIdx = defaultIds.indexOf(a.id);
        final bIdx = defaultIds.indexOf(b.id);
        if (aIdx != -1 && bIdx != -1) {
          return aIdx.compareTo(bIdx);
        } else if (aIdx != -1) {
          return -1;
        } else if (bIdx != -1) {
          return 1;
        }
        return a.createdAt.compareTo(b.createdAt);
      });

      return list;
    }).handleError((err) {
      debugPrint("getExpenseBucketsStream error: $err");
      return ExpenseBucketModel.defaultBuckets;
    });
  }

  /// Seed initial 6 default buckets requested by user
  Future<void> seedDefaultExpenseBuckets() async {
    try {
      final existing = await _expenseBucketsRef.limit(1).get();
      if (existing.docs.isNotEmpty) return;

      final batch = _db.batch();
      for (final bucket in ExpenseBucketModel.defaultBuckets) {
        final doc = _expenseBucketsRef.doc(bucket.id);
        batch.set(doc, bucket.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint("Default expense buckets seeded successfully.");
    } catch (e) {
      debugPrint("seedDefaultExpenseBuckets exception: $e");
    }
  }

  /// Add a new expense bucket
  Future<void> addExpenseBucket(ExpenseBucketModel bucket) async {
    await _expenseBucketsRef.doc(bucket.id).set(bucket.toMap());
  }

  /// Update an existing expense bucket
  Future<void> updateExpenseBucket(
    String id,
    Map<String, dynamic> data, {
    String? oldName,
    String? newName,
  }) async {
    await _expenseBucketsRef.doc(id).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // If bucket name changed, update existing transactions with this bucketId
    if (newName != null && oldName != null && newName != oldName) {
      try {
        final snap = await _expensesRef.where('bucketId', isEqualTo: id).get();
        if (snap.docs.isNotEmpty) {
          final batch = _db.batch();
          for (final doc in snap.docs) {
            batch.update(doc.reference, {
              'bucketName': newName,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint("Syncing updated bucket name to expenses error: $e");
      }
    }
  }

  /// Delete an expense bucket and safely reassign its expenses to 'others'
  Future<void> deleteExpenseBucket(
    String id, {
    String fallbackBucketId = 'bucket_others',
    String fallbackBucketName = 'others',
  }) async {
    // 1. Delete bucket document
    await _expenseBucketsRef.doc(id).delete();

    // 2. Safely reassign transactions associated with this bucket to fallback
    try {
      final snap = await _expensesRef.where('bucketId', isEqualTo: id).get();
      if (snap.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in snap.docs) {
          batch.update(doc.reference, {
            'bucketId': fallbackBucketId,
            'bucketName': fallbackBucketName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Reassigning deleted bucket expenses error: $e");
    }
  }

  /// Stream of all expenses sorted by date descending
  Stream<List<ExpenseModel>> getExpensesStream() {
    return _expensesRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }).handleError((err) {
      debugPrint("getExpensesStream error: $err");
      return <ExpenseModel>[];
    });
  }

  /// Add a new expense transaction
  Future<DocumentReference> addExpense(ExpenseModel expense) async {
    return await _expensesRef.add({
      ...expense.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing expense transaction
  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    await _expensesRef.doc(id).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Delete an expense transaction
  Future<void> deleteExpense(String id) async {
    await _expensesRef.doc(id).delete();
  }

  // =========================================================================
  // 12. PERSONAL ADMIN TO-DO LIST (Scoped to Admin UID)
  // =========================================================================

  CollectionReference _adminPersonalTodosRef(String adminUid) {
    final uid = adminUid.isNotEmpty ? adminUid : 'default_admin';
    return _usersRef.doc(uid).collection('personal_todos');
  }

  /// Real-time stream of the admin's personal todos
  Stream<List<PersonalTodoModel>> getPersonalTodosStream(String adminUid) {
    return _adminPersonalTodosRef(adminUid).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => PersonalTodoModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    }).handleError((err) {
      debugPrint("getPersonalTodosStream error: $err");
      return <PersonalTodoModel>[];
    });
  }

  /// Add a new personal todo
  Future<DocumentReference> addPersonalTodo(
    String adminUid,
    String title, {
    DateTime? dueDate,
  }) async {
    return await _adminPersonalTodosRef(adminUid).add({
      'title': title,
      'isCompleted': false,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    });
  }

  /// Toggle task completion status
  Future<void> togglePersonalTodo(String adminUid, String todoId, bool isCompleted) async {
    await _adminPersonalTodosRef(adminUid).doc(todoId).update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a personal todo
  Future<void> deletePersonalTodo(String adminUid, String todoId) async {
    await _adminPersonalTodosRef(adminUid).doc(todoId).delete();
  }

  /// Clear all completed personal todos in batch
  Future<void> clearCompletedPersonalTodos(String adminUid) async {
    final snap = await _adminPersonalTodosRef(adminUid).where('isCompleted', isEqualTo: true).get();
    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
