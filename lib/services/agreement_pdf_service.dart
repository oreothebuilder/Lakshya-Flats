import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Rect, Offset, debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Data bundle for populating the Lakshya Residency Rent & License Agreement
class RentalAgreementData {
  final String agreementDate;
  final String commencementDate;
  final String endingDate;
  final String studentFullName;
  final String mobileNumber;
  final String email;
  final String regNumber;
  final String dob;
  final String course;
  final String branch;
  final String hometownAddress;
  final String building;
  final String roomNumber;
  final String bedNumber;
  final String flatConfig;
  final String guardianName;
  final String guardianRelationship;
  final String guardianPhone;
  final String dietaryPreference;
  final String plan;
  final String rentalTerm;
  final String lockInPeriod;
  final int termMonths;
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

  final String bookingAmount;
  final String paymentPlan;
  final int totalInstallments;
  final List<String> installmentAmounts;
  final List<String> installmentDueDates;
  final bool optedMeals;
  final bool optedTransport;
  final bool optedLaundry;
  final bool optedCleaning;
  final bool optedWifi;
  final String ownerRemarks;
  final String studentSignatureTimestamp;

  RentalAgreementData({
    required this.agreementDate,
    this.commencementDate = '',
    this.endingDate = '',
    required this.studentFullName,
    required this.mobileNumber,
    required this.email,
    required this.regNumber,
    this.dob = '',
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
    this.lockInPeriod = "Complete Year (July to May) — 11 Months Lock-in (irrespective of late joining)",
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
    this.bookingAmount = '',
    this.paymentPlan = '',
    this.totalInstallments = 0,
    this.installmentAmounts = const [],
    this.installmentDueDates = const [],
    this.optedMeals = false,
    this.optedTransport = false,
    this.optedLaundry = false,
    this.optedCleaning = false,
    this.optedWifi = false,
    this.ownerRemarks = '',
    this.studentSignatureTimestamp = '',
  });
}

/// Generates the complete legally binding Lakshya Residency
/// Rent and License Agreement in PDF format across 23 fully utilized,
/// beautifully formatted pages matching the final legal PDF.
class AgreementPdfService {
  static const int totalPages = 23;

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

  /// Compiles all 23 pages and returns the PDF bytes
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
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 22),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      y += 24;

      page.graphics.drawString(
        "Rent and License AGREEMENT",
        bold13,
        brush: PdfSolidBrush(primaryBlue),
        bounds: Rect.fromLTWH(0, y, 523, 18),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      y += 32;

      // Summary Card
      page.graphics.drawRectangle(
        pen: PdfPen(borderGrey, width: 1.2),
        brush: PdfSolidBrush(tableHeaderBg),
        bounds: Rect.fromLTWH(20, y, 483, 160),
      );

      final double cardX = 35;
      double cardY = y + 16;

      void drawCardRow(String label, String value, {bool isHighlight = false}) {
        page.graphics.drawString(
          label,
          bold85,
          brush: PdfSolidBrush(textDark),
          bounds: Rect.fromLTWH(cardX, cardY, 150, 14),
        );
        page.graphics.drawString(
          value,
          isHighlight ? bold85 : regular85,
          brush: PdfSolidBrush(isHighlight ? primaryBlue : textDark),
          bounds: Rect.fromLTWH(cardX + 155, cardY, 280, 14),
        );
        cardY += 24;
      }

      drawCardRow("Agreement Date:", data.agreementDate);
      drawCardRow("Owner / Licensor:", "Mr. Ajay Singh (Lakshya Residency)");
      drawCardRow("Tenant / Licensee (Student):", data.studentFullName, isHighlight: true);
      drawCardRow("Allocated Room / Flat:", "Building ${data.building}, Room ${data.roomNumber}${data.bedNumber.isNotEmpty ? ', Bed ${data.bedNumber}' : ''}");
      drawCardRow("Tenant's Hometown Address:", data.hometownAddress.isNotEmpty ? data.hometownAddress : "On file in App Profile");

      y += 180;

      page.graphics.drawString(
        "This is a legally binding document. Please read carefully before signing / accepting digitally on the App.",
        italic9,
        brush: PdfSolidBrush(textMuted),
        bounds: Rect.fromLTWH(20, y, 483, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }

    // ==========================================
    // PAGE 2: Table of Contents (Part 1, Sections 1 to 22)
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
      y += 24;

      final List<Map<String, String>> toc1 = [
        {"title": "1. Parties and Recitals", "page": "4", "bold": "true"},
        {"title": "   Recitals", "page": "4"},
        {"title": "2. Nature of Agreement", "page": "4", "bold": "true"},
        {"title": "3. Definitions and Interpretation", "page": "5", "bold": "true"},
        {"title": "4. Term, Lock-In Period and Renewal", "page": "5", "bold": "true"},
        {"title": "5. Booking, Rent, Deposits and Payment Terms", "page": "6", "bold": "true"},
        {"title": "6. Package-Based Facilities (Optional Value-Added Services)", "page": "8", "bold": "true"},
        {"title": "   6.A Meals", "page": "8"},
        {"title": "   6.B Pick-up and Drop to College/Institute", "page": "8"},
        {"title": "   6.C Laundry and Cleaning", "page": "8"},
        {"title": "   6.D Wi-Fi / Internet Access", "page": "8"},
        {"title": "   6.E General Terms Applicable to All Package Facilities", "page": "9"},
        {"title": "7. Utilities and Common Area Charges", "page": "9", "bold": "true"},
        {"title": "8. Permitted Use of Premises and Occupancy Limits", "page": "9", "bold": "true"},
        {"title": "9. Tenant's General Obligations", "page": "11", "bold": "true"},
        {"title": "10. Prohibited Activities and Strict Conduct Rules", "page": "11", "bold": "true"},
        {"title": "   10.1 Damage to Property", "page": "11"},
        {"title": "   10.2 Drugs, Narcotics and Substance Abuse", "page": "12"},
        {"title": "   10.3 Activities Involving Minors", "page": "12"},
        {"title": "   10.4 Commercial, Business or Unlawful Trade Activity", "page": "12"},
        {"title": "   10.5 Unauthorised Occupants, Subletting and Relocation of Third Parties", "page": "13"},
        {"title": "   10.6 Mobile Application — Acceptable Use Policy", "page": "13"},
        {"title": "   10.7 General Nuisance, Safety and Miscellaneous Prohibitions", "page": "13"},
        {"title": "   10.8 Fights and Disputes Among Residents", "page": "14"},
        {"title": "11. House Rules — Curfew, Outings and Visitor Policy", "page": "14", "bold": "true"},
        {"title": "12. Co-Habitation / Live-in Arrangements", "page": "15", "bold": "true"},
        {"title": "13. Owner's Rights and Remedies on Breach", "page": "15", "bold": "true"},
        {"title": "14. Inspection, Entry and Room Reallocation", "page": "16", "bold": "true"},
        {"title": "15. Maintenance, Repairs and Damage Liability", "page": "16", "bold": "true"},
        {"title": "16. Security Deposit and Advance Charges — Deductions and Refund", "page": "16", "bold": "true"},
        {"title": "17. Termination of Agreement", "page": "17", "bold": "true"},
        {"title": "18. Consequences of Termination for Cause", "page": "17", "bold": "true"},
        {"title": "19. Indemnity and Limitation of Liability", "page": "18", "bold": "true"},
        {"title": "20. Health, Safety, Emergency and Personal Well-Being", "page": "18", "bold": "true"},
        {"title": "21. Force Majeure", "page": "19", "bold": "true"},
        {"title": "22. Confidentiality, Data Privacy and Promotional Use", "page": "19", "bold": "true"},
      ];

      for (var item in toc1) {
        final bool isBold = item["bold"] == "true";
        final font = isBold ? bold85 : regular85;
        _drawTocRow(page, item["title"]!, item["page"]!, font, y, 523);
        y += 18.0;
      }
    }

    // ==========================================
    // PAGE 3: Table of Contents (Part 2, Sections 23 to Signatures)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString(
        "TABLE OF CONTENTS (Contd.)",
        bold13,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      y += 28;

      final List<Map<String, String>> toc2 = [
        {"title": "23. Dispute Resolution and Governing Law", "page": "19", "bold": "true"},
        {"title": "24. General / Miscellaneous Provisions", "page": "19", "bold": "true"},
        {"title": "SCHEDULE A — Student Onboarding & Property Details", "page": "21", "bold": "true"},
        {"title": "SCHEDULE D — Furniture, Inventory and House Rules Acknowledgement", "page": "21", "bold": "true"},
        {"title": "ANNEXURE I — CO-HABITATION / LIVE-IN CONSENT FORM", "page": "22", "bold": "true"},
        {"title": "   Resident 1", "page": "22"},
        {"title": "   Resident 2", "page": "22"},
        {"title": "   Acknowledged by Owner / Warden", "page": "22"},
        {"title": "TENANT'S DECLARATION", "page": "22", "bold": "true"},
        {"title": "SIGNATURES", "page": "23", "bold": "true"},
        {"title": "   Witnesses", "page": "23"},
      ];

      for (var item in toc2) {
        final bool isBold = item["bold"] == "true";
        final font = isBold ? bold85 : regular85;
        _drawTocRow(page, item["title"]!, item["page"]!, font, y, 523);
        y += 22.0;
      }
    }

    // ==========================================
    // PAGE 4: Section 1 (Parties and Recitals) & Section 2 (Nature of Agreement)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString("1. Parties and Recitals", bold11, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y, 523, 16));
      y += 18;

      final guardianStr = data.guardianName.isNotEmpty ? data.guardianName : "Guardian on file";
      final addressStr = data.hometownAddress.isNotEmpty ? data.hometownAddress : "On file in App Profile";

      final String pText = """This Rent/License Agreement ("Agreement") is made and entered into on this date ${data.agreementDate} by and between:

OWNER / LICENSOR: Mr. Ajay Singh , hereinafter referred to as the "Owner" representing Lakshya Residency, located at Lakshay Residency and Flats, Tejasvi Greens, L2 L3, behind barcode cafe, near Manipal University Jaipur, Dahmi Kalan, Dahmi Khurd, Rajasthan 303007, of the ONE PART;

AND

TENANT / LICENSEE: ${data.studentFullName} who’s guardian is $guardianStr, and their hometown is located at $addressStr, of the OTHER PART.

Where the context so requires, the Owner and the Tenant are hereinafter individually referred to as a "Party" and collectively as the "Parties".

Recitals
1.1 The Owner is the lawful owner and/or authorised managing operator of the residential unit(s) known as Lakshya Residency, and is competent to let out/license the said premises for residential and allied purposes.

1.2 The Tenant has approached the Owner seeking accommodation on a rental / leave-and-license basis at the Residency, either on a standalone rent basis or coupled with certain optional package-based facilities (meals, transport, laundry, cleaning, Wi-Fi, etc.), and the Owner has agreed to provide the same on the terms and conditions recorded in this Agreement.

1.3 This Agreement, together with its Schedules (A,D and Annexure I, and any further Annexures executed in writing by both Parties, constitutes the entire understanding between the Parties in relation to the subject matter herein.

1.4 This Agreement, along with any rent receipts, notices, and renewal confirmations, will also be maintained on the Lakshya Residency mobile application ("the App") for administrative and compliance purposes.

1.5 This Agreement, including Schedule A, is auto-generated using the information the Tenant submits at the time of onboarding on the App — including personal, academic, identity, room-allocation, guardian, and payment-plan details — and such App records shall be read together with, and form an integral part of, this Agreement. Upon completion of onboarding, the Tenant shall review and digitally sign this auto-generated Agreement on the App, which shall also bear the Owner's digital countersignature.

2. Nature of Agreement
2.1 This Agreement is intended to constitute a leave and licence arrangement under applicable Indian law, whereby the Licensor grants the Licensee a limited, personal and non-transferable permission to use and occupy the specified Premises within Lakshya Residency solely for the residential purpose and for the Term expressly stated herein, subject to the terms and conditions of this Agreement and payment of the applicable Licence Fee and opted Package Charges.

2.2 The Owner retains overall control, management, and right of entry over the Premises and Common Areas at all times, subject to Clause 14 (Inspection, Entry and Room Reallocation).""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 5: Section 3 (Definitions) & Section 4 (4.1 to 4.3)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString("3. Definitions and Interpretation", bold11, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y, 523, 16));
      y += 18;

      final String pText = """3.1 "Premises" means the specific flat/room (Building ${data.building}, Room/Flat ${data.roomNumber}${data.bedNumber.isNotEmpty ? ', Bed ${data.bedNumber}' : ''}), along with fittings, fixtures, furniture and appliances provided therein, allotted to the Tenant at Lakshya Residency, as recorded in the app.
