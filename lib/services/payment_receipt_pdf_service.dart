import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Data bundle for generating a personalized Lakshya Residency Payment Receipt & Bill PDF
class PaymentReceiptData {
  final String receiptNo;
  final String billIssueDate; // Date formatted for display or header
  final String payeeName;
  final String contactNumber;
  final String email;
  final String buildingAddress;
  final String roomAndBed;
  final String paymentType; // e.g. "Hostel Rent", "Mess Bill", "Electricity Bill"
  final String paymentMethod; // e.g. "UPI", "Bank transfer", "Cash"
  final double amount;
  final String deadline; // Due Date
  final String paidOn; // The day user paid, or "Pending Payment"
  final String paymentStatus; // "PAID", "PENDING", "DEFAULTER"
  final String? transactionRef;
  final String? adminRemarks;

  // Enriched bill fields
  final String billTitle; // Title of the bill fetched from the app
  final String billInformedDate; // Date the bill was informed / issued
  final double baseAmount; // Base bill amount
  final double defaulterAmount; // Defaulter amount (0 by default, added if any)
  final double totalAmount; // baseAmount + defaulterAmount
  final double paidAmount; // Amount paid
  final double balanceAmount; // Balance due
  final bool isPaid;
  final bool isDefaulter;
  final int daysOverdue;
  final String headerDate; // Date shown on the letterhead: dd/mm/yyyy

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
    String? billTitle,
    String? billInformedDate,
    double? baseAmount,
    this.defaulterAmount = 0.0,
    double? totalAmount,
    double? paidAmount,
    double? balanceAmount,
    bool? isPaid,
    bool? isDefaulter,
    this.daysOverdue = 0,
    String? headerDate,
  })  : billTitle = (billTitle != null && billTitle.trim().isNotEmpty) ? billTitle : paymentType,
        billInformedDate = (billInformedDate != null && billInformedDate.trim().isNotEmpty) ? billInformedDate : billIssueDate,
        baseAmount = baseAmount ?? amount,
        totalAmount = totalAmount ?? (amount + defaulterAmount),
        paidAmount = paidAmount ?? (paymentStatus.toUpperCase() == "PAID" ? (amount + defaulterAmount) : 0.0),
        balanceAmount = balanceAmount ??
            ((totalAmount ?? (amount + defaulterAmount)) -
                    (paidAmount ?? (paymentStatus.toUpperCase() == "PAID" ? (amount + defaulterAmount) : 0.0)))
                .clamp(0.0, double.infinity),
        isPaid = isPaid ?? (paymentStatus.toUpperCase() == "PAID"),
        isDefaulter = isDefaulter ?? (paymentStatus.toUpperCase().contains("DEFAULTER")),
        headerDate = headerDate ?? billIssueDate;
}

/// Generates the official, legally compliant single-page Payment Receipt & Bill PDF
/// matching the exact header and footer vector design of the official Lakshya Residency letterhead.
class PaymentReceiptPdfService {
  // Theme Colors matching Lakshya Residency letterhead
  static final PdfColor primaryNavy = PdfColor(31, 56, 100);
  static final PdfColor accentMagenta = PdfColor(255, 0, 157);
  static final PdfColor textDark = PdfColor(15, 23, 42);
  static final PdfColor textMuted = PdfColor(71, 85, 105);
  static final PdfColor borderGrey = PdfColor(226, 232, 240);
  static final PdfColor cardBg = PdfColor(248, 250, 252);
  static final PdfColor greenBg = PdfColor(240, 253, 244);
  static final PdfColor greenText = PdfColor(22, 101, 52);
  static final PdfColor greenBorder = PdfColor(187, 247, 208);
  static final PdfColor alertBg = PdfColor(254, 242, 242);
  static final PdfColor alertBorder = PdfColor(254, 202, 202);
  static final PdfColor headerGrey = PdfColor(241, 245, 249);
  static final PdfColor blueBg = PdfColor(239, 246, 255);
  static final PdfColor blueBorder = PdfColor(191, 219, 254);
  static final PdfColor redText = PdfColor(220, 38, 38);

  static PdfBitmap? _cachedLogoBitmap;
  static PdfBitmap? _cachedSignatureBitmap;

  /// Load the logo from assets
  static Future<Uint8List?> loadLogoAsset() async {
    try {
      final ByteData byteData = await rootBundle.load('assets/images/lakshya_logo.png');
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

  /// Generates the complete 1-page Payment Receipt & Bill PDF on the letterhead
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
    final PdfFont bold13 = PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold);
    final PdfFont bold14 = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    final PdfFont italic8 = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.italic);

