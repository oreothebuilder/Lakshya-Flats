import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/admin_drawer.dart';
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

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialFilter != null) {
      final f = widget.initialFilter!.toLowerCase();
      if (f.contains("defaulter")) {
        initialIndex = 1;
      } else if (f.contains("pending")) {
        initialIndex = 2;
      } else if (f.contains("collect") || f.contains("paid")) {
        initialIndex = 3;
      }
    }

    _tabController = TabController(length: 4, vsync: this, initialIndex: initialIndex);
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
      // Tab 0: Recent (All payments)
      // Tab 1: Defaulters (Overdue unpaid payments)
      // Tab 2: Pending (Pending non-defaulter payments)
      // Tab 3: Paid (Completed payments)
      final tabIndex = _tabController.index;
      if (tabIndex == 1) {
        if (!p.isDefaulter) return false;
      } else if (tabIndex == 2) {
        if (p.isPaid || p.isDefaulter) return false;
      } else if (tabIndex == 3) {
        if (!p.isPaid) return false;
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
      // Recent: Most recent activity (createdAt / paidDate) first
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (tabIndex == 1) {
      // Defaulters: Latest defaulters on top (dueDate descending)
      filtered.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    } else if (tabIndex == 2) {
      // Pending: Earliest upcoming payment on top (dueDate ascending)
      filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else if (tabIndex == 3) {
      // Paid: Most recent paid transaction on top (paidDate / createdAt descending)
      filtered.sort((a, b) {
        if (a.paidDate != null && b.paidDate != null) {
          return b.paidDate!.compareTo(a.paidDate!);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    return filtered;
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
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF003896) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
              // Header Badge & Title
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF003896), size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                "LAKSHYA RESIDENCY",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF003896),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                item.isPaid ? "Official Fee Receipt" : "Official Invoice Statement",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // Receipt Table
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow("Receipt / Ref No", receiptNo, isBold: true),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildReceiptRow("Student Name", item.studentName.isNotEmpty ? item.studentName : "Resident"),
                    _buildReceiptRow("Building / Room", "${item.building} • ${item.room.isNotEmpty ? item.room : 'N/A'}"),
                    _buildReceiptRow("Fee Description", item.billType),
                    _buildReceiptRow("Billing Period", item.billingMonth.isNotEmpty ? item.billingMonth : "Current Term"),
                    _buildReceiptRow(item.isPaid ? "Payment Date" : "Due Date", dateStr),
                    _buildReceiptRow("Payment Mode", item.isPaid ? (item.paymentMethod ?? "Online / UPI") : "Pending Collection"),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildReceiptRow(
                      item.isPaid ? "Amount Paid" : "Balance Due",
                      "₹${(item.isPaid ? item.paidAmount : item.balance).toStringAsFixed(0)}",
                      isHighlight: true,
                      highlightColor: item.isPaid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
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
LAKSHYA RESIDENCY - FEE RECEIPT
---------------------------------
Receipt Ref: $receiptNo
Student: ${item.studentName}
Building: ${item.building} (Room ${item.room})
Fee Type: ${item.billType}
Billing Month: ${item.billingMonth}
Amount: ₹${(item.isPaid ? item.paidAmount : item.amount).toStringAsFixed(0)}
Payment Method: ${item.paymentMethod ?? 'Online'}
Date: $dateStr
Status: ${item.isPaid ? 'PAID & VERIFIED' : 'PENDING'}
'''));
                        Navigator.pop(ctx);
                        _showSnackbar(item.isPaid ? "Receipt downloaded & copied to clipboard!" : "Invoice details copied!");
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        item.isPaid ? "Download" : "Copy Info",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003896),
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

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, bool isHighlight = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isHighlight ? 15 : 12.5,
                fontWeight: isHighlight || isBold ? FontWeight.w800 : FontWeight.w600,
                color: isHighlight ? (highlightColor ?? const Color(0xFF16A34A)) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Record payment modal
  void _openRecordPaymentModal(BillModel item) {
    final amountController = TextEditingController(text: item.balance.toStringAsFixed(0));
    final refController = TextEditingController();
    String selectedMode = "UPI / QR Code";
    final List<String> modes = [
      "UPI / QR Code",
      "Cash",
      "Bank Transfer (NEFT/RTGS)",
      "Debit/Credit Card",
      "Cheque",
    ];
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
                              "Invoice: ${item.invoiceNo}",
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
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (selectedStudent == null) {
                                  _showSnackbar("Please search and select a student first", isSuccess: false);
                                  return;
                                }

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
                                    'studentName': student.fullName,
                                    'phone': student.phone,
                                    'building': student.building,
                                    'room': student.room,
                                    'billType': billType,
                                    'billCategory': selectedCategory,
                                    'billingMonth': billName,
                                    'amount': amt,
                                    'paidAmount': 0.0,
                                    'dueDate': Timestamp.fromDate(selectedDueDate),
                                    'status': 'Pending',
                                    'invoiceNo': billId,
                                    'avatarUrl': student.photoUrl ?? '',
                                    'studentEmail': student.email,
                                  });

                                  // 2. Dispatch in-app notification to that student
                                  await FirestoreService().sendStudentNotification(
                                    studentId: student.id,
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
                            : const Icon(Icons.send_rounded, size: 18),
                        label: isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                "Issue Bill & Send Notification",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003896),
                          foregroundColor: Colors.white,
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
            final pendingCount = allBills.where((p) => !p.isPaid && !p.isDefaulter).length;
            final collectedCount = allBills.where((p) => p.isPaid).length;

            final filteredList = _applyFilters(allBills);

            return Column(
              children: [
                // Top Analytics KPI Summary Banner Card (Matching User's Specified Layout)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003D9E), Color(0xFF0056D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0056D2).withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top Row: Total Fees Collected & Total Remaining
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatIndianCurrency(totalCollectedSum),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Total Remaining",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatIndianCurrency(totalPendingSum),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Middle Sub-Card (Hostel Fees vs Utility Bill remaining)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
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
                                        child: Icon(Icons.domain_rounded, size: 15, color: Colors.white70),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Hostel Fees\nremaining",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(alpha: 0.95),
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatIndianCurrency(hostelRemainingSum),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 50,
                              width: 1,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
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
                                        child: Icon(Icons.bolt_rounded, size: 15, color: Colors.white70),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Utility Bill\nremaining",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(alpha: 0.95),
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatIndianCurrency(utilityRemainingSum),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 19,
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
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                      const SizedBox(height: 14),

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
                                    fontSize: 10.5,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "$defaultersCount Past Due",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFFF7676),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.2)),
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
                                      fontSize: 10.5,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatIndianCurrency(defaulterPendingSum),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
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
                          Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Total Bills",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${allBills.length} Active",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
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
                ),

                // Status Tabs (Recent, Defaulters, Pending, Paid)
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 6),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: const Color(0xFF003896),
                    unselectedLabelColor: const Color(0xFF64748B),
                    indicatorColor: const Color(0xFF003896),
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5),
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
                            const Text("Paid"),
                            _buildTabBadge("$collectedCount", const Color(0xFF16A34A)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Filters Bar: Buildings & Types (in one non-scrollable line)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                                fontSize: 12.5,
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
                                fontSize: 12.5,
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
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Bills List View
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEEF2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.payments_outlined, size: 40, color: Color(0xFF003896)),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                allBills.isEmpty ? "No real bills in system yet" : "No matching payment records found",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                allBills.isEmpty
                                    ? "Tap 'Issue Bill' to generate your first invoice."
                                    : "Try adjusting your building or category filters.",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              if (allBills.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _openIssueBillModal,
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                  label: Text(
                                    "Issue First Bill",
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF003896),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ],
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



  Widget _buildPaymentCard(BillModel item) {
    Color statusBg;
    Color statusTextColor;
    String statusLabel;

    if (item.isPaid) {
      statusBg = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF16A34A);
      statusLabel = "Paid";
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
                      const SizedBox(height: 2),
                      Text(
                        item.isPaid
                            ? "Via ${item.paymentMethod ?? 'Online'} (${item.paidDate ?? 'Paid'})"
                            : "Invoice: ${item.invoiceNo}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
            const SizedBox(height: 14),

            // Action buttons per item
            Row(
              children: [
                if (item.isPaid) ...[
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Bill ${bill.invoiceNo} deleted successfully",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF003896),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Text("Delete", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