3.2 "Common Areas" means all shared spaces within the Residency including but not limited to corridors, staircases, terrace, dining hall, common kitchen, lounge, and parking area, which are not for the exclusive use of any single Tenant.
3.3 "Package Facilities" means the optional services which the Tenant may avail in addition to the base rent, including meals, pick-up and drop transport, laundry, cleaning, and Wi-Fi/internet access.
3.4 "App" means the official Lakshya Residency mobile application through which onboarding, rent/fee payments, service requests, complaints, digital copies of this Agreement, notices, and communication between Owner and Tenant are facilitated.
3.5 "Booking Amount" means the amount paid by the Tenant to reserve a room/bed prior to move-in, as recorded in Schedule B, which is non-refundable in the manner described in Clause 5.
3.6 "Security Deposit" means the interest-free amount collected by the Owner from the Tenant as security against damage, unpaid dues, or breach of this Agreement, refundable subject to Clause 16.
3.7 "Academic Session" or "Lock-in Period" means the period for which the Tenant has subscribed, as determined by the Plan (${data.plan}) and the Rental Term selected by the Tenant at onboarding on the App (${data.lockInPeriod}), which is the minimum period for which the Tenant commits to reside at the Premises.
3.8 "Minor" means any individual who has not completed eighteen (18) years of age as on the date of the relevant event.
3.9 "Authorised Occupant" means only the Tenant named who is onboarded on the Lakshya Residency app and any additional occupant(s) whose details have been disclosed to and expressly approved in writing (including via the App) by the Owner prior to occupation.
3.10 Words importing the singular include the plural and vice versa; words importing any gender include all genders; references to "writing" include communication through the App unless stated otherwise.

