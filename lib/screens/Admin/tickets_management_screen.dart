import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/complaint_model.dart';
import '../../models/user_role_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_drawer.dart';
import 'dashboard_screen.dart';
import '../../widgets/app_toast.dart';

class TicketsManagementScreen extends StatefulWidget {
  final AppUser? currentUser;
  final String? initialFilter; // "All", "Received", "Under execution", "Resolved"

  const TicketsManagementScreen({
    super.key,
    this.currentUser,
    this.initialFilter,
  });

  @override
  State<TicketsManagementScreen> createState() => _TicketsManagementScreenState();
}

class _TicketsManagementScreenState extends State<TicketsManagementScreen> {
  late String _selectedStatusFilter;
  String _selectedBuilding = "All Buildings";
  String _searchQuery = "";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = [
    "All",
    ComplaintModel.statusReceived,
    ComplaintModel.statusUnderExecution,
    ComplaintModel.statusResolved,
  ];

  final List<String> _buildings = [
    "All Buildings",
    "Lakshya",
    "Shivalya",
    "Ishaan",
    "Univ homes",
    "Tirupati",
    "Rameshwaram",
    "Livano",
    "Somnath",
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatusFilter = widget.initialFilter ?? "All";
    if (!_statusFilters.contains(_selectedStatusFilter)) {
      _selectedStatusFilter = "All";
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStatusUpdateDialog(ComplaintModel ticket) {
    String currentStatus = ticket.status;
    final remarksController = TextEditingController(text: ticket.adminRemarks ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Update Ticket Status",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${ticket.studentName} • ${ticket.building} - ${ticket.room}",
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
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status Selection Header
                    Text(
                      "Select New Status",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Three Options: Received, Under execution, Resolved
                    Column(
                      children: ComplaintModel.validStatuses.map((statusOption) {
                        final isSelected = currentStatus == statusOption;
                        final color = _getStatusColor(statusOption);
                        final icon = _getStatusIcon(statusOption);

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              currentStatus = statusOption;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? color : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 18),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        statusOption,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? color : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _getStatusDescription(statusOption),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: color, size: 22)
                                else
                                  const Icon(Icons.circle_outlined, color: Color(0xFFCBD5E1), size: 22),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    // Admin Remarks
                    Text(
                      "Admin Remarks / Action Taken (Optional)",
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
                        hintText: "e.g. Electrician scheduled for 3 PM, Water pipe replaced, etc.",
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.all(14),
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                    ),

                    const SizedBox(height: 22),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting ? null : () => Navigator.pop(modalContext),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setModalState(() {
                                      isSubmitting = true;
                                    });

                                    try {
                                      await FirestoreService().updateComplaintStatus(
                                        complaintId: ticket.id,
                                        status: currentStatus,
                                        remarks: remarksController.text.trim(),
                                        complaint: ticket,
                                      );

                                      if (modalContext.mounted) {
                                        Navigator.pop(modalContext);
                                      }
                                      if (!mounted) return;
                                      final isNotified = currentStatus == ComplaintModel.statusUnderExecution ||
                                          currentStatus == ComplaintModel.statusResolved;
                                      AppToast.show(
                                        context,
                                        isNotified
                                            ? "Ticket updated to \"$currentStatus\" • Notification sent to resident!"
                                            : "Ticket updated to \"$currentStatus\"",
                                        isSuccess: true,
                                      );
                                    } catch (e) {
                                      setModalState(() {
                                        isSubmitting = false;
                                      });
                                      if (!mounted) return;
                                      AppToast.showError(context, "Error updating status: $e");
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D52CE),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    "Save Changes",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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

  String _getStatusDescription(String status) {
    switch (status) {
      case ComplaintModel.statusReceived:
        return "Received by default when student raises ticket";
      case ComplaintModel.statusUnderExecution:
        return "Sends notification to student & assigns maintenance";
      case ComplaintModel.statusResolved:
        return "Marks complete & sends resolution notification to student";
      default:
        return "";
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case ComplaintModel.statusReceived:
        return const Color(0xFF2563EB); // Blue
      case ComplaintModel.statusUnderExecution:
        return const Color(0xFFF59E0B); // Amber / Orange
      case ComplaintModel.statusResolved:
        return const Color(0xFF10B981); // Emerald / Green
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case ComplaintModel.statusReceived:
        return const Color(0xFFEFF6FF);
      case ComplaintModel.statusUnderExecution:
        return const Color(0xFFFFFBEB);
      case ComplaintModel.statusResolved:
        return const Color(0xFFECFDF5);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case ComplaintModel.statusReceived:
        return Icons.inbox_rounded;
      case ComplaintModel.statusUnderExecution:
        return Icons.engineering_rounded;
      case ComplaintModel.statusResolved:
        return Icons.check_circle_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains("wifi") || cat.contains("internet")) return Icons.wifi_rounded;
    if (cat.contains("clean") || cat.contains("housekeep")) return Icons.cleaning_services_rounded;
    if (cat.contains("electric")) return Icons.electrical_services_rounded;
    if (cat.contains("plumb") || cat.contains("water")) return Icons.water_drop_rounded;
    if (cat.contains("carpent") || cat.contains("door") || cat.contains("furnitur")) return Icons.handyman_rounded;
    return Icons.build_rounded;
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains("wifi") || cat.contains("internet")) return const Color(0xFF8B5CF6);
    if (cat.contains("clean") || cat.contains("housekeep")) return const Color(0xFF10B981);
    if (cat.contains("electric")) return const Color(0xFFF59E0B);
    if (cat.contains("plumb") || cat.contains("water")) return const Color(0xFF0284C7);
    return const Color(0xFF3B82F6);
  }

  String _formatDate(DateTime dt) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? "PM" : "AM";
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minuteStr $period";
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
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: AdminDrawer(activeItem: "Ticket Management", currentUser: widget.currentUser),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
            tooltip: "Back to Dashboard",
            onPressed: _handleBackToDashboard,
          ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search tickets, resident, room...",
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF0F172A)),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ticket Management",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    "Lakshya Resident Support Portal",
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
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: const Color(0xFF475569)),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = "";
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          // Building Selector Filter
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF475569)),
            tooltip: "Filter by Property",
            onSelected: (val) {
              setState(() {
                _selectedBuilding = val;
              });
            },
            itemBuilder: (context) {
              return _buildings.map((b) {
                return PopupMenuItem<String>(
                  value: b,
                  child: Row(
                    children: [
                      if (_selectedBuilding == b)
                        const Icon(Icons.check_rounded, color: Color(0xFF0D52CE), size: 16)
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Text(
                        b,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: _selectedBuilding == b ? FontWeight.bold : FontWeight.w500,
                          color: _selectedBuilding == b ? const Color(0xFF0D52CE) : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          Builder(
            builder: (drawerCtx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF475569)),
              tooltip: "Open Menu",
              onPressed: () => Scaffold.of(drawerCtx).openDrawer(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: FirestoreService().getComplaintsStream(
          buildingFilter: _selectedBuilding == "All Buildings" ? null : _selectedBuilding,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D52CE)),
            );
          }

          final allTickets = snapshot.data ?? [];

          // Calculate counters
          final totalCount = allTickets.length;
          final receivedCount = allTickets.where((t) => t.isReceived).length;
          final underExecutionCount = allTickets.where((t) => t.isUnderExecution).length;
          final resolvedCount = allTickets.where((t) => t.isResolved).length;

          // Apply Status Filter
          var filtered = allTickets;
          if (_selectedStatusFilter != "All") {
            filtered = filtered.where((t) => t.status == _selectedStatusFilter).toList();
          }

          // Apply Search Query Filter
          if (_searchQuery.isNotEmpty) {
            filtered = filtered.where((t) {
              final q = _searchQuery;
              return t.title.toLowerCase().contains(q) ||
                  t.description.toLowerCase().contains(q) ||
                  t.studentName.toLowerCase().contains(q) ||
                  t.room.toLowerCase().contains(q) ||
                  t.category.toLowerCase().contains(q) ||
                  t.building.toLowerCase().contains(q);
            }).toList();
          }

          return Column(
            children: [
              // Top Metric Cards / Status Counter
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    if (_selectedBuilding != "All Buildings")
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.apartment_rounded, size: 14, color: Color(0xFF0D52CE)),
                            const SizedBox(width: 6),
                            Text(
                              "Filtered for: $_selectedBuilding",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D52CE),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() => _selectedBuilding = "All Buildings"),
                              child: Text(
                                "Clear",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Metrics Strip
                    Row(
                      children: [
                        _buildMetricPill("All", totalCount, const Color(0xFF475569)),
                        const SizedBox(width: 8),
                        _buildMetricPill(ComplaintModel.statusReceived, receivedCount, const Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        _buildMetricPill(ComplaintModel.statusUnderExecution, underExecutionCount, const Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        _buildMetricPill(ComplaintModel.statusResolved, resolvedCount, const Color(0xFF10B981)),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Status Filter Tabs
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((filter) {
                      final isSelected = _selectedStatusFilter == filter;
                      int badgeCount = totalCount;
                      Color activeColor = const Color(0xFF0D52CE);

                      if (filter == ComplaintModel.statusReceived) {
                        badgeCount = receivedCount;
                        activeColor = const Color(0xFF2563EB);
                      } else if (filter == ComplaintModel.statusUnderExecution) {
                        badgeCount = underExecutionCount;
                        activeColor = const Color(0xFFF59E0B);
                      } else if (filter == ComplaintModel.statusResolved) {
                        badgeCount = resolvedCount;
                        activeColor = const Color(0xFF10B981);
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStatusFilter = filter;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? activeColor : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? activeColor : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                filter,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFCBD5E1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "$badgeCount",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Main List View
              Expanded(
                child: filtered.isEmpty ? _buildEmptyState() : _buildTicketsList(filtered),
              ),
            ],
          );
        },
      ),
    ),
  );
}

  Widget _buildMetricPill(String title, int count, Color color) {
    final isSelected = _selectedStatusFilter == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatusFilter = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                "$count",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title == ComplaintModel.statusUnderExecution ? "Execution" : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 54,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty ? "No tickets match search" : "No tickets found",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? "Try searching with a different resident name, room or keyword."
                  : _selectedStatusFilter != "All"
                      ? "There are currently no tickets marked as \"$_selectedStatusFilter\"."
                      : "When students raise tickets from their Lakshya app, they will appear here in real time.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            if (_selectedStatusFilter != "All" || _searchQuery.isNotEmpty || _selectedBuilding != "All Buildings") ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedStatusFilter = "All";
                    _selectedBuilding = "All Buildings";
                    _searchQuery = "";
                    _searchController.clear();
                    _isSearching = false;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("Reset Filters"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D52CE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList(List<ComplaintModel> tickets) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final statusColor = _getStatusColor(ticket.status);
        final statusBg = _getStatusBgColor(ticket.status);
        final statusIcon = _getStatusIcon(ticket.status);
        final catColor = _getCategoryColor(ticket.category);
        final catIcon = _getCategoryIcon(ticket.category);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
              // Header Row: Category Badge, Date, Status Chip
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Category Chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(catIcon, size: 14, color: catColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      ticket.category,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: catColor,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Priority Badge
                              if (ticket.priority == "High" || ticket.priority == "Emergency")
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.priority_high_rounded, size: 12, color: Color(0xFFEF4444)),
                                      const SizedBox(width: 2),
                                      Text(
                                        ticket.priority,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFFEF4444),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Badge with clickable interaction
                        InkWell(
                          onTap: () => _showStatusUpdateDialog(ticket),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  ticket.status,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: statusColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: statusColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Ticket Title
                    Text(
                      ticket.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Description
                    if (ticket.description.isNotEmpty)
                      Text(
                        ticket.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Student & Room Details Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF0D52CE).withValues(alpha: 0.12),
                            child: Text(
                              ticket.studentName.isNotEmpty ? ticket.studentName.substring(0, 1).toUpperCase() : "R",
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF0D52CE),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.studentName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  "${ticket.building} • ${ticket.room.isNotEmpty ? ticket.room : 'Resident'}",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (ticket.studentPhone.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                              tooltip: "Copy Phone (${ticket.studentPhone})",
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: ticket.studentPhone));
                                AppToast.showSuccess(context, "Copied phone: ${ticket.studentPhone}");
                              },
                            ),
                        ],
                      ),
                    ),

                    // Admin Remarks if present
                    if (ticket.adminRemarks != null && ticket.adminRemarks!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.comment_outlined, size: 14, color: Color(0xFF1D4ED8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Admin Note: ${ticket.adminRemarks!}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Date row
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          "Raised on ${_formatDate(ticket.createdAt)}",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Quick Action Bar
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      "Mark Status:",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Quick Action Buttons for the three statuses
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickStatusBtn(
                              ticket: ticket,
                              targetStatus: ComplaintModel.statusReceived,
                              label: "Received",
                              color: const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 6),
                            _buildQuickStatusBtn(
                              ticket: ticket,
                              targetStatus: ComplaintModel.statusUnderExecution,
                              label: "Under execution",
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 6),
                            _buildQuickStatusBtn(
                              ticket: ticket,
                              targetStatus: ComplaintModel.statusResolved,
                              label: "Resolved",
                              color: const Color(0xFF10B981),
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
  }

  Widget _buildQuickStatusBtn({
    required ComplaintModel ticket,
    required String targetStatus,
    required String label,
    required Color color,
  }) {
    final isCurrent = ticket.status == targetStatus;

    return InkWell(
      onTap: isCurrent
          ? null
          : () async {
              try {
                await FirestoreService().updateComplaintStatus(
                  complaintId: ticket.id,
                  status: targetStatus,
                  complaint: ticket,
                );
                if (mounted) {
                  final isNotified = targetStatus == ComplaintModel.statusUnderExecution ||
                      targetStatus == ComplaintModel.statusResolved;
                  AppToast.show(
                    context,
                    isNotified
                        ? "Ticket marked as \"$targetStatus\" • Notification sent to resident!"
                        : "Ticket marked as \"$targetStatus\"",
                    isSuccess: true,
                  );
                }
              } catch (e) {
                if (mounted) {
                  AppToast.showError(context, "Error: $e");
                }
              }
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent ? color : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrent) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 13),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isCurrent ? Colors.white : const Color(0xFF334155),
                fontSize: 11.5,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
