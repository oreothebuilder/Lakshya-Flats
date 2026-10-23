import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agreement_pdf_service.dart';
import '../widgets/document_viewer_modal.dart';
import 'digital_signature_pad.dart';
import 'app_toast.dart';

/// Modal dialog for reviewing and digitally signing the Lakshya Residency
/// Rent & License Agreement matching the exact PDF header, footer,
/// clauses, schedules, pre-signed owner signature, and student signature pad.
class RentalAgreementDialog extends StatefulWidget {
  final RentalAgreementData agreementData;

  const RentalAgreementDialog({
    super.key,
    required this.agreementData,
  });

  /// Presents the agreement in a full-screen or wide dialog
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required RentalAgreementData agreementData,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 0 : 20,
          vertical: isMobile ? 0 : 12,
        ),
        backgroundColor: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 0 : 14),
        ),
        child: RentalAgreementDialog(agreementData: agreementData),
      ),
    );
  }

  @override
  State<RentalAgreementDialog> createState() => _RentalAgreementDialogState();
}

class _RentalAgreementDialogState extends State<RentalAgreementDialog> {
  final GlobalKey<DigitalSignaturePadState> _sigPadKey = GlobalKey<DigitalSignaturePadState>();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  Uint8List? _studentSignatureBytes;
  bool _hasAgreedToTerms = false;
  bool _isGeneratingPdf = false;

  GlobalKey _getKey(String keyId) {
    return _sectionKeys.putIfAbsent(keyId, () => GlobalKey());
  }

