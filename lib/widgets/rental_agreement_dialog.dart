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
          "Rental & License Agreement (20 Pages)",
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

                        // Document Body with Minimal Inset Padding to Maximize Space
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

                              // Cover Table matching Page 1 of PDF
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

                              // Table of Contents matching Page 2 & 3 of PDF
                              _buildTableOfContents(),
                              const SizedBox(height: 32),

                              // Section 1: Parties and Recitals
                              _buildClauseTitle("1. Parties and Recitals", keyId: "section_1"),
                              _buildParagraph(
                                "This Rent/License Agreement (\"Agreement\") is made and entered into on this date ${d.agreementDate}, by and between:\n\n"
                                "OWNER / LICENSOR: Mr. Ajay Singh , hereinafter referred to as the \"Owner\" representing Lakshya Residency, located at Lakshay Residency and Flats, Tejasvi Greens, L2 L3, behind barcode cafe, near Manipal University Jaipur, Dahmi Kalan, Dahmi Khurd, Rajasthan 303007 (\"the Property\" or \"the Residency\"), of the ONE PART;\n\n"
                                "AND\n\n"
                                "TENANT / LICENSEE: ${d.studentFullName} ${d.guardianRelationship.toLowerCase().contains('mother') ? 'daughter/son of' : 'son/daughter of'} ${d.guardianName.isNotEmpty ? d.guardianName : 'Guardian on file'}, residing at ${d.hometownAddress.isNotEmpty ? d.hometownAddress : 'On file in App Profile'}, of the OTHER PART.\n\n"
                                "Where the context so requires, the Owner and the Tenant are hereinafter individually referred to as a \"Party\" and collectively as the \"Parties\".",
                              ),
                              const SizedBox(height: 12),
                              _buildSubClauseTitle("Recitals", keyId: "section_1_recitals"),
                              _buildParagraph(
                                "1.1 The Owner is the lawful owner and/or authorised managing operator of the residential unit(s) known as Lakshya Residency, and is competent to let out/license the said premises for residential and allied purposes.\n\n"
                                "1.2 The Tenant has approached the Owner seeking accommodation on a rental / leave-and-license basis at the Residency, either on a standalone rent basis or coupled with certain optional package-based facilities (meals, transport, laundry, cleaning, Wi-Fi, etc.), and the Owner has agreed to provide the same on the terms and conditions recorded in this Agreement.\n\n"
                                "1.3 This Agreement, together with its Schedules (A, B, C, D and E) and Annexure I, and any further Annexures executed in writing by both Parties, constitutes the entire understanding between the Parties in relation to the subject matter herein.\n\n"
                                "1.4 This Agreement, along with any rent receipts, notices, and renewal confirmations, shall also be maintained on the Lakshya Residency mobile application (\"the App\") for administrative and compliance purposes.\n\n"
                                "1.5 This Agreement, including Schedule A, is auto-generated using the information the Tenant submits at the time of onboarding on the App — including personal, academic, identity, room-allocation, guardian, and payment-plan details — and such App records shall be read together with, and form an integral part of, this Agreement. Upon completion of onboarding, the Tenant shall review and digitally sign this auto-generated Agreement on the App, which shall also bear the Owner's digital countersignature.",
                              ),
                              const SizedBox(height: 24),

                              // Section 2: Nature of Agreement
                              _buildClauseTitle("2. Nature of Agreement", keyId: "section_2"),
                              _buildParagraph(
                                "2.1 This Agreement is in the nature of a leave and license. It grants the Tenant a personal, revocable permission to use and occupy the Premises, together with any opted Package Facilities, for the Term, subject to the conditions herein. It does not create any tenancy, lease, sub-lease, or any right, title, estate, or interest whatsoever in favour of the Tenant in the Premises or the Residency, and no landlord-tenant relationship under any rent control legislation shall be deemed to arise between the Parties.\n\n"
                                "2.2 The Owner retains overall control, management, and right of entry over the Premises and Common Areas at all times, subject to Clause 14 (Inspection, Entry and Room Reallocation).",
                              ),
                              const SizedBox(height: 24),

                              // Section 3: Definitions and Interpretation
                              _buildClauseTitle("3. Definitions and Interpretation", keyId: "section_3"),
                              _buildParagraph(
                                "3.1 \"Premises\" means the specific flat/room (Building ${d.building}, Room/Flat ${d.roomNumber}, Bed ${d.bedNumber.isNotEmpty ? d.bedNumber : 'Allotted'}), along with fittings, fixtures, furniture and appliances provided therein, allotted to the Tenant at Lakshya Residency, as recorded in Schedule A.\n"
                                "3.2 \"Common Areas\" means all shared spaces within the Residency including but not limited to corridors, staircases, terrace, dining hall, common kitchen, lounge, and parking area, which are not for the exclusive use of any single Tenant.\n"
                                "3.3 \"Package Facilities\" means the optional services listed in Schedule C which the Tenant may avail in addition to the base rent, including meals, pick-up and drop transport, laundry, cleaning, and Wi-Fi/internet access.\n"
                                "3.4 \"App\" means the official Lakshya Residency mobile application through which onboarding, rent/fee payments, service requests, complaints, digital copies of this Agreement, notices, and communication between Owner and Tenant are facilitated.\n"
                                "3.5 \"Booking Amount\" means the amount paid by the Tenant to reserve a room/bed prior to move-in, as recorded in Schedule B, which is non-refundable in the manner described in Clause 5.\n"
                                "3.6 \"Security Deposit\" means the interest-free amount (₹ ${d.securityDeposit}) collected by the Owner from the Tenant as security against damage, unpaid dues, or breach of this Agreement, refundable subject to Clause 16.\n"
                                "3.7 \"Academic Session\" or \"Lock-in Period\" means the period for which the Tenant has subscribed, as determined by the Plan (${d.plan}) and the Rental Term selected by the Tenant at onboarding on the App, being ${d.lockInPeriod} (${d.commencementDate} to ${d.endingDate}), which is the minimum period for which the Tenant commits to reside at the Premises.\n"
                                "3.8 \"Minor\" means any individual who has not completed eighteen (18) years of age as on the date of the relevant event.\n"
                                "3.9 \"Authorised Occupant\" means only the Tenant named in Schedule A and any additional occupant(s) whose details have been disclosed to and expressly approved in writing (including via the App) by the Owner prior to occupation.\n"
                                "3.10 Words importing the singular include the plural and vice versa; words importing any gender include all genders; references to \"writing\" include communication through the App unless stated otherwise.",
                              ),
                              const SizedBox(height: 24),

                              // Section 4: Term, Lock-In Period and Renewal
                              _buildClauseTitle("4. Term, Lock-In Period and Renewal", keyId: "section_4"),
                              _buildParagraph(
                                "4.1 The Academic Session / Term of this Agreement shall be the Rental Term / Lock-in Period corresponding to the Plan and the duration selected by the Tenant at onboarding on the App, being ${d.commencementDate} to ${d.endingDate} (Plan: ${d.plan} ; Rental Term: ${d.rentalTerm} ), unless terminated earlier under Clause 17.\n\n"
                                "4.1A Plans and Rental Terms: The following Plans and Rental Terms are offered on the App, and the Plan and Rental Term selected by the Tenant at onboarding shall be recorded in Schedule B. (a) Rent Only Plan: Complete Year (July to May) – 11 months; 1 Semester Only (July to December) – 6 months; Summer Break (May to June) – 2 months; Winter Break (December) – 1 month. Rent for the entire Rental Term selected shall be payable irrespective of late joining. (b) Full Package Plan: the Lock-in Period shall be the academic calendar of MUJ, from the commencement of the odd semester to the last examination of the even semester (excluding summer and winter break).\n\n"
                                "4.2 The Tenant undertakes to remain in occupation of the Premises for the full Lock-in Period coinciding with the Academic Session. The Lock-in Period applies uniformly to Tenants on a rental-only basis and to Tenants who have opted for the Package Facilities.\n\n"
                                "4.3 If the Tenant does not take possession of the Premises within 7 days of the agreed move-in date, or takes possession but vacates within the first 15 consecutive days thereafter, the Owner may treat this as a no-show/early exit and terminate this Agreement forthwith, with the consequences set out in Clause 16.4 and Clause 18.\n\n"
                                "4.4 Renewal: This Agreement may be renewed for a further Academic Session on mutually agreed terms, recorded in writing (including digitally through the App) at least 30 days prior to expiry. In the absence of a written/App-based renewal, the Tenant shall vacate the Premises on or before the last day of the Term.\n\n"
                                "4.5 Continued occupation beyond the Term without a signed renewal shall not be construed as an automatic extension, and the Owner may charge holding-over compensation at 10% above the last applicable rent for each day of unauthorised continued occupation, in addition to other remedies available in law.\n\n"
                                "4.6 Automatic Termination by Efflux of Time: Unless renewed under Clause 4.4, this Agreement shall stand automatically terminated upon expiry of the Academic Session/Term. All outstanding dues as on such date shall become immediately payable and shall be adjusted against the Security Deposit in accordance with Clause 16.",
                              ),
                              const SizedBox(height: 24),

                              // Section 5: Booking, Rent, Deposits and Payment Terms
                              _buildClauseTitle("5. Booking, Rent, Deposits and Payment Terms", keyId: "section_5"),
                              _buildParagraph(
                                "5.1 Booking Amount: To reserve a room/bed, the Tenant shall pay the Booking Amount specified in Schedule B. The Booking Amount is strictly non-refundable once paid, including where the Tenant subsequently withdraws or cancels the booking prior to move-in, save where the Owner is unable to provide the booked accommodation at all.\n\n"
                                "5.2 Advance Payment Before Move-In: A prospective Tenant wishing to move in must inform the Owner/App in advance (at least 7 days ahead) and shall pay the full quoted joining amount — comprising the Booking Amount, Security Deposit, and/or the first applicable installment, as the case may be — upfront and in advance of being granted possession or occupation of the Premises.\n\n"
                                "5.3 Monthly Rent: For Tenants on a rental-only basis, and as a base component for Package Tenants, Rent shall be ₹ ${d.monthlyRent} as specified in Schedule B, exclusive of any Package Facilities charged separately under Schedule C.\n\n"
                                "5.4 Payment Plan — Rental-Only Tenants: A Tenant availing accommodation on a purely rental basis shall be billed for the entire Academic Session. At onboarding, the Tenant shall elect, on the App, either to (a) pay Rent on a monthly basis, or (b) pay the full session's Rent upfront in installments of 3 (three), 4 (four), or such other number of installments as the Tenant chooses. The exact installment amounts and due dates shall be fixed on the App at the time this election is made and recorded in Schedule B.\n\n"
                                "5.5 Payment Plan — Package Tenants: A Tenant who opts for the complete package (Rent plus Package Facilities) shall also pay in installments. The number of installments and the corresponding due dates shall likewise be decided at onboarding, on the App, and recorded in Schedule B.\n\n"
                                "5.6 Default: If any installment or monthly Rent is not paid by its due date, the Tenant shall be treated as being \"in default\" and the late payment charge specified in Schedule B shall apply for each day of delay. Persistent default is additionally governed by Clause 17.3 (termination for non-payment).\n\n"
                                "5.7 Security Deposit: A refundable, interest-free Security Deposit of ₹ ${d.securityDeposit} as specified in Schedule B shall be paid by the Tenant prior to handover of possession. The Security Deposit shall not be adjusted against Rent during the subsistence of this Agreement except with the Owner's prior written consent, and is subject to forfeiture under Clause 5.8 and Clause 16.4.\n\n"
                                "5.8 Non-Refundability on Early Exit: If the Tenant leaves, discontinues occupation, or withdraws from this Agreement before completing the full Lock-in Period / Academic Session referred to in Clause 4, both the Security Deposit and the Booking Amount shall stand fully and absolutely forfeited and shall not be refunded under any circumstance, and outstanding Rent/Package charges for the remainder of the Academic Session shall remain payable. This applies equally whether the early departure is on account of the Tenant's personal choice, academic withdrawal, disciplinary action, or any other reason not attributable to the Owner's default.\n\n"
                                "5.9 Late Payment Charge: Beyond a grace period of 3 (three) days from the due date, a late payment charge (as specified in Schedule B, ₹ 100 per day) shall accrue for every day of delay, without prejudice to the Owner's right to treat persistent default as a material breach under Clause 17.\n\n"
                                "5.10 Payments Only Through the App — No Other Channel Accepted: ALL payments to the Owner (Booking Amount, Security Deposit, Rent, installments, Package charges, fines, or any other dues) shall be made ONLY through the payment details listed on the App — namely the bank account number and UPI ID displayed within the App. The Owner does NOT accept, authorise, or acknowledge any payment made through any other bank account, UPI ID, cash collection, or any individual or agent, however described. The Tenant and their parent/guardian must never trust or make payment to any person claiming to represent Lakshya Residency outside the App, and the Owner shall bear no responsibility whatsoever for payments made to any unauthorised or fraudulent party.\n\n"
                                "5.11 KYC and Verification: The Tenant shall submit, through the App at onboarding, valid identity documents (a Government-issued photo ID and College ID, as recorded in Schedule A) and a recent photograph, and shall cooperate with any police verification, tenant registration, or similar formality required under applicable local law.\n\n"
                                "5.12 All applicable taxes, government levies, or statutory charges arising in relation to the Rent or Package Facilities shall be borne as per applicable law and may be passed on to the Tenant with prior written notice.\n\n"
                                "5.13 Refund of Security Deposit (where applicable, i.e., where the Tenant has completed the Lock-in Period): Subject to Clause 16, the Owner shall refund the balance Security Deposit within the timeline specified in Schedule B, after lawful deductions.\n\n""5.14 Summer and Winter Break Charges: The Lock-in Period excludes the summer and winter breaks. Where the Tenant retains the Premises during the summer break or the winter break, such break period may be charged additionally on the basis of the monthly Rent applicable to the Tenant, payable through the App. This additional charge shall not apply to a Tenant who has subscribed exclusively for the Summer Break or the Winter Break Rental Term.",
                              ),
                              const SizedBox(height: 12),

                              // Exact Red Payment Fraud Warning Box from PDF
                              _buildPdfWarningBox(
                                title: "PAYMENT FRAUD WARNING",
                                text: "Lakshya Residency accepts payment ONLY through the bank account and UPI ID displayed on the official App. Do not pay cash, or transfer money, to anyone who contacts you claiming to be from Lakshya Residency outside the App. If in doubt, verify directly with the Owner through the App before making any payment.",
                              ),
                              const SizedBox(height: 24),

                              // Section 6: Package-Based Facilities
                              _buildClauseTitle("6. Package-Based Facilities (Optional Value-Added Services)", keyId: "section_6"),
                              _buildParagraph(
                                "Lakshya Residency offers, in addition to standalone room rental, bundled package plans comprising the facilities listed below. The Tenant may opt for none, some, or all of these facilities, as recorded in Schedule C. Charges for opted facilities are payable along with the Rent through the App, as per the Payment Plan chosen under Clause 5.5.",
                              ),
                              const SizedBox(height: 12),
                              _buildPackageFacilitiesTable(d),
                              const SizedBox(height: 14),

                              _buildSubClauseTitle("6.A Meals", keyId: "section_6_a"),
                              _buildParagraph(
                                "6.1 Where opted, meal service shall comprise up to three (3) meals a day (breakfast, lunch, and dinner) served at fixed timings communicated by the Residency management/App. Menu, timing, and portion policies are subject to reasonable modification by the Owner with advance notice on the App.\n\n"
                                "6.2 The Tenant shall inform the Owner/App of any food allergies, medical dietary restrictions, and their vegetarian/non-vegetarian preference (as recorded in Schedule A) in advance. The Owner is not liable for reactions arising from undisclosed allergies.\n\n"
                                "6.3 Wastage of food, misuse of the mess/dining facility (including removing common utensils, cooking unauthorised items in the common kitchen, or misusing the facility for commercial resale of food) is strictly prohibited and may result in withdrawal of the meal package without refund for the withdrawn period.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("6.B Pick-up and Drop to College/Institute", keyId: "section_6_b"),
                              _buildParagraph(
                                "6.4 Where opted, transport service shall be provided between the Residency and the Tenant's specified college/institute at fixed timings and routes as communicated via the App. The Tenant must be ready at the designated pick-up point at the scheduled time; the vehicle shall not be obligated to wait beyond a reasonable grace period.\n\n"
                                "6.5 This facility is meant solely for the named Tenant's commute to and from their registered institution and shall not be used to carry unauthorised persons, goods for commercial purposes, or personal errands outside the agreed route, without the Owner's prior written approval and applicable additional charge.\n\n"
                                "6.6 The Tenant shall conduct themselves safely during transit and comply with reasonable instructions of the driver/attendant.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("6.C Laundry and Cleaning", keyId: "section_6_c"),
                              _buildParagraph(
                                "6.7 Where opted, laundry service shall be provided at the frequency specified in Schedule C. The Owner/service provider shall exercise reasonable care but shall not be liable for ordinary wear, shrinkage, or colour-run inherent to fabric type, nor for items left unclaimed beyond thirty (30) days. The Tenant is advised to verify items at the time of delivery; complaints raised thereafter may not be entertained.\n\n"
                                "6.8 Where opted, cleaning service for the room/common areas shall be provided at the frequency specified in Schedule C, at reasonable hours communicated in advance.",
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
                                "6.11 Package Facilities are optional and separately charged. They may be added or opted out of only with at least 30 days' advance written notice (through the App), and refunds/adjustments, if any, shall be on a pro-rata basis at the Owner's discretion. The Owner reserves the right to require full upfront payment for certain Package Facilities as a condition of opting in.\n\n"
                                "6.12 Third-Party Facilitation: For services rendered through third-party vendors (including laundry, transport, and the internet service provider), the Owner acts only as a facilitator/aggregator and is not itself the service provider. The Owner shall not be liable for deficiency, delay, damage, or loss caused by such a third-party vendor; the Tenant's remedy, if any, in such cases lies against the vendor directly.\n\n"
                                "6.13 Complaint Window: Any complaint regarding a Package Facility must be raised via the App/email within 48 hours of the relevant service being rendered; complaints raised thereafter may not be entertained. If a timely complaint is not resolved within 15 days, the Tenant shall escalate it to the Owner/warden in writing.\n\n"
                                "6.14 Misuse, abuse, or fraudulent claims relating to any Package Facility (e.g., false damage claims, unauthorised sharing of the facility with non-residents, tampering with service logs on the App) shall be treated as a material breach of this Agreement under Clause 10 and Clause 17.",
                              ),
                              const SizedBox(height: 24),

                              // Section 7: Utilities and Common Area Charges
                              _buildClauseTitle("7. Utilities and Common Area Charges", keyId: "section_7"),
                              _buildParagraph(
                                "7.1 Electricity shall be charged at the rate of ₹12 (Rupees Twelve only) per unit consumed, as per meter/sub-meter reading, billed monthly through the App. In a shared-occupancy room, electricity charges shall be divided equally among all occupants of that room, unless otherwise agreed in writing.\n\n"
                                "7.2 Water and common maintenance charges shall be included in the Rent as specified in Schedule B.\n\n"
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
                                "9.1 Pay Rent, installments, and all Package Facility charges on time as per Clause 5 and Schedule B/C.\n\n"
                                "9.2 Maintain the Premises, fittings, fixtures, and furnishings provided (as listed in Schedule A/D) in good and tenantable condition, normal wear and tear excepted.\n\n"
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
                                "10.3.2 The Tenant shall not engage, permit, or facilitate any activity on the Premises or through the App that endangers the safety or welfare of a Minor, or that is unlawful in relation to a Minor under applicable Indian law (including the POCSO Act, 2012, the Juvenile Justice Act, 2015, and the Indian Penal Code / Bharatiya Nyaya Sanhita).\n\n"
                                "10.3.3 Any suspected or confirmed violation of this Clause 10.3 shall be reported by the Owner immediately to the local police and/or the relevant Child Welfare Committee/authority, and the Owner shall have the right to terminate this Agreement with immediate effect, over and above pursuing all available legal remedies.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.4 Commercial, Business or Unlawful Trade Activity", keyId: "section_10_4"),
                              _buildParagraph(
                                "10.4.1 The Premises are let/licensed strictly for residential use. The Tenant shall not carry out, from the Premises, any business, trade, profession, commercial venture, manufacturing, storage of trade goods, or any other for-profit commercial activity of any nature, without the Owner's prior written consent.\n\n"
                                "10.4.2 The Tenant shall not use the Premises for any unlawful purpose, including gambling/betting operations, money-lending, or counterfeit goods.\n\n"
                                "10.4.3 Violation of this Clause 10.4 shall entitle the Owner to immediately terminate this Agreement and seek compensation for any loss, statutory penalty, or reputational harm suffered, in addition to reporting the matter to the appropriate municipal, tax, or law-enforcement authority where warranted.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.5 Unauthorised Occupants, Subletting and Relocation of Third Parties", keyId: "section_10_5"),
                              _buildParagraph(
                                "10.5.1 The Tenant shall not sublet, assign, transfer, or share occupation of the Premises, in whole or in part, with any third party without the Owner's prior written consent. Any such unauthorised assignment or subletting shall be void, and the Owner may terminate this Agreement and commence eviction without further notice.\n\n"
                                "10.5.2 The Tenant shall not permit any person to relocate into, stay at, or use the Premises as their residence — continuously or intermittently — for a prolonged period without first disclosing such person's identity and obtaining the Owner's prior written approval through the App or in writing.\n\n"
                                "10.5.3 Short-term guests may be permitted strictly in accordance with the visitor policy at Clause 11, and the Tenant shall remain fully responsible for the conduct, safety, and any dues/damage caused by such guests.\n\n"
                                "10.5.4 Any unauthorised or undisclosed long-term occupant discovered at the Premises entitles the Owner to (a) charge additional occupancy fees retroactively, (b) direct immediate removal of such person, and/or (c) terminate this Agreement under Clause 17, without prejudice to any other legal remedy, including police intervention where the occupant refuses to vacate.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.6 Mobile Application — Acceptable Use Policy", keyId: "section_10_6"),
                              _buildParagraph(
                                "10.6.1 The Tenant shall use the App solely for legitimate purposes connected with their tenancy — onboarding, rent/fee payment, service requests, complaints, communication with the Owner/management, and viewing this Agreement and related documents.\n\n"
                                "10.6.2 The Tenant shall not: (a) share App login credentials with any unauthorised person; (b) attempt to hack, reverse-engineer, introduce malware into, or otherwise compromise the App or its backend systems; (c) upload or transmit obscene, defamatory, harassing, threatening, or unlawful content; (d) use the App to harass or defraud the Owner or staff; or (e) misuse payment gateways.\n\n"
                                "10.6.3 The Owner reserves the right to suspend or terminate the Tenant's App account for any misuse under Clause 10.6.2.\n\n"
                                "10.6.4 All communications, notices, payment confirmations, and complaint records exchanged via the App shall be admissible between the Parties as evidence of communication.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.7 General Nuisance, Safety and Miscellaneous Prohibitions", keyId: "section_10_7"),
                              _buildParagraph(
                                "• Storing or handling flammable, explosive, hazardous, or illegal materials/weapons within the Premises.\n"
                                "• Tampering with fire-safety equipment, CCTV cameras, electrical wiring, or common building infrastructure.\n"
                                "• Causing disturbance during designated quiet hours specified in the house rules.\n"
                                "• Bringing pets into the Residency without the Owner's prior written consent, where house rules restrict pets.\n"
                                "• Any act of harassment, ragging, discrimination, or violence against co-tenants, staff, or visitors.\n"
                                "• Circulating false, defamatory, or malicious information about the Owner, Residency, or its staff/tenants on any platform, including the App or social media.\n"
                                "• Any other act that is unlawful under the laws of India or that brings disrepute to Lakshya Residency.",
                              ),
                              const SizedBox(height: 12),

                              _buildSubClauseTitle("10.8 Fights and Disputes Among Residents", keyId: "section_10_8"),
                              _buildParagraph(
                                "10.8.1 The Tenant shall not engage in any physical altercation, dispute, or fight with other residents, staff, vendors, or members of the public in or around the Residency. The Owner shall not be responsible for any loss, injury, or damage arising from such conduct.\n\n"
                                "10.8.2 Where a Tenant is found involved in such conduct, the Owner may forfeit the Security Deposit and Booking Amount, cancel the Tenant's admission, and require immediate vacation of the Premises, without prejudice to any other remedy.",
                              ),
                              const SizedBox(height: 24),

                              // Section 11 to 24
                              _buildClauseTitle("11. House Rules — Curfew, Outings and Visitor Policy", keyId: "section_11"),
                              _buildParagraph(
                                "11.1 Outing Hours: The Tenant may move within the immediate vicinity of the Residency until designated evening hours. Venturing outside the city/campus area requires prior intimation to the Tenant's parent/guardian and to the Owner/warden.\n\n"
                                "11.2 Door-Closing Time: The main gate/door of the Residency shall close at 10:00 PM. The Tenant shall return to the Residency before this time.\n\n"
                                "11.3 Late Entry: A Tenant seeking to return after the closing time for a genuine reason must obtain prior permission from their parent/guardian and the warden/Owner.\n\n"
                                "11.4 Night-Out / Overnight Absence: The Tenant must submit a written/App-based night-out application, noting the time of departure in the Residency's register, and obtain the Owner's/warden's approval — ordinarily conditional on parental consent.\n\n"
                                "11.5 Overnight Guests: Overnight stay of any outside friend or visitor in the Tenant's room is not permitted, save as provided under Clause 12 (Co-Habitation) or with the Owner's express prior written consent. A visitor of a different gender than the room's registered occupants shall not stay overnight in the room, and may only be received during permitted visiting hours in designated common areas.\n\n"
                                "11.6 If the Tenant does not return by the curfew time without prior permission and cannot be reached, the Owner may inform the Tenant's parent/guardian.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("12. Co-Habitation / Live-in Arrangements", keyId: "section_12"),
                              _buildParagraph(
                                "12.1 Where an adult Tenant (18 years of age or above) wishes to reside at the Premises together with a partner in a live-in / co-habiting arrangement, the Tenant shall, prior to admission or prior to commencing such an arrangement, inform their parent(s)/legal guardian(s) of the same.\n\n"
                                "12.2 Both cohabiting residents shall execute and submit to the Owner a signed Co-Habitation Consent Form, in the format at Annexure I to this Agreement.\n\n"
                                "12.3 The Owner permits such an arrangement purely as an accommodation facilitator and assumes no responsibility for the personal, emotional, financial, or legal consequences of the relationship.\n\n"
                                "12.4 This Clause applies only where both cohabiting residents are adults.\n\n"
                                "12.5 Nothing in this Clause obligates the Owner to allot a shared room to cohabiting residents; room/bed allocation remains subject to availability.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("13. Owner's Rights and Remedies on Breach", keyId: "section_13"),
                              _buildParagraph(
                                "13.1 Right of Admission: The Owner reserves the right of admission to the Residency.\n\n"
                                "13.2 Without prejudice to any other right or remedy, upon the occurrence of any breach, the Owner shall be entitled to: issue warnings, suspend facilities/App access, forfeit deposits, terminate the agreement, lodge police complaints, and pursue legal recovery.\n\n"
                                "13.3 The Owner's exercise of, or delay in exercising, any right under this Clause shall not be construed as a waiver.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("14. Inspection, Entry and Room Reallocation", keyId: "section_14"),
                              _buildParagraph(
                                "14.1 The Owner or its authorised representative may enter the Premises for inspection, maintenance, or verification during reasonable hours upon giving prior notice, except in emergencies where entry may be made without prior notice.\n\n"
                                "14.2 The Tenant shall not unreasonably deny access for inspection.\n\n"
                                "14.3 The Owner may carry out necessary repair and maintenance work in the Premises.\n\n"
                                "14.4 Room / Building Reallocation: The Owner reserves the right, for operational reasons, to shift/transfer the Tenant to another room/bed on similar terms.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("15. Maintenance, Repairs and Damage Liability", keyId: "section_15"),
                              _buildParagraph(
                                "15.1 For Tenants staying on a purely rental basis, the first month's routine maintenance is attended to at no additional cost. From the second month onward, minor repairs shall be arranged and borne by the Tenant, unless covered under Package Facilities.\n\n"
                                "15.2 All repair/maintenance requests shall be logged through the App.\n\n"
                                "15.3 The inventory of furniture, fixtures, and appliances provided is recorded in Schedule A/D. The Tenant shall verify this inventory at move-in and is liable for any shortfall or damage at vacating.\n\n"
                                "15.4 Summer Break Maintenance: The Owner may undertake block-level or Residency-wide maintenance during vacations. The Tenant shall cooperate with access.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("16. Security Deposit and Advance Charges — Deductions and Refund", keyId: "section_16"),
                              _buildParagraph(
                                "16.1 The Owner may deduct from the Security Deposit unpaid rent, damages, unpaid utilities, or penalties.\n\n"
                                "16.2 Where the Tenant has completed the full Lock-in Period and dues stand settled, the balance Security Deposit shall be refunded within 30 days of vacating.\n\n"
                                "16.3 Non-Refund on Early Exit: Notwithstanding Clause 16.1 and 16.2, if the Tenant vacates before completing the 11-month Lock-in Period, the entire Security Deposit and Booking Amount stand absolutely forfeited.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("17. Termination of Agreement", keyId: "section_17"),
                              _buildParagraph(
                                "17.1 Either Party may terminate by giving not less than 30 days' prior written notice, save as provided below.\n\n"
                                "17.2 Immediate termination without notice applies in case of drugs, offences involving minors, violence, or unlawful activity.\n\n"
                                "17.3 Non-Payment: Non-payment beyond 7 days entitles the Owner to terminate forthwith.\n\n"
                                "17.4 No-show / early vacation within the initial days entitles immediate termination and forfeiture.\n\n"
                                "17.5 Upon termination, the Tenant shall peacefully vacate and return all keys.\n\n"
                                "17.6 Termination terminates all Package Facilities.\n\n"
                                "17.7 This Agreement also terminates by efflux of time at the end of the 11-month Term.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("18. Consequences of Termination for Cause", keyId: "section_18"),
                              _buildParagraph(
                                "18.1 Termination for cause entails forfeiture of deposits, immediate vacation, bar on App access, and recovery of remaining session charges.\n\n"
                                "18.2 Any excess damages beyond deposit remain immediately recoverable.\n\n"
                                "18.3 The Owner may re-license the vacated premises immediately.\n\n"
                                "18.4 Termination does not absolve the Tenant of liabilities accrued prior.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("19. Indemnity and Limitation of Liability", keyId: "section_19"),
                              _buildParagraph(
                                "19.1 The Tenant shall indemnify the Owner against all third-party losses or penalties caused by the Tenant.\n\n"
                                "19.2 Limitation of Liability: Owner's liability is strictly limited as provided by law.\n\n"
                                "19.3 The Owner is not liable for loss or theft of personal belongings from the Premises. Residents must keep their rooms locked.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("20. Health, Safety, Emergency and Personal Well-Being", keyId: "section_20"),
                              _buildParagraph(
                                "20.1 The Tenant shall disclose relevant medical conditions on the App.\n\n"
                                "20.2 The Tenant shall comply with fire-safety and emergency protocols.\n\n"
                                "20.3 In emergencies, staff may contact medical services and guardians.\n\n"
                                "20.4 Self-Harm & Personal Safety: The Owner is an accommodation provider and not a mental-health clinic; no clinical duty of care is assumed.\n\n"
                                "20.5 Support helpline resources are made available on the App.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("21. Force Majeure", keyId: "section_21"),
                              _buildParagraph(
                                "21.1 Neither Party is liable for failure caused by natural disaster, pandemic, government order, or civil unrest beyond reasonable control.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("22. Confidentiality, Data Privacy and Promotional Use", keyId: "section_22"),
                              _buildParagraph(
                                "22.1 Personal data is used solely for tenancy administration and legal compliance.\n\n"
                                "22.2 Data may be shared with law enforcement where legally required.\n\n"
                                "22.3 Technical measures protect data under applicable law.\n\n"
                                "22.4 Promotional photography may be opted out of by written intimation.\n\n"
                                "22.5 Commercial terms of this Agreement remain strictly confidential.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("23. Dispute Resolution and Governing Law", keyId: "section_23"),
                              _buildParagraph(
                                "23.1 Parties shall first attempt amicable resolution.\n\n"
                                "23.2 Failing resolution, disputes shall be subject to arbitration/exclusive jurisdiction of courts at Jaipur, Rajasthan.\n\n"
                                "23.3 Governed by the laws of India.\n\n"
                                "23.4 The Owner may approach criminal courts directly for offences under Clause 10.",
                              ),
                              const SizedBox(height: 24),

                              _buildClauseTitle("24. General / Miscellaneous Provisions", keyId: "section_24"),
                              _buildParagraph(
                                "24.1 Notices sent via App or email constitute valid service.\n\n"
                                "24.2 Amendments must be in writing.\n\n"
                                "24.3 Severability applies.\n\n"
                                "24.4 Entire Agreement constitutes complete understanding.\n\n"
                                "24.5 Tenant cannot assign without consent.\n\n"
                                "24.6 Owner may assign upon written notice.\n\n"
                                "24.7 Counterparts and digital execution through App are deemed original and binding under the Information Technology Act, 2000.\n\n"
                                "24.8 Stamp duty and registration charges shall be borne as per applicable State law.",
                              ),
                              const SizedBox(height: 32),

                              // SCHEDULES
                              const Divider(thickness: 1.5, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 20),
                              _buildScheduleHeading("SCHEDULE A — Student Onboarding & Property Details", keyId: "schedule_a"),
                              _buildParagraph("The fields below are populated automatically from the Tenant's onboarding profile on the App:"),
                              const SizedBox(height: 10),
                              _buildScheduleATable(d),
                              const SizedBox(height: 28),

                              _buildScheduleHeading("SCHEDULE B — Rent, Deposit and Payment Details", keyId: "schedule_b"),
                              _buildScheduleBTable(d),
                              const SizedBox(height: 28),

                              _buildScheduleHeading("SCHEDULE C — Package-Based Facilities Opted", keyId: "schedule_c"),
                              _buildScheduleCTable(d),
                              const SizedBox(height: 28),

                              _buildScheduleHeading("SCHEDULE D — Furniture, Inventory and House Rules Acknowledgement", keyId: "schedule_d"),
                              _buildParagraph(
                                "The furniture, fixtures, and appliances provided in the Premises at the time of onboarding/move-in are as listed in the Tenant's onboarding record on the App. Both Parties confirm this inventory and its condition through the App at check-in, and any discrepancy must be flagged within 48 hours of move-in.\n\n"
                                "Verified Allotted Inventory Checklist (${d.inventoryItems.length} items):\n"
                                "${d.inventoryItems.isNotEmpty ? d.inventoryItems.map((e) => '• $e').join('   |   ') : 'Standard room inventory verified at check-in.'}\n\n"
                                "The Tenant confirms having read and understood the Residency's house rules, including visiting hours, quiet hours, gate-closing time, and guest policy, and agrees to be bound by the same.",
                              ),
                              const SizedBox(height: 28),

                              _buildScheduleHeading("SCHEDULE E — Owner's Notes", keyId: "schedule_e"),
                              _buildParagraph(
                                "Any additional understanding reached between the Owner and the Tenant at the time of onboarding (special arrangements, waivers, or remarks) shall be recorded here by the Owner and remain visible to both Parties on the App:",
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF94A3B8), width: 0.8),
                                  color: Colors.white,
                                ),
                                child: Text(
                                  d.notes.isNotEmpty
                                      ? d.notes.map((n) => "• $n").join("\n")
                                      : "• Standard accommodation guidelines apply.\n• Emergency numbers: +91 97840 70543.",
                                  style: GoogleFonts.roboto(fontSize: 11.5, color: const Color(0xFF0F172A)),
                                ),
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
                                "D.1 I confirm that I am legally permitted and eligible to execute this Agreement, either personally or through my parent/legal guardian, and that the particulars fetched from my onboarding profile on the App (Schedule A) are true and accurate to the best of my knowledge; I have not wilfully suppressed any material fact, and I understand that any misrepresentation may render me ineligible for accommodation.\n\n"
                                "D.2 I undertake to submit valid KYC documents (Government ID and College ID, as recorded in Schedule A) to the Owner through the App on or before moving into the Premises, and to provide full cooperation and documentation for any police verification, tenant registration, or similar process required by the Owner or applicable law.\n\n"
                                "D.3 I undertake not to disclose the commercial terms of this Agreement, including the information at Schedule A, B, and C, to any third party other than my parent/guardian or as required by law, in accordance with Clause 22.5.\n\n"
                                "D.4 I have read and understood this Agreement in full, including Clause 10 (Prohibited Activities and Strict Conduct Rules) and Clause 13 (Owner's Rights and Remedies). I understand and agree that engaging in property damage, drug/narcotic-related activity, any activity endangering a Minor, unauthorised commercial/business use of the Premises, housing any unauthorised person for a prolonged period without prior disclosure and consent, exceeding the occupancy limits at Clause 8.4, or misuse of the App, shall constitute a serious breach of this Agreement.\n\n"
                                "D.5 I understand that the Owner has the full right, without limitation, to terminate this Agreement, forfeit the Security Deposit and Booking Amount to the extent described in Clauses 5.8, 16.3 and 18, evict me in accordance with law, lodge a police complaint, and/or escalate the matter to any higher civil, criminal, or regulatory authority, and I accept full legal responsibility for any consequence arising from such breach.\n\n"
                                "D.6 I confirm that I have read and understood Clause 20.4 (Self-Harm and Personal Safety) and Clause 19.2 (Limitation of Liability) of this Agreement.",
                              ),
                              const SizedBox(height: 14),

                              // Important Notice matching Page 28 of PDF
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
                              // EXACT PAGE 29 SIGNATURES SECTION
                              // ==========================================
                              // Owner Signature Block
                              Text(
                                "Signature of Owner / Authorised Representative:",
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Owner signature placed directly on the document line
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
                              // Date for owner intentionally omitted as instructed!

                              const SizedBox(height: 28),

                              // Student Signature Block
                              Text(
                                "Signature of Tenant:",
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Interactive Signature Pad placed directly here
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
                              const SizedBox(height: 4),
                              Text(
                                "Date: ${d.agreementDate}",
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Parent / Guardian info
                              Text(
                                "(If Tenant is a Minor) Signature of Parent / Legal Guardian, consenting to and countersigning this Agreement:",
                                style: GoogleFonts.roboto(fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Signature of Parent / Guardian: _________________________________________________",
                                style: GoogleFonts.roboto(fontSize: 11.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Name: ${d.guardianName.isNotEmpty ? d.guardianName : '_________________________________________________'}",
                                style: GoogleFonts.roboto(fontSize: 11.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Relationship to Tenant: ${d.guardianRelationship.isNotEmpty ? d.guardianRelationship : '_________________________________________________'}",
                                style: GoogleFonts.roboto(fontSize: 11.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Contact Number: ${d.guardianPhone.isNotEmpty ? d.guardianPhone : '_________________________________________________'}",
                                style: GoogleFonts.roboto(fontSize: 11.5),
                              ),

                              const SizedBox(height: 24),

                              // Witnesses
                              Container(
                                key: _getKey("witnesses"),
                                child: Text(
                                  "Witnesses",
                                  style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Witness 1 — Name & Signature: _________________________________________________",
                                style: GoogleFonts.roboto(fontSize: 11.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Witness 1 — Address: _________________________________________________",
                                style: GoogleFonts.roboto(fontSize: 11.5),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Witness 2 — Name & Signature: _________________________________________________",
                                style: GoogleFonts.roboto(fontSize: 11.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Witness 2 — Address: _________________________________________________",
                                style: GoogleFonts.roboto(fontSize: 11.5),
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

                        // EXACT FOOTER UI FROM PDF (Page 29)
                        _buildExactPdfFooter(29),
                        const SizedBox(height: 16),

                        // Clean Agreement Confirmation Checkbox
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
  // ==========================================================================
  // EXACT HEADER UI MATCHING ORIGINAL PDF
  // ==========================================================================
  Widget _buildExactPdfHeader(String dateStr) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        // In original PDF: Page width = 595.32 pt. Header height down to GST line = 138 pt.
        final double h = w * (138.0 / 595.32);
        final double scale = w / 595.32;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Top Navy Blue Polygon Bar (#1F3864) with exact cubic bezier swoop
              Positioned.fill(
                child: CustomPaint(
                  painter: _TopHeaderNavyPainter(),
                ),
              ),

              // 2. Official Lakshya Logo (Under the curve on the left)
              // PDF bounds: x = 60.8..143.0, y_from_top = 56.3..106.7
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

              // 3. Founder Details (Right aligned, left of vertical magenta bar)
              // PDF bounds: x = 372..523.4, y_from_top = 60..108
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

              // 4. Vertical Magenta Bar on the right of Founder text
              // PDF bounds: x = 525.9..529.3, y_from_top = 59.9..107.6
              Positioned(
                right: (595.32 - 529.3) * scale,
                top: 56.0 * scale,
                width: 3.2 * scale,
                height: 48.0 * scale,
                child: Container(color: const Color(0xFFFF009D)),
              ),

              // 5. Horizontal Magenta Line across page
              // PDF bounds: y_from_top = 112.5. Left segment thin (1.5pt), right segment thick bar (3.5pt) from x=348
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
              // PDF bounds: y_from_top = 122.4, Date on left at x=72, GST on right at x=523.4
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
              // 1. Navy bottom shape (#1F3864) with exact cubic bezier swoop
              Positioned.fill(
                child: CustomPaint(
                  painter: _BottomFooterNavyPainter(),
                ),
              ),

              // 2. Page number text right above curve
              // PDF bounds: x = 496..540, y_bottom = 35.2..37.0
              Positioned(
                right: (595.32 - 523.4) * scale,
                bottom: 34.0 * scale,
                child: Text(
                  "Page $pageNum of 20",
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
        _buildPdfTableRow("Agreement Date", "${d.agreementDate}  (auto-filled from App)"),
        _buildPdfTableRow("Owner / Licensor", "Mr. Ajay Singh, Lakshya Residency"),
        _buildPdfTableRow("Tenant / Licensee (Student)", d.studentFullName),
        _buildPdfTableRow("Property Address", "Lakshya Residency, Building ${d.building}, Room/Flat No. ${d.roomNumber}${d.bedNumber.isNotEmpty ? ' (Bed ${d.bedNumber})' : ''}"),
        _buildPdfTableRow("Tenant's Hometown Address", d.hometownAddress.isNotEmpty ? d.hometownAddress : "On file in student profile"),
        _buildPdfTableRow("Academic Session / Lock-In", "Plan: ${d.plan} | Rental Term / Lock-in: ${d.lockInPeriod}"),
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
  // TABLE OF CONTENTS (PAGE 2 & 3)
  // ==========================================================================
  Widget _buildTableOfContents() {
    final items = [
      ("TABLE OF CONTENTS", "2", "toc", false),
      ("1. Parties and Recitals", "3", "section_1", false),
      ("   Recitals", "3", "section_1_recitals", true),
      ("2. Nature of Agreement", "3", "section_2", false),
      ("3. Definitions and Interpretation", "4", "section_3", false),
      ("4. Term, Lock-In Period and Renewal", "4", "section_4", false),
      ("5. Booking, Rent, Deposits and Payment Terms", "5", "section_5", false),
      ("6. Package-Based Facilities (Optional Value-Added Services)", "7", "section_6", false),
      ("   6.A Meals", "7", "section_6_a", true),
      ("   6.B Pick-up and Drop to College/Institute", "7", "section_6_b", true),
      ("   6.C Laundry and Cleaning", "8", "section_6_c", true),
      ("   6.D Wi-Fi / Internet Access", "8", "section_6_d", true),
      ("   6.E General Terms Applicable to All Package Facilities", "8", "section_6_e", true),
      ("7. Utilities and Common Area Charges", "8", "section_7", false),
      ("8. Permitted Use of Premises and Occupancy Limits", "9", "section_8", false),
      ("9. Tenant's General Obligations", "9", "section_9", false),
      ("10. Prohibited Activities and Strict Conduct Rules", "10", "section_10", false),
      ("   10.1 Damage to Property", "10", "section_10_1", true),
      ("   10.2 Drugs, Narcotics and Substance Abuse", "10", "section_10_2", true),
      ("   10.3 Activities Involving Minors", "10", "section_10_3", true),
      ("   10.4 Commercial, Business or Unlawful Trade Activity", "10", "section_10_4", true),
      ("   10.5 Unauthorised Occupants, Subletting and Relocation", "11", "section_10_5", true),
      ("   10.6 Mobile Application — Acceptable Use Policy", "11", "section_10_6", true),
      ("   10.7 General Nuisance, Safety and Miscellaneous Prohibitions", "11", "section_10_7", true),
      ("   10.8 Fights and Disputes Among Residents", "11", "section_10_8", true),
      ("11. House Rules — Curfew, Outings and Visitor Policy", "12", "section_11", false),
      ("12. Co-Habitation / Live-in Arrangements", "12", "section_12", false),
      ("13. Owner's Rights and Remedies on Breach", "13", "section_13", false),
      ("14. Inspection, Entry and Room Reallocation", "13", "section_14", false),
      ("15. Maintenance, Repairs and Damage Liability", "14", "section_15", false),
      ("16. Security Deposit and Advance Charges — Deductions and Refund", "14", "section_16", false),
      ("17. Termination of Agreement", "14", "section_17", false),
      ("18. Consequences of Termination for Cause", "15", "section_18", false),
      ("19. Indemnity and Limitation of Liability", "15", "section_19", false),
      ("20. Health, Safety, Emergency and Personal Well-Being", "15", "section_20", false),
      ("21. Force Majeure", "15", "section_21", false),
      ("22. Confidentiality, Data Privacy and Promotional Use", "16", "section_22", false),
      ("23. Dispute Resolution and Governing Law", "16", "section_23", false),
      ("24. General / Miscellaneous Provisions", "16", "section_24", false),
      ("SCHEDULE A — Student Onboarding & Property Details", "17", "schedule_a", false),
      ("SCHEDULE B — Rent, Deposit and Payment Details", "18", "schedule_b", false),
      ("SCHEDULE C — Package-Based Facilities Opted", "18", "schedule_c", false),
      ("SCHEDULE D — Furniture, Inventory and House Rules Acknowledgement", "19", "schedule_d", false),
      ("SCHEDULE E — Owner's Notes", "19", "schedule_e", false),
      ("ANNEXURE I — CO-HABITATION / LIVE-IN CONSENT FORM", "19", "annexure_1", false),
      ("TENANT'S DECLARATION & NOTICE", "20", "declaration", false),
      ("SIGNATURES & WITNESSES", "20", "signatures", false),
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
  // PAGE 9 PACKAGE FACILITIES TABLE
  // ==========================================================================
  Widget _buildPackageFacilitiesTable(RentalAgreementData d) {
    final isPkg = d.plan.toLowerCase().contains("package");
    return Table(
      border: TableBorder.all(color: const Color(0xFF94A3B8), width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(0.8),
        2: FlexColumnWidth(1.6),
        3: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF1F3864)),
          children: [
            _buildTh("Package Facility"),
            _buildTh("Included? (Y/N)"),
            _buildTh("Frequency / Details"),
            _buildTh("Additional Charge (if any)"),
          ],
        ),
        _buildPkgRow("Room / Flat Rent (Base)", "Y", "Monthly / As per Plan", "As per Schedule B"),
        _buildPkgRow("Meals (Breakfast, Lunch, Dinner)", isPkg ? "Y" : "N", "3 times daily / as opted", isPkg ? "Included in Package" : "Optional"),
        _buildPkgRow("Pick-up & Drop to College", "N", "Fixed timing routes", "Optional / On Request"),
        _buildPkgRow("Laundry Service", isPkg ? "Y" : "N", "times per week", isPkg ? "Included" : "Optional"),
        _buildPkgRow("Room / Common Area Cleaning", "Y", "times per week", "Included"),
        _buildPkgRow("Wi-Fi / Internet Access", "Y", "Shared bandwidth, FUP applies", "Included"),
      ],
    );
  }

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

  TableRow _buildPkgRow(String col1, String col2, String col3, String col4) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(col1, style: GoogleFonts.roboto(fontSize: 10.5)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(col2, style: GoogleFonts.roboto(fontSize: 10.5, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(col3, style: GoogleFonts.roboto(fontSize: 10.5)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(col4, style: GoogleFonts.roboto(fontSize: 10.5)),
        ),
      ],
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
        _buildPdfTableRow("College Registration Number", d.regNumber.isNotEmpty ? d.regNumber : "On file in App onboarding"),
        _buildPdfTableRow("Course", d.course),
        _buildPdfTableRow("Branch / Specialisation / Honours", d.branch),
        _buildPdfTableRow("Building", d.building),
        _buildPdfTableRow("Room / Flat Number", d.roomNumber),
        _buildPdfTableRow("Bed Number", d.bedNumber.isNotEmpty ? d.bedNumber : "Allotted"),
        _buildPdfTableRow("Flat Configuration (1/2/3 BHK)", d.flatConfig),
        _buildPdfTableRow("Guardian's Name", d.guardianName),
        _buildPdfTableRow("Guardian's Relationship to Tenant", d.guardianRelationship),
        _buildPdfTableRow("Guardian's Phone Number", d.guardianPhone),
        _buildPdfTableRow("Vegetarian / Non-Vegetarian Preference", d.dietaryPreference),
        _buildPdfTableRow("Property Name", "Lakshya Residency"),
        _buildPdfTableRow("Full Address", d.hometownAddress.isNotEmpty ? d.hometownAddress : "On file in App onboarding profile"),
        _buildPdfTableRow("Government ID Uploaded", d.govtIdUploaded ? "Yes (Verified on App)" : "Pending Upload"),
        _buildPdfTableRow("College ID Uploaded", d.collegeIdUploaded ? "Yes (Verified on App)" : "Pending Upload"),
        _buildPdfTableRow("Furnishing Status", "As recorded in the App onboarding inventory (see Schedule D)"),
      ],
    );
  }

  Widget _buildScheduleBTable(RentalAgreementData d) {
    String instSummary = "As scheduled on App (${d.installmentsCount} installments)";
    if (d.installments.isNotEmpty) {
      instSummary = d.installments.map((e) => "${e['title']}: ₹${e['amount']} (${e['dueDate']})").join("\n");
    }

    return Table(
      border: TableBorder.all(color: const Color(0xFF94A3B8), width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(1.4),
        1: FlexColumnWidth(2.2),
      },
      children: [
        _buildPdfTableRow("Booking Amount (Non-Refundable)", "₹ 0 / Included in Deposit"),
        _buildPdfTableRow("Monthly Rent", "₹ ${d.monthlyRent}"),
        _buildPdfTableRow("Security Deposit (Non-refundable on early exit)", "₹ ${d.securityDeposit}"),
        _buildPdfTableRow("Basis of Stay", "Plan: ${d.plan} (Rental Term: ${d.rentalTerm})"),
        _buildPdfTableRow("Payment Plan Selected", "${d.paymentFrequency} — Number of Installments: ${d.installmentsCount}"),
        _buildPdfTableRow("Installment Amounts & Due Dates", instSummary),
        _buildPdfTableRow("Rent Due Date (if monthly)", "10th of every month"),
        _buildPdfTableRow("Late Payment Charge", "₹ 100 per day, chargeable from the 4th day after due date"),
        _buildPdfTableRow("Electricity Charges", "₹ 12 per unit as per meter reading (shared equally)"),
        _buildPdfTableRow("Water Charges", "Included in Rent"),
        _buildPdfTableRow("Common Maintenance Charges", "Included in Rent"),
        _buildPdfTableRow("Academic Session / Lock-in Period", "${d.lockInPeriod} (${d.commencementDate} to ${d.endingDate})"),
        _buildPdfTableRow("Notice Period for Termination", "30 days"),
        _buildPdfTableRow("Deposit Refund Timeline", "30 days from vacating"),
        _buildPdfTableRow("All Payments Payable To", "Bank Account Number and UPI ID displayed on the App ONLY"),
      ],
    );
  }

  Widget _buildScheduleCTable(RentalAgreementData d) {
    final bool isPkg = d.plan.toLowerCase().contains("package");
    return Table(
      border: TableBorder.all(color: const Color(0xFF94A3B8), width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(0.8),
        2: FlexColumnWidth(1.6),
        3: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF1F3864)),
          children: [
            _buildTh("Package Facility"),
            _buildTh("Included?"),
            _buildTh("Frequency / Details"),
            _buildTh("Additional Charge"),
          ],
        ),
        _buildPkgRow("Room / Flat Rent (Base)", "Y", "Monthly / As per Plan", "As per Schedule B"),
        _buildPkgRow("Meals (Breakfast, Lunch, Dinner)", isPkg ? "Y" : "N", "3 times daily / as opted", isPkg ? "Included in Package" : "Optional"),
        _buildPkgRow("Pick-up & Drop to College", "N", "Fixed timing routes", "Optional"),
        _buildPkgRow("Laundry Service", isPkg ? "Y" : "N", "2 times per week", isPkg ? "Included" : "Optional"),
        _buildPkgRow("Room / Common Area Cleaning", "Y", "Regular scheduled cleaning", "Included"),
        _buildPkgRow("Wi-Fi / Internet Access", "Y", "Shared bandwidth, FUP applies", "Complimentary"),
      ],
    );
  }

  Widget _buildAnnexureITable(RentalAgreementData d) {
    return Table(
      border: TableBorder.all(color: const Color(0xFF94A3B8), width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2.0),
      },
      children: [
        _buildPdfTableRow("Building / Room / Flat No.", "Building ${d.building}, Room ${d.roomNumber}"),
        _buildPdfTableRow("Date of this Form", d.agreementDate),
        _buildPdfTableRow("Resident 1", "${d.studentFullName} (Digitally Signed on App)"),
        _buildPdfTableRow("Acknowledged by Owner / Warden", "Mr. Ajay Singh, Founder / Licensor"),
      ],
    );
  }

  // ==========================================================================
  // BOTTOM ACTION BAR
  // ==========================================================================
  Widget _buildBottomActionBar() {
    return Container(
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
              child: Text(
                "Back / Edit Form",
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF475569),
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
              label: Text(
                _isGeneratingPdf ? "Compiling Signed Agreement..." : "Accept & Sign Agreement",
                style: GoogleFonts.roboto(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
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
    );
  }
}

// -------------------------------------------------------------
// EXACT VECTOR PAINTERS MATCHING THE ORIGINAL PDF STREAM
// -------------------------------------------------------------

/// Top Navy Shape: Color #1F3864
/// Enters at (52.67, 0) and swoops down via cubic bezier to (176.10, 50.50),
/// then runs flat across to the right edge at height 50.50 pt.
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

    // Exact subdivided cubic bezier curve from original PDF stream:
    // P0=(52.67, 0.00), P1=(84.44, 31.23), P2=(128.02, 50.50), P3=(176.10, 50.50)
    path.cubicTo(
      84.44 * scale,
      31.23 * scale,
      128.02 * scale,
      50.50 * scale,
      xFlat,
      flatH,
    );

    // Straight horizontal line to right edge
    path.lineTo(w, flatH);
    // Straight up to top right corner
    path.lineTo(w, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom Navy Shape: Color #1F3864
/// Solid dark navy footer bar from bottom-left across to 412.47 pt,
/// then swoops down via cubic bezier to 531.19 pt at the bottom edge.
class _BottomFooterNavyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F3864)
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;
    final double scale = w / 595.32;

    // In PDF: flat height is 44.02 pt from bottom
    final double flatY = h - (44.02 * scale);
    final double xFlat = 412.47 * scale;
    final double xEnd = 531.19 * scale;

    final path = Path();
    path.moveTo(0, flatY);
    // Straight horizontal line to 412.47
    path.lineTo(xFlat, flatY);

    // Exact subdivided cubic bezier curve from original PDF stream:
    // P0=(412.47, 44.02), P1=(457.83, 44.02), P2=(499.31, 27.43), P3=(531.19, 0.00)
    path.cubicTo(
      457.83 * scale,
      flatY,
      499.31 * scale,
      h - (27.43 * scale),
      xEnd,
      h,
    );

    // Along bottom edge to bottom-left corner
    path.lineTo(0, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
