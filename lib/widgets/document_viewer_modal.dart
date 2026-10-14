import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/cloudinary_service.dart';
import '../services/platform_file_saver.dart';
import 'app_toast.dart';

/// Modal dialog for viewing both images and PDF documents seamlessly in-app.
/// Supports zooming, multi-page PDFs, direct downloading to device storage,
/// and launching in an external viewer or browser.
class DocumentViewerModal extends StatefulWidget {
  final String url;
  final String title;
  final Uint8List? memoryBytes;
  final String? fileName;
  final Future<Uint8List?> Function()? onGenerateFallbackBytes;

  const DocumentViewerModal({
    super.key,
    required this.url,
    required this.title,
    this.memoryBytes,
    this.fileName,
    this.onGenerateFallbackBytes,
  });

  /// Convenient static method to present the viewer modal
  static void show(
    BuildContext context, {
    required String url,
    required String title,
    Uint8List? memoryBytes,
    String? fileName,
    Future<Uint8List?> Function()? onGenerateFallbackBytes,
  }) {
    if (url.isEmpty && memoryBytes == null && onGenerateFallbackBytes == null) {
      AppToast.showError(context, "No document or image available to preview.");
      return;
    }

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => DocumentViewerModal(
          url: url,
          title: title,
          memoryBytes: memoryBytes,
          fileName: fileName,
          onGenerateFallbackBytes: onGenerateFallbackBytes,
        ),
      ),
    );
  }

  @override
  State<DocumentViewerModal> createState() => _DocumentViewerModalState();
}

class _DocumentViewerModalState extends State<DocumentViewerModal> {
  bool _isDownloading = false;
  bool _isSharing = false;
  bool _isPdf = false;
  bool _loadFailed = false;
  bool _isLoadingFallback = false;
  String? _loadErrorMessage;
  late String _displayName;
  Uint8List? _cachedBytes;

  @override
  void initState() {
    super.initState();
    _cachedBytes = widget.memoryBytes;
    _isPdf = CloudinaryService.isPdf(widget.url) ||
        CloudinaryService.isPdf(widget.fileName) ||
        widget.onGenerateFallbackBytes != null;
    _displayName = widget.fileName ??
        CloudinaryService.getFileNameFromUrl(
          widget.url,
          fallback: widget.title.isNotEmpty ? widget.title : "document",
        );
  }

