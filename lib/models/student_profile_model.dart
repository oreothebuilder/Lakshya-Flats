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
  final String hometownAddress;
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
  final bool photoAddLater;
  final bool collegeIdAddLater;
  final bool govtIdAddLater;
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
    this.hometownAddress = '',
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
    this.photoAddLater = false,
    this.collegeIdAddLater = false,
    this.govtIdAddLater = false,
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
      hometownAddress: data['hometownAddress']?.toString() ?? data['address']?.toString() ?? '',
      building: data['building'] ?? '',
      room: data['room'] ?? '',
      bedNumber: data['bedNumber']?.toString() ?? data['bed']?.toString() ?? '',
      plan: data['plan'] ?? '',
      paymentFrequency: data['paymentFrequency'] ?? '',
      monthlyRent: data['monthlyRent']?.toString() ?? '',
      securityDeposit: data['securityDeposit']?.toString() ?? '',
      guardianName: data['guardianName'] ?? '',
      guardianPhone: data['guardianPhone'] ?? '',
      guardianRelationship: data['guardianRelationship'] ?? '',
      dietaryPreference: data['dietaryPreference'] ?? '',
      photoUrl: data['photoUrl'],
      collegeIdUrl: data['collegeIdUrl'],
      govtIdUrl: data['govtIdUrl'],
      rentAgreementUrl: data['rentAgreementUrl']?.toString(),
      photoAddLater: data['photoAddLater'] == true,
      collegeIdAddLater: data['collegeIdAddLater'] == true,
      govtIdAddLater: data['govtIdAddLater'] == true,
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
      'hometownAddress': hometownAddress,
      'address': hometownAddress,
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
      'photoAddLater': photoAddLater,
      'collegeIdAddLater': collegeIdAddLater,
      'govtIdAddLater': govtIdAddLater,
      'additionalDocs': additionalDocs,
      'inventory': inventory,
      'notes': notes,
      'installments': installments,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  StudentProfile copyWith({
    String? id,
    String? studentId,
    String? fullName,
    String? firstName,
    String? email,
    String? phone,
    String? registrationNumber,
    String? course,
    String? branch,
    String? hometownAddress,
    String? building,
    String? room,
    String? bedNumber,
    String? plan,
    String? paymentFrequency,
    String? monthlyRent,
    String? securityDeposit,
    String? guardianName,
    String? guardianPhone,
    String? guardianRelationship,
    String? dietaryPreference,
    String? photoUrl,
    String? collegeIdUrl,
    String? govtIdUrl,
    String? rentAgreementUrl,
    bool? photoAddLater,
    bool? collegeIdAddLater,
    bool? govtIdAddLater,
    Map<String, dynamic>? additionalDocs,
    List<String>? inventory,
    List<String>? notes,
    List<Map<String, dynamic>>? installments,
    String? status,
    DateTime? createdAt,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      course: course ?? this.course,
      branch: branch ?? this.branch,
      hometownAddress: hometownAddress ?? this.hometownAddress,
      building: building ?? this.building,
      room: room ?? this.room,
      bedNumber: bedNumber ?? this.bedNumber,
      plan: plan ?? this.plan,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianRelationship: guardianRelationship ?? this.guardianRelationship,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      photoUrl: photoUrl ?? this.photoUrl,
      collegeIdUrl: collegeIdUrl ?? this.collegeIdUrl,
      govtIdUrl: govtIdUrl ?? this.govtIdUrl,
      rentAgreementUrl: rentAgreementUrl ?? this.rentAgreementUrl,
      photoAddLater: photoAddLater ?? this.photoAddLater,
      collegeIdAddLater: collegeIdAddLater ?? this.collegeIdAddLater,
      govtIdAddLater: govtIdAddLater ?? this.govtIdAddLater,
      additionalDocs: additionalDocs ?? this.additionalDocs,
      inventory: inventory ?? this.inventory,
      notes: notes ?? this.notes,
      installments: installments ?? this.installments,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
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
