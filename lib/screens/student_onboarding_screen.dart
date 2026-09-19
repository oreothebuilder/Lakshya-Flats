import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../models/building_model.dart';
import '../services/cloudinary_service.dart';
import '../config/cloudinary_config.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/email_service.dart';
import '../services/navigation_service.dart';
import '../widgets/document_viewer_modal.dart';
import '../services/agreement_pdf_service.dart';
import '../widgets/rental_agreement_dialog.dart';
import '../widgets/app_toast.dart';
import 'Admin/dashboard_screen.dart';

class StudentOnboardingScreen extends StatefulWidget {
  const StudentOnboardingScreen({super.key});

  @override
  State<StudentOnboardingScreen> createState() => _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> {
  // Step State: 0 = Landing/Drafts, 1 = Step 1, 2 = Step 2, 3 = Step 3, 4 = Step 4, 5 = Step 5
  int _currentStep = 0;

  // Step 1 Controllers & State
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _hometownAddressController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();
  final TextEditingController _bedNumberController = TextEditingController();

  // Step 3 Lease Configuration Controllers & State
  String _selectedPlan = "Rent Only"; // "Rent Only" or "Full Package"
  String _paymentFrequency = "Pay Monthly"; // "Pay Monthly" or "Whole Year"
  String _packageInstallmentType = "Quarterly"; // "Single", "Quarterly", "Custom"
  int _packageInstallmentsCount = 4;
  bool _isCustomPackageInstallments = false;

  String _selectedRentTerm = "Complete Year (July to May)";

  static const List<Map<String, String>> _rentTermOptions = [
    {
      "title": "Complete Year (July to May)",
      "badge": "11 Months",
      "rule": "11 month fee irrespective of late joining",
      "monthlySchedule": "1st month rent on date of joining and then from the first of the month",
    },
    {
      "title": "1 Semester Only (July – December)",
      "badge": "6 Months",
      "rule": "6 month fee irrespective of late joining",
      "monthlySchedule": "1st month rent on date of joining and then from the first of the month",
    },
    {
      "title": "Summer Break (May – June)",
      "badge": "2 Months",
      "rule": "2 month fee irrespective of late joining",
      "monthlySchedule": "1st month rent on date of joining and then from the first of the month",
    },
    {
      "title": "Winter Break (December)",
      "badge": "1 Month",
      "rule": "1 month fee irrespective of late joining",
      "monthlySchedule": "Rent on date of joining",
    },
  ];

  int _getRentTermMonths(String term) {
    if (term.contains("Summer")) return 2;
    if (term.contains("Winter")) return 1;
    if (term.contains("Semester") || term.contains("Sem")) return 6;
    return 11;
  }

  String _getRentTermShortName(String term) {
    if (term.contains("Summer")) return "Summer Break";
    if (term.contains("Winter")) return "Winter Break";
    if (term.contains("Semester") || term.contains("Sem")) return "1 Semester";
    return "11-Month Annual";
  }

  String _getRentTermLockInDescription(String term) {
    if (term.contains("Summer")) {
      return "Summer Break (May – June) • 2 Months Lock-in (irrespective of late joining)";
    }
    if (term.contains("Winter")) {
      return "Winter Break (December) • 1 Month Lock-in (irrespective of late joining)";
    }
    if (term.contains("Semester") || term.contains("Sem")) {
      return "1 Semester Only (July – December) • 6 Months Lock-in (irrespective of late joining)";
    }
    return "Complete Year (July to May) • 11 Months Lock-in (irrespective of late joining)";
  }

  String _getRentTermMonthlyScheduleNote(String term) {
    if (term.contains("Summer")) {
      return "2 month fee irrespective of late joining — 1st month rent on date of joining and then from the first of the month";
    }
    if (term.contains("Winter")) {
      return "1 month fee irrespective of late joining — rent due on date of joining";
    }
    if (term.contains("Semester") || term.contains("Sem")) {
      return "6 month fee irrespective of late joining — 1st month rent on date of joining and then from the first of the month";
    }
    return "11 month fee irrespective of late joining — 1st month rent on date of joining and then from the first of the month";
  }

  String _getLockInPeriod() {
    if (_selectedPlan == "Full Package") {
      return "Academic calendar of MUJ — Commencement of odd semester to last exam of even semester (excluding winter and summer break)";
    } else {
      return _getRentTermLockInDescription(_selectedRentTerm);
    }
  }

  final TextEditingController _monthlyRentController = TextEditingController(text: "12,500");
  final TextEditingController _securityDepositController = TextEditingController(text: "25,000");
  final TextEditingController _yearInstallmentsController = TextEditingController(text: "4");
  final TextEditingController _totalAcademicFeesController = TextEditingController(text: "1,50,000");
  final TextEditingController _customInstallmentsController = TextEditingController(text: "4");
  final TextEditingController _premiumDepositController = TextEditingController(text: "30,000");
  String? _selectedBuilding;
  final List<String> _buildings = [
    "Lakshya",
    "Shivalya",
    "Ishaan",
    "Univ homes",
    "Tirupati",
    "Rameshwaram",
    "Livano",
    "Somnath",
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
    "Chair",
    "Geyser",
    "Fan",
    "Curtains",
    "Pillow",
    "Bucket",
    "Mug",
  ];
  final TextEditingController _customInventoryController = TextEditingController();
  final TextEditingController _finalNotesController = TextEditingController();
  final List<String> _attachedNotes = [];

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _profilePhotoBytes;
  String? _profilePhotoUrl;
  bool _isUploadingPhoto = false;
  bool _profilePhotoAddLater = false;
  bool _isSavingStudent = false;

  Uint8List? _collegeIdBytes;
  String? _collegeIdUrl;
  bool _isUploadingCollegeId = false;
  bool _collegeIdAddLater = false;

  Uint8List? _govtIdBytes;
  String? _govtIdUrl;
  bool _isUploadingGovtId = false;
  bool _govtIdAddLater = false;

  bool _profilePhotoUploaded = false;
  bool _collegeIdUploaded = false;
  bool _govtIdUploaded = false;
  final List<Map<String, dynamic>> _savedDrafts = [];
  String? _activeDraftId;

  // Rental Agreement State
  Uint8List? _signedAgreementPdfBytes;
  Uint8List? _signedAgreementSignatureBytes;

  RentalAgreementData _buildRentalAgreementData() {
    final now = DateTime.now();
    final dayStr = now.day.toString().padLeft(2, '0');
    final monthStr = now.month.toString().padLeft(2, '0');
    final dateStr = "$dayStr/$monthStr/${now.year}";

    final int termMonths = _selectedPlan == "Rent Only" ? _getRentTermMonths(_selectedRentTerm) : 10;
    final endDate = DateTime(now.year, now.month + termMonths, now.day);
    final endDayStr = endDate.day.toString().padLeft(2, '0');
    final endMonthStr = endDate.month.toString().padLeft(2, '0');
    final endDateStr = "$endDayStr/$endMonthStr/${endDate.year}";

    final rentalTerm = _selectedPlan == "Rent Only" ? _selectedRentTerm : "Academic calendar of MUJ";
    final lockInPeriod = _getLockInPeriod();

    return RentalAgreementData(
      agreementDate: dateStr,
      commencementDate: dateStr,
      endingDate: endDateStr,
      studentFullName: _fullNameController.text.trim().isNotEmpty ? _fullNameController.text.trim() : "Resident",
      mobileNumber: _mobileController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : "student@university.edu",
      regNumber: _regNoController.text.trim().isNotEmpty ? _regNoController.text.trim() : "N/A",
      course: _courseController.text.trim(),
      branch: _branchController.text.trim(),
      hometownAddress: _hometownAddressController.text.trim(),
      building: _selectedBuilding ?? "Lakshya",
      roomNumber: _roomNumberController.text.trim().isNotEmpty ? _roomNumberController.text.trim() : "Room 101",
      bedNumber: _bedNumberController.text.trim(),
      flatConfig: "2 BHK",
      guardianName: _guardianNameController.text.trim(),
      guardianRelationship: _guardianRelationship,
      guardianPhone: _guardianPhoneController.text.trim(),
      dietaryPreference: _dietaryPreference,
      plan: _selectedPlan,
      rentalTerm: rentalTerm,
      lockInPeriod: lockInPeriod,
      termMonths: termMonths,
      monthlyRent: _monthlyRentController.text.trim(),
      securityDeposit: _securityDepositController.text.trim(),
      paymentFrequency: _paymentFrequency,
      installmentsCount: _installments.length,
      installments: _installments,
      inventoryItems: _inventoryItems,
      notes: _attachedNotes,
      studentSignatureBytes: _signedAgreementSignatureBytes,
      studentPhotoBytes: _profilePhotoBytes,
      collegeIdUploaded: _collegeIdUploaded || _collegeIdBytes != null,
      govtIdUploaded: _govtIdUploaded || _govtIdBytes != null,
    );
  }

  final List<String> _relationships = ["Father", "Mother", "Guardian", "Sibling", "Other"];

  String _getBuildingAsset(String? buildingName) {
    if (buildingName == null) return "assets/buildings/Lakshya.png";
    final b = buildingName.toLowerCase().replaceAll(' ', '');
    if (b.contains('ishaan')) return "assets/buildings/Ishaan.png";
    if (b.contains('shival')) return "assets/buildings/Shivalay.png";
    if (b.contains('univ')) return "assets/buildings/univhomes.png";
    if (b.contains('tirupati')) return "assets/buildings/Tirupati.png";
    if (b.contains('rameshwaram')) return "assets/buildings/Rameshwaram.png";
    if (b.contains('livano')) return "assets/buildings/Livano.png";
    if (b.contains('somnath')) return "assets/buildings/Somnath.png";
    return "assets/buildings/Lakshya.png";
  }

  StreamSubscription<List<BuildingModel>>? _buildingsSub;

  @override
  void initState() {
    super.initState();
    _generateInstallmentsFromStep3();
    _loadDynamicBuildings();
  }

  void _loadDynamicBuildings() {
    _buildingsSub = FirestoreService().getBuildingsStream().listen((buildings) {
      if (!mounted) return;
      setState(() {
        for (final b in buildings) {
          final n = b.name.trim();
          if (n.isNotEmpty && !_buildings.any((existing) => existing.toLowerCase() == n.toLowerCase())) {
            _buildings.add(n);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _buildingsSub?.cancel();
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _regNoController.dispose();
    _courseController.dispose();
    _branchController.dispose();
    _hometownAddressController.dispose();
    _roomNumberController.dispose();
    _bedNumberController.dispose();
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
    final now = DateTime.now();

    if (_selectedPlan == "Rent Only") {
      int monthlyRent = int.tryParse(_monthlyRentController.text.replaceAll(',', '').replaceAll('₹', '').trim()) ?? 12500;
      final termMonths = _getRentTermMonths(_selectedRentTerm);

      if (_paymentFrequency == "Pay Monthly") {
        count = termMonths;
        for (int i = 1; i <= count; i++) {
          final instDate = (i == 1)
              ? now // 1st month rent on date of joining
              : DateTime(now.year, now.month + (i - 1), 1); // then from 1st of the month
          final dayStr = instDate.day.toString().padLeft(2, '0');
          final monthStr = instDate.month.toString().padLeft(2, '0');
          final title = count == 1
              ? "Rent (${_getRentTermShortName(_selectedRentTerm)})"
              : "Month $i Rent (${_getRentTermShortName(_selectedRentTerm)})";
          _installments.add(<String, String>{
            "title": title,
            "amount": "$monthlyRent",
            "dueDate": "$dayStr/$monthStr/${instDate.year}",
          });
        }
      } else {
        count = int.tryParse(_yearInstallmentsController.text.trim()) ?? 1;
        if (count < 1) count = 1;
        final totalTermAmount = monthlyRent * termMonths;
        int instAmount = totalTermAmount ~/ count;
        int remainder = totalTermAmount % count;
        final stepMonths = (termMonths / count).round().clamp(1, 12);
        for (int i = 1; i <= count; i++) {
          int currentInst = (i == 1) ? (instAmount + remainder) : instAmount;
          final instDate = (i == 1)
              ? now // Due on date of joining
              : DateTime(now.year, now.month + (i - 1) * stepMonths, 1);
          final dayStr = instDate.day.toString().padLeft(2, '0');
          final monthStr = instDate.month.toString().padLeft(2, '0');
          final title = count == 1
              ? "Full Term Fee (${_getRentTermShortName(_selectedRentTerm)})"
              : "Installment $i (${_getRentTermShortName(_selectedRentTerm)})";
          _installments.add(<String, String>{
            "title": title,
            "amount": "$currentInst",
            "dueDate": "$dayStr/$monthStr/${instDate.year}",
          });
        }
      }
    } else {
      // Full Package
      int totalAmount = int.tryParse(_totalAcademicFeesController.text.replaceAll(',', '').replaceAll('₹', '').trim()) ?? 150000;
      count = _packageInstallmentsCount > 0 ? _packageInstallmentsCount : 1;

      int instAmount = totalAmount ~/ count;
      int remainder = totalAmount % count;
      final stepMonths = (12 / count).round().clamp(1, 12);

      for (int i = 1; i <= count; i++) {
        int currentInst = (i == 1) ? (instAmount + remainder) : instAmount;
        final instDate = DateTime(now.year, now.month + (i - 1) * stepMonths, 10);
        final dayStr = instDate.day.toString().padLeft(2, '0');
        final monthStr = instDate.month.toString().padLeft(2, '0');
        _installments.add(<String, String>{
          "title": "Installment $i",
          "amount": "$currentInst",
          "dueDate": "$dayStr/$monthStr/${instDate.year}",
        });
      }
    }
  }

  Widget _buildInstallmentOptionChip(String label, int count) {
    final bool isSelected = (count == -1)
        ? _isCustomPackageInstallments
        : (!_isCustomPackageInstallments && _packageInstallmentsCount == count);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (count == -1) {
            _isCustomPackageInstallments = true;
            _packageInstallmentsCount = int.tryParse(_customInstallmentsController.text.trim()) ?? 4;
          } else {
            _isCustomPackageInstallments = false;
            _packageInstallmentsCount = count;
            _customInstallmentsController.text = "$count";
          }
          _generateInstallmentsFromStep3();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0056D2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0056D2) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0056D2).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageBreakdownBanner() {
    int total = int.tryParse(_totalAcademicFeesController.text.replaceAll(',', '').replaceAll('₹', '').trim()) ?? 150000;
    int count = _packageInstallmentsCount > 0 ? _packageInstallmentsCount : 1;
    int perInst = total ~/ count;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF0056D2), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Schedule: ₹ $perInst / installment ($count ${_packageInstallmentsCount == 1 ? 'installment' : 'installments'})",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false, bool isSuccess = true}) {
    final bool errorMode = isError || !isSuccess;
    AppToast.show(context, message, isSuccess: !errorMode);
  }

  Future<void> _capturePhotoFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo == null) return; // User closed camera

      final bytes = await photo.readAsBytes();
      setState(() {
        _profilePhotoBytes = bytes;
        _isUploadingPhoto = true;
      });

      _showSnackbar("Photo captured! Uploading...");

      // Attempt Cloudinary upload
      final uploadedUrl = await CloudinaryService.uploadImage(
        photo,
        folder: CloudinaryConfig.folderStudentAvatars,
      );

      setState(() {
        _isUploadingPhoto = false;
        _profilePhotoUploaded = true;
        _profilePhotoUrl = uploadedUrl;
      });

      if (uploadedUrl != null) {
        _showSnackbar("Resident photo uploaded successfully!");
      } else {
        _showSnackbar("Photo captured and attached to profile!");
      }
    } catch (e) {
      setState(() {
        _isUploadingPhoto = false;
      });
      _showSnackbar("Could not access camera: $e", isError: true);
    }
  }

  Future<void> _handleUploadDocument({
    required String documentType,
    required ImageSource source,
  }) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (documentType == "College ID") {
        setState(() {
          _collegeIdBytes = bytes;
          _isUploadingCollegeId = true;
        });
      } else {
        setState(() {
          _govtIdBytes = bytes;
          _isUploadingGovtId = true;
        });
      }

      _showSnackbar("Uploading $documentType...");

      final uploadedUrl = await CloudinaryService.uploadImage(
        file,
        folder: CloudinaryConfig.folderStudentDocs,
      );

      setState(() {
        if (documentType == "College ID") {
          _isUploadingCollegeId = false;
          _collegeIdUploaded = true;
          _collegeIdUrl = uploadedUrl;
        } else {
          _isUploadingGovtId = false;
          _govtIdUploaded = true;
          _govtIdUrl = uploadedUrl;
        }
      });

      if (uploadedUrl != null) {
        _showSnackbar("$documentType uploaded successfully!");
      } else {
        _showSnackbar("$documentType captured and saved!");
      }
    } catch (e) {
      setState(() {
        if (documentType == "College ID") {
          _isUploadingCollegeId = false;
        } else {
          _isUploadingGovtId = false;
        }
      });
      _showSnackbar("Could not access camera/file: $e", isError: true);
    }
  }

