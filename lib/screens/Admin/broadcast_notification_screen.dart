import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/admin_drawer.dart';
import 'dashboard_screen.dart';
import '../../services/firestore_service.dart';
import '../../models/student_profile_model.dart';
import '../../models/bill_model.dart';
import '../../models/broadcast_notice_model.dart';

class BroadcastAudience {
  static const String allStudents = "All students";
  static const String allDefaulters = "All defaulters";
  static const String building = "Building";
  static const String selectStudent = "Select student";
}

class BroadcastMessageMode {
  static const String custom = "Custom";
  static const String templates = "Templates";
}

class MessageTemplate {
  final String id;
  String heading;
  String description;
  final bool isPreset;

  MessageTemplate({
    required this.id,
    required this.heading,
    required this.description,
    this.isPreset = false,
  });
}

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
  final String? initialAudience;
  final String? initialStudentId;
  final String? initialTemplateId;
  final String? initialMessageMode;
  final String? initialCustomHeading;
  final String? initialCustomDescription;

  const BroadcastNotificationScreen({
    super.key,
    this.initialAudience,
    this.initialStudentId,
    this.initialTemplateId,
    this.initialMessageMode,
    this.initialCustomHeading,
    this.initialCustomDescription,
  });

  @override
  State<BroadcastNotificationScreen> createState() => _BroadcastNotificationScreenState();
}

