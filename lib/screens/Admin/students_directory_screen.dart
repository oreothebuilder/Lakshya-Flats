import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/admin_drawer.dart';

class StudentDirectoryItem {
  final String id;
  final String name;
  final String initials;
  final String status; // 'Upcoming', 'Paid', 'Defaulters'
  final String building;
  final String room;
  final String phone;
  final String email;
  final List<String> notes;
  final double pendingAmount;

  StudentDirectoryItem({
    required this.id,
    required this.name,
    required this.initials,
    required this.status,
    required this.building,
    required this.room,
    required this.phone,
    required this.email,
    required this.notes,
    required this.pendingAmount,
  });
}

class StudentsDirectoryScreen extends StatefulWidget {
  const StudentsDirectoryScreen({super.key});

  @override
  State<StudentsDirectoryScreen> createState() => _StudentsDirectoryScreenState();
}

class _StudentsDirectoryScreenState extends State<StudentsDirectoryScreen> {
  String _selectedBuilding = "All Buildings";
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<String> _buildings = [
    "All Buildings",
    "Lakshya Residency",
    "Univ Homes",
    "Green Villa",
  ];

  // Dummy list of students structured as per requirements
  final List<StudentDirectoryItem> _allStudents = [
    StudentDirectoryItem(
      id: "STU-001",
      name: "Sudhanshu",
      initials: "SU",
      status: "Upcoming",
      building: "Lakshya",
      room: "Room 304 (Bed A)",
      phone: "+91 8208285947",
      email: "sudhansu1906@gmail.com",
      notes: ["1 shared note regarding monthly mess pass extension."],
      pendingAmount: 3500.0,
    ),
    StudentDirectoryItem(
      id: "STU-002",
      name: "Aarav Kumar",
      initials: "AK",
      status: "Paid",
      building: "Lakshya",
      room: "Room 102 (Bed B)",
      phone: "+91 9876543210",
      email: "aarav.k@gmail.com",
      notes: [
        "Fee clearance slip verified for Q3.",
        "Requested extra chair."
      ],
      pendingAmount: 0.0,
    ),
    StudentDirectoryItem(
      id: "STU-003",
      name: "Rohan Mehta",
      initials: "RM",
      status: "Defaulter",
      building: "Univ Homes",
      room: "Room 205 (Bed A)",
      phone: "+91 9123456789",
      email: "rohan.mehta@yahoo.com",
      notes: [],
      pendingAmount: 7200.0,
    ),
    StudentDirectoryItem(
      id: "STU-004",
      name: "Priya Sharma",
      initials: "PS",
      status: "Upcoming",
      building: "Univ Homes",
      room: "Room 104 (Bed C)",
      phone: "+91 9988776655",
      email: "priya.s@outlook.com",
      notes: [
        "Parent call requested for weekend pass.",
        "AC repair request logged."
      ],
      pendingAmount: 4200.0,
    ),
    StudentDirectoryItem(
      id: "STU-005",
      name: "Vikas Singh",
      initials: "VS",
      status: "Paid",
      building: "Green Villa",
      room: "Room 301 (Bed A)",
      phone: "+91 9555443322",
      email: "vikas.singh@gmail.com",
      notes: ["Annual security deposit cleared."],
      pendingAmount: 0.0,
    ),
    StudentDirectoryItem(
      id: "STU-006",
      name: "Ananya Patel",
      initials: "AP",
      status: "Defaulter",
      building: "Green Villa",
      room: "Room 202 (Bed B)",
      phone: "+91 9777888999",
      email: "ananya.p@gmail.com",
      notes: ["Reminder sent twice on WhatsApp."],
      pendingAmount: 8500.0,
    ),
  ];

