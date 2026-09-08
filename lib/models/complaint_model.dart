import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  static const String statusReceived = 'Received';
  static const String statusUnderExecution = 'Under execution';
  static const String statusResolved = 'Resolved';

  static const List<String> validStatuses = [
    statusReceived,
    statusUnderExecution,
    statusResolved,
  ];

  static String normalizeStatus(String? raw) {
    if (raw == null) return statusReceived;
    final lower = raw.trim().toLowerCase();
    if (lower == 'resolved') return statusResolved;
    if (lower == 'under execution' || lower == 'in-progress' || lower == 'in progress') {
      return statusUnderExecution;
    }
    return statusReceived;
  }

  final String id;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String studentEmail;
  final String building;
  final String room;
  final String title;
  final String category; // "Electrical", "Plumbing", "Carpentry", "Cleaning", "Wi-Fi", "Other"
  final String description;
  final String priority; // "Low", "Medium", "High", "Emergency"
  final String status; // "Received", "Under execution", "Resolved"
  final String? adminRemarks;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  ComplaintModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentPhone = '',
    this.studentEmail = '',
    required this.building,
    required this.room,
    required this.title,
    required this.category,
    required this.description,
    this.priority = 'Medium',
    this.status = statusReceived,
    this.adminRemarks,
    DateTime? createdAt,
    this.updatedAt,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isReceived => status == statusReceived;
  bool get isUnderExecution => status == statusUnderExecution;
  bool get isResolved => status == statusResolved;

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ComplaintModel(
      id: doc.id,
      studentId: data['studentId'] ?? data['ticketId'] ?? '',
      studentName: data['studentName'] ?? 'Resident',
      studentPhone: data['studentPhone'] ?? data['phone'] ?? '',
      studentEmail: data['studentEmail'] ?? data['email'] ?? '',
      building: data['building'] ?? 'Lakshya',
      room: data['room'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? 'Maintenance',
      description: data['description'] ?? '',
      priority: data['priority'] ?? 'Medium',
      status: normalizeStatus(data['status']?.toString()),
      adminRemarks: data['adminRemarks'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] is Timestamp
              ? (data['resolvedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['resolvedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentPhone': studentPhone,
      'studentEmail': studentEmail,
      'building': building,
      'room': room,
      'title': title,
      'category': category,
      'description': description,
      'priority': priority,
      'status': status,
      'adminRemarks': adminRemarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  ComplaintModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentPhone,
    String? studentEmail,
    String? building,
    String? room,
    String? title,
    String? category,
    String? description,
    String? priority,
    String? status,
    String? adminRemarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentPhone: studentPhone ?? this.studentPhone,
      studentEmail: studentEmail ?? this.studentEmail,
      building: building ?? this.building,
      room: room ?? this.room,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      adminRemarks: adminRemarks ?? this.adminRemarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
