// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> saveAndLaunchFile(Uint8List bytes, String fileName) async {
  final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');

  String mimeType = 'application/octet-stream';
  final lower = safeName.toLowerCase();
  if (lower.endsWith('.pdf')) {
    mimeType = 'application/pdf';
  } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    mimeType = 'image/jpeg';
  } else if (lower.endsWith('.png')) {
    mimeType = 'image/png';
  }

  try {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = safeName
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.dispatchEvent(html.MouseEvent('click', canBubble: true, cancelable: true));
    anchor.click();

    // Do NOT remove synchronously! Delay removal so the browser processes the click completely
    Timer(const Duration(seconds: 5), () {
      try {
        anchor.remove();
      } catch (_) {}
    });

    // Delay revocation to ensure download stream completes
    Timer(const Duration(seconds: 60), () {
      try {
        html.Url.revokeObjectUrl(url);
      } catch (_) {}
    });

    return safeName;
  } catch (e) {
    debugPrint("saveAndLaunchFile Web Error: $e");
    return null;
  }
}

Future<bool> triggerBrowserDownloadUrl(String url, String fileName) async {
  try {
    final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final anchor = html.AnchorElement(href: url)
      ..download = safeName
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.dispatchEvent(html.MouseEvent('click', canBubble: true, cancelable: true));
    anchor.click();

    Timer(const Duration(seconds: 5), () {
      try {
        anchor.remove();
      } catch (_) {}
    });
    return true;
  } catch (e) {
    debugPrint("triggerBrowserDownloadUrl Web Error: $e");
    return false;
  }
}

Future<void> shareFileOrBytes(String filePathOrName, Uint8List bytes, {String? text, String? subject}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: filePathOrName)],
        text: text,
        subject: subject,
      ),
    );
  } catch (e) {
    debugPrint("shareFileOrBytes Web Error: $e");
  }
}
