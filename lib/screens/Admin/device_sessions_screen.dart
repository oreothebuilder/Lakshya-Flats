import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_role_model.dart';
import '../../models/device_session_model.dart';
import '../../services/session_management_service.dart';
import '../../services/navigation_service.dart';
import '../../widgets/admin_drawer.dart';
import '../../widgets/app_toast.dart';
import '../login_screen.dart';

class DeviceSessionsScreen extends StatefulWidget {
  final AppUser? currentUser;

  const DeviceSessionsScreen({super.key, this.currentUser});

  @override
  State<DeviceSessionsScreen> createState() => _DeviceSessionsScreenState();
}

class _DeviceSessionsScreenState extends State<DeviceSessionsScreen> {
  bool _isProcessing = false;

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? "PM" : "AM";
    final minute = dt.minute.toString().padLeft(2, '0');
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $period";
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return _formatDateTime(dt);
  }

  IconData _getDeviceIcon(String deviceType, String os) {
    final osLower = os.toLowerCase();
    final typeLower = deviceType.toLowerCase();

    if (osLower.contains('ios') || osLower.contains('iphone') || typeLower.contains('mobile')) {
      return Icons.phone_iphone_rounded;
    }
    if (osLower.contains('android')) {
      return Icons.phone_android_rounded;
    }
    if (osLower.contains('ipad') || typeLower.contains('tablet')) {
      return Icons.tablet_mac_rounded;
    }
    if (osLower.contains('mac')) {
      return Icons.laptop_mac_rounded;
    }
    if (osLower.contains('windows')) {
      return Icons.laptop_windows_rounded;
    }
    return Icons.devices_rounded;
  }

  void _confirmLogoutSpecificDevice(DeviceSessionModel session) {
    final uid = widget.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Log Out Device?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          "Are you sure you want to log out ${session.deviceName}? This session will be immediately disconnected.",
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);
              try {
                await SessionManagementService().logoutSpecificSession(uid, session.id);
                if (mounted) {
                  AppToast.showSuccess(context, "Session disconnected: ${session.deviceName}");
                }
              } catch (e) {
                if (mounted) {
                  AppToast.showError(context, "Failed to log out device: $e");
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Log Out",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogoutOtherDevices() {
    final uid = widget.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Log Out Other Devices?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          "This will disconnect all other phones, tablets, and computers currently logged into this administrator account. You will remain logged in on this device.",
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);
              try {
                await SessionManagementService().logoutAllOtherDevices(uid);
                if (mounted) {
                  AppToast.showSuccess(context, "Successfully logged out from all other devices.");
                }
              } catch (e) {
                if (mounted) {
                  AppToast.showError(context, "Failed to log out other devices: $e");
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Log Out Others",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogoutAllDevices() {
    final uid = widget.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 8),
            Text(
              "Log Out Everywhere?",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to log out from ALL devices? This device and all other phones, tablets, and computers will be disconnected immediately.",
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);
              try {
                await SessionManagementService().logoutAllDevices(uid);
                final nav = rootNavigatorKey.currentState;
                if (nav != null) {
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen(initialRole: LoginRole.manager)),
                    (_) => false,
                  );
                } else if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen(initialRole: LoginRole.manager)),
                    (_) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isProcessing = false);
                  AppToast.showError(context, "Error logging out from all devices: $e");
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Log Out All",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: AdminDrawer(activeItem: "Logged-in Devices", currentUser: widget.currentUser),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          "Logged-in Devices",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: uid.isEmpty
            ? Center(
                child: Text(
                  "No active user session found.",
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                ),
              )
            : StreamBuilder<List<DeviceSessionModel>>(
                stream: SessionManagementService().getActiveSessionsStream(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sessions = snapshot.data ?? [];
                  final currentSession = sessions.where((s) => s.isCurrent).firstOrNull;
                  final otherSessions = sessions.where((s) => !s.isCurrent).toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF003896),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.security_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Device & Session Security",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Review where your account is currently signed in. If you see an unfamiliar device, log out immediately.",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF475569),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Current Device Section
                      Text(
                        "THIS DEVICE",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (currentSession != null)
                        _buildSessionCard(currentSession, isCurrentDevice: true)
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.laptop_chromebook_rounded, color: Color(0xFF0D52CE)),
                              const SizedBox(width: 12),
                              Text(
                                "Current browser session active",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Other Devices Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "OTHER LOGGED-IN DEVICES (${otherSessions.length})",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                              letterSpacing: 0.8,
                            ),
                          ),
                          if (otherSessions.isNotEmpty)
                            TextButton.icon(
                              onPressed: _isProcessing ? null : _confirmLogoutOtherDevices,
                              icon: const Icon(Icons.power_settings_new_rounded, size: 16, color: Color(0xFF0F172A)),
                              label: Text(
                                "Log Out Others",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (otherSessions.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  "No other devices logged in",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Your account is only active on this device.",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...otherSessions.map((s) => _buildSessionCard(s, isCurrentDevice: false)),

                      const SizedBox(height: 28),

                      // Global Log Out Action Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  "Log Out of All Devices",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Lost a device or want to secure your account? Log out from all phones, tablets, and computers at once.",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFFB91C1C),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _confirmLogoutAllDevices,
                                icon: _isProcessing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.power_settings_new_rounded, size: 18),
                                label: Text(
                                  "Log Out From All Devices",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSessionCard(DeviceSessionModel session, {required bool isCurrentDevice}) {
    final icon = _getDeviceIcon(session.deviceType, session.os);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentDevice ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: isCurrentDevice ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCurrentDevice ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isCurrentDevice ? const Color(0xFF16A34A) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.deviceName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isCurrentDevice)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "ACTIVE NOW",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF15803D),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${session.browser} • ${session.os}",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            session.location.isNotEmpty ? session.location : "Location unavailable",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (session.ip.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.wifi_rounded, size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            "IP: ${session.ip}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCurrentDevice
                    ? "Logged in on ${_formatDateTime(session.createdAt)}"
                    : "Last active: ${_formatRelativeTime(session.lastActive)}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!isCurrentDevice)
                OutlinedButton(
                  onPressed: _isProcessing ? null : () => _confirmLogoutSpecificDevice(session),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    foregroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    "Log Out",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
