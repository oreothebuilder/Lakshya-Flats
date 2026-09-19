import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Data bundle for generating a personalized Lakshya Residency Payment Receipt PDF
class PaymentReceiptData {
  final String receiptNo;
  final String billIssueDate; // The day admin/owner confirms the payment
  final String payeeName;
  final String contactNumber;
  final String email;
  final String buildingAddress;
  final String roomAndBed;
  final String paymentType; // e.g. "Installment 1 / Hostel Fees", "Electricity Bill"
  final String paymentMethod; // e.g. "UPI", "Bank transfer", "Cash"
  final double amount;
  final String deadline; // Due Date
  final String paidOn; // The day user paid and submitted for approval
  final String paymentStatus; // "PAID"
  final String? transactionRef;
  final String? adminRemarks;

  PaymentReceiptData({
    required this.receiptNo,
    required this.billIssueDate,
    required this.payeeName,
    required this.contactNumber,
    required this.email,
    required this.buildingAddress,
    required this.roomAndBed,
    required this.paymentType,
    required this.paymentMethod,
    required this.amount,
    required this.deadline,
    required this.paidOn,
    this.paymentStatus = "PAID",
    this.transactionRef,
    this.adminRemarks,
  });
}

/// Generates the official, legally compliant single-page Payment Receipt PDF
/// matching the exact header and footer vector design of the Rent Agreement.
class PaymentReceiptPdfService {
  // Theme Colors matching AgreementPdfService
  static final PdfColor primaryNavy = PdfColor(31, 56, 100);
  static final PdfColor accentMagenta = PdfColor(255, 0, 157);
  static final PdfColor textDark = PdfColor(15, 23, 42);
  static final PdfColor textMuted = PdfColor(71, 85, 105);
  static final PdfColor borderGrey = PdfColor(226, 232, 240);
  static final PdfColor cardBg = PdfColor(248, 250, 252);
  static final PdfColor greenBg = PdfColor(240, 253, 244);
  static final PdfColor greenText = PdfColor(22, 101, 52);
  static final PdfColor greenBorder = PdfColor(187, 247, 208);

  static PdfBitmap? _cachedLogoBitmap;
  static PdfBitmap? _cachedSignatureBitmap;

  /// Load the logo from assets
  static Future<Uint8List?> loadLogoAsset() async {
    try {
      final ByteData byteData = await rootBundle.load('assets/images/lakshya_logo.jpg');
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint("Could not load logo asset: $e");
      return null;
    }
  }

  /// Load the authorized signature from assets
  static Future<Uint8List?> loadSignatureAsset() async {
    try {
      final ByteData byteData = await rootBundle.load('assets/images/authorised_signature.jpg');
      return byteData.buffer.asUint8List();
    } catch (e) {
      try {
        final ByteData byteData = await rootBundle.load('assets/images/owner_signature.jpg');
        return byteData.buffer.asUint8List();
      } catch (_) {
        return null;
      }
    }
  }

