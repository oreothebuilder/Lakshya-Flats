import 'package:cloud_firestore/cloud_firestore.dart';

enum AppRole {
  admin,
  management,
  student,
}

extension AppRoleExtension on AppRole {
  String get name {
    switch (this) {
      case AppRole.admin:
        return 'admin';
      case AppRole.management:
        return 'management';
      case AppRole.student:
        return 'student';
    }
  }

  String get displayName {
    switch (this) {
      case AppRole.admin:
        return 'Super Admin';
      case AppRole.management:
        return 'Management Staff';
      case AppRole.student:
        return 'Resident Student';
    }
  }

  static AppRole fromString(String? roleStr) {
    if (roleStr == null) return AppRole.student;
    final r = roleStr.toLowerCase().trim();
    if (r == 'admin' || r == 'superadmin' || r == 'owner') {
      return AppRole.admin;
    }
    if (r == 'management' || r == 'staff' || r == 'warden' || r == 'manager') {
      return AppRole.management;
    }
    return AppRole.student;
  }
}

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String phone;
  final AppRole role;
  final String? studentId;
  final String? registrationNumber;
  final String? building;
  final String? room;
  final String status;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phone = '',
    required this.role,
    this.studentId,
    this.registrationNumber,
    this.building,
    this.room,
    this.status = 'Active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == AppRole.admin;
  bool get isManagement => role == AppRole.management;
  bool get isStudent => role == AppRole.student;

  /// Permissions Matrix
  bool get canManagePayments => isAdmin; // Only admin can access billing/finance
  bool get canManageExpenses => isAdmin; // Only admin can access expense tracker
  bool get canEditStudents => isAdmin; // Only admin can edit or delete students
  bool get canIssueBills => isAdmin;
  bool get canManageMess => isAdmin || isManagement;
  bool get canManageComplaints => isAdmin || isManagement;
  bool get canBroadcast => isAdmin || isManagement;
  bool get canViewDirectory => isAdmin || isManagement;
  bool get canOnboardStudent => isAdmin; // Only admin can onboard new students

  factory AppUser.fromFirestore({
    required String uid,
    required Map<String, dynamic> data,
    AppRole? fallbackRole,
  }) {
    final roleString = data['role']?.toString();
    final role = roleString != null
        ? AppRoleExtension.fromString(roleString)
        : (fallbackRole ?? AppRole.student);

    DateTime parsedCreated = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        parsedCreated = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedCreated = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }

    return AppUser(
      uid: uid,
      email: data['email']?.toString() ?? '',
      fullName: data['fullName']?.toString() ??
          data['name']?.toString() ??
          (role == AppRole.admin ? 'Super Admin' : 'Staff Member'),
      phone: data['phone']?.toString() ?? '',
      role: role,
      studentId: data['studentId']?.toString(),
      registrationNumber: data['registrationNumber']?.toString() ??
          data['regNo']?.toString(),
      building: data['building']?.toString(),
      room: data['room']?.toString(),
      status: data['status']?.toString() ?? 'Active',
      createdAt: parsedCreated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role.name,
      if (studentId != null) 'studentId': studentId,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
      if (building != null) 'building': building,
      if (room != null) 'room': room,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
