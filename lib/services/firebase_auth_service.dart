import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_role_model.dart';
import 'firestore_service.dart';

class FirebaseAuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Direct Google Identity Toolkit REST API credential check
  /// Accurately verifies credentials without triggering WebKit IndexedDB/storage issues on iOS Safari
  static Future<Map<String, dynamic>?> verifyCredentialsViaRest({
    required String email,
    required String password,
  }) async {
    try {
      const apiKey = 'AIzaSyASkAtM4zYs8sDR9LPeSPzPsEUMw3rKsVM';
      final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          'returnSecureToken': true,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'uid': data['localId']?.toString(),
          'email': data['email']?.toString(),
          'idToken': data['idToken']?.toString(),
          'refreshToken': data['refreshToken']?.toString(),
        };
      } else {
        final data = jsonDecode(res.body);
        final err = data['error']?['message']?.toString() ?? '';
        debugPrint("Identity Toolkit REST error: $err");
        if (err.contains('INVALID_LOGIN_CREDENTIALS') ||
            err.contains('INVALID_PASSWORD')) {
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: "Incorrect password or credentials. Please try again.",
          );
        } else if (err.contains('EMAIL_NOT_FOUND')) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: "No account found with this email address.",
          );
        } else if (err.contains('USER_DISABLED')) {
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: "This account has been disabled by the administrator.",
          );
        } else if (err.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
          throw FirebaseAuthException(
            code: 'too-many-requests',
            message: "Too many attempts. Please wait a moment before trying again.",
          );
        }
      }
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      debugPrint("verifyCredentialsViaRest notice: $e");
    }
    return null;
  }

  /// Stream of user authentication state changes
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges().handleError((e) {
        debugPrint("Auth state stream error: $e");
        return null;
      });
    } catch (e) {
      debugPrint("Auth state stream error: $e");
      return Stream.value(null);
    }
  }

  /// Currently signed in user
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Retrieve the current logged in user with their verified role from Firestore
  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;
    return await FirestoreService().getAppUser(user.uid, emailHint: user.email);
  }

  /// Resolve email from identifier (supports Email or Student Registration Number)
  Future<String> resolveEmailFromIdentifier(String rawIdentifier) async {
    final clean = rawIdentifier.trim();
    if (clean.isEmpty) {
      throw Exception("Please enter your email or registration number.");
    }

    // Special case for primary admin username / aliases
    final lowerClean = clean.toLowerCase();
    if (lowerClean == "lakshyaresidency" ||
        lowerClean == "lakshya" ||
        lowerClean == "admin") {
      return "lakshyaresidency@gmail.com";
    }
    if (lowerClean == "sudhansu1906") {
      return "sudhansu1906@gmail.com";
    }

    // Direct email format
    if (clean.contains('@')) {
      return clean.toLowerCase();
    }

    // 1. Fast, unauthenticated check in registration_lookup
    final lookup = await FirestoreService().getRegistrationLookup(clean);
    if (lookup != null && lookup['email'] != null && lookup['email'].toString().isNotEmpty) {
      return lookup['email'].toString().toLowerCase().trim();
    }

    // 2. Treat as student registration number - lookup student in Firestore
    final studentData = await FirestoreService().findStudentByRegNoOrEmail(clean);
    if (studentData != null && studentData['email'] != null && studentData['email'].toString().isNotEmpty) {
      return studentData['email'].toString().toLowerCase().trim();
    }

    // If not found as registration number, append default domain or throw
    throw Exception("No resident or staff account found with Registration Number \"$clean\".");
  }

  /// Unified Sign In with Email OR Student Registration Number
  Future<AppUser> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u00A0]'), '')
        .trim();
    final cleanPassword = password
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u00A0]'), '')
        .trim();

    final resolvedEmail = await resolveEmailFromIdentifier(cleanIdentifier);
    
    UserCredential? credential;
    Map<String, dynamic>? restVerifiedUser;

    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: cleanPassword,
      );
    } catch (rawError) {
      debugPrint("Primary signInWithEmailAndPassword note: $rawError");

      // On Web (specifically iOS Safari / WebKit where IndexedDB or storage can fail),
      // verify credentials with Google Identity Toolkit REST API
      if (kIsWeb) {
        try {
          restVerifiedUser = await verifyCredentialsViaRest(
            email: resolvedEmail,
            password: cleanPassword,
          );
          if (restVerifiedUser != null) {
            debugPrint("Credentials verified via REST API for ${restVerifiedUser['email']}");
            // Credentials are valid! Retry _auth with Persistence.NONE to set in-memory session
            try {
              await _auth.setPersistence(Persistence.NONE);
              credential = await _auth.signInWithEmailAndPassword(
                email: resolvedEmail,
                password: cleanPassword,
              );
              debugPrint("Retry with Persistence.NONE succeeded!");
            } catch (retryErr) {
              debugPrint("Retry with Persistence.NONE note: $retryErr");
            }
          }
        } catch (restErr) {
          if (restErr is FirebaseAuthException) {
            rethrow;
          }
        }
      }

      if (credential == null && restVerifiedUser == null) {
        FirebaseAuthException authError;
        if (rawError is FirebaseAuthException) {
          authError = rawError;
        } else {
          final errStr = rawError.toString();
          if (errStr.contains('INVALID_LOGIN_CREDENTIALS') ||
              errStr.contains('invalid-credential') ||
              errStr.contains('wrong-password')) {
            authError = FirebaseAuthException(
              code: 'invalid-credential',
              message: "Incorrect password or credentials. Please try again.",
            );
          } else if (errStr.contains('user-not-found')) {
            authError = FirebaseAuthException(
              code: 'user-not-found',
              message: "No user found with this email.",
            );
          } else {
            rethrow;
          }
        }

        // If primary admin and account doesn't exist in Firebase Auth yet, auto-provision on first setup
        if (FirestoreService().isPrimaryAdminEmail(resolvedEmail) &&
            authError.code == 'user-not-found') {
          if (resolvedEmail == "lakshyaresidency@gmail.com" && cleanPassword != "India@1234") {
            throw FirebaseAuthException(
              code: 'wrong-password',
              message: "Incorrect password for admin account. Password is India@1234.",
            );
          }
          try {
            credential = await _auth.createUserWithEmailAndPassword(
              email: resolvedEmail,
              password: cleanPassword,
            );
          } on FirebaseAuthException catch (createError) {
            if (createError.code == 'email-already-in-use') {
              throw FirebaseAuthException(
                code: 'wrong-password',
                message: "Incorrect password for admin account. If you forgot your password, tap 'Forgot Password?' below.",
              );
            }
            rethrow;
          } catch (_) {
            rethrow;
          }
        } else if (FirestoreService().isPrimaryAdminEmail(resolvedEmail) &&
                   (authError.code == 'wrong-password' || authError.code == 'invalid-credential')) {
          throw FirebaseAuthException(
            code: 'wrong-password',
            message: "Incorrect password for admin account. Please verify your password.",
          );
        } else if (authError.code == 'user-not-found' || authError.code == 'invalid-credential') {
          // Resident student auto-provisioning fallback:
          // Check registration_lookup first (works unauthenticated), then users collection
          var studentData = await FirestoreService().getRegistrationLookup(resolvedEmail);
          studentData ??= await FirestoreService().findStudentByRegNoOrEmail(resolvedEmail);

          if (studentData != null) {
            final rawFirst = (studentData['firstName'] ?? '').toString().trim();
            final rawReg = (studentData['registrationNumber'] ?? studentData['regNo'] ?? '').toString().trim();
            final defaultFormulaPassword = "$rawFirst@$rawReg".trim();
            final storedDefaultPassword = (studentData['defaultPassword'] ?? defaultFormulaPassword).toString().trim();

            final isPasswordCorrect = password.trim() == storedDefaultPassword ||
                password.trim() == defaultFormulaPassword ||
                (storedDefaultPassword.isNotEmpty && password.trim().toLowerCase() == storedDefaultPassword.toLowerCase()) ||
                (defaultFormulaPassword.isNotEmpty && password.trim().toLowerCase() == defaultFormulaPassword.toLowerCase());

            if (isPasswordCorrect) {
              try {
                credential = await _auth.createUserWithEmailAndPassword(
                  email: resolvedEmail,
                  password: password.trim(),
                );
              } on FirebaseAuthException catch (createError) {
                if (createError.code == 'email-already-in-use') {
                  throw FirebaseAuthException(
                    code: 'wrong-password',
                    message: "Incorrect password for student resident account.",
                  );
                }
                rethrow;
              }
            } else {
              throw FirebaseAuthException(
                code: 'wrong-password',
                message: "Incorrect password. Default password is: FirstName@RegistrationNumber",
              );
            }
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }
    }

    final uid = credential?.user?.uid ?? restVerifiedUser?['uid'];
    if (uid == null) {
      throw Exception("Authentication failed. Unable to identify user.");
    }

    // Fetch user profile and role from Firestore
    final appUser = await FirestoreService().getAppUser(uid, emailHint: resolvedEmail);
    if (appUser == null) {
      // In case user exists in Auth but not Firestore yet, bootstrap fallback
      if (FirestoreService().isPrimaryAdminEmail(resolvedEmail)) {
        await FirestoreService().bootstrapPrimaryAdmin(uid, resolvedEmail);
        return AppUser(
          uid: uid,
          email: resolvedEmail,
          fullName: resolvedEmail.toLowerCase().contains("sudhansu")
              ? "Sudhanshu (Super Admin)"
              : "Lakshya Admin (Super Admin)",
          role: AppRole.admin,
        );
      }
      throw Exception("User profile not found in residency records. Contact administrator.");
    }

    // Edge case: Account Suspended or Inactive
    if (appUser.status.toLowerCase() == 'inactive' || appUser.status.toLowerCase() == 'suspended') {
      await signOut();
      throw Exception("Your account has been deactivated. Please contact hostel administration.");
    }

    return appUser;
  }

  /// Sign in directly with Email & Password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Sign In Exception (${e.code}): ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Generic Auth Sign In Exception: $e");
      rethrow;
    }
  }

  /// Create student auth account safely without disrupting current admin session
  Future<UserCredential?> createStudentAuthAccount({
    required String email,
    required String password,
  }) async {
    FirebaseApp? tempApp;
    try {
      final appName = 'StudentCreationApp_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await tempAuth.signOut();
      return credential;
    } catch (e) {
      debugPrint("createStudentAuthAccount secondary app notice: $e");
      // If secondary app creation is unavailable, the student will safely auto-provision
      // upon first sign-in using their registered credentials in signInWithIdentifier
      // without disrupting the active admin session!
      return null;
    } finally {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }
    }
  }

  /// Create new account with Email & Password
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Registration Exception (${e.code}): ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Generic Auth Registration Exception: $e");
      rethrow;
    }
  }

  /// Send Password Reset Email (with direct REST fallback for iOS Safari & Web)
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    if (kIsWeb) {
      try {
        const apiKey = 'AIzaSyASkAtM4zYs8sDR9LPeSPzPsEUMw3rKsVM';
        final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$apiKey');
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'requestType': 'PASSWORD_RESET',
            'email': cleanEmail,
          }),
        );
        if (res.statusCode == 200) {
          debugPrint("Password reset email sent via Identity Toolkit REST to $cleanEmail");
          return;
        } else {
          final data = jsonDecode(res.body);
          final err = data['error']?['message']?.toString() ?? '';
          if (err.contains('EMAIL_NOT_FOUND')) {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: "No account found with this email address.",
            );
          } else if (err.contains('INVALID_EMAIL')) {
            throw FirebaseAuthException(
              code: 'invalid-email',
              message: "The email address is formatted improperly.",
            );
          }
        }
      } catch (e) {
        if (e is FirebaseAuthException) rethrow;
        debugPrint("REST password reset attempt note: $e");
      }
    }

    try {
      await _auth.sendPasswordResetEmail(email: cleanEmail);
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Password Reset Exception (${e.code}): ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Generic Auth Password Reset Exception: $e");
      rethrow;
    }
  }

  /// Change user password after validating current password via re-authentication
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User is not signed in.");
    }
    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      throw Exception("User account does not have an email address associated with it.");
    }

    // 1. Re-authenticate user with their current password to refresh credentials
    // and prevent [firebase_auth/requires-recent-login] exceptions
    final cred = EmailAuthProvider.credential(
      email: email.trim(),
      password: currentPassword.trim(),
    );

    try {
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("Current password is incorrect. Please try again.");
      } else if (e.code == 'too-many-requests') {
        throw Exception("Too many attempts. Please wait a few moments before trying again.");
      }
      throw Exception(e.message ?? "Failed to verify current password.");
    }

    // 2. Update to new password
    try {
      await user.updatePassword(newPassword.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception("New password is too weak. Please use at least 6 characters.");
      } else if (e.code == 'requires-recent-login') {
        throw Exception("Recent authentication required. Please sign out and log in again.");
      }
      throw Exception(e.message ?? "Failed to update password.");
    }
  }

  /// Sign Out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Firebase Auth Sign Out Exception: $e");
      rethrow;
    }
  }

  /// Helper to convert Firebase Auth exceptions into clean user-friendly messages
  static String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return "No account found with this email address.";
        case 'wrong-password':
        case 'invalid-credential':
          return "Incorrect password or credentials. Please try again.";
        case 'invalid-email':
          return "The email address is formatted improperly.";
        case 'user-disabled':
          return "This account has been disabled by the administrator.";
        case 'email-already-in-use':
          return "An account already exists for this email.";
        case 'weak-password':
          return "The password is too weak. Use at least 6 characters.";
        case 'requires-recent-login':
          return "Security check required: please verify your current password.";
        case 'too-many-requests':
          return "Too many attempts. Please wait a moment before trying again.";
        case 'network-request-failed':
          return "Network connection error. Check your internet connection.";
        default:
          return error.message ?? "Authentication failed. Please verify your details.";
      }
    }
    String msg = error?.toString() ?? "An unexpected error occurred.";
    if (msg.startsWith("Exception: ")) {
      msg = msg.substring("Exception: ".length);
    }
    return msg;
  }
}
