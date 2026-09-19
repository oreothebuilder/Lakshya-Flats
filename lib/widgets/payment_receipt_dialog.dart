import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bill_model.dart';
import '../models/student_profile_model.dart';
import '../services/firestore_service.dart';
import '../services/payment_receipt_pdf_service.dart';
import '../services/platform_file_saver.dart';
import '../widgets/document_viewer_modal.dart';
import 'app_toast.dart';

/// Modal dialog for reviewing and downloading the Lakshya Residency
/// Official Payment Receipt matching the exact Rent Agreement header and footer branding.
class PaymentReceiptDialog extends StatefulWidget {
  final PaymentReceiptData receiptData;

  const PaymentReceiptDialog({
    super.key,
    required this.receiptData,
  });

  /// Convenient static launcher that extracts details from BillModel and optional StudentProfile
  static Future<void> show(
    BuildContext context, {
    required BillModel bill,
    StudentProfile? studentProfile,
  }) async {
    // If studentProfile not provided, try to fetch to get bed number & email
    StudentProfile? profile = studentProfile;
    if (profile == null && bill.studentId.isNotEmpty) {
      try {
        final doc = await FirestoreService().getStudentProfile(bill.studentId);
        if (doc.exists) {
          profile = StudentProfile.fromFirestore(doc);
        }
      } catch (_) {}
    }

    final String receiptNo = (bill.receiptNo != null && bill.receiptNo!.trim().isNotEmpty)
        ? bill.receiptNo!.trim()
        : (bill.transactionRef != null && bill.transactionRef!.trim().isNotEmpty)
            ? bill.transactionRef!.trim()
            : bill.invoiceNo;

    final String billIssueDate = bill.receiptIssuedAt != null
        ? _formatDate(bill.receiptIssuedAt!)
        : (bill.paidDate != null && bill.paidDate!.isNotEmpty)
            ? bill.paidDate!
            : _formatDate(DateTime.now());

    final String paidOnDate = bill.submittedAt != null
        ? _formatDate(bill.submittedAt!)
        : (bill.paidDate != null && bill.paidDate!.isNotEmpty)
            ? bill.paidDate!
            : _formatDate(bill.createdAt);

    final String roomAndBed = [
      if (bill.room.isNotEmpty) "Room ${bill.room}",
      if ((bill.bed != null && bill.bed!.isNotEmpty))
        "Bed ${bill.bed}"
      else if (profile != null && profile.bedNumber.isNotEmpty)
        "Bed ${profile.bedNumber}"
      else
        "Bed Assigned",
    ].join(" • ");

    final data = PaymentReceiptData(
      receiptNo: receiptNo,
      billIssueDate: billIssueDate,
      payeeName: bill.studentName.isNotEmpty ? bill.studentName : (profile?.fullName ?? "Tenant"),
      contactNumber: bill.phone.isNotEmpty ? bill.phone : (profile?.phone ?? "On File"),
      email: (bill.studentEmail != null && bill.studentEmail!.isNotEmpty)
          ? bill.studentEmail!
          : (profile?.email ?? "On File"),
      buildingAddress: "Lakshya Residency, Building ${bill.building}",
      roomAndBed: roomAndBed,
      paymentType: (bill.billingMonth.isNotEmpty && bill.billingMonth != bill.billType)
          ? "${bill.billType} (${bill.billingMonth})"
          : bill.billType,
      paymentMethod: bill.paymentMethod ?? (bill.isCash ? "Cash Handover" : "UPI / Online"),
      amount: bill.paidAmount > 0 ? bill.paidAmount : bill.amount,
      deadline: _formatDate(bill.dueDate),
      paidOn: paidOnDate,
      paymentStatus: "PAID",
      transactionRef: bill.transactionRef,
      adminRemarks: bill.adminRemarks,
    );

    if (!context.mounted) return;
    final isMobile = MediaQuery.of(context).size.width < 700;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 24,
          vertical: isMobile ? 8 : 16,
        ),
        backgroundColor: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 18),
        ),
        child: PaymentReceiptDialog(receiptData: data),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}";
  }

  @override
  State<PaymentReceiptDialog> createState() => _PaymentReceiptDialogState();
}

class _PaymentReceiptDialogState extends State<PaymentReceiptDialog> {
  bool _isDownloadingPdf = false;
  bool _isSharingPdf = false;

