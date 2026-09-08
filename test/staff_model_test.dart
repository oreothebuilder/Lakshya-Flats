import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/models/staff_model.dart';

void main() {
  group('StaffModel Tests', () {
    test('Ensures defaultStaff list is completely empty (no dummy data)', () {
      expect(StaffModel.defaultStaff, isEmpty);
      expect(StaffModel.defaultStaff.length, 0);
    });

    test('Creates Building In-Charge staff profile correctly', () {
      final warden = StaffModel(
        id: 'stf_001',
        staffId: 'STF-101',
        name: 'Ramesh Singh',
        phone: '+91 9876543210',
        email: 'ramesh@lakshya.com',
        assignmentType: 'building_incharge',
        designation: 'Senior Warden',
        assignedBuildings: ['Lakshya', 'Ishaan'],
      );

      expect(warden.isBuildingInCharge, true);
      expect(warden.isTaskBased, false);
      expect(warden.assignedBuildings, contains('Lakshya'));
      expect(warden.assignedBuildings, contains('Ishaan'));
      expect(warden.isActive, true);

      final map = warden.toMap();
      expect(map['assignmentType'], 'building_incharge');
      expect(map['designation'], 'Senior Warden');
      expect(map['assignedBuildings'], ['Lakshya', 'Ishaan']);
    });

    test('Creates Particular Task (Driver) staff profile correctly', () {
      final driver = StaffModel(
        id: 'stf_002',
        staffId: 'STF-102',
        name: 'Sukhwinder Pal',
        phone: '+91 9811223344',
        assignmentType: 'task_based',
        designation: 'Driver',
        assignedTask: 'Driver',
        notes: 'Duty: Morning & Evening Bus Route 1',
      );

      expect(driver.isTaskBased, true);
      expect(driver.isBuildingInCharge, false);
      expect(driver.assignedTask, 'Driver');
      expect(driver.notes, contains('Route 1'));

      final map = driver.toMap();
      expect(map['assignmentType'], 'task_based');
      expect(map['assignedTask'], 'Driver');
    });

    test('Creates Particular Task (Chef) staff profile correctly', () {
      final chef = StaffModel(
        id: 'stf_003',
        staffId: 'STF-103',
        name: 'Bhawani Shankar',
        phone: '+91 9822334455',
        assignmentType: 'task_based',
        designation: 'Head Chef',
        assignedTask: 'Chef / Cook',
        assignedBuildings: ['Univ Homes'],
        notes: 'Duty: Central Mess Lunch & Dinner',
      );

      expect(chef.isTaskBased, true);
      expect(chef.assignedTask, 'Chef / Cook');
      expect(chef.assignedBuildings, contains('Univ Homes'));
    });

    test('StaffModel copyWith preserves and updates fields accurately', () {
      final staff = StaffModel(
        id: 'stf_004',
        staffId: 'STF-104',
        name: 'Sunil Verma',
        phone: '+91 9833445566',
        assignmentType: 'task_based',
        designation: 'Electrician',
        assignedTask: 'Electrician',
        status: 'Active',
      );

      final updated = staff.copyWith(
        status: 'On Leave',
        notes: 'Emergency medical leave',
      );

      expect(updated.status, 'On Leave');
      expect(updated.isActive, false);
      expect(updated.notes, 'Emergency medical leave');
      expect(updated.name, 'Sunil Verma');
      expect(updated.assignedTask, 'Electrician');
    });
  });
}
