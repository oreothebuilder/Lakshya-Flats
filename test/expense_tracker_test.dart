import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/models/expense_bucket_model.dart';
import 'package:lakshya_residency/models/expense_model.dart';

void main() {
  group('ExpenseBucketModel Tests', () {
    test('Default buckets contain exactly the 6 requested categories in order', () {
      final buckets = ExpenseBucketModel.defaultBuckets;
      expect(buckets.length, 6);

      expect(buckets[0].name, 'Hostel mess');
      expect(buckets[1].name, 'Maintenance and fixes');
      expect(buckets[2].name, 'Staff payment');
      expect(buckets[3].name, 'Laundry');
      expect(buckets[4].name, 'Petrol for transportation');
      expect(buckets[5].name, 'others');

      // All default buckets should be flagged isDefault: true
      for (final b in buckets) {
        expect(b.isDefault, true);
        expect(b.iconData, isNotNull);
      }
    });

    test('Custom bucket creation, toMap, and copyWith work correctly', () {
      final customBucket = ExpenseBucketModel(
        id: 'bucket_custom_water',
        name: 'Water Supply',
        iconKey: 'water',
        colorValue: 0xFF06B6D4,
        description: 'Water tankers and filtration maintenance',
      );

      expect(customBucket.isDefault, false);
      expect(customBucket.name, 'Water Supply');
      expect(customBucket.iconKey, 'water');

      final map = customBucket.toMap();
      expect(map['name'], 'Water Supply');
      expect(map['iconKey'], 'water');
      expect(map['colorValue'], 0xFF06B6D4);
      expect(map['isDefault'], false);

      final updated = customBucket.copyWith(name: 'RO Water Tankers');
      expect(updated.name, 'RO Water Tankers');
      expect(updated.id, 'bucket_custom_water');
    });
  });

  group('ExpenseModel Tests', () {
    test('ExpenseModel initializes with proper defaults and formats map', () {
      final now = DateTime(2026, 9, 7);
      final expense = ExpenseModel(
        id: 'exp_001',
        title: 'Weekly Vegetables',
        amount: 4500.0,
        bucketId: 'bucket_hostel_mess',
        bucketName: 'Hostel mess',
        date: now,
        paymentMode: 'UPI',
        paidTo: 'Green Grocers',
        building: 'Univ homes',
        notes: 'Invoice #1024',
        recordedBy: 'Admin User',
      );

      expect(expense.amount, 4500.0);
      expect(expense.title, 'Weekly Vegetables');
      expect(expense.bucketName, 'Hostel mess');
      expect(expense.paymentMode, 'UPI');
      expect(expense.building, 'Univ homes');

      final map = expense.toMap();
      expect(map['title'], 'Weekly Vegetables');
      expect(map['amount'], 4500.0);
      expect(map['bucketId'], 'bucket_hostel_mess');
      expect(map['paymentMode'], 'UPI');
      expect(map['paidTo'], 'Green Grocers');
    });

    test('ExpenseModel copyWith updates fields cleanly', () {
      final expense = ExpenseModel(
        id: 'exp_002',
        title: 'Generator Fuel',
        amount: 2500.0,
        bucketId: 'bucket_petrol',
        bucketName: 'Petrol for transportation',
        date: DateTime.now(),
      );

      final modified = expense.copyWith(
        amount: 3000.0,
        notes: 'Emergency diesel',
      );

      expect(modified.id, 'exp_002');
      expect(modified.amount, 3000.0);
      expect(modified.notes, 'Emergency diesel');
      expect(modified.bucketName, 'Petrol for transportation');
    });
  });
}
