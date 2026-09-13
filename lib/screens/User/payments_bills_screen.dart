import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/bill_model.dart';
import '../../models/user_role_model.dart';
import '../../services/firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../config/cloudinary_config.dart';
import '../../widgets/document_viewer_modal.dart';
import '../../widgets/user_drawer.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'user_home_screen.dart';

class PaymentsBillsScreen extends StatefulWidget {
  final String? studentId;
  final AppUser? currentUser;

  const PaymentsBillsScreen({
    super.key,
    this.studentId,
    this.currentUser,
  });

  @override
  State<PaymentsBillsScreen> createState() => _PaymentsBillsScreenState();
}

class _PaymentsBillsScreenState extends State<PaymentsBillsScreen> {
  String _activeTab = "To Be Paid"; // "To Be Paid" or "Paid Bills"
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (widget.currentUser != null) {
      if (mounted) {
        setState(() {
          _user = widget.currentUser;
        });
      }
      return;
    }

    try {
      final appUser = await FirebaseAuthService().getCurrentAppUser();
      if (mounted) {
        setState(() {
          _user = appUser;
        });
      }
    } catch (_) {}
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

  IconData _getBillIcon(BillModel bill) {
    final lower = "${bill.billType} ${bill.billingMonth}".toLowerCase();
    if (lower.contains('electricity') || lower.contains('power')) {
      return Icons.bolt_rounded;
    } else if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi_rounded;
    } else if (lower.contains('mess') || lower.contains('food') || lower.contains('dining')) {
      return Icons.restaurant_rounded;
    } else if (lower.contains('deposit') || lower.contains('security')) {
      return Icons.shield_rounded;
    } else if (lower.contains('cleaning') || lower.contains('maintenance')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.home_rounded;
  }

  void _viewFullScreenImage(String imageUrl, {Uint8List? memoryBytes, String? fileName}) {
    DocumentViewerModal.show(
      context,
      url: imageUrl,
      title: "Payment Receipt / Proof",
      memoryBytes: memoryBytes,
      fileName: fileName,
    );
  }

