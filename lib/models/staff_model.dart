import 'package:cloud_firestore/cloud_firestore.dart';

class StaffModel {
  final String id;
  final String staffId; // e.g. "STF-101"
  final String name;
  final String phone;
  final String email;
  final String assignmentType; // 'building_incharge' or 'task_based'
  final String designation; // e.g. "Warden", "Driver", "Chef", "Security Guard", "Electrician"
  final String? assignedTask; // e.g. "Driver", "Chef", "Security Guard", or custom details like "Bus Route 1"
  final List<String> assignedBuildings; // List of building names
  final String status; // 'Active', 'On Leave', 'Inactive'
  final DateTime joinedDate;
  final DateTime createdAt;
  final String? photoUrl;
  final String? notes;

  StaffModel({
    required this.id,
    required this.staffId,
    required this.name,
    required this.phone,
    this.email = '',
    this.assignmentType = 'building_incharge',
    this.designation = 'Warden',
    this.assignedTask,
    this.assignedBuildings = const [],
    this.status = 'Active',
    DateTime? joinedDate,
    DateTime? createdAt,
    this.photoUrl,
    this.notes,
  })  : joinedDate = joinedDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  bool get isActive => status.toLowerCase() == 'active';
  bool get isBuildingInCharge =>
      assignmentType == 'building_incharge' || (assignedBuildings.isNotEmpty && (assignedTask == null || assignedTask!.isEmpty));
  bool get isTaskBased =>
      assignmentType == 'task_based' || (assignedTask != null && assignedTask!.isNotEmpty);

  factory StaffModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final task = data['assignedTask']?.toString() ?? data['task']?.toString();
    final rawType = data['assignmentType']?.toString();
    final determinedType = rawType ?? ((task != null && task.isNotEmpty) ? 'task_based' : 'building_incharge');

    return StaffModel(
      id: doc.id,
      staffId: data['staffId']?.toString() ?? 'STF-${doc.id.substring(0, doc.id.length > 4 ? 4 : doc.id.length).toUpperCase()}',
      name: data['name']?.toString() ?? data['fullName']?.toString() ?? 'Staff Member',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      assignmentType: determinedType,
      designation: data['designation']?.toString() ?? data['role']?.toString() ?? (task ?? 'Warden'),
      assignedTask: task,
      assignedBuildings: (data['assignedBuildings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (data['building'] != null ? [data['building'].toString()] : []),
      status: data['status']?.toString() ?? 'Active',
      joinedDate: data['joinedDate'] is Timestamp
          ? (data['joinedDate'] as Timestamp).toDate()
          : DateTime.tryParse(data['joinedDate']?.toString() ?? '') ?? DateTime.now(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      photoUrl: data['photoUrl']?.toString(),
      notes: data['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'name': name,
      'fullName': name,
      'phone': phone,
      'email': email,
      'assignmentType': assignmentType,
      'designation': designation,
      'assignedTask': assignedTask,
      'assignedBuildings': assignedBuildings,
      'status': status,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StaffModel copyWith({
    String? id,
    String? staffId,
    String? name,
    String? phone,
    String? email,
    String? assignmentType,
    String? designation,
    String? assignedTask,
    List<String>? assignedBuildings,
    String? status,
    DateTime? joinedDate,
    DateTime? createdAt,
    String? photoUrl,
    String? notes,
  }) {
    return StaffModel(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      assignmentType: assignmentType ?? this.assignmentType,
      designation: designation ?? this.designation,
      assignedTask: assignedTask ?? this.assignedTask,
      assignedBuildings: assignedBuildings ?? this.assignedBuildings,
      status: status ?? this.status,
      joinedDate: joinedDate ?? this.joinedDate,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
    );
  }

  /// Default staff list is empty: no dummy data seeded or displayed
  static List<StaffModel> get defaultStaff => const [];
}
