import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalTodoModel {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  PersonalTodoModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year && dueDate!.month == now.month && dueDate!.day == now.day;
  }

  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  factory PersonalTodoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedCreated = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        parsedCreated = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedCreated = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }

    DateTime? parsedDue;
    if (data['dueDate'] != null) {
      if (data['dueDate'] is Timestamp) {
        parsedDue = (data['dueDate'] as Timestamp).toDate();
      } else if (data['dueDate'] is String) {
        parsedDue = DateTime.tryParse(data['dueDate']);
      }
    }

    DateTime? parsedCompleted;
    if (data['completedAt'] != null) {
      if (data['completedAt'] is Timestamp) {
        parsedCompleted = (data['completedAt'] as Timestamp).toDate();
      } else if (data['completedAt'] is String) {
        parsedCompleted = DateTime.tryParse(data['completedAt']);
      }
    }

    return PersonalTodoModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      isCompleted: data['isCompleted'] == true,
      dueDate: parsedDue,
      createdAt: parsedCreated,
      completedAt: parsedCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PersonalTodoModel copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return PersonalTodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
