import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/models/user_role_model.dart';
import 'package:lakshya_residency/models/building_model.dart';
import 'package:lakshya_residency/models/bill_model.dart';
import 'package:lakshya_residency/models/complaint_model.dart';
import 'package:lakshya_residency/models/staff_model.dart';
import 'package:lakshya_residency/models/expense_bucket_model.dart';
import 'package:lakshya_residency/models/expense_model.dart';
import 'package:lakshya_residency/models/personal_todo_model.dart';
import 'package:lakshya_residency/services/firestore_service.dart';

void main() {
  group('Admin & Management End-to-End Flow Tests', () {
    test('E2E Admin Journey 1: Super Admin identity & privilege restoration logic', () {
      final firestoreService = FirestoreService();

      // Primary admin email has root privileges
      expect(firestoreService.isPrimaryAdminEmail('sudhansu1906@gmail.com'), isTrue);
      expect(firestoreService.isPrimaryAdminEmail('SUDHANSU1906@GMAIL.COM'), isTrue);

      // Student and random emails do not have root privilege
      expect(firestoreService.isPrimaryAdminEmail('student@example.com'), isFalse);
      expect(firestoreService.isPrimaryAdminEmail('admin@otherdomain.com'), isFalse);

      final adminUser = AppUser(
        uid: 'adm_root_001',
        email: 'sudhansu1906@gmail.com',
        fullName: 'Sudhanshu (Super Admin)',
        role: AppRole.admin,
      );

      expect(adminUser.isAdmin, isTrue);
      expect(adminUser.isManagement, isFalse);
      expect(adminUser.isStudent, isFalse);
      expect(adminUser.role.name, 'admin');
    });

    test('E2E Admin Journey 2: Property catalog & multi-building capacity aggregation', () {
      final properties = BuildingModel.defaultBuildings;
      expect(properties.length, 8);

      int totalCampusCapacity = 0;
      int totalCampusOccupied = 0;

      for (final p in properties) {
        totalCampusCapacity += p.totalCapacity;
        totalCampusOccupied += p.occupiedCount;
        expect(p.availableBeds, equals(p.totalCapacity - p.occupiedCount));
        expect(p.occupancyRate, lessThanOrEqualTo(1.0));
      }

      expect(totalCampusCapacity, greaterThan(0));
      expect(totalCampusOccupied, greaterThanOrEqualTo(0));

      final aggregateOccupancyPercentage =
          ((totalCampusOccupied / totalCampusCapacity) * 100).round();
      expect(aggregateOccupancyPercentage, inInclusiveRange(0, 100));

      // Simulate a property becoming near capacity (>= 90%)
      final nearFullLakshya = properties.first.copyWith(
        occupiedCount: (properties.first.totalCapacity * 0.95).round(),
      );
      expect(nearFullLakshya.isNearCapacity, isTrue);
      expect(nearFullLakshya.isFull, isFalse);

      // Simulate a property reaching 100% full
      final fullLakshya = nearFullLakshya.copyWith(
        occupiedCount: nearFullLakshya.totalCapacity,
      );
      expect(fullLakshya.isFull, isTrue);
      expect(fullLakshya.availableBeds, 0);
    });

    test('E2E Admin Journey 3: Billing collection, pending proof review, and defaulters pipeline', () {
      final now = DateTime.now();

      final bill1 = BillModel(
        id: 'bill_001',
        studentId: 'st_01',
        studentName: 'Aarav Gupta',
        building: 'Lakshya',
        room: '101',
        billType: 'Hostel Rent',
        amount: 15000,
        paidAmount: 15000,
        status: 'Paid',
        dueDate: now.subtract(const Duration(days: 5)),
        invoiceNo: 'INV-001',
      );

      final bill2 = BillModel(
        id: 'bill_002',
        studentId: 'st_02',
        studentName: 'Pooja Verma',
        building: 'Ishaan',
        room: '202',
        billType: 'Electricity',
        amount: 2500,
        paidAmount: 0,
        status: 'Pending Verification',
        dueDate: now.add(const Duration(days: 2)),
        invoiceNo: 'INV-002',
        paymentMethod: 'UPI',
        transactionRef: '492817294821',
        proofUrl: 'https://res.cloudinary.com/lakshya/image/upload/upi_sample.jpg',
      );

      final bill3 = BillModel(
        id: 'bill_003',
        studentId: 'st_03',
        studentName: 'Vikram Singh',
        building: 'Univ Homes',
        room: '305',
        billType: 'Mess Fee',
        amount: 4500,
        paidAmount: 0,
        status: 'Pending',
        dueDate: now.subtract(const Duration(days: 4)),
        invoiceNo: 'INV-003',
      );

      final allBills = [bill1, bill2, bill3];

      // Defaulters pipeline
      final defaulters = allBills.where((b) => b.isDefaulter).toList();
      expect(defaulters.length, 1);
      expect(defaulters.first.studentName, 'Vikram Singh');
      expect(defaulters.first.daysOverdue, greaterThanOrEqualTo(4));

      // Pending verification queue
      final pendingVerification = allBills.where((b) => b.isPendingVerification).toList();
      expect(pendingVerification.length, 1);
      expect(pendingVerification.first.studentName, 'Pooja Verma');
      expect(pendingVerification.first.hasProofScreenshot, isTrue);
      expect(pendingVerification.first.utrNumber, '492817294821');

      // Admin executes approval on bill2
      final approvedBill2 = bill2.copyWith(
        status: 'Paid',
        paidAmount: 2500,
        paidDate: '09 Sep 2026',
        adminRemarks: 'Verified against ICICI Statement',
      );
      expect(approvedBill2.isPaid, isTrue);
      expect(approvedBill2.isPendingVerification, isFalse);
      expect(approvedBill2.balance, 0.0);

      // Admin executes rejection on bill2
      final rejectedBill2 = bill2.copyWith(
        status: 'Pending',
        transactionRef: '',
        adminRemarks: 'Invalid UTR reference. Amount not credited.',
      );
      expect(rejectedBill2.isPaid, isFalse);
      expect(rejectedBill2.isPendingVerification, isFalse);
      expect(rejectedBill2.status, 'Pending');
      expect(rejectedBill2.adminRemarks, contains('Invalid UTR'));
    });

    test('E2E Admin Journey 4: Helpdesk triage & lifecycle management', () {
      final rawTicket = ComplaintModel(
        id: 'tkt_adm_01',
        studentId: 'st_10',
        studentName: 'Sneha Patel',
        building: 'Rameshwaram',
        room: '201',
        title: 'WiFi router not functioning',
        category: 'Wi-Fi',
        description: 'No SSID broadcasting on 2nd floor.',
      );

      expect(rawTicket.status, ComplaintModel.statusReceived);

      // Triage: Move to Under Execution
      final inProgress = rawTicket.copyWith(
        status: ComplaintModel.statusUnderExecution,
        adminRemarks: 'Jio Fiber ISP technician notified. Dispatch scheduled.',
      );
      expect(inProgress.status, ComplaintModel.statusUnderExecution);
      expect(inProgress.isUnderExecution, isTrue);

      // Triage: Resolve ticket
      final resolved = inProgress.copyWith(
        status: ComplaintModel.statusResolved,
        adminRemarks: 'Fiber cable re-spliced by technician. Signal restored.',
        resolvedAt: DateTime.now(),
      );
      expect(resolved.status, ComplaintModel.statusResolved);
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolvedAt, isNotNull);
    });

    test('E2E Admin Journey 5: Multi-bucket expense ledger and financial aggregation', () {
      final buckets = ExpenseBucketModel.defaultBuckets;
      expect(buckets.length, 6);

      final expenses = [
        ExpenseModel(
          id: 'exp_01',
          title: 'Daily Dairy & Milk supply',
          amount: 8500.0,
          bucketId: buckets[0].id,
          bucketName: buckets[0].name, // Hostel mess
          date: DateTime.now(),
        ),
        ExpenseModel(
          id: 'exp_02',
          title: 'Plumber plumbing repairs',
          amount: 3200.0,
          bucketId: buckets[1].id,
          bucketName: buckets[1].name, // Maintenance and fixes
          date: DateTime.now(),
        ),
        ExpenseModel(
          id: 'exp_03',
          title: 'Hostel Bus Diesel',
          amount: 4000.0,
          bucketId: buckets[4].id,
          bucketName: buckets[4].name, // Petrol for transportation
          date: DateTime.now(),
        ),
      ];

      final totalExpense = expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
      expect(totalExpense, 15700.0);

      final messExpenses = expenses
          .where((e) => e.bucketName == 'Hostel mess')
          .fold<double>(0.0, (sum, item) => sum + item.amount);
      expect(messExpenses, 8500.0);
    });

    test('E2E Admin Journey 6: Staff duty roster & building allocations', () {
      final warden = StaffModel(
        id: 'stf_w1',
        staffId: 'STF-01',
        name: 'Mahesh Sharma',
        phone: '+91 9988776655',
        assignmentType: 'building_incharge',
        designation: 'Warden',
        assignedBuildings: ['Lakshya', 'Ishaan'],
      );

      final driver = StaffModel(
        id: 'stf_d1',
        staffId: 'STF-02',
        name: 'Karamjit Singh',
        phone: '+91 9911223344',
        assignmentType: 'task_based',
        designation: 'Driver',
        assignedTask: 'Driver',
        assignedBuildings: ['Univ Homes'],
      );

      expect(warden.isBuildingInCharge, isTrue);
      expect(warden.assignedBuildings, contains('Lakshya'));
      expect(driver.isTaskBased, isTrue);
      expect(driver.assignedTask, 'Driver');
      expect(driver.isActive, isTrue);
    });

    test('E2E Admin Journey 7: Daily operational checklist & to-do management', () {
      final now = DateTime.now();
      final todayTask = PersonalTodoModel(
        id: 'td_01',
        title: 'Inspect mess kitchen hygiene',
        dueDate: now,
      );

      final overdueTask = PersonalTodoModel(
        id: 'td_02',
        title: 'Renew building fire safety NOC',
        dueDate: now.subtract(const Duration(days: 3)),
      );

      expect(todayTask.isDueToday, isTrue);
      expect(todayTask.isOverdue, isFalse);

      expect(overdueTask.isOverdue, isTrue);
      expect(overdueTask.isDueToday, isFalse);

      final completedTask = overdueTask.copyWith(
        isCompleted: true,
        completedAt: now,
      );
      expect(completedTask.isCompleted, isTrue);
      expect(completedTask.isOverdue, isFalse); // Once completed, no longer flagged overdue
    });
  });
}