4. Term, Lock-In Period and Renewal
4.1 The Academic Session / Term of this Agreement shall be the Rental Term / Lock-in Period corresponding to the Plan and the duration selected by the Tenant at onboarding on the App OR/AND period for which the tenant is extending their stay at Lakshya residency, unless terminated earlier under Clause 17.
4.2 The Tenant undertakes to remain in occupation of the Premises for the full Lock-in Period coinciding with the Academic Session. The Lock-in Period applies uniformly to Tenants on a rental-only basis and to Tenants who have opted for the Package Facilities.
4.3 If the Tenant does not take possession of the Premises within 30 days of the agreed move-in date thereafter, the Owner may treat this as a showup breach and terminate this Agreement forthwith, with the consequences set out in Clause 16.4 and Clause 18.""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 6: Section 4 (4.4 to 4.6) & Section 5 (5.1 to 5.7)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """4.4 Renewal: This Agreement may be renewed for a further Academic Session on mutually agreed terms. If failed to inform the person in charge, the Tenant shall vacate the Premises on or before the last day of the Term.
4.5 Continued occupation beyond the Term without a signed renewal/ upfront confrontation shall not be construed as an automatic extension, and the Owner may charge holding-over compensation above the last applicable rent for each day of unauthorised continued occupation, in addition to other remedies available in law.
4.6 Automatic Termination by Efflux of Time: Unless renewed under Clause 4.4, this Agreement shall stand automatically terminated upon expiry of the Academic Session/Term. All outstanding dues as on such date shall become immediately payable and shall be adjusted against the Security Deposit in accordance with Clause 16.

5. Booking, Rent, Deposits and Payment Terms
5.1 Booking Amount: To reserve a room/bed, the Tenant shall pay the Booking Amount. The Booking Amount is strictly non-refundable once paid, including where the Tenant subsequently withdraws or cancels the booking prior to move-in, save where the Owner is unable to provide the booked accommodation at all.
5.2 Advance Payment Before Move-In: A prospective Tenant wishing to move in must inform the person incharge well in advance and shall pay the full quoted joining amount — comprising the Booking Amount(that may be compensated to the actual fees), Security Deposit, and/or the first applicable installment, as the case may be — upfront and in advance of being granted possession or occupation of the Premises.
5.3 Payment Plan — Rental-Only Tenants: A Tenant availing accommodation on a purely rental basis shall be billed for the entire Academic Session. At onboarding, the Tenant shall elect, on the App, either to (a) pay Rent on a monthly basis, or (b) pay the full session's Rent upfront in installments of 3 (three), 4 (four), or such other number of installments as the Tenant chooses. The exact installment amounts and due dates shall be fixed on the App at the time this election is made.
5.4 Payment Plan — Package Tenants: A Tenant who opts for the complete package (Rent plus Package Facilities) shall also pay in installments. The number of installments and the corresponding due dates shall likewise be decided at onboarding, on the App.
5.5 Default: If any installment or monthly Rent is not paid by its due date, the Tenant shall be treated as being "in default" and the late payment charge shall apply for each day of delay. Persistent default is additionally governed by Clause 17.3 (termination for non-payment).
5.6 Security Deposit: A refundable, interest-free Security Deposit shall be paid by the Tenant prior to handover of possession. The Security Deposit shall not be adjusted against Rent during the subsistence of this Agreement, and is subject to forfeiture under Clause 5.8 and Clause 16.4.
5.7 Non-Refundability on Early Exit: If the Tenant leaves, discontinues occupation, or withdraws from this Agreement before completing the full specified Period / Academic Session referred to in Clause 4, both the Security Deposit and the Booking Amount shall stand fully and absolutely forfeited and shall not be refunded under any circumstance, and outstanding Rent/Package charges for the remainder of the Academic Session shall remain payable. This applies equally whether the early departure is on account of the Tenant's personal choice, academic withdrawal, disciplinary action, or any other reason not attributable to the Owner's default.""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 7: Section 5 (5.10 to 5.14) & Fraud Alert Box
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """5.10 Late Payment Charge: Beyond a grace period of 3 (three) days from the due date, a late payment charge shall accrue for every day of delay, without prejudice to the Owner's right to treat persistent default as a material breach under Clause 17.
5.11 Payments declaration Only Through the App — No Other Channel Accepted: ALL payments to the Owner (Booking Amount, Security Deposit, Rent, installments, Package charges, fines, or any other dues) shall be made ONLY through the payment details listed on the App — namely the bank account number and UPI ID displayed within the App. The Owner does NOT accept, authorise, or acknowledge any payment made through any other bank account, UPI ID, cash collection, or any individual or agent, however described. The Tenant and their parent/guardian must never trust or make payment to any person claiming to represent Lakshya Residency outside the App, and the Owner shall bear no responsibility whatsoever for payments made to any unauthorised or fraudulent party.
5.12 KYC and Verification: The Tenant shall submit, through the App at onboarding, valid identity documents (a Government-issued photo ID and College ID, as recorded in the app) and a recent photograph, and shall cooperate with any police verification, tenant registration, or similar process required by the Owner or local administration.
5.13 Mode of Payment: All payments under this Agreement shall be made through UPI, net banking, debit/credit card, or other digital payment methods configured on the App. Cash payments are discouraged and, if exceptionally accepted by the Owner, must be accompanied by an official receipt issued through the App.
5.14 Taxes: All amounts payable by the Tenant are exclusive of applicable Goods and Services Tax (GST) or other statutory levies, which shall be charged additionally if and when applicable by law.""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 300));
      y += 280;

      // Fraud Alert Box
      page.graphics.drawRectangle(
        pen: PdfPen(alertBorder, width: 1.5),
        brush: PdfSolidBrush(alertBg),
        bounds: Rect.fromLTWH(0, y, 523, 110),
      );

      page.graphics.drawString(
        "CRITICAL FRAUD ALERT — MANDATORY PAYMENT INSTRUCTION",
        bold10,
        brush: PdfSolidBrush(alertBorder),
        bounds: Rect.fromLTWH(12, y + 10, 499, 14),
      );

      final String alertText = "ALL PAYMENTS MUST BE MADE SOLELY THROUGH THE OFFICIAL LAKSHYA RESIDENCY APP / PLATFORM.\n"
          "Do NOT pay cash, transfer funds to personal UPI IDs, or make bank transfers to any person claiming to be an agent, broker, manager, warden, or owner outside of the verified account details displayed inside the Lakshya Residency App.\n"
          "The Owner shall NOT be liable or responsible for any payment made outside the App.";

      _drawParagraph(page, alertText, regular8, Rect.fromLTWH(12, y + 28, 499, 75));
    }

    // ==========================================
    // PAGE 8: Section 6 (Package-Based Facilities, 6.A to 6.D)
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

      final String pText = """The Tenant may choose to avail one or more optional facilities offered by the Owner as part of a consolidated Package, subject to additional payment of applicable Package Charges. The specific facilities opted for by the Tenant, the duration for which they are opted, and the corresponding charges are set out in Schedule C to this Agreement. The following terms govern each package facility:

6.A Meals
6.1 Where opted, meals shall be provided in accordance with the meal plan and menu published by the Residency from time to time.
6.2 Meal timings shall be communicated via the App. A Tenant missing a meal during scheduled hours shall not be entitled to a replacement, takeaway, or refund.
6.3 The Owner shall take reasonable care in food preparation and hygiene. The Tenant shall inform the management of any severe food allergies at the time of admission; the Owner does not guarantee allergen-free preparation in a communal kitchen environment.
6.4 Taking Residency cutlery, utensils, or bulk food items out of the dining hall or into individual rooms without written permission from the warden is prohibited.

6.B Pick-up and Drop to College/Institute
6.5 Where opted, transport shall operate on schedules coinciding with standard college class hours, as notified on the App. The vehicle shall operate on fixed routes with designated stops.
6.6 The Tenant shall adhere strictly to pickup and departure times. The vehicle shall not wait for late passengers. The Owner shall not be liable for any Tenant missing a class or exam on account of unavoidable traffic delay, vehicle breakdown, or weather conditions.
The transportation facilities are outsourced, so the tenants are requested to contact the concerned cab person/driver for anything regarding the cab. Cab charges are non-refundable under any circumstances. In case the cab is not available on any day, the Tenant must arrange their own transport.

6.C Laundry and Cleaning
6.7 Where opted, laundry service will be provided. The Owner/service shall not be liable for ordinary wear, shrinkage, or colour-run inherent to fabric type, nor for items left unclaimed beyond thirty (30) days. The Tenant is advised to verify items at the time of delivery; complaints raised thereafter may not be entertained. The laundry services are outsourced so the tenants are requested to contact the concerned laundry person for anything regarding the laundry.

6.D Wi-Fi / Internet Access
6.9 Where opted, Wi-Fi/internet access shall be provided on a shared-bandwidth, best-effort basis, subject to a Fair Usage Policy. The Owner does not guarantee uninterrupted, error-free, or specific-speed connectivity, and shall not be liable for any inconvenience, loss, or damage arising from unavailability or malfunction of the network.""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 9: Section 6.D (6.10), 6.E (6.11 to 6.14), Section 7 (7.1 to 7.4), Section 8 (8.1)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """6.10 The Wi-Fi facility shall be used strictly for lawful purposes. The Tenant shall not use the network to download, host, stream, or transmit pirated content or malware; to access or distribute content depicting the exploitation or abuse of minors (which shall be reported to law enforcement immediately upon detection); or to carry out cyber-crime, hacking, or unauthorised access to third-party systems. Any such misuse shall entitle the Owner to immediately suspend access and pursue legal action, including reporting to the police and/or the cyber-crime authorities.

6.E General Terms Applicable to All Package Facilities
6.11 Third-Party Facilitation: For services rendered through third-party vendors (including laundry, the internet service provider), the Owner acts only as a facilitator/aggregator and is not itself the service provider. The Owner shall not be liable for deficiency, delay, damage, or loss caused by such a third-party vendor; the Tenant's remedy, if any, in such cases lies against the vendor directly.
6.12 Complaint Window: Any complaint regarding a Package Facility must be raised via the App/email. If a timely complaint is not resolved within 15 days, the Tenant shall escalate it to the Owner/warden in writing/in person.
6.13 Misuse, abuse, or fraudulent claims relating to any Package Facility (e.g., false damage claims, unauthorised sharing of the facility with non-residents, tampering with service logs on the App) shall be treated as a material breach of this Agreement under Clause 10 and Clause 17.
6.14 National Holidays, Summer Break and Winter Break: During national holidays and during the summer and winter breaks, there is no confirmation or assurance of meals or of any other services, including pick-up and drop (cab), cleaning, laundry and similar services. Availability of any such service during these periods shall be communicated through the App at the Owner’s discretion, and the Owner shall not be liable for its non-availability.

