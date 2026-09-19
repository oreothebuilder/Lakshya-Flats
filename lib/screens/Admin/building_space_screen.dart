import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/building_model.dart';
import '../../models/student_profile_model.dart';
import '../../models/staff_model.dart';
import '../../models/complaint_model.dart';
import '../../models/user_role_model.dart';
import '../../services/firestore_service.dart';
import 'student_profile_detail_screen.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/building_photo_selector.dart';

class BuildingSpaceScreen extends StatefulWidget {
  final BuildingModel building;
  final AppUser? currentUser;

  const BuildingSpaceScreen({
    super.key,
    required this.building,
    this.currentUser,
  });

  @override
  State<BuildingSpaceScreen> createState() => _BuildingSpaceScreenState();
}

class _BuildingSpaceScreenState extends State<BuildingSpaceScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  final TextEditingController _studentSearchController = TextEditingController();
  String _studentSearchQuery = '';

  String _ticketStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  bool _matchesBuilding(String target, String candidate) {
    final t = target.toLowerCase().replaceAll('residency', '').replaceAll('homes', '').replaceAll('villa', '').trim();
    final c = candidate.toLowerCase().replaceAll('residency', '').replaceAll('homes', '').replaceAll('villa', '').trim();
    if (t.isEmpty || c.isEmpty) return false;
    return t.contains(c) || c.contains(t);
  }

  void _showSnackbar(String msg, {bool isSuccess = true}) {
    AppToast.show(context, msg, isSuccess: isSuccess);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackbar("$label copied to clipboard!");
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'resolved') return const Color(0xFF16A34A);
    if (s == 'under execution' || s == 'in progress') return const Color(0xFF0D52CE);
    return const Color(0xFFD97706); // Received / Pending
  }

  Color _getPriorityColor(String priority) {
    final p = priority.toLowerCase();
    if (p == 'emergency' || p == 'critical') return const Color(0xFFE11D48);
    if (p == 'high') return const Color(0xFFEA580C);
    if (p == 'medium') return const Color(0xFF0D52CE);
    return const Color(0xFF64748B);
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
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

  void _openBuildingEditorModal(BuildingModel existing) {
    final nameController = TextEditingController(text: existing.name);
    final capacityController = TextEditingController(text: existing.totalCapacity.toString());
    final roomsController = TextEditingController(text: existing.totalRooms.toString());
    final rentController = TextEditingController(text: existing.startingRent.toStringAsFixed(0));
    final locationController = TextEditingController(text: existing.campusLocation);
    final addressController = TextEditingController(text: existing.address);
    final customImageController = TextEditingController(text: existing.imageUrl ?? '');
    final wardenNameController = TextEditingController(text: existing.wardenName);
    final wardenPhoneController = TextEditingController(text: existing.wardenPhone);
    String selectedCategory = existing.category;
    String selectedAsset = existing.imageAsset;
    String? selectedStaffId = existing.staffId;

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
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
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Color(0xFF0D52CE),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Edit ${existing.name} & Capacity",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "Configure seats capacity, rooms, rent, and details",
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel("Building Name *"),
                                    TextField(
                                      controller: nameController,
                                      decoration: _inputDecoration("e.g. Lakshya, Ishaan"),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel("Category"),
                                    Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedCategory,
                                          isExpanded: true,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D52CE), size: 18),
                                          items: ['Boys Hostel', 'Girls Hostel', 'Co-Ed', 'Premium Flats']
                                              .map((cat) => DropdownMenuItem(
                                                    value: cat,
                                                    child: Text(cat, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                                  ))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) setModalState(() => selectedCategory = val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Capacity & Seating Configuration
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
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.event_seat_rounded, color: Color(0xFF16A34A), size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Seats & Room Capacity Configuration",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: const Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildFieldLabel("Total Seats (Capacity) *"),
                                          TextField(
                                            controller: capacityController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            decoration: _inputDecoration("e.g. 90, 120").copyWith(
                                              prefixIcon: const Icon(Icons.people_alt_rounded, size: 18, color: Color(0xFF16A34A)),
                                              suffixText: "Seats",
                                              suffixStyle: GoogleFonts.plusJakartaSans(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF166534),
                                              ),
                                            ),
                                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildFieldLabel("Total Rooms *"),
                                          TextField(
                                            controller: roomsController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            decoration: _inputDecoration("e.g. 45, 60").copyWith(
                                              prefixIcon: const Icon(Icons.meeting_room_rounded, size: 18, color: Color(0xFF16A34A)),
                                              suffixText: "Rooms",
                                              suffixStyle: GoogleFonts.plusJakartaSans(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF166534),
                                              ),
                                            ),
                                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFDCFCE7)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF16A34A)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Live Occupancy: The occupied count updates automatically whenever students are enrolled into this building from the Student Directory.",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            color: const Color(0xFF166534),
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel("Starting Rent (₹ / month)"),
                                    TextField(
                                      controller: rentController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: _inputDecoration("e.g. 12500").copyWith(
                                        prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18, color: Color(0xFF0D52CE)),
                                      ),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel("Campus Location"),
                                    TextField(
                                      controller: locationController,
                                      decoration: _inputDecoration("e.g. Main Campus, North"),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          _buildFieldLabel("Property Address (optional)"),
                          TextField(
                            controller: addressController,
                            decoration: _inputDecoration("e.g. Plot 12, Main Residency Boulevard"),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                          const SizedBox(height: 18),

                          // Building Photo Selector (Catalog + Device Upload)
                          BuildingPhotoSelector(
                            initialAsset: selectedAsset,
                            customImageController: customImageController,
                            onAssetChanged: (newAsset) {
                              setModalState(() => selectedAsset = newAsset);
                            },
                          ),
                          const SizedBox(height: 20),

                          // Staff Assignment Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.badge_rounded, color: Color(0xFF0D52CE), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Assigned Staff",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                StreamBuilder<List<StaffModel>>(
                                  stream: _firestoreService.getStaffStream(),
                                  builder: (context, staffSnapshot) {
                                    final staffList = staffSnapshot.data ?? [];

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel("Select from Staff Directory"),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFCBD5E1)),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String?>(
                                              value: staffList.any((s) => s.staffId == selectedStaffId) ? selectedStaffId : null,
                                              hint: Text(
                                                "Choose staff member...",
                                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
                                              ),
                                              isExpanded: true,
                                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D52CE)),
                                              items: [
                                                const DropdownMenuItem<String?>(
                                                  value: null,
                                                  child: Text("None / Custom Staff"),
                                                ),
                                                ...staffList.map((s) => DropdownMenuItem<String?>(
                                                      value: s.staffId,
                                                      child: Text("${s.name} (${s.staffId} • ${s.designation})"),
                                                    )),
                                              ],
                                              onChanged: (val) {
                                                setModalState(() {
                                                  selectedStaffId = val;
                                                  if (val != null) {
                                                    final found = staffList.firstWhere((s) => s.staffId == val);
                                                    wardenNameController.text = found.name;
                                                    wardenPhoneController.text = found.phone;
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    );
                                  },
                                ),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildFieldLabel("Staff / Warden Name"),
                                          TextField(
                                            controller: wardenNameController,
                                            decoration: _inputDecoration("e.g. Ramesh Kumar"),
                                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildFieldLabel("Staff Contact Phone"),
                                          TextField(
                                            controller: wardenPhoneController,
                                            keyboardType: TextInputType.phone,
                                            decoration: _inputDecoration("e.g. +91 98765 43210"),
                                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Bottom action buttons
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                                    if (name.isEmpty) {
                                      _showSnackbar("Please enter a building name", isSuccess: false);
                                      return;
                                    }

                                    final capacity = int.tryParse(capacityController.text.trim());
                                    if (capacity == null || capacity <= 0) {
                                      _showSnackbar("Please enter a valid total seating capacity (> 0)", isSuccess: false);
                                      return;
                                    }

                                    final rooms = int.tryParse(roomsController.text.trim()) ?? (capacity ~/ 2).clamp(1, 999);
                                    final rent = double.tryParse(rentController.text.trim()) ?? 12500.0;
                                    final campus = locationController.text.trim().isNotEmpty
                                        ? locationController.text.trim()
                                        : 'Main Campus';
                                    final address = addressController.text.trim();

                                    setModalState(() => isSaving = true);

                                    try {
                                      final warden = wardenNameController.text.trim().isNotEmpty
                                          ? wardenNameController.text.trim()
                                          : 'Warden In-Charge';
                                      final phone = wardenPhoneController.text.trim().isNotEmpty
                                          ? wardenPhoneController.text.trim()
                                          : '';
                                      final customImg = customImageController.text.trim().isNotEmpty
                                          ? customImageController.text.trim()
                                          : null;

                                      final updated = existing.copyWith(
                                        name: name,
                                        category: selectedCategory,
                                        campusLocation: campus,
                                        address: address,
                                        totalCapacity: capacity,
                                        totalRooms: rooms,
                                        startingRent: rent,
                                        imageAsset: selectedAsset,
                                        imageUrl: customImg,
                                        wardenName: warden,
                                        wardenPhone: phone,
                                        staffId: selectedStaffId,
                                      );
                                      await _firestoreService.updateBuilding(existing.id, updated.toMap());
                                      _showSnackbar("Building '${updated.name}' updated! Capacity set to $capacity seats.");

                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                      }
                                    } catch (e) {
                                      _showSnackbar("Error saving building: $e", isSuccess: false);
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
                                : Text(
                                    "Save Changes",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                    ),
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

  // ---------------------------------------------------------------------------
  // Status Update Dialog for Tickets
  // ---------------------------------------------------------------------------
  void _openUpdateTicketModal(ComplaintModel ticket) {
    String selectedStatus = ticket.status;
    final remarksController = TextEditingController(text: ticket.adminRemarks ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 14,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Update Ticket Status",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  Text(
                    "#${ticket.id.substring(0, ticket.id.length > 8 ? 8 : ticket.id.length).toUpperCase()} • ${ticket.title}",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "New Status",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ComplaintModel.validStatuses.map((s) {
                      final isSelected = selectedStatus == s;
                      return ChoiceChip(
                        label: Text(s),
                        selected: isSelected,
                        selectedColor: _getStatusColor(s),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                        side: BorderSide(
                          color: isSelected ? _getStatusColor(s) : const Color(0xFFE2E8F0),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedStatus = s);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Resolution Note / Admin Remarks",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: remarksController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter resolution details, technician notes, or update...",
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
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
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              try {
                                await _firestoreService.updateComplaintStatus(
                                  complaintId: ticket.id,
                                  status: selectedStatus,
                                  remarks: remarksController.text.trim(),
                                  complaint: ticket,
                                );
                                _showSnackbar("Ticket status updated to '$selectedStatus'");
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              } catch (e) {
                                _showSnackbar("Error updating status: $e", isSuccess: false);
                              } finally {
                                if (sheetCtx.mounted) setModalState(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D52CE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              "Update Ticket",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
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

  // ---------------------------------------------------------------------------
  // TAB 1: All Students in this Building
  // ---------------------------------------------------------------------------
  Widget _buildStudentsTab(List<StudentProfile> allStudents, BuildingModel currentBuilding) {
    final buildingStudents = allStudents.where((s) => _matchesBuilding(currentBuilding.name, s.building)).toList();

    final filteredStudents = buildingStudents.where((s) {
      if (_studentSearchQuery.isEmpty) return true;
      final q = _studentSearchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          s.room.toLowerCase().contains(q) ||
          s.registrationNumber.toLowerCase().contains(q) ||
          s.phone.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _studentSearchController,
              onChanged: (val) => setState(() => _studentSearchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: "Search ${currentBuilding.name} residents by name, room...",
                hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13.5),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                suffixIcon: _studentSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                        onPressed: () {
                          _studentSearchController.clear();
                          setState(() => _studentSearchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
            ),
          ),
        ),

        // Count header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Enrolled Residents (${filteredStudents.length})",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Live sync",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Students list
        Expanded(
          child: filteredStudents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 56, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 14),
                        Text(
                          _studentSearchQuery.isEmpty
                              ? "No students registered in ${currentBuilding.name} yet"
                              : "No residents match '$_studentSearchQuery'",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "New students onboarded to this building in the directory will appear here automatically.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  itemCount: filteredStudents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final student = filteredStudents[idx];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentProfileDetailScreen(
                              student: student,
                              currentUser: widget.currentUser,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar with photo or initials
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFE8F0FE),
                              backgroundImage: (student.photoUrl != null && student.photoUrl!.isNotEmpty)
                                  ? NetworkImage(student.photoUrl!)
                                  : null,
                              child: (student.photoUrl == null || student.photoUrl!.isEmpty)
                                  ? Text(
                                      student.fullName.isNotEmpty
                                          ? student.fullName.substring(0, 1).toUpperCase()
                                          : 'S',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0D52CE),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          student.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "Room ${student.room.isNotEmpty ? student.room : 'N/A'}${student.bedNumber.isNotEmpty ? ' • Bed ${student.bedNumber}' : ''}",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0D52CE),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          student.registrationNumber.isNotEmpty
                                              ? student.registrationNumber
                                              : student.studentId,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      if (student.phone.isNotEmpty) ...[
                                        const Text(" • ", style: TextStyle(color: Color(0xFF94A3B8))),
                                        GestureDetector(
                                          onTap: () => _copyToClipboard(student.phone, "Phone"),
                                          child: Text(
                                            student.phone,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Concerned Staff for this Building
  // ---------------------------------------------------------------------------
  Widget _buildStaffTab(List<StaffModel> allStaff, BuildingModel currentBuilding) {
    // Filter staff who are assigned to this building
    var staffList = allStaff.where((s) {
      return s.assignedBuildings.any((b) => _matchesBuilding(currentBuilding.name, b));
    }).toList();

    // If no staff explicitly assigned yet in staff collection, create a fallback
    // card from BuildingModel's designated warden & manager
    final hasExplicitStaff = staffList.isNotEmpty;
    if (!hasExplicitStaff && currentBuilding.wardenName.isNotEmpty) {
      staffList = [
        StaffModel(
          id: 'warden_bld_${currentBuilding.id}',
          staffId: 'WARDEN-INCHARGE',
          name: currentBuilding.wardenName,
          phone: currentBuilding.wardenPhone,
          designation: 'Hostel Warden In-Charge',
          assignedBuildings: [currentBuilding.name],
          status: 'Active',
        ),
      ];
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Concerned Staff (${staffList.length})",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Active Duty",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...staffList.map((staff) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFE8F0FE),
                      backgroundImage: (staff.photoUrl != null && staff.photoUrl!.isNotEmpty)
                          ? NetworkImage(staff.photoUrl!)
                          : null,
                      child: (staff.photoUrl == null || staff.photoUrl!.isEmpty)
                          ? Text(
                              staff.name.isNotEmpty ? staff.name.substring(0, 1).toUpperCase() : 'W',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0D52CE),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            staff.designation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0D52CE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: staff.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        staff.status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: staff.isActive ? const Color(0xFF15803D) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Contact Actions Row
                Row(
                  children: [
                    if (staff.phone.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyToClipboard(staff.phone, "Phone number"),
                          icon: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF0D52CE)),
                          label: Text(
                            staff.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0D52CE),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    if (staff.phone.isNotEmpty && staff.email.isNotEmpty)
                      const SizedBox(width: 10),
                    if (staff.email.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyToClipboard(staff.email, "Email address"),
                          icon: const Icon(Icons.email_outlined, size: 16, color: Color(0xFF475569)),
                          label: Text(
                            staff.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: Raised Tickets for this Building (Recent One on Top)
  // ---------------------------------------------------------------------------
  Widget _buildTicketsTab(List<ComplaintModel> allTickets, BuildingModel currentBuilding) {
    // Filter tickets for this building
    final buildingTickets = allTickets.where((t) => _matchesBuilding(currentBuilding.name, t.building)).toList();

    // Ensure sorted with recent one on top
    buildingTickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Apply status filter
    final filteredTickets = buildingTickets.where((t) {
      if (_ticketStatusFilter == 'All') return true;
      return t.status.toLowerCase() == _ticketStatusFilter.toLowerCase();
    }).toList();

    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                'All',
                ComplaintModel.statusReceived,
                ComplaintModel.statusUnderExecution,
                ComplaintModel.statusResolved,
              ].map((filter) {
                final isSelected = _ticketStatusFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0D52CE),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0D52CE) : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (val) {
                      if (val) setState(() => _ticketStatusFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Count Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Maintenance Tickets (${filteredTickets.length})",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF0D52CE)),
                  const SizedBox(width: 2),
                  Text(
                    "Newest first",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D52CE),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Tickets list
        Expanded(
          child: filteredTickets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_turned_in_outlined, size: 56, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 14),
                        Text(
                          _ticketStatusFilter == 'All'
                              ? "No tickets raised from ${currentBuilding.name} yet"
                              : "No '$_ticketStatusFilter' tickets found",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Resident complaints from ${currentBuilding.name} will be displayed here with the newest issues on top.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  itemCount: filteredTickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final ticket = filteredTickets[idx];
                    final statusColor = _getStatusColor(ticket.status);
                    final priorityColor = _getPriorityColor(ticket.priority);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top header: Category, Time ago, Status
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ticket.category.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0D52CE),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${ticket.priority} Priority",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: priorityColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(ticket.createdAt),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Title
                          Text(
                            ticket.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Student & Room detail
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${ticket.studentName} • Room ${ticket.room}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (ticket.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              ticket.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Bottom row: Status badge + update button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      ticket.status,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _openUpdateTicketModal(ticket),
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: Text(
                                  "Update Status",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0D52CE),
                                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Main Screen Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BuildingModel>>(
      stream: _firestoreService.getBuildingsStream(),
      builder: (context, buildingsSnapshot) {
        final currentBuilding = (buildingsSnapshot.data ?? []).firstWhere(
          (b) => b.id == widget.building.id || b.name.toLowerCase() == widget.building.name.toLowerCase(),
          orElse: () => widget.building,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${currentBuilding.name} Space",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "${currentBuilding.campusLocation} • ${currentBuilding.category}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF0F172A)),
                tooltip: "Edit Building & Capacity",
                onPressed: () => _openBuildingEditorModal(currentBuilding),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<List<StudentProfile>>(
            stream: _firestoreService.getStudentsStream(),
            builder: (context, studentsSnapshot) {
              final allStudents = studentsSnapshot.data ?? [];
              final buildingStudents = allStudents.where((s) => _matchesBuilding(currentBuilding.name, s.building)).toList();
              final detectedOccupancy = buildingStudents.length;

              return StreamBuilder<List<StaffModel>>(
                stream: _firestoreService.getStaffStream(),
                builder: (context, staffSnapshot) {
                  final allStaff = staffSnapshot.data ?? [];
                  final buildingStaff = allStaff.where((s) => s.assignedBuildings.any((b) => _matchesBuilding(currentBuilding.name, b))).toList();
                  final staffCount = buildingStaff.length;

                  return StreamBuilder<List<ComplaintModel>>(
                    stream: _firestoreService.getComplaintsStream(buildingFilter: currentBuilding.name),
                    builder: (context, ticketsSnapshot) {
                      final allTickets = ticketsSnapshot.data ?? [];
                      final buildingTickets = allTickets.where((t) => _matchesBuilding(currentBuilding.name, t.building)).toList();
                      final openTicketsCount = buildingTickets.where((t) => t.status != ComplaintModel.statusResolved).length;

                      final occupancyRate = currentBuilding.totalCapacity > 0
                          ? (detectedOccupancy / currentBuilding.totalCapacity).clamp(0.0, 1.0)
                          : 0.0;
                      final occupancyPercent = currentBuilding.totalCapacity > 0
                          ? ((detectedOccupancy / currentBuilding.totalCapacity) * 100).round()
                          : 0;

                      return Column(
                        children: [
                          // Top Hero & Occupancy Card
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                            child: Column(
                              children: [
                                // Building Photo Banner
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    height: 130,
                                    width: double.infinity,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: currentBuilding.hasRemoteImage
                                              ? Image.network(
                                                  currentBuilding.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => Container(
                                                    color: const Color(0xFFCBD5E1),
                                                    child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 36),
                                                  ),
                                                )
                                              : currentBuilding.imageAsset.isNotEmpty
                                                  ? Image.asset(
                                                      currentBuilding.imageAsset,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, _, _) => Container(
                                                        color: const Color(0xFFCBD5E1),
                                                        child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 36),
                                                      ),
                                                    )
                                                  : Container(
                                                      color: const Color(0xFFCBD5E1),
                                                      child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 36),
                                                    ),
                                        ),
                                        // Gradient overlay
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withValues(alpha: 0.2),
                                                  Colors.black.withValues(alpha: 0.6),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Overlay info
                                        Positioned(
                                          bottom: 12,
                                          left: 14,
                                          right: 14,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      currentBuilding.name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w900,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Text(
                                                      "${currentBuilding.campusLocation} • ${currentBuilding.totalCapacity} Total Beds",
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white.withValues(alpha: 0.9),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  "$occupancyPercent% Full",
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(0xFF0D52CE),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Dynamic Occupancy Bar
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.people_alt_rounded, size: 15, color: Color(0xFF0D52CE)),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    "$detectedOccupancy / ${currentBuilding.totalCapacity} Students",
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            children: [
                                              Text(
                                                "${(currentBuilding.totalCapacity - detectedOccupancy).clamp(0, currentBuilding.totalCapacity)} Available",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF16A34A),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () => _openBuildingEditorModal(currentBuilding),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0D52CE).withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.edit_rounded, size: 11, color: Color(0xFF0D52CE)),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        "Edit Seats",
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: const Color(0xFF0D52CE),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: SizedBox(
                                          height: 7,
                                          child: LinearProgressIndicator(
                                            value: occupancyRate,
                                            backgroundColor: const Color(0xFFE2E8F0),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              occupancyRate >= 0.90
                                                  ? const Color(0xFFEA580C)
                                                  : const Color(0xFF0D52CE),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tabs Header
                          Container(
                            color: Colors.white,
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: const Color(0xFF0D52CE),
                              indicatorWeight: 3,
                              labelColor: const Color(0xFF0D52CE),
                              unselectedLabelColor: const Color(0xFF64748B),
                              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Students"),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: _tabController.index == 0
                                              ? const Color(0xFF0D52CE)
                                              : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "$detectedOccupancy",
                                          style: TextStyle(
                                            color: _tabController.index == 0 ? Colors.white : const Color(0xFF475569),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Staff"),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: _tabController.index == 1
                                              ? const Color(0xFF0D52CE)
                                              : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "$staffCount",
                                          style: TextStyle(
                                            color: _tabController.index == 1 ? Colors.white : const Color(0xFF475569),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Tickets"),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: openTicketsCount > 0
                                              ? const Color(0xFFEF4444)
                                              : (_tabController.index == 2
                                                  ? const Color(0xFF0D52CE)
                                                  : const Color(0xFFE2E8F0)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "${buildingTickets.length}",
                                          style: TextStyle(
                                            color: (openTicketsCount > 0 || _tabController.index == 2)
                                                ? Colors.white
                                                : const Color(0xFF475569),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),

                          // Tab Views
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildStudentsTab(allStudents, currentBuilding),
                                _buildStaffTab(allStaff, currentBuilding),
                                _buildTicketsTab(buildingTickets, currentBuilding),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