  void _openPaymentModal(BillModel bill) {
    // 3 Options: "Bank transfer", "UPI", "Cash"
    String selectedMethod = "UPI";
    if (bill.paymentMethod != null && bill.paymentMethod!.isNotEmpty) {
      final pm = bill.paymentMethod!.toLowerCase();
      if (pm.contains('bank')) {
        selectedMethod = "Bank transfer";
      } else if (pm.contains('cash')) {
        selectedMethod = "Cash";
      } else {
        selectedMethod = "UPI";
      }
    }

    final utrController = TextEditingController(text: bill.utrNumber ?? bill.transactionRef ?? '');
    final remarksController = TextEditingController(text: bill.paymentRemarks ?? '');
    Uint8List? pickedProofBytes;
    bool pickedProofIsPdf = false;
    String? pickedProofFileName;
    String? currentProofUrl = bill.proofUrl;
    bool isSubmitting = false;
    String submittingText = "Submitting...";

    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickImage(ImageSource source) async {
            try {
              final file = await picker.pickImage(
                source: source,
                maxWidth: 1600,
                maxHeight: 1600,
                imageQuality: 85,
              );
              if (file != null) {
                final bytes = await file.readAsBytes();
                setModalState(() {
                  pickedProofBytes = bytes;
                  pickedProofIsPdf = false;
                  pickedProofFileName = file.name;
                });
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text("Error picking image: $e"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          }

          Future<void> pickPdf() async {
            try {
              final file = await FilePicker.pickFile(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (file != null) {
                final bytes = await file.readAsBytes();
                setModalState(() {
                  pickedProofBytes = bytes;
                  pickedProofIsPdf = true;
                  pickedProofFileName = file.name;
                });
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text("Error picking PDF: $e"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          }

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  const SizedBox(height: 18),

                  // Verification In Progress Banner (if already submitted)
                  if (bill.isPendingVerification) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Verification In Progress (${bill.paymentMethod ?? 'Submitted'})",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bill.isCash
                                      ? "Cash handover reported. Administration will verify physical cash and approve."
                                      : "Proof submitted (Ref: ${bill.utrNumber ?? bill.transactionRef ?? 'Uploaded'}). Administration is reviewing.",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Previous Admin Rejection Note (if any)
                  if (bill.status == 'Pending' && bill.adminRemarks != null && bill.adminRemarks!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Administration Note",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bill.adminRemarks!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: const Color(0xFFB91C1C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Bill Header & Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.billingMonth.isNotEmpty ? bill.billingMonth : bill.billType,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Due: ${_formatDate(bill.dueDate)} • Invoice: ${bill.invoiceNo}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatIndianCurrency(bill.balance),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. Official Hostel Bank & UPI Details Card
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
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.account_balance_rounded, color: Color(0xFF2563EB), size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Official Hostel Bank & UPI Details",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentInfoRow("Account Name", "Lakshya Student Residences"),
                        const SizedBox(height: 6),
                        _buildPaymentInfoRow("Bank Name", "ICICI Bank"),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Account Number",
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                            Row(
                              children: [
                                Text(
                                  "002105018921",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(const ClipboardData(text: "002105018921"));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Account number copied!"), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "IFSC Code",
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                            Row(
                              children: [
                                Text(
                                  "ICIC0000021",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(const ClipboardData(text: "ICIC0000021"));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("IFSC code copied!"), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hostel UPI ID",
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                                  ),
                                  Text(
                                    "lakshyastays@icici",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(const ClipboardData(text: "lakshyastays@icici"));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("UPI ID copied to clipboard!"),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
                              label: Text(
                                "Copy UPI",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Instructions Notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Please transfer or hand over the exact fee amount through your preferred method, then select the method below and submit proof to notify administration.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF1E40AF),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Payment Method: Three Radio Buttons
                  Text(
                    "Select Payment Method",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: selectedMethod,
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedMethod = val);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          // Radio 1: Bank transfer
                          InkWell(
                            onTap: () => setModalState(() => selectedMethod = "Bank transfer"),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                children: [
                                  const Radio<String>(
                                    value: "Bank transfer",
                                    activeColor: Color(0xFF2563EB),
                                  ),
                                  const Icon(Icons.account_balance_rounded, size: 18, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Bank transfer",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: selectedMethod == "Bank transfer" ? FontWeight.w800 : FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (selectedMethod == "Bank transfer")
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 18),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          // Radio 2: UPI
                          InkWell(
                            onTap: () => setModalState(() => selectedMethod = "UPI"),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                children: [
                                  const Radio<String>(
                                    value: "UPI",
                                    activeColor: Color(0xFF2563EB),
                                  ),
                                  const Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "UPI",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: selectedMethod == "UPI" ? FontWeight.w800 : FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (selectedMethod == "UPI")
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 18),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          // Radio 3: Cash
                          InkWell(
                            onTap: () => setModalState(() => selectedMethod = "Cash"),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                children: [
                                  const Radio<String>(
                                    value: "Cash",
                                    activeColor: Color(0xFF16A34A),
                                  ),
                                  const Icon(Icons.payments_rounded, size: 18, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Cash",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: selectedMethod == "Cash" ? FontWeight.w800 : FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (selectedMethod == "Cash")
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Dynamic Fields based on selection
                  if (selectedMethod == "UPI") ...[
                    // UPI Transaction ID / UTR (Optional)
                    Text(
                      "UPI Transaction ID / UTR Number (Optional)",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: utrController,
                      decoration: InputDecoration(
                        hintText: "e.g. 423489123456 (12-digit UPI UTR)",
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF2563EB), size: 18),
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
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (selectedMethod == "Bank transfer" || selectedMethod == "UPI") ...[
                    // Screenshot Upload Section
                    Text(
                      "Attach Payment Proof Screenshot",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedMethod == "Bank transfer"
                          ? "Upload a screenshot of your bank transfer receipt for admin verification."
                          : "Upload a screenshot of your UPI payment receipt for admin verification.",
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),

                    // Screenshot Preview or Picker Buttons
                    if (pickedProofBytes != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _viewFullScreenImage(
                                "",
                                memoryBytes: pickedProofBytes,
                                fileName: pickedProofFileName,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: pickedProofIsPdf
                                    ? Container(
                                        width: 60,
                                        height: 60,
                                        color: const Color(0xFFFEF2F2),
                                        child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 28),
                                      )
                                    : Image.memory(
                                        pickedProofBytes!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pickedProofFileName ?? (pickedProofIsPdf ? "payment_receipt.pdf" : "receipt.jpg"),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Tap thumbnail to preview full screen",
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              tooltip: "Remove proof",
                              onPressed: () {
                                setModalState(() {
                                  pickedProofBytes = null;
                                  pickedProofIsPdf = false;
                                  pickedProofFileName = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ] else if (currentProofUrl != null && currentProofUrl.isNotEmpty) ...[
                      Builder(builder: (context) {
                        final bool isCurrentPdf = CloudinaryService.isPdf(currentProofUrl);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _viewFullScreenImage(currentProofUrl),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: isCurrentPdf
                                      ? Container(
                                          width: 60,
                                          height: 60,
                                          color: const Color(0xFFFEF2F2),
                                          child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 28),
                                        )
                                      : Image.network(
                                          currentProofUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCurrentPdf ? "Previously Uploaded PDF Receipt" : "Previously Uploaded Proof",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Tap thumbnail to preview",
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF2563EB)),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => pickImage(ImageSource.gallery),
                                child: Text(
                                  "Replace",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined, size: 16),
                              label: Text(
                                "Gallery",
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(color: Color(0xFF93C5FD)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined, size: 16),
                              label: Text(
                                "Camera",
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickPdf,
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                              label: Text(
                                "PDF File",
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFECACA)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    // CASH PAYMENT SECTION
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
                              const Icon(Icons.payments_rounded, color: Color(0xFF16A34A), size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Cash Handover Process",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF14532D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "1. Hand over ${_formatIndianCurrency(bill.balance)} directly to the Lakshya Hostel Administration / Warden Office.\n2. Update your payment status here.\n3. The administrator will inspect the cash and approve your payment in the system.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF166534),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      "Cash Handover Details / Note",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: remarksController,
                      decoration: InputDecoration(
                        hintText: "e.g. Handed cash to Warden / Manager on ${DateTime.now().day}/${DateTime.now().month}",
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.receipt_outlined, color: Color(0xFF16A34A), size: 18),
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
                          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional cash receipt photo
                    if (pickedProofBytes != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(pickedProofBytes!, width: 44, height: 44, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Optional paper slip attached",
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => setModalState(() {
                                pickedProofBytes = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      TextButton.icon(
                        onPressed: () => pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                        label: Text(
                          "Attach physical receipt slip (Optional)",
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF16A34A),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 22),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final utr = utrController.text.trim();
                              final remarks = remarksController.text.trim();

                              // Validation
                              if (selectedMethod == "Bank transfer") {
                                if (pickedProofBytes == null && (currentProofUrl == null || currentProofUrl.isEmpty)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Please attach a screenshot or PDF of your bank transfer receipt.",
                                        style: GoogleFonts.plusJakartaSans(),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                              } else if (selectedMethod == "UPI") {
                                if (utr.isEmpty && pickedProofBytes == null && (currentProofUrl == null || currentProofUrl.isEmpty)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Please upload a screenshot or PDF of your payment receipt.",
                                        style: GoogleFonts.plusJakartaSans(),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                              } else {
                                if (remarks.isEmpty) {
                                  remarksController.text = "Handed cash to hostel office";
                                }
                              }

                              setModalState(() {
                                isSubmitting = true;
                                submittingText = pickedProofBytes != null ? "Uploading proof to cloud..." : "Submitting...";
                              });

                              try {
                                String? finalProofUrl = currentProofUrl;
                                if (pickedProofBytes != null) {
                                  final uploaded = await CloudinaryService.uploadBytes(
                                    pickedProofBytes!,
                                    fileName: pickedProofFileName ?? (pickedProofIsPdf ? "payment_receipt.pdf" : "receipt.jpg"),
                                    folder: CloudinaryConfig.folderPaymentReceipts,
                                  );
                                  if (uploaded != null) {
                                    finalProofUrl = uploaded;
                                  }
                                }

                                setModalState(() => submittingText = "Updating bill status...");

                                await FirestoreService().submitBillPaymentProof(
                                  billId: bill.id,
                                  paymentMode: selectedMethod,
                                  utrNumber: utr.isNotEmpty ? utr : (selectedMethod == "Cash" ? "CASH-HANDOVER" : null),
                                  proofUrl: finalProofUrl,
                                  remarks: remarksController.text.trim(),
                                );

                                if (!context.mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      selectedMethod == "Cash"
                                          ? "Cash handover updated! Administration will verify physical cash and approve."
                                          : "Payment proof submitted successfully! Administration will verify shortly.",
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Submission failed: $e", style: GoogleFonts.plusJakartaSans()),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        isSubmitting
                            ? submittingText
                            : (selectedMethod == "Cash"
                                ? (bill.isPendingVerification ? "Update Cash Handover" : "Submit Cash Payment")
                                : (bill.isPendingVerification ? "Update Payment Proof" : "Submit Payment Proof")),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedMethod == "Cash" ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        "Close",
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
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

  Widget _buildPaymentInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  void _openReceiptDialog(BillModel item) {
    final receiptNo = item.transactionRef ?? item.invoiceNo;
    final dateStr = item.paidDate != null && item.paidDate!.isNotEmpty
        ? item.paidDate!
        : _formatDate(item.createdAt);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Official Stamp Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                "Fee Cleared Reward Voucher",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                "Lakshya Student Residences",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Reward Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFF16A34A), size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Resident In Good Standing • Zero Outstanding Dues",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildPaymentInfoRow("Receipt No", receiptNo),
                    const SizedBox(height: 8),
                    _buildPaymentInfoRow("Invoice No", item.invoiceNo),
                    const SizedBox(height: 8),
                    _buildPaymentInfoRow("Date Paid", dateStr),
                    const SizedBox(height: 8),
                    _buildPaymentInfoRow("Bill Type", item.billType),
                    if (item.billingMonth.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildPaymentInfoRow("Period", item.billingMonth),
                    ],
                    if (item.paymentMethod != null && item.paymentMethod!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildPaymentInfoRow("Payment Mode", item.paymentMethod!),
                    ],
                    if (item.adminRemarks != null && item.adminRemarks!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildPaymentInfoRow("Verification Note", item.adminRemarks!),
                    ],
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Paid",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _formatIndianCurrency(item.paidAmount > 0 ? item.paidAmount : item.amount),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (item.proofUrl != null && item.proofUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _viewFullScreenImage(item.proofUrl!),
                    icon: const Icon(Icons.image_outlined, size: 16),
                    label: Text(
                      "View Attached Payment Proof",
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    "Close Receipt",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBackToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => UserHomeScreen(currentUser: _user ?? widget.currentUser)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStudentId = widget.studentId ??
        _user?.studentId ??
        _user?.uid ??
        FirebaseAuthService().currentUser?.uid ??
        '';

    final effectivePhone = _user?.phone;
    final effectiveEmail = _user?.email ?? widget.currentUser?.email;
    final effectiveRegNo = _user?.registrationNumber ?? widget.currentUser?.registrationNumber;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackToHome();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: UserDrawer(activeItem: "Payments & Bills", currentUser: _user ?? widget.currentUser),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
            tooltip: "Back to Home",
            onPressed: _handleBackToHome,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF1A65D6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Payments & Bills",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    _user != null && _user!.building != null
                        ? "${_user!.building} • Rm ${_user!.room ?? ''}"
                        : "Resident Portal",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getStudentNotificationsStream(
                effectiveStudentId,
                building: _user?.building ?? widget.currentUser?.building,
                regNo: effectiveRegNo,
              ),
              builder: (context, notifSnapshot) {
                final notifs = notifSnapshot.data ?? [];
                final unreadCount = notifs.where((n) => n['isRead'] != true).length;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsScreen(currentUser: _user ?? widget.currentUser),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? "9+" : "$unreadCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(currentUser: _user ?? widget.currentUser)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8, left: 4),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    _user != null && _user!.fullName.isNotEmpty
                        ? _user!.fullName.substring(0, 1).toUpperCase()
                        : "SU",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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
        body: SafeArea(
          child: StreamBuilder<List<BillModel>>(
            stream: FirestoreService().getStudentBillsStream(
              effectiveStudentId,
              phone: effectivePhone,
              email: effectiveEmail,
              regNo: effectiveRegNo,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                );
              }

            final allBills = snapshot.data ?? [];
            final pendingBills = allBills.where((b) => !b.isPaid).toList();
            final paidBills = allBills.where((b) => b.isPaid).toList();

            final totalOutstanding = pendingBills.fold(0.0, (acc, b) => acc + b.balance);
            final totalPaid = paidBills.fold(0.0, (acc, b) => acc + b.paidAmount);
            final overdueSum = pendingBills.where((b) => b.isDefaulter).fold(0.0, (acc, b) => acc + b.balance);
            final paidReceiptsCount = paidBills.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Dynamic Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "HOSTEL FEES & PAYMENTS",
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: pendingBills.isNotEmpty
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                pendingBills.isNotEmpty
                                    ? "${pendingBills.length} Pending ${pendingBills.length == 1 ? 'Due' : 'Dues'}"
                                    : "All Dues Cleared",
                                style: GoogleFonts.plusJakartaSans(
                                  color: pendingBills.isNotEmpty ? const Color(0xFFFCA5A5) : const Color(0xFF34D399),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _formatIndianCurrency(totalOutstanding),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Total Outstanding Payable Amount",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, thickness: 1),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Paid Dues
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _formatIndianCurrency(totalPaid),
                                            style: GoogleFonts.plusJakartaSans(
                                              color: const Color(0xFF10B981),
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Paid Dues",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(width: 8),
                            // Overdue Dues
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _formatIndianCurrency(overdueSum),
                                            style: GoogleFonts.plusJakartaSans(
                                              color: const Color(0xFFEF4444),
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Overdue Dues",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(width: 8),
                            // Paid Receipts
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.receipt_long_rounded, color: Color(0xFF3B82F6), size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "$paidReceiptsCount",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFF3B82F6),
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Paid Receipts",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 24),

                  // Segmented Tab Bar Switcher
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        // To Be Paid Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = "To Be Paid"),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _activeTab == "To Be Paid" ? const Color(0xFF2563EB) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "To Be Paid",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: _activeTab == "To Be Paid" ? Colors.white : const Color(0xFF64748B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _activeTab == "To Be Paid"
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : (pendingBills.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "${pendingBills.length}",
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Paid Bills Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = "Paid Bills"),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _activeTab == "Paid Bills" ? const Color(0xFF2563EB) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Paid Bills",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: _activeTab == "Paid Bills" ? Colors.white : const Color(0xFF64748B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _activeTab == "Paid Bills"
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : const Color(0xFFD1FAE5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "${paidBills.length}",
                                      style: GoogleFonts.plusJakartaSans(
                                        color: _activeTab == "Paid Bills" ? Colors.white : const Color(0xFF065F46),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
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

                  // Bills List
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _activeTab == "To Be Paid"
                        ? _buildPendingList(pendingBills)
                        : _buildPaidList(paidBills),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

  Widget _buildPendingList(List<BillModel> bills) {
    if (bills.isEmpty) {
      return Container(
        key: const ValueKey("empty_pending_list"),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              "No Pending Bills",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "All your hostel and utility dues are completely cleared. You are all caught up!",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey("pending_list"),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        final isOverdue = bill.isDefaulter;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverdue ? const Color(0xFFFECACA) : const Color(0xFFF1F5F9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getBillIcon(bill),
                        color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.billingMonth.isNotEmpty ? bill.billingMonth : bill.billType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  bill.billType,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF2563EB),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                "Due: ${_formatDate(bill.dueDate)}",
                                style: GoogleFonts.plusJakartaSans(
                                  color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w600,
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
                          _formatIndianCurrency(bill.balance),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bill.isPendingVerification
                                ? const Color(0xFFFEF3C7)
                                : (isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bill.isPendingVerification
                                ? "Pending Verification"
                                : (isOverdue ? "Overdue" : "Upcoming"),
                            style: GoogleFonts.plusJakartaSans(
                              color: bill.isPendingVerification
                                  ? const Color(0xFFD97706)
                                  : (isOverdue ? const Color(0xFFDC2626) : const Color(0xFF2563EB)),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        bill.isPendingVerification
                            ? "UTR: ${bill.utrNumber ?? bill.transactionRef ?? 'Submitted'}"
                            : (isOverdue ? "Immediate Action" : "To Be Paid"),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: bill.isPendingVerification
                              ? const Color(0xFFD97706)
                              : (isOverdue ? const Color(0xFFDC2626) : const Color(0xFFEF4444)),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _openPaymentModal(bill),
                      icon: Icon(
                        bill.isPendingVerification ? Icons.edit_note_rounded : Icons.credit_card_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: Text(
                        bill.isPendingVerification ? "Update UTR / Proof" : "Pay / Submit Proof",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bill.isPendingVerification
                            ? const Color(0xFFD97706)
                            : const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
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

  Widget _buildPaidList(List<BillModel> bills) {
    if (bills.isEmpty) {
      return Container(
        key: const ValueKey("empty_paid_list"),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              "No Paid Bills Yet",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Your completed payments and official digital receipts will be archived here.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey("paid_list"),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        final dateStr = bill.paidDate != null && bill.paidDate!.isNotEmpty
            ? bill.paidDate!
            : _formatDate(bill.createdAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getBillIcon(bill),
                        color: const Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.billingMonth.isNotEmpty ? bill.billingMonth : bill.billType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  bill.billType,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF2563EB),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                "Paid on: $dateStr",
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
                          _formatIndianCurrency(bill.paidAmount > 0 ? bill.paidAmount : bill.amount),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Paid",
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF065F46),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Paid Successfully",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openReceiptDialog(bill),
                      icon: const Icon(Icons.download_rounded, size: 14, color: Color(0xFF64748B)),
                      label: Text(
                        "Receipt",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        backgroundColor: Colors.white,
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
}
