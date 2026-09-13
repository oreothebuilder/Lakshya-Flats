import 'package:cloud_firestore/cloud_firestore.dart';

class BillModel {
  final String id;
  final String studentId;
  final String studentName;
  final String building;
  final String room;
  final String billType;
  final double amount;
  final double paidAmount;
  final String status; // "Paid", "Pending", "Defaulter"
  final DateTime dueDate;
  final String invoiceNo;
  final DateTime createdAt;
  final String phone;
  final String avatarUrl;
  final String billingMonth;
  final String? paymentMethod;
  final String? transactionRef;
  final String? paidDate;
  final String? studentEmail;
  final String? proofUrl;
  final String? paymentRemarks;
  final String? adminRemarks;
  final DateTime? submittedAt;

  BillModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.building,
    required this.room,
    required this.billType,
    required this.amount,
    this.paidAmount = 0.0,
    required this.status,
    required this.dueDate,
    required this.invoiceNo,
    DateTime? createdAt,
    this.phone = '',
    this.avatarUrl = '',
    this.billingMonth = '',
    this.paymentMethod,
    this.transactionRef,
    this.paidDate,
    this.studentEmail,
    this.proofUrl,
    this.paymentRemarks,
    this.adminRemarks,
    this.submittedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get balance => (amount - paidAmount).clamp(0.0, amount);
  bool get isPaid => (paidAmount >= amount && amount > 0) || status.toLowerCase() == 'paid';
  
  String? get utrNumber => transactionRef;
  
  bool get isPendingVerification {
    if (isPaid || status.toLowerCase() == 'paid') return false;
    final s = status.toLowerCase();
    return s == 'pending verification' || (transactionRef != null && transactionRef!.trim().isNotEmpty);
  }

