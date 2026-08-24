import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../screens/login_screen.dart';
import '../screens/Admin/dashboard_screen.dart';
import '../screens/mess_menu_management_screen.dart';
import '../screens/student_onboarding_screen.dart';
import '../screens/Admin/students_directory_screen.dart';
import '../screens/Admin/broadcast_notification_screen.dart';

class AdminDrawer extends StatelessWidget {
  final String activeItem;

  const AdminDrawer({
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
          "Are you sure you want to log out of Lakshya Residency Admin?",
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
              Navigator.pop(dialogContext);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(initialRole: LoginRole.manager),
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
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF0D52CE);
    final inactiveIconColor = const Color(0xFF334155);
    final inactiveTextColor = const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveIconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Admin Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 54, left: 20, right: 20, bottom: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF0D52CE),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.domain_rounded,
                      color: Color(0xFF0D52CE),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Lakshya Residency Admin",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "owner@lakshya.com",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.grid_view_rounded,
                  title: "Dashboard",
                  isSelected: activeItem == "Dashboard",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Dashboard") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      );
                    }
                  },
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.apartment_rounded,
                  title: "Building",
                  isSelected: activeItem == "Building",
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Building selected.", style: GoogleFonts.plusJakartaSans()),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.payments_outlined,
                  title: "Payment Collection",
                  isSelected: activeItem == "Payment Collection",
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Payment Collection selected.", style: GoogleFonts.plusJakartaSans()),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.campaign_outlined,
                  title: "Broadcast Notification",
                  isSelected: activeItem == "Broadcast Notification",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Broadcast Notification") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BroadcastNotificationScreen(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.flatware_outlined,
                  title: "Mess Menu\nManagement",
                  isSelected: activeItem == "Mess Menu Management",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Mess Menu Management") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MessMenuManagementScreen(
                            initialMess: "Univ Homes",
                            isAdmin: true,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.badge_outlined,
                  title: "Student Onboarding\nPage",
                  isSelected: activeItem == "Student Onboarding Page",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Student Onboarding Page") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentOnboardingScreen(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.group_outlined,
                  title: "Students Directory",
                  isSelected: activeItem == "Students Directory",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Students Directory") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentsDirectoryScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: InkWell(
              onTap: () => _handleLogout(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 14),
                    Text(
                      "Log Out",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.redAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
