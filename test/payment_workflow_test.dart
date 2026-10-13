import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/models/bill_model.dart';
import 'package:lakshya_residency/services/payment_receipt_pdf_service.dart';

void main() {
  group('Payment Workflow BillModel Unit Tests', () {
    test('Correctly identifies Bank Transfer and proof properties', () {
      final bill = BillModel(
        id: 'bill_001',
        studentId: 'stud_123',
        studentName: 'Aman Kumar',
        studentEmail: 'aman@example.com',
        building: 'Lakshya Tower A',
        room: '204',
        billType: 'Rent',
        amount: 8500.0,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        status: 'Pending Verification',
        invoiceNo: 'INV-2026-001',
        paymentMethod: 'Bank transfer',
        transactionRef: 'ICIC000123456789',
        proofUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        paymentRemarks: 'Paid via IMPS transfer',
        submittedAt: DateTime.now(),
      );

      expect(bill.isBankTransfer, isTrue);
      expect(bill.isUpi, isFalse);
      expect(bill.isCash, isFalse);
      expect(bill.hasProofScreenshot, isTrue);
      expect(bill.isPendingVerification, isTrue);
      expect(bill.studentEmail, equals('aman@example.com'));
      expect(bill.utrNumber, equals('ICIC000123456789'));
    });

    test('Correctly identifies UPI Payment with UTR and proof', () {
      final bill = BillModel(
        id: 'bill_002',
        studentId: 'stud_456',
        studentName: 'Rohan Sharma',
        building: 'Lakshya Tower B',
        room: '102',
        billType: 'Mess',
        amount: 3500.0,
        dueDate: DateTime.now().add(const Duration(days: 2)),
        status: 'Pending Verification',
        invoiceNo: 'INV-2026-002',
        paymentMethod: 'UPI',
        transactionRef: '423489123456',
        proofUrl: 'https://res.cloudinary.com/demo/image/upload/upi_receipt.png',
      );

      expect(bill.isBankTransfer, isFalse);
      expect(bill.isUpi, isTrue);
      expect(bill.isCash, isFalse);
      expect(bill.hasProofScreenshot, isTrue);
      expect(bill.isPendingVerification, isTrue);
    });

    test('Correctly identifies Cash Handover flow', () {
      final bill = BillModel(
        id: 'bill_003',
        studentId: 'stud_789',
        studentName: 'Priya Verma',
        building: 'Lakshya Tower A',
        room: '305',
        billType: 'Electricity',
        amount: 1200.0,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        status: 'Pending Verification',
        invoiceNo: 'INV-2026-003',
        paymentMethod: 'Cash',
        paymentRemarks: 'Handed Rs 1200 cash at hostel front office',
      );

      expect(bill.isBankTransfer, isFalse);
      expect(bill.isUpi, isFalse);
      expect(bill.isCash, isTrue);
      expect(bill.hasProofScreenshot, isFalse);
      expect(bill.isPendingVerification, isTrue);
      expect(bill.paymentRemarks, contains('front office'));
    });

    test('Round-trip serialization toMap and copyWith preserves all payment fields', () {
      final now = DateTime.now();
      final bill = BillModel(
        id: 'bill_004',
        studentId: 'stud_999',
        studentName: 'Suresh Patel',
        studentEmail: 'suresh@domain.com',
        building: 'Lakshya Tower C',
        room: '401',
        billType: 'Security Deposit',
        amount: 10000.0,
        dueDate: now.add(const Duration(days: 10)),
        status: 'Pending Verification',
        invoiceNo: 'INV-2026-004',
        paymentMethod: 'UPI',
        transactionRef: 'UPI987654321',
        proofUrl: 'https://res.cloudinary.com/demo/image/upload/security.png',
        paymentRemarks: 'Transferred via Google Pay',
        adminRemarks: 'Verified against SBI statements',
        submittedAt: now,
      );

      final map = bill.toMap();
      expect(map['studentEmail'], equals('suresh@domain.com'));
      expect(map['paymentMode'], equals('UPI'));
      expect(map['utrNumber'], equals('UPI987654321'));
      expect(map['proofUrl'], equals('https://res.cloudinary.com/demo/image/upload/security.png'));
      expect(map['paymentRemarks'], equals('Transferred via Google Pay'));
      expect(map['adminRemarks'], equals('Verified against SBI statements'));
      expect(map['submittedAt'], isNotNull);

      // Verify copyWith works smoothly
      final approvedBill = bill.copyWith(
        status: 'Paid',
        adminRemarks: 'Approved by Hostel Manager',
      );
      expect(approvedBill.status, equals('Paid'));
      expect(approvedBill.isPendingVerification, isFalse);
      expect(approvedBill.adminRemarks, equals('Approved by Hostel Manager'));
      expect(approvedBill.utrNumber, equals('UPI987654321'));
      expect(approvedBill.proofUrl, equals('https://res.cloudinary.com/demo/image/upload/security.png'));
    });

    test('Defaulter amount defaults to 0.0 and computes totalPayable correctly', () {
      final bill = BillModel(
        id: 'bill_def_0',
        studentId: 'stud_101',
        studentName: 'Rahul Verma',
        building: 'Lakshya Tower A',
        room: '101',
        billType: 'Mess Charges',
        billingMonth: 'March 2026',
        amount: 4000.0,
        dueDate: DateTime(2026, 3, 10),
        status: 'Pending',
        invoiceNo: 'INV-TEST-001',
      );

      expect(bill.defaulterAmount, equals(0.0));
      expect(bill.totalPayable, equals(4000.0));
      expect(bill.balance, equals(4000.0));
      expect(bill.isPaid, isFalse);
    });

    test('Defaulter amount is added to totalPayable and balance when present', () {
      final bill = BillModel(
        id: 'bill_def_1',
        studentId: 'stud_102',
        studentName: 'Sneha Roy',
        building: 'Lakshya Tower B',
        room: '202',
        billType: 'Rent',
        billingMonth: 'Installment 2 Rent (Q1)',
        amount: 8000.0,
        defaulterAmount: 500.0,
        paidAmount: 2000.0,
        dueDate: DateTime(2026, 2, 28),
        status: 'Overdue',
        invoiceNo: 'INV-TEST-002',
      );

      expect(bill.defaulterAmount, equals(500.0));
      expect(bill.totalPayable, equals(8500.0)); // 8000 + 500
      expect(bill.balance, equals(6500.0)); // 8500 - 2000
      expect(bill.isPaid, isFalse);

      // Verify toMap serialization
      final map = bill.toMap();
      expect(map['defaulterAmount'], equals(500.0));

      // Verify copyWith preserves and updates defaulterAmount
      final updatedBill = bill.copyWith(defaulterAmount: 750.0);
      expect(updatedBill.defaulterAmount, equals(750.0));
      expect(updatedBill.totalPayable, equals(8750.0));
    });

    test('PaymentReceiptData and PDF generation executes cleanly for letterhead format', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final receiptData = PaymentReceiptData(
        receiptNo: 'INV-2026-TEST',
        billIssueDate: '01/03/2026',
        headerDate: '01/03/2026',
        payeeName: 'Kunal Sharma',
        contactNumber: '9876543210',
        email: 'kunal@example.com',
        buildingAddress: 'Lakshya Tower A, Kota',
        roomAndBed: 'Room 302, Bed A',
        billTitle: 'Installment 1 - Hostel Rent 2026',
        billInformedDate: '01/03/2026',
        paymentType: 'Rent',
        paymentMethod: 'UPI',
        baseAmount: 10000.0,
        defaulterAmount: 300.0,
        amount: 10000.0,
        totalAmount: 10300.0,
        paidAmount: 10300.0,
        balanceAmount: 0.0,
        deadline: '10/03/2026',
        paidOn: '05/03/2026',
        paymentStatus: 'PAID',
        transactionRef: 'UPI1234567890',
      );

      expect(receiptData.billTitle, equals('Installment 1 - Hostel Rent 2026'));
      expect(receiptData.defaulterAmount, equals(300.0));
      expect(receiptData.totalAmount, equals(10300.0));
      expect(receiptData.isPaid, isTrue);
      expect(receiptData.headerDate, equals('01/03/2026'));

      final pdfBytes = await PaymentReceiptPdfService.generateReceiptPdf(receiptData);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}