7. Utilities and Common Area Charges
7.1 Electricity shall be charged at the rate of ₹12 (Rupees Twelve only) per unit consumed, as per meter/sub-meter reading, billed monthly through the App. In a shared-occupancy room, electricity charges shall be divided equally among all occupants of that room, unless otherwise agreed in writing.
7.2 Common maintenance charges can be charged separately as per actuals, 
7.3 The Tenant shall use electrical appliances, water, and other utilities responsibly and shall not install high-load appliances (e.g., heaters, induction cooktops, air-conditioners) without the Owner's prior written consent, given the shared electrical load of the Residency.
7.4 Common Area maintenance charges, if applicable, shall be shared proportionately among all Tenants of the Residency and billed through the App.

8. Permitted Use of Premises and Occupancy Limits
8.1 The Premises shall be used solely for lawful residential purposes by the Tenant (and any Authorised Occupant) for the duration of their bona fide studies, and for no other purpose whatsoever.""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 10: Section 8 (8.2 to 8.5) & Flat Configuration Table
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """8.2 The Tenant shall comply with all house rules of Lakshya Residency as displayed on the premises and/or communicated through the App, including the curfew, outing, and visitor policy at Clause 11, which shall be deemed part of this Agreement.
8.3 The Tenant shall not use the Premises in any manner that causes nuisance, annoyance, danger, or disturbance to the Owner, other tenants, neighbours, or the general public.
8.4 Maximum Occupancy Limits: To ensure resident safety, comfort, and compliance with fire and building-safety norms, the number of persons residing in any flat shall not exceed the limits below:""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 110));
      y += 105;

      // Table for Flat Configuration
      final PdfGrid occGrid = PdfGrid();
      occGrid.columns.add(count: 2);
      occGrid.columns[0].width = 250;
      occGrid.columns[1].width = 273;

      occGrid.headers.add(1);
      final PdfGridRow occHdr = occGrid.headers[0];
      occHdr.cells[0].value = "Flat Configuration";
      occHdr.cells[1].value = "Maximum Persons Permitted";

      final PdfGridRow r1 = occGrid.rows.add();
      r1.cells[0].value = "1 BHK";
      r1.cells[1].value = "2 persons";

      final PdfGridRow r2 = occGrid.rows.add();
      r2.cells[0].value = "2 BHK";
      r2.cells[1].value = "4 persons";

      final PdfGridRow r3 = occGrid.rows.add();
      r3.cells[0].value = "3 BHK";
      r3.cells[1].value = "6 persons";

      _styleGrid(occGrid);
      occGrid.draw(page: page, bounds: Rect.fromLTWH(0, y, 523, 100));
      y += 105;

      final String pPost = """8.5 Occupancy beyond the limits in Clause 8.4 — whether through unauthorised additional occupants or otherwise — is strictly prohibited and constitutes a material breach entitling the Owner to the remedies under Clause 13 and Clause 17.""";

      _drawParagraph(page, pPost, regular8, Rect.fromLTWH(0, y, 523, 50));
    }

    // ==========================================
    // PAGE 11: Section 9 (Tenant's Obligations) & Section 10 (10.1.1)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString(
        "9. Tenant's General Obligations",
        bold11,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 16),
      );
      y += 18;

      final String pText = """9.1 Pay Rent, installments, and all Package Facility charges on time as per Clause 5.
9.2 Maintain the Premises, fittings, fixtures, and furnishings provided in good and tenantable condition, normal wear and tear excepted.
9.3 Promptly report any damage, malfunction, leakage, or safety hazard in the Premises or Common Areas to the Owner/App helpdesk.
9.4 Permit the Owner or its authorised representative to inspect the Premises in accordance with Clause 14.
9.5 Not make any structural alteration, additional construction, drilling, or fixture installation without the Owner's prior written consent.
9.6 Comply with all applicable laws, municipal regulations, society/RWA rules, and fire-safety norms during occupation.
9.7 Keep the Owner informed, through the App, of correct and current contact details and guardian/emergency contact information.
9.8 Vacate and hand over peaceful, vacant, and undamaged possession of the Premises upon expiry or termination of this Agreement, along with all keys, access cards, and Residency-issued property.
9.9 Keep personal valuables and belongings securely locked away when absent from the Premises. The Owner/Residency staff shall not be liable for loss of personal belongings from the Premises, except to the extent caused by the Owner's proven gross negligence.
9.10 Cooperate with the Owner's repair, maintenance, and housekeeping staff, including during the Tenant's absence and specifically during the summer vacation/break period when block-level or Residency-wide maintenance work may be undertaken (see Clause 15.4). The Tenant shall not obstruct such work.
9.11 Cooperate with police verification, tenant registration, or other formalities required by applicable law, as referred to in Clause 5.11.

10. Prohibited Activities and Strict Conduct Rules
The Tenant expressly acknowledges and agrees that the activities described below are strictly prohibited within the Premises, the Residency, and in connection with use of the App. Any breach of this Clause 10 shall be treated as a material and fundamental breach of this Agreement, entitling the Owner to the remedies set out in Clause 13 and Clause 17, including but not limited to immediate termination, forfeiture of the Security Deposit and Booking Amount, eviction in accordance with law, and initiation of criminal/civil legal proceedings.

10.1 Damage to Property
10.1.1 The Tenant shall not intentionally or negligently damage, deface, remove, or destroy any part of the Premises, Common Areas, furniture, fixtures, fittings, electrical/plumbing installations, or any property belonging to the Owner, the Residency, or other tenants.""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 12: Section 10 (10.1.2 to 10.4.2)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """10.1.2 Any damage beyond normal wear and tear shall be assessed by the Owner and the cost of repair/replacement shall be recovered from the Security Deposit and/or directly from the Tenant. In a shared room, such cost may be recovered jointly from all occupants of that room, without prejudice to the Owner's right to pursue further legal remedies for wilful or grossly negligent damage.
10.1.3 The Tenant shall be liable for damage caused by any guest, visitor, or Authorised Occupant permitted onto the Premises by the Tenant.

10.2 Drugs, Narcotics and Substance Abuse
10.2.1 The possession, consumption, cultivation, storage, sale, distribution, or facilitation of any narcotic drug or psychotropic substance banned under the Narcotic Drugs and Psychotropic Substances Act, 1985 (or any successor/equivalent law) is absolutely and strictly prohibited within the Premises, the Residency, and its Common Areas. Smoking, drinking, and chewing tobacco are likewise governed by the Residency's house rules and applicable law.
10.2.2 Upon discovery or reasonable suspicion of any activity described in this Clause 10.2, the Owner shall be entitled, without further notice, to (a) immediately restrict/terminate occupancy, (b) confiscate and hand over any illegal substance/paraphernalia to the police, (c) inform the Tenant's parent/guardian, and (d) lodge a formal police complaint and fully cooperate with any resulting investigation or prosecution, at the Tenant's sole cost and risk.
10.2.3 The Tenant shall indemnify the Owner against any loss, penalty, or legal consequence arising from a violation of this Clause 10.2 by the Tenant or any person permitted onto the Premises by the Tenant.

10.3 Activities Involving Minors
10.3.1 No Minor shall reside at, be housed in, or stay overnight at the Premises unless such Minor is accompanied by, and under the direct supervision of, a parent or legal guardian, or unless prior written consent has been obtained from the Owner along with complete identity and guardian-contact details.
10.3.2 The Tenant shall not engage, permit, or facilitate any activity on the Premises or through the App that endangers the safety or welfare of a Minor, or that constitutes an offence under the Protection of Children from Sexual Offences (POCSO) Act, 2012, the Juvenile Justice (Care and Protection of Children) Act, 2015, or the Indian Penal Code / Bharatiya Nyaya Sanhita.
10.3.3 The Tenant shall not possess, download, store, create, or distribute child sexual abuse material (CSAM) or any exploitation material involving Minors, using the Residency's Wi-Fi network or on the Premises. Any violation of this sub-clause shall result in immediate termination, eviction, forfeiture of deposits, and a mandatory immediate report by the Owner to law enforcement authorities.

10.4 Commercial, Business or Unlawful Trade Activity
10.4.1 The Premises shall not be used to carry on any trade, business, commercial activity, manufacturing, or professional practice, whether registered or unregistered, including using the Premises as a registered office, godown, retail pickup point, or dark-store hub.
10.4.2 The Tenant shall not run or permit to be run from the Premises any unlawful enterprise, including gambling, betting, sex work, multi-level marketing (MLM) schemes, or financial fraud.""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 13: Section 10 (10.4.3 to 10.7 part)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """10.4.3 Violation of this Clause 10.4 shall entitle the Owner to immediately terminate this Agreement, report the activity to the relevant municipal and tax authorities, and claim damages from the Tenant.

