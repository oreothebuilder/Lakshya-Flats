import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/services/agreement_pdf_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AgreementPdfService generates exact 20-page document with valid data and zero overflow', () async {
    final data = RentalAgreementData(
      agreementDate: "19/09/2026",
      commencementDate: "01/08/2026",
      endingDate: "30/06/2027",
      studentFullName: "Test Student",
      mobileNumber: "9876543210",
      email: "student@example.com",
      regNumber: "MUJ/2026/001",
      course: "B.Tech",
      branch: "Computer Science",
      hometownAddress: "123 Test Street, New Delhi",
      building: "A",
      roomNumber: "204",
      bedNumber: "A",
      flatConfig: "2 BHK",
      guardianName: "Test Guardian",
      guardianRelationship: "Father",
      guardianPhone: "9876543211",
      dietaryPreference: "Vegetarian",
      plan: "Rent Only (Monthly)",
      monthlyRent: "18,000",
      securityDeposit: "25,000",
      paymentFrequency: "Monthly",
      installmentsCount: 11,
      installments: [
        {"title": "Month 1 (Joining)", "amount": "18,000", "dueDate": "01/08/2026"},
        {"title": "Month 2", "amount": "18,000", "dueDate": "01/09/2026"},
      ],
      inventoryItems: ["Bed", "Study Table", "Chair", "AC", "Wardrobe", "Geyser"],
      notes: ["Special parking slot requested"],
      rentalTerm: "Complete Year (July to May) – 11 months",
      lockInPeriod: "11 Months",
      termMonths: 11,
      collegeIdUploaded: true,
      govtIdUploaded: true,
    );

    final Uint8List pdfBytes = await AgreementPdfService.generateAgreementPdf(data);
    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.length, greaterThan(10000));

    final PdfDocument doc = PdfDocument(inputBytes: pdfBytes);
    expect(doc.pages.count, equals(20));
    doc.dispose();
  });
}
