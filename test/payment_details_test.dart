import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/models/payment_details_model.dart';
import 'package:lakshya_residency/models/bill_model.dart';
import 'package:lakshya_residency/services/firestore_service.dart';

void main() {
  group('Payment Details & Custom Receiving Accounts Tests', () {
    test('Default Payment Details matches official Lakshya banking credentials', () {
      final details = PaymentDetailsModel.defaultDetails();

      expect(details.id, equals('default'));
      expect(details.scope, equals('global'));
      expect(details.buildingName, isNull);
      expect(details.accountHolderName, equals('Lakshya Student Residences'));
      expect(details.bankName, equals('ICICI Bank'));
      expect(details.accountNumber, equals('002105018921'));
      expect(details.ifscCode, equals('ICIC0000021'));
      expect(details.upiId, equals('lakshyastays@icici'));
      expect(details.instructions, contains('Please transfer or hand over the exact fee amount'));
    });

    test('Building-specific default payment details creates proper building scope and account name', () {
      final details = PaymentDetailsModel.defaultDetails(buildingName: 'Univ Homes');

      expect(details.scope, equals('building'));
      expect(details.buildingName, equals('Univ Homes'));
      expect(details.id, equals('building_univ_homes'));
      expect(details.accountHolderName, contains('Univ Homes'));
      expect(details.bankName, equals('ICICI Bank'));
      expect(details.accountNumber, equals('002105018921'));
      expect(details.ifscCode, equals('ICIC0000021'));
      expect(details.upiId, equals('lakshyastays@icici'));
    });

    test('PaymentDetailsModel toMap and copyWith preserves all fields', () {
      final original = PaymentDetailsModel(
        id: 'building_livano',
        scope: 'building',
        buildingName: 'Livano',
        accountHolderName: 'Livano Residences Ltd',
        bankName: 'HDFC Bank',
        accountNumber: '50100234567890',
        ifscCode: 'HDFC0001234',
        upiId: 'livano@hdfcbank',
        qrCodeUrl: 'https://res.cloudinary.com/demo/image/upload/livano_qr.png',
        instructions: 'Scan QR code and enter student admission number in remarks.',
        updatedBy: 'admin@lakshya.com',
      );

      final map = original.toMap();
      expect(map['scope'], equals('building'));
      expect(map['buildingName'], equals('Livano'));
      expect(map['accountHolderName'], equals('Livano Residences Ltd'));
      expect(map['bankName'], equals('HDFC Bank'));
      expect(map['accountNumber'], equals('50100234567890'));
      expect(map['ifscCode'], equals('HDFC0001234'));
      expect(map['upiId'], equals('livano@hdfcbank'));
      expect(map['qrCodeUrl'], equals('https://res.cloudinary.com/demo/image/upload/livano_qr.png'));
      expect(map['instructions'], contains('student admission number'));
      expect(map['updatedBy'], equals('admin@lakshya.com'));

      final modified = original.copyWith(
        bankName: 'Axis Bank',
        upiId: 'livano@axisbank',
      );
      expect(modified.bankName, equals('Axis Bank'));
      expect(modified.upiId, equals('livano@axisbank'));
      expect(modified.accountNumber, equals('50100234567890'));
      expect(modified.buildingName, equals('Livano'));
    });

    test('BillModel supports optional custom payee details', () {
      final bill = BillModel(
        id: 'bill_custom_001',
        studentId: 'stud_123',
        studentName: 'Aarav Patel',
        building: 'Ishaan',
        room: '101',
        billType: 'Hostel Fees',
        amount: 15000.0,
        status: 'Pending',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        invoiceNo: 'INV-2026-999',
        payeeAccountName: 'Ishaan Hostel Trust',
        payeeBankName: 'State Bank of India',
        payeeAccountNumber: '33445566778',
        payeeIfscCode: 'SBIN0001122',
        payeeUpiId: 'ishaanhostel@sbi',
        payeeQrCodeUrl: 'https://res.cloudinary.com/demo/image/upload/ishaan_qr.png',
      );

      expect(bill.payeeAccountName, equals('Ishaan Hostel Trust'));
      expect(bill.payeeBankName, equals('State Bank of India'));
      expect(bill.payeeAccountNumber, equals('33445566778'));
      expect(bill.payeeIfscCode, equals('SBIN0001122'));
      expect(bill.payeeUpiId, equals('ishaanhostel@sbi'));
      expect(bill.payeeQrCodeUrl, equals('https://res.cloudinary.com/demo/image/upload/ishaan_qr.png'));

      final map = bill.toMap();
      expect(map['payeeAccountName'], equals('Ishaan Hostel Trust'));
      expect(map['payeeBankName'], equals('State Bank of India'));
      expect(map['payeeAccountNumber'], equals('33445566778'));
      expect(map['payeeIfscCode'], equals('SBIN0001122'));
      expect(map['payeeUpiId'], equals('ishaanhostel@sbi'));
      expect(map['payeeQrCodeUrl'], equals('https://res.cloudinary.com/demo/image/upload/ishaan_qr.png'));
    });

    test('FirestoreService.normalizeBuildingKey creates consistent keys', () {
      expect(FirestoreService.normalizeBuildingKey('Univ Homes'), equals('univ_homes'));
      expect(FirestoreService.normalizeBuildingKey('Lakshya Residency'), equals('lakshya_residency'));
      expect(FirestoreService.normalizeBuildingKey('Somnath - Girls'), equals('somnath_girls'));
      expect(FirestoreService.normalizeBuildingKey('Rameshwaram'), equals('rameshwaram'));
    });
  });
}
