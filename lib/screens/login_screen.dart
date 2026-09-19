import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_role_model.dart';
import '../theme/app_colors.dart';
import 'User/user_home_screen.dart';
import 'Admin/dashboard_screen.dart';
import 'onboarding_screen.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/app_toast.dart';

enum LoginRole { user, manager }
enum ManagementSubRole { staff, admin }

class LoginScreen extends StatefulWidget {
  final LoginRole initialRole;

  const LoginScreen({
    super.key,
    this.initialRole = LoginRole.user,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late LoginRole _selectedRole;
  ManagementSubRole _managementSubRole = ManagementSubRole.admin;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _updateDefaultEmail();
  }

  void _updateDefaultEmail() {
    if (_selectedRole == LoginRole.user) {
      _emailController.clear();
    } else {
      if (_managementSubRole == ManagementSubRole.admin) {
        _emailController.text = "sudhansu1906@gmail.com";
      } else {
        _emailController.clear();
      }
    }
    _passwordController.clear();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchManagementSubRole(ManagementSubRole subRole) {
    setState(() {
      _managementSubRole = subRole;
      _updateDefaultEmail();
    });
  }

  void _showNotification(String msg, {bool isSuccess = true}) {
    AppToast.show(context, msg, isSuccess: isSuccess);
  }

  Future<void> _handleSignIn() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      _showNotification(
        _selectedRole == LoginRole.user
            ? "Please enter your Email ID or Student Registration Number."
            : "Please enter your management email address.",
        isSuccess: false,
      );
      return;
    }

    if (password.isEmpty) {
      _showNotification("Please enter your password.", isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AppUser appUser = await FirebaseAuthService().signInWithIdentifier(
        identifier: identifier,
        password: password,
      );

      if (!mounted) return;

      // Role check against chosen tab:
      if (_selectedRole == LoginRole.manager && appUser.isStudent) {
        _showNotification(
          "Access Notice: Resident account detected. Redirecting to Student Resident Portal...",
          isSuccess: false,
        );
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserHomeScreen(currentUser: appUser)),
        );
        return;
      }

      if (_selectedRole == LoginRole.user && !appUser.isStudent) {
        _showNotification(
          "Access Notice: Staff/Admin account detected. Redirecting to Management Portal...",
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(currentUser: appUser)),
        );
        return;
      }

      final Widget destination = appUser.isStudent
          ? UserHomeScreen(currentUser: appUser)
          : DashboardScreen(currentUser: appUser);

      _showNotification(
        appUser.isStudent
            ? "Welcome to Lakshya Residency, ${appUser.fullName}!"
            : (appUser.isAdmin
                ? "Authenticated as Super Administrator (${appUser.fullName})"
                : "Authenticated as Management Staff (${appUser.fullName})"),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } catch (e) {
      if (mounted) {
        final errorMsg = FirebaseAuthService.getReadableErrorMessage(e);
        _showNotification(errorMsg, isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showNotification("Please enter a valid email address first.", isSuccess: false);
      return;
    }

    try {
      await FirebaseAuthService().sendPasswordResetEmail(email);
      if (mounted) {
        _showNotification("Password reset email sent to $email. Check your inbox!");
      }
    } catch (e) {
      if (mounted) {
        _showNotification(FirebaseAuthService.getReadableErrorMessage(e), isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const labelGrey = Color(0xFF334155);
    const textGrey = Color(0xFF64748B);
    const inputBorderGrey = Color(0xFFE2E8F0);
    const inputBgColor = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Lakshya Residency",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: _selectedRole == LoginRole.manager
                        ? _buildManagementForm(labelGrey, textGrey, inputBorderGrey, inputBgColor)
                        : _buildStudentForm(labelGrey, textGrey, inputBorderGrey, inputBgColor),
                  ),
                ),
              ),
            ),

            // Bottom Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "© 2026 Lakshya Residency. All rights reserved.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementForm(
      Color labelGrey, Color textGrey, Color inputBorderGrey, Color inputBgColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title
        Text(
          "Management Portal",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 24),

        // Access Role Label
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Access Role",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: labelGrey,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Access Role Switcher (Staff vs Admin)
        Container(
          height: 52,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              // Staff Tab
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchManagementSubRole(ManagementSubRole.staff),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _managementSubRole == ManagementSubRole.staff
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _managementSubRole == ManagementSubRole.staff
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 18,
                          color: _managementSubRole == ManagementSubRole.staff
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Staff",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _managementSubRole == ManagementSubRole.staff
                                ? Colors.white
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Admin Tab
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchManagementSubRole(ManagementSubRole.admin),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _managementSubRole == ManagementSubRole.admin
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _managementSubRole == ManagementSubRole.admin
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 18,
                          color: _managementSubRole == ManagementSubRole.admin
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Admin",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _managementSubRole == ManagementSubRole.admin
                                ? Colors.white
                                : const Color(0xFF475569),
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

        // Authorized Email ID Field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Authorized Email ID",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: labelGrey,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBgColor,
            hintText: "admin@lakshya.com",
            prefixIcon: const Icon(
              Icons.mail_outline_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Password Field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Password",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: labelGrey,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBgColor,
            hintText: "Enter password",
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _handleForgotPassword,
            child: Text(
              "Forgot Password?",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Log In to Management Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          "Log In to Management",
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentForm(
      Color labelGrey, Color textGrey, Color inputBorderGrey, Color inputBgColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title
        Text(
          "Student Portal Login",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 24),

        // Email ID / Reg No Field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Student Email or Registration Number",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: labelGrey,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBgColor,
            hintText: "e.g. REG101 or student@university.edu",
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Icon(
              Icons.badge_outlined,
              color: Color(0xFF64748B),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Password Field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Password",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: labelGrey,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBgColor,
            hintText: "e.g. Rahul@REG101",
            hintStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _handleForgotPassword,
            child: Text(
              "Forgot Password?",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Sign In Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sign In",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
