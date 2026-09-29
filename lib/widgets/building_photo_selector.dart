import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/media_picker_service.dart';
import '../config/cloudinary_config.dart';
import 'app_toast.dart';

/// Direct Building Photo Uploader without catalog dependencies.
/// Allows uploading a fresh photo for the building directly from camera/gallery
/// or specifying an image URL.
class BuildingPhotoSelector extends StatefulWidget {
  final String initialAsset;
  final TextEditingController customImageController;
  final ValueChanged<String> onAssetChanged;

  const BuildingPhotoSelector({
    super.key,
    required this.initialAsset,
    required this.customImageController,
    required this.onAssetChanged,
  });

  @override
  State<BuildingPhotoSelector> createState() => _BuildingPhotoSelectorState();
}

class _BuildingPhotoSelectorState extends State<BuildingPhotoSelector> {
  bool _isUploading = false;
  bool _showDirectUrlField = false;

  @override
  void initState() {
    super.initState();
    _showDirectUrlField = widget.customImageController.text.trim().isNotEmpty;
    widget.customImageController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    widget.customImageController.removeListener(_onUrlChanged);
    super.dispose();
  }

  void _onUrlChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _uploadBuildingPhoto() async {
    setState(() => _isUploading = true);
    try {
      final res = await MediaPickerService.showPickerAndUpload(
        context: context,
        title: "Upload Building Photo",
        folder: CloudinaryConfig.folderBuildings,
        allowPdf: false,
      );

      if (res != null && res.url.isNotEmpty) {
        widget.customImageController.text = res.url;
        widget.onAssetChanged(widget.initialAsset);
        if (mounted) {
          AppToast.showSuccess(context, "Building photo uploaded successfully!");
        }
      }
    } catch (e) {
      debugPrint("Error uploading building photo: $e");
      if (mounted) {
        AppToast.showError(context, "Failed to upload photo. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUrl = widget.customImageController.text.trim();
    final bool hasUploadedImage = activeUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.add_a_photo_rounded, size: 16, color: Color(0xFF0D52CE)),
            const SizedBox(width: 6),
            Text(
              "Building Photo",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Upload a new photo of this building from your device",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        if (hasUploadedImage) ...[
          // Uploaded Photo Preview Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    activeUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Photo Uploaded",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activeUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: "Change Photo",
                  icon: const Icon(Icons.cached_rounded, color: Color(0xFF0D52CE), size: 22),
                  onPressed: _isUploading ? null : _uploadBuildingPhoto,
                ),
                IconButton(
                  tooltip: "Remove Photo",
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
                  onPressed: () {
                    widget.customImageController.clear();
                    setState(() {});
                    AppToast.showSuccess(context, "Building photo removed");
                  },
                ),
              ],
            ),
          ),
        ] else ...[
          // Upload Prompt Box (clean, tap-to-upload, responsive)
          InkWell(
            onTap: _isUploading ? null : _uploadBuildingPhoto,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF93C5FD),
                  width: 1.4,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: _isUploading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0D52CE)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Uploading building photo...",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D52CE),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF0D52CE), size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Upload Building Photo",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D52CE),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap to choose from Camera or Gallery",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Direct URL entry toggle (compact and collapsible)
        InkWell(
          onTap: () => setState(() => _showDirectUrlField = !_showDirectUrlField),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showDirectUrlField ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  _showDirectUrlField ? "Hide direct image URL" : "Or enter direct image URL",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_showDirectUrlField) ...[
          const SizedBox(height: 6),
          TextField(
            controller: widget.customImageController,
            decoration: InputDecoration(
              hintText: "https://res.cloudinary.com/...",
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0D52CE), width: 1.5),
              ),
              suffixIcon: activeUrl.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () => widget.customImageController.clear(),
                    )
                  : null,
            ),
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}
