import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CloudinaryService {
  // Configurable Cloudinary properties
  static String cloudName = "osibuv3d";
  static String uploadPreset = "lakshya-flats";

  /// Update Cloudinary configuration dynamically
  static void configure({required String name, required String preset}) {
    cloudName = name;
    uploadPreset = preset;
  }

  /// Checks if a given file name or URL represents a PDF document
  static bool isPdf(String? urlOrName) {
    if (urlOrName == null || urlOrName.trim().isEmpty) return false;
    final clean = urlOrName.trim().toLowerCase().split('?').first;
    return clean.endsWith('.pdf');
  }

  /// Extracts a friendly display file name from a URL or fallback
  static String getFileNameFromUrl(String url, {String fallback = "document"}) {
    try {
      final uri = Uri.parse(url);
      final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : fallback;
      return segment.isNotEmpty ? segment : fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Uploads raw bytes directly to Cloudinary using `/auto/upload`.
  /// Automatically handles images (JPG, PNG, WEBP), PDFs, and other media.
  static Future<String?> uploadBytes(
    Uint8List bytes, {
    required String fileName,
    String folder = "lakshya_app",
    String resourceType = "auto",
  }) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload",
      );
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder;

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final secureUrl = data['secure_url'] as String?;
        debugPrint("Cloudinary Upload Success ($fileName): $secureUrl");
        return secureUrl;
      } else {
        debugPrint(
          "Cloudinary Upload Error (${response.statusCode}): ${response.body}",
        );
        return null;
      }
    } catch (e) {
      debugPrint("Cloudinary Upload Exception: $e");
      return null;
    }
  }

  /// Uploads an XFile (from ImagePicker) to Cloudinary.
  /// Backward-compatible with all existing callers.
  static Future<String?> uploadImage(
    XFile file, {
    String folder = "lakshya_app",
  }) async {
    try {
      final bytes = await file.readAsBytes();
      return await uploadBytes(
        bytes,
        fileName: file.name,
        folder: folder,
      );
    } catch (e) {
      debugPrint("Cloudinary uploadImage Exception: $e");
      return null;
    }
  }

  /// Uploads a PlatformFile (from FilePicker) to Cloudinary.
  static Future<String?> uploadPlatformFile(
    PlatformFile file, {
    String folder = "lakshya_app",
  }) async {
    try {
      final bytes = await file.readAsBytes();
      return await uploadBytes(
        bytes,
        fileName: file.name,
        folder: folder,
      );
    } catch (e) {
      debugPrint("Cloudinary uploadPlatformFile Exception: $e");
      return null;
    }
  }

  /// Downloads a file/PDF from a given URL and saves it to local device storage.
  /// Returns the absolute saved file path if successful.
  static Future<String?> downloadAndSaveFile(
    String url, {
    required String fileName,
  }) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint("Failed to download file from $url (${response.statusCode})");
        return null;
      }

      Directory? dir;
      if (!kIsWeb && Platform.isAndroid) {
        dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      } else if (!kIsWeb) {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) return null;

      // Clean file name
      final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final targetFile = File("${dir.path}/$safeName");
      await targetFile.writeAsBytes(response.bodyBytes);
      debugPrint("File downloaded and saved to: ${targetFile.path}");
      return targetFile.path;
    } catch (e) {
      debugPrint("downloadAndSaveFile Exception: $e");
      return null;
    }
  }

  /// Opens an external URL (PDF, document, web link) in default browser/viewer.
  static Future<bool> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("openUrl Exception: $e");
    }
    return false;
  }
}