    final PdfPage page = document.pages.add();

    // 1. Draw Exact Letterhead Vector Header with Date & GST
    _drawPageHeader(page, data.headerDate);

    // 2. Draw Bill Body (starts cleanly below the header)
    double y = 104;

    // Document Title: dynamic bill title from the app
    final String mainTitle = data.billTitle.toUpperCase();
    page.graphics.drawString(
      mainTitle,
      bold13,
      brush: PdfSolidBrush(primaryNavy),
      bounds: const Rect.fromLTWH(0, 104, 523, 16),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    y = 122;

    // Status Banner
    final bool isPaidBill = data.isPaid || data.paymentStatus.toUpperCase() == "PAID";
    final bool isDefaulterBill = data.isDefaulter || data.paymentStatus.toUpperCase().contains("DEFAULTER");

    final PdfColor badgeBg = isPaidBill
        ? greenBg
        : (isDefaulterBill ? alertBg : cardBg);
    final PdfColor badgeBorder = isPaidBill
        ? greenBorder
        : (isDefaulterBill ? alertBorder : borderGrey);
    final PdfColor badgeText = isPaidBill
        ? greenText
        : (isDefaulterBill ? PdfColor(220, 38, 38) : primaryNavy);

    final String statusBannerText = isPaidBill
        ? "OFFICIAL BILL & RECEIPT  •  STATUS: PAID  •  RECEIPT NO: ${data.receiptNo}"
        : (isDefaulterBill
            ? "OFFICIAL BILL & OVERDUE NOTICE  •  STATUS: DEFAULTER ${data.daysOverdue > 0 ? '(${data.daysOverdue}D OVERDUE)' : ''}  •  INVOICE NO: ${data.receiptNo}"
            : "OFFICIAL BILL & INVOICE  •  STATUS: ${data.paymentStatus.toUpperCase()}  •  INVOICE NO: ${data.receiptNo}");

    page.graphics.drawRectangle(
      brush: PdfSolidBrush(badgeBg),
      pen: PdfPen(badgeBorder, width: 1),
      bounds: Rect.fromLTWH(0, y, 523, 22),
    );
    page.graphics.drawString(
      statusBannerText,
      bold9,
      brush: PdfSolidBrush(badgeText),
      bounds: Rect.fromLTWH(0, y + 5, 523, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    y += 28;

    // SECTION 1: TWO COLUMNS (TENANT DETAILS & BILL ISSUER)
    const double colW = 255;
    const double colGap = 13;

    // Left Box: TENANT DETAILS
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(cardBg),
      pen: PdfPen(borderGrey, width: 1),
      bounds: Rect.fromLTWH(0, y, colW, 110),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(headerGrey),
      bounds: Rect.fromLTWH(0, y, colW, 20),
    );
    page.graphics.drawString(
      "TENANT DETAILS",
      bold8,
      brush: PdfSolidBrush(primaryNavy),
      bounds: Rect.fromLTWH(8, y + 4.5, colW - 16, 12),
    );

    double ly = y + 25;
    _drawKVRow(page, "Tenant Name:", data.payeeName.isNotEmpty ? data.payeeName : "Tenant", 0, ly, colW, bold8, regular8);
    ly += 16;
    _drawKVRow(page, "Building:", data.buildingAddress.isNotEmpty ? data.buildingAddress : "Lakshya Residency", 0, ly, colW, bold8, regular8);
    ly += 16;
    _drawKVRow(page, "Room & Bed:", data.roomAndBed.isNotEmpty ? data.roomAndBed : "Assigned", 0, ly, colW, bold8, regular8);
    ly += 16;
    _drawKVRow(page, "Contact No:", data.contactNumber.isNotEmpty ? data.contactNumber : "On file", 0, ly, colW, bold8, regular8);
    ly += 16;
    _drawKVRow(page, "Email:", data.email.isNotEmpty ? data.email : "On file", 0, ly, colW, bold8, regular8);

    // Right Box: BILL ISSUER
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(cardBg),
      pen: PdfPen(borderGrey, width: 1),
      bounds: Rect.fromLTWH(colW + colGap, y, colW, 110),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(headerGrey),
      bounds: Rect.fromLTWH(colW + colGap, y, colW, 20),
    );
    page.graphics.drawString(
      "BILL ISSUER / LAKSHYA RESIDENCY",
      bold8,
      brush: PdfSolidBrush(primaryNavy),
      bounds: Rect.fromLTWH(colW + colGap + 8, y + 4.5, colW - 16, 12),
    );

    double ry = y + 25;
    _drawKVRow(page, "Organisation:", "Lakshya Residency", colW + colGap, ry, colW, bold8, regular8);
    ry += 16;
    _drawKVRow(page, "Managed by:", "Ajay Singh (Founder)", colW + colGap, ry, colW, bold8, regular8);
    ry += 16;
    _drawKVRow(page, "Mail:", "lakshyaresidency@gmail.com", colW + colGap, ry, colW, bold8, regular8);
    ry += 16;
    _drawKVRow(page, "Phone:", "+91 97840 70543", colW + colGap, ry, colW, bold8, regular8);
    ry += 16;
    _drawKVRow(page, "Website:", "www.lakshyaresidency.com", colW + colGap, ry, colW, bold8, regular8);

    y += 118;

    // SECTION 2: BILL PARTICULARS & DATES
    final double particularsH = (data.transactionRef != null && data.transactionRef!.isNotEmpty) ? 116.0 : 100.0;
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(cardBg),
      pen: PdfPen(borderGrey, width: 1),
      bounds: Rect.fromLTWH(0, y, 523, particularsH),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(headerGrey),
      bounds: Rect.fromLTWH(0, y, 523, 20),
    );
    page.graphics.drawString(
      "BILL PARTICULARS & DATES",
      bold8,
      brush: PdfSolidBrush(primaryNavy),
      bounds: Rect.fromLTWH(10, y + 4.5, 500, 12),
    );

