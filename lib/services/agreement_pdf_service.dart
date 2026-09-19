import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Data bundle for generating a personalized Lakshya Residency Rent & License Agreement
class RentalAgreementData {
  final String agreementDate; // e.g. "19/09/2026"
  final String commencementDate; // e.g. "19/09/2026"
  final String endingDate; // e.g. "19/08/2027"
  final String studentFullName;
  final String mobileNumber;
  final String email;
  final String regNumber;
  final String course;
  final String branch;
  final String hometownAddress;
  final String building;
  final String roomNumber;
  final String bedNumber;
  final String flatConfig; // e.g. "2 BHK"
  final String guardianName;
  final String guardianRelationship;
  final String guardianPhone;
  final String dietaryPreference;
  final String plan; // "Rent Only" or "Full Package"
  final String rentalTerm; // e.g. "Complete Year (July to May)"
  final String lockInPeriod; // Full descriptive lock-in text
  final int termMonths; // 11, 6, 2, 1
  final String monthlyRent;
  final String securityDeposit;
  final String paymentFrequency;
  final int installmentsCount;
  final List<Map<String, String>> installments;
  final List<String> inventoryItems;
  final List<String> notes;
  final Uint8List? studentSignatureBytes;
  final Uint8List? ownerSignatureBytes;
  final Uint8List? studentPhotoBytes;
  final bool collegeIdUploaded;
  final bool govtIdUploaded;

  RentalAgreementData({
    required this.agreementDate,
    required this.commencementDate,
    required this.endingDate,
    required this.studentFullName,
    required this.mobileNumber,
    required this.email,
    required this.regNumber,
    required this.course,
    required this.branch,
    required this.hometownAddress,
    required this.building,
    required this.roomNumber,
    required this.bedNumber,
    this.flatConfig = "2 BHK",
    required this.guardianName,
    required this.guardianRelationship,
    required this.guardianPhone,
    required this.dietaryPreference,
    required this.plan,
    this.rentalTerm = "Complete Year (July to May)",
    this.lockInPeriod = "Complete Year (July to May) • 11 Months Lock-in (irrespective of late joining)",
    this.termMonths = 11,
    required this.monthlyRent,
    required this.securityDeposit,
    this.paymentFrequency = "Pay Monthly",
    this.installmentsCount = 4,
    this.installments = const [],
    this.inventoryItems = const [],
    this.notes = const [],
    this.studentSignatureBytes,
    this.ownerSignatureBytes,
    this.studentPhotoBytes,
    this.collegeIdUploaded = false,
    this.govtIdUploaded = false,
  });
}

/// Generates the complete legally binding Lakshya Residency
/// Rent and License Agreement in PDF format.
/// Eliminates unnecessary white space by cleanly consolidating clauses
/// across 20 fully utilized, beautifully formatted pages.
class AgreementPdfService {
  static const int totalPages = 20;

  // Colors
  static final PdfColor primaryBlue = PdfColor(0, 86, 210);
  static final PdfColor textDark = PdfColor(15, 23, 42);
  static final PdfColor textMuted = PdfColor(71, 85, 105);
  static final PdfColor borderGrey = PdfColor(226, 232, 240);
  static final PdfColor tableHeaderBg = PdfColor(241, 245, 249);
  static final PdfColor alertBg = PdfColor(254, 242, 242);
  static final PdfColor alertBorder = PdfColor(239, 68, 68);

  /// Load the owner's countersignature from assets
  static Future<Uint8List?> loadOwnerSignatureAsset() async {
    try {
      final ByteData byteData = await rootBundle.load('assets/images/owner_signature.jpg');
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint("Could not load owner signature asset: $e");
      return null;
    }
  }

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

  static PdfBitmap? _cachedLogoBitmap;

