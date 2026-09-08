import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String bucketId;
  final String bucketName;
  final DateTime date;
  final String paymentMode; // 'UPI', 'Cash', 'Bank Transfer', 'Cheque', 'Card'
  final String paidTo;
  final String building;
  final String notes;
  final String? receiptUrl;
  final String recordedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.bucketId,
    required this.bucketName,
    required this.date,
    this.paymentMode = 'UPI',
    this.paidTo = '',
    this.building = 'All Buildings',
    this.notes = '',
    this.receiptUrl,
    this.recordedBy = 'Admin',
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedDate = DateTime.now();
    if (data['date'] != null) {
      if (data['date'] is Timestamp) {
        parsedDate = (data['date'] as Timestamp).toDate();
      } else if (data['date'] is String) {
        parsedDate = DateTime.tryParse(data['date']) ?? DateTime.now();
      }
    }

    DateTime parsedCreated = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        parsedCreated = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedCreated = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }

    DateTime? parsedUpdated;
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        parsedUpdated = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is String) {
        parsedUpdated = DateTime.tryParse(data['updatedAt']);
      }
    }

    double parsedAmount = 0.0;
    if (data['amount'] != null) {
      if (data['amount'] is num) {
        parsedAmount = (data['amount'] as num).toDouble();
      } else {
        parsedAmount = double.tryParse(data['amount'].toString()) ?? 0.0;
      }
    }

    return ExpenseModel(
      id: doc.id,
      title: data['title']?.toString() ?? 'Expense',
      amount: parsedAmount,
      bucketId: data['bucketId']?.toString() ?? 'bucket_others',
      bucketName: data['bucketName']?.toString() ?? 'others',
      date: parsedDate,
      paymentMode: data['paymentMode']?.toString() ?? 'UPI',
      paidTo: data['paidTo']?.toString() ?? '',
      building: data['building']?.toString() ?? 'All Buildings',
      notes: data['notes']?.toString() ?? '',
      receiptUrl: data['receiptUrl']?.toString(),
      recordedBy: data['recordedBy']?.toString() ?? 'Admin',
      createdAt: parsedCreated,
      updatedAt: parsedUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'bucketId': bucketId,
      'bucketName': bucketName,
      'date': Timestamp.fromDate(date),
      'paymentMode': paymentMode,
      'paidTo': paidTo,
      'building': building,
      'notes': notes,
      'receiptUrl': receiptUrl,
      'recordedBy': recordedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? bucketId,
    String? bucketName,
    DateTime? date,
    String? paymentMode,
    String? paidTo,
    String? building,
    String? notes,
    String? receiptUrl,
    String? recordedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      bucketId: bucketId ?? this.bucketId,
      bucketName: bucketName ?? this.bucketName,
      date: date ?? this.date,
      paymentMode: paymentMode ?? this.paymentMode,
      paidTo: paidTo ?? this.paidTo,
      building: building ?? this.building,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