  Future<void> _handleUploadPdfDocument({required String documentType}) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (file == null) return;
      final bytes = await file.readAsBytes();

      if (documentType == "College ID") {
        setState(() {
          _collegeIdBytes = bytes;
          _isUploadingCollegeId = true;
        });
      } else {
        setState(() {
          _govtIdBytes = bytes;
          _isUploadingGovtId = true;
        });
      }

      _showSnackbar("Uploading $documentType PDF to cloud...");

      final uploadedUrl = await CloudinaryService.uploadPlatformFile(
        file,
        folder: CloudinaryConfig.folderStudentDocs,
      );

      setState(() {
        if (documentType == "College ID") {
          _isUploadingCollegeId = false;
          _collegeIdUploaded = uploadedUrl != null;
          _collegeIdUrl = uploadedUrl;
        } else {
          _isUploadingGovtId = false;
          _govtIdUploaded = uploadedUrl != null;
          _govtIdUrl = uploadedUrl;
        }
      });

      if (uploadedUrl != null) {
        _showSnackbar("$documentType PDF uploaded successfully!");
      } else {
        _showSnackbar("Could not upload PDF. Please check connection.", isError: true);
      }
    } catch (e) {
      setState(() {
        if (documentType == "College ID") {
          _isUploadingCollegeId = false;
        } else {
          _isUploadingGovtId = false;
        }
      });
      _showSnackbar("Error picking PDF: $e", isError: true);
    }
  }

  void _showDocumentSourceSheet(String documentType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Upload $documentType",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0056D2), size: 22),
                ),
                title: Text(
                  "Take Photo with Camera",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                subtitle: Text(
                  "Use device camera to capture document",
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleUploadDocument(documentType: documentType, source: ImageSource.camera);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF475569), size: 22),
                ),
                title: Text(
                  "Choose Image from Gallery",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                subtitle: Text(
                  "Select JPG or PNG image from device",
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleUploadDocument(documentType: documentType, source: ImageSource.gallery);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 22),
                ),
                title: Text(
                  "Select PDF Document",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                subtitle: Text(
                  "Upload official PDF document or agreement",
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleUploadPdfDocument(documentType: documentType);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCompleteOnboarding() async {
    if (_isSavingStudent) return;
    setState(() => _isSavingStudent = true);

    final fullName = _fullNameController.text.trim().isNotEmpty ? _fullNameController.text.trim() : "Resident";
    final firstName = fullName.split(' ').first;
    final email = _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : "student@university.edu";
    final phone = _mobileController.text.trim();
    final regNo = _regNoController.text.trim().isNotEmpty ? _regNoController.text.trim() : "REG101";
    final course = _courseController.text.trim();
    final branch = _branchController.text.trim();
    final building = _selectedBuilding ?? "Lakshya Residency";
    final room = _roomNumberController.text.trim().isNotEmpty ? _roomNumberController.text.trim() : "Room 101";
    final bedNumber = _bedNumberController.text.trim();
    final defaultPassword = "$firstName@$regNo";

    // Show non-dismissible loading dialog immediately during the async creation/email delay
    BuildContext? loadingDialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dlgCtx) {
        loadingDialogContext = dlgCtx;
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 46,
                    height: 46,
                    child: CircularProgressIndicator(
                      color: Color(0xFF0056D2),
                      strokeWidth: 3.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Creating Student Account...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Saving profile, generating bills, and dispatching login credentials email...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final studentId = "STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      // 1A. Upload Signed Rental Agreement PDF to Cloudinary
      String? agreementUrl;
      Uint8List? agreementBytes = _signedAgreementPdfBytes;
      if (agreementBytes == null) {
        try {
          final agreementData = _buildRentalAgreementData();
          agreementBytes = await AgreementPdfService.generateAgreementPdf(agreementData);
        } catch (genErr) {
          debugPrint("Agreement generation fallback error: $genErr");
        }
      }

      if (agreementBytes != null && agreementBytes.isNotEmpty) {
        try {
          agreementUrl = await CloudinaryService.uploadBytes(
            agreementBytes,
            fileName: 'agreement_$studentId.pdf',
            folder: 'agreements',
          );
        } catch (uploadErr) {
          debugPrint("Agreement upload error: $uploadErr");
        }
      }

      // 1B. Save student record to Firestore
      await FirestoreService().saveStudentProfile(studentId, {
        'studentId': studentId,
        'fullName': fullName,
        'firstName': firstName,
        'email': email,
        'phone': phone,
        'registrationNumber': regNo,
        'course': course,
        'branch': branch,
        'hometownAddress': _hometownAddressController.text.trim(),
        'address': _hometownAddressController.text.trim(),
        'building': building,
        'room': room,
        'bedNumber': bedNumber,
        'plan': _selectedPlan,
        'rentalTerm': _selectedRentTerm,
        'lockInPeriod': _getLockInPeriod(),
        'paymentFrequency': _paymentFrequency,
        'monthlyRent': _monthlyRentController.text.trim(),
        'securityDeposit': _securityDepositController.text.trim(),
        'guardianName': _guardianNameController.text.trim(),
        'guardianPhone': _guardianPhoneController.text.trim(),
        'guardianRelationship': _guardianRelationship,
        'dietaryPreference': _dietaryPreference,
        'photoUrl': _profilePhotoUrl,
        'collegeIdUrl': _collegeIdUrl,
        'govtIdUrl': _govtIdUrl,
        'rentAgreementUrl': agreementUrl,
        'agreementSignedAt': DateTime.now().toIso8601String(),
        'agreementSignedBy': fullName,
        'photoAddLater': _profilePhotoAddLater,
        'collegeIdAddLater': _collegeIdAddLater,
        'govtIdAddLater': _govtIdAddLater,
        'inventory': _inventoryItems,
        'notes': _attachedNotes,
        'installments': _installments,
        'defaultPassword': defaultPassword,
        'status': 'Active',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 2. Auto-issue initial bills to Firestore
      // 2A. Security Deposit bill (if applicable)
      final depositAmount = double.tryParse(_securityDepositController.text.replaceAll(',', '').replaceAll('₹', '').trim()) ?? 0.0;
      if (depositAmount > 0) {
        try {
          await FirestoreService().issueBill({
            'studentId': studentId,
            'studentName': fullName,
            'phone': phone,
            'building': building,
            'room': room,
            'bedNumber': bedNumber,
            'billType': 'Security Deposit',
            'amount': depositAmount,
            'paidAmount': 0.0,
            'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
            'status': 'Pending',
            'invoiceNo': 'INV-DEP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
            'billingMonth': 'Security Deposit',
          });
        } catch (billErr) {
          debugPrint("Initial deposit bill error: $billErr");
        }
      }

      // 2B. Auto-issue individual bills for EVERY selected installment so they appear on Collect Payments page
      if (_installments.isNotEmpty) {
        for (int i = 0; i < _installments.length; i++) {
          final inst = _installments[i];
          final title = inst['title']?.toString() ?? "Installment ${i + 1}";
          final amount = double.tryParse(inst['amount'].toString().replaceAll(',', '').replaceAll('₹', '').trim()) ?? 0.0;
          
          Timestamp instDueDate;
          if (inst['dueDateTimestamp'] is Timestamp) {
            instDueDate = inst['dueDateTimestamp'] as Timestamp;
          } else if (inst['dueDate'] != null) {
            final parts = inst['dueDate'].toString().split('/');
            if (parts.length == 3) {
              final d = int.tryParse(parts[0]) ?? 10;
              final m = int.tryParse(parts[1]) ?? 1;
              final y = int.tryParse(parts[2]) ?? DateTime.now().year;
              instDueDate = Timestamp.fromDate(DateTime(y, m, d, 23, 59, 59));
            } else {
              instDueDate = Timestamp.fromDate(DateTime.now().add(Duration(days: (i * 30) + 10)));
            }
          } else {
            instDueDate = Timestamp.fromDate(DateTime.now().add(Duration(days: (i * 30) + 10)));
          }

          if (amount > 0) {
            try {
              final invSuffix = (DateTime.now().millisecondsSinceEpoch + i + 10).toString().substring(7);
              await FirestoreService().issueBill({
                'studentId': studentId,
                'studentName': fullName,
                'phone': phone,
                'building': building,
                'room': room,
                'bedNumber': bedNumber,
                'billType': 'Hostel Fees',
                'amount': amount,
                'paidAmount': 0.0,
                'dueDate': instDueDate,
                'status': 'Pending',
                'invoiceNo': 'INV-INST-$invSuffix',
                'billingMonth': title,
              });
            } catch (billErr) {
              debugPrint("Installment bill error ($title): $billErr");
            }
          }
        }
      } else {
        // Fallback if installments list was empty
        final rentAmount = double.tryParse(_monthlyRentController.text.replaceAll(',', '').replaceAll('₹', '').trim()) ?? 0.0;
        if (rentAmount > 0) {
          try {
            await FirestoreService().issueBill({
              'studentId': studentId,
              'studentName': fullName,
              'phone': phone,
              'building': building,
              'room': room,
              'bedNumber': bedNumber,
              'billType': 'Hostel Fees',
              'amount': rentAmount,
              'paidAmount': 0.0,
              'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 15))),
              'status': 'Pending',
              'invoiceNo': 'INV-${(DateTime.now().millisecondsSinceEpoch + 1).toString().substring(7)}',
              'billingMonth': 'Installment 1',
            });
          } catch (billErr) {
            debugPrint("Fallback rent bill error: $billErr");
          }
        }
      }

      // 3. Register user with default password (firstName@regNo) in Auth
      try {
        await FirebaseAuthService().createStudentAuthAccount(
          email: email,
          password: defaultPassword,
        );
      } catch (authErr) {
        debugPrint("Auth notice: $authErr");
      }

      // 4. Send official account credentials email via EmailService
      try {
        await EmailService().sendStudentCredentialsEmail(
          studentEmail: email,
          studentName: fullName,
          registrationNumber: regNo,
          password: defaultPassword,
          building: building,
          room: room,
          bedNumber: bedNumber,
          course: course,
          branch: branch,
        );
      } catch (emailErr) {
        debugPrint("Credentials email dispatch error: $emailErr");
      }

      // 5. Remove active cloud draft if student completed onboarding
      if (_activeDraftId != null) {
        try {
          await FirestoreService().deleteDraftFromCloud(_activeDraftId!);
        } catch (_) {}
        _activeDraftId = null;
      }
    } catch (e) {
      debugPrint("Storage notice: $e");
    } finally {
      if (loadingDialogContext != null && loadingDialogContext!.mounted) {
        Navigator.of(loadingDialogContext!).pop();
      }
      if (mounted) setState(() => _isSavingStudent = false);
    }

    if (!mounted) return;

    // Show credential confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Onboarding Complete!",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "Profile stored & password mailed",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                    tooltip: "Close & Go to Home",
                    onPressed: () {
                      _resetForm();
                      setState(() => _currentStep = 0);
                      Navigator.pop(dialogContext);
                      final nav = rootNavigatorKey.currentState ?? Navigator.of(context);
                      nav.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Email Confirmation Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.mark_email_read_rounded, color: Color(0xFF0056D2), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Password Confirmation Email Sent!\n",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: const Color(0xFF003896),
                              ),
                            ),
                            TextSpan(
                              text: "The student will receive an email confirming their login credentials at ",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                            TextSpan(
                              text: email,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: const Color(0xFF003896),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Credentials Card
              Text(
                "Student Login Credentials",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Username / Email",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            email,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Password",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Sent to student's mail",
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF003896),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Summary Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "$fullName • $regNo",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "$building ($room${bedNumber.isNotEmpty ? ' • Bed: $bedNumber' : ''})",
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action buttons
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                              text: "Lakshya Residency Resident Login:\nUsername / Email: $email\nRegistration No: $regNo\nRoom: $room${bedNumber.isNotEmpty ? ' (Bed: $bedNumber)' : ''}\nNote: Password sent to $email",
                            ));
                            _showSnackbar("Login details copied to clipboard!");
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Copy",
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            _showSnackbar("Re-dispatching credentials email to $email...");
                            final res = await EmailService().sendStudentCredentialsEmail(
                              studentEmail: email,
                              studentName: fullName,
                              registrationNumber: regNo,
                              password: defaultPassword,
                              building: building,
                              room: room,
                              bedNumber: bedNumber,
                              course: course,
                              branch: branch,
                            );
                            if (res['success'] == true) {
                              _showSnackbar(res['message']?.toString() ?? "Credentials email re-sent successfully to $email!");
                            } else {
                              _showSnackbar("Failed to send: ${res['message']}", isSuccess: false);
                            }
                          },
                          icon: const Icon(Icons.mark_email_read_outlined, size: 16),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Resend Email",
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Color(0xFF0056D2)),
                            foregroundColor: const Color(0xFF0056D2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _resetForm();
                        setState(() => _currentStep = 0);
                        Navigator.pop(dialogContext);
                        final nav = rootNavigatorKey.currentState ?? Navigator.of(context);
                        nav.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056D2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "Done & Finish",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackNavigation() async {
    if (_isSavingStudent) return;
    if (_currentStep == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (route) => false,
      );
      return;
    }

    final hasData = _fullNameController.text.trim().isNotEmpty ||
        _mobileController.text.trim().isNotEmpty ||
        _emailController.text.trim().isNotEmpty ||
        _regNoController.text.trim().isNotEmpty ||
        _profilePhotoBytes != null ||
        _collegeIdBytes != null ||
        _govtIdBytes != null ||
        _currentStep > 1;

    if (!hasData) {
      setState(() => _currentStep = 0);
      return;
    }

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
        actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bookmark_border_rounded, color: Color(0xFF0056D2), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Save as Draft?",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "You are currently filling out the student onboarding form. Would you like to save your progress as a draft to resume later, or continue editing?",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(dialogCtx, 'save'),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    "Save as Draft",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056D2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogCtx, 'continue'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    "Continue Editing",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, 'discard'),
                child: Text(
                  "Discard Changes & Exit",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (action == 'save') {
      _saveDraft();
    } else if (action == 'discard') {
      _resetForm();
      setState(() => _currentStep = 0);
    }
  }

  Future<void> _saveDraft() async {
    final fullName = _fullNameController.text.trim().isNotEmpty
        ? _fullNameController.text.trim()
        : "Draft Resident Application";
    final building = _selectedBuilding ?? "Lakshya";
    final room = _roomNumberController.text.trim().isNotEmpty ? _roomNumberController.text.trim() : "TBD";

    final draftId = _activeDraftId ?? 'DRAFT-${DateTime.now().millisecondsSinceEpoch}';
    _activeDraftId = draftId;

    final newDraft = {
      'id': draftId,
      'fullName': _fullNameController.text,
      'mobile': _mobileController.text,
      'email': _emailController.text,
      'regNo': _regNoController.text,
      'course': _courseController.text,
      'branch': _branchController.text,
      'hometownAddress': _hometownAddressController.text,
      'roomNumber': _roomNumberController.text,
      'selectedBuilding': _selectedBuilding,
      'selectedPlan': _selectedPlan,
      'selectedRentTerm': _selectedRentTerm,
      'paymentFrequency': _paymentFrequency,
      'packageInstallmentType': _packageInstallmentType,
      'monthlyRent': _monthlyRentController.text,
      'securityDeposit': _securityDepositController.text,
      'yearInstallments': _yearInstallmentsController.text,
      'totalAcademicFees': _totalAcademicFeesController.text,
      'customInstallments': _customInstallmentsController.text,
      'premiumDeposit': _premiumDepositController.text,
      'guardianName': _guardianNameController.text,
      'guardianPhone': _guardianPhoneController.text,
      'guardianRelationship': _guardianRelationship,
      'dietaryPreference': _dietaryPreference,
      'profilePhotoUrl': _profilePhotoUrl,
      'profilePhotoUploaded': _profilePhotoUploaded,
      'collegeIdUrl': _collegeIdUrl,
      'collegeIdUploaded': _collegeIdUploaded,
      'govtIdUrl': _govtIdUrl,
      'govtIdUploaded': _govtIdUploaded,
      'savedStep': _currentStep > 0 ? _currentStep : 1,
      'lastSaved': DateTime.now().toIso8601String(),
      'displayName': fullName,
      'subtitle': "Saved at Step ${_currentStep > 0 ? _currentStep : 1} • $building ($room)",
    };

    try {
      await FirestoreService().saveDraftToCloud(draftId, newDraft);
    } catch (e) {
      debugPrint("Draft cloud save error: $e");
    }

    setState(() {
      _savedDrafts.removeWhere((d) => d['id'] == draftId || (d['fullName'] == _fullNameController.text && _fullNameController.text.isNotEmpty));
      _savedDrafts.insert(0, newDraft);
      _currentStep = 0;
    });

    _showSnackbar("Application saved to cloud drafts!");
  }

  void _resumeDraft(Map<String, dynamic> draft) {
    _activeDraftId = draft['id']?.toString();
    setState(() {
      _fullNameController.text = draft['fullName'] ?? "";
      _mobileController.text = draft['mobile'] ?? "";
      _emailController.text = draft['email'] ?? "";
      _regNoController.text = draft['regNo'] ?? "";
      _courseController.text = draft['course'] ?? "";
      _branchController.text = draft['branch'] ?? "";
      _hometownAddressController.text = draft['hometownAddress'] ?? draft['address'] ?? "";
      _roomNumberController.text = draft['roomNumber'] ?? "";
      _bedNumberController.text = draft['bedNumber'] ?? "";
      _selectedBuilding = draft['selectedBuilding'];
      if (_selectedBuilding != null && _selectedBuilding!.isNotEmpty) {
        if (!_buildings.contains(_selectedBuilding)) {
          _buildings.add(_selectedBuilding!);
        }
      }
      _selectedPlan = draft['selectedPlan'] ?? "Rent Only";
      _selectedRentTerm = draft['selectedRentTerm'] ?? "Complete Year (July to May)";
      _paymentFrequency = draft['paymentFrequency'] ?? "Pay Monthly";
      _packageInstallmentType = draft['packageInstallmentType'] ?? "Single";
      _monthlyRentController.text = draft['monthlyRent'] ?? "12,500";
      _securityDepositController.text = draft['securityDeposit'] ?? "25,000";
      _yearInstallmentsController.text = draft['yearInstallments'] ?? "4";
      _totalAcademicFeesController.text = draft['totalAcademicFees'] ?? "1,50,000";
      _customInstallmentsController.text = draft['customInstallments'] ?? "6";
      _premiumDepositController.text = draft['premiumDeposit'] ?? "30,000";
      _guardianNameController.text = draft['guardianName'] ?? "";
      _guardianPhoneController.text = draft['guardianPhone'] ?? "";
      _guardianRelationship = draft['guardianRelationship'] ?? "Father";
      _dietaryPreference = draft['dietaryPreference'] ?? "Vegetarian";
      _profilePhotoBytes = null;
      _profilePhotoUrl = draft['profilePhotoUrl'];
      _profilePhotoUploaded = draft['profilePhotoUploaded'] ?? (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty);
      _collegeIdBytes = null;
      _collegeIdUrl = draft['collegeIdUrl'];
      _collegeIdUploaded = draft['collegeIdUploaded'] ?? (_collegeIdUrl != null && _collegeIdUrl!.isNotEmpty);
      _govtIdBytes = null;
      _govtIdUrl = draft['govtIdUrl'];
      _govtIdUploaded = draft['govtIdUploaded'] ?? (_govtIdUrl != null && _govtIdUrl!.isNotEmpty);
      _currentStep = draft['savedStep'] ?? 1;
    });

    _generateInstallmentsFromStep3();
    _showSnackbar("Resumed draft for ${draft['displayName'] ?? 'Resident'}");
  }

  Future<void> _deleteDraft(String draftId) async {
    try {
      await FirestoreService().deleteDraftFromCloud(draftId);
    } catch (_) {}
    setState(() {
      _savedDrafts.removeWhere((d) => d['id'] == draftId);
    });
    _showSnackbar("Draft removed from cloud.");
  }

  void _resetForm() {
    _fullNameController.clear();
    _mobileController.clear();
    _emailController.clear();
    _regNoController.clear();
    _courseController.clear();
    _branchController.clear();
    _hometownAddressController.clear();
    _roomNumberController.clear();
    _bedNumberController.clear();
    _selectedBuilding = null;
    _selectedPlan = "Rent Only";
    _paymentFrequency = "Pay Monthly";
    _profilePhotoBytes = null;
    _profilePhotoUrl = null;
    _profilePhotoUploaded = false;
    _profilePhotoAddLater = false;
    _collegeIdBytes = null;
    _collegeIdUrl = null;
    _collegeIdUploaded = false;
    _collegeIdAddLater = false;
    _govtIdBytes = null;
    _govtIdUrl = null;
    _govtIdUploaded = false;
    _govtIdAddLater = false;
    _guardianNameController.clear();
    _guardianPhoneController.clear();
    _inventoryItems.clear();
    _inventoryItems.addAll([
      "AC",
      "Bed",
      "Cupboard",
      "Study Table",
      "Chair",
      "Geyser",
      "Fan",
      "Curtains",
      "Pillow",
      "Bucket",
      "Mug",
    ]);
    _attachedNotes.clear();
    _finalNotesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: _handleBackNavigation,
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
          child: AbsorbPointer(
            absorbing: _isSavingStudent,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _buildCurrentView(),
            ),
          ),
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
          stream: FirestoreService().getDraftsStream(),
          builder: (context, snapshot) {
            final cloudDrafts = snapshot.data ?? _savedDrafts;

            if (cloudDrafts.isNotEmpty) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cloudDrafts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final draft = cloudDrafts[index];
                  final draftId = draft['id']?.toString() ?? "";
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
                                draft['displayName'] ?? draft['fullName'] ?? "Draft Resident",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                draft['subtitle'] ?? "Saved at Step ${draft['savedStep'] ?? 1}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                              onPressed: () => _deleteDraft(draftId),
                            ),
                            ElevatedButton(
                              onPressed: () => _resumeDraft(draft),
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
                      ],
                    ),
                  );
                },
              );
            }

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
                    "When you start onboarding a student and save as draft, progress will appear here.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
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
            border: Border.all(
              color: _profilePhotoBytes != null ? const Color(0xFF0056D2) : const Color(0xFFE2E8F0),
              width: _profilePhotoBytes != null ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFEEF2FF),
                    backgroundImage: _profilePhotoBytes != null ? MemoryImage(_profilePhotoBytes!) : null,
                    child: _isUploadingPhoto
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF0056D2),
                            ),
                          )
                        : (_profilePhotoBytes == null
                            ? Icon(
                                _profilePhotoUploaded ? Icons.check_circle_rounded : Icons.person_rounded,
                                size: 34,
                                color: _profilePhotoUploaded ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                              )
                            : null),
                  ),
                  if (_profilePhotoBytes != null && !_isUploadingPhoto)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "Upload Resident Photo",
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (_profilePhotoBytes != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Ready",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isUploadingPhoto
                          ? "Uploading to server..."
                          : (_profilePhotoBytes != null
                              ? "Photo attached. You can retake if needed."
                              : "Take photo via camera or select from device"),
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
                          onPressed: _isUploadingPhoto ? null : _capturePhotoFromCamera,
                          icon: _isUploadingPhoto
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_alt_rounded, size: 16),
                          label: Text(
                            _profilePhotoBytes != null ? "Retake Photo" : "Choose Photo",
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
                        if (_profilePhotoBytes != null)
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _profilePhotoBytes = null;
                                _profilePhotoUrl = null;
                                _profilePhotoUploaded = false;
                                _profilePhotoAddLater = false;
                              });
                              _showSnackbar("Photo removed");
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.redAccent),
                            label: Text(
                              "Remove",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _profilePhotoAddLater = !_profilePhotoAddLater;
                              });
                              if (_profilePhotoAddLater) {
                                _showSnackbar("Profile photo marked as 'Add Later'.");
                              }
                            },
                            icon: Icon(
                              _profilePhotoAddLater ? Icons.check_circle_rounded : Icons.access_time_rounded,
                              size: 15,
                              color: _profilePhotoAddLater ? const Color(0xFF16A34A) : const Color(0xFF475569),
                            ),
                            label: Text(
                              _profilePhotoAddLater ? "Marked: Add Later" : "Add Later",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _profilePhotoAddLater ? const Color(0xFF16A34A) : const Color(0xFF475569),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _profilePhotoAddLater ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: _profilePhotoAddLater ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                                ),
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

        _buildInputLabel("Full Name *"),
        const SizedBox(height: 6),
        TextField(
          controller: _fullNameController,
          decoration: _buildInputDecoration(
            hintText: "Enter your legal full name (Mandatory)",
            prefixIcon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Mobile Number (India +91) *"),
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
                  hintText: "10-digit mobile number",
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Email ID *"),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration(
            hintText: "student@university.edu (Compulsory)",
            prefixIcon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("College Registration Number *"),
        const SizedBox(height: 6),
        TextField(
          controller: _regNoController,
          decoration: _buildInputDecoration(
            hintText: "Registration or Roll number (Compulsory)",
            prefixIcon: Icons.badge_outlined,
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Course *"),
        const SizedBox(height: 6),
        TextField(
          controller: _courseController,
          decoration: _buildInputDecoration(
            hintText: "e.g. B.Tech / B.Sc / MBA (Compulsory)",
            prefixIcon: Icons.school_outlined,
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Branch / Specialization *"),
        const SizedBox(height: 6),
        TextField(
          controller: _branchController,
          decoration: _buildInputDecoration(
            hintText: "e.g. Computer Science & Engineering / AI & ML",
            prefixIcon: Icons.account_tree_outlined,
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Hometown Address *"),
        const SizedBox(height: 6),
        TextField(
          controller: _hometownAddressController,
          maxLines: 2,
          decoration: _buildInputDecoration(
            hintText: "e.g. House No., Street, City, State, PIN Code",
            prefixIcon: Icons.home_outlined,
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (_profilePhotoBytes == null && !_profilePhotoUploaded && !_profilePhotoAddLater) {
                _showSnackbar("Please upload Profile Photo or select 'Add Later'", isSuccess: false);
                return;
              }
              if (_fullNameController.text.trim().isEmpty) {
                _showSnackbar("Please enter student's legal full name", isSuccess: false);
                return;
              }
              final phoneDigits = _mobileController.text.trim().replaceAll(RegExp(r'\D'), '');
              if (phoneDigits.length < 10) {
                _showSnackbar("Please enter a valid 10-digit mobile number", isSuccess: false);
                return;
              }
              if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
                _showSnackbar("Please enter a valid email address", isSuccess: false);
                return;
              }
              if (_regNoController.text.trim().isEmpty) {
                _showSnackbar("Please enter College Registration Number", isSuccess: false);
                return;
              }
              if (_courseController.text.trim().isEmpty) {
                _showSnackbar("Please enter Course", isSuccess: false);
                return;
              }
              if (_branchController.text.trim().isEmpty) {
                _showSnackbar("Please enter Branch / Specialization", isSuccess: false);
                return;
              }
              if (_hometownAddressController.text.trim().isEmpty) {
                _showSnackbar("Please enter student's hometown address", isSuccess: false);
                return;
              }
              setState(() {
                _currentStep = 2;
              });
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

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "College ID Card *",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _collegeIdAddLater = !_collegeIdAddLater;
                });
                if (_collegeIdAddLater) {
                  _showSnackbar("College ID marked as 'Add Later'.");
                }
              },
              icon: Icon(
                _collegeIdAddLater ? Icons.check_circle_rounded : Icons.access_time_rounded,
                size: 13,
                color: _collegeIdAddLater ? const Color(0xFF16A34A) : const Color(0xFF475569),
              ),
              label: Text(
                _collegeIdAddLater ? "Marked: Add Later" : "Add Later",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _collegeIdAddLater ? const Color(0xFF16A34A) : const Color(0xFF475569),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _collegeIdAddLater ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: _collegeIdAddLater ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildUploadCard(
          title: _collegeIdAddLater ? "College ID (Marked for Add Later)" : "Click to Upload College ID Card",
          subtitle: "📸 Camera, 📁 Gallery, or 📄 PDF Document",
          icon: Icons.note_add_rounded,
          iconBg: const Color(0xFFEEF2FF),
          iconColor: const Color(0xFF4F46E5),
          isUploaded: _collegeIdUploaded,
          isUploading: _isUploadingCollegeId,
          previewBytes: _collegeIdBytes,
          uploadedUrl: _collegeIdUrl,
          onTap: () {
            setState(() => _collegeIdAddLater = false);
            _showDocumentSourceSheet("College ID");
          },
          onRemove: () {
            setState(() {
              _collegeIdBytes = null;
              _collegeIdUrl = null;
              _collegeIdUploaded = false;
              _collegeIdAddLater = false;
            });
            _showSnackbar("College ID Card removed.");
          },
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Government Authorized ID *\n(Aadhar, PAN, DL)",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _govtIdAddLater = !_govtIdAddLater;
                });
                if (_govtIdAddLater) {
                  _showSnackbar("Government ID marked as 'Add Later'.");
                }
              },
              icon: Icon(
                _govtIdAddLater ? Icons.check_circle_rounded : Icons.access_time_rounded,
                size: 13,
                color: _govtIdAddLater ? const Color(0xFF16A34A) : const Color(0xFF475569),
              ),
              label: Text(
                _govtIdAddLater ? "Marked: Add Later" : "Add Later",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _govtIdAddLater ? const Color(0xFF16A34A) : const Color(0xFF475569),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _govtIdAddLater ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: _govtIdAddLater ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildUploadCard(
          title: _govtIdAddLater ? "Government ID (Marked for Add Later)" : "Click to Upload Government Authorized ID",
          subtitle: "📸 Camera, 📁 Gallery, or 📄 PDF Document",
          icon: Icons.verified_user_rounded,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          isUploaded: _govtIdUploaded,
          isUploading: _isUploadingGovtId,
          previewBytes: _govtIdBytes,
          uploadedUrl: _govtIdUrl,
          onTap: () {
            setState(() => _govtIdAddLater = false);
            _showDocumentSourceSheet("Government ID");
          },
          onRemove: () {
            setState(() {
              _govtIdBytes = null;
              _govtIdUrl = null;
              _govtIdUploaded = false;
              _govtIdAddLater = false;
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
        _buildInputLabel("Selected Building *"),
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
                "Choose a building (Mandatory)",
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

        // Room & Bed Assignment Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel("Room Number *"),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _roomNumberController,
                    decoration: _buildInputDecoration(
                      hintText: "e.g. 402-A (Mandatory)",
                      suffixIcon: Icons.door_sliding_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel("Bed Number"),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bedNumberController,
                    decoration: _buildInputDecoration(
                      hintText: "e.g. Bed 1 / A",
                      suffixIcon: Icons.bed_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                    if (_collegeIdBytes == null && !_collegeIdUploaded && !_collegeIdAddLater) {
                      _showSnackbar("Please upload College ID Card or select 'Add Later'", isSuccess: false);
                      return;
                    }
                    if (_govtIdBytes == null && !_govtIdUploaded && !_govtIdAddLater) {
                      _showSnackbar("Please upload Government ID or select 'Add Later'", isSuccess: false);
                      return;
                    }
                    if (_selectedBuilding == null || _selectedBuilding!.isEmpty) {
                      _showSnackbar("Please select a building", isSuccess: false);
                      return;
                    }
                    if (_roomNumberController.text.trim().isEmpty) {
                      _showSnackbar("Please enter a room number", isSuccess: false);
                      return;
                    }
                    setState(() {
                      _currentStep = 3;
                    });
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
          "Choose Your Plan *",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 56,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedPlan == "Rent Only"
                          ? const Color(0xFF0056D2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _selectedPlan == "Rent Only"
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0056D2).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _selectedPlan == "Rent Only" ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlan = "Full Package";
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedPlan == "Full Package"
                          ? const Color(0xFF0056D2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _selectedPlan == "Full Package"
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0056D2).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
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
                            fontSize: 14,
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
        const SizedBox(height: 20),

        if (_selectedPlan == "Rent Only") ...[
          Text(
            "Rental Term / Lock-in Period *",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // 4 Rental Term Cards
          Column(
            children: _rentTermOptions.map((opt) {
              final isSelected = _selectedRentTerm == opt['title'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRentTerm = opt['title']!;
                      _generateInstallmentsFromStep3();
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0056D2) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0056D2) : const Color(0xFF94A3B8),
                              width: 2,
                            ),
                            color: isSelected ? const Color(0xFF0056D2) : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.circle, size: 8, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      opt['title']!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? const Color(0xFF0056D2) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      opt['badge']!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? const Color(0xFF0056D2) : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                opt['rule']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          Text(
            "Payment Frequency *",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _paymentFrequency = "Pay Monthly";
                      _generateInstallmentsFromStep3();
                    });
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _paymentFrequency == "Pay Monthly" ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentFrequency == "Pay Monthly" ? const Color(0xFF0056D2) : const Color(0xFFE2E8F0),
                        width: _paymentFrequency == "Pay Monthly" ? 1.8 : 1,
                      ),
                    ),
                    child: Text(
                      "Pay Monthly",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _paymentFrequency == "Pay Monthly" ? const Color(0xFF0056D2) : const Color(0xFF0F172A),
                      ),
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
                      _generateInstallmentsFromStep3();
                    });
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _paymentFrequency == "Whole Year" ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentFrequency == "Whole Year" ? const Color(0xFF0056D2) : const Color(0xFFE2E8F0),
                        width: _paymentFrequency == "Whole Year" ? 1.8 : 1,
                      ),
                    ),
                    child: Text(
                      "Whole Year",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _paymentFrequency == "Whole Year" ? const Color(0xFF0056D2) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dynamic Schedule Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.event_available_rounded, size: 18, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _paymentFrequency == "Pay Monthly"
                            ? "Monthly Schedule ($_selectedRentTerm)"
                            : "Full Term Upfront ($_selectedRentTerm)",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _paymentFrequency == "Pay Monthly"
                            ? _getRentTermMonthlyScheduleNote(_selectedRentTerm)
                            : "Full ${_getRentTermMonths(_selectedRentTerm)} month(s) fee payable irrespective of late joining.",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF15803D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_paymentFrequency == "Whole Year") ...[
            _buildInputLabel("Number of Installments"),
            const SizedBox(height: 6),
            TextField(
              controller: _yearInstallmentsController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _generateInstallmentsFromStep3(),
              decoration: _buildInputDecoration(
                hintText: "4",
                prefixIcon: Icons.format_list_numbered_rounded,
              ),
            ),
            const SizedBox(height: 20),
          ],

          _buildInputLabel("Monthly Rent (₹) *"),
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

          _buildInputLabel("Security Deposit (₹) *"),
          const SizedBox(height: 6),
          TextField(
            controller: _securityDepositController,
            keyboardType: TextInputType.number,
            decoration: _buildInputDecoration(
              hintText: "₹ 25,000",
              prefixIcon: Icons.shield_outlined,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Refundable at the end of tenancy",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ] else ...[
          Text(
            "Total Academic Package Fee (₹) *",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _totalAcademicFeesController,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              setState(() {
                _generateInstallmentsFromStep3();
              });
            },
            decoration: _buildInputDecoration(
              hintText: "₹ 1,50,000",
              prefixIcon: Icons.currency_rupee_rounded,
            ),
          ),
          const SizedBox(height: 20),

          // Number of Installments Selector
          _buildInputLabel("Number of Installments *"),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildInstallmentOptionChip("1 (Full Pay)", 1),
                const SizedBox(width: 8),
                _buildInstallmentOptionChip("2 (Semester)", 2),
                const SizedBox(width: 8),
                _buildInstallmentOptionChip("3 (Tri-Term)", 3),
                const SizedBox(width: 8),
                _buildInstallmentOptionChip("4 (Quarterly)", 4),
                const SizedBox(width: 8),
                _buildInstallmentOptionChip("Custom", -1),
              ],
            ),
          ),
          if (_isCustomPackageInstallments) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Custom Installments Count",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "Choose between 1 to 12 installments",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _packageInstallmentsCount > 1
                            ? () {
                                setState(() {
                                  _packageInstallmentsCount--;
                                  _customInstallmentsController.text = "$_packageInstallmentsCount";
                                  _generateInstallmentsFromStep3();
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: const Color(0xFF0056D2),
                      ),
                      Container(
                        width: 36,
                        alignment: Alignment.center,
                        child: Text(
                          "$_packageInstallmentsCount",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _packageInstallmentsCount < 12
                            ? () {
                                setState(() {
                                  _packageInstallmentsCount++;
                                  _customInstallmentsController.text = "$_packageInstallmentsCount";
                                  _generateInstallmentsFromStep3();
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: const Color(0xFF0056D2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildPackageBreakdownBanner(),
          const SizedBox(height: 20),

          _buildInputLabel("Premium Security Deposit (₹) *"),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Unit Summary",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0056D2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedBuilding ?? "Lakshya",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0056D2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  _getBuildingAsset(_selectedBuilding),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: const Color(0xFFCBD5E1),
                    child: const Icon(Icons.business_rounded, color: Colors.white, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "${_selectedBuilding ?? 'Lakshya'} — Room ${_roomNumberController.text.trim().isEmpty ? '101' : _roomNumberController.text.trim()}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${_selectedBuilding ?? 'Lakshya'} Residency",
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
                    "Plan Selected",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    _selectedPlan,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0056D2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Term / Lock-in Period",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getLockInPeriod(),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.35,
                      ),
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
                    if (_selectedPlan == "Rent Only" && _monthlyRentController.text.trim().isEmpty) {
                      _showSnackbar("Please enter monthly rent", isSuccess: false);
                      return;
                    }
                    if (_selectedPlan == "Rent Only" && _securityDepositController.text.trim().isEmpty) {
                      _showSnackbar("Please enter security deposit", isSuccess: false);
                      return;
                    }
                    if (_selectedPlan == "Full Package" && _totalAcademicFeesController.text.trim().isEmpty) {
                      _showSnackbar("Please enter total academic fee", isSuccess: false);
                      return;
                    }
                    if (_selectedPlan == "Full Package" && _premiumDepositController.text.trim().isEmpty) {
                      _showSnackbar("Please enter premium deposit", isSuccess: false);
                      return;
                    }
                    _generateInstallmentsFromStep3();
                    setState(() {
                      _currentStep = 4;
                    });
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
                  Expanded(
                    child: Text(
                      "Installment Schedule",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0056D2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddInstallmentDialog(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      "Add",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056D2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Security Deposit Card (Amber Bordered)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Security Deposit",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
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
                            "One-time",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Deposit Amount",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFCD34D)),
                                ),
                                child: Text(
                                  "₹ $secDepositVal",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
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
                                "Due Timeline",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFCD34D)),
                                ),
                                child: Text(
                                  "At Move-In",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
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
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _installments[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, color: Color(0xFF0056D2), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showEditInstallmentNameDialog(index),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item['title'] ?? "Installment ${index + 1}",
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF0056D2)),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                              onPressed: () {
                                setState(() {
                                  _installments.removeAt(index);
                                });
                                _showSnackbar("Removed installment.");
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Amount (₹)",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    initialValue: item['amount'],
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                                    decoration: _buildInputDecoration(hintText: "25000"),
                                    onChanged: (val) {
                                      item['amount'] = val;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Due Date",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _pickDueDate(index),
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              item['dueDate'] ?? "24/08/2024",
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF0056D2)),
                                        ],
                                      ),
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
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Emergency Contact Section
        Text(
          "Emergency Contact Details",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),

        _buildInputLabel("Guardian / Parent Full Name *"),
        const SizedBox(height: 6),
        TextField(
          controller: _guardianNameController,
          decoration: _buildInputDecoration(
            hintText: "Enter guardian name (Mandatory)",
            prefixIcon: Icons.badge_outlined,
          ),
        ),
        const SizedBox(height: 18),

        _buildInputLabel("Relationship *"),
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

        _buildInputLabel("Emergency Contact Phone (India +91) *"),
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
                  hintText: "10-digit guardian number",
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Text(
          "Dietary Preference *",
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
                    if (_guardianNameController.text.trim().isEmpty) {
                      _showSnackbar("Please enter Guardian / Emergency Contact Name", isSuccess: false);
                      return;
                    }
                    final gPhone = _guardianPhoneController.text.trim().replaceAll(RegExp(r'\D'), '');
                    if (gPhone.length < 10) {
                      _showSnackbar("Please enter a valid 10-digit Guardian Contact Number", isSuccess: false);
                      return;
                    }
                    setState(() {
                      _currentStep = 5;
                    });
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
  // STEP 5 OF 5: INVENTORY & FINAL NOTES
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
              "INVENTORY & SUMMARY",
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
          "Inventory & Profile Notes",
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
                  Expanded(
                    child: Text(
                      "Student Room Inventory",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Add Custom Item Input Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customInventoryController,
                      decoration: InputDecoration(
                        hintText: "Add room amenity (e.g. Mattress, Lamp)...",
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
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_customInventoryController.text.trim().isNotEmpty) {
                          setState(() {
                            _inventoryItems.add(_customInventoryController.text.trim());
                            _customInventoryController.clear();
                          });
                          _showSnackbar("Added amenity to inventory!");
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

        // Negotiations & Student Notes Container (Profile Notes)
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
                    child: const Icon(Icons.note_alt_outlined, color: Color(0xFF0056D2), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Student Profile Notes",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Attached Notes List
              if (_attachedNotes.isNotEmpty) ...[
                Text(
                  "Attached Notes (${_attachedNotes.length})",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _attachedNotes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final note = _attachedNotes[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sticky_note_2_outlined, size: 18, color: Color(0xFF0056D2)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: const Color(0xFF0F172A),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Admin Note",
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF0056D2)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              setState(() {
                                _attachedNotes.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Unified Modern Note Composer
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _finalNotesController,
                      maxLines: 3,
                      minLines: 2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: const Color(0xFF0F172A),
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: "Add note regarding room preferences, negotiations, fee concessions, etc...",
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                          height: 1.4,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        border: InputBorder.none,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 5),
                              Text(
                                "Visible on Profile",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_finalNotesController.text.trim().isNotEmpty) {
                                setState(() {
                                  _attachedNotes.add(_finalNotesController.text.trim());
                                  _finalNotesController.clear();
                                });
                                _showSnackbar("Note attached to student profile!");
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text(
                              "Attach Note",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0056D2),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Step 5 Actions (Full Width Stacked Action Buttons)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSavingStudent ? null : _showSummaryReviewModal,
            icon: _isSavingStudent
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : const Icon(Icons.rate_review_outlined, size: 20),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _isSavingStudent ? "Creating Student Account..." : "Review Summary & Confirm",
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSavingStudent ? const Color(0xFF94A3B8) : const Color(0xFF0056D2),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF94A3B8),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isSavingStudent
                ? null
                : () {
                    setState(() {
                      _currentStep = 4;
                    });
                  },
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(
              "Back",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _isSavingStudent ? const Color(0xFF94A3B8) : const Color(0xFF0056D2),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _isSavingStudent ? const Color(0xFFCBD5E1) : const Color(0xFF0056D2),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper Dialogs for Installments and Summary ---

  Future<void> _pickDueDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: (index + 1) * 30)),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final formatted = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      setState(() {
        _installments[index]["dueDate"] = formatted;
      });
    }
  }

  void _showEditInstallmentNameDialog(int index) {
    final nameCtrl = TextEditingController(text: _installments[index]["title"]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Installment Title", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
        content: TextField(
          controller: nameCtrl,
          decoration: _buildInputDecoration(hintText: "e.g. Semester 1 Tuition / Term 1"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _installments[index]["title"] = nameCtrl.text.trim();
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056D2), foregroundColor: Colors.white),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showAddInstallmentDialog() {
    final titleCtrl = TextEditingController(text: "Installment ${_installments.length + 1}");
    final amtCtrl = TextEditingController(text: "25000");
    String dueDate = "24/08/2024";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Add Custom Installment", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: _buildInputDecoration(hintText: "Installment Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(hintText: "Amount (₹)"),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      dueDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                    });
                  }
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Due: $dueDate", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                      const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF0056D2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _installments.add(<String, String>{
                      "title": titleCtrl.text.trim(),
                      "amount": amtCtrl.text.trim(),
                      "dueDate": dueDate,
                    });
                  });
                  _showSnackbar("Added new installment!");
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056D2), foregroundColor: Colors.white),
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _showSummaryReviewModal() {
    if (_isSavingStudent) return;
    final fullName = _fullNameController.text.trim().isNotEmpty ? _fullNameController.text.trim() : "Resident";
    final regNo = _regNoController.text.trim().isNotEmpty ? _regNoController.text.trim() : "REG101";
    final building = _selectedBuilding ?? "Lakshya";
    final room = _roomNumberController.text.trim().isNotEmpty ? _roomNumberController.text.trim() : "Room 101";
    final bed = _bedNumberController.text.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: !_isSavingStudent,
      enableDrag: !_isSavingStudent,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Onboarding Application Summary",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(modalCtx),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Building Image Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.asset(
                              _getBuildingAsset(_selectedBuilding),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, st) => Container(
                                height: 150,
                                color: const Color(0xFFCBD5E1),
                                child: const Icon(Icons.business_rounded, color: Colors.white, size: 40),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "$building — $room${bed.isNotEmpty ? ' • Bed $bed' : ''}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Personal & Academic Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow("Student Name", fullName),
                            const Divider(height: 16, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Registration No.", regNo),
                            const Divider(height: 16, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Course", _courseController.text),
                            const Divider(height: 16, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Branch / Specialization", _branchController.text),
                            const Divider(height: 16, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Hometown Address", _hometownAddressController.text),
                            const Divider(height: 16, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Mobile", "+91 ${_mobileController.text}"),
                            const Divider(height: 16, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Email", _emailController.text),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Documents & Verification Status (With Live Image Previews)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Attached Documents & Photos",
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF334155)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "3 Documents",
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0056D2)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryDocItem(
                              "Student Profile Photo",
                              _profilePhotoBytes,
                              _profilePhotoUrl,
                              _profilePhotoAddLater,
                              Icons.face_rounded,
                            ),
                            _buildSummaryDocItem(
                              "College ID Card",
                              _collegeIdBytes,
                              _collegeIdUrl,
                              _collegeIdAddLater,
                              Icons.badge_outlined,
                            ),
                            _buildSummaryDocItem(
                              "Government Authorized ID",
                              _govtIdBytes,
                              _govtIdUrl,
                              _govtIdAddLater,
                              Icons.verified_user_outlined,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Plan & Financial Breakdown
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lease Plan & Installments",
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF334155)),
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryRow("Plan", _selectedPlan),
                            const Divider(height: 14, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Term / Lock-in", _getLockInPeriod()),
                            const Divider(height: 14, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Monthly Rent", "₹ ${_monthlyRentController.text}"),
                            const Divider(height: 14, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Security Deposit", "₹ ${_securityDepositController.text}"),
                            const Divider(height: 14, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Installments Count", "${_installments.length} Installments"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Guardian & Emergency Contact
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow("Guardian", _guardianNameController.text),
                            const Divider(height: 14, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Relationship", _guardianRelationship),
                            const Divider(height: 14, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Guardian Contact", "+91 ${_guardianPhoneController.text}"),
                            const Divider(height: 14, color: Color(0xFFE2E8F0)),
                            _buildSummaryRow("Dietary Preference", _dietaryPreference),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Room Inventory List
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Room Inventory Checklist (${_inventoryItems.length} items)",
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF334155)),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _inventoryItems.map((item) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "✓ $item",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0056D2)),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Attached Notes
                      if (_attachedNotes.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Attached Notes (${_attachedNotes.length})",
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF334155)),
                              ),
                              const SizedBox(height: 8),
                              ..._attachedNotes.map((note) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.circle, size: 6, color: Color(0xFF0056D2)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        note,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF334155)),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 29-Page Rental Agreement Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _signedAgreementPdfBytes != null
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _signedAgreementPdfBytes != null
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFDE68A),
                            width: 1.3,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _signedAgreementPdfBytes != null
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _signedAgreementPdfBytes != null
                                        ? Icons.verified_user_rounded
                                        : Icons.draw_rounded,
                                    color: _signedAgreementPdfBytes != null
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFD97706),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Rental Agreement (29 Pages)",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        _signedAgreementPdfBytes != null
                                            ? "Digitally signed with Owner & Tenant signatures"
                                            : "Student digital signature required before boarding",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: _signedAgreementPdfBytes != null
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _signedAgreementPdfBytes != null
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _signedAgreementPdfBytes != null ? "Signed" : "Pending",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _signedAgreementPdfBytes != null
                                          ? const Color(0xFF166534)
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final agreementData = _buildRentalAgreementData();
                                  final res = await RentalAgreementDialog.show(
                                    context,
                                    agreementData: agreementData,
                                  );
                                  if (res != null) {
                                    setState(() {
                                      _signedAgreementPdfBytes = res['pdfBytes'] as Uint8List?;
                                      _signedAgreementSignatureBytes = res['signatureBytes'] as Uint8List?;
                                    });
                                    setModalState(() {});
                                  }
                                },
                                icon: Icon(
                                  _signedAgreementPdfBytes != null
                                      ? Icons.visibility_rounded
                                      : Icons.edit_document,
                                  size: 16,
                                ),
                                label: Text(
                                  _signedAgreementPdfBytes != null
                                      ? "View Agreement / Redraw Signature"
                                      : "Review & Sign Rental Agreement",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _signedAgreementPdfBytes != null
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF0056D2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password Email Notice Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mark_email_read_outlined, color: Color(0xFF0056D2), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Password will be sent to student's mail",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF003896),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSavingStudent
                      ? null
                      : () async {
                          if (_isSavingStudent) return;
                          if (_signedAgreementPdfBytes == null) {
                            final agreementData = _buildRentalAgreementData();
                            final res = await RentalAgreementDialog.show(
                              context,
                              agreementData: agreementData,
                            );
                            if (res != null) {
                              setState(() {
                                _signedAgreementPdfBytes = res['pdfBytes'] as Uint8List?;
                                _signedAgreementSignatureBytes = res['signatureBytes'] as Uint8List?;
                              });
                              if (!modalCtx.mounted) return;
                              Navigator.pop(modalCtx);
                              _handleCompleteOnboarding();
                            }
                            return;
                          }
                          Navigator.pop(modalCtx);
                          _handleCompleteOnboarding();
                        },
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Confirm & Create Student Account",
                      maxLines: 1,
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryDocItem(
    String title,
    Uint8List? bytes,
    String? url,
    bool isAddLater,
    IconData defaultIcon, {
    bool isLast = false,
  }) {
    final bool hasImage = bytes != null || (url != null && url.isNotEmpty);

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasImage ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: hasImage ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Image Preview Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 58,
              height: 58,
              color: const Color(0xFFF1F5F9),
              child: hasImage
                  ? (bytes != null
                      ? Image.memory(
                          bytes,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          url!,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => const Center(
                            child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                          ),
                        ))
                  : Center(
                      child: Icon(
                        isAddLater ? Icons.access_time_rounded : defaultIcon,
                        color: isAddLater ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasImage
                        ? const Color(0xFFDCFCE7)
                        : (isAddLater ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasImage
                            ? Icons.check_circle_rounded
                            : (isAddLater ? Icons.access_time_rounded : Icons.info_outline_rounded),
                        size: 13,
                        color: hasImage
                            ? const Color(0xFF16A34A)
                            : (isAddLater ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          hasImage ? "Image Attached" : (isAddLater ? "Marked: Add Later" : "Not Provided"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: hasImage
                                ? const Color(0xFF16A34A)
                                : (isAddLater ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isHighlighted ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
            ),
          ),
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
    required bool isUploaded,
    bool isUploading = false,
    Uint8List? previewBytes,
    String? uploadedUrl,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    final bool isPdfDoc = CloudinaryService.isPdf(uploadedUrl);

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isUploaded ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUploaded ? const Color(0xFF86EFAC) : (isUploading ? const Color(0xFF0056D2) : const Color(0xFFE2E8F0)),
            width: isUploaded || isUploading ? 1.5 : 1,
          ),
        ),
        child: isUploading
            ? const Column(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF0056D2)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Uploading document to cloud...",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0056D2)),
                  ),
                ],
              )
            : Column(
                children: [
                  if (previewBytes != null && !isPdfDoc) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        previewBytes,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (isUploaded && isPdfDoc) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "PDF Document Attached",
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF991B1B),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUploaded ? const Color(0xFFDCFCE7) : iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUploaded ? (isPdfDoc ? Icons.picture_as_pdf_rounded : Icons.check_circle_rounded) : icon,
                        color: isUploaded ? (isPdfDoc ? const Color(0xFFDC2626) : const Color(0xFF16A34A)) : iconColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isUploaded) ...[
                        Icon(isPdfDoc ? Icons.picture_as_pdf_rounded : Icons.check_circle_rounded, color: isPdfDoc ? const Color(0xFFDC2626) : const Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          isUploaded ? (isPdfDoc ? "PDF Attached! (Tap to change)" : "Uploaded Successfully! (Tap to change)") : title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isUploaded ? const Color(0xFF166534) : const Color(0xFF0056D2),
                          ),
                        ),
                      ),
                    ],
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
                  if (isUploaded) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (uploadedUrl != null || previewBytes != null) ...[
                          TextButton.icon(
                            onPressed: () {
                              DocumentViewerModal.show(
                                context,
                                url: uploadedUrl ?? "",
                                title: title,
                                memoryBytes: previewBytes,
                              );
                            },
                            icon: const Icon(Icons.visibility_rounded, size: 16, color: Color(0xFF0056D2)),
                            label: Text(
                              "View / Download",
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0056D2)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (onRemove != null)
                          TextButton.icon(
                            onPressed: onRemove,
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                            label: Text(
                              "Remove",
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