  /// Compiles all 20 pages and returns the PDF bytes
  static Future<Uint8List> generateAgreementPdf(RentalAgreementData data) async {
    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 36;
    document.pageSettings.size = PdfPageSize.a4;

    final Uint8List? logoBytes = await loadLogoAsset();
    if (logoBytes != null && logoBytes.isNotEmpty) {
      try {
        _cachedLogoBitmap = PdfBitmap(logoBytes);
      } catch (e) {
        debugPrint("Error creating PdfBitmap for logo: $e");
      }
    }

    Uint8List? ownerSig = data.ownerSignatureBytes;
    if (ownerSig == null || ownerSig.isEmpty) {
      ownerSig = await loadOwnerSignatureAsset();
    }

    // Standard fonts
    final PdfFont regular8 = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final PdfFont regular85 = PdfStandardFont(PdfFontFamily.helvetica, 8.5);
    final PdfFont bold8 = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);
    final PdfFont bold85 = PdfStandardFont(PdfFontFamily.helvetica, 8.5, style: PdfFontStyle.bold);
    final PdfFont bold9 = PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold);
    final PdfFont bold10 = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    final PdfFont bold11 = PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);
    final PdfFont bold13 = PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold);
    final PdfFont bold16 = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final PdfFont italic9 = PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.italic);

    // ==========================================
    // PAGE 1: Cover / Summary Sheet
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;
      page.graphics.drawString(
        "LAKSHYA RESIDENCY",
        bold16,
        brush: PdfSolidBrush(primaryBlue),
        bounds: Rect.fromLTWH(0, y, 523, 24),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      y += 24;
      page.graphics.drawString(
        "Rent and License AGREEMENT",
        bold13,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      y += 32;

      // Summary Table
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 2);
      grid.columns[0].width = 175;
      grid.columns[1].width = 348;

      _addGridRow(grid, "Agreement Date", data.agreementDate, isBoldVal: true);
      _addGridRow(grid, "Owner / Licensor", "Mr. Ajay Singh, Lakshya Residency");
      _addGridRow(grid, "Tenant / Licensee (Student)", data.studentFullName, isBoldVal: true);
      _addGridRow(
        grid,
        "Property Address",
        "Lakshya Residency, Building ${data.building}, Room/Flat No. ${data.roomNumber}${data.bedNumber.isNotEmpty ? ' (Bed ${data.bedNumber})' : ''}",
      );
      _addGridRow(
        grid,
        "Tenant's Hometown Address",
        data.hometownAddress.isNotEmpty ? data.hometownAddress : "On file in App Profile",
      );
      _addGridRow(
        grid,
        "Academic Session / Lock-In",
        "Plan: ${data.plan} | Rental Term / Lock-in Period: ${data.lockInPeriod}",
        isBoldVal: true,
      );

      _styleGrid(grid);
      grid.draw(page: page, bounds: Rect.fromLTWH(0, y, 523, 220));

      y += 240;
      page.graphics.drawString(
        "This is a legally binding document. Please read carefully before signing / accepting digitally on the App.",
        italic9,
        brush: PdfSolidBrush(textMuted),
        bounds: Rect.fromLTWH(0, y, 523, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }

    // ==========================================
    // PAGE 2: Table of Contents (Single Compact Page)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString(
        "TABLE OF CONTENTS",
        bold13,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      y += 22;

      // 2-Column Table of Contents
      final List<Map<String, String>> col1 = [
        {"title": "1. Parties and Recitals", "page": "3"},
        {"title": "   Recitals", "page": "3"},
        {"title": "2. Nature of Agreement", "page": "3"},
        {"title": "3. Definitions and Interpretation", "page": "4"},
        {"title": "4. Term, Lock-In Period and Renewal", "page": "4"},
        {"title": "5. Booking, Rent, Deposits and Payment Terms", "page": "5"},
        {"title": "6. Package-Based Facilities (Optional Services)", "page": "7"},
        {"title": "   6.A Meals", "page": "7"},
        {"title": "   6.B Pick-up and Drop to College", "page": "7"},
        {"title": "   6.C Laundry and Cleaning", "page": "8"},
        {"title": "   6.D Wi-Fi / Internet Access", "page": "8"},
        {"title": "   6.E General Terms Applicable to All Facilities", "page": "8"},
        {"title": "7. Utilities and Common Area Charges", "page": "8"},
        {"title": "8. Permitted Use and Occupancy Limits", "page": "9"},
        {"title": "9. Tenant's General Obligations", "page": "9"},
        {"title": "10. Prohibited Activities and Strict Conduct Rules", "page": "10"},
        {"title": "   10.1 Damage to Property", "page": "10"},
        {"title": "   10.2 Drugs, Narcotics and Substance Abuse", "page": "10"},
        {"title": "   10.3 Activities Involving Minors", "page": "10"},
        {"title": "   10.4 Commercial, Business or Unlawful Trade", "page": "10"},
      ];

      final List<Map<String, String>> col2 = [
        {"title": "10.5 Unauthorised Occupants & Relocation", "page": "11"},
        {"title": "10.6 Mobile Application — Acceptable Use Policy", "page": "11"},
        {"title": "10.7 General Nuisance, Safety and Prohibitions", "page": "11"},
        {"title": "10.8 Fights and Disputes Among Residents", "page": "11"},
        {"title": "11. House Rules — Curfew, Outings & Visitors", "page": "12"},
        {"title": "12. Co-Habitation / Live-in Arrangements", "page": "12"},
        {"title": "13. Owner's Rights and Remedies on Breach", "page": "13"},
        {"title": "14. Inspection, Entry and Room Reallocation", "page": "13"},
        {"title": "15. Maintenance, Repairs and Damage Liability", "page": "14"},
        {"title": "16. Security Deposit Deductions and Refund", "page": "14"},
        {"title": "17. Termination of Agreement", "page": "14"},
        {"title": "18. Consequences of Termination for Cause", "page": "15"},
        {"title": "19. Indemnity and Limitation of Liability", "page": "15"},
        {"title": "20. Health, Safety, Emergency & Well-Being", "page": "15"},
        {"title": "21. Force Majeure", "page": "15"},
        {"title": "22. Confidentiality, Data Privacy & Promotion", "page": "16"},
        {"title": "23. Dispute Resolution and Governing Law", "page": "16"},
        {"title": "24. General / Miscellaneous Provisions", "page": "16"},
        {"title": "SCHEDULE A — Student & Property Details", "page": "17"},
        {"title": "SCHEDULE B — Rent, Deposit & Payment Details", "page": "18"},
        {"title": "SCHEDULE C — Package Facilities Opted", "page": "18"},
        {"title": "SCHEDULE D — Inventory & House Rules", "page": "19"},
        {"title": "SCHEDULE E — Owner's Notes", "page": "19"},
        {"title": "ANNEXURE I — Co-Habitation Consent Form", "page": "19"},
        {"title": "TENANT'S DECLARATION & NOTICE", "page": "20"},
        {"title": "SIGNATURES & WITNESSES", "page": "20"},
      ];

      double y1 = y;
      const double wCol = 250;
      const double gap = 23;

      for (var item in col1) {
        page.graphics.drawString(item["title"]!, regular85, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y1, wCol - 25, 14));
        page.graphics.drawString(item["page"]!, bold85, brush: PdfSolidBrush(textMuted), bounds: Rect.fromLTWH(wCol - 25, y1, 25, 14), format: PdfStringFormat(alignment: PdfTextAlignment.right));
        y1 += 18.5;
      }

      double y2 = y;
      for (var item in col2) {
        page.graphics.drawString(item["title"]!, regular85, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(wCol + gap, y2, wCol - 25, 14));
        page.graphics.drawString(item["page"]!, bold85, brush: PdfSolidBrush(textMuted), bounds: Rect.fromLTWH(wCol + gap + wCol - 25, y2, 25, 14), format: PdfStringFormat(alignment: PdfTextAlignment.right));
        y2 += 18.5;
      }
    }

    // ==========================================
    // PAGE 3: Section 1 (Parties and Recitals) & Section 2 (Nature of Agreement)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString("1. Parties and Recitals", bold11, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y, 523, 16));
      y += 18;

      final relStr = data.guardianRelationship.toLowerCase().contains("mother") ? "daughter/son of" : "son/daughter of";
      final guardianStr = data.guardianName.isNotEmpty ? data.guardianName : "Guardian on file";
      final addressStr = data.hometownAddress.isNotEmpty ? data.hometownAddress : "On file in App Profile";

      final String pText = "This Rent/License Agreement (\"Agreement\") is made and entered into on this date ${data.agreementDate} by and between:\n\n"
          "OWNER / LICENSOR: Mr. Ajay Singh , hereinafter referred to as the \"Owner\" representing Lakshya Residency, located at Lakshay Residency and Flats, Tejasvi Greens, L2 L3, behind barcode cafe, near Manipal University Jaipur, Dahmi Kalan, Dahmi Khurd, Rajasthan 303007, of the ONE PART;\n\n"
          "AND\n\n"
          "TENANT / LICENSEE: ${data.studentFullName} $relStr $guardianStr, residing at $addressStr, of the OTHER PART.\n\n"
          "Where the context so requires, the Owner and the Tenant are hereinafter individually referred to as a \"Party\" and collectively as the \"Parties\".\n\n"
          "Recitals\n"
          "1.1 The Owner is the lawful owner and/or authorised managing operator of the residential unit(s) known as Lakshya Residency, and is competent to let out/license the said premises for residential and allied purposes.\n"
          "1.2 The Tenant has approached the Owner seeking accommodation on a rental / leave-and-license basis at the Residency, either on a standalone rent basis or coupled with certain optional package-based facilities (meals, transport, laundry, cleaning, Wi-Fi, etc.), and the Owner has agreed to provide the same on the terms and conditions recorded in this Agreement.\n"
          "1.3 This Agreement, together with its Schedules (A, B, C, D and E) and Annexure I, and any further Annexures executed in writing by both Parties, constitutes the entire understanding between the Parties in relation to the subject matter herein.\n"
          "1.4 This Agreement, along with any rent receipts, notices, and renewal confirmations, shall also be maintained on the Lakshya Residency mobile application (\"the App\") for administrative and compliance purposes.\n"
          "1.5 This Agreement, including Schedule A, is auto-generated using the information the Tenant submits at the time of onboarding on the App — including personal, academic, identity, room-allocation, guardian, and payment-plan details — and such App records shall be read together with, and form an integral part of, this Agreement. Upon completion of onboarding, the Tenant shall review and digitally sign this auto-generated Agreement on the App, which shall also bear the Owner's digital countersignature.\n\n"
          "2. Nature of Agreement\n"
          "2.1 This Agreement is in the nature of a leave and license. It grants the Tenant a personal, revocable permission to use and occupy the Premises, together with any opted Package Facilities, for the Term, subject to the conditions herein. It does not create any tenancy, lease, sub-lease, or any right, title, estate, or interest whatsoever in favour of the Tenant in the Premises or the Residency, and no landlord-tenant relationship under any rent control legislation shall be deemed to arise between the Parties.\n"
          "2.2 The Owner retains overall control, management, and right of entry over the Premises and Common Areas at all times, subject to Clause 14 (Inspection, Entry and Room Reallocation).";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 620));
    }

    // ==========================================
    // PAGE 4: Section 3 (Definitions) & Section 4 (Term, Lock-In Period, 4.1 & 4.1A)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString("3. Definitions and Interpretation", bold11, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y, 523, 16));
      y += 18;

      final String pText = "3.1 \"Premises\" means the specific flat/room (Building ${data.building}, Room/Flat ${data.roomNumber}${data.bedNumber.isNotEmpty ? ', Bed ${data.bedNumber}' : ''}), along with fittings, fixtures, furniture and appliances provided therein, allotted to the Tenant at Lakshya Residency, as recorded in Schedule A.\n"
          "3.2 \"Common Areas\" means all shared spaces within the Residency including but not limited to corridors, staircases, terrace, dining hall, common kitchen, lounge, and parking area, which are not for the exclusive use of any single Tenant.\n"
          "3.3 \"Package Facilities\" means the optional services listed in Schedule C which the Tenant may avail in addition to the base rent, including meals, pick-up and drop transport, laundry, cleaning, and Wi-Fi/internet access.\n"
          "3.4 \"App\" means the official Lakshya Residency mobile application through which onboarding, rent/fee payments, service requests, complaints, digital copies of this Agreement, notices, and communication between Owner and Tenant are facilitated.\n"
          "3.5 \"Booking Amount\" means the amount paid by the Tenant to reserve a room/bed prior to move-in, as recorded in Schedule B, which is non-refundable in the manner described in Clause 5.\n"
          "3.6 \"Security Deposit\" means the interest-free amount collected by the Owner from the Tenant as security against damage, unpaid dues, or breach of this Agreement, refundable subject to Clause 16.\n"
          "3.7 \"Academic Session\" or \"Lock-in Period\" means the period for which the Tenant has subscribed, as determined by the Plan (${data.plan}) and the Rental Term selected by the Tenant at onboarding on the App, being ${data.lockInPeriod} (${data.commencementDate} to ${data.endingDate}), which is the minimum period for which the Tenant commits to reside at the Premises.\n"
          "3.8 \"Minor\" means any individual who has not completed eighteen (18) years of age as on the date of the relevant event.\n"
          "3.9 \"Authorised Occupant\" means only the Tenant named in Schedule A and any additional occupant(s) whose details have been disclosed to and expressly approved in writing (including via the App) by the Owner prior to occupation.\n"
          "3.10 Words importing the singular include the plural and vice versa; words importing any gender include all genders; references to \"writing\" include communication through the App unless stated otherwise.\n\n"
          "4. Term, Lock-In Period and Renewal\n"
          "4.1 The Academic Session / Term of this Agreement shall be the Rental Term / Lock-in Period corresponding to the Plan and the duration selected by the Tenant at onboarding on the App, being ${data.commencementDate} to ${data.endingDate} (Plan: ${data.plan} ; Rental Term: ${data.rentalTerm} ), unless terminated earlier under Clause 17.\n"
          "4.1A Plans and Rental Terms: The following Plans and Rental Terms are offered on the App, and the Plan and Rental Term selected by the Tenant at onboarding shall be recorded in Schedule B. (a) Rent Only Plan: Complete Year (July to May) – 11 months; 1 Semester Only (July to December) – 6 months; Summer Break (May to June) – 2 months; Winter Break (December) – 1 month. Rent for the entire Rental Term selected shall be payable irrespective of late joining. (b) Full Package Plan: the Lock-in Period shall be the academic calendar of MUJ, from the commencement of the odd semester to the last examination of the even semester (excluding summer and winter break).";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 620));
    }

    // ==========================================
    // PAGE 5: Section 4 (4.2 to 4.6) & Section 5 (5.1 to 5.7)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = "4.2 The Tenant undertakes to remain in occupation of the Premises for the full Lock-in Period coinciding with the Academic Session. The Lock-in Period applies uniformly to Tenants on a rental-only basis and to Tenants who have opted for the Package Facilities.\n"
          "4.3 If the Tenant does not take possession of the Premises within 7 days of the agreed move-in date, or takes possession but vacates within the first 15 consecutive days thereafter, the Owner may treat this as a no-show/early exit and terminate this Agreement forthwith, with the consequences set out in Clause 16.4 and Clause 18.\n"
          "4.4 Renewal: This Agreement may be renewed for a further Academic Session on mutually agreed terms, recorded in writing (including digitally through the App) at least 30 days prior to expiry. In the absence of a written/App-based renewal, the Tenant shall vacate the Premises on or before the last day of the Term.\n"
          "4.5 Continued occupation beyond the Term without a signed renewal shall not be construed as an automatic extension, and the Owner may charge holding-over compensation at 10% above the last applicable rent for each day of unauthorised continued occupation, in addition to other remedies available in law.\n"
          "4.6 Automatic Termination by Efflux of Time: Unless renewed under Clause 4.4, this Agreement shall stand automatically terminated upon expiry of the Academic Session/Term. All outstanding dues as on such date shall become immediately payable and shall be adjusted against the Security Deposit in accordance with Clause 16.\n\n"
          "5. Booking, Rent, Deposits and Payment Terms\n"
          "5.1 Booking Amount: To reserve a room/bed, the Tenant shall pay the Booking Amount specified in Schedule B. The Booking Amount is strictly non-refundable once paid, including where the Tenant subsequently withdraws or cancels the booking prior to move-in, save where the Owner is unable to provide the booked accommodation at all.\n"
          "5.2 Advance Payment Before Move-In: A prospective Tenant wishing to move in must inform the Owner/App in advance (at least 7 days ahead) and shall pay the full quoted joining amount — comprising the Booking Amount, Security Deposit, and/or the first applicable installment, as the case may be — upfront and in advance of being granted possession or occupation of the Premises.\n"
          "5.3 Monthly Rent: For Tenants on a rental-only basis, and as a base component for Package Tenants, Rent shall be Rs. ${data.monthlyRent} as specified in Schedule B, exclusive of any Package Facilities charged separately under Schedule C.\n"
          "5.4 Payment Plan — Rental-Only Tenants: A Tenant availing accommodation on a purely rental basis shall be billed for the entire Academic Session. At onboarding, the Tenant shall elect, on the App, either to (a) pay Rent on a monthly basis, or (b) pay the full session's Rent upfront in installments of 3 (three), 4 (four), or such other number of installments as the Tenant chooses. The exact installment amounts and due dates shall be fixed on the App at the time this election is made and recorded in Schedule B.\n"
          "5.5 Payment Plan — Package Tenants: A Tenant who opts for the complete package (Rent plus Package Facilities) shall also pay in installments. The number of installments and the corresponding due dates shall likewise be decided at onboarding, on the App, and recorded in Schedule B.\n"
          "5.6 Default: If any installment or monthly Rent is not paid by its due date, the Tenant shall be treated as being \"in default\" and the late payment charge specified in Schedule B shall apply for each day of delay. Persistent default is additionally governed by Clause 17.3 (termination for non-payment).\n"
          "5.7 Security Deposit: A refundable, interest-free Security Deposit as specified in Schedule B (Rs. ${data.securityDeposit}) shall be paid by the Tenant prior to handover of possession. The Security Deposit shall not be adjusted against Rent during the subsistence of this Agreement except with the Owner's prior written consent, and is subject to forfeiture under Clause 5.8 and Clause 16.4.";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 620));
    }

    // ==========================================
    // PAGE 6: Section 5 (5.8 to 5.14) & Fraud Alert Box
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = "5.8 Non-Refundability on Early Exit: If the Tenant leaves, discontinues occupation, or withdraws from this Agreement before completing the full Lock-in Period / Academic Session referred to in Clause 4, both the Security Deposit and the Booking Amount shall stand fully and absolutely forfeited and shall not be refunded under any circumstance, and outstanding Rent/Package charges for the remainder of the Academic Session shall remain payable. This applies equally whether the early departure is on account of the Tenant's personal choice, academic withdrawal, disciplinary action, or any other reason not attributable to the Owner's default.\n\n"
          "5.9 Late Payment Charge: Beyond a grace period of 3 (three) days from the due date, a late payment charge (as specified in Schedule B, Rs. 100 per day) shall accrue for every day of delay, without prejudice to the Owner's right to treat persistent default as a material breach under Clause 17.\n\n"
          "5.10 Payments Only Through the App — No Other Channel Accepted: ALL payments to the Owner (Booking Amount, Security Deposit, Rent, installments, Package charges, fines, or any other dues) shall be made ONLY through the payment details listed on the App — namely the bank account number and UPI ID displayed within the App. The Owner does NOT accept, authorise, or acknowledge any payment made through any other bank account, UPI ID, cash collection, or any individual or agent, however described. The Tenant and their parent/guardian must never trust or make payment to any person claiming to represent Lakshya Residency outside the App, and the Owner shall bear no responsibility whatsoever for payments made to any unauthorised or fraudulent party.\n\n"
          "5.11 KYC and Verification: The Tenant shall submit, through the App at onboarding, valid identity documents (a Government-issued photo ID and College ID, as recorded in Schedule A) and a recent photograph, and shall cooperate with any police verification, tenant registration, or similar formality required under applicable local law.\n\n"
          "5.12 All applicable taxes, government levies, or statutory charges arising in relation to the Rent or Package Facilities shall be borne as per applicable law and may be passed on to the Tenant with prior written notice.\n\n"
          "5.13 Refund of Security Deposit (where applicable, i.e., where the Tenant has completed the Lock-in Period): Subject to Clause 16, the Owner shall refund the balance Security Deposit within the timeline specified in Schedule B (30 days from vacating), after lawful deductions.\n\n"
          "5.14 Summer and Winter Break Charges: The Lock-in Period excludes the summer and winter breaks. Where the Tenant retains the Premises during the summer break or the winter break, such break period may be charged additionally on the basis of the monthly Rent applicable to the Tenant, payable through the App. This additional charge shall not apply to a Tenant who has subscribed exclusively for the Summer Break or the Winter Break Rental Term.";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 440));
      y += 455;

      // Fraud Warning Alert Box
      page.graphics.drawRectangle(
        pen: PdfPen(alertBorder, width: 1.2),
        brush: PdfSolidBrush(alertBg),
        bounds: Rect.fromLTWH(0, y, 523, 85),
      );
      page.graphics.drawString(
        "PAYMENT FRAUD WARNING",
        bold10,
        brush: PdfSolidBrush(alertBorder),
        bounds: Rect.fromLTWH(14, y + 10, 495, 15),
      );
      final String warnText = "Lakshya Residency accepts payment ONLY through the bank account and UPI ID displayed on the official App. Do not pay cash, or transfer money, to anyone who contacts you claiming to be from Lakshya Residency outside the App. If in doubt, verify directly with the Owner through the App before making any payment.";
      _drawParagraph(page, warnText, regular8, Rect.fromLTWH(14, y + 28, 495, 50));
    }

    // ==========================================
    // PAGE 7: Section 6 (Package-Based Facilities: Intro, Table, 6.A, 6.B)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString(
        "6. Package-Based Facilities (Optional Value-Added Services)",
        bold11,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 16),
      );
      y += 18;

      final String intro = "Lakshya Residency offers, in addition to standalone room rental, bundled package plans comprising the facilities listed below. The Tenant may opt for none, some, or all of these facilities, as recorded in Schedule C. Charges for opted facilities are payable along with the Rent through the App, as per the Payment Plan chosen under Clause 5.5.";
      _drawParagraph(page, intro, regular8, Rect.fromLTWH(0, y, 523, 35));
      y += 40;

      // Package Facility Table
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 4);
      grid.columns[0].width = 160;
      grid.columns[1].width = 75;
      grid.columns[2].width = 168;
      grid.columns[3].width = 120;

      final bool isPkg = data.plan.toLowerCase().contains("package");

      final PdfGridRow hRow = grid.headers.add(1)[0];
      hRow.cells[0].value = "Package Facility";
      hRow.cells[1].value = "Included? (Y/N)";
      hRow.cells[2].value = "Frequency / Details";
      hRow.cells[3].value = "Additional Charge (if any)";

      _addPkgRow(grid, "Room / Flat Rent (Base)", "Y", "Monthly / As per Payment Plan", "As per Schedule B");
      _addPkgRow(grid, "Meals (Breakfast, Lunch, Dinner)", isPkg ? "Y" : "N", "3 times daily / as opted", isPkg ? "Included in Package" : "Optional / On Request");
      _addPkgRow(grid, "Pick-up & Drop to College/Institute", isPkg ? "Y" : "N", "Fixed timing, scheduled routes", isPkg ? "Included in Package" : "Optional / On Request");
      _addPkgRow(grid, "Laundry Service", isPkg ? "Y" : "N", "2 times per week", isPkg ? "Included in Package" : "Optional / On Request");
      _addPkgRow(grid, "Room / Common Area Cleaning", "Y", "Regular scheduled cleaning", "Included");
      _addPkgRow(grid, "Wi-Fi / Internet Access", "Y", "Shared bandwidth, FUP applies", "Complimentary");
      _addPkgRow(grid, "Other (specify)", "N", "—", "—");

      _styleGrid(grid);
      final PdfLayoutResult? gRes = grid.draw(page: page, bounds: Rect.fromLTWH(0, y, 523, 300));
      y = gRes != null ? gRes.bounds.bottom + 12 : y + 175;

      final String pText = "6.A Meals\n"
          "6.1 Where opted, meal service shall comprise up to three (3) meals a day (breakfast, lunch, and dinner) served at fixed timings communicated by the Residency management/App. Menu, timing, and portion policies are subject to reasonable modification by the Owner with advance notice on the App.\n\n"
          "6.2 The Tenant shall inform the Owner/App of any food allergies, medical dietary restrictions, and their vegetarian/non-vegetarian preference (as recorded in Schedule A, currently noted as: ${data.dietaryPreference}) in advance. The Owner is not liable for reactions arising from undisclosed allergies.\n\n"
          "6.3 Wastage of food, misuse of the mess/dining facility (including removing common utensils, cooking unauthorised items in the common kitchen, or misusing the facility for commercial resale of food) is strictly prohibited and may result in withdrawal of the meal package without refund for the withdrawn period.\n\n"
          "6.B Pick-up and Drop to College/Institute\n"
          "6.4 Where opted, transport service shall be provided between the Residency and the Tenant's specified college/institute at fixed timings and routes as communicated via the App. The Tenant must be ready at the designated pick-up point at the scheduled time; the vehicle shall not be obligated to wait beyond a reasonable grace period.\n\n"
          "6.5 This facility is meant solely for the named Tenant's commute to and from their registered institution and shall not be used to carry unauthorised persons, goods for commercial purposes, or personal errands outside the agreed route, without the Owner's prior written approval and applicable additional charge.\n\n"
          "6.6 The Tenant shall conduct themselves safely during transit and comply with reasonable instructions of the driver/attendant.";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 310));
    }

    // ==========================================
    // PAGE 8: Section 6 (6.C to 6.E) & Section 7 (Utilities 7.1)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = "6.C Laundry and Cleaning\n"
          "6.7 Where opted, laundry service shall be provided at the frequency specified in Schedule C. The Owner/service provider shall exercise reasonable care but shall not be liable for ordinary wear, shrinkage, or colour-run inherent to fabric type, nor for items left unclaimed beyond thirty (30) days. The Tenant is advised to verify items at the time of delivery; complaints raised thereafter may not be entertained.\n"
          "6.8 Where opted, cleaning service for the room/common areas shall be provided at the frequency specified in Schedule C, at reasonable hours communicated in advance.\n\n"
          "6.D Wi-Fi / Internet Access\n"
          "6.9 Where opted, Wi-Fi/internet access shall be provided on a shared-bandwidth, best-effort basis, subject to a Fair Usage Policy. The Owner does not guarantee uninterrupted, error-free, or specific-speed connectivity, and shall not be liable for any inconvenience, loss, or damage arising from unavailability or malfunction of the network.\n"
          "6.10 The Wi-Fi facility shall be used strictly for lawful purposes. The Tenant shall not use the network to download, host, stream, or transmit pirated content or malware; to access or distribute content depicting the exploitation or abuse of minors (which shall be reported to law enforcement immediately upon detection); or to carry out cyber-crime, hacking, or unauthorised access to third-party systems. Any such misuse shall entitle the Owner to immediately suspend access and pursue legal action, including reporting to the police and/or the cyber-crime authorities.\n\n"
          "6.E General Terms Applicable to All Package Facilities\n"
          "6.11 Package Facilities are optional and separately charged. They may be added or opted out of only with at least 30 days' advance written notice (through the App), and refunds/adjustments, if any, shall be on a pro-rata basis at the Owner's discretion. The Owner reserves the right to require full upfront payment for certain Package Facilities as a condition of opting in.\n"
          "6.12 Third-Party Facilitation: For services rendered through third-party vendors (including laundry, transport, and the internet service provider), the Owner acts only as a facilitator/aggregator and is not itself the service provider. The Owner shall not be liable for deficiency, delay, damage, or loss caused by such a third-party vendor; the Tenant's remedy, if any, in such cases lies against the vendor directly.\n"
          "6.13 Complaint Window: Any complaint regarding a Package Facility must be raised via the App/email within 48 hours of the relevant service being rendered; complaints raised thereafter may not be entertained. If a timely complaint is not resolved within 15 days, the Tenant shall escalate it to the Owner/warden in writing.\n"
          "6.14 Misuse, abuse, or fraudulent claims relating to any Package Facility (e.g., false damage claims, unauthorised sharing of the facility with non-residents, tampering with service logs on the App) shall be treated as a material breach of this Agreement under Clause 10 and Clause 17.\n"
          "6.15 National Holidays, Summer Break and Winter Break: During national holidays and during the summer and winter breaks, there is no confirmation or assurance of meals or of any other services, including pick-up and drop (cab), cleaning, laundry and similar services. Availability of any such service during these periods shall be communicated through the App at the Owner’s discretion, and the Owner shall not be liable for its non-availability.\n\n"
          "7. Utilities and Common Area Charges\n"
          "7.1 Electricity shall be charged at the rate of Rs. 12 (Rupees Twelve only) per unit consumed, as per meter/sub-meter reading, billed monthly through the App. In a shared-occupancy room, electricity charges shall be divided equally among all occupants of that room, unless otherwise agreed in writing.";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 620));
    }

    // ==========================================
    // PAGE 9: Section 7 (7.2 to 7.4), Section 8 (Occupancy), Section 9 (Obligations)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String p1 = "7.2 Water and common maintenance charges shall be included in the Rent as specified in Schedule B.\n"
          "7.3 The Tenant shall use electrical appliances, water, and other utilities responsibly and shall not install high-load appliances (e.g., heaters, induction cooktops, air-conditioners) without the Owner's prior written consent, given the shared electrical load of the Residency.\n"
          "7.4 Common Area maintenance charges, if applicable, shall be shared proportionately among all Tenants of the Residency and billed through the App.\n\n"
          "8. Permitted Use of Premises and Occupancy Limits\n"
          "8.1 The Premises shall be used solely for lawful residential purposes by the Tenant (and any Authorised Occupant) for the duration of their bona fide studies, and for no other purpose whatsoever.\n"
          "8.2 The Tenant shall comply with all house rules of Lakshya Residency as displayed on the premises and/or communicated through the App, including the curfew, outing, and visitor policy at Clause 11, which shall be deemed part of this Agreement.\n"
          "8.3 The Tenant shall not use the Premises in any manner that causes nuisance, annoyance, danger, or disturbance to the Owner, other tenants, neighbours, or the general public.\n"
          "8.4 Maximum Occupancy Limits: To ensure resident safety, comfort, and compliance with fire and building-safety norms, the number of persons residing in any flat shall not exceed the limits below:";

      _drawParagraph(page, p1, regular8, Rect.fromLTWH(0, y, 523, 175));
      y += 180;

      // Occupancy Table
      final PdfGrid occGrid = PdfGrid();
      occGrid.columns.add(count: 2);
      occGrid.columns[0].width = 240;
      occGrid.columns[1].width = 283;

      final PdfGridRow hRow = occGrid.headers.add(1)[0];
      hRow.cells[0].value = "Flat Configuration";
      hRow.cells[1].value = "Maximum Persons Permitted";

      _addGridRow(occGrid, "1 BHK", "2 persons");
      _addGridRow(occGrid, "2 BHK", "4 persons");
      _addGridRow(occGrid, "3 BHK", "6 persons");

      _styleGrid(occGrid);
      final PdfLayoutResult? occRes = occGrid.draw(page: page, bounds: Rect.fromLTWH(0, y, 523, 120));
      y = occRes != null ? occRes.bounds.bottom + 10 : y + 95;

      final String p2 = "8.5 Occupancy beyond the limits in Clause 8.4 — whether through unauthorised additional occupants or otherwise — is strictly prohibited and constitutes a material breach entitling the Owner to the remedies under Clause 13 and Clause 17.\n\n"
          "9. Tenant's General Obligations\n"
          "9.1 Pay Rent, installments, and all Package Facility charges on time as per Clause 5 and Schedule B/C.\n"
          "9.2 Maintain the Premises, fittings, fixtures, and furnishings provided (as listed in Schedule A/D) in good and tenantable condition, normal wear and tear excepted.\n"
          "9.3 Promptly report any damage, malfunction, leakage, or safety hazard in the Premises or Common Areas to the Owner/App helpdesk.\n"
          "9.4 Permit the Owner or its authorised representative to inspect the Premises in accordance with Clause 14.\n"
          "9.5 Not make any structural alteration, additional construction, drilling, or fixture installation without the Owner's prior written consent.\n"
          "9.6 Comply with all applicable laws, municipal regulations, society/RWA rules, and fire-safety norms during occupation.\n"
          "9.7 Keep the Owner informed, through the App, of correct and current contact details and guardian/emergency contact information.\n"
          "9.8 Vacate and hand over peaceful, vacant, and undamaged possession of the Premises upon expiry or termination of this Agreement, along with all keys, access cards, and Residency-issued property.\n"
          "9.9 Keep personal valuables and belongings securely locked away when absent from the Premises. The Owner/Residency staff shall not be liable for loss of personal belongings from the Premises, except to the extent caused by the Owner's proven gross negligence.\n"
          "9.10 Cooperate with the Owner's repair, maintenance, and housekeeping staff, including during the Tenant's absence and specifically during the summer vacation/break period when block-level or Residency-wide maintenance work may be undertaken (see Clause 15.4). The Tenant shall not obstruct such work.\n"
          "9.11 Cooperate with police verification, tenant registration, or other formalities required by applicable law, as referred to in Clause 5.11.";

      _drawParagraph(page, p2, regular8, Rect.fromLTWH(0, y, 523, 350));
    }

    // ==========================================
    // PAGE 10: Section 10 (Prohibited Activities: 10.1 to 10.4)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString("10. Prohibited Activities and Strict Conduct Rules", bold11, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y, 523, 16));
      y += 18;

      final String pText = "The Tenant expressly acknowledges and agrees that the activities described below are strictly prohibited within the Premises, the Residency, and in connection with use of the App. Any breach of this Clause 10 shall be treated as a material and fundamental breach of this Agreement, entitling the Owner to the remedies set out in Clause 13 and Clause 17, including but not limited to immediate termination, forfeiture of the Security Deposit and Booking Amount, eviction in accordance with law, and initiation of criminal/civil legal proceedings.\n\n"
          "10.1 Damage to Property\n"
          "10.1.1 The Tenant shall not intentionally or negligently damage, deface, remove, or destroy any part of the Premises, Common Areas, furniture, fixtures, fittings, electrical/plumbing installations, or any property belonging to the Owner, the Residency, or other tenants.\n"
          "10.1.2 Any damage beyond normal wear and tear shall be assessed by the Owner and the cost of repair/replacement shall be recovered from the Security Deposit and/or directly from the Tenant. In a shared room, such cost may be recovered jointly from all occupants of that room, without prejudice to the Owner's right to pursue further legal remedies for wilful or grossly negligent damage.\n"
          "10.1.3 The Tenant shall be liable for damage caused by any guest, visitor, or Authorised Occupant permitted onto the Premises by the Tenant.\n\n"
          "10.2 Drugs, Narcotics and Substance Abuse\n"
          "10.2.1 The possession, consumption, cultivation, storage, sale, distribution, or facilitation of any narcotic drug or psychotropic substance banned under the Narcotic Drugs and Psychotropic Substances Act, 1985 (or any successor/equivalent law) is absolutely and strictly prohibited within the Premises, the Residency, and its Common Areas. Smoking, drinking, and chewing tobacco are likewise governed by the Residency's house rules and applicable law.\n"
          "10.2.2 Upon discovery or reasonable suspicion of any activity described in this Clause 10.2, the Owner shall be entitled, without further notice, to (a) immediately restrict/terminate occupancy, (b) confiscate and hand over any illegal substance/paraphernalia to the police, (c) inform the Tenant's parent/guardian, and (d) lodge a formal police complaint and fully cooperate with any resulting investigation or prosecution, at the Tenant's sole cost and risk.\n"
          "10.2.3 The Tenant shall indemnify the Owner against any loss, penalty, or legal consequence arising from a violation of this Clause 10.2 by the Tenant or any person permitted onto the Premises by the Tenant.\n\n"
          "10.3 Activities Involving Minors\n"
          "10.3.1 No Minor shall reside at, be housed in, or stay overnight at the Premises unless such Minor is accompanied by, and under the direct supervision of, a parent or legal guardian, or unless prior written consent has been obtained from the Owner along with complete identity and guardian-contact details.\n"
          "10.3.2 The Tenant shall not engage, permit, or facilitate any activity on the Premises or through the App that endangers the safety or welfare of a Minor, or that is unlawful in relation to a Minor under applicable Indian law (including the POCSO Act, 2012, the Juvenile Justice Act, 2015, and the Indian Penal Code / Bharatiya Nyaya Sanhita).\n"
          "10.3.3 Any suspected or confirmed violation of this Clause 10.3 shall be reported by the Owner immediately to the local police and/or the relevant Child Welfare Committee/authority, and the Owner shall have the right to terminate this Agreement with immediate effect, over and above pursuing all available legal remedies.\n\n"
          "10.4 Commercial, Business or Unlawful Trade Activity\n"
          "10.4.1 The Premises are let/licensed strictly for residential use. The Tenant shall not carry out, from the Premises, any business, trade, profession, commercial venture, manufacturing, storage of trade goods, or any other for-profit commercial activity of any nature, without the Owner's prior written consent.\n"
          "10.4.2 The Tenant shall not use the Premises for any unlawful purpose, including gambling/betting operations, money-lending, or counterfeit goods.\n"
          "10.4.3 Violation of this Clause 10.4 shall entitle the Owner to immediately terminate this Agreement and seek compensation for any loss, statutory penalty, or reputational harm suffered, in addition to reporting the matter to the appropriate municipal, tax, or law-enforcement authority where warranted.";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 620));
    }

    // ==========================================
    // PAGE 11: Section 10 (10.5 to 10.8)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = "10.5 Unauthorised Occupants, Subletting and Relocation of Third Parties\n"
          "10.5.1 The Tenant shall not sublet, assign, transfer, or share occupation of the Premises, in whole or in part, with any third party without the Owner's prior written consent. Any such unauthorised assignment or subletting shall be void, and the Owner may terminate this Agreement and commence eviction without further notice.\n"
          "10.5.2 The Tenant shall not permit any person to relocate into, stay at, or use the Premises as their residence — continuously or intermittently — for a prolonged period (more than 3 consecutive nights, or more than 7 nights in any calendar month) without first disclosing such person's identity and obtaining the Owner's prior written approval through the App or in writing.\n"
          "10.5.3 Short-term guests may be permitted strictly in accordance with the visitor policy at Clause 11, and the Tenant shall remain fully responsible for the conduct, safety, and any dues/damage caused by such guests.\n"
          "10.5.4 Any unauthorised or undisclosed long-term occupant discovered at the Premises entitles the Owner to (a) charge additional occupancy fees retroactively, (b) direct immediate removal of such person, and/or (c) terminate this Agreement under Clause 17, without prejudice to any other legal remedy, including police intervention where the occupant refuses to vacate.\n\n"
          "10.6 Mobile Application — Acceptable Use Policy\n"
          "10.6.1 The Tenant shall use the App solely for legitimate purposes connected with their tenancy — onboarding, rent/fee payment, service requests, complaints, communication with the Owner/management, and viewing this Agreement and related documents.\n"
          "10.6.2 The Tenant shall not: (a) share App login credentials with any unauthorised person; (b) attempt to hack, reverse-engineer, introduce malware into, or otherwise compromise the App or its backend systems; (c) upload or transmit obscene, defamatory, harassing, threatening, or unlawful content, including content involving Minors; (d) use the App's messaging, complaint, or payment features to harass, threaten, or defraud the Owner, staff, or other tenants; (e) create fraudulent service requests, falsify complaint records, or misuse the App's payment gateway (including attempted chargebacks or payment fraud); or (f) use any bot, script, or automated means to interact with the App other than through its intended interface.\n"
          "10.6.3 The Owner reserves the right to suspend or terminate the Tenant's App account for any misuse under Clause 10.6.2, without prejudice to terminating this Agreement and pursuing legal action, including cyber-crime complaints where applicable.\n"
          "10.6.4 All communications, notices, payment confirmations, and complaint records exchanged via the App shall be admissible between the Parties as evidence of communication, retained in accordance with applicable data-protection law.\n\n"
          "10.7 General Nuisance, Safety and Miscellaneous Prohibitions\n"
          "• Storing or handling flammable, explosive, hazardous, or illegal materials/weapons within the Premises.\n"
          "• Tampering with fire-safety equipment, CCTV cameras, electrical wiring, or common building infrastructure.\n"
          "• Causing disturbance during designated quiet hours specified in the house rules.\n"
          "• Bringing pets into the Residency without the Owner's prior written consent, where house rules restrict pets.\n"
          "• Any act of harassment, ragging, discrimination, or violence against co-tenants, staff, or visitors.\n"
          "• Circulating false, defamatory, or malicious information about the Owner, Residency, or its staff/tenants on any platform, including the App or social media.\n"
          "• Any other act that is unlawful under the laws of India or that brings disrepute to Lakshya Residency.\n\n"
          "10.8 Fights and Disputes Among Residents\n"
          "10.8.1 The Tenant shall not engage in any physical altercation, dispute, or fight with other residents, staff, vendors, or members of the public in or around the Residency. The Owner shall not be responsible for any loss, injury, or damage arising from such conduct.\n"
          "10.8.2 Where a Tenant is found involved in such conduct, the Owner may forfeit the Security Deposit and Booking Amount, cancel the Tenant's admission, and require immediate vacation of the Premises, without prejudice to any other remedy.";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 620));
    }

    // ==========================================
    // PAGE 12: Section 11 (House Rules) & Section 12 (Co-Habitation)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = "11. House Rules — Curfew, Outings and Visitor Policy\n\n"
          "11.1 Outing Hours: The Tenant may move within the immediate vicinity of the Residency until 22:00 hours (10:00 PM). Venturing outside the city/campus area requires prior intimation to the Tenant's parent/guardian and to the Owner/warden.\n"
          "11.2 Door-Closing Time: The main gate/door of the Residency shall close at 22:30 hours in summer and 22:00 hours in winter. The Tenant shall return to the Residency before this time.\n"
          "11.3 Late Entry: A Tenant seeking to return after the closing time for a genuine reason must obtain prior permission from their parent/guardian and the warden/Owner. Unauthorised late entry may attract a penalty or disciplinary action, and repeated late entry may be reported to the Tenant's parent/guardian.\n"
          "11.4 Night-Out / Overnight Absence: The Tenant must submit a written/App-based night-out application, noting the time of departure in the Residency's register, and obtain the Owner's/warden's approval — ordinarily conditional on parental consent — before staying away from the Residency overnight.\n"
          "11.5 Overnight Guests: Overnight stay of any outside friend or visitor in the Tenant's room is not permitted, save as provided under Clause 12 (Co-Habitation) or with the Owner's express prior written consent. A visitor of a different gender than the room's registered occupants shall not stay overnight in the room, and may only be received during permitted visiting hours in designated common areas, consistent with the Residency's safety and decorum policy.\n"
          "11.6 If the Tenant does not return by the curfew time without prior permission and cannot be reached, the Owner may inform the Tenant's parent/guardian. The Owner shall not be liable for any mishap suffered by the Tenant while outside the Residency without having taken due permission.\n\n"
          "12. Co-Habitation / Live-in Arrangements\n\n"
          "12.1 Where an adult Tenant (18 years of age or above) wishes to reside at the Premises together with a partner in a live-in / co-habiting arrangement, the Tenant shall, prior to admission or prior to commencing such an arrangement, inform their parent(s)/legal guardian(s) of the same.\n"
          "12.2 Both cohabiting residents shall execute and submit to the Owner a signed Co-Habitation Consent Form, in the format at Annexure I to this Agreement, either physically or digitally through the App, expressly confirming that their decision to reside together is mutual, voluntary, and free of coercion.\n"
          "12.3 The Owner permits such an arrangement purely as an accommodation facilitator and assumes no responsibility for the personal, emotional, financial, or legal consequences of the relationship between the cohabiting residents. In the event of any dispute, separation, allegation, or incident arising between such residents, the Owner shall not be held liable in any manner whatsoever, save for matters arising from the Owner's own proven negligence or wilful misconduct in the management of the Premises.\n"
          "12.4 This Clause applies only where both cohabiting residents are adults. Any arrangement involving a Minor is additionally governed by, and must comply with, Clause 10.3 (Activities Involving Minors), including express guardian consent, and shall not be permitted in the absence of such consent.\n"
          "12.5 Nothing in this Clause obligates the Owner to allot a shared room to cohabiting residents; room/bed allocation remains subject to availability, the Owner's policies, and the occupancy limits at Clause 8.4.";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 620));
    }

    // ==========================================
    // PAGE 13: Section 13 (Owner Remedies) & Section 14 (Inspection & Reallocation)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = "13. Owner's Rights and Remedies on Breach\n\n"
          "13.1 Right of Admission: The Owner reserves the right of admission to the Residency and may, at its sole discretion, refuse, defer, or cancel any booking/admission — including after provisional acceptance — without being obliged to disclose reasons, subject to the Owner's cancellation/refund policy then in force.\n"
          "13.2 Without prejudice to any other right or remedy available under this Agreement or in law, upon the occurrence of any breach described in Clause 10 (or any other material breach of this Agreement), the Owner shall be entitled to any or all of the following remedies, at its sole discretion:\n"
          "• Issue a written warning through the App specifying the breach and requiring rectification within a stipulated period;\n"
          "• Immediately suspend access to any or all Package Facilities and/or the App, without refund for the suspended period;\n"
          "• Forfeit the Security Deposit and Booking Amount, in whole or in part, to the extent of loss, damage, or dues arising from the breach;\n"
          "• Terminate this Agreement with immediate effect (in cases of illegal activity, drug-related offences, offences involving Minors, or serious damage/danger) or upon notice as specified in Clause 17 (for other breaches), and require the Tenant to vacate the Premises;\n"
          "• Lodge a formal complaint with the local police station, cyber-crime cell, municipal authority, educational institution, or any other appropriate government or regulatory authority;\n"
          "• Pursue civil proceedings for recovery of dues, damages, and costs, and/or support criminal proceedings where the breach constitutes an offence under Indian law;\n"
          "• Escalate the matter to the Tenant's parent/legal guardian and/or educational institution, where reasonably necessary for safety, disciplinary, or recovery purposes.\n"
          "13.3 The Owner's exercise of, or delay in exercising, any right under this Clause shall not be construed as a waiver of that right or of any other right available to the Owner.\n\n"
          "14. Inspection, Entry and Room Reallocation\n\n"
          "14.1 The Owner or its authorised representative may enter the Premises for inspection, maintenance, or verification purposes during reasonable hours upon giving at least twenty-four (24) hours' prior notice (through the App or otherwise), except in emergencies (fire, flooding, gas leak, reported illegal activity, or risk to life/property), where entry may be made without prior notice.\n"
          "14.2 The Tenant shall not unreasonably deny access for such inspection or emergency entry.\n"
          "14.3 The Owner may carry out necessary repair and maintenance work in the Premises/Residency at its discretion, including during the Tenant's absence, and the Tenant shall have no objection to entry for such purpose, subject to reasonable care of the Tenant's belongings by the Owner's staff.\n"
          "14.4 Room / Building Reallocation: The Owner reserves the right, for operational reasons, to shift/transfer the Tenant from one room/bed to another, or from one building/property under the Residency to another, on similar terms. Where such a shift involves any change in charges, the same shall be recorded via an addendum or an updated Schedule on the App.";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 620));
    }

    // ==========================================
    // PAGE 14: Section 15 (Maintenance), Section 16 (Deposit Deductions), Section 17 (Termination)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = "15. Maintenance, Repairs and Damage Liability\n\n"
          "15.1 For Tenants staying on a purely rental (non-package) basis, the first month's routine maintenance and any repair required in the Premises shall be attended to by the Owner at no additional cost. From the second month of the Term onward, day-to-day maintenance and minor repairs (excluding structural repairs and normal wear-and-tear replacement of major fixed installations, which remain the Owner's responsibility) shall be arranged and borne by the Tenant, unless otherwise covered under the Package Facilities in Schedule C.\n"
          "15.2 All repair/maintenance requests shall be logged through the App, and the Owner shall use reasonable efforts to address them within a reasonable timeframe.\n"
          "15.3 The inventory of furniture, fixtures, and appliances provided in the Premises is recorded in Schedule A/D, as fetched from the Tenant's onboarding record on the App. The Tenant shall verify this inventory at the time of possession and shall be liable for any shortfall or damage identified at the time of vacating, save for normal wear and tear.\n"
          "15.4 Summer Break Maintenance: The Owner may undertake block-level, floor-level, or Residency-wide maintenance, repainting, pest control, or renovation work during the summer vacation/break period (or any other declared maintenance window). The Tenant shall cooperate with the Owner's staff/contractors for access, temporary relocation of belongings, or temporary access restriction during such maintenance, and shall not obstruct such work.\n\n"
          "16. Security Deposit and Advance Charges — Deductions and Refund\n\n"
          "16.1 The Owner may deduct from the Security Deposit: (a) unpaid Rent, installments, or Package Facility charges; (b) cost of repair or replacement of damaged property under Clause 10.1; (c) unpaid utility or common area charges; (d) any penalty or holding-over compensation validly due under this Agreement; and (e) any other amount lawfully due from the Tenant to the Owner.\n"
          "16.2 Where the Tenant has completed the full Lock-in Period / Academic Session and dues stand settled, the balance Security Deposit shall be refunded within 30 days from vacating as specified in Schedule B, through the payment mode recorded on the App, along with a written/App-based statement of any deductions.\n"
          "16.3 Non-Refund on Early Exit: Notwithstanding Clause 16.1 and 16.2, and as also stated in Clause 5.8, if the Tenant vacates the Premises, discontinues occupation, or withdraws from this Agreement before completing the full Lock-in Period / Academic Session, the entire Security Deposit and the Booking Amount shall stand absolutely forfeited and shall not be refunded under any circumstance, and outstanding Rent/Package charges for the remaining Academic Session shall remain payable, without prejudice to the Owner's other rights.\n\n"
          "17. Termination of Agreement\n\n"
          "17.1 Either Party may terminate this Agreement prior to expiry of the Term by giving the other Party not less than 30 days' prior written notice (through the App or in writing), save as provided below.\n"
          "17.2 The Owner may terminate this Agreement with immediate effect and without notice in the event of: (a) any breach falling under Clause 10.2 (drugs/narcotics) or Clause 10.3 (offences involving Minors); (b) any act endangering the life, safety, or property of the Owner, staff, or other tenants; (c) any activity that is unlawful and exposes the Owner or the Residency to legal or regulatory liability; (d) breach of the occupancy limits at Clause 8.4; or (e) co-habitation without the consent form required under Clause 12.2.\n"
          "17.3 Non-Payment: If Rent, an installment, or Package charges remain unpaid beyond 3 days from the due date, the late payment charge under Clause 5.9 applies. If such amount remains unpaid beyond 7 days from the due date, or if there is a delay beyond 7 days for a second consecutive billing period, the Owner may terminate this Agreement forthwith, without further notice, and require the Tenant to vacate.\n"
          "17.4 No-Show / Early Exit Within Initial Days: As stated in Clause 4.3, if the Tenant does not take possession within the agreed timeline, or vacates within the first few days of moving in, the Owner may terminate this Agreement forthwith.\n"
          "17.5 Upon termination, the Tenant shall vacate the Premises, remove personal belongings, and hand over vacant, undamaged possession along with keys/access cards, failing which the Owner shall be entitled to hold-over compensation under Clause 4.5 and/or take possession in accordance with law.\n"
          "17.6 Termination of this Agreement shall automatically terminate all Package Facilities availed under Schedule C, subject to pro-rata settlement of dues/refunds as applicable and subject to Clause 16.3.\n"
          "17.7 This Agreement shall also stand automatically terminated by efflux of time in accordance with Clause 4.6.";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 620));
    }

    // ==========================================
    // PAGE 15: Section 18 (Consequences), 19 (Indemnity), 20 (Health/Safety), 21 (Force Majeure)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = "18. Consequences of Termination for Cause\n\n"
          "18.1 Where this Agreement is terminated for cause under Clause 17.2, 17.3, 17.4, or for breach under Clause 10 or Clause 13, the following consequences shall apply: (a) forfeiture of the entire Security Deposit, Booking Amount, and any advance charges paid; (b) all outstanding Rent, Package charges, fines, and other dues become immediately payable; (c) the Tenant shall immediately vacate, remove personal belongings, and return keys/access cards; (d) the Tenant's access to the Premises and the App shall be barred forthwith; and (e) any belongings not removed within a reasonable period after termination may be disposed of by the Owner without liability.\n"
          "18.2 If the amount due under Clause 18.1(b), together with the cost of any missing or damaged inventory, exceeds the Security Deposit and other amounts held by the Owner, the difference shall become immediately payable by the Tenant. If not paid within 7 days of intimation, the Owner may inform credit information agencies and/or the Tenant's educational institution, and initiate appropriate legal proceedings.\n"
          "18.3 The Owner may re-let/re-license the vacated Premises to any other individual immediately upon termination.\n"
          "18.4 Termination for cause shall not absolve the Tenant of liability accrued prior to, or as a consequence of, such termination, and the Owner's rights under this Agreement shall survive termination.\n\n"
          "19. Indemnity and Limitation of Liability\n\n"
          "19.1 The Tenant shall indemnify and keep indemnified the Owner against any loss, damage, liability, claim, penalty, or legal proceeding arising out of (a) the Tenant's breach of this Agreement, (b) any illegal or unauthorised activity conducted by the Tenant or any person permitted onto the Premises by the Tenant, or (c) any injury, loss, or damage caused by the Tenant's act or omission to any third party, the Owner, or the Owner's property.\n"
          "19.2 Limitation of Liability: Save in cases of the Owner's proven gross negligence or wilful misconduct, the aggregate liability of the Owner to the Tenant under this Agreement, whether in contract, tort, or otherwise, shall not exceed an amount equivalent to the Rent/Package charges paid by the Tenant for the five (5) days immediately preceding the date the relevant claim arises.\n"
          "19.3 The Owner shall not be liable for loss of the Tenant's personal belongings (see also Clause 9.9) due to theft, fire, or other causes, except to the extent such loss arises from the Owner's proven gross negligence or wilful default.\n\n"
          "20. Health, Safety, Emergency and Personal Well-Being\n\n"
          "20.1 The Tenant shall disclose to the Owner/App any pre-existing medical condition or emergency contact details relevant to their safety, on a voluntary basis, to enable appropriate assistance in case of emergency.\n"
          "20.2 The Tenant shall comply with fire-safety instructions, evacuation procedures, and any public-health protocols in force at the Residency from time to time. In the event of a government-mandated evacuation arising from a pandemic or public-health emergency, Rent/Fees for the ongoing Academic Session shall remain payable notwithstanding early vacation, unless the Owner decides otherwise.\n"
          "20.3 In case of a genuine medical or safety emergency involving the Tenant, the Owner/Residency staff may take reasonable steps (including contacting emergency services or the Tenant's emergency contact/guardian) without such action being construed as a breach of privacy or of this Agreement.\n"
          "20.4 Self-Harm and Personal Safety: While the Owner shall take the reasonable and bona fide safety precautions expected of a residential facility operator, the Owner shall not be held liable for any act of self-harm, attempted suicide, or suicide committed by a Tenant/resident on or off the Premises, except to the extent such incident arises directly from the Owner's own proven gross negligence or wilful default in maintaining basic safety standards at the Premises. The Tenant and their parent/guardian acknowledge that the Owner is not a medical or mental-health care provider and undertakes no duty of clinical care towards residents.\n"
          "20.5 The Residency encourages any Tenant experiencing emotional distress or a mental-health concern to reach out to their family, the Residency's designated warden/contact person, their institution's counselling service, or a national mental-health helpline, details of which shall be displayed at the Residency and on the App.\n\n"
          "21. Force Majeure\n\n"
          "21.1 Neither Party shall be held liable for any failure or delay in performing its obligations under this Agreement (excluding payment obligations) where such failure or delay results from circumstances beyond its reasonable control, including natural disaster, fire, pandemic, government order, strike, or civil unrest.";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 620));
    }

    // ==========================================
    // PAGE 16: Section 22 (Privacy), 23 (Dispute Resolution), 24 (General Provisions)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = "22. Confidentiality, Data Privacy and Promotional Use\n\n"
          "22.1 Personal data collected from the Tenant via the App (including identity proof, contact details, payment information, and complaint history) shall be used by the Owner solely for purposes connected with this Agreement, tenancy administration, safety, and legal compliance, and shall not be sold to unrelated third parties.\n"
          "22.2 The Tenant consents to the Owner sharing relevant data with law-enforcement or regulatory authorities where required in connection with a suspected breach under Clause 10, an investigation, or a legal obligation.\n"
          "22.3 The Owner shall take reasonable technical and organisational measures to protect the Tenant's data stored on the App against unauthorised access, in line with applicable data-protection law, including the Digital Personal Data Protection Act, 2023, where applicable.\n"
          "22.4 Promotional Use: The Owner may, for promotional purposes, use testimonials, photographs, or videos of the Tenant taken during events or activities organised at the Residency, on its website, social media, or marketing material, provided the same is not used in a manner prejudicial to the Tenant. The Tenant may opt out of such use by written intimation via the App.\n"
          "22.5 Non-Disclosure of Agreement Terms: The Tenant shall keep the commercial terms of this Agreement (Rent, Package charges, Security Deposit, Booking Amount, etc.) confidential and shall not disclose the same to third parties, other than parents/guardians or as required by law.\n\n"
          "23. Dispute Resolution and Governing Law\n\n"
          "23.1 The Parties shall in the first instance attempt to amicably resolve any dispute arising out of or in connection with this Agreement through good-faith discussion, including via the App's grievance-redressal feature, if any.\n"
          "23.2 Failing amicable resolution within 30 days, the dispute shall be referred to arbitration by a sole arbitrator mutually appointed by the Parties, in accordance with the Arbitration and Conciliation Act, 1996, and the seat of arbitration shall be Jaipur, Rajasthan. Alternatively, the Parties agree that disputes shall be subject to the exclusive jurisdiction of the competent courts at Jaipur, Rajasthan.\n"
          "23.3 This Agreement shall be governed by and construed in accordance with the laws of India.\n"
          "23.4 Nothing in this Clause 23 shall restrict the Owner's right to approach the police or any competent criminal court directly, without recourse to arbitration, in respect of any act constituting a criminal offence under Clause 10 of this Agreement.\n\n"
          "24. General / Miscellaneous Provisions\n\n"
          "24.1 Notices: Any notice required under this Agreement shall be deemed validly served if sent via the App, registered post, e-mail, or hand delivery to the addresses/contact details recorded herein.\n"
          "24.2 Amendment: No amendment or waiver of any provision of this Agreement shall be effective unless made in writing and signed/digitally accepted by both Parties.\n"
          "24.3 Severability: If any provision of this Agreement is held invalid or unenforceable, the remaining provisions shall continue in full force and effect.\n"
          "24.4 Entire Agreement: This Agreement, along with its Schedules and Annexure, constitutes the entire agreement between the Parties and supersedes all prior discussions, representations, or agreements, whether oral or written, relating to its subject matter.\n"
          "24.5 Assignment by Tenant: The Tenant shall not assign or transfer any rights or obligations under this Agreement without the Owner's prior written consent.\n"
          "24.6 Assignment by Owner: The Owner may sell, transfer, mortgage, or assign its rights and obligations under this Agreement, in whole or in part, without requiring the Tenant's consent. Upon such transfer, the Owner shall stand released from obligations arising thereafter, and the Tenant shall, upon written notice, recognise the transferee as the Owner for the residual Term.\n"
          "24.7 Counterparts and Digital Execution: This Agreement may be executed in counterparts, including digitally through the App, each of which shall be deemed an original.\n"
          "24.8 Stamp Duty and Registration: The Parties shall bear stamp duty and registration charges (if applicable under local law) in the proportion of 50%, and shall ensure compliance with any mandatory registration requirement for leave-and-license/rent agreements under the applicable State law.";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 620));
    }

    // ==========================================
    // PAGE 17: SCHEDULE A — Student Onboarding & Property Details
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString(
        "SCHEDULE A — Student Onboarding & Property Details",
        bold11,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 16),
      );
      y += 18;

      final String sub = "The fields below are populated automatically from the Tenant's onboarding profile on the App at the time this Agreement is generated. Any change to these details after execution must be updated on the App and confirmed with the Owner.";
      _drawParagraph(page, sub, regular8, Rect.fromLTWH(0, y, 523, 26));
      y += 30;

      final PdfGrid gridA = PdfGrid();
      gridA.columns.add(count: 2);
      gridA.columns[0].width = 180;
      gridA.columns[1].width = 343;

      _addGridRow(gridA, "Profile Photo", data.studentPhotoBytes != null ? "[Photo Captured Digitally]" : "[Photo on file — App Onboarding]");
      _addGridRow(gridA, "Full Name", data.studentFullName, isBoldVal: true);
      _addGridRow(gridA, "Mobile Number", data.mobileNumber);
      _addGridRow(gridA, "Email ID", data.email);
      _addGridRow(gridA, "College Registration Number", data.regNumber.isNotEmpty ? data.regNumber : "N/A");
      _addGridRow(gridA, "Course", data.course.isNotEmpty ? data.course : "N/A");
      _addGridRow(gridA, "Branch / Specialisation / Honours", data.branch.isNotEmpty ? data.branch : "N/A");
      _addGridRow(gridA, "College ID Card", data.collegeIdUploaded ? "Uploaded & Verified on App" : "[Photo on file — App Onboarding]");
      _addGridRow(gridA, "Government ID Proof", data.govtIdUploaded ? "Government ID Uploaded (Aadhar/PAN/DL)" : "[Photo on file — App Onboarding]");
      _addGridRow(gridA, "Building", data.building, isBoldVal: true);
      _addGridRow(gridA, "Room / Flat Number", data.roomNumber, isBoldVal: true);
      _addGridRow(gridA, "Bed Number", data.bedNumber.isNotEmpty ? data.bedNumber : "Allotted Bed");
      _addGridRow(gridA, "Flat Configuration (1/2/3 BHK)", "${data.flatConfig} (see occupancy limit, Clause 8.4)");
      _addGridRow(gridA, "Guardian's Name", data.guardianName.isNotEmpty ? data.guardianName : "N/A");
      _addGridRow(gridA, "Guardian's Relationship to Tenant", data.guardianRelationship.isNotEmpty ? data.guardianRelationship : "Guardian");
      _addGridRow(gridA, "Guardian's Phone Number", data.guardianPhone.isNotEmpty ? data.guardianPhone : "N/A");
      _addGridRow(gridA, "Vegetarian / Non-Vegetarian Preference", data.dietaryPreference);
      _addGridRow(gridA, "Property Name", "Lakshya Residency");
      _addGridRow(gridA, "Full Address", "Lakshay Residency and Flats, Tejasvi Greens, Jaipur, Rajasthan 303007");
      _addGridRow(gridA, "Furnishing Status", "Fully Furnished (as per Schedule D inventory)");

      _styleGrid(gridA);
      gridA.draw(page: page, bounds: Rect.fromLTWH(0, y, 523, 480));
    }

    // ==========================================
    // PAGE 18: SCHEDULE B & SCHEDULE C
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString(
        "SCHEDULE B — Rent, Deposit and Payment Details",
        bold11,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 16),
      );
      y += 18;

      final PdfGrid gridB = PdfGrid();
      gridB.columns.add(count: 2);
      gridB.columns[0].width = 210;
      gridB.columns[1].width = 313;

      _addGridRow(gridB, "Booking Amount (Non-Refundable)", "Rs. 0 / Included in Deposit");
      _addGridRow(gridB, "Monthly Rent", "Rs. ${data.monthlyRent}", isBoldVal: true);
      _addGridRow(gridB, "Security Deposit (Non-refundable on early exit)", "Rs. ${data.securityDeposit}", isBoldVal: true);
      _addGridRow(gridB, "Basis of Stay", data.plan);
      _addGridRow(gridB, "Payment Plan Selected", "${data.paymentFrequency} (Number of Installments: ${data.installmentsCount})");

      String instSummary = "As scheduled on App (${data.installmentsCount} installments)";
      if (data.installments.isNotEmpty) {
        instSummary = data.installments.map((e) => "${e['title']}: Rs. ${e['amount']} (${e['dueDate']})").join("\n");
      }
      _addGridRow(gridB, "Installment Amounts & Due Dates", instSummary);
      _addGridRow(gridB, "Rent Due Date (if monthly)", "1st of every month (1st month on date of joining)");
      _addGridRow(gridB, "Late Payment Charge", "Rs. 100 per day, chargeable from the 4th day after due date");
      _addGridRow(gridB, "Electricity Charges", "Rs. 12 per unit as per meter reading (shared equally in room)");
      _addGridRow(gridB, "Water Charges", "Included in Rent");
      _addGridRow(gridB, "Common Maintenance Charges", "Included in Rent (first month borne by Owner — Clause 15.1)");
      _addGridRow(gridB, "Academic Session / Lock-in Period", "Plan: ${data.plan} | Rental Term: ${data.rentalTerm} | Duration: ${data.termMonths} Months from Commencement Date (${data.commencementDate} to ${data.endingDate})");
      _addGridRow(gridB, "Summer / Winter Break Charges", "Additional, as per monthly Rent (not applicable to exclusive break terms) - Clause 5.14");
      _addGridRow(gridB, "Notice Period for Termination", "30 days");
      _addGridRow(gridB, "Deposit Refund Timeline", "30 days from vacating");
      _addGridRow(gridB, "All Payments Payable To", "Bank Account Number and UPI ID displayed on the App ONLY — see Clause 5.10");

      _styleCompactGrid(gridB);
      final PdfLayoutResult? gResB = gridB.draw(page: page, bounds: Rect.fromLTWH(0, y, 523, 350));
      y = gResB != null ? gResB.bounds.bottom + 10 : y + 270;

      page.graphics.drawString(
        "SCHEDULE C — Package-Based Facilities Opted",
        bold10,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 15),
      );
      y += 16;

      final bool isPkg = data.plan.toLowerCase().contains("package");
      final PdfGrid gridC = PdfGrid();
      gridC.columns.add(count: 4);
      gridC.columns[0].width = 160;
      gridC.columns[1].width = 75;
      gridC.columns[2].width = 168;
      gridC.columns[3].width = 120;

      final PdfGridRow hRow = gridC.headers.add(1)[0];
      hRow.cells[0].value = "Package Facility";
      hRow.cells[1].value = "Included?";
      hRow.cells[2].value = "Frequency / Details";
      hRow.cells[3].value = "Additional Charge";

      _addPkgRow(gridC, "Room / Flat Rent (Base)", "Y", "Monthly / As per Plan", "As per Schedule B");
      _addPkgRow(gridC, "Meals (Breakfast, Lunch, Dinner)", isPkg ? "Y" : "N", "3 times daily / as opted", isPkg ? "Included in Package" : "Optional / On Request");
      _addPkgRow(gridC, "Pick-up & Drop to College", isPkg ? "Y" : "N", "Fixed timing routes", isPkg ? "Included in Package" : "Optional / On Request");
      _addPkgRow(gridC, "Laundry Service", isPkg ? "Y" : "N", "2 times per week", isPkg ? "Included in Package" : "Optional / On Request");
      _addPkgRow(gridC, "Room / Common Area Cleaning", "Y", "Regular scheduled cleaning", "Included");
      _addPkgRow(gridC, "Wi-Fi / Internet Access", "Y", "Shared bandwidth, FUP applies", "Complimentary");
      _addPkgRow(gridC, "Other (specify)", "N", "—", "—");

      _styleCompactGrid(gridC);
      final PdfLayoutResult? gResC = gridC.draw(page: page, bounds: Rect.fromLTWH(0, y, 523, 170));
      y = gResC != null ? gResC.bounds.bottom + 8 : y + 130;

      page.graphics.drawString(
        "Total Monthly / Installment Payable: Rs. ${data.monthlyRent} as fixed on the App under the chosen Payment Plan.",
        bold9,
        brush: PdfSolidBrush(primaryBlue),
        bounds: Rect.fromLTWH(0, y, 523, 18),
      );
    }

    // ==========================================
    // PAGE 19: SCHEDULE D, SCHEDULE E & ANNEXURE I
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString(
        "SCHEDULE D — Furniture, Inventory and House Rules Acknowledgement",
        bold10,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 15),
      );
      y += 16;

      final String itemsJoined = data.inventoryItems.map((e) => "• $e").join("    |    ");
      final String dText = "The furniture, fixtures, and appliances provided in the Premises at the time of onboarding/move-in are as listed in the Tenant's onboarding record on the App. Both Parties confirm this inventory and its condition through the App at check-in, and any discrepancy must be flagged within 48 hours of move-in.\n"
          "Allotted Inventory Checklist (${data.inventoryItems.length} items): $itemsJoined\n"
          "The Tenant confirms having read and understood the Residency's house rules (displayed on the notice board and/or the App), including visiting hours, quiet hours, gate-closing time, and the guest-registration procedure at Clause 11, and agrees to be bound by the same as part of this Agreement.";

      _drawParagraph(page, dText, regular8, Rect.fromLTWH(0, y, 523, 80));
      y += 85;

      page.graphics.drawString(
        "SCHEDULE E — Owner's Notes",
        bold10,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 15),
      );
      y += 16;

      final String eIntro = "Any additional understanding reached between the Owner and the Tenant at the time of onboarding (special arrangements, waivers, or remarks) shall be recorded here by the Owner and remain visible to both Parties on the App:";
      _drawParagraph(page, eIntro, regular8, Rect.fromLTWH(0, y, 523, 22));
      y += 24;

      // Notes Box
      page.graphics.drawRectangle(
        pen: PdfPen(borderGrey, width: 1),
        brush: PdfSolidBrush(tableHeaderBg),
        bounds: Rect.fromLTWH(0, y, 523, 50),
      );

      final String notesContent = data.notes.isNotEmpty
          ? data.notes.map((n) => "• $n").join("\n")
          : "• Standard residency terms apply. Routine inspection scheduled in coordination with tenant.\n• Emergency numbers: +91 97840 70543 | Founder Ajay Singh";
      _drawParagraph(page, notesContent, regular8, Rect.fromLTWH(8, y + 6, 507, 38));
      y += 58;

      // ANNEXURE I
      page.graphics.drawString(
        "ANNEXURE I — CO-HABITATION / LIVE-IN CONSENT FORM",
        bold10,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      y += 16;

      final String sub = "(To be submitted physically or through the App by both residents, where applicable, in accordance with Clause 12 of this Agreement)\n"
          "We, the undersigned, both being adult residents of Lakshya Residency, voluntarily confirm our mutual consent to reside together at the Premises described below. We acknowledge and accept the terms of Clause 12 (Co-Habitation / Live-in Arrangements) of this Agreement, including that Lakshya Residency and its Owner shall not be liable for any personal, relationship, financial, or legal issue arising between us during or after this arrangement, save for matters arising from the Owner's own proven negligence or wilful misconduct.";
      _drawParagraph(page, sub, regular8, Rect.fromLTWH(0, y, 523, 55));
      y += 58;

      final PdfGrid cGrid = PdfGrid();
      cGrid.columns.add(count: 2);
      cGrid.columns[0].width = 180;
      cGrid.columns[1].width = 343;
      _addGridRow(cGrid, "Building / Room / Flat No.", "Building ${data.building}, Room/Flat ${data.roomNumber}");
      _addGridRow(cGrid, "Date of this Form", data.agreementDate);
      _styleGrid(cGrid);
      cGrid.draw(page: page, bounds: Rect.fromLTWH(0, y, 523, 45));
      y += 50;

      final String residents = "Resident 1: ${data.studentFullName}  |  ID Proof: On file in App  |  Guardian Informed: Yes (${data.agreementDate})  |  Signature: Digitally Signed on App\n"
          "Resident 2: ___________________________  |  ID Proof: _________________  |  Guardian Informed: (Y/N)  |  Signature: _________________\n"
          "Acknowledged by Owner / Warden: Mr. Ajay Singh, Founder / Licensor  |  Signature and Date: Digitally Signed on App (${data.agreementDate})";

      _drawParagraph(page, residents, regular8, Rect.fromLTWH(0, y, 523, 45));
    }

    // ==========================================
    // PAGE 20: Tenant's Declaration, Notice, Signatures & Witnesses
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString(
        "TENANT'S DECLARATION",
        bold11,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 16),
      );
      y += 16;

      final String dText = "D.1 I confirm that I am legally permitted and eligible to execute this Agreement, either personally or through my parent/legal guardian, and that the particulars fetched from my onboarding profile on the App (Schedule A) are true and accurate to the best of my knowledge; I have not wilfully suppressed any material fact, and I understand that any misrepresentation may render me ineligible for accommodation.\n"
          "D.2 I undertake to submit valid KYC documents (Government ID and College ID, as recorded in Schedule A) to the Owner through the App on or before moving into the Premises, and to provide full cooperation and documentation for any police verification, tenant registration, or similar process required by the Owner or applicable law.\n"
          "D.3 I undertake not to disclose the commercial terms of this Agreement, including the information at Schedule A, B, and C, to any third party other than my parent/guardian or as required by law, in accordance with Clause 22.5.\n"
          "D.4 I have read and understood this Agreement in full, including Clause 10 (Prohibited Activities and Strict Conduct Rules) and Clause 13 (Owner's Rights and Remedies). I understand and agree that engaging in property damage, drug/narcotic-related activity, any activity endangering a Minor, unauthorised commercial/business use of the Premises, housing any unauthorised person for a prolonged period without prior disclosure and consent, exceeding the occupancy limits at Clause 8.4, or misuse of the App, shall constitute a serious breach of this Agreement.\n"
          "D.5 I understand that the Owner has the full right, without limitation, to terminate this Agreement, forfeit the Security Deposit and Booking Amount to the extent described in Clauses 5.8, 16.3 and 18, evict me in accordance with law, lodge a police complaint, and/or escalate the matter to any higher civil, criminal, or regulatory authority, and I accept full legal responsibility for any consequence arising from such breach.\n"
          "D.6 I confirm that I have read and understood Clause 20.4 (Self-Harm and Personal Safety) and Clause 19.2 (Limitation of Liability) of this Agreement.";

      _drawParagraph(page, dText, regular8, Rect.fromLTWH(0, y, 523, 200));
      y += 205;

      // Important Notice Box
      final double noticeH = 80;
      page.graphics.drawRectangle(
        pen: PdfPen(alertBorder, width: 1.2),
        brush: PdfSolidBrush(alertBg),
        bounds: Rect.fromLTWH(0, y, 523, noticeH),
      );
      page.graphics.drawString(
        "IMPORTANT NOTICE",
        bold10,
        brush: PdfSolidBrush(alertBorder),
        bounds: Rect.fromLTWH(12, y + 8, 499, 14),
      );
      final String noticeText = "This Agreement is a legal contract. Violation of the prohibitions in Clause 10 may expose the Tenant to civil liability, forfeiture of the Security Deposit and Booking Amount, immediate eviction, and criminal prosecution under applicable Indian law. Leaving before completing the Lock-in Period (${data.rentalTerm}) results in full forfeiture of the Security Deposit and Booking Amount as described in Clauses 5.8 and 16.3. By signing below (or accepting digitally on the App), the Tenant acknowledges full understanding and acceptance of these consequences.";
      _drawParagraph(page, noticeText, regular8, Rect.fromLTWH(12, y + 24, 499, 52));
      y += noticeH + 8;

      page.graphics.drawString(
        "SIGNATURES",
        bold11,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 15),
      );
      y += 15;

      final String sigIntro = "IN WITNESS WHEREOF, the Parties (and, where the Tenant is a Minor, their parent/legal guardian) have set their hands / provided digital acceptance on the App, on the day, month, and year first above written. Where this Agreement is generated and accepted through the App, the Tenant's digital acceptance timestamp and login verification, together with the Owner's digital countersignature recorded on the App, shall be deemed equivalent to physical signatures for all purposes between the Parties.";
      _drawParagraph(page, sigIntro, regular8, Rect.fromLTWH(0, y, 523, 40));
      y += 44;

      // Two-column signature block: Owner Left, Tenant Right
      final double colW = 245;

      // Owner Box
      page.graphics.drawRectangle(
        pen: PdfPen(borderGrey, width: 1),
        brush: PdfSolidBrush(tableHeaderBg),
        bounds: Rect.fromLTWH(0, y, colW, 115),
      );
      page.graphics.drawString("Owner / Licensor Signature:", bold85, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(8, y + 6, colW - 16, 12));

      if (ownerSig != null && ownerSig.isNotEmpty) {
        try {
          final PdfBitmap ownerBitmap = PdfBitmap(ownerSig);
          page.graphics.drawImage(ownerBitmap, Rect.fromLTWH(15, y + 20, 100, 42));
        } catch (e) {
          page.graphics.drawString("[Signed Digitally: Mr. Ajay Singh]", bold8, brush: PdfSolidBrush(primaryBlue), bounds: Rect.fromLTWH(15, y + 30, colW - 30, 15));
        }
      } else {
        page.graphics.drawString("[Signed Digitally: Mr. Ajay Singh]", bold8, brush: PdfSolidBrush(primaryBlue), bounds: Rect.fromLTWH(15, y + 30, colW - 30, 15));
      }

      page.graphics.drawString("Name: Mr. Ajay Singh", regular8, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(8, y + 65, colW - 16, 11));
      page.graphics.drawString("Designation: Founder / Licensor", regular8, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(8, y + 78, colW - 16, 11));
      page.graphics.drawString("Date: ${data.agreementDate} | Status: Countersigned", bold8, brush: PdfSolidBrush(primaryBlue), bounds: Rect.fromLTWH(8, y + 91, colW - 16, 11));

      // Tenant Box
      page.graphics.drawRectangle(
        pen: PdfPen(primaryBlue, width: 1.2),
        brush: PdfSolidBrush(PdfColor(240, 249, 255)),
        bounds: Rect.fromLTWH(colW + 33, y, colW, 115),
      );
      page.graphics.drawString("Tenant / Student Signature:", bold85, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(colW + 41, y + 6, colW - 16, 12));

      if (data.studentSignatureBytes != null && data.studentSignatureBytes!.isNotEmpty) {
        try {
          final PdfBitmap studentBitmap = PdfBitmap(data.studentSignatureBytes!);
          page.graphics.drawImage(studentBitmap, Rect.fromLTWH(colW + 48, y + 20, 110, 42));
        } catch (e) {
          page.graphics.drawString("[Signed Digitally on App]", bold8, brush: PdfSolidBrush(primaryBlue), bounds: Rect.fromLTWH(colW + 48, y + 30, colW - 30, 15));
        }
      } else {
        page.graphics.drawString("[Signed Digitally on App]", bold8, brush: PdfSolidBrush(primaryBlue), bounds: Rect.fromLTWH(colW + 48, y + 30, colW - 30, 15));
      }

      page.graphics.drawString("Name: ${data.studentFullName}", regular8, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(colW + 41, y + 65, colW - 16, 11));
      page.graphics.drawString("Room: Bldg ${data.building}, Rm ${data.roomNumber}", regular8, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(colW + 41, y + 78, colW - 16, 11));
      page.graphics.drawString("Date: ${data.agreementDate} | Status: Executed", bold8, brush: PdfSolidBrush(primaryBlue), bounds: Rect.fromLTWH(colW + 41, y + 91, colW - 16, 11));

      y += 122;

      // Guardian & Witnesses in compact row
      final String gText = "(If Minor) Parent / Guardian: ${data.guardianName.isNotEmpty ? data.guardianName : 'N/A'} (${data.guardianRelationship})  |  Phone: ${data.guardianPhone.isNotEmpty ? data.guardianPhone : 'N/A'}\n"
          "Witness 1: Digital System Audit Verification (Lakshya Residency App Platform Engine)  |  Witness 2: Resident Warden Desk, Jaipur";
      _drawParagraph(page, gText, regular8, Rect.fromLTWH(0, y, 523, 28));
      y += 32;

      page.graphics.drawString(
        "— End of Agreement —",
        bold10,
        brush: PdfSolidBrush(textMuted),
        bounds: Rect.fromLTWH(0, y, 523, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }

    // ==========================================
    // POST-PASS: Apply Exact Headers & Footers on all pages
    // ==========================================
    final int actualPages = document.pages.count;
    for (int i = 0; i < actualPages; i++) {
      final PdfPage p = document.pages[i];
      _drawPageHeader(p, i + 1, data.agreementDate);
      _drawPageFooter(p, i + 1, actualPages);
    }

    final List<int> bytes = document.saveSync();
    document.dispose();
    return Uint8List.fromList(bytes);
  }

  // -------------------------------------------------------------
  // HELPER METHODS: EXACT VECTOR HEADER & FOOTER
  // -------------------------------------------------------------

  static void _drawPageHeader(PdfPage page, int pageNum, String dateStr) {
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
      brush: PdfSolidBrush(PdfColor(255, 0, 157)),
      bounds: const Rect.fromLTWH(491.5, 27, 2.8, 48.0),
    );

    // 4. Horizontal Magenta Line across page
    page.graphics.drawLine(
      PdfPen(PdfColor(255, 0, 157), width: 1.5),
      const Offset(x0, 76.5),
      const Offset(x0 + 348.0, 76.5),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 0, 157)),
      bounds: Rect.fromLTWH(x0 + 348.0, 75.0, x1 - (x0 + 348.0), 3.5),
    );

    // 5. Date & GST row
    final PdfFont fontDate = PdfStandardFont(PdfFontFamily.helvetica, 9);
    final PdfFont boldGST = PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold);

    if (pageNum == 1) {
      page.graphics.drawString("Date: $dateStr", fontDate, brush: PdfSolidBrush(textDark), bounds: const Rect.fromLTWH(0, 85, 250, 14));
    }
    page.graphics.drawString(
      "GST: 08DYPPK8554R1Z4",
      boldGST,
      brush: PdfSolidBrush(textDark),
      bounds: const Rect.fromLTWH(200, 85, 523.4 - 36, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
  }

  static void _drawPageFooter(PdfPage page, int pageNum, int totalPagesCount) {
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

    // Page number on pages 2+
    if (pageNum > 1) {
      final PdfFont fontPage = PdfStandardFont(PdfFontFamily.helvetica, 8.5, style: PdfFontStyle.italic);
      page.graphics.drawString(
        "Page $pageNum of $totalPagesCount",
        fontPage,
        brush: PdfSolidBrush(textMuted),
        bounds: const Rect.fromLTWH(0, flatY - 14, 487.4, 14),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
    }
  }

  static double _drawParagraph(PdfPage page, String text, PdfFont font, Rect bounds) {
    final cleanText = text.replaceAll('₹', 'Rs. ');
    final PdfTextElement element = PdfTextElement(
      text: cleanText,
      font: font,
      brush: PdfSolidBrush(textDark),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.left,
        lineSpacing: 1.5,
      ),
    );
    // Allow element to use all remaining page space down to footer to prevent artificial overflow
    final double maxH = 750.0 - bounds.top;
    final PdfLayoutResult? result = element.draw(
      page: page,
      bounds: Rect.fromLTWH(bounds.left, bounds.top, bounds.width, maxH > 40 ? maxH : bounds.height),
    );
    return result?.bounds.bottom ?? (bounds.top + bounds.height);
  }

  static void _addGridRow(PdfGrid grid, String label, String value, {bool isBoldVal = false}) {
    final PdfGridRow row = grid.rows.add();
    row.cells[0].value = label.replaceAll('₹', 'Rs. ');
    row.cells[1].value = value.replaceAll('₹', 'Rs. ');
    if (isBoldVal) {
      row.cells[1].style.font = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);
    }
  }

  static void _addPkgRow(PdfGrid grid, String col1, String col2, String col3, String col4) {
    final PdfGridRow row = grid.rows.add();
    row.cells[0].value = col1.replaceAll('₹', 'Rs. ');
    row.cells[1].value = col2;
    row.cells[2].value = col3.replaceAll('₹', 'Rs. ');
    row.cells[3].value = col4.replaceAll('₹', 'Rs. ');
  }

  static void _styleCompactGrid(PdfGrid grid) {
    final PdfFont font75 = PdfStandardFont(PdfFontFamily.helvetica, 7.5);
    final PdfFont bold75 = PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold);

    grid.style.cellPadding = PdfPaddings(left: 5, right: 5, top: 2.2, bottom: 2.2);
    grid.style.font = font75;

    for (int i = 0; i < grid.headers.count; i++) {
      final hRow = grid.headers[i];
      hRow.style.backgroundBrush = PdfSolidBrush(tableHeaderBg);
      hRow.style.font = bold75;
    }

    for (int i = 0; i < grid.rows.count; i++) {
      final r = grid.rows[i];
      r.cells[0].style.font = bold75;
      r.cells[0].style.backgroundBrush = PdfSolidBrush(PdfColor(248, 250, 252));
    }
  }

  static void _styleGrid(PdfGrid grid) {
    final PdfFont font8 = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final PdfFont bold8 = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);

    grid.style.cellPadding = PdfPaddings(left: 6, right: 6, top: 3.5, bottom: 3.5);
    grid.style.font = font8;

    for (int i = 0; i < grid.headers.count; i++) {
      final hRow = grid.headers[i];
      hRow.style.backgroundBrush = PdfSolidBrush(tableHeaderBg);
      hRow.style.font = bold8;
    }

    for (int i = 0; i < grid.rows.count; i++) {
      final r = grid.rows[i];
      r.cells[0].style.font = bold8;
      r.cells[0].style.backgroundBrush = PdfSolidBrush(PdfColor(248, 250, 252));
    }
  }

}
