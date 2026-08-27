import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  // Cloudinary credentials configuration.
  // Replace these with your actual Cloudinary Cloud Name and Unsigned Upload Preset.
  static const String cloudName = 'gyqt9z0e'; 
  static const String uploadPreset = 'lakshya_unsigned';

  /// Uploads raw image bytes to Cloudinary and returns the secure URL.
  /// Works seamlessly on Web, Android, iOS, and Desktop.
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
    String folder = 'students',
  }) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename,
          ),
        );

      if (kDebugMode) {
        print("Uploading $filename to Cloudinary cloud $cloudName...");
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(responseBody);
        final secureUrl = decoded['secure_url'] as String;
        if (kDebugMode) {
          print("Cloudinary upload successful. URL: $secureUrl");
        }
        return secureUrl;
      } else {
        throw Exception(
          "Cloudinary upload failed with status ${response.statusCode}: $responseBody",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error in CloudinaryService: $e");
      }
      rethrow;
    }
  }
}
