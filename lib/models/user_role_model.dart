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
  final bool hasCompletedOnboardingTour;
  final bool hasChangedDefaultPassword;
  final bool hasDismissedPasswordNotice;

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
    this.hasCompletedOnboardingTour = false,
    this.hasChangedDefaultPassword = true,
    this.hasDismissedPasswordNotice = false,
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

  AppUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phone,
    AppRole? role,
    String? studentId,
    String? registrationNumber,
    String? building,
    String? room,
    String? status,
    DateTime? createdAt,
    bool? hasCompletedOnboardingTour,
    bool? hasChangedDefaultPassword,
    bool? hasDismissedPasswordNotice,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      building: building ?? this.building,
      room: room ?? this.room,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      hasCompletedOnboardingTour: hasCompletedOnboardingTour ?? this.hasCompletedOnboardingTour,
      hasChangedDefaultPassword: hasChangedDefaultPassword ?? this.hasChangedDefaultPassword,
      hasDismissedPasswordNotice: hasDismissedPasswordNotice ?? this.hasDismissedPasswordNotice,
    );
  }

  factory AppUser.fromFirestore({
    required String uid,
    required Map<String, dynamic> data,
    AppRole? fallbackRole,
  }) {
    final roleString = data['role']?.toString();
    AppRole role;
    if (roleString != null) {
      role = AppRoleExtension.fromString(roleString);
    } else if (data['studentId'] != null ||
        data['registrationNumber'] != null ||
        data['regNo'] != null ||
        data['room'] != null) {
      role = AppRole.student;
    } else {
      role = fallbackRole ?? AppRole.student;
    }

    DateTime parsedCreated = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        parsedCreated = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedCreated = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }

    final bool tourCompleted = data['hasCompletedOnboardingTour'] == true;
    final bool noticeDismissed = data['hasDismissedPasswordNotice'] == true;

    // Determine if student has changed default password
    bool passwordChanged = true;
    if (role == AppRole.student) {
      if (data['hasChangedDefaultPassword'] != null) {
        passwordChanged = data['hasChangedDefaultPassword'] == true;
      } else if (data['defaultPassword'] != null && data['defaultPassword'].toString().trim().isNotEmpty) {
        passwordChanged = false;
      }
    }

    final String resolvedFullName = (data['fullName'] != null && data['fullName'].toString().trim().isNotEmpty)
        ? data['fullName'].toString().trim()
        : ((data['name'] != null && data['name'].toString().trim().isNotEmpty)
            ? data['name'].toString().trim()
            : ((data['firstName'] != null && data['firstName'].toString().trim().isNotEmpty)
                ? data['firstName'].toString().trim()
                : (role == AppRole.admin
                    ? 'Super Admin'
                    : (role == AppRole.student ? 'Resident Student' : 'Staff Member'))));

    return AppUser(
      uid: uid,
      email: data['email']?.toString() ?? '',
      fullName: resolvedFullName,
      phone: data['phone']?.toString() ?? '',
      role: role,
      studentId: data['studentId']?.toString(),
      registrationNumber: data['registrationNumber']?.toString() ??
          data['regNo']?.toString(),
      building: data['building']?.toString(),
      room: data['room']?.toString(),
      status: data['status']?.toString() ?? 'Active',
      createdAt: parsedCreated,
      hasCompletedOnboardingTour: tourCompleted,
      hasChangedDefaultPassword: passwordChanged,
      hasDismissedPasswordNotice: noticeDismissed,
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
      'hasCompletedOnboardingTour': hasCompletedOnboardingTour,
      'hasChangedDefaultPassword': hasChangedDefaultPassword,
      'hasDismissedPasswordNotice': hasDismissedPasswordNotice,
    };
  }
}
