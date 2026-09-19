import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/admin_drawer.dart';
import '../../models/student_profile_model.dart';
import '../../models/user_role_model.dart';
import '../../services/firestore_service.dart';
import '../../services/email_service.dart';
import '../student_onboarding_screen.dart';
import 'student_profile_detail_screen.dart';
import 'dashboard_screen.dart';
import '../../widgets/app_toast.dart';

class StudentsDirectoryScreen extends StatefulWidget {
  final AppUser? currentUser;
  final String? initialBuilding;

  const StudentsDirectoryScreen({
    super.key,
    this.currentUser,
    this.initialBuilding,
  });

  @override
  State<StudentsDirectoryScreen> createState() => _StudentsDirectoryScreenState();
}

class _StudentsDirectoryScreenState extends State<StudentsDirectoryScreen> {
  String _selectedBuilding = "All Buildings";
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialBuilding != null && widget.initialBuilding!.isNotEmpty) {
      // Find matching item or set directly
      for (final b in _buildings) {
        if (b.toLowerCase().contains(widget.initialBuilding!.toLowerCase()) ||
            widget.initialBuilding!.toLowerCase().contains(b.toLowerCase())) {
          _selectedBuilding = b;
          break;
        }
      }
    }
  }

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

  List<StudentProfile> _filterStudents(List<StudentProfile> students) {
    return students.where((student) {
      // Building Filter
      if (_selectedBuilding != "All Buildings") {
        final bSearch = _selectedBuilding.toLowerCase().replaceAll(" residency", "").replaceAll(" homes", "");
        final sBuilding = student.building.toLowerCase();
        if (!sBuilding.contains(bSearch)) {
          return false;
        }
      }

      // Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = student.fullName.toLowerCase().contains(query);
        final matchesRoom = student.room.toLowerCase().contains(query);
        final matchesPhone = student.phone.toLowerCase().contains(query);
        final matchesEmail = student.email.toLowerCase().contains(query);
        final matchesReg = student.registrationNumber.toLowerCase().contains(query);
        return matchesName || matchesRoom || matchesPhone || matchesEmail || matchesReg;
      }

      return true;
    }).toList();
  }

  void _showSnackbar(String msg, {bool isSuccess = true}) {
    AppToast.show(context, msg, isSuccess: isSuccess);
  }

  void _openSendBillBottomSheet(StudentProfile student) {
    final amountController = TextEditingController(
      text: student.monthlyRent.replaceAll(',', '').trim().isNotEmpty
          ? student.monthlyRent.replaceAll(',', '').trim()
          : "12500",
    );
    final noteController = TextEditingController(text: "Hostel Rent");
    String billType = "Hostel Rent";
    bool isSending = false;

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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF003896)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Issue Bill / Invoice",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "To: ${student.fullName} (${student.room})",
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

                  // Bill Type selector
                  Text(
                    "Bill Category",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: billType,
                        isExpanded: true,
                        items: ["Hostel Rent", "Security Deposit", "Electricity", "Mess Fee", "Maintenance Fee", "WiFi Subscription"].map((t) {
                          return DropdownMenuItem(value: t, child: Text(t));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => billType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

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
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Bill Description / Month",
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
                      hintText: "e.g. October Rent & Mess",
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isSending
                          ? null
                          : () async {
                              final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                              if (amt <= 0) {
                                _showSnackbar("Please enter a valid amount", isSuccess: false);
                                return;
                              }
                              setModalState(() => isSending = true);
                              final billName = noteController.text.trim().isNotEmpty
                                  ? noteController.text.trim()
                                  : billType;
                              final billId = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                              final dueDate = DateTime.now().add(const Duration(days: 7));
                              final isHostel = billType.toLowerCase().contains("deposit") ||
                                  billType.toLowerCase().contains("rent") ||
                                  billType.toLowerCase().contains("installment");
                              final category = isHostel ? "Hostel rent/security deposit" : "Utility bill";

                              setModalState(() => isSending = true);
                              try {
                                await FirestoreService().issueBill({
                                  'studentId': student.id,
                                  'studentDocId': student.id,
                                  'studentUid': student.studentId.isNotEmpty ? student.studentId : student.id,
                                  'userId': student.studentId.isNotEmpty ? student.studentId : student.id,
                                  'studentName': student.fullName,
                                  'phone': student.phone,
                                  'studentPhone': student.phone,
                                  'building': student.building,
                                  'room': student.room,
                                  'bed': student.bedNumber,
                                  'bedNumber': student.bedNumber,
                                  'regNo': student.registrationNumber,
                                  'registrationNumber': student.registrationNumber,
                                  'billType': billType,
                                  'billCategory': category,
                                  'billingMonth': billName,
                                  'amount': amt,
                                  'paidAmount': 0.0,
                                  'dueDate': Timestamp.fromDate(dueDate),
                                  'status': 'Pending',
                                  'paymentStatus': 'Unpaid',
                                  'invoiceNo': billId,
                                  'avatarUrl': student.photoUrl ?? '',
                                  'studentEmail': student.email,
                                  'email': student.email,
                                });

                                // Dispatch student notification
                                await FirestoreService().sendStudentNotification(
                                  studentId: student.id,
                                  studentUid: student.studentId.isNotEmpty ? student.studentId : student.id,
                                  regNo: student.registrationNumber,
                                  studentName: student.fullName,
                                  title: "New Bill: $billName (₹${amt.toStringAsFixed(0)})",
                                  message:
                                      "A new $category for $billName (₹${amt.toStringAsFixed(0)}) has been issued for your Room ${student.room} (${student.building}). Due date: ${dueDate.day}/${dueDate.month}/${dueDate.year}.",
                                  category: "Payment",
                                  targetBuilding: student.building,
                                  targetRoom: student.room,
                                  metadata: {
                                    'invoiceNo': billId,
                                    'amount': amt,
                                    'dueDate': dueDate.toIso8601String(),
                                    'billCategory': category,
                                    'billName': billName,
                                  },
                                );

                                // Dispatch email if available
                                if (student.email.isNotEmpty) {
                                  EmailService().sendBillInvoiceEmail(
                                    studentEmail: student.email,
                                    studentName: student.fullName,
                                    billName: billName,
                                    billCategory: category,
                                    amount: amt,
                                    dueDate: dueDate,
                                    invoiceNo: billId,
                                    building: student.building,
                                    room: student.room,
                                  );
                                }

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _showSnackbar("Invoice of ₹${amt.toStringAsFixed(0)} issued for ${student.fullName}!");
                                }
                              } catch (e) {
                                setModalState(() => isSending = false);
                                _showSnackbar("Error issuing bill: $e", isSuccess: false);
                              }
                            },
                      icon: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        "Generate & Issue Invoice",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003896),
                        foregroundColor: Colors.white,
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
      },
    );
  }


  void _openStudentProfileScreen(StudentProfile student, {int initialSectionIndex = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentProfileDetailScreen(
          student: student,
          currentUser: widget.currentUser,
          initialSectionIndex: initialSectionIndex,
        ),
      ),
    );
  }


  Widget _buildStudentCard(StudentProfile student) {
    final initials = student.firstName.isNotEmpty && student.fullName.split(' ').length > 1
        ? "${student.fullName.split(' ')[0][0]}${student.fullName.split(' ')[1][0]}".toUpperCase()
        : (student.fullName.isNotEmpty ? student.fullName.substring(0, 1).toUpperCase() : "ST");

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
        onTap: () => _openStudentProfileScreen(student, initialSectionIndex: 0),
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
                    backgroundColor: const Color(0xFF003896),
                    backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty
                        ? NetworkImage(student.photoUrl!)
                        : null,
                    child: student.photoUrl == null || student.photoUrl!.isEmpty
                        ? Text(
                            initials,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
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
                                student.fullName.isNotEmpty ? student.fullName : "Student",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                student.status,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
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
                    onTap: () => _openStudentProfileScreen(student, initialSectionIndex: 1),
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
                            "${student.notes.length} notes",
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
                      // Only Super Admin can issue bills directly from Directory
                      if (widget.currentUser?.canManagePayments ?? true) ...[
                        OutlinedButton.icon(
                          onPressed: () => _openSendBillBottomSheet(student),
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 15,
                            color: Color(0xFF003896),
                          ),
                          label: Text(
                            "Send Bill",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF003896),
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
                      ],
                      ElevatedButton.icon(
                        onPressed: () => _openStudentProfileScreen(student, initialSectionIndex: 0),
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          "Profile",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003896),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
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
        drawer: AdminDrawer(activeItem: "Students Directory", currentUser: widget.currentUser),
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
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search name, room, phone, reg no...",
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
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF003896)),
              tooltip: "Onboard Student",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentOnboardingScreen()),
                );
              },
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
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls Bar (Building Selector)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
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
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF003896)),
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
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Student List via real-time Firestore stream
            Expanded(
              child: StreamBuilder<List<StudentProfile>>(
                stream: FirestoreService().getStudentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF003896)),
                    );
                  }

                  final allStudents = snapshot.data ?? [];
                  final filtered = _filterStudents(allStudents);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEF2FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.people_outline_rounded, size: 44, color: Color(0xFF003896)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            allStudents.isEmpty ? "No students enrolled yet" : "No matching students found",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            allStudents.isEmpty
                                ? "Onboard your first real resident to get started."
                                : "Try clearing search query or changing building filter.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          if (allStudents.isEmpty) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const StudentOnboardingScreen()),
                                );
                              },
                              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                              label: Text(
                                "Onboard Student Now",
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003896),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildStudentCard(filtered[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentOnboardingScreen()),
          );
        },
        backgroundColor: const Color(0xFF003896),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          "Onboard Student",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
}