10.5 Unauthorised Occupants, Subletting and Relocation of Third Parties
10.5.1 Subletting, licensing, sharing, assigning, or parting with possession of the Premises (or any bed/portion thereof) to any third person, whether for money or free of charge, is strictly prohibited.
10.5.2 No person other than the Tenant (and Authorised Occupants) shall be permitted to reside in the Premises. Permitting any third person to stay at the Premises for a cumulative period exceeding seven (7) days without prior written disclosure to and written permission from the Owner shall be deemed an unauthorised subletting / illegal occupation under this Clause.
10.5.3 The Tenant shall not allow any person facing criminal charges, an active warrant, or an externment/interim restraining order to stay at the Premises.

10.6 Mobile Application — Acceptable Use Policy
10.6.1 The App is an essential operational tool of Lakshya Residency. The Tenant shall use the App solely for bona fide purposes connected with this Agreement.
10.6.2 The Tenant shall not:
• Hack, probe, reverse-engineer, decompile, or attempt to compromise the App's security, API, or databases;
• Submit false, forged, altered, or misleading identity documents, payment receipts, or KYC information through the App;
• Interfere with the payment gateway, manipulate transaction references, or generate fraudulent payment confirmations;
• Harass, abuse, defame, threaten, or send unsolicited bulk messages to other residents, staff, or the Owner through the App's messaging or complaint facilities;
• Post false or maliciously defamatory reviews, tickets, or allegations through the App.
10.6.3 The Tenant is solely responsible for maintaining the confidentiality of their App login credentials. Any action taken through the Tenant's authenticated App session shall be deemed to have been taken by the Tenant.
10.6.4 Compromising the App's integrity or attempting payment fraud through the App shall, in addition to being a material breach of this Agreement, result in immediate suspension of App access, civil recovery proceedings, and filing of a First Information Report (FIR) under the Information Technology Act, 2000 and the Indian Penal Code / Bharatiya Nyaya Sanhita.

10.7 General Nuisance, Safety and Miscellaneous Prohibitions
The Tenant shall not engage in any of the following activities:
• Playing loud music, shouting, or causing disturbance during Quiet Hours (from 23:00 hours to 07:00 hours);
• Storing hazardous, flammable, explosive, or toxic materials, gas cylinders (other than Owner-approved cooking gas arrangements), fireworks, or firearms/weapons on the Premises;""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 14: Section 10.7 (cont), 10.8 & Section 11 (House Rules)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """• Bringing pets into the Residency without the Owner's prior written consent;
• Tampering with CCTV cameras, fire alarms, smoke detectors, electrical panels, water meters, or security equipment;
• Hanging clothes, placing shoes/racks, or leaving waste, bicycles, or personal property in Common Areas or fire escapes;
• Consuming alcohol, banned substances, or tobacco in Common Areas;
• Littering, spitting, or defacing walls, doors, or furniture;
• Tampering with, duplicating, or lending keys, RFID cards, or access credentials to non-residents;
• Throwing waste, liquids, or objects out of windows, balconies, or onto neighbouring properties;
• Entering areas marked "Staff Only", electrical/pump rooms, or the terrace during restricted hours without permission.

10.8 Fights and Disputes Among Residents
10.8.1 Physical violence, assault, threatening behaviour, ragging, extortion, harassment (verbal, physical, or sexual), or bullying of any fellow resident, staff member, or neighbour is strictly prohibited.
10.8.2 Lakshya Residency maintains a strict zero-tolerance policy towards ragging, harassment of fellow students, and gender-based offences. Any incident shall be reported to the local police and to the resident's educational institution immediately.
10.8.3 The Tenant shall be liable for all harm, medical expenses, property damage, and legal consequences arising from any physical altercation or dispute initiated or participated in by the Tenant.

11. House Rules — Curfew, Outings and Visitor Policy
11.1 Outing Hours: The Tenant may move within the immediate vicinity of the Residency until ______ hours. Venturing outside the city/campus area requires prior intimation to the Tenant's parent/guardian and to the Owner/warden.
11.2 Door-Closing Time: The main gate/door of the Residency shall close at ______ hours in summer and ______ hours in winter. The Tenant shall return to the Residency before this time.
11.3 Late Entry: A Tenant seeking to return after the closing time for a genuine reason must obtain prior permission from their parent/guardian and the warden/Owner. Unauthorised late entry may attract a penalty or disciplinary action, and repeated late entry may be reported to the Tenant's parent/guardian.
11.4 Night-Out / Overnight Absence: The Tenant must submit a written/App-based night-out application, noting the time of departure in the Residency's register, and obtain the Owner's/warden's approval — ordinarily conditional on parental consent — before staying away from the Residency overnight.
11.5 Overnight Guests: Overnight stay of any outside friend or visitor in the Tenant's room is not permitted, save as provided under Clause 12 (Co-Habitation) or with the Owner's express prior written consent. A visitor of a different gender than the room's registered occupants shall not stay overnight in the room, and may only be received during permitted visiting hours in designated common areas, consistent with the Residency's safety and decorum policy.
11.6 If the Tenant does not return by the curfew time without prior permission and cannot be reached, the Owner may inform the Tenant's parent/guardian. The Owner shall not be liable for any mishap suffered by the Tenant while outside the Residency without having taken due permission.""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 15: Section 12 (Co-Habitation) & Section 13 (13.1, 13.2 part)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString(
        "12. Co-Habitation / Live-in Arrangements",
        bold11,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 16),
      );
      y += 18;

      final String pText = """12.1 Where an adult Tenant (18 years of age or above) wishes to reside at the Premises together with a partner in a live-in / co-habiting arrangement, the Tenant shall, prior to admission or prior to commencing such an arrangement, inform their parent(s)/legal guardian(s) of the same.
12.2 Both cohabiting residents shall execute and submit to the Owner a signed Co-Habitation Consent Form, in the format at Annexure I to this Agreement, either physically or digitally through the App, expressly confirming that their decision to reside together is mutual, voluntary, and free of coercion.
12.3 The Owner permits such an arrangement purely as an accommodation facilitator and assumes no responsibility for the personal, emotional, financial, or legal consequences of the relationship between the cohabiting residents. In the event of any dispute, separation, allegation, or incident arising between such residents, the Owner shall not be held liable in any manner whatsoever, save for matters arising from the Owner's own proven negligence or wilful misconduct in the management of the Premises.
12.4 This Clause applies only where both cohabiting residents are adults. Any arrangement involving a Minor is additionally governed by, and must comply with, Clause 10.3 (Activities Involving Minors), including express guardian consent, and shall not be permitted in the absence of such consent.
12.5 Nothing in this Clause obligates the Owner to allot a shared room to cohabiting residents; room/bed allocation remains subject to availability, the Owner's policies, and the occupancy limits at Clause 8.4.