  List<StudentDirectoryItem> get _filteredStudents {
    return _allStudents.where((student) {
      // Building Filter
      if (_selectedBuilding != "All Buildings") {
        if (!student.building.toLowerCase().contains(_selectedBuilding.toLowerCase().replaceAll(" residency", ""))) {
          return false;
        }
      }

      // Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = student.name.toLowerCase().contains(query);
        final matchesRoom = student.room.toLowerCase().contains(query);
        final matchesPhone = student.phone.toLowerCase().contains(query);
        final matchesEmail = student.email.toLowerCase().contains(query);
        return matchesName || matchesRoom || matchesPhone || matchesEmail;
      }

      return true;
    }).toList();
  }

  void _openSendBillBottomSheet(StudentDirectoryItem student) {
    final amountController = TextEditingController(text: student.pendingAmount > 0 ? "${student.pendingAmount.toInt()}" : "4500");
    final noteController = TextEditingController(text: "Monthly Rent & Mess Charges for August");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0D52CE)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Send Bill / Invoice",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "To: ${student.name} (${student.room})",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Bill Amount (₹)",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  hintText: "Enter amount",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Bill Description",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: "Enter bill details",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Invoice of ₹${amountController.text} sent to ${student.name} via SMS & Email!",
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        backgroundColor: const Color(0xFF0D52CE),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    "Send Invoice Bill Now",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D52CE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openNotesBottomSheet(StudentDirectoryItem student) {
    final noteInputController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded, color: Color(0xFF0D52CE)),
                      const SizedBox(width: 10),
                      Text(
                        "Shared Notes for ${student.name}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (student.notes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "No notes added yet for this student.",
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
                      ),
                    )
                  else
                    ...student.notes.map((note) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.label_important_outline_rounded, size: 16, color: Color(0xFF0D52CE)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  note,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: noteInputController,
                          decoration: InputDecoration(
                            hintText: "Add a new note...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (noteInputController.text.trim().isNotEmpty) {
                            setState(() {
                              student.notes.add(noteInputController.text.trim());
                            });
                            setModalState(() {});
                            noteInputController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D52CE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.add, size: 20),
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

  void _openProfileBottomSheet(StudentDirectoryItem student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFF0D52CE),
                child: Text(
                  student.initials,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                student.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                "${student.building} • ${student.room}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildProfileDetailRow(Icons.phone_rounded, "Phone", student.phone),
                    const Divider(height: 20),
                    _buildProfileDetailRow(Icons.email_rounded, "Email", student.email),
                    const Divider(height: 20),
                    _buildProfileDetailRow(Icons.badge_rounded, "Student ID", student.id),
                    const Divider(height: 20),
                    _buildProfileDetailRow(
                      Icons.account_balance_wallet_rounded,
                      "Payment Status",
                      student.status,
                      statusColor: _getStatusTextColor(student.status),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    "Close Profile",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: statusColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case "Paid":
        return const Color(0xFFDCFCE7);
      case "Defaulter":
      case "Defaulters":
        return const Color(0xFFFEE2E2);
      case "Upcoming":
      case "Upcoming Dues":
      default:
        return const Color(0xFFE0F2FE);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case "Paid":
        return const Color(0xFF15803D);
      case "Defaulter":
      case "Defaulters":
        return const Color(0xFFB91C1C);
      case "Upcoming":
      case "Upcoming Dues":
      default:
        return const Color(0xFF0369A1);
    }
  }

  Widget _buildStudentCard(StudentDirectoryItem student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openProfileBottomSheet(student),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row (Avatar, Name, Status, Chevron)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF0D52CE),
                    child: Text(
                      student.initials,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                student.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getStatusBgColor(student.status),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                student.status,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _getStatusTextColor(student.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${student.building} • ${student.room}",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${student.phone} • ${student.email}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // Bottom Actions Footer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shared Notes Left Link
                  InkWell(
                    onTap: () => _openNotesBottomSheet(student),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${student.notes.length} shared notes",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons Right (Send Bill & Profile)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _openSendBillBottomSheet(student),
                        icon: const Icon(
                          Icons.receipt_long_outlined,
                          size: 15,
                          color: Color(0xFF0D52CE),
                        ),
                        label: Text(
                          "Send Bill",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D52CE),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _openProfileBottomSheet(student),
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          size: 17,
                          color: Color(0xFF475569),
                        ),
                        label: Text(
                          "Profile",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminDrawer(activeItem: "Students Directory"),
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search name, room, phone...",
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[500]),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 15),
              )
            : Text(
                "Students Directory",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: const Color(0xFF0F172A)),
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
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls Bar (Building Selector & Status Chips)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // Row 1: Building Selector Dropdown
                  Row(
                    children: [
                      Text(
                        "Building:",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedBuilding,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D52CE)),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              items: _buildings.map((b) {
                                return DropdownMenuItem<String>(
                                  value: b,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.domain_rounded, size: 18, color: Color(0xFF64748B)),
                                      const SizedBox(width: 8),
                                      Text(b),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newVal) {
                                if (newVal != null) {
                                  setState(() {
                                    _selectedBuilding = newVal;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Student List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 54, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            "No students found",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Try clearing search or changing filters.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildStudentCard(filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
