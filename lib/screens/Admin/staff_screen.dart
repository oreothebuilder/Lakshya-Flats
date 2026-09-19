import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/staff_model.dart';
import '../../models/building_model.dart';
import '../../models/user_role_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_drawer.dart';
import 'dashboard_screen.dart';
import '../../widgets/app_toast.dart';

class StaffScreen extends StatefulWidget {
  final AppUser? currentUser;

  const StaffScreen({
    super.key,
    this.currentUser,
  });

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Building In-Charge', 'Task-Based', 'Active', 'On Leave'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, {bool isSuccess = true}) {
    AppToast.show(context, msg, isSuccess: isSuccess);
  }

  List<StaffModel> _filterStaff(List<StaffModel> staffList) {
    var list = staffList;

    // Filter by type or status
    if (_selectedFilter == 'Building In-Charge') {
      list = list.where((s) => s.isBuildingInCharge).toList();
    } else if (_selectedFilter == 'Task-Based') {
      list = list.where((s) => s.isTaskBased).toList();
    } else if (_selectedFilter == 'Active') {
      list = list.where((s) => s.isActive).toList();
    } else if (_selectedFilter == 'On Leave') {
      list = list.where((s) => s.status.toLowerCase() == 'on leave').toList();
    }

    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((s) {
      final matchName = s.name.toLowerCase().contains(q);
      final matchId = s.staffId.toLowerCase().contains(q);
      final matchPhone = s.phone.toLowerCase().contains(q);
      final matchEmail = s.email.toLowerCase().contains(q);
      final matchDesig = s.designation.toLowerCase().contains(q);
      final matchTask = (s.assignedTask ?? '').toLowerCase().contains(q);
      final matchNotes = (s.notes ?? '').toLowerCase().contains(q);
      final matchBld = s.assignedBuildings.any((b) => b.toLowerCase().contains(q));
      return matchName || matchId || matchPhone || matchEmail || matchDesig || matchTask || matchNotes || matchBld;
    }).toList();
  }

  IconData _getRoleIcon(StaffModel staff) {
    final taskOrRole = '${staff.assignedTask ?? ''} ${staff.designation}'.toLowerCase();
    if (taskOrRole.contains('driver')) {
      return Icons.directions_bus_rounded;
    } else if (taskOrRole.contains('chef') || taskOrRole.contains('cook') || taskOrRole.contains('mess')) {
      return Icons.restaurant_rounded;
    } else if (taskOrRole.contains('security') || taskOrRole.contains('guard')) {
      return Icons.security_rounded;
    } else if (taskOrRole.contains('electric')) {
      return Icons.bolt_rounded;
    } else if (taskOrRole.contains('plumb')) {
      return Icons.plumbing_rounded;
    } else if (taskOrRole.contains('clean') || taskOrRole.contains('housekeep')) {
      return Icons.cleaning_services_rounded;
    } else if (taskOrRole.contains('garden')) {
      return Icons.yard_rounded;
    } else if (taskOrRole.contains('maintenance') || taskOrRole.contains('technician')) {
      return Icons.handyman_rounded;
    } else if (staff.isBuildingInCharge) {
      return Icons.apartment_rounded;
    }
    return Icons.badge_rounded;
  }

  Color _getRoleIconColor(StaffModel staff) {
    final taskOrRole = '${staff.assignedTask ?? ''} ${staff.designation}'.toLowerCase();
    if (taskOrRole.contains('driver')) {
      return const Color(0xFF0284C7); // Sky blue
    } else if (taskOrRole.contains('chef') || taskOrRole.contains('cook') || taskOrRole.contains('mess')) {
      return const Color(0xFFD97706); // Amber/Orange
    } else if (taskOrRole.contains('security') || taskOrRole.contains('guard')) {
      return const Color(0xFFDC2626); // Red
    } else if (taskOrRole.contains('electric')) {
      return const Color(0xFFEAB308); // Yellow
    } else if (taskOrRole.contains('plumb')) {
      return const Color(0xFF2563EB); // Royal Blue
    } else if (taskOrRole.contains('clean') || taskOrRole.contains('housekeep')) {
      return const Color(0xFF0D9488); // Teal
    } else if (staff.isBuildingInCharge) {
      return const Color(0xFF16A34A); // Green
    }
    return const Color(0xFF0D52CE); // Primary Brand Blue
  }

  void _openStaffProfileModal({StaffModel? existing}) async {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final customTaskController = TextEditingController();

    // Auto-generate staff ID if new
    String initialStaffId = existing?.staffId ?? '';
    if (!isEditing) {
      try {
        initialStaffId = await _firestoreService.generateNextStaffId();
      } catch (_) {
        initialStaffId = 'STF-${DateTime.now().millisecondsSinceEpoch % 10000}';
      }
    }
    final staffIdController = TextEditingController(text: initialStaffId);

    // Assignment Type: 'building_incharge' or 'task_based'
    String assignmentType = existing?.assignmentType ?? 'building_incharge';

    // Building in-charge designations
    final buildingDesignations = [
      'Warden',
      'Senior Warden',
      'Assistant Warden',
      'Hostel Manager',
      'Facility Supervisor',
      'Caretaker',
      'Building In-Charge',
    ];

    // Task presets
    final taskPresets = [
      {'title': 'Driver', 'icon': Icons.directions_bus_rounded},
      {'title': 'Chef / Cook', 'icon': Icons.restaurant_rounded},
      {'title': 'Security Guard', 'icon': Icons.security_rounded},
      {'title': 'Electrician', 'icon': Icons.bolt_rounded},
      {'title': 'Plumber', 'icon': Icons.plumbing_rounded},
      {'title': 'Housekeeping', 'icon': Icons.cleaning_services_rounded},
      {'title': 'Gardener', 'icon': Icons.yard_rounded},
      {'title': 'Maintenance', 'icon': Icons.handyman_rounded},
      {'title': 'Other Task', 'icon': Icons.more_horiz_rounded},
    ];

    String selectedDesignation = existing?.designation ?? 'Warden';
    String selectedTask = existing?.assignedTask ?? '';
    if (assignmentType == 'task_based' && selectedTask.isEmpty) {
      selectedTask = 'Driver';
    }

    // Check if task is one of presets
    bool isCustomTask = false;
    if (assignmentType == 'task_based' && selectedTask.isNotEmpty) {
      final isPreset = taskPresets.any((p) => p['title'] == selectedTask);
      if (!isPreset) {
        isCustomTask = true;
        customTaskController.text = selectedTask;
      }
    }

    final taskDutyController = TextEditingController(
      text: existing?.notes ?? '',
    );

    String selectedStatus = existing?.status ?? 'Active';
    List<String> assignedBuildings = existing != null ? List<String>.from(existing.assignedBuildings) : [];

    bool isSaving = false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEditing ? Icons.badge_rounded : Icons.person_add_rounded,
                            color: const Color(0xFF0D52CE),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? "Edit Staff Profile" : "Create Staff Profile",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                isEditing ? "Update assignments, buildings, or duties" : "Assign building in-charge or operational task",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Staff ID & Status Row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Staff ID *"),
                                    TextField(
                                      controller: staffIdController,
                                      decoration: _inputDec("e.g. STF-101", prefix: const Icon(Icons.tag_rounded, size: 18)),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0D52CE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Status"),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedStatus,
                                          isExpanded: true,
                                          items: const [
                                            DropdownMenuItem(value: 'Active', child: Text('Active')),
                                            DropdownMenuItem(value: 'On Leave', child: Text('On Leave')),
                                            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) setModalState(() => selectedStatus = val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2. Full Name
                          _buildLabel("Full Name *"),
                          TextField(
                            controller: nameController,
                            decoration: _inputDec("e.g. Rajesh Kumar / Mohan Lal", prefix: const Icon(Icons.person_outline_rounded, size: 20)),
                            style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),

                          // 3. Contact (Phone & Email)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Phone Number *"),
                                    TextField(
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: _inputDec("+91 9876543210", prefix: const Icon(Icons.phone_outlined, size: 18)),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Email (Optional)"),
                                    TextField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: _inputDec("staff@lakshya.com", prefix: const Icon(Icons.email_outlined, size: 18)),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // 4. Assignment Category Selector
                          _buildLabel("Assignment Type *"),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        assignmentType = 'building_incharge';
                                        selectedDesignation = 'Warden';
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: assignmentType == 'building_incharge' ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: assignmentType == 'building_incharge'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.06),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.apartment_rounded,
                                            size: 18,
                                            color: assignmentType == 'building_incharge' ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Building In-Charge",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: assignmentType == 'building_incharge' ? FontWeight.w800 : FontWeight.w600,
                                              color: assignmentType == 'building_incharge' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        assignmentType = 'task_based';
                                        if (selectedTask.isEmpty) selectedTask = 'Driver';
                                        selectedDesignation = selectedTask;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: assignmentType == 'task_based' ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: assignmentType == 'task_based'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.06),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.engineering_rounded,
                                            size: 18,
                                            color: assignmentType == 'task_based' ? const Color(0xFF0D52CE) : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Particular Task",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: assignmentType == 'task_based' ? FontWeight.w800 : FontWeight.w600,
                                              color: assignmentType == 'task_based' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
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

                          // ==========================================
                          // OPTION A: BUILDING IN-CHARGE CONFIGURATION
                          // ==========================================
                          if (assignmentType == 'building_incharge') ...[
                            _buildLabel("Role / Title in Building *"),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: buildingDesignations.contains(selectedDesignation) ? selectedDesignation : buildingDesignations.first,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF16A34A)),
                                  items: buildingDesignations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedDesignation = val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Select which buildings this staff is in charge of
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.apartment_rounded, color: Color(0xFF15803D), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Assigned Hostels / Buildings in Charge",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            color: const Color(0xFF14532D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Tap the buildings this staff member oversees:",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF166534),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Dynamic Stream of buildings
                                  StreamBuilder<List<BuildingModel>>(
                                    stream: _firestoreService.getBuildingsStream(),
                                    builder: (context, bldSnapshot) {
                                      final buildings = bldSnapshot.data ?? [];
                                      if (buildings.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Text(
                                            "No buildings found in database yet.",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: const Color(0xFF166534),
                                            ),
                                          ),
                                        );
                                      }

                                      return Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: buildings.map((b) {
                                          final isAssigned = assignedBuildings.contains(b.name);
                                          return FilterChip(
                                            label: Text(b.name),
                                            selected: isAssigned,
                                            selectedColor: const Color(0xFF16A34A),
                                            checkmarkColor: Colors.white,
                                            labelStyle: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: isAssigned ? FontWeight.w700 : FontWeight.w600,
                                              color: isAssigned ? Colors.white : const Color(0xFF1E293B),
                                            ),
                                            backgroundColor: Colors.white,
                                            side: BorderSide(
                                              color: isAssigned ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                            ),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            onSelected: (selected) {
                                              setModalState(() {
                                                if (selected) {
                                                  assignedBuildings.add(b.name);
                                                } else {
                                                  assignedBuildings.remove(b.name);
                                                }
                                              });
                                            },
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]

                          // ==========================================
                          // OPTION B: PARTICULAR TASK CONFIGURATION
                          // ==========================================
                          else ...[
                            _buildLabel("Select Particular Task *"),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: taskPresets.map((preset) {
                                final title = preset['title'] as String;
                                final icon = preset['icon'] as IconData;
                                final isSelected = !isCustomTask && selectedTask == title;

                                return ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 16,
                                        color: isSelected ? Colors.white : const Color(0xFF0D52CE),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(title),
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF0D52CE),
                                  labelStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF0D52CE) : const Color(0xFFE2E8F0),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (title == 'Other Task') {
                                        isCustomTask = true;
                                        selectedTask = customTaskController.text.trim();
                                        selectedDesignation = selectedTask.isNotEmpty ? selectedTask : 'Specialist';
                                      } else {
                                        isCustomTask = false;
                                        selectedTask = title;
                                        selectedDesignation = title;
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // If other task selected, allow custom title
                            if (isCustomTask) ...[
                              _buildLabel("Custom Task Title *"),
                              TextField(
                                controller: customTaskController,
                                decoration: _inputDec("e.g. Carpenter, Painter, Gym Trainer..."),
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
                                onChanged: (val) {
                                  selectedTask = val.trim();
                                  selectedDesignation = val.trim().isNotEmpty ? val.trim() : 'Specialist';
                                },
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Specific duty / shift description
                            _buildLabel("Task Duty / Route / Shift Details (Optional)"),
                            TextField(
                              controller: taskDutyController,
                              maxLines: 2,
                              decoration: _inputDec("e.g. Morning & Evening College Bus Route, Central Mess Lunch & Dinner Cook, Night Shift Patrol..."),
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                            ),
                            const SizedBox(height: 16),

                            // Optional building assignment for task-based staff
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Assigned Property / Base (Optional)",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: const Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Leave unselected if assigned campus-wide or across all hostels.",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  StreamBuilder<List<BuildingModel>>(
                                    stream: _firestoreService.getBuildingsStream(),
                                    builder: (context, bldSnapshot) {
                                      final buildings = bldSnapshot.data ?? [];
                                      return Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: buildings.map((b) {
                                          final isAssigned = assignedBuildings.contains(b.name);
                                          return FilterChip(
                                            label: Text(b.name),
                                            selected: isAssigned,
                                            selectedColor: const Color(0xFF0D52CE),
                                            checkmarkColor: Colors.white,
                                            labelStyle: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: isAssigned ? FontWeight.w700 : FontWeight.w600,
                                              color: isAssigned ? Colors.white : const Color(0xFF1E293B),
                                            ),
                                            backgroundColor: Colors.white,
                                            side: BorderSide(
                                              color: isAssigned ? const Color(0xFF0D52CE) : const Color(0xFFCBD5E1),
                                            ),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            onSelected: (selected) {
                                              setModalState(() {
                                                if (selected) {
                                                  assignedBuildings.add(b.name);
                                                } else {
                                                  assignedBuildings.remove(b.name);
                                                }
                                              });
                                            },
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // 5. Additional Notes
                          _buildLabel("General Notes (Optional)"),
                          TextField(
                            controller: notesController,
                            maxLines: 2,
                            decoration: _inputDec("Emergency contact, remarks, license number, etc..."),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final name = nameController.text.trim();
                                    final phone = phoneController.text.trim();
                                    final staffId = staffIdController.text.trim();

                                    if (name.isEmpty) {
                                      _showSnackbar("Please enter staff member's name", isSuccess: false);
                                      return;
                                    }
                                    if (phone.isEmpty) {
                                      _showSnackbar("Please enter a phone number", isSuccess: false);
                                      return;
                                    }
                                    if (staffId.isEmpty) {
                                      _showSnackbar("Please provide a Staff ID", isSuccess: false);
                                      return;
                                    }

                                    String finalTask = selectedTask;
                                    if (assignmentType == 'task_based' && isCustomTask) {
                                      finalTask = customTaskController.text.trim();
                                      if (finalTask.isEmpty) {
                                        _showSnackbar("Please specify the custom task", isSuccess: false);
                                        return;
                                      }
                                    }

                                    final finalDesignation = assignmentType == 'building_incharge'
                                        ? selectedDesignation
                                        : (finalTask.isNotEmpty ? finalTask : 'Staff');

                                    // Combine duty notes if provided
                                    String finalNotes = notesController.text.trim();
                                    final dutyNotes = taskDutyController.text.trim();
                                    if (assignmentType == 'task_based' && dutyNotes.isNotEmpty) {
                                      if (finalNotes.isNotEmpty) {
                                        finalNotes = "Duty: $dutyNotes | $finalNotes";
                                      } else {
                                        finalNotes = "Duty: $dutyNotes";
                                      }
                                    }

                                    setModalState(() => isSaving = true);

                                    try {
                                      final payload = StaffModel(
                                        id: isEditing ? existing.id : 'staff_${DateTime.now().millisecondsSinceEpoch}',
                                        staffId: staffId,
                                        name: name,
                                        phone: phone,
                                        email: emailController.text.trim(),
                                        assignmentType: assignmentType,
                                        designation: finalDesignation,
                                        assignedTask: assignmentType == 'task_based' ? finalTask : null,
                                        assignedBuildings: assignedBuildings,
                                        status: selectedStatus,
                                        notes: finalNotes,
                                        joinedDate: existing?.joinedDate ?? DateTime.now(),
                                      );

                                      if (isEditing) {
                                        await _firestoreService.updateStaff(existing.id, payload.toMap());
                                        _showSnackbar("Staff profile '${payload.name}' updated successfully!");
                                      } else {
                                        await _firestoreService.onboardStaff(payload);
                                        _showSnackbar("Staff profile '${payload.name}' ($staffId) created successfully!");
                                      }

                                      if (ctx.mounted) Navigator.pop(ctx);
                                    } catch (e) {
                                      _showSnackbar("Error saving staff profile: $e", isSuccess: false);
                                    } finally {
                                      if (mounted) setModalState(() => isSaving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D52CE),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(isEditing ? Icons.check_rounded : Icons.person_add_rounded, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        isEditing ? "Save Profile" : "Create Profile",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteStaff(StaffModel staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
            const SizedBox(width: 10),
            Text(
              "Remove Staff Profile",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to remove '${staff.name}' (${staff.staffId}) from the staff directory?",
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF475569)),
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
              try {
                await _firestoreService.deleteStaff(staff.id);
                _showSnackbar("Staff member '${staff.name}' removed.");
              } catch (e) {
                _showSnackbar("Error removing staff: $e", isSuccess: false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Remove", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _quickToggleStatus(StaffModel staff) {
    final nextStatus = staff.isActive ? 'On Leave' : 'Active';
    _firestoreService.updateStaff(staff.id, {'status': nextStatus}).then((_) {
      _showSnackbar("${staff.name}'s status changed to $nextStatus");
    }).catchError((e) {
      _showSnackbar("Failed to update status: $e", isSuccess: false);
    });
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
      ),
    );
  }

  InputDecoration _inputDec(String hint, {Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13.5),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D52CE), width: 1.5),
      ),
    );
  }

  Widget _buildSummaryBanner(List<StaffModel> allStaff) {
    final totalCount = allStaff.length;
    final inchargeCount = allStaff.where((s) => s.isBuildingInCharge).length;
    final taskCount = allStaff.where((s) => s.isTaskBased).length;
    final activeCount = allStaff.where((s) => s.isActive).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBannerMetric(
              icon: Icons.badge_outlined,
              iconColor: const Color(0xFF0D52CE),
              iconBg: const Color(0xFFE8F0FE),
              title: "Total Staff",
              value: "$totalCount",
              subtitle: "$activeCount Active",
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          Expanded(
            child: _buildBannerMetric(
              icon: Icons.apartment_rounded,
              iconColor: const Color(0xFF16A34A),
              iconBg: const Color(0xFFF0FDF4),
              title: "In-Charges",
              value: "$inchargeCount",
              subtitle: "Wardens",
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          Expanded(
            child: _buildBannerMetric(
              icon: Icons.engineering_rounded,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFEF3C7),
              title: "Task Staff",
              value: "$taskCount",
              subtitle: "Driver, Chef...",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerMetric({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffCard(StaffModel staff) {
    final hasBuildings = staff.assignedBuildings.isNotEmpty;
    final roleIcon = _getRoleIcon(staff);
    final iconColor = _getRoleIconColor(staff);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar, Name, Designation/Task, and Popup Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with dynamic icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(roleIcon, color: iconColor, size: 24),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Staff ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            staff.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Staff ID Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            staff.staffId,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D52CE),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Role + Assignment Type Badge
                    Row(
                      children: [
                        // Assignment Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: staff.isBuildingInCharge ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            staff.isBuildingInCharge ? "Building In-Charge" : "Particular Task",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: staff.isBuildingInCharge ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Designation or Task text
                        Flexible(
                          child: Text(
                            staff.isTaskBased && staff.assignedTask != null && staff.assignedTask!.isNotEmpty
                                ? staff.assignedTask!
                                : staff.designation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Indicator & Actions menu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _quickToggleStatus(staff),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: staff.isActive
                            ? const Color(0xFFDCFCE7)
                            : (staff.status.toLowerCase() == 'on leave' ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        staff.status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: staff.isActive
                              ? const Color(0xFF16A34A)
                              : (staff.status.toLowerCase() == 'on leave' ? const Color(0xFFD97706) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0D52CE)),
                            const SizedBox(width: 8),
                            Text("Edit Profile", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(staff.isActive ? Icons.pause_circle_outline_rounded : Icons.check_circle_outline_rounded,
                                size: 18, color: const Color(0xFFD97706)),
                            const SizedBox(width: 8),
                            Text(staff.isActive ? "Mark On Leave" : "Mark Active",
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'copy_phone',
                        child: Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF475569)),
                            const SizedBox(width: 8),
                            Text("Copy Phone", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'copy_id',
                        child: Row(
                          children: [
                            const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF475569)),
                            const SizedBox(width: 8),
                            Text("Copy Staff ID", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text("Remove", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'edit') {
                        _openStaffProfileModal(existing: staff);
                      } else if (val == 'status') {
                        _quickToggleStatus(staff);
                      } else if (val == 'copy_phone') {
                        Clipboard.setData(ClipboardData(text: staff.phone));
                        _showSnackbar("Phone number copied to clipboard");
                      } else if (val == 'copy_id') {
                        Clipboard.setData(ClipboardData(text: staff.staffId));
                        _showSnackbar("Staff ID '${staff.staffId}' copied to clipboard");
                      } else if (val == 'delete') {
                        _confirmDeleteStaff(staff);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Assigned Buildings / Task Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (staff.isBuildingInCharge) ...[
                  Row(
                    children: [
                      const Icon(Icons.domain_rounded, size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Text(
                        "In-Charge of Hostels:",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (!hasBuildings)
                    Text(
                      "No hostels assigned yet",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF94A3B8),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: staff.assignedBuildings.map((bldName) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.apartment_rounded, size: 12, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Text(
                                bldName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ] else ...[
                  // Task-based staff details
                  Row(
                    children: [
                      Icon(roleIcon, size: 14, color: iconColor),
                      const SizedBox(width: 6),
                      Text(
                        "Assigned Task: ${staff.assignedTask ?? staff.designation}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  if (staff.notes != null && staff.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      staff.notes!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (hasBuildings) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: staff.assignedBuildings.map((bldName) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            bldName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 3: Contact Info (Phone & Email)
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        staff.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (staff.email.isNotEmpty)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          staff.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleBackToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => DashboardScreen(currentUser: widget.currentUser),
      ),
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
        backgroundColor: const Color(0xFFF8FAF9),
        drawer: AdminDrawer(activeItem: "Staff", currentUser: widget.currentUser),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
            tooltip: "Back to Dashboard",
            onPressed: _handleBackToDashboard,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Staff",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                "Profiles, Building In-Charges & Tasks",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0D52CE), size: 22),
              tooltip: "Create Staff Profile",
              onPressed: () => _openStaffProfileModal(),
            ),
            Builder(
              builder: (drawerCtx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
                tooltip: "Open Menu",
                onPressed: () => Scaffold.of(drawerCtx).openDrawer(),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openStaffProfileModal(),
          backgroundColor: const Color(0xFF0D52CE),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.person_add_rounded, size: 20),
          label: Text(
            "Add Staff",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ),
        body: SafeArea(
          child: StreamBuilder<List<StaffModel>>(
            stream: _firestoreService.getStaffStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0D52CE)));
              }

              final allStaff = snapshot.data ?? [];
              final filteredStaff = _filterStaff(allStaff);

              return RefreshIndicator(
                color: const Color(0xFF0D52CE),
                onRefresh: () async => setState(() {}),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Executive Summary Banner
                      _buildSummaryBanner(allStaff),
                      const SizedBox(height: 18),

                      // 2. Search Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: "Search by staff name, ID, task, building...",
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13.5),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Category Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip("All", allStaff.length),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              "Building In-Charge",
                              allStaff.where((s) => s.isBuildingInCharge).length,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              "Task-Based",
                              allStaff.where((s) => s.isTaskBased).length,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              "Active",
                              allStaff.where((s) => s.isActive).length,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              "On Leave",
                              allStaff.where((s) => s.status.toLowerCase() == 'on leave').length,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Staff Profiles (${filteredStaff.length})",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedFilter = 'All';
                                });
                              },
                              child: Text(
                                "Reset filters",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0D52CE),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 5. Staff Cards List OR Empty State (Zero Dummy Data)
                      if (filteredStaff.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.people_outline_rounded, size: 44, color: Color(0xFF0D52CE)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                allStaff.isEmpty ? "No Staff Profiles Yet" : "No Staff Matches Filter",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                allStaff.isEmpty
                                    ? "Add staff profiles manually. Assign staff as building in-charges (wardens) or specific operational roles like driver, chef, electrician, etc."
                                    : "Try adjusting your search query or filter to see more profiles.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => _openStaffProfileModal(),
                                icon: const Icon(Icons.person_add_rounded, size: 18),
                                label: Text(
                                  "Create Staff Profile",
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D52CE),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredStaff.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, idx) => _buildStaffCard(filteredStaff[idx]),
                        ),

                      const SizedBox(height: 80), // Bottom clearance for FAB
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text("$label ($count)"),
      selected: isSelected,
      selectedColor: const Color(0xFF0D52CE),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF0D52CE) : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = label);
      },
    );
  }
}