13. Owner's Rights and Remedies on Breach
13.1 Right of Admission: The Owner reserves the right of admission to the Residency and may, at its sole discretion, refuse, defer, or cancel any booking/admission — including after provisional acceptance — without being obliged to disclose reasons, subject to the Owner's cancellation/refund policy then in force.
13.2 Without prejudice to any other right or remedy available under this Agreement or in law, upon the occurrence of any breach described in Clause 10 (or any other material breach of this Agreement), the Owner shall be entitled to any or all of the following remedies, at its sole discretion:
• Issue a written warning through the App specifying the breach and requiring rectification within a stipulated period;
• Immediately suspend access to any or all Package Facilities and/or the App, without refund for the suspended period;
• Forfeit the Security Deposit and Booking Amount, in whole or in part, to the extent of loss, damage, or dues arising from the breach;
• Terminate this Agreement with immediate effect (in cases of illegal activity, drug-related offences, offences involving Minors, or serious damage/danger) or upon notice as specified in Clause 17 (for other breaches), and require the Tenant to vacate the Premises;
• Lodge a formal complaint with the local police station, cyber-crime cell, municipal authority, educational institution, or any other appropriate government or regulatory authority;""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 16: Section 13 (cont), Section 14, Section 15 & Section 16 (16.1 part)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """• Pursue civil proceedings for recovery of dues, damages, and costs, and/or support criminal proceedings where the breach constitutes an offence under Indian law;
• Escalate the matter to the Tenant's parent/legal guardian and/or educational institution, where reasonably necessary for safety, disciplinary, or recovery purposes.
13.3 The Owner's exercise of, or delay in exercising, any right under this Clause shall not be construed as a waiver of that right or of any other right available to the Owner.

14. Inspection, Entry and Room Reallocation
14.1 The Owner or its authorised representative may enter the Premises for inspection, maintenance, or verification purposes.
14.2 The Tenant shall not unreasonably deny access for such inspection or emergency entry.
14.3 The Owner may carry out necessary repair and maintenance work in the Premises/Residency at its discretion, including during the Tenant's absence, and the Tenant shall have no objection to entry for such purpose, subject to reasonable care of the Tenant's belongings by the Owner's staff.
14.4 Room / Building Reallocation: The Owner reserves the right, for operational reasons, to shift/transfer the Tenant from one room/bed to another, or from one building/property under the Residency to another, on similar terms. Where such a shift involves any change in charges, the same shall be recorded via an addendum or an updated Schedule on the App.

15. Maintenance, Repairs and Damage Liability
15.1 For Tenants staying on a purely rental (non-package) basis, the first month's routine maintenance and any repair required in the Premises shall be attended to by the Owner at no additional cost. From the second month of the Term onward, day-to-day maintenance and minor shall be arranged and borne by the Tenant.
15.2 All repair/maintenance requests shall be logged through the App, and the Owner shall use reasonable efforts to address them within a reasonable timeframe.
15.3 The inventory of furniture, fixtures, and appliances provided in the Premises should be used with care. The Tenant shall verify this inventory at the time of possession and shall be liable for any shortfall or damage identified at the time of vacating, save for normal wear and tear.
15.4 Summer Break Maintenance: The Owner may undertake block-level, floor-level, or Residency-wide maintenance, repainting, pest control, or renovation work during the summer vacation/break period (or any other declared maintenance window). The Tenant shall cooperate with the Owner's staff/contractors for access, temporary relocation of belongings, or temporary access restriction during such maintenance, and shall not obstruct such work.

16. Security Deposit and Advance Charges — Deductions and Refund
16.1 The Owner may deduct from the Security Deposit: (a) unpaid Rent, installments, or Package Facility charges; (b) cost of repair or replacement of damaged property under Clause 10.1; (c) unpaid utility or common area""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 17: Section 16 (cont), Section 17 & Section 18 (18.1)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """charges; (d) any penalty or holding-over compensation validly due under this Agreement; and (e) any other amount lawfully due from the Tenant to the Owner.
16.2 Where the Tenant has completed the full Lock-in Period / Academic Session and dues stand settled, the balance Security Deposit shall be refunded.
16.3 Non-Refund on Early Exit: Notwithstanding Clause 16.1 and 16.2, and as also stated in Clause 5.8, if the Tenant vacates the Premises, discontinues occupation, or withdraws from this Agreement before completing the full Lock-in Period / Academic Session, the entire Security Deposit and the Booking Amount shall stand absolutely forfeited and shall not be refunded under any circumstance, and outstanding Rent/Package charges for the remaining Academic Session shall remain payable, without prejudice to the Owner's other rights.

17. Termination of Agreement
17.1 Owner may terminate the residency of tenant prior to expiry of the Term without being held for giving any.
17.2 The Owner may terminate residency of tenant with immediate effect and without notice in the event of: (a) any breach falling under Clause 10.2 (drugs/narcotics) or Clause 10.3 (offences involving Minors); (b) any act endangering the life, safety, or property of the Owner, staff, or other tenants; (c) any activity that is unlawful and exposes the Owner or the Residency to legal or regulatory liability; (d) breach of the occupancy limits at Clause 8.4; or (e) co-habitation without the consent form required under Clause 12.2.
17.3 Non-Payment: If Rent, an installment, or Package charges remain unpaid beyond 3 days from the due date, the late payment charge under Clause 5.9 applies. If such amount remains unpaid beyond 7 days from the due date, or if there is a delay beyond 7 days for a second consecutive billing period, the Owner may terminate this Agreement forthwith, without further notice, and require the Tenant to vacate within forty-eight (48) hours.
17.4 Other Breaches: For any material breach of this Agreement not covered by Clauses 17.2 or 17.3, the Owner may issue a written notice through the App requiring the Tenant to remedy the breach within 7 (seven) days. If the breach is not remedied within the notice period, this Agreement shall stand terminated upon expiry of the notice.

18. Consequences of Termination for Cause
18.1 Upon termination of this Agreement for cause (under Clause 17):
(a) The Tenant shall vacate the Premises and remove all personal belongings within the time specified by the Owner (not exceeding 48 hours for immediate-termination grounds, or within the notice period for other grounds);
(b) All outstanding Rent, Package charges, and other dues for the remaining period of the Academic Session shall become immediately due and payable;
(c) The Security Deposit and Booking Amount shall stand fully forfeited;
(d) The Owner may deactivate the Tenant's App access and biometric/key access credentials;""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 18: Section 18 (cont), Section 19 & Section 20 (20.1 to 20.4)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """18.2 If the amount due under Clause 18.1(b), together with the cost of repair of any damage, exceeds the Security Deposit and Booking Amount, the Tenant (and their parent/guardian) shall be jointly and severally liable to pay the deficiency within seven (7) days of demand.
18.3 Leftover Belongings: If the Tenant fails to remove their personal belongings from the Premises upon expiry of the handover period, the Owner may, after giving forty-eight (48) hours' notice through the App, pack and store the items at the Tenant's risk and cost (storage charge: ₹200 per day). If unclaimed beyond thirty (30) days from notice, the Owner may dispose of or auction the items to recover accrued storage and dues, without further liability to the Tenant.
18.4 Eviction: The Tenant acknowledges that the permission to occupy granted under this leave and licence stands revoked upon termination. If the Tenant refuses to vacate, the Owner shall be entitled to re-enter, take peaceful possession of the Premises, change locks/access credentials, and seek assistance from local law enforcement and civil courts to effect eviction, at the Tenant's cost.
18.5 The Tenant shall be liable for holding-over compensation at twice the daily rent rate for each day of unauthorised occupation following the date on which the Tenant was required to vacate.

19. Indemnity and Limitation of Liability
19.1 The Tenant shall indemnify, defend, and hold harmless the Owner, its agents, employees, and representatives from and against all claims, liabilities, losses, damages, penalties, fines, costs, and expenses (including reasonable legal fees) arising from:
(a) Any breach of this Agreement or violation of applicable law by the Tenant or any guest/visitor/occupant permitted by the Tenant;
(b) Any loss, damage, or injury caused to person or property by any intentional act, negligence, or omission of the Tenant;
(c) Any proceedings initiated by a third party, educational institution, local authority, or law-enforcement agency in connection with activities carried out by the Tenant on or from the Premises.
19.2 Limitation of Owner's Liability: To the maximum extent permitted by applicable law:
(a) The Owner shall not be liable for any indirect, incidental, special, consequential, or punitive damages;
(b) The Owner's total cumulative liability arising out of or in connection with this Agreement shall not exceed the total amount of Rent actually paid by the Tenant to the Owner during the three (3) months preceding the event giving rise to liability;
(c) The Owner shall not be liable for the loss, theft, or damage of personal belongings, cash, jewellery, laptops, mobile phones, or other valuables kept in the Premises or Common Areas, except where caused by the Owner's proven gross negligence;
19.3 The Tenant is strongly advised to obtain independent personal insurance for their belongings and medical coverage.