  void _scrollToKey(String keyId) {
    final key = _sectionKeys[keyId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleAcceptButtonTap() async {
    if (_isGeneratingPdf) return;

    if (_studentSignatureBytes == null) {
      final bytes = await _sigPadKey.currentState?.captureSignatureBytes();
      if (bytes != null) {
        setState(() => _studentSignatureBytes = bytes);
      }
    }

    if (_studentSignatureBytes == null) {
      _scrollToKey("signatures");
      if (!mounted) return;
      AppToast.showError(
        context,
        "Please scroll down and draw your signature under 'Signature of Tenant'.",
      );
      return;
    }

    if (!_hasAgreedToTerms) {
      _scrollToKey("confirmation_checkbox");
      if (!mounted) return;
      AppToast.showError(
        context,
        "Please tick the confirmation box agreeing to the agreement terms to proceed.",
      );
      return;
    }

    await _handleConfirmSigning();
  }

  Future<void> _previewDraftPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await AgreementPdfService.generateAgreementPdf(widget.agreementData);
      if (!mounted) return;
      DocumentViewerModal.show(
        context,
        url: "",
        title: "Lakshya Residency Agreement (PDF Preview)",
        memoryBytes: pdfBytes,
        fileName: "Lakshya_Residency_Agreement_Draft.pdf",
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, "Error generating preview: $e");
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _handleConfirmSigning() async {
    if (_studentSignatureBytes == null) {
      final bytes = await _sigPadKey.currentState?.captureSignatureBytes();
      if (bytes != null) {
        _studentSignatureBytes = bytes;
      }
    }

    if (_studentSignatureBytes == null) {
      if (!mounted) return;
      AppToast.showError(context, "Please draw your signature under 'Signature of Tenant' before proceeding.");
      return;
    }

    if (!_hasAgreedToTerms) {
      if (!mounted) return;
      AppToast.showError(context, "Please check the confirmation box agreeing to all terms.");
      return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      final signedData = RentalAgreementData(
        agreementDate: widget.agreementData.agreementDate,
        commencementDate: widget.agreementData.commencementDate,
        endingDate: widget.agreementData.endingDate,
        studentFullName: widget.agreementData.studentFullName,
        mobileNumber: widget.agreementData.mobileNumber,
        email: widget.agreementData.email,
        regNumber: widget.agreementData.regNumber,
        dob: widget.agreementData.dob,
        course: widget.agreementData.course,
        branch: widget.agreementData.branch,
        hometownAddress: widget.agreementData.hometownAddress,
        building: widget.agreementData.building,
        roomNumber: widget.agreementData.roomNumber,
        bedNumber: widget.agreementData.bedNumber,
        flatConfig: widget.agreementData.flatConfig,
        guardianName: widget.agreementData.guardianName,
        guardianRelationship: widget.agreementData.guardianRelationship,
        guardianPhone: widget.agreementData.guardianPhone,
        dietaryPreference: widget.agreementData.dietaryPreference,
        plan: widget.agreementData.plan,
        monthlyRent: widget.agreementData.monthlyRent,
        securityDeposit: widget.agreementData.securityDeposit,
        paymentFrequency: widget.agreementData.paymentFrequency,
        installmentsCount: widget.agreementData.installmentsCount,
        installments: widget.agreementData.installments,
        inventoryItems: widget.agreementData.inventoryItems,
        notes: widget.agreementData.notes,
        studentSignatureBytes: _studentSignatureBytes,
        ownerSignatureBytes: widget.agreementData.ownerSignatureBytes,
        studentPhotoBytes: widget.agreementData.studentPhotoBytes,
        rentalTerm: widget.agreementData.rentalTerm,
        lockInPeriod: widget.agreementData.lockInPeriod,
        termMonths: widget.agreementData.termMonths,
        collegeIdUploaded: widget.agreementData.collegeIdUploaded,
        govtIdUploaded: widget.agreementData.govtIdUploaded,
      );

      final signedPdfBytes = await AgreementPdfService.generateAgreementPdf(signedData);

      if (!mounted) return;
      Navigator.pop(context, {
        'pdfBytes': signedPdfBytes,
        'signatureBytes': _studentSignatureBytes,
      });
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, "Error finalizing agreement: $e");
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.agreementData;
    final isMobile = MediaQuery.of(context).size.width < 700;

    final guardianStr = d.guardianName.isNotEmpty ? d.guardianName : "Guardian on file";
    final addressStr = d.hometownAddress.isNotEmpty ? d.hometownAddress : "On file in App Profile";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 44,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF0F172A)),
          tooltip: "Close",
          onPressed: _isGeneratingPdf ? null : () => Navigator.pop(context),
        ),
        title: Text(
          "Rental & License Agreement (23 Pages)",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isGeneratingPdf ? null : _previewDraftPdf,
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F3864)),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, size: 15, color: Color(0xFF1F3864)),
            label: Text(
              _isGeneratingPdf ? "Generating..." : "Draft PDF",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F3864),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Agreement Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // EXACT HEADER UI FROM PDF
                        _buildExactPdfHeader(d.agreementDate),
                        const SizedBox(height: 20),

                        // Document Body
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title matching Page 1 of PDF
                              Center(
                                child: Text(
                                  "LAKSHYA RESIDENCY",
                                  style: GoogleFonts.merriweather(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                    color: const Color(0xFF1F3864),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Text(
                                  "Rent and License AGREEMENT",
                                  style: GoogleFonts.merriweather(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Cover Table matching Page 1 of PDF (Exact 4 fields from template)
                              _buildCoverTable(d),
                              const SizedBox(height: 14),

                              Center(
                                child: Text(
                                  "This is a legally binding document. Please read carefully before signing / accepting digitally on the App.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.roboto(
                                    fontSize: 10.5,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                                                            // Table of Contents matching Pages 2 & 3 of PDF
                              _buildTableOfContents(),
                              const SizedBox(height: 32),

                              // Section 1: Parties and Recitals
                              _buildClauseTitle("1. Parties and Recitals", keyId: "section_1"),
                              _buildParagraph(
                                "This Rent/License Agreement (\"Agreement\") is made and entered into on this date ${d.agreementDate} by and between:\n\n"
                                "OWNER / LICENSOR: Mr. Ajay Singh , hereinafter referred to as the \"Owner\" representing Lakshya Residency, located at Lakshay Residency and Flats, Tejasvi Greens, L2 L3, behind barcode cafe, near Manipal University Jaipur, Dahmi Kalan, Dahmi Khurd, Rajasthan 303007, of the ONE PART;\n\n"
                                "AND\n\n"
                                "TENANT / LICENSEE: ${d.studentFullName} who’s guardian is $guardianStr, and their hometown is located at $addressStr, of the OTHER PART.\n\n"
                                "Where the context so requires, the Owner and the Tenant are hereinafter individually referred to as a \"Party\" and collectively as the \"Parties\".",
                              ),
                              const SizedBox(height: 12),
                              _buildSubClauseTitle("Recitals", keyId: "section_1_recitals"),
                              _buildParagraph(
                                "1.1 The Owner is the lawful owner and/or authorised managing operator of the residential unit(s) known as Lakshya Residency, and is competent to let out/license the said premises for residential and allied purposes.\n\n"
                                "1.2 The Tenant has approached the Owner seeking accommodation on a rental / leave-and-license basis at the Residency, either on a standalone rent basis or coupled with certain optional package-based facilities (meals, transport, laundry, cleaning, Wi-Fi, etc.), and the Owner has agreed to provide the same on the terms and conditions recorded in this Agreement.\n\n"
                                "1.3 This Agreement, together with its Schedules (A,D and Annexure I, and any further Annexures executed in writing by both Parties, constitutes the entire understanding between the Parties in relation to the subject matter herein.\n\n"
                                "1.4 This Agreement, along with any rent receipts, notices, and renewal confirmations, will also be maintained on the Lakshya Residency mobile application (\"the App\") for administrative and compliance purposes.\n\n"
                                "1.5 This Agreement, including Schedule A, is auto-generated using the information the Tenant submits at the time of onboarding on the App — including personal, academic, identity, room-allocation, guardian, and payment-plan details — and such App records shall be read together with, and form an integral part of, this Agreement. Upon completion of onboarding, the Tenant shall review and digitally sign this auto-generated Agreement on the App, which shall also bear the Owner's digital countersignature.",
                              ),
                              const SizedBox(height: 24),

                              // Section 2: Nature of Agreement
                              _buildClauseTitle("2. Nature of Agreement", keyId: "section_2"),
                              _buildParagraph(
                                "2.1 This Agreement is intended to constitute a leave and licence arrangement under applicable Indian law, whereby the Licensor grants the Licensee a limited, personal and non-transferable permission to use and occupy the specified Premises within Lakshya Residency solely for the residential purpose and for the Term expressly stated herein, subject to the terms and conditions of this Agreement and payment of the applicable Licence Fee and opted Package Charges.\n\n"
                                "2.2 The Owner retains overall control, management, and right of entry over the Premises and Common Areas at all times, subject to Clause 14 (Inspection, Entry and Room Reallocation).",
                              ),
                              const SizedBox(height: 24),

                              // Section 3: Definitions and Interpretation
                              _buildClauseTitle("3. Definitions and Interpretation", keyId: "section_3"),
                              _buildParagraph(
                                "3.1 \"Premises\" means the specific flat/room (Building ${d.building}, Room/Flat ${d.roomNumber}${d.bedNumber.isNotEmpty ? ', Bed ${d.bedNumber}' : ''}), along with fittings, fixtures, furniture and appliances provided therein, allotted to the Tenant at Lakshya Residency, as recorded in the app.\n\n"
                                "3.2 \"Common Areas\" means all shared spaces within the Residency including but not limited to corridors, staircases, terrace, dining hall, common kitchen, lounge, and parking area, which are not for the exclusive use of any single Tenant.\n\n"
                                "3.3 \"Package Facilities\" means the optional services which the Tenant may avail in addition to the base rent, including meals, pick-up and drop transport, laundry, cleaning, and Wi-Fi/internet access.\n\n"
                                "3.4 \"App\" means the official Lakshya Residency mobile application through which onboarding, rent/fee payments, service requests, complaints, digital copies of this Agreement, notices, and communication between Owner and Tenant are facilitated.\n\n"
                                "3.5 \"Booking Amount\" means the amount paid by the Tenant to reserve a room/bed prior to move-in, as recorded in Schedule B, which is non-refundable in the manner described in Clause 5.\n\n"
                                "3.6 \"Security Deposit\" means the interest-free amount collected by the Owner from the Tenant as security against damage, unpaid dues, or breach of this Agreement, refundable subject to Clause 16.\n\n"
                                "3.7 \"Academic Session\" or \"Lock-in Period\" means the period for which the Tenant has subscribed, as determined by the Plan (${d.plan}) and the Rental Term selected by the Tenant at onboarding on the App (${d.lockInPeriod}), which is the minimum period for which the Tenant commits to reside at the Premises.\n\n"
                                "3.8 \"Minor\" means any individual who has not completed eighteen (18) years of age as on the date of the relevant event.\n\n"
                                "3.9 \"Authorised Occupant\" means only the Tenant named who is onboarded on the Lakshya Residency app and any additional occupant(s) whose details have been disclosed to and expressly approved in writing (including via the App) by the Owner prior to occupation.\n\n"
                                "3.10 Words importing the singular include the plural and vice versa; words importing any gender include all genders; references to \"writing\" include communication through the App unless stated otherwise.",
                              ),
                              const SizedBox(height: 24),

                              // Section 4: Term, Lock-In Period and Renewal
                              _buildClauseTitle("4. Term, Lock-In Period and Renewal", keyId: "section_4"),
                              _buildParagraph(
                                "4.1 The Academic Session / Term of this Agreement shall be the Rental Term / Lock-in Period corresponding to the Plan and the duration selected by the Tenant at onboarding on the App OR/AND period for which the tenant is extending their stay at Lakshya residency, unless terminated earlier under Clause 17.\n\n"
                                "4.2 The Tenant undertakes to remain in occupation of the Premises for the full Lock-in Period coinciding with the Academic Session. The Lock-in Period applies uniformly to Tenants on a rental-only basis and to Tenants who have opted for the Package Facilities.\n\n"
                                "4.3 If the Tenant does not take possession of the Premises within 30 days of the agreed move-in date thereafter, the Owner may treat this as a showup breach and terminate this Agreement forthwith, with the consequences set out in Clause 16.4 and Clause 18.\n\n"
                                "4.4 Renewal: This Agreement may be renewed for a further Academic Session on mutually agreed terms. If failed to inform the person in charge, the Tenant shall vacate the Premises on or before the last day of the Term.\n\n"
                                "4.5 Continued occupation beyond the Term without a signed renewal/ upfront confrontation shall not be construed as an automatic extension, and the Owner may charge holding-over compensation above the last applicable rent for each day of unauthorised continued occupation, in addition to other remedies available in law.\n\n"
                                "4.6 Automatic Termination by Efflux of Time: Unless renewed under Clause 4.4, this Agreement shall stand automatically terminated upon expiry of the Academic Session/Term. All outstanding dues as on such date shall become immediately payable and shall be adjusted against the Security Deposit in accordance with Clause 16.",
                              ),
                              const SizedBox(height: 24),

                              // Section 5: Booking, Rent, Deposits and Payment Terms
                              _buildClauseTitle("5. Booking, Rent, Deposits and Payment Terms", keyId: "section_5"),
                              _buildParagraph(
                                "5.1 Booking Amount: To reserve a room/bed, the Tenant shall pay the Booking Amount. The Booking Amount is strictly non-refundable once paid, including where the Tenant subsequently withdraws or cancels the booking prior to move-in, save where the Owner is unable to provide the booked accommodation at all.\n\n"
                                "5.2 Advance Payment Before Move-In: A prospective Tenant wishing to move in must inform the person incharge well in advance and shall pay the full quoted joining amount — comprising the Booking Amount(that may be compensated to the actual fees), Security Deposit, and/or the first applicable installment, as the case may be — upfront and in advance of being granted possession or occupation of the Premises.\n\n"
                                "5.3 Payment Plan — Rental-Only Tenants: A Tenant availing accommodation on a purely rental basis shall be billed for the entire Academic Session. At onboarding, the Tenant shall elect, on the App, either to (a) pay Rent on a monthly basis, or (b) pay the full session's Rent upfront in installments of 3 (three), 4 (four), or such other number of installments as the Tenant chooses. The exact installment amounts and due dates shall be fixed on the App at the time this election is made.\n\n"
                                "5.4 Payment Plan — Package Tenants: A Tenant who opts for the complete package (Rent plus Package Facilities) shall also pay in installments. The number of installments and the corresponding due dates shall likewise be decided at onboarding, on the App.\n\n"
                                "5.5 Default: If any installment or monthly Rent is not paid by its due date, the Tenant shall be treated as being \"in default\" and the late payment charge shall apply for each day of delay. Persistent default is additionally governed by Clause 17.3 (termination for non-payment).\n\n"
                                "5.6 Security Deposit: A refundable, interest-free Security Deposit shall be paid by the Tenant prior to handover of possession. The Security Deposit shall not be adjusted against Rent during the subsistence of this Agreement, and is subject to forfeiture under Clause 5.8 and Clause 16.4.\n\n"
                                "5.7 Non-Refundability on Early Exit: If the Tenant leaves, discontinues occupation, or withdraws from this Agreement before completing the full specified Period / Academic Session referred to in Clause 4, both the Security Deposit and the Booking Amount shall stand fully and absolutely forfeited and shall not be refunded under any circumstance, and outstanding Rent/Package charges for the remainder of the Academic Session shall remain payable. This applies equally whether the early departure is on account of the Tenant's personal choice, academic withdrawal, disciplinary action, or any other reason not attributable to the Owner's default.\n\n"
                                "5.10 Late Payment Charge: Beyond a grace period of 3 (three) days from the due date, a late payment charge shall accrue for every day of delay, without prejudice to the Owner's right to treat persistent default as a material breach under Clause 17.\n\n"
                                "5.11 Payments declaration Only Through the App — No Other Channel Accepted: ALL payments to the Owner (Booking Amount, Security Deposit, Rent, installments, Package charges, fines, or any other dues) shall be made ONLY through the payment details listed on the App — namely the bank account number and UPI ID displayed within the App. The Owner does NOT accept, authorise, or acknowledge any payment made through any other bank account, UPI ID, cash collection, or any individual or agent, however described. The Tenant and their parent/guardian must never trust or make payment to any person claiming to represent Lakshya Residency outside the App, and the Owner shall bear no responsibility whatsoever for payments made to any unauthorised or fraudulent party.\n\n"
                                "5.12 KYC and Verification: The Tenant shall submit, through the App at onboarding, valid identity documents (a Government-issued photo ID and College ID, as recorded in the app) and a recent photograph, and shall cooperate with any police verification, tenant registration, or similar process required by the Owner or local administration.\n\n"
                                "5.13 Mode of Payment: All payments under this Agreement shall be made through UPI, net banking, debit/credit card, or other digital payment methods configured on the App. Cash payments are discouraged and, if exceptionally accepted by the Owner, must be accompanied by an official receipt issued through the App.\n\n"
                                "5.14 Taxes: All amounts payable by the Tenant are exclusive of applicable Goods and Services Tax (GST) or other statutory levies, which shall be charged additionally if and when applicable by law.",
                              ),
                              const SizedBox(height: 14),

                              _buildPdfWarningBox(
                                title: "CRITICAL FRAUD ALERT — MANDATORY PAYMENT INSTRUCTION",
                                text: "ALL PAYMENTS MUST BE MADE SOLELY THROUGH THE OFFICIAL LAKSHYA RESIDENCY APP / PLATFORM.\n"
                                    "Do NOT pay cash, transfer funds to personal UPI IDs, or make bank transfers to any person claiming to be an agent, broker, manager, warden, or owner outside of the verified account details displayed inside the Lakshya Residency App.\n"
                                    "The Owner shall NOT be liable or responsible for any payment made outside the App.",
                              ),
                              const SizedBox(height: 24),

                              // Section 6: Package-Based Facilities
                              _buildClauseTitle("6. Package-Based Facilities (Optional Value-Added Services)", keyId: "section_6"),
                              _buildParagraph(
                                "The Tenant may choose to avail one or more optional facilities offered by the Owner as part of a consolidated Package, subject to additional payment of applicable Package Charges. The specific facilities opted for by the Tenant, the duration for which they are opted, and the corresponding charges are set out in Schedule C to this Agreement. The following terms govern each package facility:",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("6.A Meals", keyId: "section_6_a"),
                              _buildParagraph(
                                "6.1 Where opted, meals shall be provided in accordance with the meal plan and menu published by the Residency from time to time.\n\n"
                                "6.2 Meal timings shall be communicated via the App. A Tenant missing a meal during scheduled hours shall not be entitled to a replacement, takeaway, or refund.\n\n"
                                "6.3 The Owner shall take reasonable care in food preparation and hygiene. The Tenant shall inform the management of any severe food allergies at the time of admission; the Owner does not guarantee allergen-free preparation in a communal kitchen environment.\n\n"
                                "6.4 Taking Residency cutlery, utensils, or bulk food items out of the dining hall or into individual rooms without written permission from the warden is prohibited.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("6.B Pick-up and Drop to College/Institute", keyId: "section_6_b"),
                              _buildParagraph(
                                "6.5 Where opted, transport shall operate on schedules coinciding with standard college class hours, as notified on the App. The vehicle shall operate on fixed routes with designated stops.\n\n"
                                "6.6 The Tenant shall adhere strictly to pickup and departure times. The vehicle shall not wait for late passengers. The Owner shall not be liable for any Tenant missing a class or exam on account of unavoidable traffic delay, vehicle breakdown, or weather conditions.\n"
                                "The transportation facilities are outsourced, so the tenants are requested to contact the concerned cab person/driver for anything regarding the cab. Cab charges are non-refundable under any circumstances. In case the cab is not available on any day, the Tenant must arrange their own transport.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("6.C Laundry and Cleaning", keyId: "section_6_c"),
                              _buildParagraph(
                                "6.7 Where opted, laundry service will be provided. The Owner/service shall not be liable for ordinary wear, shrinkage, or colour-run inherent to fabric type, nor for items left unclaimed beyond thirty (30) days. The Tenant is advised to verify items at the time of delivery; complaints raised thereafter may not be entertained. The laundry services are outsourced so the tenants are requested to contact the concerned laundry person for anything regarding the laundry.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("6.D Wi-Fi / Internet Access", keyId: "section_6_d"),
                              _buildParagraph(
                                "6.9 Where opted, Wi-Fi/internet access shall be provided on a shared-bandwidth, best-effort basis, subject to a Fair Usage Policy. The Owner does not guarantee uninterrupted, error-free, or specific-speed connectivity, and shall not be liable for any inconvenience, loss, or damage arising from unavailability or malfunction of the network.\n\n"
                                "6.10 The Wi-Fi facility shall be used strictly for lawful purposes. The Tenant shall not use the network to download, host, stream, or transmit pirated content or malware; to access or distribute content depicting the exploitation or abuse of minors (which shall be reported to law enforcement immediately upon detection); or to carry out cyber-crime, hacking, or unauthorised access to third-party systems. Any such misuse shall entitle the Owner to immediately suspend access and pursue legal action, including reporting to the police and/or the cyber-crime authorities.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("6.E General Terms Applicable to All Package Facilities", keyId: "section_6_e"),
                              _buildParagraph(
                                "6.11 Third-Party Facilitation: For services rendered through third-party vendors (including laundry, the internet service provider), the Owner acts only as a facilitator/aggregator and is not itself the service provider. The Owner shall not be liable for deficiency, delay, damage, or loss caused by such a third-party vendor; the Tenant's remedy, if any, in such cases lies against the vendor directly.\n\n"
                                "6.12 Complaint Window: Any complaint regarding a Package Facility must be raised via the App/email. If a timely complaint is not resolved within 15 days, the Tenant shall escalate it to the Owner/warden in writing/in person.\n\n"
                                "6.13 Misuse, abuse, or fraudulent claims relating to any Package Facility (e.g., false damage claims, unauthorised sharing of the facility with non-residents, tampering with service logs on the App) shall be treated as a material breach of this Agreement under Clause 10 and Clause 17.\n\n"
                                "6.14 National Holidays, Summer Break and Winter Break: During national holidays and during the summer and winter breaks, there is no confirmation or assurance of meals or of any other services, including pick-up and drop (cab), cleaning, laundry and similar services. Availability of any such service during these periods shall be communicated through the App at the Owner’s discretion, and the Owner shall not be liable for its non-availability.",
                              ),
                              const SizedBox(height: 24),

                              // Section 7: Utilities and Common Area Charges
                              _buildClauseTitle("7. Utilities and Common Area Charges", keyId: "section_7"),
                              _buildParagraph(
                                "7.1 Electricity shall be charged at the rate of ₹12 (Rupees Twelve only) per unit consumed, as per meter/sub-meter reading, billed monthly through the App. In a shared-occupancy room, electricity charges shall be divided equally among all occupants of that room, unless otherwise agreed in writing.\n\n"
                                "7.2 Common maintenance charges can be charged separately as per actuals,\n\n"
                                "7.3 The Tenant shall use electrical appliances, water, and other utilities responsibly and shall not install high-load appliances (e.g., heaters, induction cooktops, air-conditioners) without the Owner's prior written consent, given the shared electrical load of the Residency.\n\n"
                                "7.4 Common Area maintenance charges, if applicable, shall be shared proportionately among all Tenants of the Residency and billed through the App.",
                              ),
                              const SizedBox(height: 24),

                              // Section 8: Permitted Use of Premises and Occupancy Limits
                              _buildClauseTitle("8. Permitted Use of Premises and Occupancy Limits", keyId: "section_8"),
                              _buildParagraph(
                                "8.1 The Premises shall be used solely for lawful residential purposes by the Tenant (and any Authorised Occupant) for the duration of their bona fide studies, and for no other purpose whatsoever.\n\n"
                                "8.2 The Tenant shall comply with all house rules of Lakshya Residency as displayed on the premises and/or communicated through the App, including the curfew, outing, and visitor policy at Clause 11, which shall be deemed part of this Agreement.\n\n"
                                "8.3 The Tenant shall not use the Premises in any manner that causes nuisance, annoyance, danger, or disturbance to the Owner, other tenants, neighbours, or the general public.\n\n"
                                "8.4 Maximum Occupancy Limits: To ensure resident safety, comfort, and compliance with fire and building-safety norms, the number of persons residing in any flat shall not exceed the limits below:",
                              ),
                              const SizedBox(height: 10),
                              _buildOccupancyLimitsTable(),
                              const SizedBox(height: 10),
                              _buildParagraph(
                                "8.5 Occupancy beyond the limits in Clause 8.4 — whether through unauthorised additional occupants or otherwise — is strictly prohibited and constitutes a material breach entitling the Owner to the remedies under Clause 13 and Clause 17.",
                              ),
                              const SizedBox(height: 24),

                              // Section 9: Tenant's General Obligations
                              _buildClauseTitle("9. Tenant's General Obligations", keyId: "section_9"),
                              _buildParagraph(
                                "9.1 Pay Rent, installments, and all Package Facility charges on time as per Clause 5.\n\n"
                                "9.2 Maintain the Premises, fittings, fixtures, and furnishings provided in good and tenantable condition, normal wear and tear excepted.\n\n"
                                "9.3 Promptly report any damage, malfunction, leakage, or safety hazard in the Premises or Common Areas to the Owner/App helpdesk.\n\n"
                                "9.4 Permit the Owner or its authorised representative to inspect the Premises in accordance with Clause 14.\n\n"
                                "9.5 Not make any structural alteration, additional construction, drilling, or fixture installation without the Owner's prior written consent.\n\n"
                                "9.6 Comply with all applicable laws, municipal regulations, society/RWA rules, and fire-safety norms during occupation.\n\n"
                                "9.7 Keep the Owner informed, through the App, of correct and current contact details and guardian/emergency contact information.\n\n"
                                "9.8 Vacate and hand over peaceful, vacant, and undamaged possession of the Premises upon expiry or termination of this Agreement, along with all keys, access cards, and Residency-issued property.\n\n"
                                "9.9 Keep personal valuables and belongings securely locked away when absent from the Premises. The Owner/Residency staff shall not be liable for loss of personal belongings from the Premises, except to the extent caused by the Owner's proven gross negligence.\n\n"
                                "9.10 Cooperate with the Owner's repair, maintenance, and housekeeping staff, including during the Tenant's absence and specifically during the summer vacation/break period when block-level or Residency-wide maintenance work may be undertaken (see Clause 15.4). The Tenant shall not obstruct such work.\n\n"
                                "9.11 Cooperate with police verification, tenant registration, or other formalities required by applicable law, as referred to in Clause 5.11.",
                              ),
                              const SizedBox(height: 24),

                              // Section 10: Prohibited Activities and Strict Conduct Rules
                              _buildClauseTitle("10. Prohibited Activities and Strict Conduct Rules", keyId: "section_10"),
                              _buildParagraph(
                                "The Tenant expressly acknowledges and agrees that the activities described below are strictly prohibited within the Premises, the Residency, and in connection with use of the App. Any breach of this Clause 10 shall be treated as a material and fundamental breach of this Agreement, entitling the Owner to the remedies set out in Clause 13 and Clause 17, including but not limited to immediate termination, forfeiture of the Security Deposit and Booking Amount, eviction in accordance with law, and initiation of criminal/civil legal proceedings.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.1 Damage to Property", keyId: "section_10_1"),
                              _buildParagraph(
                                "10.1.1 The Tenant shall not intentionally or negligently damage, deface, remove, or destroy any part of the Premises, Common Areas, furniture, fixtures, fittings, electrical/plumbing installations, or any property belonging to the Owner, the Residency, or other tenants.\n\n"
                                "10.1.2 Any damage beyond normal wear and tear shall be assessed by the Owner and the cost of repair/replacement shall be recovered from the Security Deposit and/or directly from the Tenant. In a shared room, such cost may be recovered jointly from all occupants of that room, without prejudice to the Owner's right to pursue further legal remedies for wilful or grossly negligent damage.\n\n"
                                "10.1.3 The Tenant shall be liable for damage caused by any guest, visitor, or Authorised Occupant permitted onto the Premises by the Tenant.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.2 Drugs, Narcotics and Substance Abuse", keyId: "section_10_2"),
                              _buildParagraph(
                                "10.2.1 The possession, consumption, cultivation, storage, sale, distribution, or facilitation of any narcotic drug or psychotropic substance banned under the Narcotic Drugs and Psychotropic Substances Act, 1985 (or any successor/equivalent law) is absolutely and strictly prohibited within the Premises, the Residency, and its Common Areas. Smoking, drinking, and chewing tobacco are likewise governed by the Residency's house rules and applicable law.\n\n"
                                "10.2.2 Upon discovery or reasonable suspicion of any activity described in this Clause 10.2, the Owner shall be entitled, without further notice, to (a) immediately restrict/terminate occupancy, (b) confiscate and hand over any illegal substance/paraphernalia to the police, (c) inform the Tenant's parent/guardian, and (d) lodge a formal police complaint and fully cooperate with any resulting investigation or prosecution, at the Tenant's sole cost and risk.\n\n"
                                "10.2.3 The Tenant shall indemnify the Owner against any loss, penalty, or legal consequence arising from a violation of this Clause 10.2 by the Tenant or any person permitted onto the Premises by the Tenant.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.3 Activities Involving Minors", keyId: "section_10_3"),
                              _buildParagraph(
                                "10.3.1 No Minor shall reside at, be housed in, or stay overnight at the Premises unless such Minor is accompanied by, and under the direct supervision of, a parent or legal guardian, or unless prior written consent has been obtained from the Owner along with complete identity and guardian-contact details.\n\n"
                                "10.3.2 The Tenant shall not engage, permit, or facilitate any activity on the Premises or through the App that endangers the safety or welfare of a Minor, or that constitutes an offence under the Protection of Children from Sexual Offences (POCSO) Act, 2012, the Juvenile Justice (Care and Protection of Children) Act, 2015, or the Indian Penal Code / Bharatiya Nyaya Sanhita.\n\n"
                                "10.3.3 The Tenant shall not possess, download, store, create, or distribute child sexual abuse material (CSAM) or any exploitation material involving Minors, using the Residency's Wi-Fi network or on the Premises. Any violation of this sub-clause shall result in immediate termination, eviction, forfeiture of deposits, and a mandatory immediate report by the Owner to law enforcement authorities.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.4 Commercial, Business or Unlawful Trade Activity", keyId: "section_10_4"),
                              _buildParagraph(
                                "10.4.1 The Premises shall not be used to carry on any trade, business, commercial activity, manufacturing, or professional practice, whether registered or unregistered, including using the Premises as a registered office, godown, retail pickup point, or dark-store hub.\n\n"
                                "10.4.2 The Tenant shall not run or permit to be run from the Premises any unlawful enterprise, including gambling, betting, sex work, multi-level marketing (MLM) schemes, or financial fraud.\n\n"
                                "10.4.3 Violation of this Clause 10.4 shall entitle the Owner to immediately terminate this Agreement, report the activity to the relevant municipal and tax authorities, and claim damages from the Tenant.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.5 Unauthorised Occupants, Subletting and Relocation of Third Parties", keyId: "section_10_5"),
                              _buildParagraph(
                                "10.5.1 Subletting, licensing, sharing, assigning, or parting with possession of the Premises (or any bed/portion thereof) to any third person, whether for money or free of charge, is strictly prohibited.\n\n"
                                "10.5.2 No person other than the Tenant (and Authorised Occupants) shall be permitted to reside in the Premises. Permitting any third person to stay at the Premises for a cumulative period exceeding seven (7) days without prior written disclosure to and written permission from the Owner shall be deemed an unauthorised subletting / illegal occupation under this Clause.\n\n"
                                "10.5.3 The Tenant shall not allow any person facing criminal charges, an active warrant, or an externment/interim restraining order to stay at the Premises.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.6 Mobile Application — Acceptable Use Policy", keyId: "section_10_6"),
                              _buildParagraph(
                                "10.6.1 The App is an essential operational tool of Lakshya Residency. The Tenant shall use the App solely for bona fide purposes connected with this Agreement.\n\n"
                                "10.6.2 The Tenant shall not:\n"
                                "• Hack, probe, reverse-engineer, decompile, or attempt to compromise the App's security, API, or databases;\n"
                                "• Submit false, forged, altered, or misleading identity documents, payment receipts, or KYC information through the App;\n"
                                "• Interfere with the payment gateway, manipulate transaction references, or generate fraudulent payment confirmations;\n"
                                "• Harass, abuse, defame, threaten, or send unsolicited bulk messages to other residents, staff, or the Owner through the App's messaging or complaint facilities;\n"
                                "• Post false or maliciously defamatory reviews, tickets, or allegations through the App.\n\n"
                                "10.6.3 The Tenant is solely responsible for maintaining the confidentiality of their App login credentials. Any action taken through the Tenant's authenticated App session shall be deemed to have been taken by the Tenant.\n\n"
                                "10.6.4 Compromising the App's integrity or attempting payment fraud through the App shall, in addition to being a material breach of this Agreement, result in immediate suspension of App access, civil recovery proceedings, and filing of a First Information Report (FIR) under the Information Technology Act, 2000 and the Indian Penal Code / Bharatiya Nyaya Sanhita.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.7 General Nuisance, Safety and Miscellaneous Prohibitions", keyId: "section_10_7"),
                              _buildParagraph(
                                "The Tenant shall not engage in any of the following activities:\n"
                                "• Playing loud music, shouting, or causing disturbance during Quiet Hours (from 23:00 hours to 07:00 hours);\n"
                                "• Storing hazardous, flammable, explosive, or toxic materials, gas cylinders (other than Owner-approved cooking gas arrangements), fireworks, or firearms/weapons on the Premises;\n"
                                "• Bringing pets into the Residency without the Owner's prior written consent;\n"
                                "• Tampering with CCTV cameras, fire alarms, smoke detectors, electrical panels, water meters, or security equipment;\n"
                                "• Hanging clothes, placing shoes/racks, or leaving waste, bicycles, or personal property in Common Areas or fire escapes;\n"
                                "• Consuming alcohol, banned substances, or tobacco in Common Areas;\n"
                                "• Littering, spitting, or defacing walls, doors, or furniture;\n"
                                "• Tampering with, duplicating, or lending keys, RFID cards, or access credentials to non-residents;\n"
                                "• Throwing waste, liquids, or objects out of windows, balconies, or onto neighbouring properties;\n"
                                "• Entering areas marked \"Staff Only\", electrical/pump rooms, or the terrace during restricted hours without permission.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.8 Fights and Disputes Among Residents", keyId: "section_10_8"),
                              _buildParagraph(
                                "10.8.1 Physical violence, assault, threatening behaviour, ragging, extortion, harassment (verbal, physical, or sexual), or bullying of any fellow resident, staff member, or neighbour is strictly prohibited.\n\n"
                                "10.8.2 Lakshya Residency maintains a strict zero-tolerance policy towards ragging, harassment of fellow students, and gender-based offences. Any incident shall be reported to the local police and to the resident's educational institution immediately.\n\n"
                                "10.8.3 The Tenant shall be liable for all harm, medical expenses, property damage, and legal consequences arising from any physical altercation or dispute initiated or participated in by the Tenant.",
                              ),
                              const SizedBox(height: 24),

                              // Section 11: House Rules — Curfew, Outings and Visitor Policy
                              _buildClauseTitle("11. House Rules — Curfew, Outings and Visitor Policy", keyId: "section_11"),
                              _buildParagraph(
                                "11.1 Outing Hours: The Tenant may move within the immediate vicinity of the Residency until ______ hours. Venturing outside the city/campus area requires prior intimation to the Tenant's parent/guardian and to the Owner/warden.\n\n"
                                "11.2 Door-Closing Time: The main gate/door of the Residency shall close at ______ hours in summer and ______ hours in winter. The Tenant shall return to the Residency before this time.\n\n"
                                "11.3 Late Entry: A Tenant seeking to return after the closing time for a genuine reason must obtain prior permission from their parent/guardian and the warden/Owner. Unauthorised late entry may attract a penalty or disciplinary action, and repeated late entry may be reported to the Tenant's parent/guardian.\n\n"
                                "11.4 Night-Out / Overnight Absence: The Tenant must submit a written/App-based night-out application, noting the time of departure in the Residency's register, and obtain the Owner's/warden's approval — ordinarily conditional on parental consent — before staying away from the Residency overnight.\n\n"
                                "11.5 Overnight Guests: Overnight stay of any outside friend or visitor in the Tenant's room is not permitted, save as provided under Clause 12 (Co-Habitation) or with the Owner's express prior written consent. A visitor of a different gender than the room's registered occupants shall not stay overnight in the room, and may only be received during permitted visiting hours in designated common areas, consistent with the Residency's safety and decorum policy.\n\n"
                                "11.6 If the Tenant does not return by the curfew time without prior permission and cannot be reached, the Owner may inform the Tenant's parent/guardian. The Owner shall not be liable for any mishap suffered by the Tenant while outside the Residency without having taken due permission.",
                              ),
                              const SizedBox(height: 24),

                              // Section 12: Co-Habitation / Live-in Arrangements
                              _buildClauseTitle("12. Co-Habitation / Live-in Arrangements", keyId: "section_12"),
                              _buildParagraph(
                                "12.1 Where an adult Tenant (18 years of age or above) wishes to reside at the Premises together with a partner in a live-in / co-habiting arrangement, the Tenant shall, prior to admission or prior to commencing such an arrangement, inform their parent(s)/legal guardian(s) of the same.\n\n"
                                "12.2 Both cohabiting residents shall execute and submit to the Owner a signed Co-Habitation Consent Form, in the format at Annexure I to this Agreement, either physically or digitally through the App, expressly confirming that their decision to reside together is mutual, voluntary, and free of coercion.\n\n"
                                "12.3 The Owner permits such an arrangement purely as an accommodation facilitator and assumes no responsibility for the personal, emotional, financial, or legal consequences of the relationship between the cohabiting residents. In the event of any dispute, separation, allegation, or incident arising between such residents, the Owner shall not be held liable in any manner whatsoever, save for matters arising from the Owner's own proven negligence or wilful misconduct in the management of the Premises.\n\n"
                                "12.4 This Clause applies only where both cohabiting residents are adults. Any arrangement involving a Minor is additionally governed by, and must comply with, Clause 10.3 (Activities Involving Minors), including express guardian consent, and shall not be permitted in the absence of such consent.\n\n"
                                "12.5 Nothing in this Clause obligates the Owner to allot a shared room to cohabiting residents; room/bed allocation remains subject to availability, the Owner's policies, and the occupancy limits at Clause 8.4.",
                              ),
                              const SizedBox(height: 24),

                              // Section 13: Owner's Rights and Remedies on Breach
                              _buildClauseTitle("13. Owner's Rights and Remedies on Breach", keyId: "section_13"),
                              _buildParagraph(
                                "13.1 Right of Admission: The Owner reserves the right of admission to the Residency and may, at its sole discretion, refuse, defer, or cancel any booking/admission — including after provisional acceptance — without being obliged to disclose reasons, subject to the Owner's cancellation/refund policy then in force.\n\n"
                                "13.2 Without prejudice to any other right or remedy available under this Agreement or in law, upon the occurrence of any breach described in Clause 10 (or any other material breach of this Agreement), the Owner shall be entitled to any or all of the following remedies, at its sole discretion:\n"
                                "• Issue a written warning through the App specifying the breach and requiring rectification within a stipulated period;\n"
                                "• Immediately suspend access to any or all Package Facilities and/or the App, without refund for the suspended period;\n"
                                "• Forfeit the Security Deposit and Booking Amount, in whole or in part, to the extent of loss, damage, or dues arising from the breach;\n"
                                "• Terminate this Agreement with immediate effect (in cases of illegal activity, drug-related offences, offences involving Minors, or serious damage/danger) or upon notice as specified in Clause 17 (for other breaches), and require the Tenant to vacate the Premises;\n"
                                "• Lodge a formal complaint with the local police station, cyber-crime cell, municipal authority, educational institution, or any other appropriate government or regulatory authority;\n"
                                "• Pursue civil proceedings for recovery of dues, damages, and costs, and/or support criminal proceedings where the breach constitutes an offence under Indian law;\n"
                                "• Escalate the matter to the Tenant's parent/legal guardian and/or educational institution, where reasonably necessary for safety, disciplinary, or recovery purposes.\n\n"
                                "13.3 The Owner's exercise of, or delay in exercising, any right under this Clause shall not be construed as a waiver of that right or of any other right available to the Owner.",
                              ),
                              const SizedBox(height: 24),

                              // Section 14: Inspection, Entry and Room Reallocation
                              _buildClauseTitle("14. Inspection, Entry and Room Reallocation", keyId: "section_14"),
                              _buildParagraph(
                                "14.1 The Owner or its authorised representative may enter the Premises for inspection, maintenance, or verification purposes.\n\n"
                                "14.2 The Tenant shall not unreasonably deny access for such inspection or emergency entry.\n\n"
                                "14.3 The Owner may carry out necessary repair and maintenance work in the Premises/Residency at its discretion, including during the Tenant's absence, and the Tenant shall have no objection to entry for such purpose, subject to reasonable care of the Tenant's belongings by the Owner's staff.\n\n"
                                "14.4 Room / Building Reallocation: The Owner reserves the right, for operational reasons, to shift/transfer the Tenant from one room/bed to another, or from one building/property under the Residency to another, on similar terms. Where such a shift involves any change in charges, the same shall be recorded via an addendum or an updated Schedule on the App.",
                              ),
                              const SizedBox(height: 24),

                              // Section 15: Maintenance, Repairs and Damage Liability
                              _buildClauseTitle("15. Maintenance, Repairs and Damage Liability", keyId: "section_15"),
                              _buildParagraph(
                                "15.1 For Tenants staying on a purely rental (non-package) basis, the first month's routine maintenance and any repair required in the Premises shall be attended to by the Owner at no additional cost. From the second month of the Term onward, day-to-day maintenance and minor shall be arranged and borne by the Tenant.\n\n"
                                "15.2 All repair/maintenance requests shall be logged through the App, and the Owner shall use reasonable efforts to address them within a reasonable timeframe.\n\n"
                                "15.3 The inventory of furniture, fixtures, and appliances provided in the Premises should be used with care. The Tenant shall verify this inventory at the time of possession and shall be liable for any shortfall or damage identified at the time of vacating, save for normal wear and tear.\n\n"
                                "15.4 Summer Break Maintenance: The Owner may undertake block-level, floor-level, or Residency-wide maintenance, repainting, pest control, or renovation work during the summer vacation/break period (or any other declared maintenance window). The Tenant shall cooperate with the Owner's staff/contractors for access, temporary relocation of belongings, or temporary access restriction during such maintenance, and shall not obstruct such work.",
                              ),
                              const SizedBox(height: 24),

                              // Section 16: Security Deposit and Advance Charges — Deductions and Refund
                              _buildClauseTitle("16. Security Deposit and Advance Charges — Deductions and Refund", keyId: "section_16"),
                              _buildParagraph(
                                "16.1 The Owner may deduct from the Security Deposit: (a) unpaid Rent, installments, or Package Facility charges; (b) cost of repair or replacement of damaged property under Clause 10.1; (c) unpaid utility or common area charges; (d) any penalty or holding-over compensation validly due under this Agreement; and (e) any other amount lawfully due from the Tenant to the Owner.\n\n"
                                "16.2 Where the Tenant has completed the full Lock-in Period / Academic Session and dues stand settled, the balance Security Deposit shall be refunded.\n\n"
                                "16.3 Non-Refund on Early Exit: Notwithstanding Clause 16.1 and 16.2, and as also stated in Clause 5.8, if the Tenant vacates the Premises, discontinues occupation, or withdraws from this Agreement before completing the full Lock-in Period / Academic Session, the entire Security Deposit and the Booking Amount shall stand absolutely forfeited and shall not be refunded under any circumstance, and outstanding Rent/Package charges for the remaining Academic Session shall remain payable, without prejudice to the Owner's other rights.",
                              ),
                              const SizedBox(height: 24),

                              // Section 17: Termination of Agreement
                              _buildClauseTitle("17. Termination of Agreement", keyId: "section_17"),
                              _buildParagraph(
                                "17.1 Owner may terminate the residency of tenant prior to expiry of the Term without being held for giving any.\n\n"
                                "17.2 The Owner may terminate residency of tenant with immediate effect and without notice in the event of: (a) any breach falling under Clause 10.2 (drugs/narcotics) or Clause 10.3 (offences involving Minors); (b) any act endangering the life, safety, or property of the Owner, staff, or other tenants; (c) any activity that is unlawful and exposes the Owner or the Residency to legal or regulatory liability; (d) breach of the occupancy limits at Clause 8.4; or (e) co-habitation without the consent form required under Clause 12.2.\n\n"
                                "17.3 Non-Payment: If Rent, an installment, or Package charges remain unpaid beyond 3 days from the due date, the late payment charge under Clause 5.9 applies. If such amount remains unpaid beyond 7 days from the due date, or if there is a delay beyond 7 days for a second consecutive billing period, the Owner may terminate this Agreement forthwith, without further notice, and require the Tenant to vacate within forty-eight (48) hours.\n\n"
                                "17.4 Other Breaches: For any material breach of this Agreement not covered by Clauses 17.2 or 17.3, the Owner may issue a written notice through the App requiring the Tenant to remedy the breach within 7 (seven) days. If the breach is not remedied within the notice period, this Agreement shall stand terminated upon expiry of the notice.",
                              ),
                              const SizedBox(height: 24),

                              // Section 18: Consequences of Termination for Cause
                              _buildClauseTitle("18. Consequences of Termination for Cause", keyId: "section_18"),
                              _buildParagraph(
                                "18.1 Upon termination of this Agreement for cause (under Clause 17):\n"
                                "(a) The Tenant shall vacate the Premises and remove all personal belongings within the time specified by the Owner (not exceeding 48 hours for immediate-termination grounds, or within the notice period for other grounds);\n"
                                "(b) All outstanding Rent, Package charges, and other dues for the remaining period of the Academic Session shall become immediately due and payable;\n"
                                "(c) The Security Deposit and Booking Amount shall stand fully forfeited;\n"
                                "(d) The Owner may deactivate the Tenant's App access and biometric/key access credentials;\n\n"
                                "18.2 If the amount due under Clause 18.1(b), together with the cost of repair of any damage, exceeds the Security Deposit and Booking Amount, the Tenant (and their parent/guardian) shall be jointly and severally liable to pay the deficiency within seven (7) days of demand.\n\n"
                                "18.3 Leftover Belongings: If the Tenant fails to remove their personal belongings from the Premises upon expiry of the handover period, the Owner may, after giving forty-eight (48) hours' notice through the App, pack and store the items at the Tenant's risk and cost (storage charge: ₹200 per day). If unclaimed beyond thirty (30) days from notice, the Owner may dispose of or auction the items to recover accrued storage and dues, without further liability to the Tenant.\n\n"
                                "18.4 Eviction: The Tenant acknowledges that the permission to occupy granted under this leave and licence stands revoked upon termination. If the Tenant refuses to vacate, the Owner shall be entitled to re-enter, take peaceful possession of the Premises, change locks/access credentials, and seek assistance from local law enforcement and civil courts to effect eviction, at the Tenant's cost.\n\n"
                                "18.5 The Tenant shall be liable for holding-over compensation at twice the daily rent rate for each day of unauthorised occupation following the date on which the Tenant was required to vacate.",
                              ),
                              const SizedBox(height: 24),

                              // Section 19: Indemnity and Limitation of Liability
                              _buildClauseTitle("19. Indemnity and Limitation of Liability", keyId: "section_19"),
                              _buildParagraph(
                                "19.1 The Tenant shall indemnify, defend, and hold harmless the Owner, its agents, employees, and representatives from and against all claims, liabilities, losses, damages, penalties, fines, costs, and expenses (including reasonable legal fees) arising from:\n"
                                "(a) Any breach of this Agreement or violation of applicable law by the Tenant or any guest/visitor/occupant permitted by the Tenant;\n"
                                "(b) Any loss, damage, or injury caused to person or property by any intentional act, negligence, or omission of the Tenant;\n"
                                "(c) Any proceedings initiated by a third party, educational institution, local authority, or law-enforcement agency in connection with activities carried out by the Tenant on or from the Premises.\n\n"
                                "19.2 Limitation of Owner's Liability: To the maximum extent permitted by applicable law:\n"
                                "(a) The Owner shall not be liable for any indirect, incidental, special, consequential, or punitive damages;\n"
                                "(b) The Owner's total cumulative liability arising out of or in connection with this Agreement shall not exceed the total amount of Rent actually paid by the Tenant to the Owner during the three (3) months preceding the event giving rise to liability;\n"
                                "(c) The Owner shall not be liable for the loss, theft, or damage of personal belongings, cash, jewellery, laptops, mobile phones, or other valuables kept in the Premises or Common Areas, except where caused by the Owner's proven gross negligence;\n\n"
                                "19.3 The Tenant is strongly advised to obtain independent personal insurance for their belongings and medical coverage.",
                              ),
                              const SizedBox(height: 24),

                              // Section 20: Health, Safety, Emergency and Personal Well-Being
                              _buildClauseTitle("20. Health, Safety, Emergency and Personal Well-Being", keyId: "section_20"),
                              _buildParagraph(
                                "20.1 The Tenant shall keep the Premises in a hygienic condition, free from biohazards, accumulated waste, and pests, and shall dispose of rubbish daily in designated bins.\n\n"
                                "20.2 The Tenant shall promptly report any communicable disease, medical condition requiring emergency support, or epidemic symptoms to the warden, and shall comply with any health directives in force at the Residency from time to time. In the event of a government-mandated evacuation arising from a pandemic or public-health emergency, Rent/Fees for the ongoing Academic Session shall remain payable notwithstanding early vacation, unless the Owner decides otherwise.\n\n"
                                "20.3 In case of a genuine medical or safety emergency involving the Tenant, the Owner/Residency staff may take reasonable steps (including contacting emergency services or the Tenant's emergency contact/guardian) without such action being construed as a breach of privacy or of this Agreement.\n\n"
                                "20.4 Self-Harm and Personal Safety: While the Owner shall take the reasonable and bona fide safety precautions expected of a residential facility operator, the Owner shall not be held liable for any act of self-harm, attempted suicide, or suicide committed by a Tenant/resident on or off the Premises, except to the extent such incident arises directly from the Owner's own proven gross negligence or wilful default in maintaining basic safety standards at the Premises. The Tenant and their parent/guardian acknowledge that the Owner is not a medical or mental-health care provider and undertakes no duty of clinical care towards residents.\n\n"
                                "20.5 The Residency encourages any Tenant experiencing emotional distress or a mental-health concern to reach out to their family, the Residency's designated warden/contact person, their institution's counselling service, or a national mental-health helpline, details of which shall be displayed at the Residency and on the App.",
                              ),
                              const SizedBox(height: 24),

                              // Section 21: Force Majeure
                              _buildClauseTitle("21. Force Majeure", keyId: "section_21"),
                              _buildParagraph(
                                "21.1 Neither Party shall be held liable for any failure or delay in performing its obligations under this Agreement (excluding payment obligations) where such failure or delay results from circumstances beyond its reasonable control, including natural disaster, fire, pandemic, government order, strike, or civil unrest.",
                              ),
                              const SizedBox(height: 24),

                              // Section 22: Confidentiality, Data Privacy and Promotional Use
                              _buildClauseTitle("22. Confidentiality, Data Privacy and Promotional Use", keyId: "section_22"),
                              _buildParagraph(
                                "22.1 Personal data collected from the Tenant via the App (including identity proof, contact details, payment information, and complaint history) shall be used by the Owner solely for purposes connected with this Agreement, tenancy administration, safety, and legal compliance, and shall not be sold to unrelated third parties.\n\n"
                                "22.2 Promotional Use: The Owner may, for promotional purposes, use testimonials, photographs, or videos of the Tenant taken during events or activities organised at the Residency, on its website, social media, or marketing material, provided the same is not used in a manner prejudicial to the Tenant.\n\n"
                                "22.3 Non-Disclosure of Agreement Terms: The Tenant shall keep the commercial terms of this Agreement (Rent, Package charges, Security Deposit, Booking Amount, etc.) confidential and shall not disclose the same to third parties, other than parents/guardians or as required by law.",
                              ),
                              const SizedBox(height: 24),

                              // Section 23: Dispute Resolution and Governing Law
                              _buildClauseTitle("23. Dispute Resolution and Governing Law", keyId: "section_23"),
                              _buildParagraph(
                                "23.1 The Parties shall in the first instance attempt to amicably resolve any dispute arising out of or in connection with this Agreement through good-faith discussion.\n\n"
                                "23.2 This Agreement shall be governed by and construed in accordance with the laws of India.\n\n"
                                "23.3 Nothing in this Clause 23 shall restrict the Owner's right to approach the police or any competent criminal court directly, without recourse to arbitration, in respect of any act constituting a criminal offence under Clause 10 of this Agreement.",
                              ),
                              const SizedBox(height: 24),

                              // Section 24: General / Miscellaneous Provisions
                              _buildClauseTitle("24. General / Miscellaneous Provisions", keyId: "section_24"),
                              _buildParagraph(
                                "24.1 Notices: Any notice required under this Agreement shall be deemed validly served if sent via the App, registered post, e-mail, or hand delivery to the addresses/contact details recorded herein.\n\n"
                                "24.2 Amendment: No amendment or waiver of any provision of this Agreement shall be effective unless made in writing and signed/digitally accepted by both Parties.\n\n"
                                "24.3 Severability: If any provision of this Agreement is held invalid or unenforceable, the remaining provisions shall continue in full force and effect.\n\n"
                                "24.4 Entire Agreement: This Agreement, along with its Schedules and Annexure, constitutes the entire agreement between the Parties and supersedes all prior discussions, representations, or agreements, whether oral or written, relating to its subject matter.\n\n"
                                "24.5 Assignment by Tenant: The Tenant shall not assign or transfer any rights or obligations under this Agreement without the Owner's prior written consent.\n\n"
                                "24.6 Assignment by Owner: The Owner may sell, transfer, mortgage, or assign its rights and obligations under this Agreement, in whole or in part, without requiring the Tenant's consent. Upon such transfer, the Owner shall stand released from obligations arising thereafter, and the Tenant shall, upon written notice, recognise the transferee as the Owner for the residual Term.\n\n"
                                "24.7 Counterparts and Digital Execution: This Agreement may be executed in counterparts, including digitally through the App, each of which shall be deemed an original.",
                              ),
                              const SizedBox(height: 28),

                              // SCHEDULES
                              const Divider(thickness: 1.5, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 20),

                              _buildScheduleHeading("SCHEDULE A — Student Onboarding & Property Details", keyId: "schedule_a"),
                              _buildParagraph(
                                "The fields below are populated automatically from the Tenant's onboarding profile on the App at the time this Agreement is generated. Any change to these details after execution must be updated on the App and, where materially relevant (e.g., room/bed/building), confirmed with the Owner:",
                              ),
                              const SizedBox(height: 10),
                              _buildScheduleATable(d),
                              const SizedBox(height: 28),

                              _buildScheduleHeading("SCHEDULE D — Furniture, Inventory and House Rules Acknowledgement", keyId: "schedule_d"),
                              _buildParagraph(
                                "The furniture, fixtures, and appliances provided in the Premises at the time of onboarding/move-in are as listed in the Tenant's onboarding record on the App (e.g., bed, mattress, study table, chair, wardrobe, fan, light, curtains, geyser, and other applicable items with quantity). Both Parties confirm this inventory and its condition through the App at check-in, and any discrepancy must be flagged within 48 hours of move-in.\n\n"
                                "Allotted Inventory Checklist (${d.inventoryItems.length} items):\n"
                                "${d.inventoryItems.isNotEmpty ? d.inventoryItems.map((e) => '• $e').join('   |   ') : 'Standard room inventory verified at check-in (bed, mattress, study table, chair, wardrobe, fan, light, geyser).'}\n\n"
                                "The Tenant confirms having read and understood the Residency's house rules (displayed on the notice board and/or the App), including visiting hours, quiet hours, gate-closing time, and the guest-registration procedure at Clause 11, and agrees to be bound by the same as part of this Agreement.",
                              ),
                              const SizedBox(height: 28),

                              _buildScheduleHeading("ANNEXURE I — CO-HABITATION / LIVE-IN CONSENT FORM", keyId: "annexure_1"),
                              _buildParagraph(
                                "(To be submitted physically or through the App by both residents, where applicable, in accordance with Clause 12 of this Agreement)\n\n"
                                "We, the undersigned, both being adult residents of Lakshya Residency, voluntarily confirm our mutual consent to reside together at the Premises described below. We acknowledge and accept the terms of Clause 12 (Co-Habitation / Live-in Arrangements) of this Agreement, including that Lakshya Residency and its Owner shall not be liable for any personal, relationship, financial, or legal issue arising between us during or after this arrangement, save for matters arising from the Owner's own proven negligence or wilful misconduct.",
                              ),
                              const SizedBox(height: 10),
                              _buildAnnexureITable(d),
                              const SizedBox(height: 28),

                              _buildScheduleHeading("TENANT'S DECLARATION", keyId: "declaration"),
                              _buildParagraph(
                                "D.1 I confirm that I am legally permitted and eligible to execute this Agreement, either personally or through my parent/legal guardian, and that the particulars fetched from my onboarding profile on the App are true and accurate to the best of my knowledge; I have not wilfully suppressed any material fact, and I understand that any misrepresentation may render me ineligible for accommodation.\n\n"
                                "D.2 I undertake to submit valid KYC documents (Government ID and College ID, as recorded in the app) to the Owner through the App on or before moving into the Premises, and to provide full cooperation and documentation for any police verification, tenant registration, or similar process required by the Owner or applicable law.\n\n"
                                "D.3 I undertake not to disclose the commercial terms of this Agreement, including the information at Schedule A, D, to any third party other than my parent/guardian or as required by law, in accordance with Clause 22.5.\n\n"
                                "D.4 I have read and understood this Agreement in full, including Clause 10 (Prohibited Activities and Strict Conduct Rules) and Clause 13 (Owner's Rights and Remedies). I understand and agree that engaging in property damage, drug/narcotic-related activity, any activity endangering a Minor, unauthorised commercial/business use of the Premises, housing any unauthorised person for a prolonged period without prior disclosure and consent, exceeding the occupancy limits at Clause 8.4, or misuse of the App, shall constitute a serious breach of this Agreement.\n\n"
                                "D.5 I understand that the Owner has the full right, without limitation, to terminate this Agreement, forfeit the Security Deposit and Booking Amount to the extent described in Clauses 5.8, 16.3 and 18, evict me in accordance with law, lodge a police complaint, and/or escalate the matter to any higher civil, criminal, or regulatory authority, and I accept full legal responsibility for any consequence arising from such breach.\n\n"
                                "D.6 I confirm that I have read and understood Clause 20.4 (Self-Harm and Personal Safety) and Clause 19.2 (Limitation of Liability) of this Agreement.",
                              ),
                              const SizedBox(height: 14),

                              // Important Notice Box
                              _buildPdfWarningBox(
                                title: "IMPORTANT NOTICE",
                                text: "This Agreement is a legal contract. Violation of the prohibitions in Clause 10 may expose the Tenant to civil liability, forfeiture of the Security Deposit and Booking Amount, immediate eviction, and criminal prosecution under applicable Indian law. Leaving before completing the Lock-in Period (${d.rentalTerm}) results in full forfeiture of the Security Deposit and Booking Amount as described in Clauses 5.8 and 16.3. By signing below (or accepting digitally on the App), the Tenant acknowledges full understanding and acceptance of these consequences.",
                              ),
                              const SizedBox(height: 28),

                              _buildScheduleHeading("SIGNATURES", keyId: "signatures"),
                              _buildParagraph(
                                "IN WITNESS WHEREOF, the Parties (and, where the Tenant is a Minor, their parent/legal guardian) have set their hands / provided digital acceptance on the App, on the day, month, and year first above written. Where this Agreement is generated and accepted through the App, the Tenant's digital acceptance timestamp and login verification, together with the Owner's digital countersignature recorded on the App, shall be deemed equivalent to physical signatures for all purposes between the Parties.",
                              ),
                              const SizedBox(height: 24),

                              // ==========================================
                              // SIGNATURES SECTION
                              // ==========================================
                              // Owner Signature Block
                              Text(
                                "Owner / Licensor Signature:",
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 55,
                                    width: 220,
                                    alignment: Alignment.bottomLeft,
                                    child: Image.asset(
                                      'assets/images/owner_signature.jpg',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const Text(
                                        "[Mr. Ajay Singh - Signed]",
                                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 320,
                                    height: 1,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Name: Mr. Ajay Singh",
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "Designation: Founder / Licensor",
                                style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              Text(
                                "Date: ${d.agreementDate} | Status: Countersigned",
                                style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0056D2),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Student Signature Block
                              Text(
                                "Tenant / Student Signature:",
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Interactive Signature Pad
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(maxWidth: 450),
                                child: DigitalSignaturePad(
                                  key: _sigPadKey,
                                  title: "Draw your signature on the line",
                                  signerName: d.studentFullName,
                                  onSignatureCaptured: (bytes) {
                                    setState(() => _studentSignatureBytes = bytes);
                                  },
                                  onClear: () {
                                    setState(() => _studentSignatureBytes = null);
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Name: ${d.studentFullName}",
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "Room: Bldg ${d.building}, Rm ${d.roomNumber}${d.bedNumber.isNotEmpty ? ' (Bed ${d.bedNumber})' : ''}",
                                style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              Text(
                                "Date: ${d.agreementDate} | Status: Executed",
                                style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0056D2),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Guardian & Witnesses summary line (Matching PDF Page 23)
                              Text(
                                "(If Minor) Parent / Guardian: ${d.guardianName.isNotEmpty ? d.guardianName : 'N/A'} (${d.guardianRelationship})  |  Phone: ${d.guardianPhone.isNotEmpty ? d.guardianPhone : 'N/A'}",
                                style: GoogleFonts.roboto(fontSize: 11, fontStyle: FontStyle.italic, color: const Color(0xFF475569)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Witnesses: Witness 1 — Digital System Audit Verification (Lakshya Residency App Platform Engine)  |  Witness 2 — Resident Warden Desk, Jaipur",
                                style: GoogleFonts.roboto(fontSize: 11, color: const Color(0xFF475569)),
                              ),

                              const SizedBox(height: 28),
                              Center(
                                child: Text(
                                  "— End of Agreement —",
                                  style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        // FOOTER UI (Page 23 of 23)
                        _buildExactPdfFooter(23),
                        const SizedBox(height: 16),

                        // Agreement Confirmation Checkbox
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 28),
                          child: Container(
                            key: _getKey("confirmation_checkbox"),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: _hasAgreedToTerms ? const Color(0xFFF0FDF4) : Colors.white,
                              border: Border.all(
                                color: _hasAgreedToTerms ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _hasAgreedToTerms,
                                  activeColor: const Color(0xFF16A34A),
                                  onChanged: (val) => setState(() => _hasAgreedToTerms = val ?? false),
                                ),
                                Expanded(
                                  child: Text(
                                    "I have read and scrolled through all 24 sections, schedules, house rules, and lock-in commitments (${d.lockInPeriod}) of this Lakshya Residency Agreement. I accept all terms and conditions.",
                                    style: GoogleFonts.roboto(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Action Bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // EXACT HEADER UI MATCHING ORIGINAL PDF
  // ==========================================================================
  Widget _buildExactPdfHeader(String dateStr) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = w * (138.0 / 595.32);
        final double scale = w / 595.32;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TopHeaderNavyPainter(),
                ),
              ),
              Positioned(
                left: 12.0 * scale,
                top: 28.0 * scale,
                width: 145.0 * scale,
                height: 36.0 * scale,
                child: Image.asset(
                  'assets/images/lakshya_logo.png',
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
              Positioned(
                right: (595.32 - 529.3) * scale,
                top: 56.0 * scale,
                width: 3.2 * scale,
                height: 48.0 * scale,
                child: Container(color: const Color(0xFFFF009D)),
              ),
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

  // ==========================================================================
  // EXACT FOOTER UI MATCHING ORIGINAL PDF
  // ==========================================================================
  Widget _buildExactPdfFooter(int pageNum) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double scale = w / 595.32;
        final double h = 64.0 * scale;

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
                right: (595.32 - 523.4) * scale,
                bottom: 34.0 * scale,
                child: Text(
                  "Page $pageNum of 23",
                  style: GoogleFonts.roboto(
                    fontSize: 9.5 * scale,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // PAGE 1 COVER TABLE
  // ==========================================================================
  Widget _buildCoverTable(RentalAgreementData d) {
    return Table(
      border: TableBorder.all(color: const Color(0xFF94A3B8), width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2.0),
      },
      children: [
        _buildPdfTableRow("Agreement Date", d.agreementDate),
        _buildPdfTableRow("Owner / Licensor", "Lakshya Residency (Mr. Ajay Singh)"),
        _buildPdfTableRow("Tenant / Licensee (Student)", d.studentFullName),
        _buildPdfTableRow("Tenant’s Hometown Address", d.hometownAddress.isNotEmpty ? d.hometownAddress : "On file in App Profile"),
      ],
    );
  }

  TableRow _buildPdfTableRow(String col1, String col2, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFF1F5F9) : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            col1,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            col2,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w400,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TABLE OF CONTENTS (PAGE 2)
  // ==========================================================================
  Widget _buildTableOfContents() {
    final items = [
      ("TABLE OF CONTENTS", "2", "toc", false),
      ("1. Parties and Recitals", "4", "section_1", false),
      ("   Recitals", "4", "section_1_recitals", true),
      ("2. Nature of Agreement", "4", "section_2", false),
      ("3. Definitions and Interpretation", "5", "section_3", false),
      ("4. Term, Lock-In Period and Renewal", "5", "section_4", false),
      ("5. Booking, Rent, Deposits and Payment Terms", "6", "section_5", false),
      ("6. Package-Based Facilities (Optional Value-Added Services)", "8", "section_6", false),
      ("   6.A Meals", "8", "section_6_a", true),
      ("   6.B Pick-up and Drop to College/Institute", "8", "section_6_b", true),
      ("   6.C Laundry and Cleaning", "8", "section_6_c", true),
      ("   6.D Wi-Fi / Internet Access", "8", "section_6_d", true),
      ("   6.E General Terms Applicable to All Package Facilities", "9", "section_6_e", true),
      ("7. Utilities and Common Area Charges", "9", "section_7", false),
      ("8. Permitted Use of Premises and Occupancy Limits", "9", "section_8", false),
      ("9. Tenant's General Obligations", "11", "section_9", false),
      ("10. Prohibited Activities and Strict Conduct Rules", "11", "section_10", false),
      ("   10.1 Damage to Property", "11", "section_10_1", true),
      ("   10.2 Drugs, Narcotics and Substance Abuse", "12", "section_10_2", true),
      ("   10.3 Activities Involving Minors", "12", "section_10_3", true),
      ("   10.4 Commercial, Business or Unlawful Trade Activity", "12", "section_10_4", true),
      ("   10.5 Unauthorised Occupants, Subletting and Relocation of Third Parties", "13", "section_10_5", true),
      ("   10.6 Mobile Application — Acceptable Use Policy", "13", "section_10_6", true),
      ("   10.7 General Nuisance, Safety and Miscellaneous Prohibitions", "13", "section_10_7", true),
      ("   10.8 Fights and Disputes Among Residents", "14", "section_10_8", true),
      ("11. House Rules — Curfew, Outings and Visitor Policy", "14", "section_11", false),
      ("12. Co-Habitation / Live-in Arrangements", "15", "section_12", false),
      ("13. Owner's Rights and Remedies on Breach", "15", "section_13", false),
      ("14. Inspection, Entry and Room Reallocation", "16", "section_14", false),
      ("15. Maintenance, Repairs and Damage Liability", "16", "section_15", false),
      ("16. Security Deposit and Advance Charges — Deductions and Refund", "16", "section_16", false),
      ("17. Termination of Agreement", "17", "section_17", false),
      ("18. Consequences of Termination for Cause", "17", "section_18", false),
      ("19. Indemnity and Limitation of Liability", "18", "section_19", false),
      ("20. Health, Safety, Emergency and Personal Well-Being", "18", "section_20", false),
      ("21. Force Majeure", "19", "section_21", false),
      ("22. Confidentiality, Data Privacy and Promotional Use", "19", "section_22", false),
      ("23. Dispute Resolution and Governing Law", "19", "section_23", false),
      ("24. General / Miscellaneous Provisions", "19", "section_24", false),
      ("SCHEDULE A — Student Onboarding & Property Details", "21", "schedule_a", false),
      ("SCHEDULE D — Furniture, Inventory and House Rules Acknowledgement", "21", "schedule_d", false),
      ("ANNEXURE I — CO-HABITATION / LIVE-IN CONSENT FORM", "22", "annexure_1", false),
      ("   Resident 1", "22", "annexure_1", true),
      ("   Resident 2", "22", "annexure_1", true),
      ("   Acknowledged by Owner / Warden", "22", "annexure_1", true),
      ("TENANT'S DECLARATION", "22", "declaration", false),
      ("SIGNATURES", "23", "signatures", false),
      ("   Witnesses", "23", "signatures", true),
    ];

    return Container(
      key: _getKey("toc"),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              "TABLE OF CONTENTS",
              style: GoogleFonts.merriweather(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              "(Click any item below to jump directly to that section)",
              style: GoogleFonts.roboto(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF0056D2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final title = item.$1;
            final page = item.$2;
            final keyId = item.$3;
            final isSub = item.$4;

            return InkWell(
              onTap: () => _scrollToKey(keyId),
              borderRadius: BorderRadius.circular(4),
              hoverColor: const Color(0xFF0056D2).withValues(alpha: 0.08),
              child: Padding(
                padding: EdgeInsets.only(
                  left: isSub ? 16 : 4,
                  right: 4,
                  top: 3.5,
                  bottom: 3.5,
                ),
                child: Row(
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        title.trimLeft(),
                        style: GoogleFonts.roboto(
                          fontSize: isSub ? 10.5 : 11,
                          fontWeight: isSub ? FontWeight.w400 : FontWeight.w600,
                          color: const Color(0xFF0056D2),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF93C5FD),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final count = (constraints.maxWidth / 6).floor();
                          if (count <= 0) return const SizedBox.shrink();
                          return Text(
                            "." * count,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 2,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      page,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================================================
  // CLAUSE TITLE & PARAGRAPH HELPERS
  // ==========================================================================
  Widget _buildClauseTitle(String title, {String? keyId}) {
    return Container(
      key: keyId != null ? _getKey(keyId) : null,
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.merriweather(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildSubClauseTitle(String title, {String? keyId}) {
    return Container(
      key: keyId != null ? _getKey(keyId) : null,
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.merriweather(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildScheduleHeading(String title, {String? keyId}) {
    return Container(
      key: keyId != null ? _getKey(keyId) : null,
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.merriweather(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: GoogleFonts.roboto(
        fontSize: 11,
        height: 1.5,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildPdfWarningBox({required String title, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.justify,
            style: GoogleFonts.roboto(
              fontSize: 10.5,
              height: 1.45,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // PACKAGE FACILITIES TABLE (2 COLUMNS MATCHING TEMPLATE)
  // ==========================================================================
  Widget _buildTh(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildOccupancyLimitsTable() {
    return Table(
      border: TableBorder.all(color: const Color(0xFF94A3B8), width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.8),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF1F3864)),
          children: [
            _buildTh("Flat Configuration"),
            _buildTh("Maximum Persons Permitted"),
          ],
        ),
        _build2ColRow("1 BHK", "2 persons"),
        _build2ColRow("2 BHK", "4 persons"),
        _build2ColRow("3 BHK", "6 persons"),
      ],
    );
  }

  TableRow _build2ColRow(String col1, String col2) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(col1, style: GoogleFonts.roboto(fontSize: 10.5, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(col2, style: GoogleFonts.roboto(fontSize: 10.5)),
        ),
      ],
    );
  }

  // ==========================================================================
  // SCHEDULE A, B, C TABLES
  // ==========================================================================
  Widget _buildScheduleATable(RentalAgreementData d) {
    return Table(
      border: TableBorder.all(color: const Color(0xFF94A3B8), width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(1.4),
        1: FlexColumnWidth(2.2),
      },
      children: [
        _buildPdfTableRow("Full Name", d.studentFullName),
        _buildPdfTableRow("Mobile Number", d.mobileNumber),
        _buildPdfTableRow("Email ID", d.email),
        _buildPdfTableRow("College Registration Number", d.regNumber.isNotEmpty ? d.regNumber : "N/A"),
        _buildPdfTableRow("Course", d.course.isNotEmpty ? d.course : "N/A"),
        _buildPdfTableRow("Branch / Specialisation / Honours", d.branch.isNotEmpty ? d.branch : "N/A"),
        _buildPdfTableRow("Building", d.building),
        _buildPdfTableRow("Room / Flat Number", d.roomNumber),
        _buildPdfTableRow("Bed Number", d.bedNumber.isNotEmpty ? d.bedNumber : "N/A"),
        _buildPdfTableRow("Guardian's Name", d.guardianName.isNotEmpty ? d.guardianName : "N/A"),
        _buildPdfTableRow("Guardian's Relationship to Tenant", d.guardianRelationship.isNotEmpty ? d.guardianRelationship : "Guardian"),
        _buildPdfTableRow("Guardian's Phone Number", d.guardianPhone.isNotEmpty ? d.guardianPhone : "N/A"),
        _buildPdfTableRow("Vegetarian / Non-Vegetarian Preference", d.dietaryPreference),
        _buildPdfTableRow("Home Town Address", d.hometownAddress.isNotEmpty ? d.hometownAddress : "On file in App Profile"),
      ],
    );
  }

  Widget _buildAnnexureITable(RentalAgreementData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          border: TableBorder.all(color: const Color(0xFF94A3B8), width: 0.8),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2.0),
          },
          children: [
            _buildPdfTableRow("Building / Room / Flat No.", "Building ${d.building}, Room/Flat ${d.roomNumber}${d.bedNumber.isNotEmpty ? ' (Bed ${d.bedNumber})' : ''}"),
            _buildPdfTableRow("Date of this Form", d.agreementDate),
          ],
        ),
        const SizedBox(height: 8),
        _buildParagraph(
          "Resident 1: ${d.studentFullName}  |  ID Proof: On file in App  |  Guardian Informed: Yes (${d.agreementDate})  |  Signature: Digitally Signed on App\n"
          "Resident 2: ___________________________  |  ID Proof: _________________  |  Guardian Informed: (Y/N)  |  Signature: _________________\n"
          "Acknowledged by Owner / Warden: Mr. Ajay Singh, Founder / Licensor  |  Signature and Date: Digitally Signed on App (${d.agreementDate})",
        ),
      ],
    );
  }

  // ==========================================================================
  // BOTTOM ACTION BAR
  // ==========================================================================
  Widget _buildBottomActionBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isGeneratingPdf ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Back / Edit Form",
                    maxLines: 1,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : _handleAcceptButtonTap,
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _isGeneratingPdf ? "Compiling Signed Agreement..." : "Accept & Sign Agreement",
                    maxLines: 1,
                    style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF94A3B8),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// EXACT VECTOR PAINTERS MATCHING THE ORIGINAL PDF STREAM
// -------------------------------------------------------------

/// Top Navy Shape: Color #1F3864
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

/// Bottom Navy Shape: Color #1F3864
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
