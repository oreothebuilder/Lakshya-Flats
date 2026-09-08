import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Configurable Cloudinary properties
  static String cloudName = "lakshya_cloud";
  static String uploadPreset = "lakshya_unsigned_preset";

  /// Update Cloudinary configuration dynamically
  static void configure({required String name, required String preset}) {
    cloudName = name;
    uploadPreset = preset;
  }

  /// Uploads an XFile (Image Picker result) to Cloudinary via unsigned REST API.
  /// Returns the secure HTTPS URL of the uploaded image/file.
  static Future<String?> uploadImage(
    XFile file, {
    String folder = "lakshya_app",
  }) async {
    try {
      final uri =
          Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder;

      final bytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['secure_url'] as String?;
      } else {
        debugPrint(
            "Cloudinary Upload Error (${response.statusCode}): ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Cloudinary Exception: $e");
      return null;
    }
  }

  /// Uploads raw bytes directly to Cloudinary.
  static Future<String?> uploadBytes(
    Uint8List bytes, {
    required String fileName,
    String folder = "lakshya_app",
  }) async {
    try {
      final uri =
          Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
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
        return data['secure_url'] as String?;
      } else {
        debugPrint(
            "Cloudinary Bytes Upload Error (${response.statusCode}): ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Cloudinary Exception: $e");
      return null;
    }
  }
}
