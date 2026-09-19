import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> saveAndLaunchFile(Uint8List bytes, String fileName) async {
  final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
  File? file;

  // 1. Android: Directly save to public /storage/emulated/0/Download WITHOUT prompting file manager
  if (Platform.isAndroid) {
    final candidateDirs = [
      Directory('/storage/emulated/0/Download'),
      Directory('/sdcard/Download'),
    ];

    for (final dir in candidateDirs) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final target = File('${dir.path}/$safeName');
        await target.writeAsBytes(bytes, flush: true);
        if (await target.exists() && await target.length() > 0) {
          file = target;
          debugPrint("Automatically saved to public Android Downloads: ${file.path}");
          break;
        }
      } catch (e) {
        debugPrint("Writing to ${dir.path} failed: $e");
      }
    }

    // Android external storage downloads fallback
    if (file == null) {
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDirs != null && extDirs.isNotEmpty) {
          final target = File('${extDirs.first.path}/$safeName');
          await target.writeAsBytes(bytes, flush: true);
          if (await target.exists()) {
            file = target;
            debugPrint("Saved to ExternalStorageDirectory downloads: ${file.path}");
          }
        }
      } catch (e) {
        debugPrint("ExternalStorageDirectory fallback error: $e");
      }
    }

    if (file == null) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final target = File('${extDir.path}/$safeName');
          await target.writeAsBytes(bytes, flush: true);
          if (await target.exists()) {
            file = target;
            debugPrint("Saved to ExternalStorageDirectory: ${file.path}");
          }
        }
      } catch (e) {
        debugPrint("ExternalStorageDirectory error: $e");
      }
    }
  }

  // 2. Desktop (Windows / macOS / Linux): Automatically save to user's Downloads folder
  if (file == null && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final target = File('${downloadsDir.path}\\$safeName');
        await target.writeAsBytes(bytes, flush: true);
        if (await target.exists()) {
          file = target;
          debugPrint("Automatically saved to Desktop Downloads: ${file.path}");
        }
      }
    } catch (e) {
      debugPrint("Desktop Downloads automatic save failed: $e");
    }
  }

  // 3. General App Storage Fallback
  if (file == null) {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final target = File('${dir.path}/$safeName');
      await target.writeAsBytes(bytes, flush: true);
      file = target;
      debugPrint("Saved to app documents fallback: ${file.path}");
    } catch (e) {
      debugPrint("App documents save failed: $e");
    }
  }

  // 4. Automatically open/launch the saved file so the user can immediately view & use it
  if (file != null && await file.exists()) {
    try {
      final openResult = await OpenFilex.open(file.path);
      debugPrint("OpenFilex result: ${openResult.type} - ${openResult.message}");
    } catch (e) {
      debugPrint("OpenFilex exception: $e");
    }
  }

  return file?.path;
}

Future<void> shareFileOrBytes(String filePathOrName, Uint8List bytes, {String? text, String? subject}) async {
  try {
    final file = File(filePathOrName);
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: text,
          subject: subject,
        ),
      );
      return;
    }
  } catch (_) {}

  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: filePathOrName)],
        text: text,
        subject: subject,
      ),
    );
  } catch (e) {
    debugPrint("shareFileOrBytes IO Error: $e");
  }
}

Future<bool> triggerBrowserDownloadUrl(String url, String fileName) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final res = await saveAndLaunchFile(response.bodyBytes, fileName);
      return res != null;
    }
  } catch (e) {
    debugPrint("triggerBrowserDownloadUrl IO Error: $e");
  }
  return false;
}
