import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_role_model.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/user_drawer.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'user_home_screen.dart';
import '../../widgets/app_toast.dart';

class SettingsScreen extends StatefulWidget {
  final AppUser? currentUser;

  const SettingsScreen({
    super.key,
    this.currentUser,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;

  // Account State
  late String _email;
  late String _phone;
  String _passwordSubtext = "Protected with Lakshya Auth";

  // Preference State
  String _selectedLanguage = "English (US)";
  bool _isLightTheme = true;

  // Deletion State
  bool _deletionRequested = false;
  DateTime? _deletionRequestedAt;
  String? _deletionReason;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  final List<String> _languages = [
    "English (US)",
    "English (UK)",
    "Hindi (IN)",
    "Spanish (ES)",
    "French (FR)",
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.currentUser;
    final authUser = FirebaseAuthService().currentUser;
    _email = (u?.email.isNotEmpty == true)
        ? u!.email
        : (authUser?.email ?? "");
    _phone = (u?.phone.isNotEmpty == true)
        ? u!.phone
        : (authUser?.phoneNumber ?? "");
    _phoneController = TextEditingController(text: _phone);

    _deletionRequested = u?.deletionRequested ?? false;
    _deletionRequestedAt = u?.deletionRequestedAt;
    _deletionReason = u?.deletionReason;
    _subscribeToUserStatus();
  }

  void _subscribeToUserStatus() {
    final uid = widget.currentUser?.uid ?? FirebaseAuthService().currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    _userDocSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snap) {
      if (snap.exists && snap.data() != null && mounted) {
        final data = snap.data()!;
        DateTime? delReqAt;
        if (data['deletionRequestedAt'] != null) {
          if (data['deletionRequestedAt'] is Timestamp) {
            delReqAt = (data['deletionRequestedAt'] as Timestamp).toDate();
          } else if (data['deletionRequestedAt'] is String) {
            delReqAt = DateTime.tryParse(data['deletionRequestedAt']);
          }
        }
        setState(() {
          _deletionRequested = data['deletionRequested'] == true;
          _deletionRequestedAt = delReqAt;
          _deletionReason = data['deletionReason']?.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  void _showDeleteAccountDialog() {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

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
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Delete Account Request",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Notice: Students cannot directly delete their account. Confirming this will forward a deletion request to the Hostel Administrator for review and directory removal.",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF92400E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "What happens next?",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "• Your request is placed in the Administrator's queue.\n"
                      "• Administration will verify pending dues, room vacating status, and deposits.\n"
                      "• The Administrator will permanently delete your resident record from the Student Directory.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Reason for Deletion (Optional)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: "e.g. Vacating hostel, course finished, incorrect registration...",
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: Text(
                    "Keep Account",
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          final u = widget.currentUser;
                          final authUser = FirebaseAuthService().currentUser;
                          final uid = u?.uid ?? authUser?.uid ?? '';
                          final sid = u?.studentId ?? uid;
                          final name = u?.fullName ?? authUser?.displayName ?? 'Resident Student';
                          final email = _email;
                          final phone = _phone;
                          final bldg = u?.building ?? '';
                          final room = u?.room ?? '';
                          final reg = u?.registrationNumber ?? '';
                          final reason = reasonController.text.trim();

                          try {
                            await FirestoreService().requestAccountDeletion(
                              userId: uid,
                              studentId: sid,
                              fullName: name,
                              email: email,
                              phone: phone,
                              building: bldg,
                              room: room,
                              registrationNumber: reg,
                              reason: reason.isNotEmpty ? reason : null,
                            );

                            if (mounted) {
                              setState(() {
                                _deletionRequested = true;
                                _deletionRequestedAt = DateTime.now();
                                _deletionReason = reason.isNotEmpty ? reason : null;
                              });
                            }

                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            if (mounted) {
                              AppToast.showSuccess(
                                context,
                                "Account deletion request sent to administrator for review.",
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (mounted) {
                              AppToast.showError(context, "Failed to submit request: $e");
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          "Submit Request",
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmCancelDeletionRequest() {
    bool isCancelling = false;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (_, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Cancel Deletion Request?",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              content: Text(
                "Are you sure you want to cancel your account deletion request? Your resident account will remain active in the system.",
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: isCancelling ? null : () => Navigator.pop(dialogCtx),
                  child: Text(
                    "Back",
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: isCancelling
                      ? null
                      : () async {
                          setModalState(() => isCancelling = true);
                          final u = widget.currentUser;
                          final uid = u?.uid ?? FirebaseAuthService().currentUser?.uid ?? '';
                          final sid = u?.studentId ?? uid;
                          try {
                            await FirestoreService().cancelAccountDeletionRequest(uid, studentId: sid);
                            if (mounted) {
                              setState(() {
                                _deletionRequested = false;
                                _deletionRequestedAt = null;
                                _deletionReason = null;
                              });
                            }
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            if (mounted) {
                              AppToast.showSuccess(context, "Account deletion request has been cancelled.");
                            }
                          } catch (e) {
                            setModalState(() => isCancelling = false);
                            if (mounted) {
                              AppToast.showError(context, "Failed to cancel request: $e");
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isCancelling
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("Cancel Request", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    bool obscureCurrent = true;
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
                key: dialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Current Password",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          hintText: "Enter current password",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? "Field cannot be empty" : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "New Password",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          hintText: "Enter new password",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
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
                          if (v == null || v.trim().isEmpty) return "Field cannot be empty";
                          if (v.trim().length < 6) return "Password must be at least 6 characters";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Confirm New Password",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        enabled: !isSubmitting,
                        decoration: InputDecoration(
                          hintText: "Confirm new password",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
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
                          if (v != newPasswordController.text) {
                            return "Passwords do not match";
                          }
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
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (dialogFormKey.currentState!.validate()) {
                            setModalState(() => isSubmitting = true);
                            final navigator = Navigator.of(dialogCtx);
                            final currentPass = currentPasswordController.text.trim();
                            final newPass = newPasswordController.text.trim();
                            try {
                              await FirebaseAuthService().changePassword(
                                currentPassword: currentPass,
                                newPassword: newPass,
                              );
                              setState(() {
                                _passwordSubtext = "Last changed just now";
                              });
                              navigator.pop();
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          "Update",
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

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _phone = _phoneController.text.trim();
      });

      final sId = widget.currentUser?.uid ??
          widget.currentUser?.studentId ??
          FirebaseAuthService().currentUser?.uid ??
          '';
      if (sId.isNotEmpty) {
        try {
          await FirestoreService().updateStudentProfile(sId, {
            'phone': _phone,
          });
        } catch (e) {
          debugPrint("Error updating phone in Firestore: $e");
        }
      }

      if (!mounted) return;
      AppToast.showSuccess(context, "Settings saved successfully!");
    }
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
        drawer: UserDrawer(activeItem: "Settings", currentUser: widget.currentUser),
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
            "Settings",
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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(currentUser: widget.currentUser)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8, left: 4),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    (widget.currentUser?.fullName.isNotEmpty ?? false)
                        ? widget.currentUser!.fullName.substring(0, 1).toUpperCase()
                        : "R",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Settings Header
                Text(
                  "Settings",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Manage your account preferences and secure your profile.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Card 1: Account Settings
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF1D4ED8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Account Settings",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Email Address (Disabled style)
                      Text(
                        "Email Address",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _email,
                        readOnly: true,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Contact administration to change primary email.",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Phone Number (Editable)
                      Text(
                        "Phone Number",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            return "Phone number cannot be empty";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Password Group
                      Text(
                        "Password",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _passwordSubtext,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _showChangePasswordDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: Text(
                          "Change Password",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card 2: App Preferences
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.palette_outlined,
                              color: Color(0xFF1D4ED8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "App Preferences",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Language Dropdown
                      Text(
                        "Language",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLanguage,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                        items: _languages.map((String lang) {
                          return DropdownMenuItem<String>(
                            value: lang,
                            child: Text(lang),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedLanguage = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Theme Selection (Light/Dark buttons)
                      Text(
                        "Theme",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Light button
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isLightTheme = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _isLightTheme ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                                    width: _isLightTheme ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.wb_sunny_outlined,
                                      color: _isLightTheme ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Light",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: _isLightTheme ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Dark button
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isLightTheme = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: !_isLightTheme ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                                    width: !_isLightTheme ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.nightlight_round_outlined,
                                      color: !_isLightTheme ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Dark",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: !_isLightTheme ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Card 3: Account Deletion / Management
                const SizedBox(height: 20),
                _buildDangerZoneCard(),
                const SizedBox(height: 32),

                // Save Changes button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: Text(
                      "Save Changes",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

  Widget _buildDangerZoneCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _deletionRequested ? const Color(0xFFFED7AA) : const Color(0xFFFEE2E2),
          width: 1.2,
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
                  color: _deletionRequested ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _deletionRequested ? Icons.hourglass_top_rounded : Icons.delete_outline_rounded,
                  color: _deletionRequested ? const Color(0xFFEA580C) : const Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Account Management",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_deletionRequested) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Deletion Request Pending Admin Review",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You have submitted a request to delete your student resident account. The administrator will review your clearance in the Student Directory and complete permanent deletion.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFFB45309),
                      height: 1.4,
                    ),
                  ),
                  if (_deletionReason != null && _deletionReason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Reason: $_deletionReason",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF78350F),
                        ),
                      ),
                    ),
                  ],
                  if (_deletionRequestedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Submitted on: ${_formatDateTime(_deletionRequestedAt!)}",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _confirmCancelDeletionRequest,
              icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF475569)),
              label: Text(
                "Cancel Deletion Request",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF334155),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ] else ...[
            Text(
              "Delete Account",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Submit a request to the hostel administration to permanently remove your account and resident profile from the student directory.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showDeleteAccountDialog,
              icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Color(0xFFDC2626)),
              label: Text(
                "Request Account Deletion",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFDC2626),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                backgroundColor: const Color(0xFFFFF1F2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? "PM" : "AM";
    final minute = dt.minute.toString().padLeft(2, '0');
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $period";
  }
}
