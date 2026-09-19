import 'dart:typed_data';

Future<String?> saveAndLaunchFile(Uint8List bytes, String fileName) async {
  throw UnsupportedError('Platform not supported for saving file');
}

Future<void> shareFileOrBytes(String filePathOrName, Uint8List bytes, {String? text, String? subject}) async {
  throw UnsupportedError('Platform not supported for sharing file');
}

Future<bool> triggerBrowserDownloadUrl(String url, String fileName) async {
  throw UnsupportedError('Platform not supported for downloading file url');
}
