import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/User/user_home_screen.dart';
import '../screens/User/mess_menu_screen.dart';
import '../screens/User/payments_bills_screen.dart';
import '../screens/User/tickets_screen.dart';
import '../screens/User/profile_screen.dart';
import '../screens/User/notifications_screen.dart';
import '../screens/User/settings_screen.dart';

class UserDrawer extends StatelessWidget {
  final String activeItem;

  const UserDrawer({
    super.key,
    required this.activeItem,
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
            onPressed: () {
              AuthService().logout();
              Navigator.pop(dialogContext); // close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(initialRole: LoginRole.user),
                ),
                (route) => false,
              );
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
    final student = AuthService().currentUser;
    final initials = student?.initials.isNotEmpty == true ? student!.initials : "SU";
    final name = student?.name.isNotEmpty == true ? student!.name : "Student";
    final roomInfo = student != null 
        ? "${student.building} • Room ${student.room} (Bed A)"
        : "Lakshya • Room 304 (Bed A)";
    final phoneInfo = student?.phone ?? "+91 8208285947";

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                student != null && student.profilePhotoUrl.isNotEmpty
                    ? (student.profilePhotoUrl.startsWith('http')
                        ? CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage(student.profilePhotoUrl),
                          )
                        : (student.profilePhotoUrl == 'uploaded'
                            ? CircleAvatar(
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
                              )
                            : CircleAvatar(
                                radius: 35,
                                backgroundImage: FileImage(File(student.profilePhotoUrl)),
                              )))
                    : CircleAvatar(
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
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roomInfo,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phoneInfo,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const UserHomeScreen()),
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
                        MaterialPageRoute(builder: (context) => const MessMenuScreen()),
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
                        MaterialPageRoute(builder: (context) => const PaymentsBillsScreen()),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.notifications_rounded,
                  title: "Notification",
                  isSelected: activeItem == "Notification",
                  badgeCount: 2,
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Notification") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    }
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
                        MaterialPageRoute(builder: (context) => const TicketsScreen()),
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
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                Navigator.pop(context);
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
