import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/admin_drawer.dart';
import '../../models/user_role_model.dart';
import '../../models/building_model.dart';
import '../../models/staff_model.dart';
import '../../models/student_profile_model.dart';
import '../../services/firestore_service.dart';
import 'dashboard_screen.dart';
import 'building_space_screen.dart';

class BuildingsManagementScreen extends StatefulWidget {
  final AppUser? currentUser;

  const BuildingsManagementScreen({
    super.key,
    this.currentUser,
  });

  @override
  State<BuildingsManagementScreen> createState() => _BuildingsManagementScreenState();
}

class _BuildingsManagementScreenState extends State<BuildingsManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isGridView = false;
  bool _matchesBuilding(String b1, String b2) {
    final t1 = b1.toLowerCase().replaceAll('residency', '').replaceAll('homes', '').replaceAll('villa', '').trim();
    final t2 = b2.toLowerCase().replaceAll('residency', '').replaceAll('homes', '').replaceAll('villa', '').trim();
    if (t1.isEmpty || t2.isEmpty) return false;
    return t1.contains(t2) || t2.contains(t1);
  }

  int _countStudentsForBuilding(String buildingName, List<StudentProfile> students) {
    return students.where((s) => _matchesBuilding(buildingName, s.building)).length;
  }

  List<BuildingModel> _filterBuildings(List<BuildingModel> buildings) {
    if (_searchQuery.isEmpty) return buildings;

    final q = _searchQuery.toLowerCase();
    return buildings.where((b) {
      return b.name.toLowerCase().contains(q) ||
          b.campusLocation.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q) ||
          b.wardenName.toLowerCase().contains(q) ||
          b.address.toLowerCase().contains(q) ||
          (b.staffId ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF0D52CE) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getOccupancyColor(double rate) {
    if (rate >= 0.95) return const Color(0xFFE11D48); // Near complete/critical (Rose/Red)
    if (rate >= 0.85) return const Color(0xFFEA580C); // High occupancy (Orange)
    if (rate >= 0.60) return const Color(0xFF0D52CE); // Steady healthy occupancy (Navy/Blue)
    return const Color(0xFF16A34A); // Ample spots (Green)
  }

  // ---------------------------------------------------------------------------
  // Add / Edit Building Modal (Photo, Name, Staff only)
  // ---------------------------------------------------------------------------
  void _openBuildingEditorModal({BuildingModel? existing}) {
    final isEditing = existing != null;

    final nameController = TextEditingController(text: existing?.name ?? '');
    final customImageController = TextEditingController(text: existing?.imageUrl ?? '');
    final wardenNameController = TextEditingController(text: existing?.wardenName ?? '');
    final wardenPhoneController = TextEditingController(text: existing?.wardenPhone ?? '');
    String selectedAsset = existing?.imageAsset ?? 'assets/buildings/Lakshya.png';
    String? selectedStaffId = existing?.staffId;

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Modal drag handle & header
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
                          child: Icon(
                            isEditing ? Icons.edit_note_rounded : Icons.add_business_rounded,
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
                                isEditing ? "Edit Building" : "Add New Building",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                isEditing
                                    ? "Update photo, name, and assigned staff"
                                    : "Register property into Lakshya system",
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

                  // Scrollable form fields: Photo, Name, Staff ONLY
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Building Name
                          _buildFieldLabel("Building Name *"),
                          TextField(
                            controller: nameController,
                            decoration: _inputDecoration("e.g. Lakshya, Livano, Shiv Villa"),
                            style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 18),

                          // 2. Select Building Photo from Catalog
                          _buildFieldLabel("Select Building Photo (from assets catalog)"),
                          SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: BuildingModel.builtInAssets.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 10),
                              itemBuilder: (context, idx) {
                                final item = BuildingModel.builtInAssets[idx];
                                final assetPath = item['asset']!;
                                final isSelected = selectedAsset == assetPath;

                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() => selectedAsset = assetPath);
                                  },
                                  child: Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF0D52CE) : const Color(0xFFE2E8F0),
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        children: [
                                          Image.asset(
                                            assetPath,
                                            width: 100,
                                            height: 110,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Container(
                                              color: const Color(0xFFCBD5E1),
                                              child: const Icon(Icons.apartment_rounded, color: Colors.white),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                                              color: Colors.black.withValues(alpha: 0.65),
                                              child: Text(
                                                item['name']!,
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF0D52CE),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.check, color: Colors.white, size: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Optional Remote Image URL
                          _buildFieldLabel("Or Custom Image URL (optional)"),
                          TextField(
                            controller: customImageController,
                            decoration: _inputDecoration("https://..."),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                          const SizedBox(height: 20),

                          // 3. Staff Assignment Section
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

                                // Select from Staff Directory
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

                                // Staff Name & Contact text inputs (auto filled or editable)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildFieldLabel("Staff Name *"),
                                          TextField(
                                            controller: wardenNameController,
                                            decoration: _inputDecoration("e.g. Rajesh Sharma"),
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
                                          _buildFieldLabel("Staff Phone *"),
                                          TextField(
                                            controller: wardenPhoneController,
                                            keyboardType: TextInputType.phone,
                                            decoration: _inputDecoration("+91 9876543210"),
                                            style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
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

                  // Bottom Save Action
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
                                    if (name.isEmpty) {
                                      _showSnackbar("Please enter a building name", isSuccess: false);
                                      return;
                                    }

                                    setModalState(() => isSaving = true);

                                    try {
                                      final warden = wardenNameController.text.trim().isNotEmpty
                                          ? wardenNameController.text.trim()
                                          : 'Warden In-Charge';
                                      final phone = wardenPhoneController.text.trim().isNotEmpty
                                          ? wardenPhoneController.text.trim()
                                          : '+91 9876543210';
                                      final customImg = customImageController.text.trim().isNotEmpty
                                          ? customImageController.text.trim()
                                          : null;

                                      if (isEditing) {
                                        final updated = existing.copyWith(
                                          name: name,
                                          imageAsset: selectedAsset,
                                          imageUrl: customImg,
                                          wardenName: warden,
                                          wardenPhone: phone,
                                          staffId: selectedStaffId,
                                        );
                                        await _firestoreService.updateBuilding(existing.id, updated.toMap());
                                        _showSnackbar("Building '${updated.name}' updated successfully!");
                                      } else {
                                        final newBld = BuildingModel(
                                          id: 'bld_${DateTime.now().millisecondsSinceEpoch}',
                                          name: name,
                                          imageAsset: selectedAsset,
                                          imageUrl: customImg,
                                          wardenName: warden,
                                          wardenPhone: phone,
                                          staffId: selectedStaffId,
                                        );
                                        await _firestoreService.addBuilding(newBld);
                                        _showSnackbar("New building '${newBld.name}' added successfully!");
                                      }

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
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(isEditing ? Icons.check_rounded : Icons.add_rounded, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        isEditing ? "Save Changes" : "Create Building",
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

  void _confirmDeleteBuilding(BuildingModel building) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 10),
            Text(
              "Delete Building",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '${building.name}'? This property will be removed from your building management directory.",
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestoreService.deleteBuilding(building.id);
                _showSnackbar("Building '${building.name}' removed.");
              } catch (e) {
                _showSnackbar("Error deleting building: $e", isSuccess: false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Delete",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
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

  // ---------------------------------------------------------------------------
  // Top Executive Metrics Summary Widget
  // ---------------------------------------------------------------------------
  Widget _buildExecutiveSummaryBanner(List<BuildingModel> buildings) {
    final totalBuildings = buildings.length;
    final totalCapacity = buildings.fold<int>(0, (sum, b) => sum + b.totalCapacity);
    final totalOccupied = buildings.fold<int>(0, (sum, b) => sum + b.occupiedCount);
    final totalVacant = (totalCapacity - totalOccupied).clamp(0, totalCapacity);
    final overallRate = totalCapacity > 0 ? ((totalOccupied / totalCapacity) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: Color(0xFF0D52CE), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Overall Portfolio Occupancy",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.domain_rounded, size: 13, color: Color(0xFF0D52CE)),
                    const SizedBox(width: 4),
                    Text(
                      "$totalBuildings Properties",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D52CE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Big Ratio & Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          text: "$totalOccupied",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                          children: [
                            TextSpan(
                              text: " / $totalCapacity Beds Occupied",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$totalVacant Vacant Beds available across all campuses",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getOccupancyColor(totalCapacity > 0 ? (totalOccupied / totalCapacity) : 0.0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$overallRate% Full",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Large Visual Occupancy Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: totalCapacity > 0 ? (totalOccupied / totalCapacity).clamp(0.0, 1.0) : 0.0,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getOccupancyColor(totalCapacity > 0 ? (totalOccupied / totalCapacity) : 0.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Individual Building Card Widget
  // ---------------------------------------------------------------------------
  Widget _buildBuildingCard(BuildingModel building, {bool isGrid = false}) {
    final occupancyColor = _getOccupancyColor(building.occupancyRate);
    final hasAsset = building.imageAsset.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BuildingSpaceScreen(
                  building: building,
                  currentUser: widget.currentUser,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Property Photo with overlay tag
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      height: isGrid ? 130 : 180,
                      width: double.infinity,
                      child: building.hasRemoteImage
                          ? Image.network(
                              building.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _fallbackImage(building),
                            )
                          : hasAsset
                              ? Image.asset(
                                  building.imageAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _fallbackImage(building),
                                )
                              : _fallbackImage(building),
                    ),
                  ),
                  // Subtle top gradient for badge readability
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Occupancy badge (top-right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: occupancyColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "${building.occupancyPercentage}% Full",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Card Content: Name, Occupancy Visual Bar, Tap Prompt
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Options Menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            building.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 22),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'space',
                              child: Row(
                                children: [
                                  const Icon(Icons.meeting_room_rounded, size: 18, color: Color(0xFF0D52CE)),
                                  const SizedBox(width: 10),
                                  Text("Open Building Space", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0D52CE)),
                                  const SizedBox(width: 10),
                                  Text("Edit Building", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                  const SizedBox(width: 10),
                                  Text("Delete", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (val) {
                            if (val == 'space') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BuildingSpaceScreen(
                                    building: building,
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                            } else if (val == 'edit') {
                              _openBuildingEditorModal(existing: building);
                            } else if (val == 'delete') {
                              _confirmDeleteBuilding(building);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Occupancy Visual Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
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
                                    const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF0D52CE)),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "${building.occupiedCount} / ${building.totalCapacity} Students",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${building.availableBeds} Available",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: building.availableBeds > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),

                          // Visual progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              height: 10,
                              child: LinearProgressIndicator(
                                value: building.occupancyRate,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(occupancyColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Navigation Hint to Building Space
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "View Building Space",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D52CE),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Color(0xFF0D52CE),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackImage(BuildingModel building) {
    return Container(
      color: const Color(0xFFCBD5E1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apartment_rounded, size: 40, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              building.name,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Screen Build
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
        drawer: AdminDrawer(activeItem: "Building", currentUser: widget.currentUser),
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
                "Building Management",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                "Occupancy & Residency Overview",
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
              tooltip: _isGridView ? "List View" : "Grid View",
              icon: Icon(
                _isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                color: const Color(0xFF475569),
                size: 22,
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
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
        onPressed: () => _openBuildingEditorModal(),
        backgroundColor: const Color(0xFF0D52CE),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_business_rounded, size: 20),
        label: Text(
          "Add Building",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<StudentProfile>>(
          stream: _firestoreService.getStudentsStream(),
          builder: (context, studentSnapshot) {
            final allStudents = studentSnapshot.data ?? [];

            return StreamBuilder<List<BuildingModel>>(
              stream: _firestoreService.getBuildingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0D52CE)),
                  );
                }

                final rawBuildings = snapshot.data ?? BuildingModel.defaultBuildings;
                // Live count calculation for each building from the student directory database!
                final allBuildings = rawBuildings.map((b) {
                  final count = _countStudentsForBuilding(b.name, allStudents);
                  return b.copyWith(occupiedCount: count);
                }).toList();
                final filteredBuildings = _filterBuildings(allBuildings);

                return RefreshIndicator(
                  color: const Color(0xFF0D52CE),
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Executive Summary Metric Banner
                        _buildExecutiveSummaryBanner(allBuildings),
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
                              hintText: "Search buildings, campus, location, warden...",
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
                        const SizedBox(height: 18),

                        // 3. Section Header & Count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Hostel Buildings (${filteredBuildings.length})",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Text(
                                  "Clear search",
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

                        // 4. Buildings List or Grid
                        if (filteredBuildings.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.apartment_rounded, size: 48, color: Color(0xFFCBD5E1)),
                                const SizedBox(height: 12),
                                Text(
                                  "No buildings match your criteria",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Try adjusting search terms.",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_isGridView)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredBuildings.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.68,
                            ),
                            itemBuilder: (context, idx) => _buildBuildingCard(filteredBuildings[idx], isGrid: true),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredBuildings.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 16),
                            itemBuilder: (context, idx) => _buildBuildingCard(filteredBuildings[idx]),
                          ),

                        const SizedBox(height: 80), // bottom clearance for FAB
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );
}
}
