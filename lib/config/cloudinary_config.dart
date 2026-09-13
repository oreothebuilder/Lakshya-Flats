import '../services/cloudinary_service.dart';

/// Central Cloudinary Configuration for Lakshya Residency
class CloudinaryConfig {
  /// Replace these values with your Cloudinary credentials from https://console.cloudinary.com
  /// 1. Cloud Name: Found on your Cloudinary Dashboard
  static String cloudName = "osibuv3d";
  static String uploadPreset = "lakshya-flats";

  /// Folder names for organizing uploads cleanly in Cloudinary
  static const String folderStudentDocs = "lakshya/student_documents";
  static const String folderStudentAvatars = "lakshya/student_avatars";
  static const String folderPaymentReceipts = "lakshya/payment_receipts";
  static const String folderNoticeAttachments = "lakshya/notices";
  static const String folderMessMenu = "lakshya/mess_menu";
  static const String folderExpenseInvoices = "lakshya/expenses";
  static const String folderComplaints = "lakshya/complaints";

  /// Update credentials dynamically at runtime if needed
  static void configure({required String name, required String preset}) {
    cloudName = name;
    uploadPreset = preset;
    CloudinaryService.configure(name: name, preset: preset);
  }

  /// Initialize Cloudinary credentials on app launch
  static void init() {
    CloudinaryService.configure(
      name: cloudName,
      preset: uploadPreset,
    );
  }
}