  void _openFullPdfViewer(Uint8List pdfBytes, String filename) {
    if (!mounted) return;
    DocumentViewerModal.show(
      context,
      url: "",
      title: "Payment Receipt - ${widget.receiptData.receiptNo}",
      memoryBytes: pdfBytes,
      fileName: filename,
    );
  }

  Future<void> _handleDownloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    try {
      final pdfBytes = await PaymentReceiptPdfService.generateReceiptPdf(widget.receiptData);
      final filename = "Payment_Receipt_${widget.receiptData.receiptNo}.pdf";

      await saveAndLaunchFile(pdfBytes, filename);
      if (mounted) {
        AppToast.showSuccess(context, "Receipt PDF saved to Downloads");
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, "Failed to download PDF: $e");
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  Future<void> _handleSharePdf() async {
    setState(() => _isSharingPdf = true);
    try {
      final pdfBytes = await PaymentReceiptPdfService.generateReceiptPdf(widget.receiptData);
      final filename = "Payment_Receipt_${widget.receiptData.receiptNo}.pdf";
      await shareFileOrBytes(
        filename,
        pdfBytes,
        subject: "Payment Receipt - ${widget.receiptData.receiptNo}",
        text: "Official Payment Receipt for ${widget.receiptData.payeeName} (Receipt No: ${widget.receiptData.receiptNo})",
      );
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, "Failed to share PDF: $e");
      }
    } finally {
      if (mounted) setState(() => _isSharingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.receiptData;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return SizedBox(
      width: 780,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Modal Action Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF1F3864)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMobile ? "Payment Receipt" : "Official Payment Receipt",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFF1F3864)),
                  tooltip: "View Full PDF Bill",
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final pdfBytes = await PaymentReceiptPdfService.generateReceiptPdf(widget.receiptData);
                    final filename = "Payment_Receipt_${widget.receiptData.receiptNo}.pdf";
                    _openFullPdfViewer(pdfBytes, filename);
                  },
                ),
                IconButton(
                  icon: _isSharingPdf
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F3864)),
                        )
                      : const Icon(Icons.share_rounded, size: 18, color: Color(0xFF1F3864)),
                  onPressed: _isSharingPdf ? null : _handleSharePdf,
                  tooltip: "Share / Export PDF",
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: _isDownloadingPdf ? null : _handleDownloadPdf,
                  icon: _isDownloadingPdf
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download_rounded, size: 15),
                  label: Text(
                    _isDownloadingPdf ? "..." : (isMobile ? "PDF" : "Download PDF"),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F3864),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  tooltip: "Close",
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Scrollable Receipt Body
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. EXACT VECTOR HEADER FROM RENT AGREEMENT
                  _buildExactPdfHeader(d.billIssueDate),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 28, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // TITLE
                        Center(
                          child: Text(
                            "PAYMENT RECEIPT - LAKSHYA RESIDENCY",
                            style: GoogleFonts.merriweather(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: const Color(0xFF1F3864),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Green Status Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "OFFICIAL RECEIPT  •  STATUS: ${d.paymentStatus.toUpperCase()}  •  RECEIPT NO: ${d.receiptNo}",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: isMobile ? 10.5 : 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF15803D),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // TWO COLUMNS: TENANT DETAILS & PAYMENT RECIPIENT
                        if (isMobile) ...[
                          _buildTenantDetailsCard(d),
                          const SizedBox(height: 14),
                          _buildRecipientDetailsCard(),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildTenantDetailsCard(d)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildRecipientDetailsCard()),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),

                        // PAYMENT DETAILS CARD
                        _buildPaymentDetailsCard(d),
                        const SizedBox(height: 20),

                        // TERMS AND CONDITIONS
                        _buildTermsAndConditionsCard(),
                        const SizedBox(height: 20),

                        // Authorised Signatory Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/authorised_signature.jpg',
                                  width: 115,
                                  height: 48,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    'assets/images/owner_signature.jpg',
                                    width: 115,
                                    height: 48,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => const SizedBox(height: 32),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 140,
                                  height: 1,
                                  color: const Color(0xFFCBD5E1),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Authorised Signatory",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  "Lakshya Residency Management",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  // 2. EXACT VECTOR FOOTER FROM RENT AGREEMENT
                  _buildExactPdfFooter(),
                ],
              ),
            ),
          ),

          // Sticky Bottom Action Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final pdfBytes = await PaymentReceiptPdfService.generateReceiptPdf(widget.receiptData);
                    final filename = "Payment_Receipt_${widget.receiptData.receiptNo}.pdf";
                    _openFullPdfViewer(pdfBytes, filename);
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: Text(
                    isMobile ? "Preview" : "Preview Bill",
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F3864),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isSharingPdf ? null : _handleSharePdf,
                  icon: _isSharingPdf
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F3864)),
                        )
                      : const Icon(Icons.share_rounded, size: 16),
                  label: Text(
                    isMobile ? "Share" : "Share",
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F3864),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloadingPdf ? null : _handleDownloadPdf,
                    icon: _isDownloadingPdf
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded, size: 17),
                    label: Text(
                      _isDownloadingPdf
                          ? "Downloading..."
                          : (isMobile ? "Download PDF" : "Download Official PDF"),
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F3864),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BODY SECTION CARDS
  // =========================================================================

  Widget _buildTenantDetailsCard(PaymentReceiptData d) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              "TENANT DETAILS",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F3864),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildInfoRow("Payee Name", d.payeeName, isBoldVal: true),
                _buildInfoRow("Contact No", d.contactNumber),
                _buildInfoRow("Email", d.email),
                _buildInfoRow("Building", d.buildingAddress),
                _buildInfoRow("Room & Bed", d.roomAndBed, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              "PAYMENT RECIPIENT",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F3864),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildInfoRow("Organisation", "Lakshya residency", isBoldVal: true),
                _buildInfoRow("Managed by", "Ajay singh"),
                _buildInfoRow("Mail", "lakshyaresidency@gmail.com"),
                _buildInfoRow("Phone number", "+91 97840 70543"),
                _buildInfoRow("Website", "www.lakshyaresidency.com", isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard(PaymentReceiptData d) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              "PAYMENT DETAILS",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F3864),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildInfoRow("Receipt Number", d.receiptNo, isBoldVal: true, isHighlightVal: true),
                _buildInfoRow("Bill Issue Date", d.billIssueDate),
                _buildInfoRow("Payment Type", d.paymentType),
                _buildInfoRow("Payment Method", d.paymentMethod),
                if (d.transactionRef != null && d.transactionRef!.isNotEmpty)
                  _buildInfoRow("Transaction Ref / UTR", d.transactionRef!),
                _buildInfoRow("Deadline (Due Date)", d.deadline),
                _buildInfoRow("Paid On", d.paidOn),
                _buildInfoRow("Payment Status", d.paymentStatus, isBoldVal: true, isHighlightVal: true),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TOTAL AMOUNT PAID",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        "₹${d.amount.toStringAsFixed(0)}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditionsCard() {
    final terms = [
      "This receipt serves as an acknowledgement of the payment made by the tenant through the applicable payment method for the services/charges mentioned above.",
      "In case an online payment fails or is unsuccessful, this receipt shall be considered null and void.",
      "No refund, adjustment, or discount shall be entertained against this receipt.",
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TERMS AND CONDITIONS",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          for (final term in terms)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                  Expanded(
                    child: Text(
                      term,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String key,
    String val, {
    bool isBoldVal = false,
    bool isHighlightVal = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isBoldVal ? FontWeight.w700 : FontWeight.w500,
                color: isHighlightVal
                    ? const Color(0xFF1F3864)
                    : (isBoldVal ? const Color(0xFF0F172A) : const Color(0xFF334155)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // EXACT VECTOR HEADER MATCHING RENT AGREEMENT
  // =========================================================================
  Widget _buildExactPdfHeader(String dateStr) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double scale = w / 595.32;
        final double h = w * (138.0 / 595.32);

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Top Navy Blue Polygon (#1F3864)
              Positioned.fill(
                child: CustomPaint(
                  painter: _TopHeaderNavyPainter(),
                ),
              ),

              // 2. Lakshya Logo (Under curve on left)
              Positioned(
                left: 55.0 * scale,
                top: 48.0 * scale,
                width: 95.0 * scale,
                height: 56.0 * scale,
                child: Image.asset(
                  'assets/images/lakshya_logo.jpg',
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  errorBuilder: (context, error, stackTrace) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Lakshya",
                        style: GoogleFonts.merriweather(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F3864),
                        ),
                      ),
                      Text(
                        "Residency",
                        style: GoogleFonts.merriweather(
                          fontSize: 10 * scale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Founder Details (Right aligned)
              Positioned(
                right: (595.32 - 523.4 + 10.0) * scale,
                top: 54.0 * scale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Founder: ",
                            style: GoogleFonts.roboto(
                              fontSize: 9.5 * scale,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          TextSpan(
                            text: "Ajay Singh",
                            style: GoogleFonts.roboto(
                              fontSize: 9.5 * scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.5 * scale),
                    Text(
                      "Mail: lakshyaresidency@gmail.com",
                      style: GoogleFonts.roboto(
                        fontSize: 9.0 * scale,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 1.5 * scale),
                    Text(
                      "Website: www.lakshyaresidency.com",
                      style: GoogleFonts.roboto(
                        fontSize: 9.0 * scale,
                        color: const Color(0xFF0563C1),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    SizedBox(height: 1.5 * scale),
                    Text(
                      "Phone number: +91 97840 70543",
                      style: GoogleFonts.roboto(
                        fontSize: 9.0 * scale,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Vertical Magenta Bar
              Positioned(
                right: (595.32 - 529.3) * scale,
                top: 56.0 * scale,
                width: 3.2 * scale,
                height: 48.0 * scale,
                child: Container(color: const Color(0xFFFF009D)),
              ),

              // 5. Horizontal Magenta Line across page
              Positioned(
                left: 0,
                right: 0,
                top: 112.5 * scale,
                child: Row(
                  children: [
                    Expanded(
                      flex: 348,
                      child: Container(
                        height: 1.5 * scale,
                        color: const Color(0xFFFF009D),
                      ),
                    ),
                    Expanded(
                      flex: (595.32 - 348).round(),
                      child: Container(
                        height: 3.5 * scale,
                        color: const Color(0xFFFF009D),
                      ),
                    ),
                  ],
                ),
              ),

              // 6. Date & GST row
              Positioned(
                left: 55.0 * scale,
                right: (595.32 - 523.4) * scale,
                top: 121.0 * scale,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Date: ",
                            style: GoogleFonts.roboto(
                              fontSize: 10.0 * scale,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          TextSpan(
                            text: dateStr,
                            style: GoogleFonts.roboto(
                              fontSize: 10.0 * scale,
                              fontWeight: FontWeight.normal,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "GST: 08DYPPK8554R1Z4",
                      style: GoogleFonts.roboto(
                        fontSize: 10.0 * scale,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
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

  // =========================================================================
  // EXACT VECTOR FOOTER MATCHING RENT AGREEMENT
  // =========================================================================
  Widget _buildExactPdfFooter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double scale = w / 595.32;
        final double h = 54.0 * scale;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BottomFooterNavyPainter(),
                ),
              ),
              Positioned(
                right: (595.32 - 487.4) * scale,
                bottom: 8 * scale,
                child: Text(
                  "Lakshya Residency • Official Digital Payment Receipt",
                  style: GoogleFonts.roboto(
                    fontSize: 8.5 * scale,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// VECTOR PAINTERS
// =============================================================================

class _TopHeaderNavyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F3864)
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double scale = w / 595.32;

    final double xStart = 52.67 * scale;
    final double flatH = 50.50 * scale;
    final double xFlat = 176.10 * scale;

    final path = Path();
    path.moveTo(xStart, 0);

    path.cubicTo(
      84.44 * scale,
      31.23 * scale,
      128.02 * scale,
      50.50 * scale,
      xFlat,
      flatH,
    );

    path.lineTo(w, flatH);
    path.lineTo(w, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomFooterNavyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F3864)
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;
    final double scale = w / 595.32;

    final double flatY = h - (44.02 * scale);
    final double xFlat = 412.47 * scale;
    final double xEnd = 531.19 * scale;

    final path = Path();
    path.moveTo(0, flatY);
    path.lineTo(xFlat, flatY);

    path.cubicTo(
      457.83 * scale,
      flatY,
      499.31 * scale,
      h - (27.43 * scale),
      xEnd,
      h,
    );

    path.lineTo(0, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
