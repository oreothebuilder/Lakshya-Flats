import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/models/user_role_model.dart';
import 'package:lakshya_residency/models/bill_model.dart';
import 'package:lakshya_residency/models/complaint_model.dart';
import 'package:lakshya_residency/screens/onboarding_screen.dart';
import 'package:lakshya_residency/screens/login_screen.dart';
import 'package:lakshya_residency/screens/User/mess_menu_screen.dart';

void main() {
  group('Resident End-to-End Flow Tests', () {
    testWidgets('E2E Journey 1: Onboarding slide carousel and navigation to Login',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // Verify initial slide buttons
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Tap Skip to directly jump to the final action slide
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Verify final action buttons
      expect(find.text('User Login'), findsOneWidget);
      expect(find.text('Management'), findsOneWidget);

      // Tapping User Login navigates to student LoginScreen
      await tester.tap(find.text('User Login'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Student Portal Login'), findsOneWidget);
    });

    testWidgets('E2E Journey 2: Student Login form validation and password visibility toggle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(initialRole: LoginRole.user),
        ),
      );
      await tester.pumpAndSettle();

      // Student Portal Login title and Sign In button
      expect(find.text('Student Portal Login'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Submitting empty credentials triggers validation snackbar
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Please enter your Email ID'), findsOneWidget);

      // Enter student credentials
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.first, 'student@lakshya.com');
      await tester.enterText(textFields.last, 'Student@123');
      await tester.pumpAndSettle();

      final TextField emailField = tester.widget(textFields.first);
      final TextField passwordField = tester.widget(textFields.last);

      expect(emailField.controller?.text, 'student@lakshya.com');
      expect(passwordField.controller?.text, 'Student@123');
      expect(passwordField.obscureText, isTrue);

      // Toggle password visibility
      final visibilityIcon = find.byIcon(Icons.visibility_outlined);
      expect(visibilityIcon, findsOneWidget);
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      final TextField updatedPasswordField = tester.widget(textFields.last);
      expect(updatedPasswordField.obscureText, isFalse);
    });

    testWidgets('E2E Journey 3: Management Portal role toggle and super admin auto-fill',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(initialRole: LoginRole.manager),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Management Portal'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Log In to Management'), findsOneWidget);

      // Admin tab auto-populates the super admin email
      final emailField = find.byType(TextField).first;
      final TextField adminEmail = tester.widget(emailField);
      expect(adminEmail.controller?.text, 'sudhansu1906@gmail.com');

      // Switch to Staff tab
      await tester.tap(find.text('Staff'));
      await tester.pumpAndSettle();

      final TextField staffEmail = tester.widget(emailField);
      expect(staffEmail.controller?.text, isEmpty);

      // Switch back to Admin tab
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      final TextField restoredAdminEmail = tester.widget(emailField);
      expect(restoredAdminEmail.controller?.text, 'sudhansu1906@gmail.com');
    });

    testWidgets('E2E Journey 4: Mess Menu screen viewing and day switching',
        (WidgetTester tester) async {
      final studentUser = AppUser(
        uid: 'stud_e2e_001',
        email: 'rahul@student.com',
        fullName: 'Rahul Sharma',
        role: AppRole.student,
        building: 'Univ Homes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MessMenuScreen(currentUser: studentUser),
        ),
      );
      await tester.pumpAndSettle();

      // Check header title
      expect(find.text('Mess Menu & Timings'), findsOneWidget);

      // Check that day selector chips exist
      expect(find.text('Monday'), findsWidgets);

      // Tap Monday chip
      await tester.tap(find.text('Monday').first);
      await tester.pumpAndSettle();

      // Univ Homes Monday menu contains Indori Poha for breakfast
      expect(find.textContaining('Indori Poha'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Evening Snacks'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
    });

    test('E2E Journey 5: Resident bill inspection and UPI payment submission workflow', () {
      // 1. Initial unpaid bill
      final unpaidBill = BillModel(
        id: 'bill_e2e_101',
        studentId: 'stud_e2e_001',
        studentName: 'Rahul Sharma',
        studentEmail: 'rahul@student.com',
        building: 'Lakshya',
        room: '204',
        billType: 'Hostel Rent',
        amount: 12000.0,
        paidAmount: 0.0,
        status: 'Pending',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        invoiceNo: 'INV-2026-101',
      );

      expect(unpaidBill.isPaid, isFalse);
      expect(unpaidBill.isPendingVerification, isFalse);
      expect(unpaidBill.computedStatus, 'Pending');

      // 2. Student enters UPI payment with 12-digit UTR and receipt reference
      final submittedBill = unpaidBill.copyWith(
        status: 'Pending Verification',
        paymentMethod: 'UPI',
        transactionRef: '629847192847',
        paymentRemarks: 'Paid via PhonePe',
        submittedAt: DateTime.now(),
      );

      expect(submittedBill.isPendingVerification, isTrue);
      expect(submittedBill.computedStatus, 'Pending Verification');
      expect(submittedBill.utrNumber, '629847192847');
      expect(submittedBill.isUpi, isTrue);

      // 3. Admin verifies and approves payment
      final approvedBill = submittedBill.copyWith(
        status: 'Paid',
        paidAmount: 12000.0,
        paidDate: '09 Sep 2026',
        adminRemarks: 'Payment verified with HDFC statement',
      );

      expect(approvedBill.isPaid, isTrue);
      expect(approvedBill.isPendingVerification, isFalse);
      expect(approvedBill.balance, 0.0);
      expect(approvedBill.computedStatus, 'Paid');
    });

    test('E2E Journey 6: Resident maintenance ticket lifecycle from submission to resolution', () {
      // 1. Resident files a complaint
      final ticket = ComplaintModel(
        id: 'tkt_e2e_001',
        studentId: 'stud_e2e_001',
        studentName: 'Rahul Sharma',
        studentPhone: '+91 9876543210',
        building: 'Lakshya',
        room: '204',
        title: 'Geyser thermostat not working',
        category: 'Electrical',
        description: 'Water does not heat up in bathroom.',
      );

      expect(ticket.status, 'Received');
      expect(ticket.isReceived, isTrue);
      expect(ticket.isUnderExecution, isFalse);
      expect(ticket.isResolved, isFalse);

      // 2. Admin assigns electrician and marks Under execution
      final inProgressTicket = ticket.copyWith(
        status: ComplaintModel.statusUnderExecution,
        adminRemarks: 'Assigned to Sunil Verma (Electrician). Visit scheduled at 3 PM.',
      );

      expect(inProgressTicket.isReceived, isFalse);
      expect(inProgressTicket.isUnderExecution, isTrue);
      expect(inProgressTicket.isResolved, isFalse);
      expect(inProgressTicket.adminRemarks, contains('Sunil Verma'));

      // 3. Electrician completes work; Admin resolves ticket
      final resolvedTicket = inProgressTicket.copyWith(
        status: ComplaintModel.statusResolved,
        adminRemarks: 'Thermostat replaced and tested. Geyser heating properly.',
      );

      expect(resolvedTicket.isResolved, isTrue);
      expect(resolvedTicket.isUnderExecution, isFalse);
      expect(resolvedTicket.adminRemarks, contains('Thermostat replaced'));
    });
  });
}
