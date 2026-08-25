import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../screens/login_screen.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  StudentDirectoryItem? _currentUser;
  StudentDirectoryItem? get currentUser => _currentUser;
  set currentUser(StudentDirectoryItem? user) {
    _currentUser = user;
    notifyListeners();
  }

  // Seeding a default student if the database is empty or doesn't have this student
  Future<void> seedMockStudentIfNeeded() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: 'user@lakshya.com')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        final mockStudent = StudentDirectoryItem(
          id: 'mock_student_sudhanshu',
          name: 'Sudhanshu Kumar',
          initials: 'SU',
          status: 'Paid',
          building: 'Lakshya',
          room: '304',
          phone: '+91 8208285947',
          email: 'user@lakshya.com',
          notes: [
            'Please submit your updated ID proof by Friday.',
            'Hostel fee payment for the next semester is now open.'
          ],
          pendingAmount: 112745.0,
          regNo: '2021BCS0123',
          course: 'B.Tech',
          branch: 'Computer Science & Engineering',
          guardianName: 'Ramesh Kumar',
          guardianRelationship: 'Father',
          guardianPhone: '+91 9876543210',
          dietaryPreference: 'Veg',
          selectedPlan: 'Premium Double Sharing',
          paymentFrequency: 'Monthly',
          monthlyRent: '12500',
          securityDeposit: '15000',
        );

        await FirebaseFirestore.instance
            .collection('students')
            .doc(mockStudent.id)
            .set(mockStudent.toJson());
        
        debugPrint("Seeded mock student 'user@lakshya.com' successfully.");
      }
    } catch (e) {
      debugPrint("Failed to seed mock student: $e");
    }
  }

  Future<String?> login(String email, String password, LoginRole role) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      return "Email and password cannot be empty.";
    }

    if (role == LoginRole.manager) {
      if (trimmedEmail.toLowerCase() == 'manager@lakshya.com' && trimmedPassword == 'password123') {
        _currentUser = null; // Manager doesn't have a StudentDirectoryItem
        notifyListeners();
        return null; // Success
      } else {
        return "Invalid credentials for Manager.";
      }
    } else {
      // User login
      if (trimmedPassword != 'password123') {
        return "Incorrect password.";
      }

      // Ensure mock student is seeded
      await seedMockStudentIfNeeded();

      try {
        final query = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: trimmedEmail.toLowerCase())
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          // Try a case-sensitive fallback or exact match if case-insensitive query didn't succeed
          final queryFallback = await FirebaseFirestore.instance
              .collection('students')
              .where('email', isEqualTo: trimmedEmail)
              .limit(1)
              .get();
              
          if (queryFallback.docs.isEmpty) {
            return "No student found with email '$trimmedEmail'.";
          } else {
            _currentUser = StudentDirectoryItem.fromJson(queryFallback.docs.first.data());
            notifyListeners();
            return null; // Success
          }
        }

        _currentUser = StudentDirectoryItem.fromJson(query.docs.first.data());
        notifyListeners();
        return null; // Success
      } catch (e) {
        return "Database error during login: $e";
      }
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
