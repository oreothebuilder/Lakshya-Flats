import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/cloudinary_service.dart';

/// Modal dialog for viewing both images and PDF documents seamlessly in-app.
/// Supports zooming, multi-page PDFs, direct downloading to device storage,
/// and launching in an external viewer or browser.
class DocumentViewerModal extends StatefulWidget {
  final String url;
  final String title;
  final Uint8List? memoryBytes;
  final String? fileName;

  const DocumentViewerModal({
    super.key,
    required this.url,
    required this.title,
    this.memoryBytes,
    this.fileName,
  });

  /// Convenient static method to present the viewer modal
  static void show(
    BuildContext context, {
    required String url,
    required String title,
    Uint8List? memoryBytes,
    String? fileName,
  }) {
    if (url.isEmpty && memoryBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No document or image available to preview."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => DocumentViewerModal(
        url: url,
        title: title,
        memoryBytes: memoryBytes,
        fileName: fileName,
      ),
    );
  }

  @override
  State<DocumentViewerModal> createState() => _DocumentViewerModalState();
}

class _DocumentViewerModalState extends State<DocumentViewerModal> {
  bool _isDownloading = false;
  bool _isPdf = false;
  late String _displayName;

  @override
  void initState() {
    super.initState();
    _isPdf = CloudinaryService.isPdf(widget.url) ||
        CloudinaryService.isPdf(widget.fileName);
    _displayName = widget.fileName ??
        CloudinaryService.getFileNameFromUrl(
          widget.url,
          fallback: widget.title.isNotEmpty ? widget.title : "document",
        );
  }

  Future<void> _handleDownload() async {
    if (widget.url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File is not uploaded to cloud yet.")),
      );
      return;
    }

    setState(() => _isDownloading = true);
    final ext = _isPdf ? ".pdf" : ".jpg";
    final targetName = _displayName.contains('.') ? _displayName : "$_displayName$ext";

    final savedPath = await CloudinaryService.downloadAndSaveFile(
      widget.url,
      fileName: targetName,
    );

    setState(() => _isDownloading = false);

    if (!mounted) return;

    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Downloaded successfully!\nSaved to: $savedPath",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "OPEN",
            textColor: Colors.white,
            onPressed: () => CloudinaryService.openUrl(widget.url),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not download file. Please check connection."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _isPdf ? "PDF Document" : "Image Media",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _isPdf ? const Color(0xFF93C5FD) : const Color(0xFF86EFAC),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            if (widget.url.isNotEmpty) ...[
              // Download Button
              IconButton(
                icon: _isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, color: Colors.white),
                tooltip: "Download to device",
                onPressed: _isDownloading ? null : _handleDownload,
              ),

              // Open in External Browser / App
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                tooltip: "Open in external browser",
                onPressed: () => CloudinaryService.openUrl(widget.url),
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 1. PDF Viewer
    if (_isPdf) {
      if (widget.memoryBytes != null) {
        return SfPdfViewer.memory(
          widget.memoryBytes!,
          canShowPaginationDialog: true,
          enableDoubleTapZooming: true,
        );
      } else if (widget.url.isNotEmpty) {
        return SfPdfViewer.network(
          widget.url,
          canShowPaginationDialog: true,
          enableDoubleTapZooming: true,
          onDocumentLoadFailed: (details) {
            debugPrint("PDF load failed: ${details.description}");
          },
        );
      }
    }

    // 2. Local Memory Bytes Image
    if (widget.memoryBytes != null) {
      return Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(
            widget.memoryBytes!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // 3. Network Image
    if (widget.url.isNotEmpty) {
      return Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, err, stack) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image_rounded,
                    size: 56,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Unable to load media preview",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => CloudinaryService.openUrl(widget.url),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: const Text("Open in Browser"),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return const Center(
      child: Text(
        "No media to display",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
