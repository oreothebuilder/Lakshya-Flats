import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/student_profile_model.dart';
import '../../models/user_role_model.dart';
import '../../models/bill_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import 'broadcast_notification_screen.dart';
import 'dashboard_screen.dart';

class StudentProfileDetailScreen extends StatefulWidget {
  final StudentProfile student;
  final AppUser? currentUser;
  final int initialSectionIndex;

  const StudentProfileDetailScreen({
    super.key,
    required this.student,
    this.currentUser,
    this.initialSectionIndex = 0,
  });

  @override
  State<StudentProfileDetailScreen> createState() => _StudentProfileDetailScreenState();
}

class _StudentProfileDetailScreenState extends State<StudentProfileDetailScreen> {
  late StudentProfile _student;
  late int _activeSection; // 0 = Fees, 1 = Notes, 2 = Amenities, 3 = Emergency, 4 = Documents

  final TextEditingController _noteInputController = TextEditingController();
  final ScrollController _notesScrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _isSendingNote = false;
  bool _isUploadingDoc = false;

  static const Color primaryBlue = Color(0xFF003896);
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color bgSurface = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _activeSection = widget.initialSectionIndex;
    FirestoreService().purgeDummyBills();
  }

  @override
  void dispose() {
    _noteInputController.dispose();
    _notesScrollController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isSuccess ? primaryBlue : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}";
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? "PM" : "AM";
    final minute = dt.minute.toString().padLeft(2, '0');
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $period";
  }

  // ===========================================================================
  // TOP PROFILE HEADER
  // ===========================================================================

  Widget _buildTopHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Profile photo, Name, Status Badge, Edit Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _openImageFullscreen(
                  _student.photoUrl ?? '',
                  title: "${_student.fullName} - Photo",
                ),
                child: Hero(
                  tag: "student_photo_${_student.id}",
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xFFE8F0FE),
                    backgroundImage: _student.photoUrl != null && _student.photoUrl!.isNotEmpty
                        ? NetworkImage(_student.photoUrl!)
                        : null,
                    child: _student.photoUrl == null || _student.photoUrl!.isEmpty
                        ? Text(
                            _student.initials,
                            style: GoogleFonts.plusJakartaSans(
                              color: primaryBlue,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _student.fullName.isNotEmpty ? _student.fullName : "Student Resident",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _student.status,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Building and Bed Number Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.domain_rounded, size: 15, color: primaryBlue),
                          const SizedBox(width: 6),
                          Text(
                            _student.building,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          const Text("  •  ", style: TextStyle(color: Color(0xFF93C5FD))),
                          const Icon(Icons.bed_rounded, size: 15, color: primaryBlue),
                          const SizedBox(width: 5),
                          Text(
                            "${_student.displayRoomOnly} (${_student.displayBed})",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: primaryBlue, size: 26),
                tooltip: "Edit Profile Information",
                onPressed: _openEditProfileDialog,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Contact Details & Reg No Row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Phone & Email Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _student.phone));
                          _showSnackbar("Phone number copied: ${_student.phone}");
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 16, color: primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _student.phone.isNotEmpty ? _student.phone : "No Phone",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(height: 20, width: 1, color: const Color(0xFFCBD5E1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _student.email));
                          _showSnackbar("Email copied: ${_student.email}");
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 16, color: primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _student.email.isNotEmpty ? _student.email : "No Email",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18, color: Color(0xFFE2E8F0)),

                // Reg No, Course & Branch Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _student.registrationNumber));
                          _showSnackbar("Registration No. copied: ${_student.registrationNumber}");
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 16, color: textMuted),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "College Reg No",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: textMuted),
                                ),
                                Text(
                                  _student.registrationNumber.isNotEmpty ? _student.registrationNumber : "N/A",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.school_outlined, size: 16, color: textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Course & Branch",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: textMuted),
                                ),
                                Text(
                                  "${_student.course} ${_student.branch}".trim().isNotEmpty
                                      ? "${_student.course} - ${_student.branch}".trim()
                                      : "General",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: primaryDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5 NAVIGATION BUTTONS BELOW HEADER
  // ===========================================================================

  Widget _buildSectionButtonsBar() {
    final buttons = [
      {"icon": Icons.receipt_long_rounded, "label": "Fees Details"},
      {"icon": Icons.notes_rounded, "label": "Notes"},
      {"icon": Icons.chair_rounded, "label": "Amenities"},
      {"icon": Icons.contact_phone_rounded, "label": "Emergency"},
      {"icon": Icons.folder_shared_rounded, "label": "Documents"},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(buttons.length, (index) {
            final isSelected = _activeSection == index;
            final item = buttons[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _activeSection = index;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryBlue : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryBlue.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item["icon"] as IconData,
                        size: 17,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item["label"] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: FEES DETAILS (HOSTEL FEES & UTILITY BILLS)
  // ===========================================================================

  Widget _buildFeesDetailsSection() {
    return StreamBuilder<List<BillModel>>(
      stream: FirestoreService().getStudentBillsStream(_student.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: primaryBlue),
            ),
          );
        }

        List<BillModel> bills = snapshot.data ?? [];

        // Extra defensive filter against INV-DEP-101 or dummy fallback items
        bills = bills.where((b) {
          final inv = b.invoiceNo.toLowerCase().trim();
          final id = b.id.toLowerCase().trim();
          final month = b.billingMonth.toLowerCase().trim();
          if (inv == 'inv-dep-101' || id.contains('inv-dep-101')) return false;
          if (id.startsWith('fb-')) return false;
          if (inv.startsWith('inv-hst-10') || inv.startsWith('inv-util-30')) return false;
          if (month == 'admission deposit') return false;
          return true;
        }).toList();

        // Section 1: Hostel Fees & Security Deposit
        final hostelBills = bills.where((b) => b.isHostelBillOrSecurityDeposit).toList();

        // Section 2: Utility Bills
        final utilityBills = bills.where((b) => b.isUtilityBill || !b.isHostelBillOrSecurityDeposit).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Action: Issue New Bill Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Fee Records & Billing",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _openIssueBillDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    "Issue Bill",
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // SECTION 1. THE HOSTEL FEES
            _buildFeeCategoryHeader(
              title: "1. The Hostel Fees",
              subtitle: "Hostel rent installments & security deposit",
              icon: Icons.apartment_rounded,
              color: primaryBlue,
            ),
            const SizedBox(height: 10),
            if (hostelBills.isEmpty)
              _buildEmptyFeeCard("No hostel rent or security deposit bills found.")
            else
              ...hostelBills.map((b) => _buildFeeItemCard(b, categoryHeading: "Hostel fees")),

            const SizedBox(height: 24),

            // SECTION 2. THE UTILITY BILL
            _buildFeeCategoryHeader(
              title: "2. The Utility Bill",
              subtitle: "Electricity, mess, cleaning, and maintenance charges",
              icon: Icons.bolt_rounded,
              color: const Color(0xFFD97706),
            ),
            const SizedBox(height: 10),
            if (utilityBills.isEmpty)
              _buildEmptyFeeCard("No utility bills issued yet for this student.")
            else
              ...utilityBills.map((b) => _buildFeeItemCard(b, categoryHeading: "The utility bill")),
            
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildFeeCategoryHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeeCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textMuted),
        ),
      ),
    );
  }

  Widget _buildFeeItemCard(BillModel bill, {required String categoryHeading}) {
    final isPaid = bill.isPaid;
    final isDefaulter = bill.isDefaulter;

    // Remaining time or overdue days calculation
    String dueStatusText;
    Color statusBadgeBg;
    Color statusBadgeText;
    IconData statusIcon;

    if (isPaid) {
      dueStatusText = "Paid";
      statusBadgeBg = const Color(0xFFDCFCE7);
      statusBadgeText = const Color(0xFF15803D);
      statusIcon = Icons.check_circle_rounded;
    } else if (isDefaulter) {
      final days = bill.daysOverdue;
      dueStatusText = days > 0 ? "Defaulter • ${days}d overdue" : "Defaulter";
      statusBadgeBg = const Color(0xFFFEE2E2);
      statusBadgeText = const Color(0xFFDC2626);
      statusIcon = Icons.warning_amber_rounded;
    } else {
      // Days or months remaining
      final now = DateTime.now();
      final diffDays = bill.dueDate.difference(now).inDays;
      if (diffDays <= 0) {
        dueStatusText = "Due Today";
      } else if (diffDays < 30) {
        dueStatusText = "$diffDays d remaining";
      } else {
        final months = (diffDays / 30).round();
        dueStatusText = "$months ${months == 1 ? 'mo' : 'mos'} remaining";
      }
      statusBadgeBg = const Color(0xFFFEF3C7);
      statusBadgeText = const Color(0xFFB45309);
      statusIcon = Icons.schedule_rounded;
    }

    // Determine heading type
    String headingType = categoryHeading;
    if (bill.billType.toLowerCase().contains("deposit")) {
      headingType = "Security deposit";
    } else if (bill.isHostelBillOrSecurityDeposit) {
      headingType = "Hostel fees";
    } else {
      headingType = "The utility bill";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefaulter ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isDefaulter ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Heading Type & Due Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Type (Heading)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      headingType.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF475569),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 4. Defaulter or Remaining Days Badge
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: statusBadgeBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusBadgeText),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dueStatusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: statusBadgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Row 2: 2. Name of the Bill & Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.billingMonth.isNotEmpty
                            ? "${bill.billType} (${bill.billingMonth})"
                            : bill.billType,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 3. Due Date
                      Row(
                        children: [
                          const Icon(Icons.event_outlined, size: 14, color: textMuted),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              "Due Date: ${_formatDate(bill.dueDate)}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDefaulter ? const Color(0xFFDC2626) : textMuted,
                                fontWeight: isDefaulter ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${bill.amount.toStringAsFixed(0)}",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDefaulter ? const Color(0xFFDC2626) : primaryDark,
                      ),
                    ),
                    if (!isPaid && bill.paidAmount > 0)
                      Text(
                        "Balance: ₹${bill.balance.toStringAsFixed(0)}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Row 3: Action Buttons (Download Bill or Send Notification)
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Invoice: ${bill.invoiceNo}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isPaid)
                  // Option to Download Receipt (PAID FEES ONLY)
                  ElevatedButton.icon(
                    onPressed: () => _openReceiptDialog(bill),
                    icon: const Icon(Icons.download_rounded, size: 15),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Download Receipt",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                    ),
                  )
                else
                  // Option to Send Notification (Fee Payment Reminder for unpaid, Urgent Defaulter Warning for defaulters)
                  ElevatedButton.icon(
                    onPressed: () => _navigateToBroadcastForBill(bill),
                    icon: const Icon(Icons.campaign_rounded, size: 15),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Send Notification",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDefaulter ? const Color(0xFFDC2626) : primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                    ),
                  ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _confirmDeleteBill(bill),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFDC2626)),
                  tooltip: "Delete Bill",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  splashRadius: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Confirmation dialog to permanently delete a bill
  void _confirmDeleteBill(BillModel bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Delete Bill?",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently delete bill ${bill.invoiceNo} (${bill.billType}) of ₹${bill.amount.toStringAsFixed(0)}? This action cannot be undone.",
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().deleteBill(bill.id);
              if (mounted) {
                _showSnackbar("Bill ${bill.invoiceNo} deleted successfully");
              }
            },
            child: Text("Delete", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Navigate to Broadcast Notification Page: Fee Payment Reminder for unpaid, Urgent Defaulter Warning for defaulters
  void _navigateToBroadcastForBill(BillModel bill) {
    final isDefaulter = bill.isDefaulter;
    final templateId = isDefaulter ? "t1" : "t2";
    final heading = isDefaulter
        ? "Urgent Defaulter Warning: ${bill.billType}"
        : "Fee Payment Reminder: ${bill.billType}";
    final description = isDefaulter
        ? "URGENT NOTICE: Your fee payment of ₹${bill.balance.toStringAsFixed(0)} for ${bill.billType} was due on ${_formatDate(bill.dueDate)}. Please clear your outstanding dues immediately."
        : "Fee Payment Reminder: Your fee payment of ₹${bill.balance.toStringAsFixed(0)} for ${bill.billType} is due on ${_formatDate(bill.dueDate)}. Kindly clear your dues via the student app.";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BroadcastNotificationScreen(
          initialAudience: BroadcastAudience.selectStudent,
          initialStudentId: _student.id,
          initialTemplateId: templateId,
          initialMessageMode: BroadcastMessageMode.templates,
          initialCustomHeading: heading,
          initialCustomDescription: description,
        ),
      ),
    );
  }

  // Receipt / Download Bill Dialog (Paid fees only)
  void _openReceiptDialog(BillModel item) {
    if (!item.isPaid) {
      _showSnackbar("Receipts are available for paid fees only.", isSuccess: false);
      return;
    }
    final receiptNo = item.transactionRef ?? item.invoiceNo;
    final dateStr = item.paidDate != null && item.paidDate!.isNotEmpty
        ? item.paidDate!
        : _formatDate(item.createdAt);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: primaryBlue, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                "LAKSHYA RESIDENCY",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "Official Fee Receipt",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow("Receipt / Ref No", receiptNo, isBold: true),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildReceiptRow("Student Name", _student.fullName),
                    _buildReceiptRow("Building / Room", "${_student.building} • ${_student.room}"),
                    _buildReceiptRow("Fee Description", item.billType),
                    _buildReceiptRow("Billing Period", item.billingMonth.isNotEmpty ? item.billingMonth : "Current Term"),
                    _buildReceiptRow("Payment Date", dateStr),
                    _buildReceiptRow("Payment Mode", item.paymentMethod ?? "Online / UPI / Cash"),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildReceiptRow(
                      "Amount Paid",
                      "₹${(item.isPaid ? item.paidAmount : item.amount).toStringAsFixed(0)}",
                      isHighlight: true,
                      highlightColor: const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        "Close",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '''
LAKSHYA RESIDENCY - OFFICIAL FEE RECEIPT
-----------------------------------------
Receipt Ref: $receiptNo
Student Name: ${_student.fullName}
Building: ${_student.building} (Room ${_student.room}, ${_student.displayBed})
Fee Description: ${item.billType}
Billing Period: ${item.billingMonth}
Amount Paid: ₹${(item.isPaid ? item.paidAmount : item.amount).toStringAsFixed(0)}
Payment Date: $dateStr
Payment Mode: ${item.paymentMethod ?? 'Online'}
Status: PAID & VERIFIED
-----------------------------------------
'''));
                        Navigator.pop(ctx);
                        _showSnackbar("Bill receipt downloaded & copied to clipboard!");
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        "Download",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String title, String value,
      {bool isBold = false, bool isHighlight = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: textMuted,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isHighlight ? 15 : 12.5,
              color: highlightColor ?? (isBold ? primaryDark : const Color(0xFF334155)),
              fontWeight: (isBold || isHighlight) ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Issue New Bill Dialog
  void _openIssueBillDialog() {
    final amountController = TextEditingController();
    final nameController = TextEditingController();
    String billType = "Hostel Rent";
    int dueDays = 15;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
              Text(
                "Issue New Bill / Invoice",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: primaryDark,
                ),
              ),
              Text(
                "For resident: ${_student.fullName} (${_student.building} • ${_student.room})",
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: textMuted),
              ),
              const SizedBox(height: 16),

              Text(
                "Bill Category",
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: billType,
                    isExpanded: true,
                    items: [
                      "Hostel Rent",
                      "Security Deposit",
                      "Electricity Bill",
                      "Mess Bill",
                      "Cleaning Bill",
                      "Maintenance Fee",
                      "WiFi Subscription",
                    ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => billType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "Name of Bill / Period",
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "e.g. October Rent / Monthly Electricity",
                  filled: true,
                  fillColor: bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "Amount (₹)",
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  hintText: "Enter amount",
                  filled: true,
                  fillColor: bgSurface,
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
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                          if (amt <= 0) {
                            _showSnackbar("Please enter a valid amount", isSuccess: false);
                            return;
                          }
                          setModalState(() => isSaving = true);
                          try {
                            await FirestoreService().issueBill({
                              'studentId': _student.id,
                              'studentName': _student.fullName,
                              'phone': _student.phone,
                              'building': _student.building,
                              'room': _student.room,
                              'billType': billType,
                              'amount': amt,
                              'paidAmount': 0.0,
                              'dueDate': Timestamp.fromDate(DateTime.now().add(Duration(days: dueDays))),
                              'status': 'Pending',
                              'invoiceNo': 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                              'billingMonth': nameController.text.trim().isNotEmpty
                                  ? nameController.text.trim()
                                  : billType,
                            });
                            if (modalCtx.mounted) {
                              Navigator.pop(modalCtx);
                            }
                            if (mounted) {
                              _showSnackbar("Bill issued successfully for ${_student.fullName}!");
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            _showSnackbar("Failed to issue bill: $e", isSuccess: false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Issue Bill & Generate Invoice",
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 2: NOTES (PERSONAL CHAT / MESSAGES WITH DATE & TIME)
  // ===========================================================================

  Widget _buildNotesSection() {
    return Column(
      children: [
        // Informational Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFEFF6FF),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Personal messages sent here remain in the chat and are visible to both the student and admin.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF1E40AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Chat Message Thread Stream
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getPersonalNotesStream(_student.id),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              // Merge Firestore subcollection notes with existing onboarding notes
              final allNotes = <Map<String, dynamic>>[];

              // Add historical onboarding notes if subcollection is new
              if (_student.notes.isNotEmpty && docs.isEmpty) {
                for (var n in _student.notes) {
                  allNotes.add({
                    'text': n,
                    'senderName': 'Management',
                    'senderRole': 'admin',
                    'createdAt': _student.createdAt,
                  });
                }
              }

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                DateTime dt = DateTime.now();
                if (data['createdAt'] is Timestamp) {
                  dt = (data['createdAt'] as Timestamp).toDate();
                } else if (data['createdAt'] != null) {
                  dt = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
                }

                allNotes.add({
                  'id': doc.id,
                  'text': data['text'] ?? data['message'] ?? '',
                  'senderName': data['senderName'] ?? 'Admin',
                  'senderRole': data['senderRole'] ?? 'admin',
                  'createdAt': dt,
                });
              }

              if (allNotes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, size: 38, color: primaryBlue),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "No personal messages yet",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Send a personal note to ${_student.firstName} below.",
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: textMuted),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _notesScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: allNotes.length,
                itemBuilder: (context, index) {
                  final note = allNotes[index];
                  final String text = note['text'] ?? '';
                  final String senderName = note['senderName'] ?? 'Admin';
                  final bool isAdmin = (note['senderRole'] ?? 'admin') == 'admin';
                  final DateTime dt = note['createdAt'] is DateTime
                      ? note['createdAt'] as DateTime
                      : DateTime.now();

                  return Align(
                    alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isAdmin ? primaryBlue : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isAdmin ? 16 : 4),
                          bottomRight: Radius.circular(isAdmin ? 4 : 16),
                        ),
                        border: isAdmin ? null : Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAdmin ? "Admin Notice" : senderName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isAdmin ? Colors.white : primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: isAdmin ? Colors.white : primaryDark,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Date and Time Sent
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: isAdmin ? Colors.white70 : textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(dt),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isAdmin ? Colors.white70 : textMuted,
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
          ),
        ),

        // Message Composer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteInputController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Send a personal note to ${_student.firstName}...",
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: textMuted),
                      filled: true,
                      fillColor: bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSendingNote ? null : _sendPersonalNote,
                  icon: _isSendingNote
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
                        )
                      : const Icon(Icons.send_rounded, color: primaryBlue, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendPersonalNote() async {
    final msg = _noteInputController.text.trim();
    if (msg.isEmpty) return;

    setState(() => _isSendingNote = true);
    try {
      await FirestoreService().sendPersonalNote(_student.id, {
        'text': msg,
        'senderName': widget.currentUser?.fullName ?? 'Administrator',
        'senderRole': 'admin',
      });
      _noteInputController.clear();
      _showSnackbar("Message sent to ${_student.fullName}!");
      // Scroll to bottom
      if (_notesScrollController.hasClients) {
        _notesScrollController.animateTo(
          _notesScrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      _showSnackbar("Failed to send message: $e", isSuccess: false);
    } finally {
      if (mounted) setState(() => _isSendingNote = false);
    }
  }

  // ===========================================================================
  // SECTION 3: AMENITIES (ROOM INVENTORY & ASSETS)
  // ===========================================================================

  Widget _buildAmenitiesSection() {
    final List<String> inventory = List.from(_student.inventory);

    // Fallback default room amenities if none were recorded
    if (inventory.isEmpty) {
      inventory.addAll([
        "Bed",
        "Almirah",
        "Induction",
        "Microwave",
        "Fridge",
        "TV",
        "Study Table",
        "Chair",
        "AC",
        "Geyser",
      ]);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Room Amenities Provided",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
                Text(
                  "Assigned to Room ${_student.room} (${_student.displayBed})",
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textMuted),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _openAddAmenityDialog,
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                "Add Item",
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Grid of Amenities
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: inventory.length,
          itemBuilder: (context, index) {
            final item = inventory[index];
            final icon = _getAmenityIcon(item);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: primaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Provided in Room",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _removeAmenity(item),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Quick suggestions / Common items
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Quick Add Common Amenities",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryDark,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  "Bed",
                  "Almirah",
                  "Induction",
                  "Microwave",
                  "Fridge",
                  "TV",
                  "Study Table",
                  "Chair",
                  "Geyser",
                  "AC",
                  "Curtains",
                  "Wi-Fi",
                ].map((item) {
                  final alreadyHas = inventory.any((x) => x.toLowerCase() == item.toLowerCase());
                  return ActionChip(
                    label: Text(
                      alreadyHas ? "✓ $item" : "+ $item",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: alreadyHas ? const Color(0xFF15803D) : primaryBlue,
                      ),
                    ),
                    backgroundColor: alreadyHas ? const Color(0xFFDCFCE7) : Colors.white,
                    side: BorderSide(
                      color: alreadyHas ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                    ),
                    onPressed: () {
                      if (!alreadyHas) {
                        _addAmenity(item);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getAmenityIcon(String item) {
    final lower = item.toLowerCase();
    if (lower.contains("bed")) return Icons.bed_rounded;
    if (lower.contains("almirah") || lower.contains("cupboard") || lower.contains("wardrobe")) {
      return Icons.door_sliding_rounded;
    }
    if (lower.contains("induction") || lower.contains("cook")) return Icons.soup_kitchen_rounded;
    if (lower.contains("microwave") || lower.contains("oven")) return Icons.microwave_rounded;
    if (lower.contains("fridge") || lower.contains("refrigerator")) return Icons.kitchen_rounded;
    if (lower.contains("tv") || lower.contains("television")) return Icons.tv_rounded;
    if (lower.contains("table") || lower.contains("desk")) return Icons.desk_rounded;
    if (lower.contains("chair")) return Icons.chair_alt_rounded;
    if (lower.contains("geyser") || lower.contains("heater") || lower.contains("water")) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains("ac") || lower.contains("air")) return Icons.ac_unit_rounded;
    if (lower.contains("fan")) return Icons.wind_power_rounded;
    if (lower.contains("curtain")) return Icons.curtains_rounded;
    if (lower.contains("wifi") || lower.contains("internet")) return Icons.wifi_rounded;
    return Icons.inventory_2_rounded;
  }

  void _openAddAmenityDialog() {
    final itemController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Add Room Amenity",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: itemController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "e.g. Electric Kettle, Study Lamp",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final val = itemController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(dialogCtx);
                _addAmenity(val);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text("Add Item", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addAmenity(String item) async {
    final list = List<String>.from(_student.inventory);
    if (!list.contains(item)) {
      list.add(item);
      setState(() {
        _student = StudentProfile(
          id: _student.id,
          studentId: _student.studentId,
          fullName: _student.fullName,
          firstName: _student.firstName,
          email: _student.email,
          phone: _student.phone,
          registrationNumber: _student.registrationNumber,
          course: _student.course,
          branch: _student.branch,
          building: _student.building,
          room: _student.room,
          bedNumber: _student.bedNumber,
          plan: _student.plan,
          paymentFrequency: _student.paymentFrequency,
          monthlyRent: _student.monthlyRent,
          securityDeposit: _student.securityDeposit,
          guardianName: _student.guardianName,
          guardianPhone: _student.guardianPhone,
          guardianRelationship: _student.guardianRelationship,
          dietaryPreference: _student.dietaryPreference,
          photoUrl: _student.photoUrl,
          collegeIdUrl: _student.collegeIdUrl,
          govtIdUrl: _student.govtIdUrl,
          rentAgreementUrl: _student.rentAgreementUrl,
          additionalDocs: _student.additionalDocs,
          inventory: list,
          notes: _student.notes,
          installments: _student.installments,
          status: _student.status,
          createdAt: _student.createdAt,
        );
      });
      try {
        await FirestoreService().updateStudentAmenities(_student.id, list);
        _showSnackbar("Added $item to room inventory!");
      } catch (e) {
        _showSnackbar("Failed to update inventory: $e", isSuccess: false);
      }
    }
  }

  Future<void> _removeAmenity(String item) async {
    final list = List<String>.from(_student.inventory);
    list.remove(item);
    setState(() {
      _student = StudentProfile(
        id: _student.id,
        studentId: _student.studentId,
        fullName: _student.fullName,
        firstName: _student.firstName,
        email: _student.email,
        phone: _student.phone,
        registrationNumber: _student.registrationNumber,
        course: _student.course,
        branch: _student.branch,
        building: _student.building,
        room: _student.room,
        bedNumber: _student.bedNumber,
        plan: _student.plan,
        paymentFrequency: _student.paymentFrequency,
        monthlyRent: _student.monthlyRent,
        securityDeposit: _student.securityDeposit,
        guardianName: _student.guardianName,
        guardianPhone: _student.guardianPhone,
        guardianRelationship: _student.guardianRelationship,
        dietaryPreference: _student.dietaryPreference,
        photoUrl: _student.photoUrl,
        collegeIdUrl: _student.collegeIdUrl,
        govtIdUrl: _student.govtIdUrl,
        rentAgreementUrl: _student.rentAgreementUrl,
        additionalDocs: _student.additionalDocs,
        inventory: list,
        notes: _student.notes,
        installments: _student.installments,
        status: _student.status,
        createdAt: _student.createdAt,
      );
    });
    try {
      await FirestoreService().updateStudentAmenities(_student.id, list);
      _showSnackbar("Removed $item from inventory");
    } catch (e) {
      _showSnackbar("Failed to update inventory: $e", isSuccess: false);
    }
  }

  // ===========================================================================
  // SECTION 4: EMERGENCY CONTACT DETAILS
  // ===========================================================================

  Widget _buildEmergencyContactSection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Primary Emergency Contact Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Primary Emergency Contact",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryDark,
                          ),
                        ),
                        Text(
                          "Immediate parent / legal guardian details",
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: primaryBlue, size: 20),
                    tooltip: "Edit Emergency Contact",
                    onPressed: _openEditEmergencyDialog,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),

              // Guardian Name
              _buildDetailItem(
                icon: Icons.person_outline_rounded,
                label: "Guardian / Parent Name",
                value: _student.guardianName.isNotEmpty ? _student.guardianName : "Not Provided",
              ),
              const SizedBox(height: 14),

              // Relationship
              _buildDetailItem(
                icon: Icons.family_restroom_rounded,
                label: "Relationship",
                value: _student.guardianRelationship.isNotEmpty
                    ? _student.guardianRelationship
                    : "Guardian",
              ),
              const SizedBox(height: 14),

              // Phone Number
              _buildDetailItem(
                icon: Icons.phone_rounded,
                label: "Emergency Phone Number",
                value: _student.guardianPhone.isNotEmpty ? _student.guardianPhone : "Not Provided",
                statusColor: primaryBlue,
              ),

              const SizedBox(height: 24),

              // Call & WhatsApp Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_student.guardianPhone.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: _student.guardianPhone));
                          _showSnackbar("Emergency number copied to dial: ${_student.guardianPhone}");
                        } else {
                          _showSnackbar("No emergency phone provided", isSuccess: false);
                        }
                      },
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: Text(
                        "Call Guardian",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (_student.guardianPhone.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: _student.guardianPhone));
                          _showSnackbar("Guardian phone copied: ${_student.guardianPhone}");
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(
                        "Copy Phone",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: primaryDark,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Additional Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dietary & Health Preference",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.restaurant_menu_rounded, size: 18, color: primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    "Dietary Preference: ${_student.dietaryPreference}",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openEditEmergencyDialog() {
    final nameCtrl = TextEditingController(text: _student.guardianName);
    final phoneCtrl = TextEditingController(text: _student.guardianPhone);
    String relationship = _student.guardianRelationship.isNotEmpty
        ? _student.guardianRelationship
        : "Father";

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Edit Emergency Contact",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Guardian / Parent Name", style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Text("Relationship", style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: relationship,
                  items: ["Father", "Mother", "Guardian", "Sibling", "Other"].map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => relationship = val);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Text("Emergency Phone Number", style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newPhone = phoneCtrl.text.trim();
                Navigator.pop(dialogCtx);

                setState(() {
                  _student = StudentProfile(
                    id: _student.id,
                    studentId: _student.studentId,
                    fullName: _student.fullName,
                    firstName: _student.firstName,
                    email: _student.email,
                    phone: _student.phone,
                    registrationNumber: _student.registrationNumber,
                    course: _student.course,
                    branch: _student.branch,
                    building: _student.building,
                    room: _student.room,
                    bedNumber: _student.bedNumber,
                    plan: _student.plan,
                    paymentFrequency: _student.paymentFrequency,
                    monthlyRent: _student.monthlyRent,
                    securityDeposit: _student.securityDeposit,
                    guardianName: newName,
                    guardianPhone: newPhone,
                    guardianRelationship: relationship,
                    dietaryPreference: _student.dietaryPreference,
                    photoUrl: _student.photoUrl,
                    collegeIdUrl: _student.collegeIdUrl,
                    govtIdUrl: _student.govtIdUrl,
                    rentAgreementUrl: _student.rentAgreementUrl,
                    additionalDocs: _student.additionalDocs,
                    inventory: _student.inventory,
                    notes: _student.notes,
                    installments: _student.installments,
                    status: _student.status,
                    createdAt: _student.createdAt,
                  );
                });

                try {
                  await FirestoreService().updateStudentEmergencyContact(
                    _student.id,
                    name: newName,
                    relationship: relationship,
                    phone: newPhone,
                  );
                  _showSnackbar("Emergency contact details updated!");
                } catch (e) {
                  _showSnackbar("Failed to update contact: $e", isSuccess: false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 5: DOCUMENTS (COLLEGE ID, GOVT ID, RENT AGREEMENT & OTHERS)
  // ===========================================================================

  Widget _buildDocumentsSection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Student Documents Repository",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryDark,
          ),
        ),
        Text(
          "ID cards, lease agreements, and verified attachments",
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textMuted),
        ),
        const SizedBox(height: 16),
        if (_isUploadingDoc)
          const Padding(
            padding: EdgeInsets.only(bottom: 14.0),
            child: LinearProgressIndicator(color: primaryBlue),
          ),

        // 1. College ID Card
        _buildDocumentCard(
          title: "College ID Card",
          subtitle: "Institutional student verification card",
          url: _student.collegeIdUrl,
          docKey: "collegeIdUrl",
          icon: Icons.badge_rounded,
        ),

        const SizedBox(height: 14),

        // 2. Registered Government ID Card
        _buildDocumentCard(
          title: "Registered Government ID Card",
          subtitle: "Aadhaar Card, Passport, or Voter Identity",
          url: _student.govtIdUrl,
          docKey: "govtIdUrl",
          icon: Icons.shield_rounded,
        ),

        const SizedBox(height: 14),

        // 3. Rent Agreement
        _buildDocumentCard(
          title: "Rent Agreement",
          subtitle: "Executed residential lease agreement & terms",
          url: _student.rentAgreementUrl,
          docKey: "rentAgreementUrl",
          icon: Icons.description_rounded,
        ),

        const SizedBox(height: 14),

        // 4. Additional Documents (if any)
        ..._student.additionalDocs.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: _buildDocumentCard(
              title: entry.key,
              subtitle: "Additional verified attachment",
              url: entry.value?.toString(),
              docKey: "additionalDocs.${entry.key}",
              icon: Icons.attach_file_rounded,
            ),
          );
        }),

        const SizedBox(height: 10),

        // Button to add another document
        OutlinedButton.icon(
          onPressed: _openAddCustomDocDialog,
          icon: const Icon(Icons.note_add_rounded, size: 18),
          label: Text(
            "Add Another Document",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required String? url,
    required String docKey,
    required IconData icon,
  }) {
    final bool hasDoc = url != null && url.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasDoc ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: hasDoc ? primaryBlue : textMuted, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: primaryDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasDoc ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasDoc ? "Uploaded" : "Pending",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: hasDoc ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              if (hasDoc) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openImageFullscreen(url, title: title),
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: Text(
                      "View Document",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _uploadOrReplaceDoc(docKey),
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: Text(
                    hasDoc ? "Replace File" : "Upload File",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: primaryDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _uploadOrReplaceDoc(String docKey) async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      setState(() => _isUploadingDoc = true);
      _showSnackbar("Uploading document...");

      final url = await CloudinaryService.uploadImage(file, folder: "lakshya_documents");
      if (url != null) {
        if (docKey.startsWith("additionalDocs.")) {
          final customName = docKey.replaceFirst("additionalDocs.", "");
          final updatedAdditional = Map<String, dynamic>.from(_student.additionalDocs);
          updatedAdditional[customName] = url;
          await FirestoreService().updateStudentDocuments(_student.id, {
            'additionalDocs': updatedAdditional,
          });
          setState(() {
            _student = StudentProfile(
              id: _student.id,
              studentId: _student.studentId,
              fullName: _student.fullName,
              firstName: _student.firstName,
              email: _student.email,
              phone: _student.phone,
              registrationNumber: _student.registrationNumber,
              course: _student.course,
              branch: _student.branch,
              building: _student.building,
              room: _student.room,
              bedNumber: _student.bedNumber,
              plan: _student.plan,
              paymentFrequency: _student.paymentFrequency,
              monthlyRent: _student.monthlyRent,
              securityDeposit: _student.securityDeposit,
              guardianName: _student.guardianName,
              guardianPhone: _student.guardianPhone,
              guardianRelationship: _student.guardianRelationship,
              dietaryPreference: _student.dietaryPreference,
              photoUrl: _student.photoUrl,
              collegeIdUrl: _student.collegeIdUrl,
              govtIdUrl: _student.govtIdUrl,
              rentAgreementUrl: _student.rentAgreementUrl,
              additionalDocs: updatedAdditional,
              inventory: _student.inventory,
              notes: _student.notes,
              installments: _student.installments,
              status: _student.status,
              createdAt: _student.createdAt,
            );
          });
        } else {
          await FirestoreService().updateStudentDocuments(_student.id, {docKey: url});
          setState(() {
            _student = StudentProfile(
              id: _student.id,
              studentId: _student.studentId,
              fullName: _student.fullName,
              firstName: _student.firstName,
              email: _student.email,
              phone: _student.phone,
              registrationNumber: _student.registrationNumber,
              course: _student.course,
              branch: _student.branch,
              building: _student.building,
              room: _student.room,
              bedNumber: _student.bedNumber,
              plan: _student.plan,
              paymentFrequency: _student.paymentFrequency,
              monthlyRent: _student.monthlyRent,
              securityDeposit: _student.securityDeposit,
              guardianName: _student.guardianName,
              guardianPhone: _student.guardianPhone,
              guardianRelationship: _student.guardianRelationship,
              dietaryPreference: _student.dietaryPreference,
              photoUrl: docKey == 'photoUrl' ? url : _student.photoUrl,
              collegeIdUrl: docKey == 'collegeIdUrl' ? url : _student.collegeIdUrl,
              govtIdUrl: docKey == 'govtIdUrl' ? url : _student.govtIdUrl,
              rentAgreementUrl: docKey == 'rentAgreementUrl' ? url : _student.rentAgreementUrl,
              additionalDocs: _student.additionalDocs,
              inventory: _student.inventory,
              notes: _student.notes,
              installments: _student.installments,
              status: _student.status,
              createdAt: _student.createdAt,
            );
          });
        }
        _showSnackbar("Document uploaded and saved successfully!");
      } else {
        _showSnackbar("Failed to upload document", isSuccess: false);
      }
    } catch (e) {
      _showSnackbar("Error uploading: $e", isSuccess: false);
    } finally {
      if (mounted) setState(() => _isUploadingDoc = false);
    }
  }

  void _openAddCustomDocDialog() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Add New Document",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            hintText: "Document Name (e.g. Police Verification)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final docName = nameCtrl.text.trim();
              if (docName.isNotEmpty) {
                Navigator.pop(dialogCtx);
                _uploadOrReplaceDoc("additionalDocs.$docName");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text("Select & Upload File", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Fullscreen interactive document & photo viewer
  void _openImageFullscreen(String url, {required String title}) {
    if (url.isEmpty) {
      _showSnackbar("No document file uploaded yet to view.");
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (context, err, stack) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image_rounded, size: 50, color: Colors.white54),
                      const SizedBox(height: 12),
                      Text(
                        "Unable to load document preview",
                        style: GoogleFonts.plusJakartaSans(color: Colors.white70),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Edit Basic Profile Information Dialog
  void _openEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _student.fullName);
    final phoneCtrl = TextEditingController(text: _student.phone);
    final emailCtrl = TextEditingController(text: _student.email);
    final regCtrl = TextEditingController(text: _student.registrationNumber);
    final courseCtrl = TextEditingController(text: _student.course);
    final branchCtrl = TextEditingController(text: _student.branch);
    final roomCtrl = TextEditingController(text: _student.room);
    final bedCtrl = TextEditingController(text: _student.bedNumber);
    String selectedBuilding = _student.building;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
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
          child: SingleChildScrollView(
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
                Text(
                  "Edit Student Profile",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField("Full Name", nameCtrl),
                const SizedBox(height: 12),

                // Building Dropdown
                Text("Building", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedBuilding,
                  items: [
                    "Lakshya",
                    "Shivalya",
                    "Ishaan",
                    "Univ homes",
                    "Tirupati",
                    "Rameshwaram",
                    "Livano",
                    "Somnath",
                  ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedBuilding = val);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: bgSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _buildTextField("Room Number", roomCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField("Bed Number", bedCtrl, hint: "Bed 1")),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _buildTextField("Phone Number", phoneCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField("Registration No", regCtrl)),
                  ],
                ),
                const SizedBox(height: 12),

                _buildTextField("Email ID", emailCtrl),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _buildTextField("Course", courseCtrl, hint: "B.Tech")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField("Branch", branchCtrl, hint: "CSE")),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updatedFields = {
                        'fullName': nameCtrl.text.trim(),
                        'building': selectedBuilding,
                        'room': roomCtrl.text.trim(),
                        'bedNumber': bedCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'registrationNumber': regCtrl.text.trim(),
                        'course': courseCtrl.text.trim(),
                        'branch': branchCtrl.text.trim(),
                      };

                      Navigator.pop(modalCtx);

                      setState(() {
                        _student = StudentProfile(
                          id: _student.id,
                          studentId: _student.studentId,
                          fullName: updatedFields['fullName']!,
                          firstName: updatedFields['fullName']!.split(' ').first,
                          email: updatedFields['email']!,
                          phone: updatedFields['phone']!,
                          registrationNumber: updatedFields['registrationNumber']!,
                          course: updatedFields['course']!,
                          branch: updatedFields['branch']!,
                          building: updatedFields['building']!,
                          room: updatedFields['room']!,
                          bedNumber: updatedFields['bedNumber']!,
                          plan: _student.plan,
                          paymentFrequency: _student.paymentFrequency,
                          monthlyRent: _student.monthlyRent,
                          securityDeposit: _student.securityDeposit,
                          guardianName: _student.guardianName,
                          guardianPhone: _student.guardianPhone,
                          guardianRelationship: _student.guardianRelationship,
                          dietaryPreference: _student.dietaryPreference,
                          photoUrl: _student.photoUrl,
                          collegeIdUrl: _student.collegeIdUrl,
                          govtIdUrl: _student.govtIdUrl,
                          rentAgreementUrl: _student.rentAgreementUrl,
                          additionalDocs: _student.additionalDocs,
                          inventory: _student.inventory,
                          notes: _student.notes,
                          installments: _student.installments,
                          status: _student.status,
                          createdAt: _student.createdAt,
                        );
                      });

                      try {
                        await FirestoreService().updateStudentProfileFields(_student.id, updatedFields);
                        _showSnackbar("Profile updated successfully!");
                      } catch (e) {
                        _showSnackbar("Failed to update profile: $e", isSuccess: false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Save Profile Details",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(modalCtx);
                      _confirmDeleteStudentProfile();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                    label: Text(
                      "Delete Student Profile",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? statusColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: textMuted),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: textMuted)),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: statusColor ?? primaryDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // DELETE STUDENT PROFILE
  // ===========================================================================

  Future<void> _confirmDeleteStudentProfile() async {
    bool deleteBills = true;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Delete Profile?",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: primaryDark,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: const Color(0xFF475569),
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: "Are you sure you want to permanently delete the resident profile of "),
                    TextSpan(
                      text: "${_student.fullName} (${_student.registrationNumber})",
                      style: const TextStyle(fontWeight: FontWeight.w800, color: primaryDark),
                    ),
                    const TextSpan(text: " from "),
                    TextSpan(
                      text: "${_student.building}, Room ${_student.displayRoomOnly}",
                      style: const TextStyle(fontWeight: FontWeight.w700, color: primaryBlue),
                    ),
                    const TextSpan(text: "?"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This action cannot be undone. Room occupancy will be released immediately.",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () {
                  setDialogState(() {
                    deleteBills = !deleteBills;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: deleteBills,
                          activeColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setDialogState(() {
                              deleteBills = val ?? true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Also delete associated bills & payment records",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                "Cancel",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogCtx, true),
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: Text(
                "Delete Profile",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFDC2626)),
        ),
      );

      try {
        await FirestoreService().deleteStudentProfile(
          _student.id,
          deleteBills: deleteBills,
        );

        if (mounted) {
          Navigator.pop(context); // Dismiss loading spinner
          Navigator.pop(context, true); // Pop back to students directory
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Student profile for ${_student.fullName} deleted successfully.",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Dismiss loading spinner
          _showSnackbar("Failed to delete profile: $e", isSuccess: false);
        }
      }
    }
  }

  // ===========================================================================
  // MAIN BUILD METHOD
  // ===========================================================================

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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryDark, size: 20),
            tooltip: "Back to Dashboard",
            onPressed: _handleBackToDashboard,
          ),
        title: Text(
          "Resident Profile",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: primaryDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: primaryBlue),
            tooltip: "Call Student",
            onPressed: () {
              if (_student.phone.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: _student.phone));
                _showSnackbar("Student phone copied: ${_student.phone}");
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
            tooltip: "Delete Student Profile",
            onPressed: _confirmDeleteStudentProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Top Profile Header
            _buildTopHeader(),

            // 5 Functional Button Tabs
            _buildSectionButtonsBar(),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Active Section Body
            Expanded(
              child: IndexedStack(
                index: _activeSection,
                children: [
                  _buildFeesDetailsSection(), // Button 1: Fees Details
                  _buildNotesSection(),       // Button 2: Notes
                  _buildAmenitiesSection(),   // Button 3: Amenities
                  _buildEmergencyContactSection(), // Button 4: Emergency Contact
                  _buildDocumentsSection(),   // Button 5: Documents
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