class _BroadcastNotificationScreenState extends State<BroadcastNotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Primary Admin Color
  static const Color adminPrimary = Color(0xFF003896);

  // Section 1: Audience Selection State (Hot-reload resilient)
  dynamic _selectedAudience = BroadcastAudience.allStudents;
  String get _currentAudience {
    final str = _selectedAudience.toString().toLowerCase();
    if (str.contains("defaulter")) return BroadcastAudience.allDefaulters;
    if (str.contains("building")) return BroadcastAudience.building;
    if (str.contains("student") && !str.contains("all")) return BroadcastAudience.selectStudent;
    return BroadcastAudience.allStudents;
  }

  final Set<String> _selectedBuildings = {"Lakshya"};
  final Set<String> _selectedStudentIds = {};
  String _studentSearchQuery = "";
  final TextEditingController _studentSearchController = TextEditingController();

  // Section 2: Message Mode State (Hot-reload resilient)
  dynamic _messageMode = BroadcastMessageMode.custom;
  String get _currentMode {
    final str = _messageMode.toString().toLowerCase();
    if (str.contains("template")) return BroadcastMessageMode.templates;
    return BroadcastMessageMode.custom;
  }

  // Custom Message Controllers
  final TextEditingController _customHeadingController = TextEditingController();
  final TextEditingController _customDescriptionController = TextEditingController();

  // Template Selection & Editing Controllers
  String _selectedTemplateId = "t1";
  final TextEditingController _templateHeadingController = TextEditingController();
  final TextEditingController _templateDescriptionController = TextEditingController();

  // Available Buildings
  final List<String> _buildings = [
    "Lakshya",
    "Shivalya",
    "Ishaan",
    "Univ homes",
    "Tirupati",
    "Rameshwaram",
    "Livano",
    "Somnath",
  ];

  // Prewritten and Custom Templates
  final List<MessageTemplate> _templates = [
    MessageTemplate(
      id: "t1",
      heading: "Urgent Defaulter Warning",
      description:
          "URGENT NOTICE: Your fee payment is past the due deadline. Please settle your outstanding dues immediately to avoid hostel service interruption.",
      isPreset: true,
    ),
    MessageTemplate(
      id: "t2",
      heading: "Fee Payment Reminder",
      description:
          "Reminder: Upcoming hostel and mess dues for this month are scheduled by 5th. Kindly clear your dues via the student mobile app.",
      isPreset: true,
    ),
    MessageTemplate(
      id: "t3",
      heading: "Mess Menu Update",
      description:
          "Mess Menu Updated: Check out the new revised weekly mess menu in your student portal under the Food section.",
      isPreset: true,
    ),
    MessageTemplate(
      id: "t4",
      heading: "Maintenance Notice",
      description:
          "Notice: Scheduled water tank maintenance tomorrow from 10 AM to 1 PM. Please store sufficient water in advance.",
      isPreset: true,
    ),
    MessageTemplate(
      id: "t5",
      heading: "Gate Closing & Curfew",
      description:
          "Reminder: The main hostel gates will strictly close at 10:00 PM tonight. Kindly ensure you return before curfew hours.",
      isPreset: true,
    ),
    MessageTemplate(
      id: "t6",
      heading: "Community Announcement",
      description:
          "Important Update: All residents are invited to the hostel community meeting this Sunday at 6:00 PM in the main common hall.",
      isPreset: true,
    ),
    MessageTemplate(
      id: "t7",
      heading: "Wi-Fi & Network Maintenance",
      description:
          "Notice: Scheduled network router and Wi-Fi maintenance tonight from 12 AM to 2 AM. Services will resume immediately after.",
      isPreset: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Apply any initial parameters passed (e.g. when triggered from defaulter bill)
    if (widget.initialAudience != null) {
      _selectedAudience = widget.initialAudience!;
    }
    if (widget.initialStudentId != null && widget.initialStudentId!.isNotEmpty) {
      _selectedStudentIds.add(widget.initialStudentId!);
    }
    if (widget.initialMessageMode != null) {
      _messageMode = widget.initialMessageMode!;
    }
    if (widget.initialTemplateId != null) {
      final t = _templates.firstWhere(
        (e) => e.id == widget.initialTemplateId,
        orElse: () => _templates.first,
      );
      _selectedTemplateId = t.id;
      _templateHeadingController.text = t.heading;
      _templateDescriptionController.text = t.description;
    } else if (_templates.isNotEmpty) {
      _templateHeadingController.text = _templates.first.heading;
      _templateDescriptionController.text = _templates.first.description;
    }

    if (widget.initialCustomHeading != null) {
      _customHeadingController.text = widget.initialCustomHeading!;
      _templateHeadingController.text = widget.initialCustomHeading!;
    }
    if (widget.initialCustomDescription != null) {
      _customDescriptionController.text = widget.initialCustomDescription!;
      _templateDescriptionController.text = widget.initialCustomDescription!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentSearchController.dispose();
    _customHeadingController.dispose();
    _customDescriptionController.dispose();
    _templateHeadingController.dispose();
    _templateDescriptionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // TEMPLATE MANAGEMENT METHODS
  // ---------------------------------------------------------------------------

  void _onSelectTemplate(MessageTemplate template) {
    setState(() {
      _selectedTemplateId = template.id;
      _templateHeadingController.text = template.heading;
      _templateDescriptionController.text = template.description;
    });
  }

  void _showAddTemplateDialog() {
    final headingCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Add New Template",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Heading",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: headingCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "e.g. Laundry Timing Change",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Description",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Enter the prewritten template body...",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final h = headingCtrl.text.trim();
              final d = descCtrl.text.trim();
              if (h.isEmpty || d.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Please fill in both heading and description.",
                      style: GoogleFonts.plusJakartaSans(),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              Navigator.pop(dialogCtx);
              final newTemplate = MessageTemplate(
                id: "custom_${DateTime.now().millisecondsSinceEpoch}",
                heading: h,
                description: d,
                isPreset: false,
              );

              setState(() {
                _templates.insert(0, newTemplate);
                _onSelectTemplate(newTemplate);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Template \"$h\" saved successfully!",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: adminPrimary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: adminPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Save Template", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showEditTemplateDialog(MessageTemplate template) {
    final headingCtrl = TextEditingController(text: template.heading);
    final descCtrl = TextEditingController(text: template.description);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Edit Template",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Heading",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: headingCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Description",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final h = headingCtrl.text.trim();
              final d = descCtrl.text.trim();
              if (h.isEmpty || d.isEmpty) return;

              Navigator.pop(dialogCtx);
              setState(() {
                template.heading = h;
                template.description = d;
                if (_selectedTemplateId == template.id) {
                  _templateHeadingController.text = h;
                  _templateDescriptionController.text = d;
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Template updated successfully!",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: adminPrimary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: adminPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Save Changes", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(MessageTemplate template) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Template?",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          "Are you sure you want to delete \"${template.heading}\"?",
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() {
                _templates.removeWhere((t) => t.id == template.id);
                if (_selectedTemplateId == template.id && _templates.isNotEmpty) {
                  _onSelectTemplate(_templates.first);
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Template removed.",
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Delete", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILDING MULTI-SELECT BOTTOM SHEET
  // ---------------------------------------------------------------------------

  void _openBuildingSelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select Buildings",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  _selectedBuildings.addAll(_buildings);
                                });
                                setState(() {});
                              },
                              child: Text(
                                "Select All",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: adminPrimary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  _selectedBuildings.clear();
                                });
                                setState(() {});
                              },
                              child: Text(
                                "Clear",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select one or multiple buildings to send this message simultaneously.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _buildings.length,
                        itemBuilder: (context, index) {
                          final building = _buildings[index];
                          final isSelected = _selectedBuildings.contains(building);
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(
                              building,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.domain_rounded,
                                size: 18,
                                color: isSelected ? adminPrimary : const Color(0xFF64748B),
                              ),
                            ),
                            activeColor: adminPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onChanged: (checked) {
                              setSheetState(() {
                                if (checked == true) {
                                  _selectedBuildings.add(building);
                                } else {
                                  _selectedBuildings.remove(building);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: adminPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          "Done (${_selectedBuildings.length} Selected)",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SEND BROADCAST LOGIC
  // ---------------------------------------------------------------------------

  void _attemptSendBroadcast({
    required List<StudentProfile> allStudents,
    required List<BillModel> allBills,
  }) {
    // 1. Determine active heading and description
    final isCustom = _currentMode == BroadcastMessageMode.custom;
    final heading = isCustom ? _customHeadingController.text.trim() : _templateHeadingController.text.trim();
    final description = isCustom ? _customDescriptionController.text.trim() : _templateDescriptionController.text.trim();

    if (heading.isEmpty) {
      _showSnackbar("Please enter a notice heading.", isError: true);
      return;
    }
    if (description.isEmpty) {
      _showSnackbar("Please enter a notice description.", isError: true);
      return;
    }

    // 2. Audience validation
    if (_currentAudience == BroadcastAudience.building && _selectedBuildings.isEmpty) {
      _showSnackbar("Please select at least one building.", isError: true);
      return;
    }
    if (_currentAudience == BroadcastAudience.selectStudent && _selectedStudentIds.isEmpty) {
      _showSnackbar("Please select at least one student.", isError: true);
      return;
    }

    // 3. Compute recipient count & summary
    int recipientCount = 0;
    String audienceSummary = "";

    switch (_currentAudience) {
      case BroadcastAudience.allStudents:
        recipientCount = allStudents.length;
        audienceSummary = "All students of all buildings ($recipientCount recipients)";
        break;
      case BroadcastAudience.allDefaulters:
        final defaulterBills = allBills.where((b) => b.isDefaulter).toList();
        recipientCount = defaulterBills.length;
        audienceSummary = "All Defaulters across all buildings ($recipientCount recipients)";
        break;
      case BroadcastAudience.building:
        final matchedStudents = allStudents.where((s) {
          final sBuilding = s.building.toLowerCase();
          return _selectedBuildings.any((b) => sBuilding.contains(b.toLowerCase()));
        }).toList();
        recipientCount = matchedStudents.length;
        audienceSummary = "Buildings: ${_selectedBuildings.join(', ')} ($recipientCount recipients)";
        break;
      case BroadcastAudience.selectStudent:
        recipientCount = _selectedStudentIds.length;
        audienceSummary = "$recipientCount specific student(s) selected";
        break;
    }

    // 4. Show Confirmation Modal
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: adminPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Confirm Broadcast",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Send this broadcast notification to:",
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_rounded, size: 16, color: adminPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audienceSummary,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Heading:",
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
            ),
            Text(
              heading,
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              "Message:",
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
            ),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF334155)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);

              setState(() {
                if (isCustom) {
                  _customHeadingController.clear();
                  _customDescriptionController.clear();
                }
              });

              // 2. Persist to Firestore
              try {
                FirestoreService().addNotification({
                  'title': heading,
                  'message': description,
                  'targetAudience': audienceSummary,
                  'recipientCount': recipientCount,
                  'senderName': 'Management Admin',
                  'selectedBuildings': _selectedBuildings.toList(),
                  'selectedStudentIds': _selectedStudentIds.toList(),
                  'category': heading.toLowerCase().contains('defaulter') || heading.toLowerCase().contains('fee')
                      ? 'Payment'
                      : (heading.toLowerCase().contains('mess') ? 'Mess' : 'General'),
                  'createdAt': DateTime.now().toIso8601String(),
                });
              } catch (e) {
                debugPrint("Notice cloud save error: $e");
              }

              _showSnackbar("Broadcast notification sent successfully to $recipientCount recipients!");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: adminPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text("Send Now", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : adminPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD METHODS
  // ---------------------------------------------------------------------------

  void _handleBackToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackToDashboard();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const AdminDrawer(activeItem: "Broadcast Notification"),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
            tooltip: "Back to Dashboard",
            onPressed: _handleBackToDashboard,
          ),
          title: Text(
            "Broadcast Notification",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          actions: [
            Builder(
              builder: (drawerCtx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
                tooltip: "Open Menu",
                onPressed: () => Scaffold.of(drawerCtx).openDrawer(),
              ),
            ),
            const SizedBox(width: 4),
          ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: adminPrimary,
          indicatorWeight: 3,
          labelColor: adminPrimary,
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
                  const Text("History"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<StudentProfile>>(
        stream: FirestoreService().getStudentsStream(),
        builder: (context, studentsSnapshot) {
          final allStudents = studentsSnapshot.data ?? [];

          return StreamBuilder<List<BillModel>>(
            stream: FirestoreService().getBillsStream(),
            builder: (context, billsSnapshot) {
              final allBills = billsSnapshot.data ?? [];

              return TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: Send Broadcast
                  _buildSendBroadcastTab(allStudents: allStudents, allBills: allBills),

                  // TAB 2: Notification History
                  _buildHistoryTab(),
                ],
              );
            },
          );
        },
      ),
    ),
  );
}

  // ---------------------------------------------------------------------------
  // TAB 1: SEND BROADCAST
  // ---------------------------------------------------------------------------

  Widget _buildSendBroadcastTab({
    required List<StudentProfile> allStudents,
    required List<BillModel> allBills,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===================================================================
          // SECTION 1: SEND MESSAGE TO (Audience Selection)
          // ===================================================================
          _buildAudienceSectionCard(allStudents: allStudents, allBills: allBills),

          const SizedBox(height: 18),

          // ===================================================================
          // SECTION 2: MESSAGE CONTENT (Custom vs Templates)
          // ===================================================================
          _buildMessageContentCard(allStudents: allStudents, allBills: allBills),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1 WIDGET: AUDIENCE SELECTION
  // ---------------------------------------------------------------------------

  Widget _buildAudienceSectionCard({
    required List<StudentProfile> allStudents,
    required List<BillModel> allBills,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: adminPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_alt_rounded, color: adminPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                "1. Send message to",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Radio Option 1: All students
          _buildAudienceRadioTile(
            value: BroadcastAudience.allStudents,
            title: "All students",
            subtitle: "Send notification to all students across all buildings",
            icon: Icons.groups_rounded,
          ),

          // Radio Option 2: All defaulters
          _buildAudienceRadioTile(
            value: BroadcastAudience.allDefaulters,
            title: "All defaulters",
            subtitle: "Send message to all students with overdue fee payments",
            icon: Icons.warning_amber_rounded,
            isWarning: true,
          ),

          // Radio Option 3: Building
          _buildAudienceRadioTile(
            value: BroadcastAudience.building,
            title: "Building",
            subtitle: "Choose one or multiple buildings from menu",
            icon: Icons.domain_rounded,
          ),

          // Sub-view when Building is selected: Multi-select Dropdown & Chips
          if (_currentAudience == BroadcastAudience.building) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36.0, right: 8.0, top: 4.0, bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Multi-select building button/dropdown
                  InkWell(
                    onTap: _openBuildingSelectorSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedBuildings.isNotEmpty ? adminPrimary : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.domain_rounded,
                            size: 18,
                            color: _selectedBuildings.isNotEmpty ? adminPrimary : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedBuildings.isEmpty
                                  ? "Choose buildings (Tap to select)..."
                                  : "${_selectedBuildings.length} Buildings Selected",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _selectedBuildings.isNotEmpty
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),

                  // Selected building chips
                  if (_selectedBuildings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selectedBuildings.map((building) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                building,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: adminPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedBuildings.remove(building);
                                  });
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: adminPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Radio Option 4: Select student
          _buildAudienceRadioTile(
            value: BroadcastAudience.selectStudent,
            title: "Select student",
            subtitle: "Search, add and send to multiple specific students",
            icon: Icons.person_search_rounded,
          ),

          // Sub-view when Select student is selected: Search & Selection Tray
          if (_currentAudience == BroadcastAudience.selectStudent) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36.0, right: 8.0, top: 4.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Field
                  TextField(
                    controller: _studentSearchController,
                    onChanged: (val) {
                      setState(() {
                        _studentSearchQuery = val.trim().toLowerCase();
                      });
                    },
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: "Search by name, room, or registration number...",
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                      suffixIcon: _studentSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                setState(() {
                                  _studentSearchController.clear();
                                  _studentSearchQuery = "";
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),

                  // Matching Search Results (Filtered)
                  if (_studentSearchQuery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Builder(
                        builder: (context) {
                          final filtered = allStudents.where((s) {
                            final q = _studentSearchQuery;
                            return s.fullName.toLowerCase().contains(q) ||
                                s.room.toLowerCase().contains(q) ||
                                s.registrationNumber.toLowerCase().contains(q) ||
                                s.building.toLowerCase().contains(q);
                          }).toList();

                          if (filtered.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "No students found matching \"$_studentSearchQuery\"",
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (context, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (context, i) {
                              final student = filtered[i];
                              final isSelected = _selectedStudentIds.contains(student.id);

                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isSelected ? adminPrimary : const Color(0xFFE2E8F0),
                                  child: Text(
                                    student.firstName.isNotEmpty ? student.firstName[0].toUpperCase() : "S",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student.fullName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                subtitle: Text(
                                  "Room ${student.room} • ${student.building} • ${student.registrationNumber}",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle_rounded, color: adminPrimary, size: 20)
                                    : const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedStudentIds.remove(student.id);
                                    } else {
                                      _selectedStudentIds.add(student.id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  // Selected Students Tray
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Selected Students (${_selectedStudentIds.length}):",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      if (_selectedStudentIds.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedStudentIds.clear();
                            });
                          },
                          child: Text(
                            "Clear All",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_selectedStudentIds.isEmpty)
                    Text(
                      "No students added yet. Use the search box above to add students.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selectedStudentIds.map((sid) {
                        final student = allStudents.firstWhere(
                          (s) => s.id == sid,
                          orElse: () => StudentProfile(
                            id: sid,
                            studentId: sid,
                            fullName: "Student",
                            firstName: "S",
                            email: "",
                            phone: "",
                            registrationNumber: sid,
                            course: "",
                            branch: "",
                            building: "",
                            room: "",
                            plan: "",
                            paymentFrequency: "",
                            monthlyRent: "",
                            securityDeposit: "",
                            guardianName: "",
                            guardianPhone: "",
                            guardianRelationship: "",
                            dietaryPreference: "",
                          ),
                        );

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${student.fullName} (${student.room})",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: adminPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedStudentIds.remove(sid);
                                  });
                                },
                                child: const Icon(Icons.close_rounded, size: 14, color: adminPrimary),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadioCircle({required bool isSelected, bool isWarning = false}) {
    final activeColor = isWarning ? const Color(0xFFDC2626) : adminPrimary;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? activeColor : const Color(0xFF94A3B8),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAudienceRadioTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isWarning = false,
  }) {
    final isSelected = _currentAudience == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAudience = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? (isWarning ? const Color(0xFFFEF2F2) : const Color(0xFFEEF2FF)) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: isWarning ? const Color(0xFFFCA5A5) : const Color(0xFFC7D2FE))
              : null,
        ),
        child: Row(
          children: [
            _buildRadioCircle(isSelected: isSelected, isWarning: isWarning),
            const SizedBox(width: 10),
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isWarning ? const Color(0xFFDC2626) : adminPrimary)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? (isWarning ? const Color(0xFFDC2626) : const Color(0xFF0F172A))
                          : const Color(0xFF334155),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2 WIDGET: MESSAGE CONTENT (Custom vs Templates)
  // ---------------------------------------------------------------------------

  Widget _buildMessageContentCard({
    required List<StudentProfile> allStudents,
    required List<BillModel> allBills,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: adminPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note_rounded, color: adminPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                "2. Message Content",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Message Mode Radio Buttons (Custom vs Templates)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Radio Option: Custom
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _messageMode = BroadcastMessageMode.custom;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _currentMode == BroadcastMessageMode.custom ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _currentMode == BroadcastMessageMode.custom
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRadioCircle(isSelected: _currentMode == BroadcastMessageMode.custom),
                          const SizedBox(width: 8),
                          Text(
                            "Custom",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _currentMode == BroadcastMessageMode.custom
                                  ? adminPrimary
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Radio Option: Templates
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _messageMode = BroadcastMessageMode.templates;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _currentMode == BroadcastMessageMode.templates ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _currentMode == BroadcastMessageMode.templates
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRadioCircle(isSelected: _currentMode == BroadcastMessageMode.templates),
                          const SizedBox(width: 8),
                          Text(
                            "Templates",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _currentMode == BroadcastMessageMode.templates
                                  ? adminPrimary
                                  : const Color(0xFF64748B),
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
          const SizedBox(height: 18),

          // -------------------------------------------------------------------
          // VIEW A: UNDER CUSTOM
          // -------------------------------------------------------------------
          if (_currentMode == BroadcastMessageMode.custom) ...[
            Text(
              "Heading",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _customHeadingController,
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "e.g. Water Tank Maintenance",
                hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              "Description",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _customDescriptionController,
              maxLines: 5,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.45),
              decoration: InputDecoration(
                hintText: "Type your custom notification message here...",
                hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.all(14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _attemptSendBroadcast(allStudents: allStudents, allBills: allBills),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  "Send Broadcast Notification",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: adminPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],

          // -------------------------------------------------------------------
          // VIEW B: UNDER TEMPLATES
          // -------------------------------------------------------------------
          if (_currentMode == BroadcastMessageMode.templates) ...[
            // Templates Header with "Add Template" button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Choose a Template",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showAddTemplateDialog,
                  icon: const Icon(Icons.add_rounded, size: 16, color: adminPrimary),
                  label: Text(
                    "Add Template",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: adminPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: adminPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Horizontal / Vertical Template Cards
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _templates.length,
                separatorBuilder: (context, i) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final template = _templates[i];
                  final isSelected = _selectedTemplateId == template.id;

                  return InkWell(
                    onTap: () => _onSelectTemplate(template),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 240,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? adminPrimary : const Color(0xFFCBD5E1),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  template.heading,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? adminPrimary : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showEditTemplateDialog(template),
                                    child: const Padding(
                                      padding: EdgeInsets.all(3.0),
                                      child: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                  if (!template.isPreset)
                                    GestureDetector(
                                      onTap: () => _deleteTemplate(template),
                                      child: const Padding(
                                        padding: EdgeInsets.all(3.0),
                                        child: Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              template.description,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 15,
                                color: isSelected ? adminPrimary : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSelected ? "Selected" : "Tap to use",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? adminPrimary : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Live Editable Fields for Selected Template
            const SizedBox(height: 6),

            Text(
              "Heading (Editable)",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _templateHeadingController,
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              "Description (Editable)",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _templateDescriptionController,
              maxLines: 5,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.45),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _attemptSendBroadcast(allStudents: allStudents, allBills: allBills),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  "Send Broadcast Notification",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: adminPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: NOTIFICATION HISTORY
  // ---------------------------------------------------------------------------

  Widget _buildHistoryTab() {
    return StreamBuilder<List<BroadcastNoticeModel>>(
      stream: FirestoreService().getNotificationsStream(),
      builder: (context, snapshot) {
        final cloudItems = snapshot.data ?? [];

        final displayItems = cloudItems.map((n) {
          return BroadcastHistoryItem(
            id: n.id,
            title: n.title,
            message: n.message,
            audience: n.targetAudience,
            recipientCount: 0,
            timestamp: "${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}",
          );
        }).toList();

        if (displayItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_off_outlined, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text(
                  "No broadcast notifications sent yet.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];

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
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      height: 1.4,
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
                            item.recipientCount > 0 ? "${item.audience} (${item.recipientCount})" : item.audience,
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
        );
      },
    );
  }
}
