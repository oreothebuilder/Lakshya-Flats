import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A universal toast notification utility that inserts an [OverlayEntry] into the
/// root [Navigator]'s [Overlay].
///
/// Because it uses [rootOverlay: true], it is guaranteed to render in front of
/// all active [ModalBottomSheetRoute]s, [DialogRoute]s, popups, and screens.
class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Shows a floating toast message at the top of the screen in front of all modals and dialogs.
  static void show(
    BuildContext context,
    String message, {
    bool isSuccess = true,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    // 1. Dismiss any active toast immediately
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
    }

    if (!context.mounted) return;

    // 2. Find the root overlay above all dialogs, bottom sheets, and routes
    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);

    if (overlay == null) {
      // Fallback to ScaffoldMessenger if overlay is unavailable
      try {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isSuccess ? const Color(0xFF003896) : const Color(0xFFDC2626),
            duration: duration,
          ),
        );
      } catch (_) {}
      return;
    }

    final widgetKey = GlobalKey<_ToastWidgetState>();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        key: widgetKey,
        message: message,
        isSuccess: isSuccess,
        onDismiss: () {
          _cleanUpEntry(entry);
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    // 3. Set timer to automatically trigger dismissal animation
    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        widgetKey.currentState?.dismiss();
      }
    });
  }

  static void _cleanUpEntry(OverlayEntry entry) {
    if (_currentEntry == entry) {
      _dismissTimer?.cancel();
      _dismissTimer = null;
      try {
        entry.remove();
      } catch (_) {}
      _currentEntry = null;
    }
  }

  /// Convenience helper for success messages
  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      isSuccess: true,
      duration: duration ?? const Duration(milliseconds: 2500),
    );
  }

  /// Convenience helper for info messages
  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      isSuccess: true,
      duration: duration ?? const Duration(milliseconds: 2500),
    );
  }

  /// Convenience helper for error / warning messages
  static void showError(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      isSuccess: false,
      duration: duration ?? const Duration(milliseconds: 2800),
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback onDismiss;

  const _ToastWidget({
    super.key,
    required this.message,
    required this.isSuccess,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();
  }

  /// Triggered by timer or user tap
  Future<void> dismiss() async {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    try {
      await _controller.reverse();
    } catch (_) {}
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 14, left: 16, right: 16),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: dismiss,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isSuccess
                          ? const Color(0xFF0F172A) // Sleek dark slate
                          : const Color(0xFF7F1D1D), // Deep crimson
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.isSuccess
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.4) // Cyan / blue glow
                            : const Color(0xFFF87171).withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.isSuccess
                                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.isSuccess
                                ? Icons.check_circle_rounded
                                : Icons.error_outline_rounded,
                            color: widget.isSuccess
                                ? const Color(0xFF34D399)
                                : Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
