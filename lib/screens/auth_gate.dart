import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_role_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'onboarding_screen.dart';
import 'Admin/dashboard_screen.dart';
import 'User/user_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuthService().authStateChanges,
      builder: (context, authSnapshot) {
        // 1. Loading Firebase Auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF003896),
              ),
            ),
          );
        }

        final user = authSnapshot.data;

        // 2. Unauthenticated: route to Landing / Onboarding
        if (user == null) {
          return const OnboardingScreen();
        }

        // 3. Authenticated: Fetch verified role and profile from Firestore
        return FutureBuilder<AppUser?>(
          future: FirestoreService().getAppUser(user.uid, emailHint: user.email),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF003896).withValues(alpha: 0.1),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            color: Color(0xFF003896),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Lakshya Residency",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Verifying access privileges...",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final appUser = userSnapshot.data;

            // If account has been deactivated
            if (appUser != null &&
                (appUser.status.toLowerCase() == 'inactive' ||
                    appUser.status.toLowerCase() == 'suspended')) {
              FirebaseAuthService().signOut();
              return const OnboardingScreen();
            }

            // Route based on role
            if (appUser != null) {
              if (appUser.isAdmin || appUser.isManagement) {
                return DashboardScreen(currentUser: appUser);
              } else {
                return UserHomeScreen(currentUser: appUser);
              }
            }

            // Fallback: If no role doc yet (e.g. initial login before profile save)
            // If primary admin email
            if (user.email != null &&
                FirestoreService().isPrimaryAdminEmail(user.email!)) {
              final adminUser = AppUser(
                uid: user.uid,
                email: user.email!,
                fullName: "Sudhanshu (Super Admin)",
                role: AppRole.admin,
              );
              return DashboardScreen(currentUser: adminUser);
            }

            // Otherwise, route to resident home or fallback
            return const OnboardingScreen();
          },
        );
      },
    );
  }
}