20. Health, Safety, Emergency and Personal Well-Being
20.1 The Tenant shall keep the Premises in a hygienic condition, free from biohazards, accumulated waste, and pests, and shall dispose of rubbish daily in designated bins.
20.2 The Tenant shall promptly report any communicable disease, medical condition requiring emergency support, or epidemic symptoms to the warden, and shall comply with any health directives in force at the Residency from time to time. In the event of a government-mandated evacuation arising from a pandemic or public-health emergency, Rent/Fees for the ongoing Academic Session shall remain payable notwithstanding early vacation, unless the Owner decides otherwise.
20.3 In case of a genuine medical or safety emergency involving the Tenant, the Owner/Residency staff may take reasonable steps (including contacting emergency services or the Tenant's emergency contact/guardian) without such action being construed as a breach of privacy or of this Agreement.
20.4 Self-Harm and Personal Safety: While the Owner shall take the reasonable and bona fide safety precautions expected of a residential facility operator, the Owner shall not be held liable for any act of self-harm, attempted suicide, or suicide committed by a Tenant/resident on or off the Premises, except to the extent such incident arises directly from the Owner's own proven gross negligence or wilful default in maintaining basic safety standards at the Premises. The Tenant and their parent/guardian acknowledge that the Owner is not a medical or mental-health care provider and undertakes no duty of clinical care towards residents.""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 19: Section 20.5, 21, 22, 23, 24 (24.1 to 24.3)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """20.5 The Residency encourages any Tenant experiencing emotional distress or a mental-health concern to reach out to their family, the Residency's designated warden/contact person, their institution's counselling service, or a national mental-health helpline, details of which shall be displayed at the Residency and on the App.

21. Force Majeure
21.1 Neither Party shall be held liable for any failure or delay in performing its obligations under this Agreement (excluding payment obligations) where such failure or delay results from circumstances beyond its reasonable control, including natural disaster, fire, pandemic, government order, strike, or civil unrest.

22. Confidentiality, Data Privacy and Promotional Use
22.1 Personal data collected from the Tenant via the App (including identity proof, contact details, payment information, and complaint history) shall be used by the Owner solely for purposes connected with this Agreement, tenancy administration, safety, and legal compliance, and shall not be sold to unrelated third parties.
22.2 Promotional Use: The Owner may, for promotional purposes, use testimonials, photographs, or videos of the Tenant taken during events or activities organised at the Residency, on its website, social media, or marketing material, provided the same is not used in a manner prejudicial to the Tenant.
22.3 Non-Disclosure of Agreement Terms: The Tenant shall keep the commercial terms of this Agreement (Rent, Package charges, Security Deposit, Booking Amount, etc.) confidential and shall not disclose the same to third parties, other than parents/guardians or as required by law.

23. Dispute Resolution and Governing Law
23.1 The Parties shall in the first instance attempt to amicably resolve any dispute arising out of or in connection with this Agreement through good-faith discussion.
23.2 This Agreement shall be governed by and construed in accordance with the laws of India.
23.3 Nothing in this Clause 23 shall restrict the Owner's right to approach the police or any competent criminal court directly, without recourse to arbitration, in respect of any act constituting a criminal offence under Clause 10 of this Agreement.

24. General / Miscellaneous Provisions
24.1 Notices: Any notice required under this Agreement shall be deemed validly served if sent via the App, registered post, e-mail, or hand delivery to the addresses/contact details recorded herein.
24.2 Amendment: No amendment or waiver of any provision of this Agreement shall be effective unless made in writing and signed/digitally accepted by both Parties.
24.3 Severability: If any provision of this Agreement is held invalid or unenforceable, the remaining provisions shall continue in full force and effect.""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 650));
    }

    // ==========================================
    // PAGE 20: Section 24 (24.4 to 24.7)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String pText = """24.4 Entire Agreement: This Agreement, along with its Schedules and Annexure, constitutes the entire agreement between the Parties and supersedes all prior discussions, representations, or agreements, whether oral or written, relating to its subject matter.
24.5 Assignment by Tenant: The Tenant shall not assign or transfer any rights or obligations under this Agreement without the Owner's prior written consent.
24.6 Assignment by Owner: The Owner may sell, transfer, mortgage, or assign its rights and obligations under this Agreement, in whole or in part, without requiring the Tenant's consent. Upon such transfer, the Owner shall stand released from obligations arising thereafter, and the Tenant shall, upon written notice, recognise the transferee as the Owner for the residual Term.
24.7 Counterparts and Digital Execution: This Agreement may be executed in counterparts, including digitally through the App, each of which shall be deemed an original.""";

      _drawParagraph(page, pText, regular8, Rect.fromLTWH(0, y, 523, 300));
    }

    // ==========================================
    // PAGE 21: SCHEDULE A & SCHEDULE D
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

      final String sub = "The fields below are populated automatically from the Tenant's onboarding profile on the App at the time this Agreement is generated. Any change to these details after execution must be updated on the App and, where materially relevant (e.g., room/bed/building), confirmed with the Owner.";
      _drawParagraph(page, sub, regular8, Rect.fromLTWH(0, y, 523, 30));
      y += 34;

      final PdfGrid gridA = PdfGrid();
      gridA.columns.add(count: 2);
      gridA.columns[0].width = 190;
      gridA.columns[1].width = 333;

      _addGridRow(gridA, "Full Name", data.studentFullName, isBoldVal: true);
      _addGridRow(gridA, "Mobile Number", data.mobileNumber);
      _addGridRow(gridA, "Email ID", data.email);
      _addGridRow(gridA, "College Registration Number", data.regNumber.isNotEmpty ? data.regNumber : "N/A");
      _addGridRow(gridA, "Course", data.course.isNotEmpty ? data.course : "N/A");
      _addGridRow(gridA, "Branch / Specialisation / Honours", data.branch.isNotEmpty ? data.branch : "N/A");
      _addGridRow(gridA, "Building", data.building, isBoldVal: true);
      _addGridRow(gridA, "Room / Flat Number", data.roomNumber, isBoldVal: true);
      _addGridRow(gridA, "Bed Number", data.bedNumber.isNotEmpty ? data.bedNumber : "N/A");
      _addGridRow(gridA, "Guardian's Name", data.guardianName.isNotEmpty ? data.guardianName : "N/A");
      _addGridRow(gridA, "Guardian's Relationship to Tenant", data.guardianRelationship.isNotEmpty ? data.guardianRelationship : "Guardian");
      _addGridRow(gridA, "Guardian's Phone Number", data.guardianPhone.isNotEmpty ? data.guardianPhone : "N/A");
      _addGridRow(gridA, "Vegetarian / Non-Vegetarian Preference", data.dietaryPreference);
      _addGridRow(gridA, "Home Town Address", data.hometownAddress.isNotEmpty ? data.hometownAddress : "On file in App Profile");

      _styleCompactGrid(gridA);
      gridA.draw(page: page, bounds: Rect.fromLTWH(0, y, 523, 310));
      y += 320;

      page.graphics.drawString(
        "SCHEDULE D — Furniture, Inventory and House Rules Acknowledgement",
        bold10,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 15),
      );
      y += 18;

      final String itemsJoined = data.inventoryItems.isNotEmpty
          ? data.inventoryItems.map((e) => "• $e").join("    |    ")
          : "Standard room inventory verified at check-in (bed, mattress, study table, chair, wardrobe, fan, light, geyser)";
      final String dText = "The furniture, fixtures, and appliances provided in the Premises at the time of onboarding/move-in are as listed in the Tenant's onboarding record on the App (e.g., bed, mattress, study table, chair, wardrobe, fan, light, curtains, geyser, and other applicable items with quantity). Both Parties confirm this inventory and its condition through the App at check-in, and any discrepancy must be flagged within 48 hours of move-in.\n"
          "Allotted Inventory Checklist: $itemsJoined\n\n"
          "The Tenant confirms having read and understood the Residency's house rules (displayed on the notice board and/or the App), including visiting hours, quiet hours, gate-closing time, and the guest-registration procedure at Clause 11, and agrees to be bound by the same as part of this Agreement.";

      _drawParagraph(page, dText, regular8, Rect.fromLTWH(0, y, 523, 140));
    }

    // ==========================================
    // PAGE 22: ANNEXURE I & TENANT'S DECLARATION (D.1)
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      page.graphics.drawString(
        "ANNEXURE I — CO-HABITATION / LIVE-IN CONSENT FORM",
        bold10,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 15),
      );
      y += 18;

      final String annIntro = "(To be submitted physically or through the App by both residents, where applicable, in accordance with Clause 12 of this Agreement)\n\n"
          "We, the undersigned, both being adult residents of Lakshya Residency, voluntarily confirm our mutual consent to reside together at the Premises described below. We acknowledge and accept the terms of Clause 12 (Co-Habitation / Live-in Arrangements) of this Agreement, including that Lakshya Residency and its Owner shall not be liable for any personal, relationship, financial, or legal issue arising between us during or after this arrangement, save for matters arising from the Owner's own proven negligence or wilful misconduct.";

      _drawParagraph(page, annIntro, regular8, Rect.fromLTWH(0, y, 523, 85));
      y += 90;

      final PdfGrid annGrid = PdfGrid();
      annGrid.columns.add(count: 2);
      annGrid.columns[0].width = 200;
      annGrid.columns[1].width = 323;

      _addGridRow(annGrid, "Building / Room / Flat No.", "Building ${data.building}, Room ${data.roomNumber}");
      _addGridRow(annGrid, "Date of this Form", data.agreementDate);
      _addGridRow(annGrid, "Resident 1 (Tenant)", "${data.studentFullName}  (Signature on App)");
      _addGridRow(annGrid, "Resident 2 (Co-Habitant)", "Name: ____________________  Sign: _________");
      _addGridRow(annGrid, "Acknowledged by Owner / Warden", "Mr. Ajay Singh (Founder / Licensor)");

      _styleCompactGrid(annGrid);
      annGrid.draw(page: page, bounds: Rect.fromLTWH(0, y, 523, 140));
      y += 150;

      page.graphics.drawString(
        "TENANT'S DECLARATION",
        bold11,
        brush: PdfSolidBrush(textDark),
        bounds: Rect.fromLTWH(0, y, 523, 16),
      );
      y += 18;

      final String d1Text = "D.1 I confirm that I am legally permitted and eligible to execute this Agreement, either personally or through my parent/legal guardian, and that the particulars fetched from my onboarding profile on the App are true and accurate to the best of my knowledge; I have not wilfully suppressed any material fact, and I understand that any misrepresentation may render me ineligible for accommodation.";
      _drawParagraph(page, d1Text, regular8, Rect.fromLTWH(0, y, 523, 100));
    }

    // ==========================================
    // PAGE 23: TENANT'S DECLARATION (D.2 to D.6), NOTICE & SIGNATURES
    // ==========================================
    {
      final PdfPage page = document.pages.add();
      double y = 80;

      final String dText = """D.2 I undertake to submit valid KYC documents (Government ID and College ID, as recorded in the app) to the Owner through the App on or before moving into the Premises, and to provide full cooperation and documentation for any police verification, tenant registration, or similar process required by the Owner or applicable law.
