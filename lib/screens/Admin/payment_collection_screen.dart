import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/admin_drawer.dart';
import '../../widgets/document_viewer_modal.dart';
import '../../widgets/payment_receipt_dialog.dart';
import '../../widgets/app_toast.dart';
import '../../services/firestore_service.dart';
import '../../services/email_service.dart';
import '../../models/bill_model.dart';
import '../../models/student_profile_model.dart';
import 'broadcast_notification_screen.dart';
import 'dashboard_screen.dart';

class PaymentCollectionScreen extends StatefulWidget {
  final String? initialFilter; // 'All', 'Pending', 'Defaulters', 'Collected'
  final bool openIssueBillModal;

  const PaymentCollectionScreen({
    super.key,
    this.initialFilter,
    this.openIssueBillModal = false,
  });

  @override
  State<PaymentCollectionScreen> createState() => _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState extends State<PaymentCollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isKpiExpanded = true;
  String _selectedBuilding = "All Buildings";
  String _selectedBillType = "All Types";
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

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

  final List<String> _billTypes = [
    "All Types",
    "Hostel bill & security deposit",
    "Utility bills",
  ];

  String _depositSubFilter = "All"; // "All", "Held", "Returned"

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialFilter != null) {
      final f = widget.initialFilter!.toLowerCase();
      if (f.contains("defaulter")) {
        initialIndex = 1;
      } else if (f.contains("unverif")) {
        initialIndex = 3;
      } else if (f.contains("pending")) {
        initialIndex = 2;
      } else if (f.contains("deposit") || f.contains("security")) {
        initialIndex = 5;
      } else if (f.contains("collect") || f.contains("paid")) {
        initialIndex = 4;
      }
    }

    _tabController = TabController(length: 6, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.openIssueBillModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openIssueBillModal();
      });
    }
    FirestoreService().purgeDummyBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}";
  }

  String _formatIndianCurrency(double amount) {
    int val = amount.round();
    if (val < 0) val = 0;
    String s = val.toString();
    if (s.length <= 3) return "₹$s";
    String lastThree = s.substring(s.length - 3);
    String otherNumbers = s.substring(0, s.length - 3);
    if (otherNumbers.isNotEmpty) {
      RegExp reg = RegExp(r'(\d+?)(?=(\d{2})+(?!\d))');
      otherNumbers = otherNumbers.replaceAllMapped(reg, (Match m) => "${m[1]},");
    }
    return "₹$otherNumbers,$lastThree";
  }

  Widget _buildTabBadge(String count, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  List<BillModel> _applyFilters(List<BillModel> bills) {
    final filtered = bills.where((p) {
      // 1. Building filter
      if (_selectedBuilding != "All Buildings") {
        final bSearch = _selectedBuilding.toLowerCase().replaceAll(" residency", "").replaceAll(" homes", "");
        final pBuilding = p.building.toLowerCase();
        if (!pBuilding.contains(bSearch)) {
          return false;
        }
      }

      // 2. Bill Types filter
      if (_selectedBillType == "Hostel bill & security deposit") {
        if (!p.isHostelBillOrSecurityDeposit) return false;
      } else if (_selectedBillType == "Utility bills") {
        if (!p.isUtilityBill) return false;
      }

      // 3. Tab filter:
      // Tab 0: Recent (All active bills)
      // Tab 1: Defaulters (Overdue unpaid payments)
      // Tab 2: Pending (Pending non-defaulter payments, not submitted yet)
      // Tab 3: Unverified (Submitted payment proof awaiting owner verification)
      // Tab 4: Paid (Completed verified payments)
      // Tab 5: Security Deposit (Verified held deposits and returned deposits)
      final tabIndex = _tabController.index;
      if (tabIndex == 1) {
        if (!p.isDefaulter) return false;
      } else if (tabIndex == 2) {
        if (!p.isPendingOnly) return false;
      } else if (tabIndex == 3) {
        if (!p.isPendingVerification) return false;
      } else if (tabIndex == 4) {
        if (!p.isPaid) return false;
      } else if (tabIndex == 5) {
        if (!p.isSecurityDeposit || (!p.isPaid && !p.isDepositReturned)) return false;
        if (_depositSubFilter == "Held" && !p.isDepositHeld) return false;
        if (_depositSubFilter == "Returned" && !p.isDepositReturned) return false;
      }

      // 4. Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = p.studentName.toLowerCase().contains(q);
        final matchRoom = p.room.toLowerCase().contains(q);
        final matchId = p.invoiceNo.toLowerCase().contains(q) || p.id.toLowerCase().contains(q);
        final matchPhone = p.phone.toLowerCase().contains(q);
        return matchName || matchRoom || matchId || matchPhone;
      }

      return true;
    }).toList();

    // 5. Apply Tab-Specific Sorting Rules:
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
      // Recent: Pending verification first, then most recent activity (createdAt / paidDate)
      filtered.sort((a, b) {
        if (a.isPendingVerification != b.isPendingVerification) {
          return a.isPendingVerification ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    } else if (tabIndex == 1) {
      // Defaulters: latest defaulters on top (dueDate descending)
      filtered.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    } else if (tabIndex == 2) {
      // Pending: earliest upcoming payment on top (dueDate ascending)
      filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else if (tabIndex == 3) {
      // Unverified: latest submitted first
      filtered.sort((a, b) {
        final aTime = a.submittedAt ?? a.createdAt;
        final bTime = b.submittedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
    } else if (tabIndex == 4) {
      // Paid: Most recent paid transaction on top (paidDate / createdAt descending)
      filtered.sort((a, b) {
        if (a.paidDate != null && b.paidDate != null) {
          return b.paidDate!.compareTo(a.paidDate!);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    } else if (tabIndex == 5) {
      // Security Deposit: Held deposits first, then returned; sorted by date descending
      filtered.sort((a, b) {
        if (a.isDepositHeld != b.isDepositHeld) {
          return a.isDepositHeld ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    return filtered;
  }

  void _showSnackbar(String msg, {bool isSuccess = true}) {
    AppToast.show(context, msg, isSuccess: isSuccess);
  }

  void _viewFullScreenImage(String imageUrl) {
    DocumentViewerModal.show(
      context,
      url: imageUrl,
      title: "Attached Payment Proof",
    );
  }

  void _openReceiptDialog(BillModel item) {
    if (!item.isPaid && !item.isDepositHeld && !item.isDepositReturned) {
      _showSnackbar("Receipts are available for paid fees and security deposits only.", isSuccess: false);
      return;
    }
    PaymentReceiptDialog.show(context, bill: item);
  }

  // Record payment modal
  void _openRecordPaymentModal(BillModel item) {
    final amountController = TextEditingController(text: item.balance.toStringAsFixed(0));
    final refController = TextEditingController(text: item.transactionRef ?? '');
    String selectedMode = (item.paymentMethod != null && item.paymentMethod!.isNotEmpty)
        ? item.paymentMethod!
        : "UPI / QR Code";
    final List<String> modes = [
      "UPI / QR Code",
      "Cash",
      "Bank Transfer (NEFT/RTGS)",
      "Debit/Credit Card",
      "Cheque",
    ];
    if (!modes.contains(selectedMode)) {
      selectedMode = "UPI / QR Code";
    }
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
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
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Record Payment",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.billingMonth.isNotEmpty ? "${item.billType} • ${item.billingMonth}" : item.billType,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Student quick card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFE0E7FF),
                            child: Text(
                              item.initials,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF4338CA),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.studentName.isNotEmpty ? item.studentName : "Student",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${item.room.isNotEmpty ? item.room : 'Room'} • ${item.building}",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Total Due",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "₹${item.balance.toStringAsFixed(0)}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Amount Received Field
                    Text(
                      "Amount Received (₹)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF003896)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003896), width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Dropdown
                    Text(
                      "Payment Mode",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedMode,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                          items: modes.map((m) {
                            return DropdownMenuItem<String>(
                              value: m,
                              child: Text(
                                m,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedMode = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reference ID / Notes
                    Text(
                      "Transaction Ref ID / Notes (Optional)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: refController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "e.g. UPI-982348 or Cash collected by Warden",
                        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003896), width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirm Collect Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final double enteredAmt = double.tryParse(amountController.text) ?? 0.0;
                                if (enteredAmt <= 0) {
                                  _showSnackbar("Please enter a valid received amount", isSuccess: false);
                                  return;
                                }

                                final navigator = Navigator.of(context);
                                setModalState(() => isSaving = true);
                                try {
                                  await FirestoreService().recordPayment(
                                    billId: item.id,
                                    paymentAmount: enteredAmt,
                                    paymentMode: selectedMode,
                                    transactionRef: refController.text.trim().isNotEmpty
                                        ? refController.text.trim()
                                        : "REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
                                    notes: "Recorded by Admin in Payment Collection",
                                  );

                                  if (mounted) {
                                    navigator.pop();
                                    _showSnackbar(
                                        "Payment of ₹${enteredAmt.toStringAsFixed(0)} recorded successfully for ${item.studentName}!");
                                  }
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  _showSnackbar("Error recording payment: $e", isSuccess: false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003896),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Confirm & Record Payment",
                                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                ],
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

  // Issue Bill Modal
  void _openIssueBillModal() {
    StudentProfile? selectedStudent;
    final searchController = TextEditingController();
    String studentSearchQuery = "";

    // 2 Options specified by user:
    // 1. hostel rent/security deposit
    // 2. utility bill
    const String catHostel = "Hostel rent/security deposit";
    const String catUtility = "Utility bill";
    String selectedCategory = catHostel;

    final billNameController = TextEditingController(text: "First Installment");
    final amountController = TextEditingController();
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 7));
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isHostelCategory = selectedCategory == catHostel;
            final bool isStudentSelected = selectedStudent != null;
            final bool isButtonEnabled = isStudentSelected && !isSubmitting;

            // Quick suggestion chips based on selected category
            final suggestionChips = isHostelCategory
                ? [
                    "First Installment",
                    "Second Installment",
                    "Third Installment",
                    "Fourth Installment",
                    "Security Deposit",
                    "Hostel Rent",
                  ]
                : [
                    "Electricity Bill",
                    "Mess Bill",
                    "Cleaning Bill",
                    "WiFi Subscription",
                    "Maintenance Fee",
                    "Water Charges",
                  ];

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
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
                    const SizedBox(height: 14),

                    // Modal Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Issue New Bill",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Search student, assign bill & send notification",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(modalContext),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SECTION 1: STUDENT SELECTION
                    Row(
                      children: [
                        const Icon(Icons.person_search_rounded, size: 18, color: Color(0xFF003896)),
                        const SizedBox(width: 6),
                        Text(
                          "Student Resident",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (selectedStudent == null) ...[
                      // Search Input Field
                      TextField(
                        controller: searchController,
                        onChanged: (val) {
                          setModalState(() {
                            studentSearchQuery = val.trim();
                          });
                        },
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Search student by name, room, reg no...",
                          hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF003896), size: 20),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                  onPressed: () {
                                    searchController.clear();
                                    setModalState(() => studentSearchQuery = "");
                                  },
                                )
                              : null,
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF003896), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Stream list of matching students
                      StreamBuilder<List<StudentProfile>>(
                        stream: FirestoreService().getStudentsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003896)),
                                ),
                              ),
                            );
                          }

                          final students = snapshot.data ?? [];
                          final q = studentSearchQuery.toLowerCase();
                          final filtered = students.where((s) {
                            if (q.isEmpty) return true;
                            return s.fullName.toLowerCase().contains(q) ||
                                s.registrationNumber.toLowerCase().contains(q) ||
                                s.room.toLowerCase().contains(q) ||
                                s.building.toLowerCase().contains(q);
                          }).toList();

                          if (filtered.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Center(
                                child: Text(
                                  q.isEmpty
                                      ? "No students registered yet in system"
                                      : "No student found matching \"$studentSearchQuery\"",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
                                ),
                              ),
                            );
                          }

                          return Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: filtered.length,
                              separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              itemBuilder: (context, idx) {
                                final s = filtered[idx];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFFEEF2FF),
                                    backgroundImage: (s.photoUrl != null && s.photoUrl!.isNotEmpty)
                                        ? NetworkImage(s.photoUrl!)
                                        : null,
                                    child: (s.photoUrl == null || s.photoUrl!.isEmpty)
                                        ? Text(
                                            s.firstName.isNotEmpty ? s.firstName[0].toUpperCase() : "S",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF003896),
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    s.fullName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Room ${s.room.isNotEmpty ? s.room : 'N/A'} • ${s.building} • ${s.registrationNumber}",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Color(0xFF003896),
                                  ),
                                  onTap: () {
                                    setModalState(() {
                                      selectedStudent = s;
                                    });
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      // Selected Student Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFDBEAFE),
                              backgroundImage:
                                  (selectedStudent!.photoUrl != null && selectedStudent!.photoUrl!.isNotEmpty)
                                      ? NetworkImage(selectedStudent!.photoUrl!)
                                      : null,
                              child: (selectedStudent!.photoUrl == null || selectedStudent!.photoUrl!.isEmpty)
                                  ? Text(
                                      selectedStudent!.firstName.isNotEmpty
                                          ? selectedStudent!.firstName[0].toUpperCase()
                                          : "S",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF003896),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          selectedStudent!.fullName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "Selected",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF15803D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Room ${selectedStudent!.room.isNotEmpty ? selectedStudent!.room : 'N/A'} • ${selectedStudent!.building}",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF003896),
                                    ),
                                  ),
                                  Text(
                                    "Reg: ${selectedStudent!.registrationNumber} • Ph: ${selectedStudent!.phone}",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  selectedStudent = null;
                                  studentSearchQuery = "";
                                  searchController.clear();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF003896),
                                side: const BorderSide(color: Color(0xFF93C5FD)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                "Change",
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // SECTION 2: BILL CATEGORY (2 options specified by user)
                    Row(
                      children: [
                        const Icon(Icons.category_rounded, size: 18, color: Color(0xFF003896)),
                        const SizedBox(width: 6),
                        Text(
                          "Bill Category",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // Option 1: Hostel rent / Security deposit
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedCategory = catHostel;
                                if (billNameController.text.isEmpty ||
                                    billNameController.text.contains("Electricity") ||
                                    billNameController.text.contains("Mess") ||
                                    billNameController.text.contains("WiFi")) {
                                  billNameController.text = "First Installment";
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: isHostelCategory ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isHostelCategory ? const Color(0xFF003896) : const Color(0xFFCBD5E1),
                                  width: isHostelCategory ? 1.8 : 1.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.home_work_rounded,
                                    size: 24,
                                    color: isHostelCategory ? const Color(0xFF003896) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Hostel rent /\nSecurity deposit",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: isHostelCategory ? FontWeight.w800 : FontWeight.w600,
                                      color: isHostelCategory ? const Color(0xFF003896) : const Color(0xFF475569),
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Option 2: Utility bill
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedCategory = catUtility;
                                if (billNameController.text.isEmpty ||
                                    billNameController.text.contains("Installment") ||
                                    billNameController.text.contains("Rent") ||
                                    billNameController.text.contains("Deposit")) {
                                  billNameController.text = "Electricity Bill";
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: !isHostelCategory ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !isHostelCategory ? const Color(0xFF003896) : const Color(0xFFCBD5E1),
                                  width: !isHostelCategory ? 1.8 : 1.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 24,
                                    color: !isHostelCategory ? const Color(0xFF003896) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Utility bill\n(Electricity, Mess...)",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: !isHostelCategory ? FontWeight.w800 : FontWeight.w600,
                                      color: !isHostelCategory ? const Color(0xFF003896) : const Color(0xFF475569),
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // SECTION 3: NAME OF THE BILL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF003896)),
                            const SizedBox(width: 6),
                            Text(
                              "Name of the Bill",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Custom or quick tap",
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: billNameController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: isHostelCategory
                            ? "e.g. First Installment, Security Deposit"
                            : "e.g. Electricity Bill, Mess Bill, Cleaning Bill",
                        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003896), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick suggestion chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: suggestionChips.map((chip) {
                          final isSelected = billNameController.text.trim().toLowerCase() == chip.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(
                                chip,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                              backgroundColor: isSelected ? const Color(0xFF003896) : const Color(0xFFF1F5F9),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF003896) : const Color(0xFFE2E8F0),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setModalState(() {
                                  billNameController.text = chip;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 4: AMOUNT & DUE DATE
                    Row(
                      children: [
                        // Amount
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Amount (₹)",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
                                decoration: InputDecoration(
                                  prefixText: "₹ ",
                                  prefixStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF003896),
                                  ),
                                  hintText: isHostelCategory ? "37500" : "1500",
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF003896), width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Due Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Due Date",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDueDate,
                                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                    lastDate: DateTime.now().add(const Duration(days: 730)),
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedDueDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF003896)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _formatDate(selectedDueDate),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
                                          ),
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
                    const SizedBox(height: 24),

                    // SUBMIT BUTTON: Issue Bill & Send Notification
                    if (!isStudentSelected)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              "Select a student from the list above to issue bill",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: !isButtonEnabled
                            ? null
                            : () async {
                                final billName = billNameController.text.trim();
                                if (billName.isEmpty) {
                                  _showSnackbar("Please enter the name of the bill", isSuccess: false);
                                  return;
                                }

                                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                                if (amt <= 0) {
                                  _showSnackbar("Please enter a valid bill amount greater than ₹0", isSuccess: false);
                                  return;
                                }

                                final student = selectedStudent!;
                                final billId = "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
                                final isHostel = selectedCategory == catHostel;
                                final billType = isHostel
                                    ? (billName.toLowerCase().contains("deposit") ? "Security Deposit" : "Hostel Fees")
                                    : "Utility Bill";

                                setModalState(() => isSubmitting = true);

                                try {
                                  // 1. Issue bill in Firestore
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
                                    'billCategory': selectedCategory,
                                    'billingMonth': billName,
                                    'amount': amt,
                                    'paidAmount': 0.0,
                                    'dueDate': Timestamp.fromDate(selectedDueDate),
                                    'status': 'Pending',
                                    'paymentStatus': 'Unpaid',
                                    'invoiceNo': billId,
                                    'avatarUrl': student.photoUrl ?? '',
                                    'studentEmail': student.email,
                                    'email': student.email,
                                  });

                                  // 2. Dispatch in-app notification to that student
                                  await FirestoreService().sendStudentNotification(
                                    studentId: student.id,
                                    studentUid: student.studentId.isNotEmpty ? student.studentId : student.id,
                                    regNo: student.registrationNumber,
                                    studentName: student.fullName,
                                    title: "New Bill: $billName (₹${amt.toStringAsFixed(0)})",
                                    message:
                                        "A new $selectedCategory for $billName (₹${amt.toStringAsFixed(0)}) has been issued for your Room ${student.room} (${student.building}). Due date: ${_formatDate(selectedDueDate)}.",
                                    category: "Payment",
                                    targetBuilding: student.building,
                                    targetRoom: student.room,
                                    metadata: {
                                      'invoiceNo': billId,
                                      'amount': amt,
                                      'dueDate': selectedDueDate.toIso8601String(),
                                      'billCategory': selectedCategory,
                                      'billName': billName,
                                    },
                                  );

                                  // 3. Dispatch Email notification if student has email
                                  if (student.email.isNotEmpty) {
                                    EmailService().sendBillInvoiceEmail(
                                      studentEmail: student.email,
                                      studentName: student.fullName,
                                      billName: billName,
                                      billCategory: selectedCategory,
                                      amount: amt,
                                      dueDate: selectedDueDate,
                                      invoiceNo: billId,
                                      building: student.building,
                                      room: student.room,
                                    );
                                  }

                                  if (modalContext.mounted) {
                                    Navigator.pop(modalContext);
                                  }
                                  if (mounted) {
                                    _showSnackbar(
                                      "New bill '$billName' of ₹${amt.toStringAsFixed(0)} issued & notification sent to ${student.fullName}!",
                                      isSuccess: true,
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  _showSnackbar("Failed to issue bill: $e", isSuccess: false);
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox.shrink()
                            : Icon(
                                isStudentSelected ? Icons.send_rounded : Icons.person_search_rounded,
                                size: 18,
                                color: isButtonEnabled ? Colors.white : const Color(0xFF94A3B8),
                              ),
                        label: isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                isStudentSelected
                                    ? "Issue Bill & Send Notification"
                                    : "Select Student to Issue Bill",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isButtonEnabled ? Colors.white : const Color(0xFF94A3B8),
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003896),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          disabledForegroundColor: const Color(0xFF94A3B8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        backgroundColor: const Color(0xFFF8FAF9),
        drawer: const AdminDrawer(activeItem: "Payment Collection"),
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: "Search student, room, invoice...",
                    hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                )
              : Text(
                  "Payment Collection",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: const Color(0xFF0F172A),
              ),
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
              icon: const Icon(Icons.campaign_outlined, color: Color(0xFF003896)),
              tooltip: "Broadcast Notification",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BroadcastNotificationScreen()),
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
        child: StreamBuilder<List<BillModel>>(
          stream: FirestoreService().getBillsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF003896)),
              );
            }

            final allBills = snapshot.data ?? [];

            // Compute KPIs on allBills
            final totalCollectedSum = allBills.fold(0.0, (acc, p) => acc + p.paidAmount);
            final totalPendingSum = allBills
                .where((p) => !p.isPaid)
                .fold(0.0, (acc, p) => acc + p.balance);
            final hostelRemainingSum = allBills
                .where((p) => !p.isPaid && p.isHostelBillOrSecurityDeposit)
                .fold(0.0, (acc, p) => acc + p.balance);
            final utilityRemainingSum = allBills
                .where((p) => !p.isPaid && p.isUtilityBill)
                .fold(0.0, (acc, p) => acc + p.balance);
            final defaultersCount = allBills.where((p) => p.isDefaulter).length;
            final defaulterPendingSum = allBills
                .where((p) => p.isDefaulter)
                .fold(0.0, (acc, p) => acc + p.balance);
            final pendingVerificationCount = allBills.where((p) => p.isPendingVerification).length;
            final pendingCount = allBills.where((p) => p.isPendingOnly).length;
            final collectedCount = allBills.where((p) => p.isPaid).length;
            final securityDepositCount = allBills.where((p) => p.isSecurityDeposit && (p.isPaid || p.isDepositReturned)).length;
            final heldDepositCount = allBills.where((p) => p.isDepositHeld).length;
            final returnedDepositCount = allBills.where((p) => p.isDepositReturned).length;

            final filteredList = _applyFilters(allBills);

            return Column(
              children: [
                // Top Analytics KPI Summary Banner Card (Collapsible & Compact-Optimized)
                _isKpiExpanded
                    ? Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF003D9E), Color(0xFF0056D2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0056D2).withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Top Row: Total Fees Collected, Total Remaining, and Collapse Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Fees Collected",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatIndianCurrency(totalCollectedSum),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Total Remaining",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(alpha: 0.85),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatIndianCurrency(totalPendingSum),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => setState(() => _isKpiExpanded = false),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.keyboard_arrow_up_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Middle Sub-Card (Hostel Fees vs Utility Bill remaining)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                              ),
                              child: Row(
                                children: [
                                  // Left: Hostel Fees remaining
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(top: 2),
                                              child: Icon(Icons.domain_rounded, size: 14, color: Colors.white70),
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                "Hostel Fees remaining",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white.withValues(alpha: 0.95),
                                                  height: 1.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _formatIndianCurrency(hostelRemainingSum),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 36,
                                    width: 1,
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  // Right: Utility Bill remaining
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(top: 2),
                                              child: Icon(Icons.bolt_rounded, size: 14, color: Colors.white70),
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                "Utility Bill remaining",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white.withValues(alpha: 0.95),
                                                  height: 1.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _formatIndianCurrency(utilityRemainingSum),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                            const SizedBox(height: 8),

                            // Bottom Row: Defaulters, Defaulters Amount, Total Bills
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Defaulters",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        "$defaultersCount Past Due",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFFF7676),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                                Expanded(
                                  flex: 8,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Defaulters Amount",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _formatIndianCurrency(defaulterPendingSum),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFFF7676),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Total Bills",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        "${allBills.length} Active",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : InkWell(
                        onTap: () => setState(() => _isKpiExpanded = true),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF003D9E), Color(0xFF0056D2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0056D2).withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "${_formatIndianCurrency(totalCollectedSum)} collected • ${_formatIndianCurrency(totalPendingSum)} due",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (defaultersCount > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "$defaultersCount Due",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Expand",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                // Status Tabs (Recent, Defaulters, Pending, Paid)
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 4),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: const Color(0xFF003896),
                    unselectedLabelColor: const Color(0xFF64748B),
                    indicatorColor: const Color(0xFF003896),
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: [
                      Tab(
                        child: Row(
                          children: [
                            const Text("Recent"),
                            _buildTabBadge("${allBills.length}", const Color(0xFF003896)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Text("Defaulters"),
                            _buildTabBadge("$defaultersCount", const Color(0xFFDC2626)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Text("Pending"),
                            _buildTabBadge("$pendingCount", const Color(0xFFD97706)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Text("Unverified"),
                            _buildTabBadge(
                              "$pendingVerificationCount",
                              pendingVerificationCount > 0 ? const Color(0xFFEA580C) : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Text("Paid"),
                            _buildTabBadge("$collectedCount", const Color(0xFF16A34A)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Text("Security Deposit"),
                            _buildTabBadge(
                              "$securityDepositCount",
                              securityDepositCount > 0 ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Filters Bar: Buildings & Types (in one non-scrollable line)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      // 1. Building Dropdown Filter
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedBuilding,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              items: _buildings.map((b) {
                                return DropdownMenuItem<String>(
                                  value: b,
                                  child: Text(
                                    b,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedBuilding = val);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 2. Bill Types Dropdown Filter
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: _selectedBillType != "All Types" ? const Color(0xFFEEF2FF) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedBillType != "All Types" ? const Color(0xFF003896) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedBillType,
                              isExpanded: true,
                              icon: const Icon(Icons.filter_list_rounded, size: 18),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _selectedBillType != "All Types" ? const Color(0xFF003896) : const Color(0xFF0F172A),
                              ),
                              items: _billTypes.map((t) {
                                return DropdownMenuItem<String>(
                                  value: t,
                                  child: Text(
                                    t,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedBillType = val);
                              },
                            ),
                          ),
                        ),
                      ),

                      // 3. Active Filters Reset
                      if (_selectedBuilding != "All Buildings" || _selectedBillType != "All Types") ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBuilding = "All Buildings";
                              _selectedBillType = "All Types";
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 15, color: Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Security Deposit Sub-filter Chips (when Security Deposit Tab is active)
                if (_tabController.index == 5) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                    child: Row(
                      children: [
                        _buildDepositSubChip("All", "All ($securityDepositCount)"),
                        const SizedBox(width: 8),
                        _buildDepositSubChip("Held", "Verified & Held ($heldDepositCount)"),
                        const SizedBox(width: 8),
                        _buildDepositSubChip("Returned", "Returned ($returnedDepositCount)"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                const SizedBox(height: 4),

                // Bills List View (with Scrollable, non-overflowing Empty State)
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEEF2FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.payments_outlined, size: 34, color: Color(0xFF003896)),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  allBills.isEmpty ? "No real bills in system yet" : "No matching payment records found",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  allBills.isEmpty
                                      ? "Tap 'Issue Bill' to generate your first invoice."
                                      : "Try adjusting your building or category filters.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                if (allBills.isEmpty) ...[
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    onPressed: _openIssueBillModal,
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                                    label: Text(
                                      "Issue First Bill",
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003896),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return _buildPaymentCard(item);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openIssueBillModal,
        backgroundColor: const Color(0xFF003896),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          "Issue Bill",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}

  Widget _buildDepositSubChip(String key, String label) {
    final isSelected = _depositSubFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _depositSubFilter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BillModel item) {
    Color statusBg;
    Color statusTextColor;
    String statusLabel;

    if (item.isDepositReturned) {
      statusBg = const Color(0xFFEDE9FE);
      statusTextColor = const Color(0xFF6D28D9);
      statusLabel = "Deposit Returned";
    } else if (item.isDepositHeld) {
      statusBg = const Color(0xFFE0E7FF);
      statusTextColor = const Color(0xFF4338CA);
      statusLabel = "Deposit Held";
    } else if (item.isPaid) {
      statusBg = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF16A34A);
      statusLabel = "Paid";
    } else if (item.isPendingVerification) {
      statusBg = const Color(0xFFFFF7ED);
      statusTextColor = const Color(0xFFEA580C);
      statusLabel = "Unverified";
    } else if (item.isDefaulter) {
      statusBg = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFDC2626);
      statusLabel = item.daysOverdue > 0 ? "Overdue (${item.daysOverdue}d)" : "Defaulter";
    } else {
      statusBg = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFD97706);
      statusLabel = "Pending";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Student info & Status Tag
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFEEF2FF),
                  backgroundImage: item.avatarUrl.isNotEmpty ? NetworkImage(item.avatarUrl) : null,
                  onBackgroundImageError: item.avatarUrl.isNotEmpty ? (error, stack) {} : null,
                  child: item.avatarUrl.isEmpty
                      ? Text(
                          item.initials,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF003896),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName.isNotEmpty ? item.studentName : "Student",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${item.room.isNotEmpty ? item.room : 'Room'} • ${item.building}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: item.billingMonth.toLowerCase().contains('installment')
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: item.billingMonth.toLowerCase().contains('installment')
                              ? Border.all(color: const Color(0xFFBFDBFE), width: 0.8)
                              : null,
                        ),
                        child: Text(
                          (item.billingMonth.isNotEmpty && item.billingMonth != item.billType)
                              ? "${item.billType} • ${item.billingMonth}"
                              : item.billType,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: item.billingMonth.toLowerCase().contains('installment')
                                ? const Color(0xFF003896)
                                : const Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Due & Amount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.isPaid ? "Payment Completed" : "Due Date: ${_formatDate(item.dueDate)}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.isPaid && (item.paymentMethod != null || item.paidDate != null)) ...[
                        const SizedBox(height: 2),
                        Text(
                          "Via ${item.paymentMethod ?? 'Online'} (${item.paidDate ?? 'Paid'})",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.isPaid ? "Amount Paid" : "Pending Balance",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.isPaid
                          ? "₹${item.paidAmount.toStringAsFixed(0)}"
                          : "₹${item.balance.toStringAsFixed(0)}",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: item.isPaid ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Proof Banner if student submitted UTR or cash handover (visible in Unverified AND Paid sections)
            if (item.isPendingVerification || (item.isPaid && (item.hasProofScreenshot || (item.transactionRef != null && item.transactionRef!.isNotEmpty) || (item.paymentRemarks != null && item.paymentRemarks!.isNotEmpty) || item.isCash))) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.isPaid
                      ? const Color(0xFFF0FDF4)
                      : (item.isCash ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.isPaid
                        ? const Color(0xFFBBF7D0)
                        : (item.isCash ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: item.isPaid
                                ? const Color(0xFFDCFCE7)
                                : (item.isCash ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item.isPaid
                                ? Icons.verified_rounded
                                : (item.isCash ? Icons.payments_rounded : Icons.verified_user_outlined),
                            size: 18,
                            color: item.isPaid
                                ? const Color(0xFF16A34A)
                                : (item.isCash ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.isPaid
                                    ? "Verified Payment Proof"
                                    : (item.isCash ? "Physical Cash Handover Reported" : "Student Submitted Payment Proof"),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: item.isPaid
                                      ? const Color(0xFF14532D)
                                      : (item.isCash ? const Color(0xFF14532D) : const Color(0xFF92400E)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Method: ${item.paymentMethod ?? (item.isCash ? 'Cash' : 'Online')} • Paid on: ${item.paidDate ?? (item.submittedAt != null ? _formatDate(item.submittedAt!) : 'Recorded')}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!item.isCash && item.transactionRef != null && item.transactionRef!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "UTR / Ref: ${item.transactionRef!}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF9A3412),
                                letterSpacing: 0.3,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: item.transactionRef!));
                                _showSnackbar("UTR copied to clipboard!");
                              },
                              child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFEA580C)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (item.paymentRemarks != null && item.paymentRemarks!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        "Student Note: \"${item.paymentRemarks}\"",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF78350F),
                        ),
                      ),
                    ],
                    if (item.hasProofScreenshot) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _viewFullScreenImage(item.proofUrl!),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  item.proofUrl!,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined, size: 24, color: Color(0xFF64748B)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Screenshot Proof Attached (Tap to inspect)",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF003896),
                                  ),
                                ),
                              ),
                              const Icon(Icons.zoom_in_rounded, size: 16, color: Color(0xFF003896)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Returned Security Deposit notice (if returned)
            if (item.isDepositReturned) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_return_rounded, color: Color(0xFF7C3AED), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Security Deposit Refunded on ${item.returnedAt != null ? _formatDate(item.returnedAt!) : 'Record'} via ${item.refundMode ?? 'Bank transfer'}${item.refundRef?.isNotEmpty == true ? ' (Ref: ${item.refundRef})' : ''}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5B21B6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons per item
            Row(
              children: [
                if (item.isDepositReturned) ...[
                  // Returned Deposit Action: Download Receipt
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openReceiptDialog(item),
                      icon: const Icon(Icons.download_rounded, size: 17),
                      label: Text(
                        "Download Receipt",
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D28D9),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else if (item.isDepositHeld) ...[
                  // Held Deposit Actions: Download Receipt & Return Deposit
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openReceiptDialog(item),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: Text(
                        "Receipt",
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _openReturnDepositModal(item),
                      icon: const Icon(Icons.assignment_return_rounded, size: 16),
                      label: Text(
                        "Return Deposit",
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D28D9),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else if (item.isPaid) ...[
                  // Paid Item Action: Download Receipt Button (PAID FEES ONLY)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openReceiptDialog(item),
                      icon: const Icon(Icons.download_rounded, size: 17),
                      label: Text(
                        "Download Receipt",
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else if (item.isPendingVerification) ...[
                  // Pending Verification Actions: "Verify & Mark Paid" and "Reject"
                  Expanded(
                    flex: 6,
                    child: ElevatedButton.icon(
                      onPressed: () => _openVerifyConfirmationWarningDialog(item),
                      icon: const Icon(Icons.verified_rounded, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Verify & Mark Paid",
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      onPressed: () => _openRejectConfirmationWarningDialog(item),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Reject",
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else ...[
                  // Unpaid Item Actions: Send Notification (Fee Payment Reminder / Urgent Defaulter Warning) & Collect
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToBroadcastForBill(item),
                      icon: const Icon(Icons.campaign_rounded, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Send Notification",
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.isDefaulter ? const Color(0xFFDC2626) : const Color(0xFF003896),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openRecordPaymentModal(item),
                      icon: const Icon(Icons.payments_rounded, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Collect",
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF003896),
                        side: const BorderSide(color: Color(0xFF003896), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _confirmDeleteBill(item),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFDC2626)),
                  tooltip: "Delete Bill",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
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
          initialStudentId: bill.studentId.isNotEmpty ? bill.studentId : null,
          initialTemplateId: templateId,
          initialMessageMode: BroadcastMessageMode.templates,
          initialCustomHeading: heading,
          initialCustomDescription: description,
        ),
      ),
    );
  }

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

  void _openVerifyConfirmationWarningDialog(BillModel item) {
    bool isProcessing = false;
    final remarksController = TextEditingController(
      text: item.isCash
          ? "Cash received & verified by admin"
          : (item.transactionRef != null && item.transactionRef!.isNotEmpty
              ? "Verified via UTR: ${item.transactionRef}"
              : "Payment verified by admin"),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFFD97706),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Confirm Payment Verification",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Review submission details before issuing bill",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Prominent Caution Alert
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.isCash
                                ? "Physical Cash Warning: Please confirm that cash of ₹${item.balance.toStringAsFixed(0)} has been physically received in hand. Confirming will generate a permanent unique bill receipt."
                                : "Bank Balance Warning: Please confirm that ₹${item.balance.toStringAsFixed(0)} is credited to your bank account / UPI statement. Confirming will generate a permanent unique bill receipt.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF92400E),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildVerifyRow("Student", item.studentName, isBold: true),
                        const SizedBox(height: 8),
                        _buildVerifyRow("Room / Building", "${item.room} • ${item.building}"),
                        if (item.bed != null && item.bed!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildVerifyRow("Bed", item.bed!),
                        ],
                        const SizedBox(height: 8),
                        _buildVerifyRow("Bill / Invoice No", item.invoiceNo),
                        const SizedBox(height: 8),
                        _buildVerifyRow("Bill Type", item.billType),
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _buildVerifyRow(
                          "Amount to Verify",
                          "₹${item.balance.toStringAsFixed(0)}",
                          isBold: true,
                          textColor: const Color(0xFF16A34A),
                        ),
                        const SizedBox(height: 8),
                        _buildVerifyRow(
                          "Payment Method",
                          item.paymentMethod ?? (item.isCash ? "Cash" : "Online"),
                          isBold: true,
                          textColor: item.isCash ? const Color(0xFF16A34A) : const Color(0xFF003896),
                        ),
                        if (!item.isCash) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Submitted UTR",
                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF64748B)),
                              ),
                              Row(
                                children: [
                                  Text(
                                    item.transactionRef ?? "Not Provided",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF003896),
                                    ),
                                  ),
                                  if (item.transactionRef != null && item.transactionRef!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: item.transactionRef!));
                                        _showSnackbar("UTR copied to clipboard!");
                                      },
                                      child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF003896)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                        if (item.paymentRemarks != null && item.paymentRemarks!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildVerifyRow("Student Remarks", item.paymentRemarks!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Screenshot Proof (if uploaded)
                  if (item.proofUrl != null && item.proofUrl!.isNotEmpty) ...[
                    Text(
                      "Payment Proof Screenshot",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _viewFullScreenImage(item.proofUrl!),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.proofUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image_rounded, size: 28, color: Color(0xFF64748B)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tap to view full-size screenshot",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF003896),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Inspect transaction ID & timestamp",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.zoom_in_rounded, size: 20, color: Color(0xFF003896)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Admin remarks
                  Text(
                    "Admin Remarks (Optional)",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: remarksController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "E.g. Bank credit confirmed or Cash received",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dialog Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  setDialogState(() => isProcessing = true);
                                  try {
                                    final receiptNo = await FirestoreService().verifyAndMarkBillPaid(
                                      item.id,
                                      paidAmount: item.balance,
                                      adminRemarks: remarksController.text.trim(),
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (!context.mounted) return;
                                    _showSnackbar(
                                      "Payment verified! Official Receipt #$receiptNo issued.",
                                      isSuccess: true,
                                    );
                                    // Show official receipt dialog immediately to admin
                                    final updatedBill = item.copyWith(
                                      status: 'Paid',
                                      paymentStatus: 'Verified & Paid',
                                      receiptNo: receiptNo,
                                      paidAmount: (item.paidAmount) + item.balance,
                                      receiptIssuedAt: DateTime.now(),
                                    );
                                    PaymentReceiptDialog.show(context, bill: updatedBill);
                                  } catch (e) {
                                    setDialogState(() => isProcessing = false);
                                    _showSnackbar("Verification failed: $e", isSuccess: false);
                                  }
                                },
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(
                            isProcessing ? "Issuing Bill..." : "Verify & Issue Bill",
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openRejectConfirmationWarningDialog(BillModel item) {
    bool isProcessing = false;
    final reasonController = TextEditingController(
      text: item.isCash
          ? "Physical cash not received at office"
          : "Payment proof unreadable or transaction not found in bank statement",
    );

    final List<String> commonReasons = [
      item.isCash ? "Physical cash not received" : "Payment not found in bank statement",
      "Invalid or incorrect UTR number",
      "Screenshot blurred / incomplete",
      "Paid amount does not match bill amount",
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Icon(
                          Icons.cancel_rounded,
                          color: Color(0xFFDC2626),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Reject Payment Proof?",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Requires student to re-submit proof",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Warning Notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "WARNING: This will reject the student's payment submission. The bill will be moved back to Pending and a high-priority warning will be displayed on the student's dashboard until dismissed.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF991B1B),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bill Details Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildVerifyRow("Student", item.studentName, isBold: true),
                        const SizedBox(height: 6),
                        _buildVerifyRow("Bill Type", item.billType),
                        const SizedBox(height: 6),
                        _buildVerifyRow("Amount", "₹${item.balance.toStringAsFixed(0)}", isBold: true),
                        if (item.transactionRef != null && item.transactionRef!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _buildVerifyRow("Submitted UTR", item.transactionRef!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Reason Chips
                  Text(
                    "Select Reason or Type Below",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: commonReasons.map((r) {
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            reasonController.text = r;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: reasonController.text == r ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: reasonController.text == r ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            r,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: reasonController.text == r ? FontWeight.w700 : FontWeight.w500,
                              color: reasonController.text == r ? const Color(0xFFDC2626) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Reason textfield
                  Text(
                    "Reason for Rejection (Visible to student) *",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Enter the reason for rejecting this payment proof...",
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final reason = reasonController.text.trim();
                                  if (reason.isEmpty) {
                                    _showSnackbar("Please provide a rejection reason", isSuccess: false);
                                    return;
                                  }
                                  setDialogState(() => isProcessing = true);
                                  try {
                                    await FirestoreService().rejectBillPaymentProof(
                                      item.id,
                                      rejectionReason: reason,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      _showSnackbar(
                                        "Payment proof rejected. Warning banner posted to student dashboard.",
                                        isSuccess: true,
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isProcessing = false);
                                    _showSnackbar("Rejection failed: $e", isSuccess: false);
                                  }
                                },
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cancel_rounded, size: 18),
                          label: Text(
                            isProcessing ? "Rejecting..." : "Confirm Rejection",
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyRow(String label, String value, {bool isBold = false, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: textColor ?? const Color(0xFF0F172A),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _openReturnDepositModal(BillModel item) {
    String selectedRefundMode = "UPI";
    final refController = TextEditingController();
    final remarksController = TextEditingController(text: "Lock-in period ended, full refund processed");
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.assignment_return_rounded, color: Color(0xFF6D28D9), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Return Security Deposit",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "${item.studentName} • ${item.building} (${item.room})",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Deposit Amount",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "₹${(item.paidAmount > 0 ? item.paidAmount : item.amount).toStringAsFixed(0)}",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF6D28D9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Refund Mode",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ["UPI", "Bank transfer", "Cash"].map((mode) {
                      final isSelected = selectedRefundMode == mode;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedRefundMode = mode),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEDE9FE) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFFCBD5E1),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                mode,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  if (selectedRefundMode != "Cash") ...[
                    Text(
                      "Refund Reference / Transaction ID",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: refController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Enter UTR or bank transaction reference",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    "Deductions / Return Remarks",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: remarksController,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Lock-in period ended, full refund processed",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setModalState(() => isProcessing = true);
                              try {
                                await FirestoreService().markSecurityDepositReturned(
                                  billId: item.id,
                                  refundMode: selectedRefundMode,
                                  refundRef: refController.text.trim(),
                                  refundRemarks: remarksController.text.trim(),
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _showSnackbar("Security deposit returned & resident notified!", isSuccess: true);
                              } catch (e) {
                                setModalState(() => isProcessing = false);
                                _showSnackbar("Failed to return deposit: $e", isSuccess: false);
                              }
                            },
                      icon: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        isProcessing ? "Processing Return..." : "Confirm & Mark as Returned",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D28D9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
