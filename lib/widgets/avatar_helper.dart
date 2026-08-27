import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Safely retrieves an ImageProvider for profile photos across platforms.
/// On web or for http/https URLs, it uses NetworkImage to avoid dart:io File instantiation crashes.
ImageProvider? getProfileImage(String url) {
  if (url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://') || kIsWeb) {
    return NetworkImage(url);
  }
  return FileImage(File(url));
}

/// A reusable, web-safe avatar widget for residents.
class StudentAvatar extends StatelessWidget {
  final double radius;
  final String? profilePhotoUrl;
  final String initials;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const StudentAvatar({
    super.key,
    required this.radius,
    required this.profilePhotoUrl,
    required this.initials,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = profilePhotoUrl ?? '';
    final hasPhoto = photoUrl.isNotEmpty && photoUrl != 'uploaded';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFF2563EB),
      backgroundImage: hasPhoto ? getProfileImage(photoUrl) : null,
      child: !hasPhoto
          ? Text(
              initials,
              style: textStyle ??
                  GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: radius * 0.66,
                    fontWeight: FontWeight.bold,
                  ),
            )
          : null,
    );
  }
}
