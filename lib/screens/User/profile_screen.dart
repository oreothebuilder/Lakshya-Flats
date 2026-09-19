import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/user_drawer.dart';
import '../../models/user_role_model.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/media_picker_service.dart';
import '../../config/cloudinary_config.dart';
import '../../widgets/document_viewer_modal.dart';
import '../../widgets/app_toast.dart';
import 'notifications_screen.dart';
import 'user_home_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser? currentUser;
  final bool autoOpenChangePassword;

  const ProfileScreen({
    super.key,
    this.currentUser,
    this.autoOpenChangePassword = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Information controllers/state
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _regController;
  late TextEditingController _courseController;
  late TextEditingController _branchController;
  late TextEditingController _hometownAddressController;

  // Emergency Contact controllers/state
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _emergencyRelationshipController;

  // Initial user values
  String _name = "Student Resident";
  String _email = "";
  String _phone = "";
  String _dob = "";
  String _reg = "";
  String _course = "";
  String _branch = "";
  String _hometownAddress = "";
  List<String> _notes = [];
  String _studentId = "";
  DateTime? _studentCreatedAt;
  String _studentDocId = "";
  StreamSubscription<DocumentSnapshot>? _studentSub;

  // Lease Plan & Installments
  String _plan = "Rent Only";
  String _monthlyRent = "0";
  String _securityDeposit = "0";
  String _installmentsCount = "12 Installments";

  // Emergency contact & dietary preference values
  String _emergencyName = "";
  String _emergencyPhone = "";
  String _emergencyRelationship = "Guardian";
  String _dietaryPreference = "Vegetarian";

  // Room Inventory
  List<String> _inventory = [];

  // Attached Documents
  String? _photoUrl;
  bool _photoAddLater = false;
  String? _collegeIdUrl;
  bool _collegeIdAddLater = false;
  String? _govtIdUrl;
  bool _govtIdAddLater = false;
  String? _rentAgreementUrl;
  bool _isUploadingDoc = false;

  // Stay details values
  String _building = "Lakshya";
  String _room = "";
  String _bed = "";
  String _moveInDate = "";

  // Account Settings state
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  String _language = "English";

  @override
  void initState() {
    super.initState();
    final u = widget.currentUser;
    final authUser = FirebaseAuthService().currentUser;
    if (u != null) {
      if (u.studentId?.isNotEmpty == true) _studentId = u.studentId!;
      _studentCreatedAt = u.createdAt;
      if (u.fullName.isNotEmpty) _name = u.fullName;
      if (u.email.isNotEmpty) _email = u.email;
      if (u.phone.isNotEmpty) _phone = u.phone;
      if (u.registrationNumber?.isNotEmpty == true) _reg = u.registrationNumber!;
      if (u.building?.isNotEmpty == true) _building = u.building!;
      if (u.room?.isNotEmpty == true) _room = u.room!;
    } else if (authUser != null) {
      if (authUser.displayName?.isNotEmpty == true) _name = authUser.displayName!;
      if (authUser.email?.isNotEmpty == true) _email = authUser.email!;
      if (authUser.phoneNumber?.isNotEmpty == true) _phone = authUser.phoneNumber!;
    }

    _nameController = TextEditingController(text: _name);
    _emailController = TextEditingController(text: _email);
    _phoneController = TextEditingController(text: _phone);
    _dobController = TextEditingController(text: _dob);
    _regController = TextEditingController(text: _reg);
    _courseController = TextEditingController(text: _course);
    _branchController = TextEditingController(text: _branch);
    _hometownAddressController = TextEditingController(text: _hometownAddress);

    _emergencyNameController = TextEditingController(text: _emergencyName);
    _emergencyPhoneController = TextEditingController(text: _emergencyPhone);
    _emergencyRelationshipController = TextEditingController(text: _emergencyRelationship);

    _loadStudentDetails();

    if (widget.autoOpenChangePassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showChangePasswordDialog();
        }
      });
    }
  }

  Future<void> _loadStudentDetails() async {
    try {
      final authUser = FirebaseAuthService().currentUser;
      final u = widget.currentUser;
      Map<String, dynamic>? doc;

      // 1. Try by uid from widget.currentUser or authUser
      final uid = u?.uid.isNotEmpty == true ? u!.uid : (authUser?.uid ?? '');
      if (uid.isNotEmpty) {
        try {
          final snap = await FirestoreService().getStudentProfile(uid);
          if (snap.exists && snap.data() != null) {
            doc = {
              'id': snap.id,
              ...snap.data() as Map<String, dynamic>,
            };
          }
        } catch (_) {}
      }

      // 2. Try by studentId if available
      if (doc == null && (u?.studentId?.isNotEmpty == true || _studentId.isNotEmpty)) {
        final sid = u?.studentId?.isNotEmpty == true ? u!.studentId! : _studentId;
        try {
          final snap = await FirestoreService().getStudentProfile(sid);
          if (snap.exists && snap.data() != null) {
            doc = {
              'id': snap.id,
              ...snap.data() as Map<String, dynamic>,
            };
          }
        } catch (_) {}
      }

      // 3. Fallback: Try by registration number or email
      if (doc == null) {
        final lookupKey = _reg.isNotEmpty && _reg != "REG-RESIDENT"
            ? _reg
            : (_email.isNotEmpty ? _email : (authUser?.email ?? ''));
        if (lookupKey.isNotEmpty) {
          doc = await FirestoreService().findStudentByRegNoOrEmail(lookupKey);
        }
      }

      // 4. Fallback: if still null, try email
      if (doc == null && _email.isNotEmpty) {
        doc = await FirestoreService().findStudentByRegNoOrEmail(_email);
      }

      if (doc != null && mounted) {
        _studentDocId = doc['id']?.toString() ?? _studentId;
        _applyStudentData(doc);

        if (_studentDocId.isNotEmpty && _studentSub == null) {
          _studentSub = FirebaseFirestore.instance
              .collection('users')
              .doc(_studentDocId)
              .snapshots()
              .listen((snap) {
            if (snap.exists && snap.data() != null) {
              _applyStudentData({
                'id': snap.id,
                ...snap.data()!,
              });
            }
          });
        }
      }
    } catch (_) {}
  }

  void _applyStudentData(Map<String, dynamic> studentData) {
    if (!mounted) return;
    setState(() {
      final sid = studentData['studentId']?.toString() ??
          studentData['id']?.toString() ??
          studentData['student_id']?.toString() ??
          '';
      if (sid.isNotEmpty) {
        _studentId = sid;
      }
      final ca = studentData['createdAt'];
      if (ca is Timestamp) {
        _studentCreatedAt = ca.toDate();
      } else if (ca is DateTime) {
        _studentCreatedAt = ca;
      } else if (ca != null) {
        _studentCreatedAt = DateTime.tryParse(ca.toString());
      }

      if (studentData['fullName'] != null && studentData['fullName'].toString().isNotEmpty) {
        _name = studentData['fullName'].toString();
        _nameController.text = _name;
      }
      if (studentData['phone'] != null && studentData['phone'].toString().isNotEmpty) {
        _phone = studentData['phone'].toString();
        _phoneController.text = _phone;
      }
      if (studentData['registrationNumber'] != null && studentData['registrationNumber'].toString().isNotEmpty) {
        _reg = studentData['registrationNumber'].toString();
        _regController.text = _reg;
      } else if (studentData['regNo'] != null && studentData['regNo'].toString().isNotEmpty) {
        _reg = studentData['regNo'].toString();
        _regController.text = _reg;
      }
      if (studentData['course'] != null && studentData['course'].toString().isNotEmpty) {
        _course = studentData['course'].toString();
        _courseController.text = _course;
      }
      if (studentData['branch'] != null && studentData['branch'].toString().isNotEmpty) {
        _branch = studentData['branch'].toString();
        _branchController.text = _branch;
      }
      if (studentData['dob'] != null && studentData['dob'].toString().isNotEmpty) {
        _dob = studentData['dob'].toString();
        _dobController.text = _dob;
      }
      final addr = studentData['hometownAddress']?.toString() ?? studentData['address']?.toString() ?? '';
      if (addr.isNotEmpty) {
        _hometownAddress = addr;
        _hometownAddressController.text = _hometownAddress;
      }

      // Stay details
      if (studentData['building'] != null && studentData['building'].toString().isNotEmpty) {
        _building = studentData['building'].toString();
      }
      if (studentData['room'] != null && studentData['room'].toString().isNotEmpty) {
        _room = studentData['room'].toString();
      }
      final bed = studentData['bedNumber']?.toString() ?? studentData['bed']?.toString() ?? '';
      if (bed.isNotEmpty) {
        _bed = bed;
      }
      final created = studentData['createdAt']?.toString() ?? '';
      if (created.isNotEmpty) {
        _moveInDate = created.contains('T') ? created.split('T').first : created;
      }

      // Lease Plan & Installments
      if (studentData['plan'] != null && studentData['plan'].toString().isNotEmpty) {
        _plan = studentData['plan'].toString();
      }
      if (studentData['monthlyRent'] != null && studentData['monthlyRent'].toString().isNotEmpty) {
        _monthlyRent = studentData['monthlyRent'].toString();
      }
      if (studentData['securityDeposit'] != null && studentData['securityDeposit'].toString().isNotEmpty) {
        _securityDeposit = studentData['securityDeposit'].toString();
      }
      if (studentData['installments'] is List && (studentData['installments'] as List).isNotEmpty) {
        _installmentsCount = "${(studentData['installments'] as List).length} Installments";
      } else if (studentData['paymentFrequency'] != null && studentData['paymentFrequency'].toString().isNotEmpty) {
        _installmentsCount = "${studentData['paymentFrequency']} Installments";
      }

      // Emergency Contact / Guardian details
      final gName = studentData['guardianName']?.toString() ??
          studentData['emergencyContactName']?.toString() ??
          studentData['emergencyName']?.toString() ??
          studentData['parentName']?.toString() ??
          '';
      if (gName.isNotEmpty) {
        _emergencyName = gName;
        _emergencyNameController.text = _emergencyName;
      }

      final gPhone = studentData['guardianPhone']?.toString() ??
          studentData['emergencyContactPhone']?.toString() ??
          studentData['emergencyPhone']?.toString() ??
          studentData['parentPhone']?.toString() ??
          '';
      if (gPhone.isNotEmpty) {
        _emergencyPhone = gPhone;
        _emergencyPhoneController.text = _emergencyPhone;
      }

      final gRel = studentData['guardianRelationship']?.toString() ??
          studentData['emergencyRelationship']?.toString() ??
          studentData['emergencyContactRelationship']?.toString() ??
          studentData['relationship']?.toString() ??
          '';
      if (gRel.isNotEmpty) {
        _emergencyRelationship = gRel;
        _emergencyRelationshipController.text = _emergencyRelationship;
      }

      if (studentData['dietaryPreference'] != null && studentData['dietaryPreference'].toString().isNotEmpty) {
        _dietaryPreference = studentData['dietaryPreference'].toString();
      }

      // Room Inventory
      if (studentData['inventory'] is List) {
        _inventory = (studentData['inventory'] as List).map((e) => e.toString()).toList();
      }

      // Attached Documents
      _photoUrl = studentData['photoUrl']?.toString();
      _photoAddLater = studentData['photoAddLater'] == true;

      _collegeIdUrl = studentData['collegeIdUrl']?.toString();
      _collegeIdAddLater = studentData['collegeIdAddLater'] == true;

      _govtIdUrl = studentData['govtIdUrl']?.toString();
      _govtIdAddLater = studentData['govtIdAddLater'] == true;

      _rentAgreementUrl = studentData['rentAgreementUrl']?.toString();

      final rawNotes = studentData['notes'];
      if (rawNotes is List) {
        _notes = rawNotes.map((e) => e.toString()).toList();
      }
    });
  }

  void _showSnackbar(String msg, {bool isSuccess = true}) {
    AppToast.show(context, msg, isSuccess: isSuccess);
  }

  Future<void> _uploadAddLaterDoc({
    required String title,
    required String docKey,
    required String addLaterKey,
  }) async {
    if (_studentDocId.isEmpty) {
      _showSnackbar("Unable to locate student profile record to upload document.", isSuccess: false);
      return;
    }

    try {
      final res = await MediaPickerService.showPickerAndUpload(
        context: context,
        title: "Upload $title",
        folder: CloudinaryConfig.folderStudentDocs,
        allowPdf: true,
      );
      if (res == null) return;

      setState(() => _isUploadingDoc = true);
      _showSnackbar("Uploading and saving $title to your profile...");

      final url = res.url;
      if (url.isNotEmpty) {
        await FirestoreService().uploadStudentAddLaterDocument(
          _studentDocId,
          docKey: docKey,
          url: url,
          addLaterKey: addLaterKey,
        );

        setState(() {
          if (docKey == 'photoUrl') {
            _photoUrl = url;
            _photoAddLater = false;
          } else if (docKey == 'collegeIdUrl') {
            _collegeIdUrl = url;
            _collegeIdAddLater = false;
          } else if (docKey == 'govtIdUrl') {
            _govtIdUrl = url;
            _govtIdAddLater = false;
          }
        });

        _showSnackbar("$title uploaded and permanently saved!");
      } else {
        _showSnackbar("Failed to upload document", isSuccess: false);
      }
    } catch (e) {
      _showSnackbar("Error uploading document: $e", isSuccess: false);
    } finally {
      if (mounted) setState(() => _isUploadingDoc = false);
    }
  }

  @override
  void dispose() {
    _studentSub?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _regController.dispose();
    _courseController.dispose();
    _branchController.dispose();
    _hometownAddressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationshipController.dispose();
    super.dispose();
  }





  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final passFormKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (_, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFF1D4ED8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Change Password",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: passFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: obscureOld,
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          labelText: "Current Password",
                          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setModalState(() => obscureOld = !obscureOld),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Enter current password" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setModalState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Enter new password";
                          if (v.trim().length < 6) return "Password must be at least 6 characters";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          labelText: "Confirm New Password",
                          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v != newPasswordController.text) return "Passwords do not match";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (passFormKey.currentState!.validate()) {
                            setModalState(() => isSubmitting = true);
                            final navigator = Navigator.of(dialogCtx);
                            final oldPass = oldPasswordController.text.trim();
                            final newPass = newPasswordController.text.trim();
                            try {
                              await FirebaseAuthService().changePassword(
                                currentPassword: oldPass,
                                newPassword: newPass,
                              );

                              // Mark in Firestore that default password has been changed
                              final currentUid = widget.currentUser?.uid ?? FirebaseAuthService().currentUser?.uid;
                              if (currentUid != null && currentUid.isNotEmpty) {
                                await FirestoreService().markPasswordChanged(
                                  currentUid,
                                  studentId: widget.currentUser?.studentId ?? _studentId,
                                );
                              }

                              navigator.pop(true);
                              if (mounted) {
                                AppToast.showSuccess(context, "Password updated successfully!");
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                AppToast.showError(context, FirebaseAuthService.getReadableErrorMessage(e));
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          "Update Password",
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNotificationPreferencesDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Notification Preferences",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(
                      "Push Notifications",
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "Receive real-time notifications on your device",
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                    value: _pushNotifications,
                    activeThumbColor: const Color(0xFF1D4ED8),
                    onChanged: (val) {
                      setModalState(() {
                        _pushNotifications = val;
                      });
                      setState(() {
                        _pushNotifications = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(
                      "Email Notifications",
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "Receive updates on payments, issues, and mess menus",
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                    value: _emailNotifications,
                    activeThumbColor: const Color(0xFF1D4ED8),
                    onChanged: (val) {
                      setModalState(() {
                        _emailNotifications = val;
                      });
                      setState(() {
                        _emailNotifications = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        "Done",
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguageSelector() {
    final languages = ["English", "Hindi", "Marathi", "Gujarati"];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Language",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                final isSel = _language == lang;
                return ListTile(
                  title: Text(
                    lang,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                    ),
                  ),
                  trailing: isSel ? const Icon(Icons.check_rounded, color: Color(0xFF1D4ED8)) : null,
                  onTap: () {
                    setState(() {
                      _language = lang;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _handleBackToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => UserHomeScreen(currentUser: widget.currentUser)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackToHome();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: UserDrawer(activeItem: "Profile", currentUser: widget.currentUser),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
            tooltip: "Back to Home",
            onPressed: _handleBackToHome,
          ),
          title: Text(
            "Profile",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          actions: [
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getStudentNotificationsStream(
                widget.currentUser?.uid ?? FirebaseAuthService().currentUser?.uid ?? '',
                building: widget.currentUser?.building,
                regNo: widget.currentUser?.registrationNumber,
              ),
              builder: (context, notifSnapshot) {
                final notifs = notifSnapshot.data ?? [];
                final unreadCount = notifs.where((n) => n['isRead'] != true).length;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsScreen(currentUser: widget.currentUser),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? "9+" : "$unreadCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  _name.isNotEmpty ? _name.substring(0, 1).toUpperCase() : "S",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Builder(
              builder: (drawerCtx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF475569)),
                tooltip: "Open Menu",
                onPressed: () => Scaffold.of(drawerCtx).openDrawer(),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile Banner Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                            ? NetworkImage(_photoUrl!)
                            : null,
                        child: (_photoUrl == null || _photoUrl!.isEmpty)
                            ? Text(
                                _name.isNotEmpty ? _name.substring(0, 1).toUpperCase() : "S",
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF1D4ED8),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _name,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.apartment_rounded, color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            "${_building.isNotEmpty ? _building : 'Lakshya'} • Room ${_room.isNotEmpty ? _room : 'N/A'}${_bed.isNotEmpty ? ' ($_bed)' : ''}",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_rounded, color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _phone,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Personal Information Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, color: Color(0xFF1D4ED8), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Personal Information",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _buildInfoField("Full Name", _nameController, _name, false),
                      const SizedBox(height: 14),
                      _buildInfoField("Email Address", _emailController, _email, false, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _buildInfoField("Phone Number", _phoneController, _phone, false, keyboardType: TextInputType.phone),
                      const SizedBox(height: 14),
                      _buildInfoField("Date of Birth", _dobController, _dob, false),
                      const SizedBox(height: 14),
                      _buildInfoField("College Registration Number", _regController, _reg, false),
                      const SizedBox(height: 14),
                      _buildInfoField("Course", _courseController, _course, false),
                      const SizedBox(height: 14),
                      _buildInfoField("Branch/Specialisation", _branchController, _branch, false),
                      const SizedBox(height: 14),
                      _buildInfoField("Hometown Address", _hometownAddressController, _hometownAddress, false, maxLines: 2),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Stay Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hotel_outlined, color: Color(0xFF1D4ED8), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Stay Details",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        children: [
                          _buildStayBox("Building", _building.isNotEmpty ? _building : "Lakshya"),
                          _buildStayBox("Room No.", _room.isNotEmpty ? _room : "N/A"),
                          _buildStayBox("Bed Type", _bed.isNotEmpty ? _bed : "Standard"),
                          _buildStayBox("Move-in Date", _moveInDate.isNotEmpty ? _moveInDate : "Active"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Lease Plan & Installments Card
                _buildLeasePlanCard(),
                const SizedBox(height: 20),

                // 5. Guardian Details & Dietary Preference Card
                _buildGuardianAndDietaryCard(),
                const SizedBox(height: 20),

                // 6. Room Inventory Checklist Card
                _buildRoomInventoryCard(),
                const SizedBox(height: 20),

                // 7. Attached Documents & Verification Card
                _buildAttachedDocumentsCard(),
                const SizedBox(height: 20),

                // 8. Notes Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, color: Color(0xFF1D4ED8), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Notes",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirestoreService().getPersonalNotesStream(
                          _studentId.isNotEmpty
                              ? _studentId
                              : (widget.currentUser?.studentId?.isNotEmpty == true
                                  ? widget.currentUser!.studentId!
                                  : (widget.currentUser?.uid.isNotEmpty == true
                                      ? widget.currentUser!.uid
                                      : (FirebaseAuthService().currentUser?.uid ?? ''))),
                        ),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          final items = <Widget>[];

                          final subcollectionTexts = <String>{};
                          for (var doc in docs) {
                            final data = doc.data() as Map<String, dynamic>? ?? {};
                            final text = data['text']?.toString() ?? data['note']?.toString() ?? data['message']?.toString() ?? '';
                            final ts = data['createdAt'];
                            DateTime? noteDate;
                            if (ts is Timestamp) {
                              noteDate = ts.toDate();
                            } else if (ts != null) {
                              noteDate = DateTime.tryParse(ts.toString());
                            }
                            final timeStr = noteDate != null ? _formatDateTime(noteDate) : "Admin Notice";
                            if (text.isNotEmpty) {
                              subcollectionTexts.add(text.trim());
                              items.add(_buildNoteItem(text, timeStr));
                              items.add(const SizedBox(height: 10));
                            }
                          }

                          if (_notes.isNotEmpty) {
                            for (var n in _notes) {
                              if (n.trim().isNotEmpty && !subcollectionTexts.contains(n.trim())) {
                                final timeStr = _studentCreatedAt != null ? _formatDateTime(_studentCreatedAt!) : "Admin Notice";
                                items.add(_buildNoteItem(n, timeStr));
                                items.add(const SizedBox(height: 10));
                              }
                            }
                          }

                          if (items.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Text(
                                "No active notices or notes from administration.",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF94A3B8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }

                          items.removeLast();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: items,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Account Settings Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings_outlined, color: Color(0xFF1D4ED8), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Account Settings",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _buildSettingsTile(
                        icon: Icons.lock_outline_rounded,
                        title: "Change Password",
                        onTap: _showChangePasswordDialog,
                      ),
                      const SizedBox(height: 4),
                      _buildSettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: "Notification Preferences",
                        onTap: _showNotificationPreferencesDialog,
                      ),
                      const SizedBox(height: 4),
                      _buildSettingsTile(
                        icon: Icons.language_rounded,
                        title: "Language",
                        value: _language,
                        onTap: _showLanguageSelector,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildInfoField(String label, TextEditingController controller, String value, bool isEditing, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return "$label cannot be empty";
              }
              return null;
            },
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : "Not provided",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: value.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStayBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? "PM" : "AM";
    final minute = dt.minute.toString().padLeft(2, '0');
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $period";
  }

  Widget _buildNoteItem(String message, String timestamp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 4),
                    Text(
                      "Admin Notice",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                timestamp,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF475569), size: 20),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildLeasePlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: Color(0xFF1D4ED8), size: 20),
              const SizedBox(width: 8),
              Text(
                "Lease Plan & Installments",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildReadOnlyDetailRow("Plan", _plan.isNotEmpty ? _plan : "Rent Only"),
          const SizedBox(height: 12),
          _buildReadOnlyDetailRow("Monthly Rent", "₹ $_monthlyRent"),
          const SizedBox(height: 12),
          _buildReadOnlyDetailRow("Security Deposit", "₹ $_securityDeposit"),
          const SizedBox(height: 12),
          _buildReadOnlyDetailRow("Installments Count", _installmentsCount),
        ],
      ),
    );
  }

  Widget _buildGuardianAndDietaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.contact_phone_outlined, color: Color(0xFF1D4ED8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Guardian & Dietary Details",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (_emergencyPhone.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF1D4ED8), size: 20),
                  tooltip: "Call Guardian",
                  onPressed: () async {
                    final cleanPhone = _emergencyPhone.replaceAll(RegExp(r'\D'), '');
                    final uri = Uri.parse('tel:$cleanPhone');
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        Clipboard.setData(ClipboardData(text: _emergencyPhone));
                        _showSnackbar("Guardian phone copied: $_emergencyPhone");
                      }
                    } catch (_) {
                      Clipboard.setData(ClipboardData(text: _emergencyPhone));
                      _showSnackbar("Guardian phone copied: $_emergencyPhone");
                    }
                  },
                ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildReadOnlyDetailRow("Guardian Name", _emergencyName.isNotEmpty ? _emergencyName : "N/A"),
          const SizedBox(height: 12),
          _buildReadOnlyDetailRow("Relationship", _emergencyRelationship.isNotEmpty ? _emergencyRelationship : "Guardian"),
          const SizedBox(height: 12),
          _buildReadOnlyDetailRow("Contact Number", _emergencyPhone.isNotEmpty ? _emergencyPhone : "N/A"),
          const SizedBox(height: 12),
          _buildReadOnlyDetailRow("Dietary Preference", _dietaryPreference.isNotEmpty ? _dietaryPreference : "Vegetarian"),
        ],
      ),
    );
  }

  Widget _buildRoomInventoryCard() {
    final items = _inventory.isNotEmpty
        ? _inventory
        : const [
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chair_outlined, color: Color(0xFF1D4ED8), size: 20),
              const SizedBox(width: 8),
              Text(
                "Room Inventory Checklist",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      item,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedDocumentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_shared_outlined, color: Color(0xFF1D4ED8), size: 20),
              const SizedBox(width: 8),
              Text(
                "Attached Documents & Verification",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildDocumentRow(
            title: "Student Profile Photo",
            url: _photoUrl,
            isAddLater: _photoAddLater,
            docKey: "photoUrl",
            addLaterKey: "photoAddLater",
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 14),
          _buildDocumentRow(
            title: "College ID Card",
            url: _collegeIdUrl,
            isAddLater: _collegeIdAddLater,
            docKey: "collegeIdUrl",
            addLaterKey: "collegeIdAddLater",
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: 14),
          _buildDocumentRow(
            title: "Government Authorized ID",
            url: _govtIdUrl,
            isAddLater: _govtIdAddLater,
            docKey: "govtIdUrl",
            addLaterKey: "govtIdAddLater",
            icon: Icons.credit_card_rounded,
          ),
          const SizedBox(height: 14),
          _buildAgreementDocumentRow(),
        ],
      ),
    );
  }

  Widget _buildAgreementDocumentRow() {
    final bool hasDoc = _rentAgreementUrl != null && _rentAgreementUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasDoc ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasDoc ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        size: 18,
                        color: hasDoc ? const Color(0xFF16A34A) : const Color(0xFF0056D2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rent & License Agreement",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "29-page executed lease contract with digital signatures",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasDoc ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasDoc ? "Executed" : "Draft / On File",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: hasDoc ? const Color(0xFF166534) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasDoc)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  DocumentViewerModal.show(
                    context,
                    url: _rentAgreementUrl!,
                    title: "Rental & License Agreement",
                    fileName: "Rental_Agreement_${_studentId.isNotEmpty ? _studentId : 'Student'}.pdf",
                  );
                },
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: Text(
                  "View & Download Agreement",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else
            Text(
              "Agreement copy will be available once finalized by management.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow({
    required String title,
    required String? url,
    required bool isAddLater,
    required String docKey,
    required String addLaterKey,
    required IconData icon,
  }) {
    final bool hasDoc = url != null && url.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasDoc
              ? const Color(0xFF86EFAC)
              : (isAddLater ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasDoc
                            ? const Color(0xFFDCFCE7)
                            : (isAddLater ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: hasDoc
                            ? const Color(0xFF15803D)
                            : (isAddLater ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasDoc
                      ? const Color(0xFFDCFCE7)
                      : (isAddLater ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasDoc
                          ? Icons.check_circle_rounded
                          : (isAddLater ? Icons.schedule_rounded : Icons.info_outline),
                      size: 12,
                      color: hasDoc
                          ? const Color(0xFF15803D)
                          : (isAddLater ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasDoc ? "Uploaded" : (isAddLater ? "Marked: Add Later" : "Not Uploaded"),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasDoc
                            ? const Color(0xFF15803D)
                            : (isAddLater ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Action button: View Document (if uploaded) or Upload Document (if Add Later)
          if (hasDoc)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => DocumentViewerModal.show(context, url: url, title: title),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                label: Text(
                  "View Document",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else if (isAddLater)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploadingDoc
                    ? null
                    : () => _uploadAddLaterDoc(
                          title: title,
                          docKey: docKey,
                          addLaterKey: addLaterKey,
                        ),
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: Text(
                  "Upload Document",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else
            Text(
              "Document upload pending administrator review.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
