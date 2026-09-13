import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/models/bill_model.dart';

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
  });
}
