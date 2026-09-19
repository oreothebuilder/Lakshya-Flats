import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_role_model.dart';
import '../theme/app_colors.dart';
import '../services/firebase_auth_service.dart';
import '../services/navigation_service.dart';
import '../screens/login_screen.dart';
import '../screens/Admin/dashboard_screen.dart';
import '../screens/mess_menu_management_screen.dart';
import '../screens/student_onboarding_screen.dart';
import '../screens/Admin/students_directory_screen.dart';
import '../screens/Admin/broadcast_notification_screen.dart';
import '../screens/Admin/payment_collection_screen.dart';
import '../screens/Admin/buildings_management_screen.dart';
import '../screens/Admin/tickets_management_screen.dart';
import '../screens/Admin/expense_tracker_screen.dart';
import '../screens/Admin/personal_todo_screen.dart';
import '../screens/Admin/staff_screen.dart';

class AdminDrawer extends StatelessWidget {
  final String activeItem;
  final AppUser? currentUser;

  const AdminDrawer({
    super.key,
    required this.activeItem,
    this.currentUser,
  });

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Log Out",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          "Are you sure you want to log out of the admin panel?",
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
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
              Navigator.pop(dialogContext);
              try {
                await FirebaseAuthService().signOut();
              } catch (e) {
                debugPrint("Admin logout error: $e");
              }
              final nav = rootNavigatorKey.currentState;
              if (nav != null) {
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(initialRole: LoginRole.manager),
                  ),
                  (route) => false,
                );
              } else if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(initialRole: LoginRole.manager),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentUser?.fullName ?? "Lakshya Residency",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (currentUser?.isAdmin ?? true)
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF38BDF8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (currentUser?.isAdmin ?? true) ? "ADMIN" : "STAFF",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.email ?? "owner@lakshya.com",
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
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DashboardScreen(currentUser: currentUser),
                        ),
                        (route) => false,
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
                    if (activeItem != "Building") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BuildingsManagementScreen(currentUser: currentUser),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.badge_outlined,
                  title: "Staff",
                  isSelected: activeItem == "Staff",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Staff") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StaffScreen(currentUser: currentUser),
                        ),
                      );
                    }
                  },
                ),
                // Payment Collection: Only visible to Super Admin
                if (currentUser?.canManagePayments ?? true) ...[
                  const SizedBox(height: 4),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.payments_outlined,
                    title: "Payment Collection",
                    isSelected: activeItem == "Payment Collection",
                    onTap: () {
                      Navigator.pop(context);
                      if (activeItem != "Payment Collection") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentCollectionScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
                // Expense Tracker: Visible to Admin
                if (currentUser?.canManageExpenses ?? true) ...[
                  const SizedBox(height: 4),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Expense Tracker",
                    isSelected: activeItem == "Expense Tracker",
                    onTap: () {
                      Navigator.pop(context);
                      if (activeItem != "Expense Tracker") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExpenseTrackerScreen(currentUser: currentUser),
                          ),
                        );
                      }
                    },
                  ),
                ],
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.check_circle_outline_rounded,
                  title: "Personal To-Do",
                  isSelected: activeItem == "Personal To-Do",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Personal To-Do") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonalTodoScreen(currentUser: currentUser),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.confirmation_number_outlined,
                  title: "Ticket Management",
                  isSelected: activeItem == "Ticket Management",
                  onTap: () {
                    Navigator.pop(context);
                    if (activeItem != "Ticket Management") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TicketsManagementScreen(currentUser: currentUser),
                        ),
                      );
                    }
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
