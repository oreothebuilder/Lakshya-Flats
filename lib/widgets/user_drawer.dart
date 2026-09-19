import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/firebase_auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/User/user_home_screen.dart';
import '../screens/User/mess_menu_screen.dart';
import '../screens/User/payments_bills_screen.dart';
import '../screens/User/tickets_screen.dart';
import '../screens/User/profile_screen.dart';
import '../screens/User/notifications_screen.dart';
import '../screens/User/settings_screen.dart';

import '../models/user_role_model.dart';
import '../services/firestore_service.dart';
import '../services/navigation_service.dart';

class UserDrawer extends StatelessWidget {
  final String activeItem;
  final AppUser? currentUser;

  const UserDrawer({
    super.key,
    required this.activeItem,
    this.currentUser,
  });

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Log Out",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          "Are you sure you want to log out of Lakshya Residency?",
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // close dialog
              try {
                await FirebaseAuthService().signOut();
              } catch (e) {
                debugPrint("Logout error: $e");
              }
              final nav = rootNavigatorKey.currentState;
              if (nav != null) {
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(initialRole: LoginRole.user),
                  ),
                  (route) => false,
                );
              } else if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(initialRole: LoginRole.user),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Log Out",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF2563EB);
    final inactiveIconColor = const Color(0xFF64748B);
    final inactiveTextColor = const Color(0xFF1E293B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveIconColor,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? activeColor : inactiveTextColor,
                  fontSize: 15.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (badgeCount != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF541FE4),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$badgeCount",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
    return Drawer(
      elevation: 0,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Builder(
              builder: (context) {
                final authUser = FirebaseAuthService().currentUser;
                final displayName = currentUser?.fullName.isNotEmpty == true
                    ? currentUser!.fullName
                    : (authUser?.displayName?.isNotEmpty == true ? authUser!.displayName! : "Resident Student");

                String initials = "RS";
                final nameParts = displayName.trim().split(RegExp(r'\s+'));
                if (nameParts.length >= 2 && nameParts[0].isNotEmpty && nameParts[1].isNotEmpty) {
                  initials = "${nameParts[0][0]}${nameParts[1][0]}".toUpperCase();
                } else if (displayName.isNotEmpty) {
                  initials = displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase();
                }

                String locationInfo = "";
                if (currentUser?.building != null && currentUser!.building!.isNotEmpty) {
                  locationInfo = currentUser!.building!;
                  if (currentUser?.room != null && currentUser!.room!.isNotEmpty) {
                    locationInfo += " • Room ${currentUser!.room!}";
                  }
                } else {
                  locationInfo = "Lakshya Residency";
                }

                final contactInfo = currentUser?.phone.isNotEmpty == true
                    ? currentUser!.phone
                    : (currentUser?.email.isNotEmpty == true
                        ? currentUser!.email
                        : (authUser?.email ?? ""));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Text(
                        initials,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF2563EB),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      displayName,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationInfo,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (contactInfo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        contactInfo,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          
          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.home_rounded,
                  title: "Home",
                  isSelected: activeItem == "Home",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Home") {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => UserHomeScreen(currentUser: currentUser)),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.restaurant_rounded,
                  title: "Mess Menu",
                  isSelected: activeItem == "Mess Menu",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Mess Menu") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MessMenuScreen(currentUser: currentUser)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.account_balance_wallet_rounded,
                  title: "Payments & Bills",
                  isSelected: activeItem == "Payments & Bills",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Payments & Bills") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => PaymentsBillsScreen(currentUser: currentUser)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getStudentNotificationsStream(
                    currentUser?.uid ?? FirebaseAuthService().currentUser?.uid ?? '',
                    building: currentUser?.building,
                    regNo: currentUser?.registrationNumber,
                  ),
                  builder: (context, snapshot) {
                    final notifs = snapshot.data ?? [];
                    final unreadCount = notifs.where((n) => n['isRead'] != true).length;

                    return _buildDrawerItem(
                      context: context,
                      icon: Icons.notifications_rounded,
                      title: "Notification",
                      isSelected: activeItem == "Notification",
                      badgeCount: unreadCount > 0 ? unreadCount : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (activeItem != "Notification") {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => NotificationsScreen(currentUser: currentUser)),
                          );
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.local_activity_rounded,
                  title: "Tickets",
                  isSelected: activeItem == "Tickets",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Tickets") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => TicketsScreen(currentUser: currentUser)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person_rounded,
                  title: "Profile",
                  isSelected: activeItem == "Profile",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Profile") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileScreen(currentUser: currentUser)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  title: "Settings",
                  isSelected: activeItem == "Settings",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Settings") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsScreen(currentUser: currentUser)),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Drawer Footer
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: InkWell(
              onTap: () {
                _handleLogout(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    "Logout",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
