import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_role_model.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/user_drawer.dart';
import 'payments_bills_screen.dart';
import 'profile_screen.dart';
import 'tickets_screen.dart';
import 'user_home_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final AppUser? currentUser;

  const NotificationsScreen({
    super.key,
    this.currentUser,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String get _studentId =>
      widget.currentUser?.uid ?? FirebaseAuthService().currentUser?.uid ?? '';

  void _markAllAsRead() async {
    if (_studentId.isEmpty) return;
    await FirestoreService().markAllNotificationsAsRead(_studentId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "All notifications marked as read",
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _markAsRead(String id) async {
    if (_studentId.isEmpty) return;
    await FirestoreService().markNotificationAsRead(_studentId, id);
  }

  void _handleBackToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => UserHomeScreen(currentUser: widget.currentUser),
      ),
      (route) => false,
    );
  }

  String _formatTimestamp(dynamic createdAt) {
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

  String _getGroupName(dynamic createdAt) {
    if (createdAt == null) return "TODAY";
    DateTime date;
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    } else if (createdAt is DateTime) {
      date = createdAt;
    } else {
      date = DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(date.year, date.month, date.day);

    final diff = today.difference(notificationDate).inDays;
    if (diff <= 0) return "TODAY";
    if (diff == 1) return "YESTERDAY";
    return "PREVIOUS";
  }

  IconData _getCategoryIcon(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'maintenance':
        return Icons.confirmation_number_rounded;
      case 'payment':
        return Icons.credit_card_rounded;
      case 'mess':
        return Icons.restaurant_rounded;
      case 'urgent':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getCategoryColor(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'maintenance':
        return const Color(0xFFD97706); // Amber
      case 'payment':
        return const Color(0xFF1D4ED8); // Blue
      case 'mess':
        return const Color(0xFF059669); // Emerald
      case 'urgent':
        return const Color(0xFFDC2626); // Red
      default:
        return const Color(0xFF4F46E5); // Indigo
    }
  }

  Color _getCategoryBg(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'maintenance':
        return const Color(0xFFFFF7ED);
      case 'payment':
        return const Color(0xFFEFF6FF);
      case 'mess':
        return const Color(0xFFECFDF5);
      case 'urgent':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFEEF2FF);
    }
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
        drawer: UserDrawer(activeItem: "Notification"),
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
          "Notifications",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: Color(0xFF1D4ED8)),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8, left: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  "SU",
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
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().getStudentNotificationsStream(_studentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 40,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No Notifications Yet",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "You will receive real-time updates here whenever administration updates your maintenance tickets, posts announcements, or issues bills.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Group notifications dynamically
            final groups = <String, List<Map<String, dynamic>>>{};
            for (var n in notifications) {
              final group = _getGroupName(n["createdAt"]);
              groups.putIfAbsent(group, () => []).add(n);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Notifications (${notifications.length})",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      InkWell(
                        onTap: _markAllAsRead,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.done_all_rounded,
                                color: Color(0xFF1D4ED8),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Mark all as read",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Main Notifications Card Wrapper
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ...["TODAY", "YESTERDAY", "PREVIOUS"].where((g) => groups.containsKey(g)).map((groupName) {
                          final items = groups[groupName]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 8.0),
                                child: Text(
                                  groupName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (context, index) => const Divider(
                                  color: Color(0xFFF1F5F9),
                                  height: 1,
                                  thickness: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final isUnread = item["isRead"] != true;
                                  final category = (item["category"] ?? "General").toString();
                                  final icon = _getCategoryIcon(category);
                                  final iconColor = _getCategoryColor(category);
                                  final iconBg = _getCategoryBg(category);
                                  final title = (item["title"] ?? "Notification").toString();
                                  final message = (item["message"] ?? item["description"] ?? "").toString();
                                  final timestamp = _formatTimestamp(item["createdAt"]);

                                  final isMaintenance = category.toLowerCase() == 'maintenance';
                                  final isPayment = category.toLowerCase() == 'payment';

                                  return InkWell(
                                    onTap: () => _markAsRead(item["id"]),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: isUnread
                                            ? const Border(
                                                left: BorderSide(
                                                  color: Color(0xFF1D4ED8),
                                                  width: 3.5,
                                                ),
                                              )
                                            : null,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Icon
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: iconBg,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              icon,
                                              color: iconColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          // Content details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              title,
                                                              style: GoogleFonts.plusJakartaSans(
                                                                fontSize: 14.5,
                                                                fontWeight: FontWeight.w700,
                                                                color: const Color(0xFF0F172A),
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          if (isUnread) ...[
                                                            const SizedBox(width: 6),
                                                            Container(
                                                              width: 6,
                                                              height: 6,
                                                              decoration: const BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                color: Color(0xFF1D4ED8),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      timestamp,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: const Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  message,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color(0xFF475569),
                                                    height: 1.4,
                                                  ),
                                                ),
                                                if (isMaintenance) ...[
                                                  const SizedBox(height: 10),
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      _markAsRead(item["id"]);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => TicketsScreen(currentUser: widget.currentUser),
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(Icons.confirmation_number_outlined, size: 14),
                                                    label: Text(
                                                      "View Tickets",
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFFD97706),
                                                      foregroundColor: Colors.white,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                  ),
                                                ] else if (isPayment) ...[
                                                  const SizedBox(height: 10),
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      _markAsRead(item["id"]);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => PaymentsBillsScreen(currentUser: widget.currentUser),
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(Icons.payment_rounded, size: 14),
                                                    label: Text(
                                                      "View Bill",
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF1D4ED8),
                                                      foregroundColor: Colors.white,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  }
}
