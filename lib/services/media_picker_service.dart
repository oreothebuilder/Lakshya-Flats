import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'cloudinary_service.dart';

class UploadedMediaResult {
  final String url;
  final String fileName;
  final bool isPdf;
  final Uint8List? localBytes;

  UploadedMediaResult({
    required this.url,
    required this.fileName,
    required this.isPdf,
    this.localBytes,
  });
}

class MediaPickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Shows a clean bottom sheet allowing user to choose Camera, Gallery, or PDF document.
  /// Handles the upload to Cloudinary and returns [UploadedMediaResult], or null if cancelled.
  static Future<UploadedMediaResult?> showPickerAndUpload({
    required BuildContext context,
    required String title,
    required String folder,
    bool allowPdf = true,
  }) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),

              // 1. Camera Option
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0056D2), size: 22),
                ),
                title: Text(
                  "Take Photo with Camera",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                subtitle: Text(
                  "Capture a new photo from your camera",
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                onTap: () => Navigator.pop(ctx, "camera"),
              ),

              // 2. Gallery Option
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF475569), size: 22),
                ),
                title: Text(
                  "Choose Image from Gallery",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                subtitle: Text(
                  "Select JPG or PNG from device photo library",
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                onTap: () => Navigator.pop(ctx, "gallery"),
              ),

              // 3. PDF Document Option
              if (allowPdf)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 22),
                  ),
                  title: Text(
                    "Select PDF Document",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    "Upload official PDF document or agreement",
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                  onTap: () => Navigator.pop(ctx, "pdf"),
                ),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !context.mounted) return null;

    // Execute selection
    try {
      if (choice == "camera" || choice == "gallery") {
        final XFile? file = await _imagePicker.pickImage(
          source: choice == "camera" ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );
        if (file == null) return null;

        final bytes = await file.readAsBytes();
        final url = await CloudinaryService.uploadBytes(
          bytes,
          fileName: file.name,
          folder: folder,
        );

        if (url == null) return null;
        return UploadedMediaResult(
          url: url,
          fileName: file.name,
          isPdf: false,
          localBytes: bytes,
        );
      } else if (choice == "pdf") {
        final file = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (file == null) return null;
        final bytes = await file.readAsBytes();
        final url = await CloudinaryService.uploadBytes(
          bytes,
          fileName: file.name,
          folder: folder,
        );

        if (url == null) return null;
        return UploadedMediaResult(
          url: url,
          fileName: file.name,
          isPdf: true,
          localBytes: bytes,
        );
      }
    } catch (e) {
      debugPrint("showPickerAndUpload error: $e");
    }

    return null;
  }
}