D.3 I undertake not to disclose the commercial terms of this Agreement, including the information at Schedule A, D, to any third party other than my parent/guardian or as required by law, in accordance with Clause 22.5.
D.4 I have read and understood this Agreement in full, including Clause 10 (Prohibited Activities and Strict Conduct Rules) and Clause 13 (Owner's Rights and Remedies). I understand and agree that engaging in property damage, drug/narcotic-related activity, any activity endangering a Minor, unauthorised commercial/business use of the Premises, housing any unauthorised person for a prolonged period without prior disclosure and consent, exceeding the occupancy limits at Clause 8.4, or misuse of the App, shall constitute a serious breach of this Agreement.
D.5 I understand that the Owner has the full right, without limitation, to terminate this Agreement, forfeit the Security Deposit and Booking Amount to the extent described in Clauses 5.8, 16.3 and 18, evict me in accordance with law, lodge a police complaint, and/or escalate the matter to any higher civil, criminal, or regulatory authority, and I accept full legal responsibility for any consequence arising from such breach.
D.6 I confirm that I have read and understood Clause 20.4 (Self-Harm and Personal Safety) and Clause 19.2 (Limitation of Liability) of this Agreement.""";

      _drawParagraph(page, dText, regular8, Rect.fromLTWH(0, y, 523, 190));
      y += 195;

      // Notice Box
      page.graphics.drawRectangle(
        pen: PdfPen(alertBorder, width: 1.2),
        brush: PdfSolidBrush(alertBg),
        bounds: Rect.fromLTWH(0, y, 523, 75),
      );

      page.graphics.drawString(
        "IMPORTANT NOTICE",
        bold9,
        brush: PdfSolidBrush(alertBorder),
        bounds: Rect.fromLTWH(10, y + 6, 503, 12),
      );

      final String noticeBody = "This Agreement is a legal contract. Violation of the prohibitions in Clause 10 may expose the Tenant to civil liability, forfeiture of the Security Deposit and Booking Amount, immediate eviction, and criminal prosecution under applicable Indian law. Leaving before completing the Lock-in Period (${data.lockInPeriod.isNotEmpty ? data.lockInPeriod : data.rentalTerm}) results in full forfeiture of the Security Deposit and Booking Amount as described in Clauses 5.8 and 16.3. By signing below (or accepting digitally on the App), the Tenant acknowledges full understanding and acceptance of these consequences.";
      _drawParagraph(page, noticeBody, regular8, Rect.fromLTWH(10, y + 20, 503, 50));
      y += 85;

      page.graphics.drawString("SIGNATURES", bold11, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y, 523, 15));
      y += 18;

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
          "Witnesses: Witness 1 — Digital System Audit Verification (Lakshya Residency App Platform Engine)  |  Witness 2 — Resident Warden Desk, Jaipur";
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
      const Offset(200, 66),
      const Offset(487.4, 66),
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

  static void _drawTocRow(PdfPage page, String title, String pageNum, PdfFont font, double y, double width) {
    final double textW = font.measureString(title).width;
    final double pageW = font.measureString(pageNum).width;
    page.graphics.drawString(title, font, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(0, y, textW + 4, 14));

    final double dotStart = textW + 8;
    final double dotEnd = width - pageW - 8;
    if (dotEnd > dotStart) {
      final double dotsWidth = dotEnd - dotStart;
      final int dotCount = (dotsWidth / 4.0).floor();
      final String dots = '.' * dotCount;
      final PdfFont dotFont = PdfStandardFont(PdfFontFamily.helvetica, 7.5);
      page.graphics.drawString(dots, dotFont, brush: PdfSolidBrush(textMuted), bounds: Rect.fromLTWH(dotStart, y, dotsWidth, 14));
    }

    page.graphics.drawString(pageNum, font, brush: PdfSolidBrush(textDark), bounds: Rect.fromLTWH(width - pageW, y, pageW + 4, 14), format: PdfStringFormat(alignment: PdfTextAlignment.right));
  }

  static double _drawParagraph(PdfPage page, String text, PdfFont font, Rect bounds) {
    final cleanText = text.replaceAll('₹', 'Rs. ');
    final PdfTextElement element = PdfTextElement(
      text: cleanText,
      font: font,
      brush: PdfSolidBrush(textDark),
      format: PdfStringFormat(
        lineSpacing: 1.5,
        alignment: PdfTextAlignment.justify,
      ),
    );
    final PdfLayoutResult? res = element.draw(page: page, bounds: bounds);
    return res != null ? res.bounds.bottom : bounds.bottom;
  }

  static void _addGridRow(PdfGrid grid, String label, String value, {bool isBoldVal = false}) {
    final PdfGridRow row = grid.rows.add();
    row.cells[0].value = label;
    row.cells[1].value = value;
  }

  static void _styleCompactGrid(PdfGrid grid) {
    grid.style.cellPadding = PdfPaddings(left: 6, right: 6, top: 2.5, bottom: 2.5);
    for (int i = 0; i < grid.rows.count; i++) {
      grid.rows[i].cells[0].style.backgroundBrush = PdfSolidBrush(tableHeaderBg);
      grid.rows[i].cells[0].style.font = PdfStandardFont(PdfFontFamily.helvetica, 7.5, style: PdfFontStyle.bold);
      grid.rows[i].cells[1].style.font = PdfStandardFont(PdfFontFamily.helvetica, 7.5);
    }
  }

  static void _styleGrid(PdfGrid grid) {
    grid.style.cellPadding = PdfPaddings(left: 8, right: 8, top: 4, bottom: 4);
    if (grid.headers.count > 0) {
      grid.headers[0].style.backgroundBrush = PdfSolidBrush(tableHeaderBg);
      grid.headers[0].style.font = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);
    }
    for (int i = 0; i < grid.rows.count; i++) {
      grid.rows[i].cells[0].style.backgroundBrush = PdfSolidBrush(tableHeaderBg);
      grid.rows[i].cells[0].style.font = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold);
      grid.rows[i].cells[1].style.font = PdfStandardFont(PdfFontFamily.helvetica, 8);
    }
  }
}
