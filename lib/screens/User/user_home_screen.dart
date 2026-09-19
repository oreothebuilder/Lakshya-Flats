import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_role_model.dart';
import '../../models/bill_model.dart';
import '../../models/complaint_model.dart';
import '../../services/firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../widgets/user_drawer.dart';
import 'mess_menu_screen.dart';
import '../../services/mess_menu_service.dart';
import '../../models/mess_menu_model.dart';
import 'payments_bills_screen.dart';
import 'tickets_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../../widgets/onboarding_tour_overlay.dart';
import '../../widgets/app_toast.dart';

class UserHomeScreen extends StatefulWidget {
  final AppUser? currentUser;

  const UserHomeScreen({
    super.key,
    this.currentUser,
  });

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final ScrollController _mealScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();

  // Navigation Keys for Onboarding Tour Spotlight
  final GlobalKey _drawerKey = GlobalKey();
  final GlobalKey _profileCardKey = GlobalKey();
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _messMenuKey = GlobalKey();
  final GlobalKey _billsKey = GlobalKey();
  final GlobalKey _ticketsKey = GlobalKey();
  final GlobalKey _profileAvatarKey = GlobalKey();

  late AppUser? _activeUser;
  bool _isTourActive = false;
  int _currentTourIndex = 0;
  List<TourStep> _tourSteps = [];
  static final Set<String> _dismissedPasswordNoticeUids = {};

