import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/expense_bucket_model.dart';
import '../../models/expense_model.dart';
import '../../models/user_role_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_drawer.dart';
import '../../widgets/app_toast.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  final AppUser? currentUser;
  final bool openAddExpenseModal;

  const ExpenseTrackerScreen({
    super.key,
    this.currentUser,
    this.openAddExpenseModal = false,
  });

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedPeriod = 'This Month'; // 'This Month', 'Last Month', 'This Year', 'All Time', 'Custom'
  DateTimeRange? _customDateRange;
  String _selectedBucketId = 'All';
  String _selectedBuilding = 'All Buildings';
  String _searchQuery = '';
  bool _isSearching = false;

  final List<String> _periods = ['This Month', 'Last Month', 'This Year', 'All Time', 'Custom'];
  final List<String> _buildings = [
    'All Buildings',
    'Lakshya',
    'Shivalya',
    'Ishaan',
    'Univ homes',
    'Tirupati',
    'Rameshwaram',
    'Livano',
    'Somnath',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.openAddExpenseModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openExpenseEditorModal();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, {bool isSuccess = true}) {
    AppToast.show(context, msg, isSuccess: isSuccess);
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

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}";
  }

  bool _isDateInPeriod(DateTime date) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Month':
        return date.year == now.year && date.month == now.month;
      case 'Last Month':
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        return date.year == lastMonthDate.year && date.month == lastMonthDate.month;
      case 'This Year':
        return date.year == now.year;
      case 'Custom':
        if (_customDateRange == null) return true;
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
               date.isBefore(end.add(const Duration(seconds: 1)));
      case 'All Time':
      default:
        return true;
    }
  }

  List<ExpenseModel> _filterExpenses(List<ExpenseModel> allExpenses) {
    return allExpenses.where((e) {
      // 1. Period filter
      if (!_isDateInPeriod(e.date)) return false;

      // 2. Bucket filter
      if (_selectedBucketId != 'All' && e.bucketId != _selectedBucketId) {
        return false;
      }

      // 3. Building filter
      if (_selectedBuilding != 'All Buildings' && e.building != _selectedBuilding) {
        return false;
      }

      // 4. Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = e.title.toLowerCase().contains(q);
        final matchPaidTo = e.paidTo.toLowerCase().contains(q);
        final matchNotes = e.notes.toLowerCase().contains(q);
        final matchCategory = e.bucketName.toLowerCase().contains(q);
        return matchTitle || matchPaidTo || matchNotes || matchCategory;
      }

      return true;
    }).toList();
  }

  // =========================================================================
  // MODAL 1: ADD / EDIT EXPENSE
  // =========================================================================
  void _openExpenseEditorModal({ExpenseModel? existing, List<ExpenseBucketModel>? availableBuckets}) {
    final isEditing = existing != null;
    final buckets = (availableBuckets != null && availableBuckets.isNotEmpty)
        ? availableBuckets
        : ExpenseBucketModel.defaultBuckets;

    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '',
    );
    final paidToController = TextEditingController(text: existing?.paidTo ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');

    String selectedBucketId = existing?.bucketId ?? buckets.first.id;
    // ensure selectedBucketId exists in buckets
    if (!buckets.any((b) => b.id == selectedBucketId)) {
      selectedBucketId = buckets.first.id;
    }

    DateTime selectedDate = existing?.date ?? DateTime.now();
    String selectedPaymentMode = existing?.paymentMode ?? 'UPI';
    String selectedBuilding = existing?.building ?? 'All Buildings';

    final paymentModes = ['UPI', 'Cash', 'Bank Transfer', 'Cheque', 'Card'];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentBucket = buckets.firstWhere(
              (b) => b.id == selectedBucketId,
              orElse: () => buckets.first,
            );

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
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
                            isEditing ? Icons.edit_note_rounded : Icons.add_card_rounded,
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
                                isEditing ? "Edit Expense" : "Record New Expense",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                isEditing
                                    ? "Update transaction details"
                                    : "Add an outlay to the expense ledger",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Amount Field
                          _buildInputLabel("Amount (₹) *"),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                            ),
                            child: TextField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Container(
                                  padding: const EdgeInsets.only(left: 14, right: 8),
                                  alignment: Alignment.centerLeft,
                                  width: 42,
                                  child: Text(
                                    "₹",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0D52CE),
                                    ),
                                  ),
                                ),
                                hintText: "0.00",
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w700,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 2. Title Field
                          _buildInputLabel("Expense Title / Purpose *"),
                          TextField(
                            controller: titleController,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: "e.g. Vegetables & Milk for Mess, Generator Diesel",
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13.5,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                          const SizedBox(height: 18),

                          // 3. Category Bucket Selector
                          _buildInputLabel("Expense Bucket / Category *"),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedBucketId,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                                items: buckets.map((bucket) {
                                  return DropdownMenuItem<String>(
                                    value: bucket.id,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: bucket.color.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(bucket.iconData, size: 16, color: bucket.color),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            bucket.name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => selectedBucketId = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 4. Date & Payment Mode Row
                          Row(
                            children: [
                              // Date Picker
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel("Transaction Date *"),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: selectedDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now().add(const Duration(days: 30)),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: const ColorScheme.light(
                                                  primary: Color(0xFF0D52CE),
                                                  onPrimary: Colors.white,
                                                  onSurface: Color(0xFF0F172A),
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          setModalState(() => selectedDate = picked);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0D52CE)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _formatDate(selectedDate),
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
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Payment Mode
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel("Payment Mode"),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedPaymentMode,
                                          isExpanded: true,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                                          items: paymentModes.map((m) {
                                            return DropdownMenuItem<String>(
                                              value: m,
                                              child: Text(
                                                m,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setModalState(() => selectedPaymentMode = val);
                                            }
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

                          // 5. Vendor / Payee & Building
                          Row(
                            children: [
                              // Payee / Vendor
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel("Paid To / Vendor"),
                                    TextField(
                                      controller: paidToController,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "e.g. Ramesh Singh",
                                        hintStyle: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFF94A3B8),
                                          fontSize: 13,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Building
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel("Building"),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedBuilding,
                                          isExpanded: true,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                                          items: _buildings.map((b) {
                                            return DropdownMenuItem<String>(
                                              value: b,
                                              child: Text(
                                                b,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setModalState(() => selectedBuilding = val);
                                            }
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

                          // 6. Notes
                          _buildInputLabel("Notes / Bill Remarks (Optional)"),
                          TextField(
                            controller: notesController,
                            maxLines: 2,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: "Add invoice number, quantity, or specific details...",
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
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
                                    final amtText = amountController.text.trim();
                                    final title = titleController.text.trim();

                                    if (amtText.isEmpty || double.tryParse(amtText) == null) {
                                      _showSnackbar("Please enter a valid amount", isSuccess: false);
                                      return;
                                    }
                                    final amount = double.parse(amtText);
                                    if (amount <= 0) {
                                      _showSnackbar("Amount must be greater than 0", isSuccess: false);
                                      return;
                                    }

                                    if (title.isEmpty) {
                                      _showSnackbar("Please enter an expense title", isSuccess: false);
                                      return;
                                    }

                                    setModalState(() => isSaving = true);

                                    try {
                                      final payload = ExpenseModel(
                                        id: isEditing ? existing.id : '',
                                        title: title,
                                        amount: amount,
                                        bucketId: currentBucket.id,
                                        bucketName: currentBucket.name,
                                        date: selectedDate,
                                        paymentMode: selectedPaymentMode,
                                        paidTo: paidToController.text.trim(),
                                        building: selectedBuilding,
                                        notes: notesController.text.trim(),
                                        recordedBy: widget.currentUser?.fullName ?? 'Admin',
                                        createdAt: existing?.createdAt ?? DateTime.now(),
                                      );

                                      if (isEditing) {
                                        await _firestoreService.updateExpense(existing.id, payload.toMap());
                                        _showSnackbar("Expense updated successfully!");
                                      } else {
                                        await _firestoreService.addExpense(payload);
                                        _showSnackbar("Expense recorded successfully!");
                                      }

                                      if (ctx.mounted) Navigator.pop(ctx);
                                    } catch (e) {
                                      _showSnackbar("Failed to save expense: $e", isSuccess: false);
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
                                    isEditing ? "Save Changes" : "Save Expense",
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
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

  // =========================================================================
  // MODAL 2: MANAGE BUCKETS (CREATE, EDIT, DELETE)
  // =========================================================================
  void _openManageBucketsModal(List<ExpenseBucketModel> buckets, List<ExpenseModel> allExpenses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.category_rounded, color: Color(0xFF0D52CE), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Manage Expense Buckets",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "Create, edit or delete expense categories",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Add New Bucket Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: InkWell(
                      onTap: () {
                        _openBucketEditorDialog(buckets: buckets, onSaved: () {
                          if (mounted) setState(() {});
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF16A34A), size: 22),
                            const SizedBox(width: 12),
                            Text(
                              "Create New Bucket",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF16A34A), size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Buckets List
                  Expanded(
                    child: StreamBuilder<List<ExpenseBucketModel>>(
                      stream: _firestoreService.getExpenseBucketsStream(),
                      initialData: buckets,
                      builder: (context, snapshot) {
                        final liveBuckets = snapshot.data ?? buckets;

                        return ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: liveBuckets.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final b = liveBuckets[idx];
                            // Count expenses under this bucket
                            final bucketExpenses = allExpenses.where((e) => e.bucketId == b.id).toList();
                            final bucketTotal = bucketExpenses.fold(0.0, (acc, e) => acc + e.amount);

                            final isProtectedOthers = b.id == 'bucket_others';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: b.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(b.iconData, color: b.color, size: 22),
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
                                                b.name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            if (b.isDefault) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE2E8F0),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  "DEFAULT",
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${bucketExpenses.length} transactions • ${_formatIndianCurrency(bucketTotal)} total",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                        if (b.description.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            b.description,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Actions: Edit & Delete
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0D52CE)),
                                        tooltip: "Edit Bucket",
                                        onPressed: () {
                                          _openBucketEditorDialog(
                                            existing: b,
                                            buckets: liveBuckets,
                                            onSaved: () {
                                              if (mounted) setState(() {});
                                            },
                                          );
                                        },
                                      ),
                                      if (!isProtectedOthers) ...[
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                                          tooltip: "Delete Bucket",
                                          onPressed: () {
                                            _confirmDeleteBucket(b, bucketExpenses.length);
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
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

  // =========================================================================
  // MODAL 3: CREATE / EDIT BUCKET DIALOG
  // =========================================================================
  void _openBucketEditorDialog({
    ExpenseBucketModel? existing,
    required List<ExpenseBucketModel> buckets,
    required VoidCallback onSaved,
  }) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');

    int selectedColorValue = existing?.colorValue ?? 0xFF10B981;
    String selectedIconKey = existing?.iconKey ?? 'category';

    final paletteColors = [
      0xFF10B981, // Emerald
      0xFFF59E0B, // Amber
      0xFF3B82F6, // Blue
      0xFF06B6D4, // Cyan
      0xFFEF4444, // Red
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
      0xFF14B8A6, // Teal
      0xFF64748B, // Slate
      0xFF84CC16, // Lime
    ];

    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentIconItem = kSupportedBucketIcons.firstWhere(
              (item) => item.key == selectedIconKey,
              orElse: () => const BucketIconItem('category', 'General', Icons.category_rounded),
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(selectedColorValue).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      currentIconItem.icon,
                      color: Color(selectedColorValue),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? "Edit Bucket" : "New Bucket",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 14),

                      // Name
                      _buildInputLabel("Bucket Name *"),
                      TextField(
                        controller: nameController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "e.g. Electricity, Water Supply",
                          hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description
                      _buildInputLabel("Description (Optional)"),
                      TextField(
                        controller: descController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: "Brief purpose of this bucket",
                          hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Color Picker
                      _buildInputLabel("Theme Color"),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: paletteColors.map((c) {
                          final isSelected = selectedColorValue == c;
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedColorValue = c),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: isSelected ? Border.all(color: const Color(0xFF0F172A), width: 2.5) : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Icon Picker
                      _buildInputLabel("Icon Symbol"),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kSupportedBucketIcons.map((item) {
                          final isSelected = selectedIconKey == item.key;
                          return Tooltip(
                            message: item.label,
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedIconKey = item.key),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Color(selectedColorValue).withValues(alpha: 0.2)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? Border.all(color: Color(selectedColorValue), width: 1.8)
                                      : null,
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 20,
                                  color: isSelected ? Color(selectedColorValue) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            _showSnackbar("Please enter a bucket name", isSuccess: false);
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            if (isEditing) {
                              await _firestoreService.updateExpenseBucket(
                                existing.id,
                                {
                                  'name': name,
                                  'description': descController.text.trim(),
                                  'colorValue': selectedColorValue,
                                  'iconKey': selectedIconKey,
                                },
                                oldName: existing.name,
                                newName: name,
                              );
                              _showSnackbar("Bucket '$name' updated!");
                            } else {
                              final newId = "bucket_${DateTime.now().millisecondsSinceEpoch}";
                              final newBucket = ExpenseBucketModel(
                                id: newId,
                                name: name,
                                description: descController.text.trim(),
                                colorValue: selectedColorValue,
                                iconKey: selectedIconKey,
                                isDefault: false,
                              );
                              await _firestoreService.addExpenseBucket(newBucket);
                              _showSnackbar("New bucket '$name' created!");
                            }

                            onSaved();
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          } catch (e) {
                            _showSnackbar("Error saving bucket: $e", isSuccess: false);
                          } finally {
                            if (mounted) setDialogState(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D52CE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? "Save" : "Create Bucket",
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // CONFIRM DELETE BUCKET
  // =========================================================================
  void _confirmDeleteBucket(ExpenseBucketModel bucket, int expenseCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete '${bucket.name}' Bucket?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to delete this expense category?",
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF334155)),
            ),
            if (expenseCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "$expenseCount active expense(s) under this bucket will safely be re-allocated to the 'others' bucket.",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestoreService.deleteExpenseBucket(bucket.id);
                _showSnackbar("Bucket deleted successfully");
              } catch (e) {
                _showSnackbar("Failed to delete bucket: $e", isSuccess: false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
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

  // =========================================================================
  // CONFIRM DELETE EXPENSE
  // =========================================================================
  void _confirmDeleteExpense(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Expense Entry?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          "Are you sure you want to delete '${expense.title}' for ${_formatIndianCurrency(expense.amount)}? This action cannot be undone.",
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestoreService.deleteExpense(expense.id);
                _showSnackbar("Expense removed from ledger");
              } catch (e) {
                _showSnackbar("Failed to delete expense: $e", isSuccess: false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
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

  // =========================================================================
  // VIEW EXPENSE DETAILS MODAL
  // =========================================================================
  void _viewExpenseDetails(ExpenseModel expense, ExpenseBucketModel? bucket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (bucket?.color ?? const Color(0xFF0D52CE)).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                bucket?.iconData ?? Icons.receipt_long_rounded,
                color: bucket?.color ?? const Color(0xFF0D52CE),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    expense.bucketName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: bucket?.color ?? const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 14),
            _buildDetailRow("Amount", _formatIndianCurrency(expense.amount), isBold: true, highlightColor: const Color(0xFFEF4444)),
            _buildDetailRow("Date", _formatDate(expense.date)),
            _buildDetailRow("Payment Mode", expense.paymentMode),
            if (expense.paidTo.isNotEmpty) _buildDetailRow("Paid To", expense.paidTo),
            if (expense.building.isNotEmpty) _buildDetailRow("Building", expense.building),
            if (expense.recordedBy.isNotEmpty) _buildDetailRow("Recorded By", expense.recordedBy),
            if (expense.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Notes:",
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  expense.notes,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E293B)),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Close",
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _openExpenseEditorModal(existing: expense);
            },
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text("Edit", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D52CE),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: highlightColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  // =========================================================================
  // MAIN BUILD METHOD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      drawer: AdminDrawer(activeItem: "Expense Tracker", currentUser: widget.currentUser),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Expense Tracker",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              "Outlays & Category Buckets",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: const Color(0xFF0F172A),
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),

      // FAB for recording new expense
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseEditorModal(),
        backgroundColor: const Color(0xFF0D52CE),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          "Add Expense",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),

      body: StreamBuilder<List<ExpenseBucketModel>>(
        stream: _firestoreService.getExpenseBucketsStream(),
        builder: (context, bucketSnap) {
          final buckets = bucketSnap.data ?? ExpenseBucketModel.defaultBuckets;

          return StreamBuilder<List<ExpenseModel>>(
            stream: _firestoreService.getExpensesStream(),
            builder: (context, expenseSnap) {
              if (expenseSnap.connectionState == ConnectionState.waiting && !expenseSnap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0D52CE)),
                );
              }

              final allExpenses = expenseSnap.data ?? <ExpenseModel>[];
              final filteredExpenses = _filterExpenses(allExpenses);

              // Financial Calculations for the active period
              final periodExpenses = allExpenses.where((e) => _isDateInPeriod(e.date)).toList();
              final totalPeriodSpent = periodExpenses.fold(0.0, (acc, e) => acc + e.amount);

              // Bucket spending aggregation
              final Map<String, double> bucketSpending = {};
              final Map<String, int> bucketTxCounts = {};
              for (final e in periodExpenses) {
                bucketSpending[e.bucketId] = (bucketSpending[e.bucketId] ?? 0.0) + e.amount;
                bucketTxCounts[e.bucketId] = (bucketTxCounts[e.bucketId] ?? 0) + 1;
              }

              // Identify top spending category
              String topBucketName = "None";
              double topBucketAmount = 0.0;
              for (final entry in bucketSpending.entries) {
                if (entry.value > topBucketAmount) {
                  topBucketAmount = entry.value;
                  final match = buckets.firstWhere(
                    (b) => b.id == entry.key,
                    orElse: () => ExpenseBucketModel(
                      id: entry.key,
                      name: 'others',
                      iconKey: 'category',
                      colorValue: 0xFF64748B,
                    ),
                  );
                  topBucketName = match.name;
                }
              }

              return CustomScrollView(
                slivers: [
                  // 1. Search Bar (if activated)
                  if (_isSearching)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: InputDecoration(
                              hintText: "Search by title, vendor, or notes...",
                              hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13.5),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 2. Period & Manage Buckets Header Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          // Period Selector
                          Expanded(
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedPeriod,
                                  isExpanded: true,
                                  icon: const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF0D52CE)),
                                  items: _periods.map((p) {
                                    return DropdownMenuItem<String>(
                                      value: p,
                                      child: Text(
                                        p == 'Custom' && _customDateRange != null
                                            ? "${_formatDate(_customDateRange!.start)} - ${_formatDate(_customDateRange!.end)}"
                                            : p,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) async {
                                    if (val == 'Custom') {
                                      final picked = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now().add(const Duration(days: 30)),
                                        initialDateRange: _customDateRange ??
                                            DateTimeRange(
                                              start: DateTime.now().subtract(const Duration(days: 30)),
                                              end: DateTime.now(),
                                            ),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _customDateRange = picked;
                                          _selectedPeriod = 'Custom';
                                        });
                                      }
                                    } else if (val != null) {
                                      setState(() => _selectedPeriod = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Manage Buckets Button
                          InkWell(
                            onTap: () => _openManageBucketsModal(buckets, allExpenses),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0D52CE)),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Buckets",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
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
                    ),
                  ),

                  // 3. Financial Summary KPI Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Total Spent
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
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
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.arrow_upward_rounded, size: 16, color: Color(0xFFEF4444)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Total Outlay",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _formatIndianCurrency(totalPeriodSpent),
                                      maxLines: 1,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${periodExpenses.length} transactions",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Top Expense Category
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
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
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.pie_chart_rounded, size: 16, color: Color(0xFFD97706)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Top Bucket",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    topBucketName,
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
                                    topBucketAmount > 0
                                        ? "${_formatIndianCurrency(topBucketAmount)} (${(topBucketAmount / (totalPeriodSpent > 0 ? totalPeriodSpent : 1) * 100).toStringAsFixed(0)}%)"
                                        : "No expenses",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. "How much money is getting where": Category Spending Breakdown Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF0D52CE)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Spending Breakdown",
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
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _selectedPeriod,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            if (totalPeriodSpent == 0) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: Text(
                                    "No expenses recorded for $_selectedPeriod",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              ...buckets.map((b) {
                                final spent = bucketSpending[b.id] ?? 0.0;
                                final percent = totalPeriodSpent > 0 ? (spent / totalPeriodSpent) : 0.0;
                                final isSelected = _selectedBucketId == b.id;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedBucketId = isSelected ? 'All' : b.id;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: b.color.withValues(alpha: 0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(b.iconData, size: 14, color: b.color),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                b.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  color: isSelected ? const Color(0xFF0D52CE) : const Color(0xFF1E293B),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatIndianCurrency(spent),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: b.color.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "${(percent * 100).toStringAsFixed(1)}%",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: b.color,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: percent,
                                            backgroundColor: const Color(0xFFF1F5F9),
                                            color: b.color,
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 5. Category Filter Pills
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: buckets.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            if (idx == 0) {
                              final isSelected = _selectedBucketId == 'All';
                              return ChoiceChip(
                                label: Text(
                                  "All Buckets",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF0D52CE),
                                backgroundColor: Colors.white,
                                side: BorderSide(color: isSelected ? const Color(0xFF0D52CE) : const Color(0xFFE2E8F0)),
                                onSelected: (val) => setState(() => _selectedBucketId = 'All'),
                              );
                            }

                            final b = buckets[idx - 1];
                            final isSelected = _selectedBucketId == b.id;

                            return ChoiceChip(
                              avatar: Icon(b.iconData, size: 14, color: isSelected ? Colors.white : b.color),
                              label: Text(
                                b.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: b.color,
                              backgroundColor: Colors.white,
                              side: BorderSide(color: isSelected ? b.color : const Color(0xFFE2E8F0)),
                              onSelected: (val) => setState(() => _selectedBucketId = isSelected ? 'All' : b.id),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // 6. Building Filter & Transaction Count Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Transactions (${filteredExpenses.length})",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Building Filter Dropdown
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBuilding,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                                items: _buildings.map((b) {
                                  return DropdownMenuItem<String>(value: b, child: Text(b));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedBuilding = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 7. Transaction Cards List
                  if (filteredExpenses.isEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 40,
                                  color: Color(0xFF0D52CE),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No expenses found",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? "No transactions match '$_searchQuery'"
                                    : "No records found for the selected bucket or time period.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: () => _openExpenseEditorModal(availableBuckets: buckets),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: Text(
                                  "Record First Expense",
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D52CE),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) {
                            final expense = filteredExpenses[idx];
                            final bucket = buckets.firstWhere(
                              (b) => b.id == expense.bucketId,
                              orElse: () => ExpenseBucketModel(
                                id: expense.bucketId,
                                name: expense.bucketName,
                                iconKey: 'category',
                                colorValue: 0xFF64748B,
                              ),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => _viewExpenseDetails(expense, bucket),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Category Icon Circle
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: bucket.color.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(bucket.iconData, color: bucket.color, size: 20),
                                      ),
                                      const SizedBox(width: 12),

                                      // Expense Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              expense.title,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // Badges Row
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                // Category Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: bucket.color.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    expense.bucketName,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: bucket.color,
                                                    ),
                                                  ),
                                                ),

                                                // Payment Mode
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    expense.paymentMode,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: const Color(0xFF475569),
                                                    ),
                                                  ),
                                                ),

                                                // Building (if specific)
                                                if (expense.building != 'All Buildings') ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEDE9FE),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      expense.building,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: const Color(0xFF6D28D9),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),

                                            const SizedBox(height: 6),
                                            // Payee & Date
                                            Row(
                                              children: [
                                                if (expense.paidTo.isNotEmpty) ...[
                                                  Flexible(
                                                    child: Text(
                                                      "To: ${expense.paidTo}",
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w500,
                                                        color: const Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    " • ",
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 11.5,
                                                      color: const Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                ],
                                                Text(
                                                  _formatDate(expense.date),
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Amount & Action
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _formatIndianCurrency(expense.amount),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFFEF4444),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                                            padding: EdgeInsets.zero,
                                            onSelected: (action) {
                                              if (action == 'edit') {
                                                _openExpenseEditorModal(existing: expense, availableBuckets: buckets);
                                              } else if (action == 'delete') {
                                                _confirmDeleteExpense(expense);
                                              } else if (action == 'view') {
                                                _viewExpenseDetails(expense, bucket);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'view',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.visibility_outlined, size: 16),
                                                    SizedBox(width: 8),
                                                    Text("View Details"),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined, size: 16),
                                                    SizedBox(width: 8),
                                                    Text("Edit"),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                                    SizedBox(width: 8),
                                                    Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                                  ],
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
                          },
                          childCount: filteredExpenses.length,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