  Future<Uint8List?> _getBytes() async {
    if (_cachedBytes != null && _cachedBytes!.isNotEmpty) return _cachedBytes;
    if (widget.memoryBytes != null && widget.memoryBytes!.isNotEmpty) {
      _cachedBytes = widget.memoryBytes;
      return _cachedBytes;
    }
    final cleanUrl = widget.url.trim();
    if (cleanUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(cleanUrl));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          _cachedBytes = res.bodyBytes;
          return _cachedBytes;
        }
      } catch (e) {
        debugPrint("Error fetching bytes: $e");
      }
    }
    if (widget.onGenerateFallbackBytes != null) {
      try {
        final generated = await widget.onGenerateFallbackBytes!();
        if (generated != null && generated.isNotEmpty) {
          _cachedBytes = generated;
          return _cachedBytes;
        }
      } catch (e) {
        debugPrint("Fallback generation error: $e");
      }
    }
    return null;
  }

  Future<void> _handleShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final bytes = await _getBytes();
      final ext = _isPdf ? ".pdf" : ".jpg";
      final targetName = _displayName.contains('.') ? _displayName : "$_displayName$ext";

      if (bytes != null && bytes.isNotEmpty) {
        await shareFileOrBytes(
          targetName,
          bytes,
          text: widget.url.isNotEmpty ? widget.url : null,
          subject: widget.title,
        );
      } else if (widget.url.isNotEmpty) {
        await shareFileOrBytes(
          targetName,
          Uint8List(0),
          text: widget.url,
          subject: widget.title,
        );
      } else {
        if (mounted) {
          AppToast.showError(context, "Unable to fetch file for sharing.");
        }
      }
    } catch (e) {
      debugPrint("Error sharing: $e");
      if (mounted) {
        AppToast.showError(context, "Share error: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    final ext = _isPdf ? ".pdf" : ".jpg";
    final targetName = _displayName.contains('.') ? _displayName : "$_displayName$ext";

    try {
      // 1. Try to fetch or generate local bytes first.
      // This works on both Web (via in-memory Blob download) and IO (via device Downloads).
      final bytes = await _getBytes();
      if (bytes != null && bytes.isNotEmpty) {
        final savedPath = await saveAndLaunchFile(bytes, targetName);
        setState(() => _isDownloading = false);
        if (!mounted) return;

        if (savedPath != null) {
          AppToast.showSuccess(context, "${_isPdf ? 'Document' : 'Image'} saved to Downloads");
        } else {
          AppToast.showError(context, "Could not save file to device.");
        }
        return;
      }

      // 2. If bytes could not be fetched directly (e.g. CORS/ACL on remote server), fall back to Cloudinary download URL
      if (widget.url.isNotEmpty) {
        final downloadUrl = CloudinaryService.getAttachmentDownloadUrl(widget.url, fileName: targetName);
        if (kIsWeb) {
          await triggerBrowserDownloadUrl(downloadUrl, targetName);
        } else {
          await CloudinaryService.openUrl(downloadUrl);
        }
        setState(() => _isDownloading = false);
        if (mounted) {
          AppToast.showSuccess(context, "${_isPdf ? 'Document' : 'Image'} download initiated");
        }
        return;
      }

      setState(() => _isDownloading = false);
      if (!mounted) return;
      AppToast.showError(context, "Could not download file. Please check connection.");
    } catch (e) {
      setState(() => _isDownloading = false);
      if (!mounted) return;
      AppToast.showError(context, "Download error: $e");
    }
  }

  Future<void> _handleOpenInBrowser() async {
    final cleanUrl = widget.url.trim();
    if (cleanUrl.isEmpty) {
      AppToast.showError(context, "No URL available to open.");
      return;
    }
    final success = await CloudinaryService.openUrl(cleanUrl);
    if (!success && mounted) {
      AppToast.showError(context, "Could not open link in external browser.");
    }
  }

  void _handleClose() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: "Close",
            onPressed: _handleClose,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
            if (widget.url.isNotEmpty || widget.memoryBytes != null) ...[
              // Share Button
              IconButton(
                icon: _isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share_rounded, color: Colors.white),
                tooltip: "Share / Export",
                onPressed: (_isSharing || _isDownloading) ? null : _handleShare,
              ),

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
                onPressed: (_isDownloading || _isSharing) ? null : _handleDownload,
              ),

              if (widget.url.isNotEmpty)
                // Open in External Browser / App
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                  tooltip: "Open in external browser",
                  onPressed: _handleOpenInBrowser,
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

  Future<void> _tryTriggerFallback() async {
    if (_cachedBytes != null || widget.onGenerateFallbackBytes == null) return;
    setState(() => _isLoadingFallback = true);
    try {
      final bytes = await widget.onGenerateFallbackBytes!();
      if (bytes != null && bytes.isNotEmpty && mounted) {
        setState(() {
          _cachedBytes = bytes;
          _isLoadingFallback = false;
          _loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFallback = false);
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 56,
              color: Color(0xFFFBBF24),
            ),
            const SizedBox(height: 14),
            Text(
              "Unable to load document preview",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadErrorMessage?.contains("401") == true
                  ? "Cloudinary PDF delivery is restricted (ACL deny). Enable 'Allow delivery of PDF and ZIP files' in Cloudinary Settings -> Security, or download directly below."
                  : (_loadErrorMessage ?? "The document could not be retrieved from the server."),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _loadFailed = false;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleDownload,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text("Download PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 1. PDF Viewer
    if (_isPdf) {
      if (_cachedBytes != null && _cachedBytes!.isNotEmpty) {
        return SfPdfViewer.memory(
          _cachedBytes!,
          canShowPaginationDialog: true,
          enableDoubleTapZooming: true,
        );
      } else if (widget.memoryBytes != null && widget.memoryBytes!.isNotEmpty) {
        return SfPdfViewer.memory(
          widget.memoryBytes!,
          canShowPaginationDialog: true,
          enableDoubleTapZooming: true,
        );
      } else if (_loadFailed) {
        return _buildErrorState();
      } else if (_isLoadingFallback) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                "Loading document preview...",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        );
      } else if (widget.url.isNotEmpty) {
        return SfPdfViewer.network(
          widget.url,
          canShowPaginationDialog: true,
          enableDoubleTapZooming: true,
          onDocumentLoadFailed: (details) async {
            debugPrint("PDF load failed: ${details.description}");
            if (widget.onGenerateFallbackBytes != null && mounted) {
              setState(() => _isLoadingFallback = true);
              try {
                final bytes = await widget.onGenerateFallbackBytes!();
                if (bytes != null && bytes.isNotEmpty && mounted) {
                  setState(() {
                    _cachedBytes = bytes;
                    _isLoadingFallback = false;
                    _loadFailed = false;
                  });
                  return;
                }
              } catch (e) {
                debugPrint("Fallback generation error: $e");
              }
            }
            if (mounted) {
              setState(() {
                _loadFailed = true;
                _loadErrorMessage = details.description;
                _isLoadingFallback = false;
              });
            }
          },
        );
      } else if (widget.onGenerateFallbackBytes != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _tryTriggerFallback());
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
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
