import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/onboarding_item.dart';
import '../theme/app_colors.dart';
import '../widgets/onboarding_page_content.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skipToLast() {
    _pageController.animateToPage(
      onboardingItems.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _onUserLoginPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(initialRole: LoginRole.user),
      ),
    );
  }

  void _onManagementPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(initialRole: LoginRole.manager),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentIndex == onboardingItems.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Lakshya Residency",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (!isLastPage)
                    GestureDetector(
                      onTap: _skipToLast,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Text(
                          "Skip",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 32),
                ],
              ),
            ),

            // Onboarding Slides (PageView)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingItems.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPageContent(item: onboardingItems[index]);
                },
              ),
            ),

            // Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingItems.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentIndex == index ? 24 : 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppColors.dotActive
                        : AppColors.dotInactive,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bottom Action Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: isLastPage
                  ? _buildFinalActionButtons()
                  : _buildNextButton(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Next",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
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
    );
  }

  Widget _buildFinalActionButtons() {
    return Column(
      children: [
        // Primary: User Login Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _onUserLoginPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "User Login",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
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
        const SizedBox(height: 12),

        // Secondary: Management Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _onManagementPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              "Management",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
