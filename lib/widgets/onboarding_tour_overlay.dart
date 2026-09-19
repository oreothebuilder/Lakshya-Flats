import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Defines a single step in the interactive onboarding tour
class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;
  final String category;
  final BorderRadius? borderRadius;
  final EdgeInsets padding;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
    this.category = "Navigation",
    this.borderRadius,
    this.padding = const EdgeInsets.all(6),
  });
}

/// Initial Welcome Modal shown on first-time login
/// Gives the user two clear options: "Continue Tour" and "Dismiss Tour"
class OnboardingWelcomeModal extends StatelessWidget {
  final String userName;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  const OnboardingWelcomeModal({
    super.key,
    required this.userName,
    required this.onContinue,
    required this.onDismiss,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String userName,
    required VoidCallback onContinue,
    required VoidCallback onDismiss,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => OnboardingWelcomeModal(
        userName: userName,
        onContinue: () {
          Navigator.pop(dialogCtx, true);
          onContinue();
        },
        onDismiss: () {
          Navigator.pop(dialogCtx, false);
          onDismiss();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero Icon / Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.explore_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Welcome Title
              Text(
                "Welcome to Lakshya Residency!",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 20 : 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Personalized Intro Subtitle
              Text(
                "Hello ${userName.isNotEmpty ? userName : 'Resident'}! Take a quick 1-minute guided tour to explore how to check your meals, view room dues, raise requests, and navigate your student portal.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Continue Tour (Primary)
                  ElevatedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(
                      "Continue Tour",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Dismiss Tour (Secondary)
                  OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Dismiss Tour",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The interactive spotlight overlay that dims the background,
/// highlights the active target element, and presents the step tooltip.
class OnboardingTourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final int currentStepIndex;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onDismiss;

  const OnboardingTourOverlay({
    super.key,
    required this.steps,
    required this.currentStepIndex,
    required this.onNext,
    required this.onBack,
    required this.onDismiss,
  });

  @override
  State<OnboardingTourOverlay> createState() => _OnboardingTourOverlayState();
}

class _OnboardingTourOverlayState extends State<OnboardingTourOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Rect? _getTargetRect(GlobalKey key, EdgeInsets padding) {
    final currentContext = key.currentContext;
    if (currentContext == null) return null;

    final renderBox = currentContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    final translation = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      translation.dx - padding.left,
      translation.dy - padding.top,
      renderBox.size.width + padding.horizontal,
      renderBox.size.height + padding.vertical,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentStepIndex < 0 || widget.currentStepIndex >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final currentStep = widget.steps[widget.currentStepIndex];
    final targetRect = _getTargetRect(currentStep.targetKey, currentStep.padding);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Stack(
      children: [
        // 1. Dark Spotlight Dimming Overlay
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return CustomPaint(
                painter: _SpotlightPainter(
                  targetRect: targetRect,
                  borderRadius: currentStep.borderRadius ?? BorderRadius.circular(16),
                  pulseScale: _pulseAnimation.value,
                ),
              );
            },
          ),
        ),

        // 2. Interactive Tooltip / Popover Card
        _buildPopoverCard(context, currentStep, targetRect, screenSize, isMobile),
      ],
    );
  }

  Widget _buildPopoverCard(
    BuildContext context,
    TourStep step,
    Rect? targetRect,
    Size screenSize,
    bool isMobile,
  ) {
    const double popoverWidth = 360.0;
    final double actualWidth = math.min(popoverWidth, screenSize.width - 32);

    // Compute vertical position: place below target if space permits, else above
    double topPosition = 120.0;
    double leftPosition = 16.0;

    if (targetRect != null) {
      final spaceBelow = screenSize.height - targetRect.bottom;
      final spaceAbove = targetRect.top;

      if (spaceBelow >= 240 || spaceBelow > spaceAbove) {
        // Place below target
        topPosition = targetRect.bottom + 12.0;
      } else {
        // Place above target
        topPosition = math.max(16.0, targetRect.top - 240.0);
      }

      // Horizontal alignment: attempt to align with target's left, clamp to screen bounds
      leftPosition = targetRect.left;
      if (leftPosition + actualWidth > screenSize.width - 16) {
        leftPosition = screenSize.width - actualWidth - 16;
      }
      if (leftPosition < 16) {
        leftPosition = 16;
      }
    } else {
      // Fallback: center in screen
      topPosition = screenSize.height * 0.35;
      leftPosition = (screenSize.width - actualWidth) / 2;
    }

    final isLastStep = widget.currentStepIndex == widget.steps.length - 1;
    final stepProgress = "${widget.currentStepIndex + 1} of ${widget.steps.length}";

    return Positioned(
      top: topPosition,
      left: leftPosition,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: actualWidth,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row: Category Badge & Step Counter & Dismiss 'X'
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(step.icon, size: 13, color: const Color(0xFF2563EB)),
                        const SizedBox(width: 5),
                        Text(
                          step.category.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2563EB),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stepProgress,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        tooltip: "Dismiss Tour",
                        onPressed: widget.onDismiss,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Step Title
              Text(
                step.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),

              // Step Description
              Text(
                step.description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Actions: Dismiss Tour | Back | Next / Finish
              Row(
                children: [
                  // Dismiss Tour Button
                  TextButton(
                    onPressed: widget.onDismiss,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Dismiss Tour",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Back Button (if not first step)
                  if (widget.currentStepIndex > 0) ...[
                    OutlinedButton(
                      onPressed: widget.onBack,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Back",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Next / Finish Button
                  ElevatedButton(
                    onPressed: widget.onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isLastStep ? "Finish Tour" : "Next",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that creates the cutout around the target element
/// and applies a glowing focus border.
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final BorderRadius borderRadius;
  final double pulseScale;

  _SpotlightPainter({
    required this.targetRect,
    required this.borderRadius,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (targetRect == null) {
      // If no target, simply dim the entire screen
      final dimPaint = Paint()..color = const Color(0xB30F172A);
      canvas.drawRect(fullRect, dimPaint);
      return;
    }

    final targetRRect = borderRadius.toRRect(targetRect!);

    // 1. Dim the screen everywhere EXCEPT the target cut-out
    final backgroundPath = Path()
      ..addRect(fullRect)
      ..addRRect(targetRRect)
      ..fillType = PathFillType.evenOdd;

    final dimPaint = Paint()
      ..color = const Color(0xB30F172A)
      ..style = PaintingStyle.fill;

    canvas.drawPath(backgroundPath, dimPaint);

    // 2. Draw soft glowing highlight border around the target cut-out
    final glowPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.45 * pulseScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * pulseScale;

    canvas.drawRRect(targetRRect, glowPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawRRect(targetRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.pulseScale != pulseScale;
  }
}
