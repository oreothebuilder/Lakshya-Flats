import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfile {
  final String id;
  final String studentId;
  final String fullName;
  final String firstName;
  final String email;
  final String phone;
  final String registrationNumber;
  final String course;
  final String branch;
  final String building;
  final String room;
  final String plan;
  final String paymentFrequency;
  final String monthlyRent;
  final String securityDeposit;
  final String guardianName;
  final String guardianPhone;
  final String guardianRelationship;
  final String dietaryPreference;
  final String? photoUrl;
  final String? collegeIdUrl;
  final String? govtIdUrl;
  final String? rentAgreementUrl;
  final String bedNumber;
  final Map<String, dynamic> additionalDocs;
  final List<String> inventory;
  final List<String> notes;
  final List<Map<String, dynamic>> installments;
  final String status;
  final DateTime createdAt;

  StudentProfile({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.registrationNumber,
    required this.course,
    required this.branch,
    required this.building,
    required this.room,
    this.bedNumber = '',
    required this.plan,
    required this.paymentFrequency,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.guardianName,
    required this.guardianPhone,
    required this.guardianRelationship,
    required this.dietaryPreference,
    this.photoUrl,
    this.collegeIdUrl,
    this.govtIdUrl,
    this.rentAgreementUrl,
    this.additionalDocs = const {},
    this.inventory = const [],
    this.notes = const [],
    this.installments = const [],
    this.status = 'Active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StudentProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentProfile(
      id: doc.id,
      studentId: data['studentId'] ?? doc.id,
      fullName: data['fullName'] ?? '',
      firstName: data['firstName'] ?? (data['fullName']?.toString().split(' ').first ?? ''),
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      registrationNumber: data['registrationNumber'] ?? data['regNo'] ?? '',
      course: data['course'] ?? '',
      branch: data['branch'] ?? '',
      building: data['building'] ?? 'Lakshya',
      room: data['room'] ?? '',
      bedNumber: data['bedNumber']?.toString() ?? data['bed']?.toString() ?? '',
      plan: data['plan'] ?? 'Rent Only',
      paymentFrequency: data['paymentFrequency'] ?? 'Pay Monthly',
      monthlyRent: data['monthlyRent']?.toString() ?? '12,500',
      securityDeposit: data['securityDeposit']?.toString() ?? '25,000',
      guardianName: data['guardianName'] ?? '',
      guardianPhone: data['guardianPhone'] ?? '',
      guardianRelationship: data['guardianRelationship'] ?? 'Father',
      dietaryPreference: data['dietaryPreference'] ?? 'Vegetarian',
      photoUrl: data['photoUrl'],
      collegeIdUrl: data['collegeIdUrl'],
      govtIdUrl: data['govtIdUrl'],
      rentAgreementUrl: data['rentAgreementUrl']?.toString(),
      additionalDocs: Map<String, dynamic>.from(data['additionalDocs'] ?? {}),
      inventory: List<String>.from(data['inventory'] ?? []),
      notes: List<String>.from(data['notes'] ?? []),
      installments: List<Map<String, dynamic>>.from(data['installments'] ?? []),
      status: data['status'] ?? 'Active',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'fullName': fullName,
      'firstName': firstName,
      'email': email,
      'phone': phone,
      'registrationNumber': registrationNumber,
      'course': course,
      'branch': branch,
      'building': building,
      'room': room,
      'bedNumber': bedNumber,
      'plan': plan,
      'paymentFrequency': paymentFrequency,
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
      'guardianRelationship': guardianRelationship,
      'dietaryPreference': dietaryPreference,
      'photoUrl': photoUrl,
      'collegeIdUrl': collegeIdUrl,
      'govtIdUrl': govtIdUrl,
      'rentAgreementUrl': rentAgreementUrl,
      'additionalDocs': additionalDocs,
      'inventory': inventory,
      'notes': notes,
      'installments': installments,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get displayBed {
    if (bedNumber.trim().isNotEmpty) return bedNumber.trim();
    if (room.toLowerCase().contains('bed')) {
      final parts = room.split(',');
      if (parts.length > 1) return parts.last.trim();
    }
    return "Bed 1";
  }

  String get displayRoomOnly {
    if (room.toLowerCase().contains('bed')) {
      final parts = room.split(',');
      return parts.first.trim();
    }
    return room.isNotEmpty ? room : "Room N/A";
  }

  String get initials {
    if (fullName.trim().isEmpty) return "ST";
    final parts = fullName.trim().split(" ");
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return fullName.trim().substring(0, fullName.trim().length >= 2 ? 2 : 1).toUpperCase();
  }
}
