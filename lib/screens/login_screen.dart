import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'user_home_screen.dart';
import 'manager_home_screen.dart';

enum LoginRole { user, manager }

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _emailController.text = _selectedRole == LoginRole.user
        ? "user@lakshya.com"
        : "manager@lakshya.com";
    _passwordController.text = "password123";
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchRole(LoginRole role) {
    setState(() {
      _selectedRole = role;
      _emailController.text = role == LoginRole.user
          ? "user@lakshya.com"
          : "manager@lakshya.com";
    });
  }

  void _handleSignIn() {
    final Widget destination = _selectedRole == LoginRole.user
        ? const UserHomeScreen()
        : const ManagerHomeScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Password reset link sent to your email.",
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleContactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Connecting to support team...",
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: const Color(0xFF0056D2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0056D2);
    const labelGrey = Color(0xFF475569);
    const inputBorderGrey = Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 440),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Building Icon Badge
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.domain_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Title: Lakshya's Hostel
                  Text(
                    "Lakshya's Hostel",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle Row: STRUCTURE ERP + Management Portal
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "STRUCTURE ERP",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A65D6),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Text(
                        "Management Portal",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: labelGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // LOGIN AS Role Selector
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "LOGIN AS",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: labelGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Segmented Switcher Container
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // User Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchRole(LoginRole.user),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _selectedRole == LoginRole.user
                                    ? primaryBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 18,
                                    color: _selectedRole == LoginRole.user
                                        ? Colors.white
                                        : labelGrey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "User",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedRole == LoginRole.user
                                          ? Colors.white
                                          : labelGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Manager Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchRole(LoginRole.manager),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _selectedRole == LoginRole.manager
                                    ? primaryBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 18,
                                    color: _selectedRole == LoginRole.manager
                                        ? Colors.white
                                        : labelGrey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Manager",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedRole == LoginRole.manager
                                          ? Colors.white
                                          : labelGrey,
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

                  // EMAIL ADDRESS Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "EMAIL ADDRESS",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: labelGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      hintText: _selectedRole == LoginRole.user
                          ? "Enter your predefined user email"
                          : "Enter your predefined manager email",
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: inputBorderGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: primaryBlue, width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // PASSWORD Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "PASSWORD",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: labelGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      hintText: "Enter your password",
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: inputBorderGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: primaryBlue, width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Remember me & Forgot password Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(
                                    color: Color(0xFFCBD5E1), width: 1.5),
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "Remember me",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF334155),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleForgotPassword,
                        child: Text(
                          "Forgot password?",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign In Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedRole == LoginRole.user
                                ? "Sign In as User"
                                : "Sign In as Manager",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // NEED HELP? Section Divider
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFE2E8F0),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          "NEED HELP?",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFE2E8F0),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Contact Support Footer (RichText with WidgetSpan & TapGestureRecognizer for overflow-safe text wrapping)
                  Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Icon(
                              Icons.help_outline_rounded,
                              size: 18,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        TextSpan(
                          text: "Having trouble logging in? ",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        TextSpan(
                          text: "Contact Support",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: primaryBlue,
                            decoration: TextDecoration.underline,
                            decorationColor: primaryBlue,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _handleContactSupport,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
