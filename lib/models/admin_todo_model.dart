import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTodoModel {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final String priority; // 'High', 'Medium', 'Low'
  final String category; // 'General', 'Maintenance', 'Inspection', 'Fee Dues', 'Staff', 'Mess'
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  AdminTodoModel({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = 'Medium',
    this.category = 'General',
    this.dueDate,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year && dueDate!.month == now.month && dueDate!.day == now.day;
  }

  factory AdminTodoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminTodoModel(
      id: doc.id,
      title: data['title']?.toString() ?? 'Untitled Task',
      description: data['description']?.toString() ?? '',
      isCompleted: data['isCompleted'] == true,
      priority: data['priority']?.toString() ?? 'Medium',
      category: data['category']?.toString() ?? 'General',
      dueDate: data['dueDate'] is Timestamp
          ? (data['dueDate'] as Timestamp).toDate()
          : (data['dueDate'] != null ? DateTime.tryParse(data['dueDate'].toString()) : null),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] != null ? DateTime.tryParse(data['createdAt'].toString()) : null) ??
              DateTime.now(),
      completedAt: data['completedAt'] is Timestamp
          ? (data['completedAt'] as Timestamp).toDate()
          : (data['completedAt'] != null ? DateTime.tryParse(data['completedAt'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority,
      'category': category,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AdminTodoModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return AdminTodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static List<AdminTodoModel> get defaultTodos => const [];
}
