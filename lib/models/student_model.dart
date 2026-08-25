class StudentDirectoryItem {
  final String id;
  final String name;
  final String initials;
  final String status; // 'Upcoming', 'Paid', 'Defaulter'
  final String building;
  final String room;
  final String phone;
  final String email;
  final List<String> notes;
  final double pendingAmount;

  // Onboarding detailed fields
  final String regNo;
  final String course;
  final String branch;
  final String profilePhotoUrl;
  final String collegeIdUrl;
  final String govtIdUrl;
  final String selectedPlan;
  final String paymentFrequency;
  final String packageInstallmentType;
  final String monthlyRent;
  final String securityDeposit;
  final String yearInstallments;
  final String totalAcademicFees;
  final String customInstallments;
  final String premiumDeposit;
  final List<Map<String, dynamic>> installments;
  final String guardianName;
  final String guardianRelationship;
  final String guardianPhone;
  final String dietaryPreference;
  final List<String> inventoryItems;
  final String finalNotes;

  StudentDirectoryItem({
    required this.id,
    required this.name,
    required this.initials,
    required this.status,
    required this.building,
    required this.room,
    required this.phone,
    required this.email,
    required this.notes,
    required this.pendingAmount,
    this.regNo = '',
    this.course = '',
    this.branch = '',
    this.profilePhotoUrl = '',
    this.collegeIdUrl = '',
    this.govtIdUrl = '',
    this.selectedPlan = '',
    this.paymentFrequency = '',
    this.packageInstallmentType = '',
    this.monthlyRent = '',
    this.securityDeposit = '',
    this.yearInstallments = '',
    this.totalAcademicFees = '',
    this.customInstallments = '',
    this.premiumDeposit = '',
    this.installments = const [],
    this.guardianName = '',
    this.guardianRelationship = '',
    this.guardianPhone = '',
    this.dietaryPreference = '',
    this.inventoryItems = const [],
    this.finalNotes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initials': initials,
      'status': status,
      'building': building,
      'room': room,
      'phone': phone,
      'email': email,
      'notes': notes,
      'pendingAmount': pendingAmount,
      'regNo': regNo,
      'course': course,
      'branch': branch,
      'profilePhotoUrl': profilePhotoUrl,
      'collegeIdUrl': collegeIdUrl,
      'govtIdUrl': govtIdUrl,
      'profilePhotoUploaded': profilePhotoUrl.isNotEmpty,
      'collegeIdUploaded': collegeIdUrl.isNotEmpty,
      'govtIdUploaded': govtIdUrl.isNotEmpty,
      'selectedPlan': selectedPlan,
      'paymentFrequency': paymentFrequency,
      'packageInstallmentType': packageInstallmentType,
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'yearInstallments': yearInstallments,
      'totalAcademicFees': totalAcademicFees,
      'customInstallments': customInstallments,
      'premiumDeposit': premiumDeposit,
      'installments': installments,
      'guardianName': guardianName,
      'guardianRelationship': guardianRelationship,
      'guardianPhone': guardianPhone,
      'dietaryPreference': dietaryPreference,
      'inventoryItems': inventoryItems,
      'finalNotes': finalNotes,
    };
  }

  factory StudentDirectoryItem.fromJson(Map<String, dynamic> json) {
    return StudentDirectoryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      initials: json['initials'] ?? '',
      status: json['status'] ?? '',
      building: json['building'] ?? '',
      room: json['room'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      notes: List<String>.from(json['notes'] ?? []),
      pendingAmount: (json['pendingAmount'] ?? 0.0).toDouble(),
      regNo: json['regNo'] ?? '',
      course: json['course'] ?? '',
      branch: json['branch'] ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] is String
          ? json['profilePhotoUrl']
          : (json['profilePhotoUploaded'] == true ? 'uploaded' : ''),
      collegeIdUrl: json['collegeIdUrl'] is String
          ? json['collegeIdUrl']
          : (json['collegeIdUploaded'] == true ? 'uploaded' : ''),
      govtIdUrl: json['govtIdUrl'] is String
          ? json['govtIdUrl']
          : (json['govtIdUploaded'] == true ? 'uploaded' : ''),
      selectedPlan: json['selectedPlan'] ?? '',
      paymentFrequency: json['paymentFrequency'] ?? '',
      packageInstallmentType: json['packageInstallmentType'] ?? '',
      monthlyRent: json['monthlyRent'] ?? '',
      securityDeposit: json['securityDeposit'] ?? '',
      yearInstallments: json['yearInstallments'] ?? '',
      totalAcademicFees: json['totalAcademicFees'] ?? '',
      customInstallments: json['customInstallments'] ?? '',
      premiumDeposit: json['premiumDeposit'] ?? '',
      installments: (json['installments'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const [],
      guardianName: json['guardianName'] ?? '',
      guardianRelationship: json['guardianRelationship'] ?? '',
      guardianPhone: json['guardianPhone'] ?? '',
      dietaryPreference: json['dietaryPreference'] ?? '',
      inventoryItems: List<String>.from(json['inventoryItems'] ?? []),
      finalNotes: json['finalNotes'] ?? '',
    );
  }

  StudentDirectoryItem copyWith({
    String? id,
    String? name,
    String? initials,
    String? status,
    String? building,
    String? room,
    String? phone,
    String? email,
    List<String>? notes,
    double? pendingAmount,
    String? regNo,
    String? course,
    String? branch,
    String? profilePhotoUrl,
    String? collegeIdUrl,
    String? govtIdUrl,
    String? selectedPlan,
    String? paymentFrequency,
    String? packageInstallmentType,
    String? monthlyRent,
    String? securityDeposit,
    String? yearInstallments,
    String? totalAcademicFees,
    String? customInstallments,
    String? premiumDeposit,
    List<Map<String, dynamic>>? installments,
    String? guardianName,
    String? guardianRelationship,
    String? guardianPhone,
    String? dietaryPreference,
    List<String>? inventoryItems,
    String? finalNotes,
  }) {
    return StudentDirectoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      status: status ?? this.status,
      building: building ?? this.building,
      room: room ?? this.room,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      regNo: regNo ?? this.regNo,
      course: course ?? this.course,
      branch: branch ?? this.branch,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      collegeIdUrl: collegeIdUrl ?? this.collegeIdUrl,
      govtIdUrl: govtIdUrl ?? this.govtIdUrl,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      packageInstallmentType: packageInstallmentType ?? this.packageInstallmentType,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      yearInstallments: yearInstallments ?? this.yearInstallments,
      totalAcademicFees: totalAcademicFees ?? this.totalAcademicFees,
      customInstallments: customInstallments ?? this.customInstallments,
      premiumDeposit: premiumDeposit ?? this.premiumDeposit,
      installments: installments ?? this.installments,
      guardianName: guardianName ?? this.guardianName,
      guardianRelationship: guardianRelationship ?? this.guardianRelationship,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      inventoryItems: inventoryItems ?? this.inventoryItems,
      finalNotes: finalNotes ?? this.finalNotes,
    );
  }
}