  @override
  void initState() {
    super.initState();
    _activeUser = widget.currentUser;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveMeal();
      _checkFirstTimeUser();
    });
  }

  @override
  void dispose() {
    _mealScrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  List<TourStep> _buildTourSteps() {
    return [
      TourStep(
        targetKey: _drawerKey,
        title: "Navigation Menu",
        description: "Open the menu anytime to access your Mess Menu, Payments & Bills, Support Tickets, Profile, and Settings.",
        icon: Icons.menu_rounded,
        category: "Navigation",
        borderRadius: BorderRadius.circular(12),
      ),
      TourStep(
        targetKey: _profileCardKey,
        title: "Resident Room Details",
        description: "Check your allocated building, room number, contact information, and current residency status at a glance.",
        icon: Icons.domain_rounded,
        category: "Resident Info",
        borderRadius: BorderRadius.circular(24),
      ),
      TourStep(
        targetKey: _notificationsKey,
        title: "Notifications & Alerts",
        description: "Stay up-to-date with official announcements from hostel management, curfew notices, and maintenance alerts.",
        icon: Icons.notifications_active_rounded,
        category: "Updates",
        borderRadius: BorderRadius.circular(12),
      ),
      TourStep(
        targetKey: _messMenuKey,
        title: "Today's Mess Menu",
        description: "View scheduled meals for breakfast, lunch, snacks, and dinner. Tap 'Weekly Menu' to see the complete 7-day schedule.",
        icon: Icons.restaurant_rounded,
        category: "Dining",
        borderRadius: BorderRadius.circular(24),
      ),
      TourStep(
        targetKey: _billsKey,
        title: "Upcoming Bills & Payments",
        description: "Review outstanding hostel rent and electricity bills. Tap 'Details' to pay dues and download official payment receipts.",
        icon: Icons.account_balance_wallet_rounded,
        category: "Billing",
        borderRadius: BorderRadius.circular(24),
      ),
      TourStep(
        targetKey: _ticketsKey,
        title: "Raise a Support Ticket",
        description: "Facing any room repair, electrical, Wi-Fi, or cleaning issues? Report a ticket directly to the administration here.",
        icon: Icons.headset_mic_rounded,
        category: "Helpdesk",
        borderRadius: BorderRadius.circular(24),
      ),
      TourStep(
        targetKey: _profileAvatarKey,
        title: "Profile & Account Security",
        description: "View your personal profile, download your signed rental agreement, and manage your password securely.",
        icon: Icons.person_rounded,
        category: "Profile & Security",
        borderRadius: BorderRadius.circular(20),
      ),
    ];
  }

  bool _hasUserDismissedPasswordNotice() {
    final uid = _activeUser?.uid ?? FirebaseAuthService().currentUser?.uid;
    if (_activeUser?.hasDismissedPasswordNotice == true) return true;
    if (uid != null && _dismissedPasswordNoticeUids.contains(uid)) return true;
    return false;
  }

  Future<void> _dismissPasswordNotice() async {
    final uid = _activeUser?.uid ?? FirebaseAuthService().currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _dismissedPasswordNoticeUids.add(uid);
    }
    if (_activeUser != null && _activeUser!.hasDismissedPasswordNotice) return;

    if (mounted) {
      setState(() {
        _activeUser = _activeUser?.copyWith(hasDismissedPasswordNotice: true);
      });
    }

    if (uid != null && uid.isNotEmpty) {
      await FirestoreService().markPasswordNoticeDismissed(
        uid,
        studentId: _activeUser?.studentId,
      );
    }
  }

  void _checkFirstTimeUser() {
    if (_activeUser != null && _activeUser!.isStudent && !_activeUser!.hasCompletedOnboardingTour) {
      OnboardingWelcomeModal.show(
        context,
        userName: _activeUser!.fullName,
        onContinue: () {
          _startTour();
        },
        onDismiss: () {
          _dismissTour();
        },
      );
    } else if (_activeUser != null &&
        _activeUser!.isStudent &&
        !_activeUser!.hasChangedDefaultPassword &&
        !_hasUserDismissedPasswordNotice()) {
      _checkSecurityPasswordPrompt();
    }
  }

  void _startTour() {
    _tourSteps = _buildTourSteps();
    setState(() {
      _isTourActive = true;
      _currentTourIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToTourStep(0);
    });
  }

  Future<void> _goToTourStep(int index) async {
    if (index < 0 || index >= _tourSteps.length) return;

    final targetContext = _tourSteps[index].targetKey.currentContext;
    if (targetContext != null) {
      try {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          alignment: 0.25,
        );
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _currentTourIndex = index;
      });
    }
  }

  Future<void> _dismissTour() async {
    setState(() {
      _isTourActive = false;
    });
    final uid = _activeUser?.uid ?? FirebaseAuthService().currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      await FirestoreService().markTourCompleted(uid);
    }
    if (mounted) {
      setState(() {
        _activeUser = _activeUser?.copyWith(hasCompletedOnboardingTour: true);
      });
      if (!_activeUser!.hasChangedDefaultPassword && !_hasUserDismissedPasswordNotice()) {
        _checkSecurityPasswordPrompt();
      }
    }
  }

  Future<void> _finishTour() async {
    setState(() {
      _isTourActive = false;
    });
    final uid = _activeUser?.uid ?? FirebaseAuthService().currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      await FirestoreService().markTourCompleted(uid);
    }
    if (mounted) {
      setState(() {
        _activeUser = _activeUser?.copyWith(hasCompletedOnboardingTour: true);
      });
      AppToast.showSuccess(
        context,
        "You're all set! Enjoy your stay at Lakshya Residency.",
      );
      if (!_activeUser!.hasChangedDefaultPassword && !_hasUserDismissedPasswordNotice()) {
        _checkSecurityPasswordPrompt();
      }
    }
  }

  void _checkSecurityPasswordPrompt() {
    if (_activeUser == null ||
        !_activeUser!.isStudent ||
        _activeUser!.hasChangedDefaultPassword ||
        _hasUserDismissedPasswordNotice()) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.security_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Security Notice",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "For your security, please change your password before continuing. You are currently using the temporary default password issued during student onboarding.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _dismissPasswordNotice();
            },
            child: Text(
              "Later",
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _dismissPasswordNotice();
              _openChangePasswordScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              "Change Password",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).then((_) {
      // If dialog dismissed via outside tap or back button, record dismissal
      _dismissPasswordNotice();
    });
  }

  Future<void> _openChangePasswordScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          currentUser: _activeUser,
          autoOpenChangePassword: true,
        ),
      ),
    );

    if (result == true || mounted) {
      final uid = _activeUser?.uid ?? FirebaseAuthService().currentUser?.uid;
      if (uid != null) {
        final updatedUser = await FirestoreService().getAppUser(uid, emailHint: _activeUser?.email);
        if (updatedUser != null && mounted) {
          setState(() {
            _activeUser = updatedUser;
          });
        }
      }
    }
  }

  void _scrollToActiveMeal() {
    final activeMeal = _getActiveMeal();
    if (activeMeal == null) return;

    int index = -1;
    if (activeMeal == "Breakfast") {
      index = 0;
    } else if (activeMeal == "Lunch") {
      index = 1;
    } else if (activeMeal == "Evening Snacks") {
      index = 2;
    } else if (activeMeal == "Dinner") {
      index = 3;
    }

    if (index >= 0 && _mealScrollController.hasClients) {
      final offset = index * 272.0; // 260 width + 12 margin
      _mealScrollController.jumpTo(offset);
    }
  }

  String _formatRelativeTime(dynamic createdAt) {
    if (createdAt == null) return "Just now";
    DateTime date;
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    } else if (createdAt is DateTime) {
      date = createdAt;
    } else {
      date = DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
    }
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}";
  }

  String _formatIndianCurrency(double amount) {
    int val = amount.round();
    if (val < 0) val = 0;
    String s = val.toString();
    if (s.length <= 3) return "₹$s";
    String lastThree = s.substring(s.length - 3);
    String otherNumbers = s.substring(0, s.length - 3);
    if (otherNumbers.isNotEmpty) {
      RegExp reg = RegExp(r'(\d+?)(?=(\d{2})+(?!\d))');
      otherNumbers = otherNumbers.replaceAllMapped(reg, (Match m) => "${m[1]},");
    }
    return "₹$otherNumbers,$lastThree";
  }

  IconData _getBillIcon(BillModel bill) {
    final lower = "${bill.billType} ${bill.billingMonth}".toLowerCase();
    if (lower.contains('electricity') || lower.contains('power')) {
      return Icons.bolt_rounded;
    } else if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi_rounded;
    } else if (lower.contains('mess') || lower.contains('food') || lower.contains('dining')) {
      return Icons.restaurant_rounded;
    } else if (lower.contains('deposit') || lower.contains('security')) {
      return Icons.shield_rounded;
    } else if (lower.contains('cleaning') || lower.contains('maintenance')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.home_rounded;
  }

  Widget _buildRejectionWarningBanner(BillModel bill) {
    final billTitle = bill.billingMonth.isNotEmpty ? bill.billingMonth : bill.billType;
    final reason = (bill.adminRemarks != null && bill.adminRemarks!.isNotEmpty)
        ? bill.adminRemarks!
        : "Payment proof could not be verified. Please review and re-submit.";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF87171), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Text(
                              "ACTION REQUIRED",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFDC2626),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Dismiss button (Permanently removes warning from dashboard)
                          InkWell(
                            onTap: () async {
                              await FirestoreService().dismissBillRejection(bill.id);
                              if (mounted) {
                                AppToast.showInfo(
                                  context,
                                  "Warning dismissed. You can re-submit anytime from Payments & Bills.",
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Dismiss",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF991B1B),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.close_rounded, size: 14, color: Color(0xFF991B1B)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Payment Proof Rejected",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$billTitle • ₹${bill.balance.toStringAsFixed(0)}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7F1D1D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Reason bubble
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7F1D1D),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Re-submit button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentsBillsScreen(
                        currentUser: _activeUser ?? widget.currentUser,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  "Re-submit Payment Proof",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
      drawer: UserDrawer(activeItem: "Home", currentUser: _activeUser ?? widget.currentUser),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              key: _drawerKey,
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.domain_rounded,
                color: Color(0xFF1A65D6),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Student Portal",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    "${_activeUser?.building ?? widget.currentUser?.building ?? 'Lakshya'} • ${_activeUser?.room ?? widget.currentUser?.room ?? 'Resident'}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getStudentNotificationsStream(
              _activeUser?.uid ?? widget.currentUser?.uid ?? FirebaseAuthService().currentUser?.uid ?? '',
              building: _activeUser?.building ?? widget.currentUser?.building,
              regNo: _activeUser?.registrationNumber ?? widget.currentUser?.registrationNumber,
            ),
            builder: (context, notifSnapshot) {
              final notifs = notifSnapshot.data ?? [];
              final unreadCount = notifs.where((n) => n['isRead'] != true).length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    key: _notificationsKey,
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
                    tooltip: "Notifications",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(currentUser: _activeUser ?? widget.currentUser),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount > 9 ? "9+" : "$unreadCount",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 9,
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
            key: _profileAvatarKey,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(currentUser: _activeUser ?? widget.currentUser),
                ),
              );
              // Refresh user if needed
              final uid = _activeUser?.uid ?? FirebaseAuthService().currentUser?.uid;
              if (uid != null && mounted) {
                final updated = await FirestoreService().getAppUser(uid, emailHint: _activeUser?.email);
                if (updated != null && mounted) {
                  setState(() => _activeUser = updated);
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12, left: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF541FE4),
                child: Text(
                  (_activeUser?.fullName.isNotEmpty ?? widget.currentUser?.fullName.isNotEmpty ?? false)
                      ? (_activeUser?.fullName ?? widget.currentUser!.fullName).substring(0, 1).toUpperCase()
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
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _mainScrollController,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Payment Rejection Warning Banner (Live Stream)
              StreamBuilder<List<BillModel>>(
                stream: FirestoreService().getStudentBillsStream(
                  _activeUser?.studentId ??
                      widget.currentUser?.studentId ??
                      _activeUser?.uid ??
                      widget.currentUser?.uid ??
                      FirebaseAuthService().currentUser?.uid ??
                      '',
                  phone: _activeUser?.phone ?? widget.currentUser?.phone,
                  email: _activeUser?.email ?? widget.currentUser?.email,
                  regNo: _activeUser?.registrationNumber ?? widget.currentUser?.registrationNumber,
                ),
                builder: (context, snapshot) {
                  final bills = snapshot.data ?? [];
                  final activeRejected = bills.where((b) => b.hasActiveRejectionWarning).toList();
                  if (activeRejected.isEmpty) return const SizedBox.shrink();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: activeRejected.map((bill) => _buildRejectionWarningBanner(bill)).toList(),
                  );
                },
              ),

              // User Profile Banner Card
              Container(
                key: _profileCardKey,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      ((_activeUser ?? widget.currentUser)?.fullName.isNotEmpty ?? false)
                                          ? (_activeUser ?? widget.currentUser)!.fullName.substring(0, 1).toUpperCase()
                                          : "R",
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Welcome Resident 🌅",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        (_activeUser ?? widget.currentUser)?.fullName ?? "Resident",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_android_rounded, color: Colors.white70, size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            ((_activeUser ?? widget.currentUser)?.phone.isNotEmpty ?? false)
                                                ? (_activeUser ?? widget.currentUser)!.phone
                                                : ((_activeUser ?? widget.currentUser)?.email ?? ""),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              color: Colors.white.withValues(alpha: 0.85),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.domain_rounded, color: Color(0xFFFCD34D), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "BUILDING",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white70,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              Text(
                                                (_activeUser ?? widget.currentUser)?.building ?? "Lakshya",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.single_bed_rounded, color: Color(0xFF34D399), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "ROOM & STATUS",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white70,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              Text(
                                                (_activeUser ?? widget.currentUser)?.room ?? "Active",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
              ),
              const SizedBox(height: 20),

              // Recent Notification Card (Live Firestore Stream)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService().getStudentNotificationsStream(
                  widget.currentUser?.uid ?? FirebaseAuthService().currentUser?.uid ?? '',
                  building: widget.currentUser?.building,
                  regNo: widget.currentUser?.registrationNumber,
                ),
                builder: (context, notifSnapshot) {
                  final notifs = notifSnapshot.data ?? [];
                  final unreadCount = notifs.where((n) => n['isRead'] != true).length;
                  final latestNotif = notifs.isNotEmpty ? notifs.first : null;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE0F2FE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: Color(0xFF0284C7),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Recent Notification",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      if (unreadCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "$unreadCount New",
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Updates from hostel administration",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotificationsScreen(currentUser: widget.currentUser),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "View All",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (latestNotif != null) ...[
                          const SizedBox(height: 14),
                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: latestNotif['isRead'] == true ? const Color(0xFF94A3B8) : const Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  latestNotif['category']?.toString().toUpperCase() ?? "NOTICE",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2563EB),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatRelativeTime(latestNotif['createdAt']),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  latestNotif['title'] ?? "Hostel Announcement",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  latestNotif['message'] ?? "",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "No notifications right now.",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Today's Mess Menu Card (Dynamic for CURRENT day)
              ListenableBuilder(
                listenable: MessMenuService(),
                builder: (context, _) {
                  final menuService = MessMenuService();
                  final currentDayName = menuService.getCurrentDayName();
                  final messName = menuService.resolveMessForBuilding(widget.currentUser?.building);
                  final todayMenu = menuService.getTodayMenu(messName);

                  String getMealImage(MealType type) {
                    switch (type) {
                      case MealType.breakfast:
                        return "assets/images/breakfast.jpg";
                      case MealType.lunch:
                        return "assets/images/lunch.jpg";
                      case MealType.snacks:
                        return "assets/images/snacks.jpg";
                      case MealType.dinner:
                        return "assets/images/dinner.jpg";
                    }
                  }

                  final meals = todayMenu?.meals ?? [];

                  return Container(
                    key: _messMenuKey,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF7ED),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.restaurant_rounded,
                                color: Color(0xFFEA580C),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's Mess Menu",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "$currentDayName • ${widget.currentUser?.building ?? 'Lakshya'}",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessMenuScreen(currentUser: widget.currentUser),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF541FE4)),
                              label: Text(
                                "Weekly Menu",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF541FE4),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                backgroundColor: const Color(0xFFEFF0FE),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Horizontal scrollable meal tiles
                        SizedBox(
                          height: 180,
                          child: SingleChildScrollView(
                            controller: _mealScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: meals.map((meal) {
                                return _buildMealTile(
                                  title: meal.title,
                                  time: meal.timeSlot,
                                  menu: meal.items.join(", "),
                                  imagePath: getMealImage(meal.type),
                                  isActive: _getActiveMeal() == meal.title,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Upcoming Bills Section (Live Firestore Stream)
              StreamBuilder<List<BillModel>>(
                stream: FirestoreService().getStudentBillsStream(
                  _activeUser?.studentId ??
                      widget.currentUser?.studentId ??
                      _activeUser?.uid ??
                      widget.currentUser?.uid ??
                      FirebaseAuthService().currentUser?.uid ??
                      '',
                  phone: _activeUser?.phone ?? widget.currentUser?.phone,
                  email: _activeUser?.email ?? widget.currentUser?.email,
                  regNo: _activeUser?.registrationNumber ?? widget.currentUser?.registrationNumber,
                ),
                builder: (context, snapshot) {
                  final allBills = snapshot.data ?? [];
                  final pendingBills = allBills.where((b) => !b.isPaid).toList();
                  final totalOutstanding = pendingBills.fold(0.0, (acc, b) => acc + b.balance);

                  return Container(
                    key: _billsKey,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: pendingBills.isNotEmpty ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: pendingBills.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Upcoming Bills",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pendingBills.isNotEmpty
                                        ? "Total Outstanding: ${_formatIndianCurrency(totalOutstanding)}"
                                        : "All Dues Cleared",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: pendingBills.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentsBillsScreen(currentUser: widget.currentUser),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Details",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (pendingBills.isEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD1FAE5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.task_alt_rounded, color: Color(0xFF10B981), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "No Pending Dues",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        "All your hostel & utility fees are completely clear.",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ...pendingBills.take(2).map((b) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildBillItem(
                                  icon: _getBillIcon(b),
                                  title: b.billingMonth.isNotEmpty ? b.billingMonth : b.billType,
                                  dueDate: "Due: ${_formatDate(b.dueDate)}",
                                  amount: _formatIndianCurrency(b.balance),
                                  onPay: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PaymentsBillsScreen(currentUser: widget.currentUser),
                                      ),
                                    );
                                  },
                                ),
                              )),
                          if (pendingBills.length > 2)
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentsBillsScreen(currentUser: widget.currentUser),
                                    ),
                                  );
                                },
                                child: Text(
                                  "→ View +${pendingBills.length - 2} more payments in Details",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Raise a Ticket Card & Recent Tickets
              Container(
                key: _ticketsKey,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDBEAFE).withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.headset_mic_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Raise a Ticket",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Report maintenance or mess issues directly to the administration.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TicketsScreen(currentUser: widget.currentUser),
                            ),
                          );
                        },
                        icon: const Icon(Icons.confirmation_number_outlined, size: 18, color: Color(0xFF3B82F6)),
                        label: Text(
                          "Raise Ticket",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3B82F6), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Tickets",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TicketsScreen(currentUser: widget.currentUser),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "View All",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<List<ComplaintModel>>(
                      stream: (widget.currentUser?.uid.isNotEmpty ?? false)
                          ? FirestoreService().getStudentComplaintsStream(
                              widget.currentUser!.uid,
                              studentName: widget.currentUser?.fullName,
                              studentEmail: widget.currentUser?.email,
                              studentPhone: widget.currentUser?.phone,
                            )
                          : FirestoreService().getComplaintsStream(),
                      builder: (context, snapshot) {
                        final tickets = snapshot.data ?? [];
                        if (tickets.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Center(
                              child: Text(
                                "No active tickets. Tap 'Raise Ticket' to report an issue.",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: tickets.take(2).map((ticket) {
                            Color statusColor = const Color(0xFF2563EB);
                            Color statusBg = const Color(0xFFEFF6FF);
                            if (ticket.status == ComplaintModel.statusUnderExecution) {
                              statusColor = const Color(0xFFF59E0B);
                              statusBg = const Color(0xFFFFFBEB);
                            } else if (ticket.status == ComplaintModel.statusResolved) {
                              statusColor = const Color(0xFF10B981);
                              statusBg = const Color(0xFFECFDF5);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildTicketRow(
                                title: ticket.title,
                                date: _formatDate(ticket.createdAt),
                                status: ticket.status,
                                statusColor: statusColor,
                                statusBg: statusBg,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    if (_isTourActive)
      Positioned.fill(
        child: OnboardingTourOverlay(
          steps: _tourSteps,
          currentStepIndex: _currentTourIndex,
          onNext: () {
            if (_currentTourIndex < _tourSteps.length - 1) {
              _goToTourStep(_currentTourIndex + 1);
            } else {
              _finishTour();
            }
          },
          onBack: () {
            if (_currentTourIndex > 0) {
              _goToTourStep(_currentTourIndex - 1);
            }
          },
          onDismiss: _dismissTour,
        ),
      ),
  ],
);
}

  Widget _buildMealTile({
    required String title,
    required String time,
    required String menu,
    required String imagePath,
    required bool isActive,
  }) {
    return Container(
      width: 260,
      height: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: isActive
            ? Border.all(color: const Color(0xFF34D399), width: 2.0)
            : Border.all(color: Colors.transparent, width: 2.0),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF34D399).withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.70),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.4, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            // Text Content
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981), // Emerald green
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    menu,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getActiveMeal() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final time = hour + (minute / 60.0);

    if (time >= 7.5 && time < 9.5) {
      return "Breakfast";
    } else if (time >= 12.5 && time < 14.5) {
      return "Lunch";
    } else if (time >= 17.0 && time < 18.0) {
      return "Evening Snacks";
    } else if (time >= 19.5 && time < 21.5) {
      return "Dinner";
    }
    return null;
  }

  Widget _buildBillItem({
    required IconData icon,
    required String title,
    required String dueDate,
    required String amount,
    required VoidCallback onPay,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dueDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: onPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Pay Now",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketRow({
    required String title,
    required String date,
    required String status,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
