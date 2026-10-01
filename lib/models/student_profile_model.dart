import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfile {
  final String id;
  final String studentId;
  final String fullName;
  final String firstName;
  final String email;
  final String phone;
  final String registrationNumber;
  final String dob;
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
  final String? leaseStartDate;
  final String? leaseEndDate;
  final String? rentalTerm;
  final List<String> academicYears;
  final String? movedOutYear;
  final String? movedOutDate;

  StudentProfile({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.registrationNumber,
    this.dob = '',
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
    this.leaseStartDate,
    this.leaseEndDate,
    this.rentalTerm,
    this.academicYears = const ["2026-2027"],
    this.movedOutYear,
    this.movedOutDate,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StudentProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Academic years resolution
    List<String> resolvedAcademicYears = [];
    if (data['academicYears'] is List) {
      resolvedAcademicYears = (data['academicYears'] as List).map((e) => e.toString().trim()).toList();
    }
    final startDate = data['leaseStartDate']?.toString();
    final endDate = data['leaseEndDate']?.toString();
    if (resolvedAcademicYears.isEmpty) {
      resolvedAcademicYears = _deriveAcademicYears(startDate, endDate);
    }

    return StudentProfile(
      id: doc.id,
      studentId: data['studentId'] ?? doc.id,
      fullName: data['fullName'] ?? '',
      firstName: data['firstName'] ?? (data['fullName']?.toString().split(' ').first ?? ''),
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      registrationNumber: data['registrationNumber'] ?? data['regNo'] ?? '',
      dob: data['dob']?.toString() ?? data['dateOfBirth']?.toString() ?? '',
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
      leaseStartDate: startDate,
      leaseEndDate: endDate,
      rentalTerm: data['rentalTerm']?.toString() ?? data['lockInPeriod']?.toString(),
      academicYears: resolvedAcademicYears,
      movedOutYear: data['movedOutYear']?.toString(),
      movedOutDate: data['movedOutDate']?.toString(),
    );
  }

  static List<String> _deriveAcademicYears(String? startStr, String? endStr) {
    int? parseYear(String? s) {
      if (s == null || s.trim().isEmpty) return null;
      final clean = s.trim();
      final parts = clean.split('/');
      if (parts.length == 3) {
        return int.tryParse(parts[2]);
      }
      final dt = DateTime.tryParse(clean);
      return dt?.year;
    }

    final startYear = parseYear(startStr);
    final endYear = parseYear(endStr);

    if (startYear != null && endYear != null && endYear >= startYear) {
      final List<String> list = [];
      const currentStartYear = 2026;
      for (int y = startYear; y < endYear; y++) {
        if (y <= currentStartYear) {
          list.add("$y-${y + 1}");
        }
      }
      if (list.isNotEmpty) return list;
    }
    return ["2026-2027"];
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'fullName': fullName,
      'firstName': firstName,
      'email': email,
      'phone': phone,
      'registrationNumber': registrationNumber,
      'dob': dob,
      'dateOfBirth': dob,
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
      'leaseStartDate': leaseStartDate,
      'leaseEndDate': leaseEndDate,
      'rentalTerm': rentalTerm,
      'academicYears': academicYears,
      'movedOutYear': movedOutYear,
      'movedOutDate': movedOutDate,
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
    String? dob,
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
    String? leaseStartDate,
    String? leaseEndDate,
    String? rentalTerm,
    List<String>? academicYears,
    String? movedOutYear,
    String? movedOutDate,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      dob: dob ?? this.dob,
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
      leaseStartDate: leaseStartDate ?? this.leaseStartDate,
      leaseEndDate: leaseEndDate ?? this.leaseEndDate,
      rentalTerm: rentalTerm ?? this.rentalTerm,
      academicYears: academicYears ?? this.academicYears,
      movedOutYear: movedOutYear ?? this.movedOutYear,
      movedOutDate: movedOutDate ?? this.movedOutDate,
    );
  }

  bool get isMovedOut {
    final s = status.toLowerCase().trim();
    return s == 'moved out' || s == 'left' || s == 'student left';
  }

  /// Determines whether the student was enrolled / present in a particular academic year.
  /// If student moved out in year X, they ARE shown in year X (as Moved Out) and previous years,
  /// but NEVER in year X+1 or any upcoming academic years.
  /// The only students shown in upcoming academic years are:
  /// (a) active students who have NOT moved out (carried forward), and
  /// (b) newly onboarded students for that academic year.
  bool isEnrolledInAcademicYear(String year) {
    final cleanYear = year.trim();
    if (cleanYear.isEmpty) return true;

    final currentViewStart = int.tryParse(cleanYear.split('-').first.trim()) ?? 0;

    // Determine earliest enrolled year
    int earliestStart = 9999;
    for (final y in academicYears) {
      final ys = int.tryParse(y.split('-').first.trim()) ?? 0;
      if (ys > 0 && ys < earliestStart) earliestStart = ys;
    }
    if (earliestStart == 9999) {
      earliestStart = 2026;
    }

    // 1. If viewing a year before the student was first enrolled, NEVER show them
    if (currentViewStart > 0 && currentViewStart < earliestStart) {
      return false;
    }

    // 2. If student moved out:
    if (isMovedOut) {
      if (movedOutYear != null && movedOutYear!.trim().isNotEmpty) {
        final movedOutStart = int.tryParse(movedOutYear!.split('-').first.trim()) ?? 0;
        if (movedOutStart > 0 && currentViewStart > 0) {
          if (currentViewStart > movedOutStart) {
            // Student moved out in a past year -> NEVER show in upcoming / future academic years
            return false;
          }
          // Viewing the year they moved out in or an earlier enrolled year -> show them historically
          return true;
        }
      }
      // If movedOutYear is not set or unparseable, only show for explicit academicYears
      return academicYears.contains(cleanYear);
    }

    // 3. For active students (not moved out):
    // Show if explicitly in academicYears or if viewing a year >= their enrollment year
    if (academicYears.contains(cleanYear)) {
      return true;
    }

    if (currentViewStart > 0 && currentViewStart >= earliestStart) {
      return true;
    }

    return false;
  }

  String get displayBed {
    if (bedNumber.trim().isNotEmpty) {
      final b = bedNumber.trim();
      if (b.toLowerCase().startsWith('bed')) return b;
      return "Bed $b";
    }
    if (room.toLowerCase().contains('bed')) {
      final parts = room.split(RegExp(r'[,•-]'));
      if (parts.length > 1) {
        final b = parts.last.trim();
        if (b.toLowerCase().startsWith('bed')) return b;
        return "Bed $b";
      }
    }
    return "";
  }

  String get displayRoomOnly {
    if (room.toLowerCase().contains('bed')) {
      final parts = room.split(RegExp(r'[,•-]'));
      return parts.first.trim();
    }
    return room.isNotEmpty ? room : "Room N/A";
  }

  String get displayRoomAndBed {
    final r = displayRoomOnly;
    final b = displayBed;
    if (r.isNotEmpty && b.isNotEmpty) {
      return "$r • $b";
    } else if (r.isNotEmpty) {
      return r;
    }
    return b.isNotEmpty ? b : "Room & Bed Assigned";
  }

  String get displayRollNo {
    if (registrationNumber.trim().isNotEmpty) {
      return registrationNumber.trim();
    }
    return studentId.isNotEmpty ? studentId : id;
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
