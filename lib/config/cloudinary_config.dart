import '../services/cloudinary_service.dart';

/// Central Cloudinary Configuration for Lakshya Residency
class CloudinaryConfig {
  /// Replace these values with your Cloudinary credentials from https://console.cloudinary.com
  /// 1. Cloud Name: Found on your Cloudinary Dashboard
  /// 2. Upload Preset: Created under Settings -> Upload -> Add Upload Preset (Set Mode to "Unsigned")
  static const String cloudName = "lakshya_cloud";
  static const String uploadPreset = "lakshya_unsigned_preset";

  /// Folder names for organizing uploads in Cloudinary
  static const String folderStudentDocs = "lakshya/student_documents";
  static const String folderStudentAvatars = "lakshya/student_avatars";
  static const String folderPaymentReceipts = "lakshya/payment_receipts";
  static const String folderNoticeAttachments = "lakshya/notices";
  static const String folderMessMenu = "lakshya/mess_menu";

  /// Initialize Cloudinary credentials on app launch
  static void init() {
    CloudinaryService.configure(
      name: cloudName,
      preset: uploadPreset,
    );
  }
}