  bool get isDefaulter {
    if (isPaid) return false;
    if (status.toLowerCase() == 'defaulter') return true;
    final now = DateTime.now();
    // Overdue if today is past the end of the dueDate
    final endOfDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59);
    return now.isAfter(endOfDueDate);
  }

  String get computedStatus {
    if (isPaid) return 'Paid';
    if (isPendingVerification) return 'Pending Verification';
    if (isDefaulter) return 'Defaulter';
    return 'Pending';
  }

  int get daysOverdue {
    if (isPaid) return 0;
    final now = DateTime.now();
    final endOfDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59);
    if (now.isAfter(endOfDueDate)) {
      return now.difference(endOfDueDate).inDays + 1;
    }
    return 0;
  }

  String get initials {
    if (studentName.trim().isEmpty) return "ST";
    final parts = studentName.trim().split(" ");
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return studentName.trim().substring(0, studentName.trim().length >= 2 ? 2 : 1).toUpperCase();
  }

  bool get isBankTransfer => (paymentMethod ?? '').toLowerCase().contains('bank');
  bool get isUpi => (paymentMethod ?? '').toLowerCase().contains('upi');
  bool get isCash => (paymentMethod ?? '').toLowerCase().contains('cash');
  bool get hasProofScreenshot => proofUrl != null && proofUrl!.isNotEmpty;

  // Helper to categorize bill into user's requested 2 types:
  // 1. Hostel bill & security deposit
  // 2. Utility bills
  bool get isHostelBillOrSecurityDeposit {
    final lower = '$billType $billingMonth'.toLowerCase();
    return lower.contains('hostel') ||
        lower.contains('deposit') ||
        lower.contains('rent') ||
        lower.contains('security') ||
        lower.contains('installment');
  }

  bool get isUtilityBill {
    final lower = '$billType $billingMonth'.toLowerCase();
    return lower.contains('electricity') ||
        lower.contains('utility') ||
        lower.contains('wifi') ||
        lower.contains('water') ||
        lower.contains('mess') ||
        lower.contains('cleaning') ||
        lower.contains('maintenance') ||
        lower.contains('power');
  }

  factory BillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedDueDate = DateTime.now();
    if (data['dueDate'] != null) {
      if (data['dueDate'] is Timestamp) {
        parsedDueDate = (data['dueDate'] as Timestamp).toDate();
      } else {
        parsedDueDate = DateTime.tryParse(data['dueDate'].toString()) ?? DateTime.now();
      }
    }

    DateTime parsedCreatedAt = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
      } else {
        parsedCreatedAt = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
      }
    }

    DateTime? parsedSubmittedAt;
    if (data['submittedAt'] != null) {
      if (data['submittedAt'] is Timestamp) {
        parsedSubmittedAt = (data['submittedAt'] as Timestamp).toDate();
      } else {
        parsedSubmittedAt = DateTime.tryParse(data['submittedAt'].toString());
      }
    }

    return BillModel(
      id: doc.id,
      studentId: data['studentId']?.toString() ?? '',
      studentName: data['studentName']?.toString() ?? '',
      building: data['building']?.toString() ?? 'Lakshya',
      room: data['room']?.toString() ?? '',
      billType: data['billType']?.toString() ?? 'Hostel Rent',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? 'Pending',
      dueDate: parsedDueDate,
      invoiceNo: data['invoiceNo']?.toString() ?? 'INV-${doc.id.length >= 6 ? doc.id.substring(0, 6) : doc.id}',
      createdAt: parsedCreatedAt,
      phone: data['phone']?.toString() ?? data['studentPhone']?.toString() ?? '',
      avatarUrl: data['avatarUrl']?.toString() ?? data['photoUrl']?.toString() ?? '',
      billingMonth: data['billingMonth']?.toString() ?? '',
      paymentMethod: data['paymentMethod']?.toString() ?? data['paymentMode']?.toString(),
      transactionRef: data['transactionRef']?.toString() ?? data['utrNumber']?.toString(),
      paidDate: data['paidDate']?.toString(),
      studentEmail: data['studentEmail']?.toString(),
      proofUrl: data['proofUrl']?.toString() ?? data['receiptUrl']?.toString(),
      paymentRemarks: data['paymentRemarks']?.toString() ?? data['remarks']?.toString(),
      adminRemarks: data['adminRemarks']?.toString(),
      submittedAt: parsedSubmittedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'building': building,
      'room': room,
      'billType': billType,
      'amount': amount,
      'paidAmount': paidAmount,
      'status': status,
      'dueDate': Timestamp.fromDate(dueDate),
      'invoiceNo': invoiceNo,
      'createdAt': Timestamp.fromDate(createdAt),
      'phone': phone,
      'avatarUrl': avatarUrl,
      'billingMonth': billingMonth,
      'paymentMethod': paymentMethod,
      'paymentMode': paymentMethod,
      'transactionRef': transactionRef,
      'utrNumber': transactionRef,
      'paidDate': paidDate,
      'studentEmail': studentEmail,
      'proofUrl': proofUrl,
      'paymentRemarks': paymentRemarks,
      'adminRemarks': adminRemarks,
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
    };
  }

  BillModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? building,
    String? room,
    String? billType,
    double? amount,
    double? paidAmount,
    String? status,
    DateTime? dueDate,
    String? invoiceNo,
    DateTime? createdAt,
    String? phone,
    String? avatarUrl,
    String? billingMonth,
    String? paymentMethod,
    String? transactionRef,
    String? paidDate,
    String? studentEmail,
    String? proofUrl,
    String? paymentRemarks,
    String? adminRemarks,
    DateTime? submittedAt,
  }) {
    return BillModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      building: building ?? this.building,
      room: room ?? this.room,
      billType: billType ?? this.billType,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      billingMonth: billingMonth ?? this.billingMonth,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionRef: transactionRef ?? this.transactionRef,
      paidDate: paidDate ?? this.paidDate,
      studentEmail: studentEmail ?? this.studentEmail,
      proofUrl: proofUrl ?? this.proofUrl,
      paymentRemarks: paymentRemarks ?? this.paymentRemarks,
      adminRemarks: adminRemarks ?? this.adminRemarks,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}
