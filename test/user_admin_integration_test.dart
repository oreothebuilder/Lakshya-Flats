import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/models/bill_model.dart';
import 'package:lakshya_residency/models/mess_menu_model.dart';
import 'package:lakshya_residency/models/user_role_model.dart';
import 'package:lakshya_residency/models/student_profile_model.dart';

void main() {
  group('BillModel Integration & Verification Tests', () {
    test('BillModel accurately detects pending verification via status string', () {
      final bill = BillModel(
        id: 'bill_001',
        studentId: 'stud_123',
        studentName: 'Rahul Sharma',
        building: 'Lakshya',
        room: '204',
        billType: 'Hostel bill & security deposit',
        amount: 15000,
        paidAmount: 0,
        status: 'Pending Verification',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        invoiceNo: 'INV-2026-001',
      );

      expect(bill.isPendingVerification, isTrue);
      expect(bill.computedStatus, 'Pending Verification');
      expect(bill.isPaid, isFalse);
    });

    test('BillModel detects pending verification when UTR reference is provided', () {
      final bill = BillModel(
        id: 'bill_002',
        studentId: 'stud_124',
        studentName: 'Pooja Verma',
        building: 'Shivalya',
        room: '102',
        billType: 'Utility bills',
        amount: 2500,
        paidAmount: 0,
        status: 'Pending Verification',
        paymentStatus: 'Pending Verification',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        invoiceNo: 'INV-2026-002',
        transactionRef: '123456789012',
        paymentMethod: 'UPI / QR Code',
      );

      expect(bill.isPendingVerification, isTrue);
      expect(bill.utrNumber, '123456789012');
      expect(bill.computedStatus, 'Pending Verification');
    });

    test('BillModel prioritizes Paid status over pending verification once cleared', () {
      final bill = BillModel(
        id: 'bill_003',
        studentId: 'stud_125',
        studentName: 'Amit Patel',
        building: 'Ishaan',
        room: '305',
        billType: 'Hostel bill & security deposit',
        amount: 10000,
        paidAmount: 10000,
        status: 'Paid',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        invoiceNo: 'INV-2026-003',
        transactionRef: '987654321098',
        paymentMethod: 'UPI / QR Code',
        paidDate: '08 Sep 2026',
      );

      expect(bill.isPaid, isTrue);
      expect(bill.isPendingVerification, isFalse);
      expect(bill.computedStatus, 'Paid');
      expect(bill.balance, 0.0);
    });

    test('BillModel accurately identifies defaulters when past due date and not paid', () {
      final bill = BillModel(
        id: 'bill_004',
        studentId: 'stud_126',
        studentName: 'Karan Mehra',
        building: 'Univ homes',
        room: '101',
        billType: 'Utility bills',
        amount: 3000,
        paidAmount: 0,
        status: 'Pending',
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
        invoiceNo: 'INV-2026-004',
      );

      expect(bill.isDefaulter, isTrue);
      expect(bill.computedStatus, 'Defaulter');
      expect(bill.daysOverdue, greaterThanOrEqualTo(3));
    });
  });

  group('MessMenuModel Serialization Tests', () {
    test('MealInfo round-trips correctly to and from JSON', () {
      final meal = MealInfo(
        type: MealType.breakfast,
        title: 'Breakfast',
        timeSlot: '07:30 AM - 09:30 AM',
        icon: 'wb_sunny_rounded',
        items: ['Poha', 'Boiled Eggs', 'Tea', 'Banana'],
      );

      final json = meal.toJson();
      expect(json['type'], 'breakfast');
      expect(json['title'], 'Breakfast');
      expect(json['timeSlot'], '07:30 AM - 09:30 AM');
      expect(json['icon'], 'wb_sunny_rounded');
      expect(json['items'], contains('Poha'));

      final restored = MealInfo.fromJson(json);
      expect(restored.type, MealType.breakfast);
      expect(restored.title, 'Breakfast');
      expect(restored.timeSlot, meal.timeSlot);
      expect(restored.icon, meal.icon);
      expect(restored.items, meal.items);
    });

    test('DayMenu round-trips correctly to and from JSON', () {
      final day = DayMenu(
        dayName: 'Monday',
        shortDay: 'Mon',
        meals: [
          MealInfo(type: MealType.breakfast, title: 'Breakfast', timeSlot: '7:30 - 9:30 AM', icon: 'wb_sunny_rounded', items: ['Idli', 'Sambar']),
          MealInfo(type: MealType.lunch, title: 'Lunch', timeSlot: '12:30 - 2:30 PM', icon: 'wb_cloudy_rounded', items: ['Dal', 'Rice', 'Roti']),
          MealInfo(type: MealType.snacks, title: 'Evening Snacks', timeSlot: '5:00 - 6:30 PM', icon: 'free_breakfast_rounded', items: ['Samosa', 'Chai']),
          MealInfo(type: MealType.dinner, title: 'Dinner', timeSlot: '7:30 - 9:30 PM', icon: 'nights_stay_rounded', items: ['Paneer', 'Roti', 'Salad']),
        ],
      );

      final json = day.toJson();
      expect(json['dayName'], 'Monday');
      expect(json['shortDay'], 'Mon');
      expect((json['meals'] as List).length, 4);

      final restored = DayMenu.fromJson(json);
      expect(restored.dayName, 'Monday');
      expect(restored.shortDay, 'Mon');
      expect(restored.meals.length, 4);
      expect(restored.meals[0].items, ['Idli', 'Sambar']);
    });

    test('MessSchedule round-trips correctly with weekly days to and from JSON', () {
      final schedule = MessSchedule(
        messName: 'Univ Homes',
        days: [
          DayMenu(
            dayName: 'Sunday',
            shortDay: 'Sun',
            meals: [
              MealInfo(type: MealType.breakfast, title: 'Breakfast', timeSlot: '8:00 - 10:00 AM', icon: 'wb_sunny_rounded', items: ['Chole Bhature']),
              MealInfo(type: MealType.lunch, title: 'Lunch', timeSlot: '12:30 - 2:30 PM', icon: 'wb_cloudy_rounded', items: ['Special Thali']),
              MealInfo(type: MealType.snacks, title: 'Evening Snacks', timeSlot: '5:00 - 6:30 PM', icon: 'free_breakfast_rounded', items: ['Cookies', 'Coffee']),
              MealInfo(type: MealType.dinner, title: 'Dinner', timeSlot: '7:30 - 9:30 PM', icon: 'nights_stay_rounded', items: ['Biryani', 'Raita']),
            ],
          ),
        ],
      );

      final json = schedule.toJson();
      expect(json['messName'], 'Univ Homes');
      expect((json['days'] as List).length, 1);

      final restored = MessSchedule.fromJson(json);
      expect(restored.messName, 'Univ Homes');
      expect(restored.days.length, 1);
      expect(restored.days[0].dayName, 'Sunday');
      expect(restored.days[0].meals[0].items, ['Chole Bhature']);
    });
  });

  group('Room & Bed Assignment and Display Tests', () {
    test('AppUser parses and formats room and bed numbers correctly', () {
      final user = AppUser(
        uid: 'user_001',
        email: 'hardikx07@gmail.com',
        fullName: 'Hardik Tomar',
        role: AppRole.student,
        building: 'Shivalya',
        room: '101',
        bedNumber: '1',
      );

      expect(user.displayBed, 'Bed 1');
      expect(user.displayRoomOnly, '101');
      expect(user.displayRoomAndBed, '101 • Bed 1');
    });

    test('AppUser handles already prefixed Bed numbers without duplicate Bed', () {
      final user = AppUser(
        uid: 'user_002',
        email: 'resident@lakshya.com',
        fullName: 'Resident User',
        role: AppRole.student,
        building: 'Ishaan',
        room: '12',
        bedNumber: 'Bed 2',
      );

      expect(user.displayBed, 'Bed 2');
      expect(user.displayRoomOnly, '12');
      expect(user.displayRoomAndBed, '12 • Bed 2');
    });

    test('AppUser extracts bed from combined room string if bedNumber is omitted', () {
      final user = AppUser(
        uid: 'user_003',
        email: 'student@lakshya.com',
        fullName: 'Student Three',
        role: AppRole.student,
        building: 'Tirupati',
        room: 'Room 6 - Bed A',
      );

      expect(user.displayBed, 'Bed A');
      expect(user.displayRoomOnly, 'Room 6');
      expect(user.displayRoomAndBed, 'Room 6 • Bed A');
    });

    test('AppUser.fromFirestore correctly extracts bedNumber and bed keys', () {
      final user1 = AppUser.fromFirestore(
        uid: 'uid_1',
        data: {
          'fullName': 'Hardik Tomar',
          'email': 'hardikx07@gmail.com',
          'building': 'Shivalya',
          'room': '101',
          'bedNumber': '1',
        },
      );
      expect(user1.bedNumber, '1');
      expect(user1.displayRoomAndBed, '101 • Bed 1');

      final user2 = AppUser.fromFirestore(
        uid: 'uid_2',
        data: {
          'fullName': 'Testing Resident',
          'email': 'test@gmail.com',
          'building': 'Lakshya',
          'room': '204',
          'bed': '2',
        },
      );
      expect(user2.bedNumber, '2');
      expect(user2.displayRoomAndBed, '204 • Bed 2');
    });

    test('StudentProfile formats displayRoomAndBed correctly', () {
      final profile = StudentProfile(
        id: 'STU-568225-149',
        studentId: 'STU-568225-149',
        fullName: 'Hardik Tomar',
        firstName: 'Hardik',
        email: 'hardikx07@gmail.com',
        phone: '7417739939',
        registrationNumber: '2427030069',
        course: 'Btech',
        branch: 'CSE',
        building: 'Shivalya',
        room: '101',
        bedNumber: '1',
        plan: 'Full Package',
        paymentFrequency: 'Pay Monthly',
        monthlyRent: '12,500',
        securityDeposit: '25,000',
        guardianName: 'Guardian',
        guardianPhone: '9968612114',
        guardianRelationship: 'Father',
        dietaryPreference: 'Vegetarian',
      );

      expect(profile.displayBed, 'Bed 1');
      expect(profile.displayRoomOnly, '101');
      expect(profile.displayRoomAndBed, '101 • Bed 1');
    });
  });
}
