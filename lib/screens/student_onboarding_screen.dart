import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';

class StudentOnboardingScreen extends StatefulWidget {
  const StudentOnboardingScreen({super.key});

  @override
  State<StudentOnboardingScreen> createState() => _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> {
  // Step State: 0 = Landing/Drafts, 1 = Step 1, 2 = Step 2, 3 = Step 3, 4 = Step 4, 5 = Step 5
  int _currentStep = 0;
  String? _currentDraftId;

  // Step 1 Controllers & State
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();

  // Step 3 Lease Configuration Controllers & State
  String _selectedPlan = "Rent Only"; // "Rent Only" or "Full Package"
  String _paymentFrequency = "Pay Monthly"; // "Pay Monthly" or "Whole Year"
  String _packageInstallmentType = "Single"; // "Single", "Quarterly", "Custom"

  final TextEditingController _monthlyRentController = TextEditingController(text: "12,500");
  final TextEditingController _securityDepositController = TextEditingController(text: "25,000");
  final TextEditingController _yearInstallmentsController = TextEditingController(text: "4");
  final TextEditingController _totalAcademicFeesController = TextEditingController(text: "1,50,000");
  final TextEditingController _customInstallmentsController = TextEditingController(text: "6");
  final TextEditingController _premiumDepositController = TextEditingController(text: "30,000");
  String? _selectedBuilding;
  final List<String> _buildings = [
    "Univ Homes",
    "Rameshwaram",
    "Shivalay",
    "Lakshya Residency Main Campus",
  ];

  // Step 4 Emergency Contact & Preferences State
  final List<Map<String, String>> _installments = [];
  final TextEditingController _guardianNameController = TextEditingController();
  String _guardianRelationship = "Father";
  final TextEditingController _guardianPhoneController = TextEditingController();
  String _dietaryPreference = "Vegetarian";

  // Step 5 Inventory & Final Notes State
  final List<String> _inventoryItems = [
    "AC",
    "Bed",
    "Cupboard",
    "Study Table",
    "Study Chair",
    "Geyser",
    "Bedside Table",
    "Curtains",
    "Pillow",
    "Bucket",
    "Mug",
  ];
  final TextEditingController _customInventoryController = TextEditingController();
  final TextEditingController _finalNotesController = TextEditingController();

  String _profilePhotoUrl = '';
  String _collegeIdUrl = '';
  String _govtIdUrl = '';


  final List<String> _relationships = ["Father", "Mother", "Guardian", "Sibling", "Other"];

  @override
  void initState() {
    super.initState();
    _generateInstallmentsFromStep3();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _regNoController.dispose();
    _courseController.dispose();
    _branchController.dispose();
    _roomNumberController.dispose();
    _monthlyRentController.dispose();
    _securityDepositController.dispose();
    _yearInstallmentsController.dispose();
    _totalAcademicFeesController.dispose();
    _customInstallmentsController.dispose();
    _premiumDepositController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _customInventoryController.dispose();
    _finalNotesController.dispose();
    super.dispose();
  }

  void _generateInstallmentsFromStep3() {
    _installments.clear();
    int count = 12;

    if (_selectedPlan == "Rent Only") {
      int monthlyRent = int.tryParse(_monthlyRentController.text.replaceAll(',', '').replaceAll('₹', '').trim()) ?? 12500;
      if (_paymentFrequency == "Pay Monthly") {
        count = 12;
        for (int i = 1; i <= count; i++) {
          final monthStr = (i < 10) ? "0$i" : "$i";
          _installments.add({
            "title": "Installment $i",
            "amount": "$monthlyRent",
            "dueDate": "24/$monthStr/2024",
          });
        }
      } else {
        count = int.tryParse(_yearInstallmentsController.text.trim()) ?? 4;
        int instAmount = (monthlyRent * 12) ~/ (count > 0 ? count : 1);
        for (int i = 1; i <= count; i++) {
          final monthStr = (i * 3 < 10) ? "0${i * 3}" : "${i * 3}";
          _installments.add({
            "title": "Installment $i",
            "amount": "$instAmount",
            "dueDate": "24/$monthStr/2024",
          });
        }
      }
    } else {
      // Full Package
      int totalAmount = int.tryParse(_totalAcademicFeesController.text.replaceAll(',', '').replaceAll('₹', '').trim()) ?? 150000;
      if (_packageInstallmentType == "Single") {
        count = 1;
      } else if (_packageInstallmentType == "Quarterly") {
        count = 4;
      } else {
        count = int.tryParse(_customInstallmentsController.text.trim()) ?? 6;
      }

      int instAmount = totalAmount ~/ (count > 0 ? count : 1);
      for (int i = 1; i <= count; i++) {
        final monthNum = ((i - 1) * (12 ~/ (count > 0 ? count : 1)) + 8) % 12 + 1;
        final monthStr = (monthNum < 10) ? "0$monthNum" : "$monthNum";
        _installments.add({
          "title": "Installment $i",
          "amount": "$instAmount",
          "dueDate": "24/$monthStr/2024",
        });
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF0056D2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    
    // Show premium option picker sheet
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Select Image Source",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0056D2)),
                ),
                title: Text(
                  "Take Photo with Camera",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const Divider(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF16A34A)),
                ),
                title: Text(
                  "Choose from Gallery",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (source != null) {
      try {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (pickedFile != null) {
          setState(() {
            if (type == 'profile') {
              _profilePhotoUrl = pickedFile.path;
            } else if (type == 'college_id') {
              _collegeIdUrl = pickedFile.path;
            } else if (type == 'govt_id') {
              _govtIdUrl = pickedFile.path;
            }
          });
          _showSnackbar("Document selected successfully!");
        }
      } catch (e) {
        _showSnackbar("Failed to pick image: $e");
      }
    }
  }

  Future<void> _saveDraftToFirestore() async {
    _currentDraftId ??= 'DRAFT-${DateTime.now().millisecondsSinceEpoch}';
    
    final draftData = {
      'fullName': _fullNameController.text,
      'mobile': _mobileController.text,
      'email': _emailController.text,
      'regNo': _regNoController.text,
      'course': _courseController.text,
      'branch': _branchController.text,
      'roomNumber': _roomNumberController.text,
      'selectedBuilding': _selectedBuilding,
      'selectedPlan': _selectedPlan,
      'paymentFrequency': _paymentFrequency,
      'packageInstallmentType': _packageInstallmentType,
      'monthlyRent': _monthlyRentController.text,
      'securityDeposit': _securityDepositController.text,
      'yearInstallments': _yearInstallmentsController.text,
      'totalAcademicFees': _totalAcademicFeesController.text,
      'customInstallments': _customInstallmentsController.text,
      'premiumDeposit': _premiumDepositController.text,
      'guardianName': _guardianNameController.text,
      'guardianRelationship': _guardianRelationship,
      'guardianPhone': _guardianPhoneController.text,
      'dietaryPreference': _dietaryPreference,
      'finalNotes': _finalNotesController.text,
      'profilePhotoUrl': _profilePhotoUrl,
      'collegeIdUrl': _collegeIdUrl,
      'govtIdUrl': _govtIdUrl,
      'profilePhotoUploaded': _profilePhotoUrl.isNotEmpty,
      'collegeIdUploaded': _collegeIdUrl.isNotEmpty,
      'govtIdUploaded': _govtIdUrl.isNotEmpty,
      'currentStep': _currentStep == 0 ? 1 : _currentStep,
      'inventoryItems': _inventoryItems,
      'installments': _installments,
    };

    await StudentService().saveDraft(_currentDraftId!, draftData);
  }

  void _loadDraft(Map<String, dynamic> draft) {
    setState(() {
      _currentDraftId = draft['draftId'];
      _fullNameController.text = draft['fullName'] ?? '';
      _mobileController.text = draft['mobile'] ?? '';
      _emailController.text = draft['email'] ?? '';
      _regNoController.text = draft['regNo'] ?? '';
      _courseController.text = draft['course'] ?? '';
      _branchController.text = draft['branch'] ?? '';
      _roomNumberController.text = draft['roomNumber'] ?? '';
      _selectedBuilding = draft['selectedBuilding'];
      _selectedPlan = draft['selectedPlan'] ?? 'Rent Only';
      _paymentFrequency = draft['paymentFrequency'] ?? 'Pay Monthly';
      _packageInstallmentType = draft['packageInstallmentType'] ?? 'Single';
      _monthlyRentController.text = draft['monthlyRent'] ?? '12,500';
      _securityDepositController.text = draft['securityDeposit'] ?? '25,000';
      _yearInstallmentsController.text = draft['yearInstallments'] ?? '4';
      _totalAcademicFeesController.text = draft['totalAcademicFees'] ?? '1,50,000';
      _customInstallmentsController.text = draft['customInstallments'] ?? '6';
      _premiumDepositController.text = draft['premiumDeposit'] ?? '30,000';
      _guardianNameController.text = draft['guardianName'] ?? '';
      _guardianRelationship = draft['guardianRelationship'] ?? 'Father';
      _guardianPhoneController.text = draft['guardianPhone'] ?? '';
      _dietaryPreference = draft['dietaryPreference'] ?? 'Vegetarian';
      _finalNotesController.text = draft['finalNotes'] ?? '';
      _profilePhotoUrl = draft['profilePhotoUrl'] is String
          ? draft['profilePhotoUrl']
          : (draft['profilePhotoUploaded'] == true ? 'uploaded' : '');
      _collegeIdUrl = draft['collegeIdUrl'] is String
          ? draft['collegeIdUrl']
          : (draft['collegeIdUploaded'] == true ? 'uploaded' : '');
      _govtIdUrl = draft['govtIdUrl'] is String
          ? draft['govtIdUrl']
          : (draft['govtIdUploaded'] == true ? 'uploaded' : '');
      _currentStep = draft['currentStep'] ?? 1;

      if (draft['inventoryItems'] != null) {
        _inventoryItems.clear();
        _inventoryItems.addAll(List<String>.from(draft['inventoryItems']));
      } else {
        _inventoryItems.clear();
        _inventoryItems.addAll([
          "AC", "Bed", "Cupboard", "Study Table", "Study Chair", "Geyser",
          "Bedside Table", "Curtains", "Pillow", "Bucket", "Mug"
        ]);
      }

      if (draft['installments'] != null) {
        _installments.clear();
        _installments.addAll((draft['installments'] as List)
            .map((e) => Map<String, String>.from(e))
            .toList());
      } else {
        _generateInstallmentsFromStep3();
      }
    });
    _showSnackbar("Draft loaded successfully!");
  }

  void _resetForm() {
    setState(() {
      _currentDraftId = null;
      _fullNameController.clear();
      _mobileController.clear();
      _otpController.clear();
      _emailController.clear();
      _regNoController.clear();
      _courseController.clear();
      _branchController.clear();
      _roomNumberController.clear();
      _selectedBuilding = null;
      _selectedPlan = 'Rent Only';
      _paymentFrequency = 'Pay Monthly';
      _packageInstallmentType = 'Single';
      _monthlyRentController.text = '12,500';
      _securityDepositController.text = '25,000';
      _yearInstallmentsController.text = '4';
      _totalAcademicFeesController.text = '1,50,000';
      _customInstallmentsController.text = '6';
      _premiumDepositController.text = '30,000';
      _guardianNameController.clear();
      _guardianRelationship = 'Father';
      _guardianPhoneController.clear();
      _dietaryPreference = 'Vegetarian';
      _finalNotesController.clear();
      _profilePhotoUrl = '';
      _collegeIdUrl = '';
      _govtIdUrl = '';
      _inventoryItems.clear();
      _inventoryItems.addAll([
        "AC", "Bed", "Cupboard", "Study Table", "Study Chair", "Geyser",
        "Bedside Table", "Curtains", "Pillow", "Bucket", "Mug"
      ]);
      _generateInstallmentsFromStep3();
    });
  }

  Future<void> _completeOnboarding() async {
    // Generate unique student ID
    final studentId = 'STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Show premium uploading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0056D2)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Uploading resident documents...",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please wait while we persist files to Firebase Storage.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    String finalProfilePhotoUrl = _profilePhotoUrl;
    String finalCollegeIdUrl = _collegeIdUrl;
    String finalGovtIdUrl = _govtIdUrl;

    try {
      if (_profilePhotoUrl.isNotEmpty && !_profilePhotoUrl.startsWith('http')) {
        finalProfilePhotoUrl = await StudentService().uploadImage(studentId, _profilePhotoUrl, 'profile_photo');
      }
      if (_collegeIdUrl.isNotEmpty && !_collegeIdUrl.startsWith('http')) {
        finalCollegeIdUrl = await StudentService().uploadImage(studentId, _collegeIdUrl, 'college_id');
      }
      if (_govtIdUrl.isNotEmpty && !_govtIdUrl.startsWith('http')) {
        finalGovtIdUrl = await StudentService().uploadImage(studentId, _govtIdUrl, 'govt_id');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Upload failed, falling back to local paths: $e");
      }
    }

    // Dismiss loading dialog
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    // Initials
    final name = _fullNameController.text.trim();
    final nameParts = name.split(' ');
    final initials = nameParts.map((part) => part.isNotEmpty ? part[0] : '').take(2).join().toUpperCase();
    
    // Sum installments for pendingAmount
    double pendingAmount = 0.0;
    for (var inst in _installments) {
      final amtStr = inst['amount'] ?? '0';
      final amt = double.tryParse(amtStr.replaceAll(',', '').replaceAll('₹', '').trim()) ?? 0.0;
      pendingAmount += amt;
    }
    final secDepStr = _selectedPlan == "Rent Only" 
        ? _securityDepositController.text 
        : _premiumDepositController.text;
    final secDep = double.tryParse(secDepStr.replaceAll(',', '').replaceAll('₹', '').trim()) ?? 0.0;
    pendingAmount += secDep;

    final status = pendingAmount > 0 ? "Upcoming" : "Paid";

    final student = StudentDirectoryItem(
      id: studentId,
      name: name.isNotEmpty ? name : "New Resident",
      initials: initials.isNotEmpty ? initials : "NR",
      status: status,
      building: _selectedBuilding ?? "Lakshya Residency",
      room: _roomNumberController.text.isNotEmpty ? "Room ${_roomNumberController.text}" : "TBD",
      phone: _mobileController.text.isNotEmpty ? "+91 ${_mobileController.text}" : "N/A",
      email: _emailController.text.isNotEmpty ? _emailController.text : "N/A",
      notes: _finalNotesController.text.isNotEmpty ? [_finalNotesController.text] : [],
      pendingAmount: pendingAmount,
      regNo: _regNoController.text,
      course: _courseController.text,
      branch: _branchController.text,
      profilePhotoUrl: finalProfilePhotoUrl,
      collegeIdUrl: finalCollegeIdUrl,
      govtIdUrl: finalGovtIdUrl,
      selectedPlan: _selectedPlan,
      paymentFrequency: _paymentFrequency,
      packageInstallmentType: _packageInstallmentType,
      monthlyRent: _monthlyRentController.text,
      securityDeposit: _securityDepositController.text,
      yearInstallments: _yearInstallmentsController.text,
      totalAcademicFees: _totalAcademicFeesController.text,
      customInstallments: _customInstallmentsController.text,
      premiumDeposit: _premiumDepositController.text,
      installments: List<Map<String, dynamic>>.from(_installments),
      guardianName: _guardianNameController.text,
      guardianRelationship: _guardianRelationship,
      guardianPhone: _guardianPhoneController.text,
      dietaryPreference: _dietaryPreference,
      inventoryItems: List<String>.from(_inventoryItems),
      finalNotes: _finalNotesController.text,
    );

    // Save to Firestore
    await StudentService().addStudent(student);

    // Delete the draft
    if (_currentDraftId != null) {
      await StudentService().deleteDraft(_currentDraftId!);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
            const SizedBox(width: 10),
            Text(
              "Onboarding Complete!",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          "Student profile for '${student.name}' has been created and saved to cloud successfully.",
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0056D2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  void _saveDraft() {
    _saveDraftToFirestore();
    setState(() {
      _currentStep = 0;
    });
    _showSnackbar("Draft saved to cloud successfully!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
              _saveDraftToFirestore();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _currentStep == 0 ? "Student Onboarding Page" : "Lakshya Residency",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: _buildCurrentView(),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentStep) {
      case 0:
        return _buildLandingView();
      case 1:
        return _buildStep1View();
      case 2:
        return _buildStep2View();
      case 3:
        return _buildStep3View();
      case 4:
        return _buildStep4View();
      case 5:
        return _buildStep5View();
      default:
        return _buildLandingView();
    }
  }

  // ==========================================
  // LANDING & DRAFTS VIEW (IMAGE 1)
  // ==========================================
  Widget _buildLandingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0056D2), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0056D2).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Onboard New Resident",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Progress is auto-saved to cloud on back",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _resetForm();
                    setState(() {
                      _currentStep = 1;
                    });
                    _saveDraftToFirestore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0056D2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          "Start New Student Onboarding",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0056D2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        Row(
          children: [
            const Icon(Icons.published_with_changes_rounded, size: 20, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text(
              "In-Progress Drafts (Cloud Saved)",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        StreamBuilder<List<Map<String, dynamic>>>(
          stream: StudentService().getDraftsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(color: Color(0xFF0056D2)),
                ),
              );
            }

            final drafts = snapshot.data ?? [];
            if (drafts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_done_outlined,
                      size: 48,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "No In-Progress Drafts",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "When you start onboarding a student, progress will auto-save to the cloud and appear here.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: drafts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final draft = drafts[index];
                final fullName = draft['fullName'] ?? '';
                final currentStep = draft['currentStep'] ?? 1;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.description_rounded, color: Color(0xFF4F46E5), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isNotEmpty ? fullName : "Draft Resident Application",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Saved on cloud • Step $currentStep In Progress",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _loadDraft(draft),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0056D2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Resume",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // STEP 1 OF 5: STUDENT INFORMATION
  // ==========================================
  Widget _buildStep1View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "STEP 1 OF 5",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0056D2),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Student Information",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.2,
            minHeight: 4,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF0056D2),
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            "Please provide your academic and contact details to start your stay application. This information will be used for your official resident profile.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          "Profile Photo (Optional / Add Later)",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage: _profilePhotoUrl.isNotEmpty
                    ? (_profilePhotoUrl.startsWith('http')
                        ? NetworkImage(_profilePhotoUrl)
                        : FileImage(File(_profilePhotoUrl)) as ImageProvider)
                    : null,
                child: _profilePhotoUrl.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: Color(0xFF94A3B8),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upload Resident Photo",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Take photo via camera or select from gallery",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage('profile'),
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: Text(
                            _profilePhotoUrl.isNotEmpty ? "Change Photo" : "Choose Photo",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0056D2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        if (_profilePhotoUrl.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _profilePhotoUrl = '';
                              });
                            },
                            icon: const Icon(Icons.delete_rounded, size: 15, color: Color(0xFFEF4444)),
                            label: Text(
                              "Remove",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () {
                              _showSnackbar("Photo step skipped for later.");
                            },
                            icon: const Icon(Icons.access_time_rounded, size: 15),
                            label: Text(
                              "Add Later",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildInputLabel("Full Name"),
        const SizedBox(height: 6),
        TextField(
          controller: _fullNameController,
          decoration: _buildInputDecoration(
            hintText: "Enter your legal full name",
            prefixIcon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Mobile Number (India +91)"),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Text("🇮🇳", style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    "+91",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration(
                  hintText: "9876543210",
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  _showSnackbar("OTP sent to mobile number!");
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0056D2), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Resend",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0056D2),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "OTP Verification",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showSnackbar("OTP resent to mobile!"),
                    child: Text(
                      "Resend OTP",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF64748B), size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0056D2)),
                    onPressed: () {
                      _showSnackbar("OTP verified successfully!");
                    },
                  ),
                  hintText: "Enter 6-digit OTP",
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0056D2), width: 1.8),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Email ID"),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration(
            hintText: "student@university.edu",
            prefixIcon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("College Registration Number"),
        const SizedBox(height: 6),
        TextField(
          controller: _regNoController,
          decoration: _buildInputDecoration(
            hintText: "Enter registration number or roll no",
            prefixIcon: Icons.badge_outlined,
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Course"),
        const SizedBox(height: 6),
        TextField(
          controller: _courseController,
          decoration: _buildInputDecoration(
            hintText: "e.g. B.Tech / B.Sc / MBA",
            prefixIcon: Icons.school_outlined,
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Branch"),
        const SizedBox(height: 6),
        TextField(
          controller: _branchController,
          decoration: _buildInputDecoration(
            hintText: "e.g. Computer Science & Engineering",
            prefixIcon: Icons.account_tree_outlined,
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 2;
              });
              _saveDraftToFirestore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0056D2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Next Step",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _saveDraft,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0056D2), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "Save as Draft",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0056D2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2 OF 5: UPLOAD IDENTIFICATION
  // ==========================================
  Widget _buildStep2View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "STEP 2 OF 5",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0056D2),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "DOCUMENT VERIFICATION",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Upload Identification",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.4,
            minHeight: 4,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF0056D2),
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            "Please provide digital copies of your identification documents. High-resolution photos or PDF scans are preferred.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "College ID Card",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => _showSnackbar("College ID step skipped for later."),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  Text(
                    "Add Later",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildUploadCard(
          title: "Click to Upload College ID Card",
          subtitle: "📸 Take Photo with Camera or 📁 Choose File",
          icon: Icons.note_add_rounded,
          iconBg: const Color(0xFFEEF2FF),
          iconColor: const Color(0xFF4F46E5),
          fileUrl: _collegeIdUrl,
          onTap: () => _pickImage('college_id'),
          onRemove: () {
            setState(() {
              _collegeIdUrl = '';
            });
            _showSnackbar("College ID Card removed.");
          },
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Government Authorized ID\n(Aadhar, PAN, DL)",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            GestureDetector(
              onTap: () => _showSnackbar("Government ID step skipped for later."),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  Text(
                    "Add Later",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildUploadCard(
          title: "Click to Upload Government Authorized ID",
          subtitle: "📸 Take Photo with Camera or 📁 Choose File",
          icon: Icons.verified_user_rounded,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          fileUrl: _govtIdUrl,
          onTap: () => _pickImage('govt_id'),
          onRemove: () {
            setState(() {
              _govtIdUrl = '';
            });
            _showSnackbar("Government ID removed.");
          },
        ),
        const SizedBox(height: 28),

        // Room Assignment Section (End of Step 2)
        Text(
          "Room Assignment",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Select your preferred building and room number for the upcoming semester.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF475569),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),

        // Selected Building Dropdown
        _buildInputLabel("Selected Building"),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBuilding,
              isExpanded: true,
              hint: Text(
                "Choose a building",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              items: _buildings.map((String b) {
                return DropdownMenuItem<String>(
                  value: b,
                  child: Text(
                    b,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedBuilding = val;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Room Number Field
        _buildInputLabel("Room Number"),
        const SizedBox(height: 6),
        TextField(
          controller: _roomNumberController,
          decoration: _buildInputDecoration(
            hintText: "e.g. 402-A",
            suffixIcon: Icons.door_sliding_outlined,
          ),
        ),
        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = 1;
                    });
                    _saveDraftToFirestore();
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(
                    "Back",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0056D2),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0056D2), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 3;
                    });
                    _saveDraftToFirestore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056D2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Next Step",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3 OF 5: LEASE CONFIGURATION
  // ==========================================
  Widget _buildStep3View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "STEP 3 OF 5",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0056D2),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "LEASE CONFIGURATION",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Lease Configuration",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.6,
            minHeight: 4,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF0056D2),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          "Choose Your Plan",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlan = "Rent Only";
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _selectedPlan == "Rent Only"
                          ? const Color(0xFF0056D2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          size: 18,
                          color: _selectedPlan == "Rent Only" ? Colors.white : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Rent Only",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedPlan == "Rent Only" ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlan = "Full Package";
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _selectedPlan == "Full Package"
                          ? const Color(0xFF0056D2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: _selectedPlan == "Full Package" ? Colors.white : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Full Package",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedPlan == "Full Package" ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "*Full Package includes 4 times meal, laundry, pick n drop etc.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),

        if (_selectedPlan == "Rent Only") ...[
          Text(
            "Payment Frequency",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _paymentFrequency = "Pay Monthly";
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _paymentFrequency == "Pay Monthly"
                          ? const Color(0xFFEFF6FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _paymentFrequency == "Pay Monthly"
                            ? const Color(0xFF0056D2)
                            : const Color(0xFFE2E8F0),
                        width: _paymentFrequency == "Pay Monthly" ? 2 : 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pay Monthly",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "12 Monthly\nInstallments",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _paymentFrequency = "Whole Year";
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _paymentFrequency == "Whole Year"
                          ? const Color(0xFFEFF6FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _paymentFrequency == "Whole Year"
                            ? const Color(0xFF0056D2)
                            : const Color(0xFFE2E8F0),
                        width: _paymentFrequency == "Whole Year" ? 2 : 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Whole Year",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Custom\nInstallments",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_paymentFrequency == "Whole Year") ...[
            _buildInputLabel("Number of Installments"),
            const SizedBox(height: 6),
            TextField(
              controller: _yearInstallmentsController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration(
                hintText: "4",
                prefixIcon: Icons.format_list_numbered_rounded,
              ),
            ),
            const SizedBox(height: 20),
          ],

          _buildInputLabel("Total Monthly Rent (₹)"),
          const SizedBox(height: 6),
          TextField(
            controller: _monthlyRentController,
            keyboardType: TextInputType.number,
            decoration: _buildInputDecoration(
              hintText: "₹ 12,500",
              prefixIcon: Icons.currency_rupee_rounded,
            ),
          ),
          const SizedBox(height: 18),

          _buildInputLabel("Security Deposit (₹)"),
          const SizedBox(height: 6),
          TextField(
            controller: _securityDepositController,
            keyboardType: TextInputType.number,
            decoration: _buildInputDecoration(
              hintText: "₹ 25,000",
              prefixIcon: Icons.shield_outlined,
            ),
          ),
        ],

        if (_selectedPlan == "Full Package") ...[
          _buildInputLabel("Total Fees for Academic Year (₹)"),
          const SizedBox(height: 6),
          TextField(
            controller: _totalAcademicFeesController,
            keyboardType: TextInputType.number,
            decoration: _buildInputDecoration(
              hintText: "₹ 1,50,000",
              prefixIcon: Icons.payments_outlined,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "Number of Installments",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildInstallmentSegment("Single"),
              const SizedBox(width: 8),
              _buildInstallmentSegment("Quarterly"),
              const SizedBox(width: 8),
              _buildInstallmentSegment("Custom"),
            ],
          ),
          const SizedBox(height: 20),

          if (_packageInstallmentType == "Custom") ...[
            _buildInputLabel("Enter Custom Number of Installments"),
            const SizedBox(height: 6),
            TextField(
              controller: _customInstallmentsController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration(
                hintText: "6",
                prefixIcon: Icons.format_list_numbered_rounded,
              ),
            ),
            const SizedBox(height: 20),
          ],

          _buildInputLabel("Premium Security Deposit (₹)"),
          const SizedBox(height: 6),
          TextField(
            controller: _premiumDepositController,
            keyboardType: TextInputType.number,
            decoration: _buildInputDecoration(
              hintText: "₹ 30,000",
              prefixIcon: Icons.shield_outlined,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Includes amenity protection fee",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
        const SizedBox(height: 28),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Unit Summary",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0056D2),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  "https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=600",
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 140,
                    color: const Color(0xFFCBD5E1),
                    child: const Icon(Icons.business_rounded, color: Colors.white, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Lakshya — Room 101",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Lakshya Residency",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Lease Term",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    "12 Months",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Move-in Date",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    "Sept 1st, 2024",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = 2;
                    });
                    _saveDraftToFirestore();
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(
                    "Back",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0056D2),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0056D2), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _generateInstallmentsFromStep3();
                    setState(() {
                      _currentStep = 4;
                    });
                    _saveDraftToFirestore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056D2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Next Step",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4 OF 5: EMERGENCY CONTACT & PREFERENCES (DYNAMIC INSTALLMENTS)
  // ==========================================
  Widget _buildStep4View() {
    final String secDepositVal = _selectedPlan == "Rent Only"
        ? _securityDepositController.text
        : _premiumDepositController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          "STEP 4 OF 5",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0056D2),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Emergency Contact & Preferences",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.8,
            minHeight: 4,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF0056D2),
          ),
        ),
        const SizedBox(height: 24),

        // Installment Breakdown Schedule Card Container
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Installment Breakdown\nSchedule",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0056D2),
                      height: 1.25,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        final idx = _installments.length + 1;
                        _installments.add({
                          "title": "Installment $idx",
                          "amount": "25000",
                          "dueDate": "24/${idx < 10 ? '0$idx' : '$idx'}/2024",
                        });
                      });
                      _showSnackbar("Added new custom installment!");
                    },
                    icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF0056D2)),
                    label: Text(
                      "Add",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0056D2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Security Deposit: ₹ $secDepositVal | Plan: $_selectedPlan",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // Security Deposit Card (Amber Bordered)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Security Deposit",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Deposit",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Deposit Amount (₹)",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFCD34D)),
                                ),
                                child: Text(
                                  "₹ $secDepositVal",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Due On Check-In",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFCD34D)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "24/08/24",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0056D2)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Dynamic Installment Cards List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _installments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _installments[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: Color(0xFF0056D2), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              item['title'] ?? "Installment ${index + 1}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                              onPressed: () {
                                setState(() {
                                  _installments.removeAt(index);
                                });
                                _showSnackbar("Removed installment.");
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Amount (₹)",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: TextEditingController(text: item['amount']),
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration(hintText: "₹ 25000"),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Due Date / Deadline",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['dueDate'] ?? "24/08/24",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0056D2)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Add Custom Installment Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      final idx = _installments.length + 1;
                      _installments.add({
                        "title": "Installment $idx",
                        "amount": "25000",
                        "dueDate": "24/${idx < 10 ? '0$idx' : '$idx'}/2024",
                      });
                    });
                    _showSnackbar("Added custom installment!");
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFF0056D2)),
                  label: Text(
                    "Add Custom Installment",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0056D2),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0056D2), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Emergency Contact & Preferences Section Title
        Text(
          "Emergency Contact & Preferences",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),

        _buildInputLabel("Guardian / Parent Full Name"),
        const SizedBox(height: 6),
        TextField(
          controller: _guardianNameController,
          decoration: _buildInputDecoration(
            hintText: "Enter guardian name",
            prefixIcon: Icons.badge_outlined,
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Relationship"),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _guardianRelationship,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              items: _relationships.map((String rel) {
                return DropdownMenuItem<String>(
                  value: rel,
                  child: Text(
                    rel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _guardianRelationship = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Emergency Contact Phone (India +91)"),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Text("🇮🇳", style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    "+91",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _guardianPhoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration(
                  hintText: "98765 43210",
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Text(
          "Dietary Preference",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _dietaryPreference = "Vegetarian";
                  });
                },
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _dietaryPreference == "Vegetarian" ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _dietaryPreference == "Vegetarian" ? const Color(0xFF0056D2) : const Color(0xFFE2E8F0),
                      width: _dietaryPreference == "Vegetarian" ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_dietaryPreference == "Vegetarian")
                        const Icon(Icons.check_rounded, color: Color(0xFF0056D2), size: 18),
                      if (_dietaryPreference == "Vegetarian") const SizedBox(width: 6),
                      Text(
                        "Vegetarian",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0056D2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _dietaryPreference = "Non-Veg";
                  });
                },
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _dietaryPreference == "Non-Veg" ? const Color(0xFFFDF2F8) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _dietaryPreference == "Non-Veg" ? const Color(0xFFDB2777) : const Color(0xFFE2E8F0),
                      width: _dietaryPreference == "Non-Veg" ? 1.8 : 1,
                    ),
                  ),
                  child: Text(
                    "Non-Veg",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _dietaryPreference == "Non-Veg" ? const Color(0xFFDB2777) : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Step 4 Actions (Back & Next Step)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = 3;
                    });
                    _saveDraftToFirestore();
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(
                    "Back",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0056D2),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0056D2), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 5;
                    });
                    _saveDraftToFirestore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056D2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Next Step",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 5 OF 5: INVENTORY & FINAL NOTES (IMAGES 3 & 4)
  // ==========================================
  Widget _buildStep5View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "STEP 5 OF 5",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0056D2),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "FINAL REVIEW & INVENTORY",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Inventory & Final Notes",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 1.0,
            minHeight: 4,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF0056D2),
          ),
        ),
        const SizedBox(height: 20),

        // Intro Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            "Document the condition of provided amenities and record any final negotiation details before completing enrollment.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Student Inventory Checklist Container
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_outlined, color: Color(0xFF0056D2), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Student Inventory Checklist",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Select items provided to the student in their room.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // Add Custom Item Input Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customInventoryController,
                      decoration: InputDecoration(
                        hintText: "Add custom item (...)",
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0056D2), width: 1.8),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_customInventoryController.text.trim().isNotEmpty) {
                          setState(() {
                            _inventoryItems.add(_customInventoryController.text.trim());
                            _customInventoryController.clear();
                          });
                          _showSnackbar("Added item to checklist!");
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        "Add",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056D2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Inventory Chip Tags Wrap
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: _inventoryItems.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF0056D2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outlined, size: 16, color: Color(0xFF0056D2)),
                        const SizedBox(width: 6),
                        Text(
                          item,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0056D2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _inventoryItems.remove(item);
                            });
                          },
                          child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF0056D2)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Negotiations & Student Notes Container
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_offer_outlined, color: Color(0xFF0056D2), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Negotiations & Student\nNotes",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Capture rent negotiations, special requests, dietary preferences, or behavioral observations.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _finalNotesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Enter final notes, agreed rent discounts, or special requirements here...",
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.all(14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF0056D2), width: 1.8),
                  ),
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Step 5 Actions (Back & View Summary)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = 4;
                    });
                    _saveDraftToFirestore();
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(
                    "Back",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0056D2),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0056D2), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056D2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "View Summary",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF64748B), size: 20) : null,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF64748B), size: 20) : null,
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: const Color(0xFF94A3B8),
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0056D2), width: 1.8),
      ),
      fillColor: Colors.white,
      filled: true,
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String fileUrl,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final hasFile = fileUrl.isNotEmpty;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: hasFile ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasFile ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: hasFile ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: hasFile ? ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Preview Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: fileUrl.startsWith('http://') || fileUrl.startsWith('https://')
                  ? Image.network(fileUrl, fit: BoxFit.cover)
                  : (fileUrl == 'uploaded'
                      ? Container(
                          color: const Color(0xFFEFF6FF),
                          child: const Icon(
                            Icons.cloud_done_rounded,
                            color: Color(0xFF2563EB),
                            size: 48,
                          ),
                        )
                      : Image.file(File(fileUrl), fit: BoxFit.cover)),
            ),
            // Dark gradient overlay at the bottom/top for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Selected check badge top left
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "Selected",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Remove Button top right
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 18),
                  onPressed: onRemove,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
            // Document Name/Title at the bottom
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Text(
                title.replaceAll("Click to Upload ", ""),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ) : InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0056D2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstallmentSegment(String title) {
    final bool isSelected = _packageInstallmentType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _packageInstallmentType = title;
          });
        },
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0056D2) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? const Color(0xFF0056D2) : const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}