  /// Generates the complete 1-page Payment Receipt PDF
  static Future<Uint8List> generateReceiptPdf(PaymentReceiptData data) async {
    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 36;
    document.pageSettings.size = PdfPageSize.a4;

    if (_cachedLogoBitmap == null) {
      final Uint8List? logoBytes = await loadLogoAsset();
      if (logoBytes != null && logoBytes.isNotEmpty) {
        try {
          _cachedLogoBitmap = PdfBitmap(logoBytes);
        } catch (e) {
          debugPrint("Error creating PdfBitmap for logo: $e");
        }
      }
    }

    if (_cachedSignatureBitmap == null) {
      final Uint8List? sigBytes = await loadSignatureAsset();
      if (sigBytes != null && sigBytes.isNotEmpty) {
        try {
          _cachedSignatureBitmap = PdfBitmap(sigBytes);
        } catch (e) {
          debugPrint("Error creating PdfBitmap for signature: $e");
        }
      }
    }

    // Standard fonts
    final PdfFont regular8 = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final PdfFont bold8 = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);
    final PdfFont bold9 = PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold);
    final PdfFont bold10 = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    final PdfFont bold14 = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    final PdfFont italic8 = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.italic);

    final PdfPage page = document.pages.add();

    // 1. Draw Exact Rent Agreement Header
    _drawPageHeader(page, data.billIssueDate);

    // 2. Draw Receipt Body
    double y = 82;

    // Title: PAYMENT RECEIPT - LAKSHYA RESIDENCY
    page.graphics.drawString(
      "PAYMENT RECEIPT - LAKSHYA RESIDENCY",
      bold14,
      brush: PdfSolidBrush(primaryNavy),
      bounds: const Rect.fromLTWH(0, 82, 523, 18),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    y += 20;

    // Verified badge banner
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(greenBg),
      pen: PdfPen(greenBorder, width: 1),
      bounds: Rect.fromLTWH(0, y, 523, 26),
    );
    page.graphics.drawString(
      "OFFICIAL RECEIPT  •  STATUS: ${data.paymentStatus.toUpperCase()}  •  RECEIPT NO: ${data.receiptNo}",
      bold9,
      brush: PdfSolidBrush(greenText),
      bounds: Rect.fromLTWH(0, y + 6, 523, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    y += 34;

    // SECTION 1: TWO COLUMNS (TENANT DETAILS & PAYMENT RECIPIENT)
    const double colW = 255;
    const double colGap = 13;

    // Left Box: TENANT DETAILS
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(cardBg),
      pen: PdfPen(borderGrey, width: 1),
      bounds: Rect.fromLTWH(0, y, colW, 116),
    );
    // Header banner inside left box
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(241, 245, 249)),
      bounds: Rect.fromLTWH(0, y, colW, 20),
    );
    page.graphics.drawString(
      "TENANT DETAILS",
      bold8,
      brush: PdfSolidBrush(primaryNavy),
      bounds: Rect.fromLTWH(8, y + 4.5, colW - 16, 12),
    );

    double ly = y + 26;
    _drawKVRow(page, "Payee Name:", data.payeeName.isNotEmpty ? data.payeeName : "Student", 0, ly, colW, bold8, regular8);
    ly += 17;
    _drawKVRow(page, "Contact No:", data.contactNumber.isNotEmpty ? data.contactNumber : "On file", 0, ly, colW, bold8, regular8);
    ly += 17;
    _drawKVRow(page, "Email:", data.email.isNotEmpty ? data.email : "On file", 0, ly, colW, bold8, regular8);
    ly += 17;
    _drawKVRow(page, "Building:", data.buildingAddress.isNotEmpty ? data.buildingAddress : "Lakshya Residency", 0, ly, colW, bold8, regular8);
    ly += 17;
    _drawKVRow(page, "Room & Bed:", data.roomAndBed.isNotEmpty ? data.roomAndBed : "Assigned", 0, ly, colW, bold8, regular8);

    // Right Box: PAYMENT RECIPIENT
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(cardBg),
      pen: PdfPen(borderGrey, width: 1),
      bounds: Rect.fromLTWH(colW + colGap, y, colW, 116),
    );
    // Header banner inside right box
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(241, 245, 249)),
      bounds: Rect.fromLTWH(colW + colGap, y, colW, 20),
    );
    page.graphics.drawString(
      "PAYMENT RECIPIENT",
      bold8,
      brush: PdfSolidBrush(primaryNavy),
      bounds: Rect.fromLTWH(colW + colGap + 8, y + 4.5, colW - 16, 12),
    );

    double ry = y + 26;
    _drawKVRow(page, "Organisation:", "Lakshya residency", colW + colGap, ry, colW, bold8, regular8);
    ry += 17;
    _drawKVRow(page, "Managed by:", "Ajay singh", colW + colGap, ry, colW, bold8, regular8);
    ry += 17;
    _drawKVRow(page, "Mail:", "lakshyaresidency@gmail.com", colW + colGap, ry, colW, bold8, regular8);
    ry += 17;
    _drawKVRow(page, "Phone number:", "+91 97840 70543", colW + colGap, ry, colW, bold8, regular8);
    ry += 17;
    _drawKVRow(page, "Website:", "www.lakshyaresidency.com", colW + colGap, ry, colW, bold8, regular8);

    y += 126;

    // SECTION 2: PAYMENT DETAILS (Table Grid)
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(cardBg),
      pen: PdfPen(borderGrey, width: 1),
      bounds: Rect.fromLTWH(0, y, 523, 184),
    );
    // Header banner
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(241, 245, 249)),
      bounds: Rect.fromLTWH(0, y, 523, 22),
    );
    page.graphics.drawString(
      "PAYMENT DETAILS",
      bold9,
      brush: PdfSolidBrush(primaryNavy),
      bounds: Rect.fromLTWH(10, y + 5, 500, 14),
    );

    double py = y + 28;
    _drawFullKVRow(page, "Receipt Number", data.receiptNo, py, bold9, bold9, isHighlightVal: true);
    py += 17;
    _drawFullKVRow(page, "Bill Issue Date", data.billIssueDate, py, bold8, regular8);
    py += 17;
    _drawFullKVRow(page, "Payment Type", data.paymentType, py, bold8, regular8);
    py += 17;
    _drawFullKVRow(page, "Payment Method Used", data.paymentMethod, py, bold8, regular8);
    py += 17;
    if (data.transactionRef != null && data.transactionRef!.isNotEmpty) {
      _drawFullKVRow(page, "Transaction Ref / UTR", data.transactionRef!, py, bold8, regular8);
      py += 17;
    }
    _drawFullKVRow(page, "Deadline (Due Date)", data.deadline, py, bold8, regular8);
    py += 17;
    _drawFullKVRow(page, "Paid On", data.paidOn, py, bold8, regular8);
    py += 17;
    _drawFullKVRow(page, "Payment Status", data.paymentStatus, py, bold9, bold9, isHighlightVal: true);
    py += 18;

    // Total Amount Box inside Payment Details
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(239, 246, 255)),
      pen: PdfPen(PdfColor(191, 219, 254), width: 1),
      bounds: Rect.fromLTWH(10, py, 503, 26),
    );
    page.graphics.drawString(
      "TOTAL AMOUNT PAID",
      bold10,
      brush: PdfSolidBrush(primaryNavy),
      bounds: Rect.fromLTWH(20, py + 6, 200, 16),
    );
    page.graphics.drawString(
      "Rs. ${data.amount.toStringAsFixed(0)}",
      bold14,
      brush: PdfSolidBrush(primaryNavy),
      bounds: Rect.fromLTWH(300, py + 4, 200, 18),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    y += 194;

    // SECTION 3: TERMS AND CONDITIONS
    page.graphics.drawString(
      "TERMS AND CONDITIONS",
      bold9,
      brush: PdfSolidBrush(textDark),
      bounds: Rect.fromLTWH(0, y, 523, 14),
    );
    y += 16;

    final List<String> terms = [
      "This receipt serves as an acknowledgement of the payment made by the tenant through the applicable payment method for the services/charges mentioned above.",
      "In case an online payment fails or is unsuccessful, this receipt shall be considered null and void.",
      "No refund, adjustment, or discount shall be entertained against this receipt.",
    ];

    for (final term in terms) {
      page.graphics.drawString(
        "•  $term",
        regular8,
        brush: PdfSolidBrush(textMuted),
        bounds: Rect.fromLTWH(0, y, 523, 18),
      );
      y += 15;
    }

    y += 8;

    // Draw Authorized Signature Image if available
    if (_cachedSignatureBitmap != null) {
      page.graphics.drawImage(
        _cachedSignatureBitmap!,
        Rect.fromLTWH(395, y, 95, 34),
      );
      y += 36;
    } else {
      y += 20;
    }

    // Divider line above Authorised Signatory
    page.graphics.drawLine(
      PdfPen(borderGrey, width: 1),
      Offset(370, y),
      Offset(510, y),
    );
    y += 5;

    // Signatures / Seal row
    page.graphics.drawString(
      "Authorised Signatory",
      bold9,
      brush: PdfSolidBrush(textDark),
      bounds: Rect.fromLTWH(360, y, 163, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    page.graphics.drawString(
      "Lakshya Residency Management",
      italic8,
      brush: PdfSolidBrush(textMuted),
      bounds: Rect.fromLTWH(360, y + 14, 163, 12),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // 3. Draw Exact Rent Agreement Footer
    _drawPageFooter(page);

    final List<int> bytes = document.saveSync();
    document.dispose();
    return Uint8List.fromList(bytes);
  }

  static void _drawKVRow(
    PdfPage page,
    String key,
    String val,
    double x,
    double y,
    double w,
    PdfFont keyFont,
    PdfFont valFont,
  ) {
    page.graphics.drawString(
      key,
      keyFont,
      brush: PdfSolidBrush(textDark),
      bounds: Rect.fromLTWH(x + 8, y, 80, 14),
    );
    page.graphics.drawString(
      val,
      valFont,
      brush: PdfSolidBrush(textDark),
      bounds: Rect.fromLTWH(x + 90, y, w - 98, 14),
    );
  }

  static void _drawFullKVRow(
    PdfPage page,
    String key,
    String val,
    double y,
    PdfFont keyFont,
    PdfFont valFont, {
    bool isHighlightVal = false,
  }) {
    page.graphics.drawString(
      key,
      keyFont,
      brush: PdfSolidBrush(textDark),
      bounds: Rect.fromLTWH(12, y, 180, 14),
    );
    page.graphics.drawString(
      val,
      valFont,
      brush: PdfSolidBrush(isHighlightVal ? primaryNavy : textDark),
      bounds: Rect.fromLTWH(200, y, 311, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
  }

  // =========================================================================
  // EXACT VECTOR HEADER FROM RENT AGREEMENT
  // =========================================================================
  static void _drawPageHeader(PdfPage page, String dateStr) {
    const double x0 = -36.0;
    const double y0 = -36.0;
    const double x1 = 559.32;

    // 1. Top Navy Blue Polygon (#1F3864)
    final List<Offset> topNavyPoly = [
      const Offset(x0 + 52.67, y0),
      const Offset(x0 + 60.62, y0 + 8.24),
      const Offset(x0 + 70.36, y0 + 17.51),
      const Offset(x0 + 81.76, y0 + 26.68),
      const Offset(x0 + 94.70, y0 + 34.61),
      const Offset(x0 + 109.05, y0 + 40.97),
      const Offset(x0 + 124.67, y0 + 45.43),
      const Offset(x0 + 141.43, y0 + 48.09),
      const Offset(x0 + 159.20, y0 + 49.52),
      const Offset(x0 + 176.10, y0 + 50.50),
      const Offset(x1, y0 + 50.50),
      const Offset(x1, y0),
    ];
    page.graphics.drawPolygon(
      topNavyPoly,
      brush: PdfSolidBrush(PdfColor(31, 56, 100)),
    );

    // 2. Lakshya Logo (Under the curve on the left)
    if (_cachedLogoBitmap != null) {
      page.graphics.drawImage(_cachedLogoBitmap!, const Rect.fromLTWH(24.75, 20.3, 82.2, 50.4));
    } else {
      page.graphics.drawString(
        "Lakshya",
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(31, 56, 100)),
        bounds: const Rect.fromLTWH(24.75, 25, 120, 16),
      );
      page.graphics.drawString(
        "Residency",
        PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(textDark),
        bounds: const Rect.fromLTWH(24.75, 42, 120, 14),
      );
    }

    // 3. Founder Details (Right Aligned)
    final PdfFont fontFounder = PdfStandardFont(PdfFontFamily.helvetica, 8.5);
    final PdfFont boldFounder = PdfStandardFont(PdfFontFamily.helvetica, 8.5, style: PdfFontStyle.bold);

    page.graphics.drawString(
      "Founder: Ajay Singh",
      boldFounder,
      brush: PdfSolidBrush(textDark),
      bounds: const Rect.fromLTWH(200, 28, 287.4, 11),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
    page.graphics.drawString(
      "Mail: lakshyaresidency@gmail.com",
      fontFounder,
      brush: PdfSolidBrush(textDark),
      bounds: const Rect.fromLTWH(200, 40, 287.4, 11),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
    page.graphics.drawString(
      "Website: www.lakshyaresidency.com",
      fontFounder,
      brush: PdfSolidBrush(PdfColor(5, 99, 193)),
      bounds: const Rect.fromLTWH(200, 52, 287.4, 11),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
    // Underline for website
    page.graphics.drawLine(
      PdfPen(PdfColor(5, 99, 193), width: 0.5),
      const Offset(365, 63),
      const Offset(487.4, 63),
    );
    page.graphics.drawString(
      "Phone number: +91 97840 70543",
      fontFounder,
      brush: PdfSolidBrush(textDark),
      bounds: const Rect.fromLTWH(200, 64, 287.4, 11),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    // Vertical Magenta Line to the right of Founder text
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(accentMagenta),
      bounds: const Rect.fromLTWH(491.5, 27, 2.8, 48.0),
    );

    // 4. Horizontal Magenta Line across page
    page.graphics.drawLine(
      PdfPen(accentMagenta, width: 1.5),
      const Offset(x0, 76.5),
      const Offset(x0 + 348.0, 76.5),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(accentMagenta),
      bounds: Rect.fromLTWH(x0 + 348.0, 75.0, x1 - (x0 + 348.0), 3.5),
    );

    // 5. Date & GST row
    final PdfFont fontDate = PdfStandardFont(PdfFontFamily.helvetica, 9);
    final PdfFont boldGST = PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold);

    page.graphics.drawString("Date: $dateStr", fontDate, brush: PdfSolidBrush(textDark), bounds: const Rect.fromLTWH(0, 85, 250, 14));
    page.graphics.drawString(
      "GST: 08DYPPK8554R1Z4",
      boldGST,
      brush: PdfSolidBrush(textDark),
      bounds: const Rect.fromLTWH(200, 85, 523.4 - 36, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
  }

  // =========================================================================
  // EXACT VECTOR FOOTER FROM RENT AGREEMENT
  // =========================================================================
  static void _drawPageFooter(PdfPage page) {
    const double x0 = -36.0;
    const double yBot = 805.92;
    const double flatY = yBot - 44.02;

    final List<Offset> bottomNavyPoly = [
      const Offset(x0, flatY),
      const Offset(x0 + 412.47, flatY),
      const Offset(x0 + 433.00, flatY + 0.70),
      const Offset(x0 + 453.00, flatY + 3.20),
      const Offset(x0 + 472.00, flatY + 8.10),
      const Offset(x0 + 490.00, flatY + 15.60),
      const Offset(x0 + 506.00, flatY + 25.50),
      const Offset(x0 + 520.00, flatY + 37.00),
      const Offset(x0 + 531.19, yBot),
      const Offset(x0, yBot),
    ];

    page.graphics.drawPolygon(
      bottomNavyPoly,
      brush: PdfSolidBrush(PdfColor(31, 56, 100)),
    );

    final PdfFont fontFooter = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.italic);
    page.graphics.drawString(
      "Lakshya Residency • Official Digital Payment Receipt",
      fontFooter,
      brush: PdfSolidBrush(textMuted),
      bounds: const Rect.fromLTWH(0, flatY - 14, 487.4, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
  }
}
