import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/cloudinary_config.dart';
import 'services/navigation_service.dart';
import 'services/push_notification_service.dart';
import 'services/academic_year_service.dart';
import 'screens/auth_gate.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Cloudinary storage configuration
  CloudinaryConfig.init();

  // Initialize Firebase with configured platform options
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint("Firebase successfully initialized with lakshya-flats.");

    // Configure Web Auth Persistence (LOCAL -> SESSION -> NONE fallback for iOS Safari)
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
        debugPrint("Firebase Auth persistence set to LOCAL for Web");
      } catch (e) {
        debugPrint("Firebase Auth LOCAL persistence failed, falling back to SESSION: $e");
        try {
          await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
        } catch (_) {
          try {
            await FirebaseAuth.instance.setPersistence(Persistence.NONE);
            debugPrint("Firebase Auth persistence set to NONE (in-memory) for Web");
          } catch (_) {}
        }
      }
    }
  } catch (e) {
    debugPrint("Firebase initialization note: $e");
  }

  // Initialize Academic Year Service (cached preference & Firestore sync)
  try {
    await AcademicYearService.instance.initialize();
  } catch (e) {
    debugPrint("AcademicYearService initialization error: $e");
  }

  // Initialize Push Notification Service (FCM & Local Notifications)
  try {
    await PushNotificationService().initialize();
  } catch (e) {
    debugPrint("Push notification initialization error: $e");
  }

  // Global Flutter Error Interceptor - eliminates silent blank/grey screens on mobile/web
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("Global Flutter Error: ${details.exceptionAsString()}");
    debugPrint(details.stack.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("Global Async Error: $error");
    debugPrint(stack.toString());
    return true; // prevent crash
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "Rendering Notice",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    details.exceptionAsString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final nav = rootNavigatorKey.currentState;
                      if (nav != null) {
                        nav.pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text("Reload Dashboard"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003896),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const LakshyaResidencyApp());
}

class LakshyaResidencyApp extends StatelessWidget {
  const LakshyaResidencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Lakshya Residency',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const AuthGate(),
    );
  }
}
