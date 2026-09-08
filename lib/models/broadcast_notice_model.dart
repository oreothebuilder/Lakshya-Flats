import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastNoticeModel {
  final String id;
  final String title;
  final String message;
  final String category; // "General", "Urgent", "Mess", "Maintenance", "Payment"
  final String targetAudience; // "All Students", "Building Specific", etc.
  final String? targetBuilding;
  final String priority; // "Low", "Medium", "High", "Critical"
  final String senderName;
  final DateTime createdAt;

  BroadcastNoticeModel({
    required this.id,
    required this.title,
    required this.message,
    this.category = 'General',
    this.targetAudience = 'All Students',
    this.targetBuilding,
    this.priority = 'Medium',
    this.senderName = 'Management',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BroadcastNoticeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BroadcastNoticeModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      category: data['category'] ?? 'General',
      targetAudience: data['targetAudience'] ?? 'All Students',
      targetBuilding: data['targetBuilding'],
      priority: data['priority'] ?? 'Medium',
      senderName: data['senderName'] ?? 'Management',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'category': category,
      'targetAudience': targetAudience,
      'targetBuilding': targetBuilding,
      'priority': priority,
      'senderName': senderName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