    double py = y + 25;
    _drawFullKVRow(page, "Bill Title / Purpose", data.billTitle, py, bold8, regular8);
    py += 15;
    _drawFullKVRow(page, "Invoice / Receipt Number", data.receiptNo, py, bold8, bold8, isHighlightVal: true);
    py += 15;
    _drawFullKVRow(page, "Date Informed / Issued", data.billInformedDate, py, bold8, regular8);
    py += 15;
    _drawFullKVRow(page, "Payment Due Date", data.deadline, py, bold8, regular8);
    py += 15;
    _drawFullKVRow(
      page,
      isPaidBill ? "Paid On (Payment Date)" : "Date of Payment",
      isPaidBill ? data.paidOn : "Pending Payment",
      py,
      bold8,
      isPaidBill ? bold8 : regular8,
    );
    if (data.transactionRef != null && data.transactionRef!.isNotEmpty) {
      py += 15;
      _drawFullKVRow(page, "Transaction Ref / UTR", data.transactionRef!, py, bold8, regular8);
    }

    y += particularsH + 8;

    // SECTION 3: AMOUNT BREAKDOWN & DEFAULTER CALCULATION
    const double breakdownH = 142.0;
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(cardBg),
      pen: PdfPen(borderGrey, width: 1),
      bounds: Rect.fromLTWH(0, y, 523, breakdownH),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(headerGrey),
      bounds: Rect.fromLTWH(0, y, 523, 20),
    );
    page.graphics.drawString(
      "AMOUNT BREAKDOWN & DEFAULTER CALCULATION",
      bold8,
      brush: PdfSolidBrush(primaryNavy),
      bounds: Rect.fromLTWH(10, y + 4.5, 500, 12),
    );

    double ay = y + 25;
    _drawFullKVRow(page, "Base Bill Amount (${data.billTitle})", "Rs. ${data.baseAmount.toStringAsFixed(2)}", ay, bold8, regular8);
    ay += 15;
    final String defText = data.defaulterAmount > 0
        ? "+ Rs. ${data.defaulterAmount.toStringAsFixed(2)} (Defaulter Added)"
        : "Rs. 0.00 (No Defaulter Charges)";
    _drawFullKVRow(
      page,
      "Amount of Defaulter",
      defText,
      ay,
      bold8,
      data.defaulterAmount > 0 ? bold8 : regular8,
      isHighlightVal: data.defaulterAmount > 0,
    );
    ay += 15;
    _drawFullKVRow(page, "Total Bill Amount Payable", "Rs. ${data.totalAmount.toStringAsFixed(2)}", ay, bold9, bold9, isHighlightVal: true);
    ay += 15;
    _drawFullKVRow(page, "Amount Paid", "Rs. ${data.paidAmount.toStringAsFixed(2)}", ay, bold8, isPaidBill ? bold8 : regular8);
    ay += 15;
    final String balText = data.balanceAmount <= 0
        ? "Rs. 0.00 (Fully Settled)"
        : "Rs. ${data.balanceAmount.toStringAsFixed(2)} (Balance Due)";
    _drawFullKVRow(page, "Balance Remaining", balText, ay, bold8, data.balanceAmount > 0 ? bold8 : regular8);
    ay += 17;

    // Highlight Banner at bottom of Breakdown box
    final PdfColor summaryBoxBg = isPaidBill
        ? greenBg
        : (isDefaulterBill ? alertBg : blueBg);
    final PdfColor summaryBoxBorder = isPaidBill
        ? greenBorder
        : (isDefaulterBill ? alertBorder : blueBorder);
    final PdfColor summaryBoxText = isPaidBill
        ? greenText
        : (isDefaulterBill ? redText : primaryNavy);

    page.graphics.drawRectangle(
      brush: PdfSolidBrush(summaryBoxBg),
      pen: PdfPen(summaryBoxBorder, width: 1),
      bounds: Rect.fromLTWH(8, ay, 507, 26),
    );
    final String summaryLabel = isPaidBill
        ? "TOTAL AMOUNT PAID (ON ${data.paidOn.toUpperCase()})"
        : (isDefaulterBill ? "TOTAL OVERDUE AMOUNT" : "NET AMOUNT DUE (BY ${data.deadline.toUpperCase()})");
    final String summaryVal = isPaidBill
        ? "Rs. ${data.paidAmount.toStringAsFixed(0)}"
        : "Rs. ${(data.balanceAmount > 0 ? data.balanceAmount : data.totalAmount).toStringAsFixed(0)}";

    page.graphics.drawString(
      summaryLabel,
      bold9,
      brush: PdfSolidBrush(summaryBoxText),
      bounds: Rect.fromLTWH(18, ay + 7, 320, 14),
    );
    page.graphics.drawString(
      summaryVal,
      bold14,
      brush: PdfSolidBrush(summaryBoxText),
      bounds: Rect.fromLTWH(340, ay + 4, 165, 18),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    y += breakdownH + 8;

    // SECTION 4: TERMS AND CONDITIONS
    page.graphics.drawString(
      "TERMS AND CONDITIONS",
      bold8,
      brush: PdfSolidBrush(textDark),
      bounds: Rect.fromLTWH(0, y, 523, 12),
    );
    y += 14;

    final List<String> terms = [
      "This official bill/receipt acknowledges charges for Lakshya Residency as recorded in the management system.",
      "Defaulter charges: 7-day grace period applies after due date; from Day 8, late fee is Rs. 100/day capped at Rs. 3,000/month (Rs. 6,000 for 30-60 days, Rs. 9,000 for 60-90 days).",
      "All online payments are subject to bank verification. Unsuccessful transactions shall render this receipt void.",
    ];

    for (final term in terms) {
      page.graphics.drawString(
        "•  $term",
        regular8,
        brush: PdfSolidBrush(textMuted),
        bounds: Rect.fromLTWH(0, y, 523, 13),
      );
      y += 13;
    }

    y += 4;

    // SECTION 5: AUTHORISED SIGNATORY
    if (_cachedSignatureBitmap != null) {
      page.graphics.drawImage(
        _cachedSignatureBitmap!,
        Rect.fromLTWH(395, y, 95, 30),
      );
      y += 32;
    } else {
      y += 18;
    }

    // Divider line above Authorised Signatory
    page.graphics.drawLine(
      PdfPen(borderGrey, width: 1),
      Offset(370, y),
      Offset(510, y),
    );
    y += 4;

    // Signatures / Seal row
    page.graphics.drawString(
      "Authorised Signatory",
      bold9,
      brush: PdfSolidBrush(textDark),
      bounds: Rect.fromLTWH(360, y, 163, 12),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    page.graphics.drawString(
      "Lakshya Residency Management",
      italic8,
      brush: PdfSolidBrush(textMuted),
      bounds: Rect.fromLTWH(360, y + 12, 163, 11),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // 3. Draw Exact Letterhead Vector Footer
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
      page.graphics.drawImage(_cachedLogoBitmap!, const Rect.fromLTWH(12, 28, 145, 36));
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
