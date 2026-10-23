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
  final String? paymentStatus;
  final String? securityDepositStatus;
  final DateTime? returnedAt;
  final String? refundMode;
  final String? refundRef;
  final String? refundRemarks;
  final String? receiptNo;
  final DateTime? receiptIssuedAt;
  final bool rejectionDismissed;
  final DateTime? rejectedAt;
  final String? bed;
  final String? regNo;
  final String? studentDocId;
  final double _storedDefaulterAmount;
  final String? payeeAccountName;
  final String? payeeBankName;
  final String? payeeAccountNumber;
  final String? payeeIfscCode;
  final String? payeeUpiId;
  final String? payeeQrCodeUrl;

  BillModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.building,
    required this.room,
    required this.billType,
    required this.amount,
    this.paidAmount = 0.0,
    double defaulterAmount = 0.0,
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
    this.paymentStatus,
    this.securityDepositStatus,
    this.returnedAt,
    this.refundMode,
    this.refundRef,
    this.refundRemarks,
    this.receiptNo,
    this.receiptIssuedAt,
    this.rejectionDismissed = false,
    this.rejectedAt,
    this.bed,
    this.regNo,
    this.studentDocId,
    this.payeeAccountName,
    this.payeeBankName,
    this.payeeAccountNumber,
    this.payeeIfscCode,
    this.payeeUpiId,
    this.payeeQrCodeUrl,
  })  : _storedDefaulterAmount = defaulterAmount,
        createdAt = createdAt ?? DateTime.now();

  bool get _isStatusPaid => status.toLowerCase() == 'paid';

  /// Calculates late payment / defaulter fee in accordance with hostel policy & Clause 5.10:
  /// - 3-day grace period following due date: Rs. 0
  /// - From Day 4 onwards: Rs. 100 per day
  /// - Capped at Rs. 3,000 per 30-day month (e.g. Days 1-30 after grace: Rs. 100/day up to Rs. 3,000;
  ///   Days 31-60 after grace: up to Rs. 6,000; Days 61-90: up to Rs. 9,000, and so on).
  static double calculateDefaulterFee(int daysOverdue) {
    if (daysOverdue <= 3) return 0.0;
    final chargeableDays = daysOverdue - 3;
    final fullMonths = chargeableDays ~/ 30;
    final remDays = chargeableDays % 30;
    return (fullMonths * 3000.0) + (remDays * 100.0);
  }

  /// Dynamic or recorded defaulter fee for this bill.
  /// Unpaid/pending bills dynamically calculate fee past the 3-day grace period.
  /// Once paid or returned, the settled/stored fee is preserved.
  double get defaulterAmount {
    if (_isStatusPaid || isDepositReturned) {
      return _storedDefaulterAmount;
    }
    final dynamicFee = calculateDefaulterFee(daysOverdue);
    return dynamicFee > _storedDefaulterAmount ? dynamicFee : _storedDefaulterAmount;
  }

  double get totalPayable => amount + defaulterAmount;
  double get balance => (totalPayable - paidAmount).clamp(0.0, totalPayable);
  bool get isPaid => _isStatusPaid || (paidAmount >= totalPayable && totalPayable > 0);
  
  String? get utrNumber => transactionRef;

  bool get isSecurityDeposit {
    final lower = '$billType $billingMonth'.toLowerCase();
    return lower.contains('security deposit') || lower.contains('deposit');
  }

  bool get isDepositReturned {
    if (!isSecurityDeposit) return false;
    final s = status.toLowerCase();
    final ds = (securityDepositStatus ?? '').toLowerCase();
    return ds == 'returned' || s == 'returned';
  }

  bool get isDepositHeld {
    return isSecurityDeposit && (_isStatusPaid || isPaid) && !isDepositReturned;
  }
  
  bool get isProofRejected {
    final s = status.toLowerCase();
    final ps = (paymentStatus ?? '').toLowerCase();
    return s == 'proof rejected' || ps == 'proof rejected' || s == 'rejected' || ps == 'rejected';
  }

  bool get hasActiveRejectionWarning {
    return isProofRejected && !rejectionDismissed;
  }
  
  bool get isPendingVerification {
    if (_isStatusPaid || isDepositReturned) return false;
    final s = status.toLowerCase();
    final ps = (paymentStatus ?? '').toLowerCase();
    if (s == 'proof rejected' || ps == 'proof rejected') return false;
    if (s == 'pending verification' || ps == 'pending verification') return true;
    return transactionRef != null && transactionRef!.trim().isNotEmpty && s != 'pending';
  }

  bool get isDefaulter {
    if (isPaid || isPendingVerification || isDepositReturned) return false;
    if (status.toLowerCase() == 'defaulter') return true;
    final now = DateTime.now();
    // Overdue if today is past the end of the dueDate
    final endOfDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59);
    return now.isAfter(endOfDueDate);
  }

  bool get isPendingOnly {
    return !isPaid && !isPendingVerification && !isDefaulter && !isDepositReturned;
  }

  String get computedStatus {
    if (isDepositReturned) return 'Returned';
    if (isPaid) return 'Paid';
    if (isPendingVerification) return 'Pending Verification';
    if (isDefaulter) return 'Defaulter';
    return 'Pending';
  }

  int get daysOverdue {
    if (_isStatusPaid || isPendingVerification || isDepositReturned) return 0;
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

    DateTime? parsedReturnedAt;
    if (data['returnedAt'] != null) {
      if (data['returnedAt'] is Timestamp) {
        parsedReturnedAt = (data['returnedAt'] as Timestamp).toDate();
      } else {
        parsedReturnedAt = DateTime.tryParse(data['returnedAt'].toString());
      }
    }

    DateTime? parsedReceiptIssuedAt;
    if (data['receiptIssuedAt'] != null) {
      if (data['receiptIssuedAt'] is Timestamp) {
        parsedReceiptIssuedAt = (data['receiptIssuedAt'] as Timestamp).toDate();
      } else {
        parsedReceiptIssuedAt = DateTime.tryParse(data['receiptIssuedAt'].toString());
      }
    }

    DateTime? parsedRejectedAt;
    if (data['rejectedAt'] != null) {
      if (data['rejectedAt'] is Timestamp) {
        parsedRejectedAt = (data['rejectedAt'] as Timestamp).toDate();
      } else {
        parsedRejectedAt = DateTime.tryParse(data['rejectedAt'].toString());
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
      defaulterAmount: (data['defaulterAmount'] as num?)?.toDouble() ??
          (data['lateFee'] as num?)?.toDouble() ??
          (data['penalty'] as num?)?.toDouble() ??
          0.0,
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
      paymentStatus: data['paymentStatus']?.toString(),
      securityDepositStatus: data['securityDepositStatus']?.toString(),
      returnedAt: parsedReturnedAt,
      refundMode: data['refundMode']?.toString(),
      refundRef: data['refundRef']?.toString(),
      refundRemarks: data['refundRemarks']?.toString(),
      receiptNo: data['receiptNo']?.toString() ?? data['receiptNumber']?.toString(),
      receiptIssuedAt: parsedReceiptIssuedAt,
      rejectionDismissed: data['rejectionDismissed'] == true || data['rejectedPaymentDismissed'] == true,
      rejectedAt: parsedRejectedAt,
      bed: data['bed']?.toString() ?? data['bedNumber']?.toString(),
      regNo: data['regNo']?.toString() ?? data['registrationNumber']?.toString(),
      studentDocId: data['studentDocId']?.toString(),
      payeeAccountName: data['payeeAccountName']?.toString(),
      payeeBankName: data['payeeBankName']?.toString(),
      payeeAccountNumber: data['payeeAccountNumber']?.toString(),
      payeeIfscCode: data['payeeIfscCode']?.toString(),
      payeeUpiId: data['payeeUpiId']?.toString(),
      payeeQrCodeUrl: data['payeeQrCodeUrl']?.toString(),
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
      'defaulterAmount': defaulterAmount,
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
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (securityDepositStatus != null) 'securityDepositStatus': securityDepositStatus,
      if (returnedAt != null) 'returnedAt': Timestamp.fromDate(returnedAt!),
      if (refundMode != null) 'refundMode': refundMode,
      if (refundRef != null) 'refundRef': refundRef,
      if (refundRemarks != null) 'refundRemarks': refundRemarks,
      if (receiptNo != null) 'receiptNo': receiptNo,
      if (receiptIssuedAt != null) 'receiptIssuedAt': Timestamp.fromDate(receiptIssuedAt!),
      'rejectionDismissed': rejectionDismissed,
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
      if (bed != null) 'bed': bed,
      if (regNo != null) 'regNo': regNo,
      if (regNo != null) 'registrationNumber': regNo,
      if (studentDocId != null) 'studentDocId': studentDocId,
      if (payeeAccountName != null) 'payeeAccountName': payeeAccountName,
      if (payeeBankName != null) 'payeeBankName': payeeBankName,
      if (payeeAccountNumber != null) 'payeeAccountNumber': payeeAccountNumber,
      if (payeeIfscCode != null) 'payeeIfscCode': payeeIfscCode,
      if (payeeUpiId != null) 'payeeUpiId': payeeUpiId,
      if (payeeQrCodeUrl != null) 'payeeQrCodeUrl': payeeQrCodeUrl,
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
    double? defaulterAmount,
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
    String? paymentStatus,
    String? securityDepositStatus,
    DateTime? returnedAt,
    String? refundMode,
    String? refundRef,
    String? refundRemarks,
    String? receiptNo,
    DateTime? receiptIssuedAt,
    bool? rejectionDismissed,
    DateTime? rejectedAt,
    String? bed,
    String? regNo,
    String? studentDocId,
    String? payeeAccountName,
    String? payeeBankName,
    String? payeeAccountNumber,
    String? payeeIfscCode,
    String? payeeUpiId,
    String? payeeQrCodeUrl,
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
      defaulterAmount: defaulterAmount ?? this.defaulterAmount,
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
      paymentStatus: paymentStatus ?? this.paymentStatus,
      securityDepositStatus: securityDepositStatus ?? this.securityDepositStatus,
      returnedAt: returnedAt ?? this.returnedAt,
      refundMode: refundMode ?? this.refundMode,
      refundRef: refundRef ?? this.refundRef,
      refundRemarks: refundRemarks ?? this.refundRemarks,
      receiptNo: receiptNo ?? this.receiptNo,
      receiptIssuedAt: receiptIssuedAt ?? this.receiptIssuedAt,
      rejectionDismissed: rejectionDismissed ?? this.rejectionDismissed,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      bed: bed ?? this.bed,
      regNo: regNo ?? this.regNo,
      studentDocId: studentDocId ?? this.studentDocId,
      payeeAccountName: payeeAccountName ?? this.payeeAccountName,
      payeeBankName: payeeBankName ?? this.payeeBankName,
      payeeAccountNumber: payeeAccountNumber ?? this.payeeAccountNumber,
      payeeIfscCode: payeeIfscCode ?? this.payeeIfscCode,
      payeeUpiId: payeeUpiId ?? this.payeeUpiId,
      payeeQrCodeUrl: payeeQrCodeUrl ?? this.payeeQrCodeUrl,
    );
  }
}
