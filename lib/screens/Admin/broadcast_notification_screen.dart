import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/admin_drawer.dart';

class BroadcastHistoryItem {
  final String id;
  final String title;
  final String message;
  final String audience;
  final int recipientCount;
  final String timestamp;

  BroadcastHistoryItem({
    required this.id,
    required this.title,
    required this.message,
    required this.audience,
    required this.recipientCount,
    required this.timestamp,
  });
}

class BroadcastNotificationScreen extends StatefulWidget {
  const BroadcastNotificationScreen({super.key});

  @override
  State<BroadcastNotificationScreen> createState() => _BroadcastNotificationScreenState();
}

class _BroadcastNotificationScreenState extends State<BroadcastNotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form State
  String _selectedAudience = "All students of all buildings";
  String _selectedTemplate = "Urgent Defaulter Warning";
  late TextEditingController _messageController;
  String _selectedBuilding = "Lakshya Residency";

  final Map<String, String> _templates = {
    "Urgent Defaulter Warning":
        "URGENT NOTICE: Your fee payment is past the due deadline. Please settle your outstanding dues immediately to avoid hostel service interruption.",
    "Fee Payment Reminder":
        "Reminder: Upcoming hostel and mess dues for this month are scheduled by 5th. Kindly clear your dues via app.",
    "Mess Menu Update":
        "Mess Menu Updated: Check out the new revised weekly mess menu in your student portal.",
    "Maintenance Notice":
        "Notice: Scheduled water tank maintenance tomorrow from 10 AM to 1 PM. Please store water in advance.",
    "General Announcement":
        "Important Update: All residents are invited to the community meeting this Sunday at 6 PM in the main hall.",
    "Custom Message": "",
  };

  final List<BroadcastHistoryItem> _historyItems = [
    BroadcastHistoryItem(
      id: "BC-101",
      title: "Urgent Defaulter Warning",
      message:
          "URGENT NOTICE: Your fee payment is past the due deadline. Please settle your outstanding dues immediately to avoid hostel service interruption.",
      audience: "All Defaulters",
      recipientCount: 24,
      timestamp: "2 hours ago",
    ),
    BroadcastHistoryItem(
      id: "BC-102",
      title: "Mess Menu Update",
      message:
          "Mess Menu Updated: Check out the new revised weekly mess menu in your student portal.",
      audience: "All students of all buildings",
      recipientCount: 120,
      timestamp: "Yesterday, 4:30 PM",
    ),
    BroadcastHistoryItem(
      id: "BC-103",
      title: "Maintenance Notice",
      message:
          "Notice: Scheduled water tank maintenance tomorrow from 10 AM to 1 PM. Please store water in advance.",
      audience: "Lakshya Residency",
      recipientCount: 45,
      timestamp: "3 days ago",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _messageController = TextEditingController(text: _templates["Urgent Defaulter Warning"]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onTemplateChanged(String? newTemplate) {
    if (newTemplate != null) {
      setState(() {
        _selectedTemplate = newTemplate;
        _messageController.text = _templates[newTemplate] ?? "";
      });
    }
  }

  int get _calculatedRecipientCount {
    switch (_selectedAudience) {
      case "All students of all buildings":
        return 120;
      case "Select Buildings":
        return 45;
      case "All Defaulters":
        return 24;
      case "Individual Students":
        return 5;
      default:
        return 120;
    }
  }

  String get _targetSummaryText {
    switch (_selectedAudience) {
      case "All students of all buildings":
        return "All students of all buildings (120 residents)";
      case "Select Buildings":
        return "$_selectedBuilding (45 residents)";
      case "All Defaulters":
        return "All Defaulters across all buildings (24 residents)";
      case "Individual Students":
        return "5 individual selected students";
      default:
        return "All students of all buildings (120 residents)";
    }
  }

  void _sendBroadcast() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter a message body before sending.",
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.send_rounded, color: Color(0xFF0D52CE)),
            const SizedBox(width: 10),
            Text(
              "Confirm Broadcast",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          "Send broadcast notification to $_targetSummaryText?\nThis will deliver instant app push notifications and SMS.",
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              final newItem = BroadcastHistoryItem(
                id: "BC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
                title: _selectedTemplate,
                message: _messageController.text.trim(),
                audience: _selectedAudience == "Select Buildings" ? _selectedBuilding : _selectedAudience,
                recipientCount: _calculatedRecipientCount,
                timestamp: "Just now",
              );

              setState(() {
                _historyItems.insert(0, newItem);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Broadcast Notification sent to $_calculatedRecipientCount residents successfully!",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFF0D52CE),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D52CE),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Send Now",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceChip({
    required String label,
    IconData? icon,
    bool isWarning = false,
  }) {
    final isSelected = _selectedAudience == label;

    if (isSelected) {
      return Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(icon ?? Icons.check, size: 16, color: Colors.white),
          label: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D52CE),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _selectedAudience = label;
          });
        },
        icon: icon != null
            ? Icon(
                icon,
                size: 16,
                color: isWarning ? const Color(0xFFDC2626) : const Color(0xFF475569),
              )
            : const SizedBox.shrink(),
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isWarning ? const Color(0xFFDC2626) : const Color(0xFF334155),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isWarning ? const Color(0xFFFEF2F2) : Colors.white,
          side: BorderSide(
            color: isWarning ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(activeItem: "Broadcast Notification"),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text(
          "Broadcast Notification",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0D52CE),
          indicatorWeight: 3,
          labelColor: const Color(0xFF0D52CE),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 16),
                  SizedBox(width: 8),
                  Text("Send Broadcast"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text("Notification History (${_historyItems.length})"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Send Broadcast Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Choose Target Audience Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7FD),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_alt_rounded, color: Color(0xFF0D52CE), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "1. Choose Target Audience",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        children: [
                          _buildAudienceChip(
                            label: "All students of all buildings",
                            icon: Icons.check,
                          ),
                          _buildAudienceChip(
                            label: "Select Buildings",
                          ),
                          _buildAudienceChip(
                            label: "All Defaulters",
                            icon: Icons.warning_amber_rounded,
                            isWarning: true,
                          ),
                          _buildAudienceChip(
                            label: "Individual Students",
                          ),
                        ],
                      ),
                      if (_selectedAudience == "Select Buildings") ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedBuilding,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D52CE)),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              items: const [
                                DropdownMenuItem(value: "Lakshya Residency", child: Text("Lakshya Residency (45 residents)")),
                                DropdownMenuItem(value: "Univ Homes", child: Text("Univ Homes (40 residents)")),
                                DropdownMenuItem(value: "Green Villa", child: Text("Green Villa (35 residents)")),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedBuilding = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 2: Notification Content Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7FD),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: Color(0xFF0D52CE), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "2. Notification Content",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Default Message Template",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTemplate,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF475569)),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            items: _templates.keys.map((templateName) {
                              return DropdownMenuItem<String>(
                                value: templateName,
                                child: Text(templateName),
                              );
                            }).toList(),
                            onChanged: _onTemplateChanged,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Message Body (Editable)",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: 5,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            color: const Color(0xFF0F172A),
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(14),
                            border: InputBorder.none,
                            hintText: "Type notification message here...",
                            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Target Summary Info Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, color: Color(0xFF0284C7), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TARGET SUMMARY",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0369A1),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _targetSummaryText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0369A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sticky Send Broadcast Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendBroadcast,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      "Send Broadcast Notification",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D52CE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab 2: Notification History List
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _historyItems.length,
            itemBuilder: (context, index) {
              final item = _historyItems[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Delivered",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt_outlined, size: 15, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              "${item.audience} (${item.recipientCount})",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              item.timestamp,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
