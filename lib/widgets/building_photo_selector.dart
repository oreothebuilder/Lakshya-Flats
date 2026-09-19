import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/building_model.dart';
import '../services/firestore_service.dart';
import '../services/media_picker_service.dart';
import '../config/cloudinary_config.dart';
import 'app_toast.dart';

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
  final FirestoreService _firestoreService = FirestoreService();

  late String _selectedAsset;
  bool _isUploadingCustom = false;
  bool _showDirectUrlField = false;

  @override
  void initState() {
    super.initState();
    _selectedAsset = widget.initialAsset.isNotEmpty
        ? widget.initialAsset
        : 'assets/buildings/Lakshya.png';
    _showDirectUrlField = widget.customImageController.text.trim().isNotEmpty;
    widget.customImageController.addListener(_onUrlControllerChanged);
  }

  @override
  void dispose() {
    widget.customImageController.removeListener(_onUrlControllerChanged);
    super.dispose();
  }

  void _onUrlControllerChanged() {
    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Action: Pick & Upload Photo Directly for this Building (Apart from Catalog)
  // ---------------------------------------------------------------------------
  Future<void> _uploadCustomPhoto() async {
    setState(() => _isUploadingCustom = true);
    try {
      final res = await MediaPickerService.showPickerAndUpload(
        context: context,
        title: "Upload Building Photo",
        folder: CloudinaryConfig.folderBuildings,
        allowPdf: false,
      );

      if (res != null && res.url.isNotEmpty) {
        widget.customImageController.text = res.url;
        widget.onAssetChanged(_selectedAsset);
        if (mounted) {
          AppToast.showSuccess(context, "Building photo uploaded successfully!");
        }
      }
    } catch (e) {
      debugPrint("Error uploading custom building photo: $e");
      if (mounted) {
        AppToast.showError(context, "Failed to upload photo. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingCustom = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Action: Open Modal to Add a Photo to the Catalog
  // ---------------------------------------------------------------------------
  void _openAddToCatalogDialog() {
    final nameCtrl = TextEditingController(text: '');
    bool isSavingCatalog = false;

    showDialog(
      context: context,
      barrierDismissible: !isSavingCatalog,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              actionsPadding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF0D52CE), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add to Catalog",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "Save a photo to reuse across buildings",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Catalog Label / Name *",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: "e.g. Green Heights, Wing B, Modern Block",
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0D52CE), width: 1.8),
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 16, color: Color(0xFF0D52CE)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Next, choose photo from camera or gallery to upload to Cloudinary.",
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSavingCatalog ? null : () => Navigator.pop(dialogCtx),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isSavingCatalog
                      ? null
                      : () async {
                          final photoName = nameCtrl.text.trim().isNotEmpty
                              ? nameCtrl.text.trim()
                              : 'Building Photo';

                          setDialogState(() => isSavingCatalog = true);

                          try {
                            final res = await MediaPickerService.showPickerAndUpload(
                              context: dialogCtx,
                              title: "Upload to Building Catalog",
                              folder: CloudinaryConfig.folderBuildingCatalog,
                              allowPdf: false,
                            );

                            if (res != null && res.url.isNotEmpty) {
                              await _firestoreService.addBuildingCatalogPhoto(
                                name: photoName,
                                imageUrl: res.url,
                              );

                              // Auto-select the newly added catalog photo
                              setState(() {
                                widget.customImageController.text = res.url;
                                widget.onAssetChanged(_selectedAsset);
                              });

                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx);
                              }

                              if (mounted) {
                                AppToast.showSuccess(
                                  context,
                                  "'$photoName' added to catalog & selected!",
                                );
                              }
                            } else {
                              setDialogState(() => isSavingCatalog = false);
                            }
                          } catch (err) {
                            debugPrint("Error adding to catalog: $err");
                            setDialogState(() => isSavingCatalog = false);
                            if (mounted) {
                              AppToast.showError(context, "Failed to upload photo: $err");
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D52CE),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isSavingCatalog
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                  label: Text(
                    isSavingCatalog ? "Uploading..." : "Select & Upload",
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Action: Confirm Deletion of Custom Catalog Photo
  // ---------------------------------------------------------------------------
  void _confirmDeleteCatalogPhoto(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete from Catalog?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          "Remove '${item['name']}' from the photo catalog? Existing buildings using this photo will keep their image.",
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final id = item['id']?.toString();
              if (id != null) {
                await _firestoreService.deleteBuildingCatalogPhoto(id);
                // If it was selected, clear customImageController
                if (widget.customImageController.text.trim() == item['imageUrl']) {
                  widget.customImageController.clear();
                  setState(() {});
                }
                if (mounted) {
                  AppToast.showSuccess(context, "Catalog photo removed");
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Delete", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUrl = widget.customImageController.text.trim();
    final bool hasActiveCustomUrl = activeUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------------------
        // 1. Photo Catalog Header & Stream
        // ---------------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Select Building Photo (from catalog)",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            InkWell(
              onTap: _openAddToCatalogDialog,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF0D52CE)),
                    const SizedBox(width: 4),
                    Text(
                      "Add to Catalog",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0D52CE),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.getBuildingCatalogPhotosStream(),
          builder: (context, snapshot) {
            final customPhotos = snapshot.data ?? <Map<String, dynamic>>[];
            return SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: 1 + customPhotos.length + BuildingModel.builtInAssets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  // Index 0: [+ Add to Catalog] Card
                  if (idx == 0) {
                    return _buildAddCatalogCard();
                  }

                  // Custom Catalog Photos (from Firestore)
                  final customIdx = idx - 1;
                  if (customIdx < customPhotos.length) {
                    final item = customPhotos[customIdx];
                    final itemUrl = item['imageUrl']?.toString() ?? '';
                    final isSelected = hasActiveCustomUrl && activeUrl == itemUrl;

                    return _buildCatalogItemCard(
                      name: item['name']?.toString() ?? 'Custom',
                      isSelected: isSelected,
                      imageWidget: Image.network(
                        itemUrl,
                        width: 105,
                        height: 116,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFCBD5E1),
                          child: const Icon(Icons.apartment_rounded, color: Colors.white),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          widget.customImageController.text = itemUrl;
                          widget.onAssetChanged(_selectedAsset);
                        });
                      },
                      onDelete: () => _confirmDeleteCatalogPhoto(item),
                    );
                  }

                  // Built-in Catalog Photos (from assets)
                  final builtInIdx = customIdx - customPhotos.length;
                  final item = BuildingModel.builtInAssets[builtInIdx];
                  final assetPath = item['asset']!;
                  // Selected if no custom image is active and asset matches
                  final isSelected = !hasActiveCustomUrl && _selectedAsset == assetPath;

                  return _buildCatalogItemCard(
                    name: item['name']!,
                    isSelected: isSelected,
                    imageWidget: Image.asset(
                      assetPath,
                      width: 105,
                      height: 116,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFCBD5E1),
                        child: const Icon(Icons.apartment_rounded, color: Colors.white),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedAsset = assetPath;
                        widget.customImageController.clear();
                        widget.onAssetChanged(_selectedAsset);
                      });
                    },
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // ---------------------------------------------------------------------
        // 2. Upload Custom Photo Apart from Catalog (Exclusive to this Building)
        // ---------------------------------------------------------------------
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.upload_file_rounded, color: Color(0xFF0D52CE), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Or Upload Custom Photo (apart from catalog)",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          "Upload an exclusive photo for this building without adding to catalog",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // If a custom URL is currently active
              if (hasActiveCustomUrl) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          activeUrl,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 58,
                            height: 58,
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Custom Photo Active",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
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
                      const SizedBox(width: 8),
                      // Change Button
                      IconButton(
                        tooltip: "Change Photo",
                        icon: const Icon(Icons.cached_rounded, color: Color(0xFF0D52CE), size: 20),
                        onPressed: _isUploadingCustom ? null : _uploadCustomPhoto,
                      ),
                      // Remove Button
                      IconButton(
                        tooltip: "Remove & Use Catalog Asset",
                        icon: const Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 20),
                        onPressed: () {
                          setState(() {
                            widget.customImageController.clear();
                            widget.onAssetChanged(_selectedAsset);
                          });
                          AppToast.showSuccess(context, "Reverted to catalog photo");
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Upload trigger button / zone
                InkWell(
                  onTap: _isUploadingCustom ? null : _uploadCustomPhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                    ),
                    child: _isUploadingCustom
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D52CE)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Uploading to Cloudinary...",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0D52CE),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, color: Color(0xFF0D52CE), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Upload Photo from Device (Camera / Gallery)",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0D52CE),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Subtle toggle for manual URL input
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
                        _showDirectUrlField ? "Hide direct image URL field" : "Or enter direct image URL",
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
                    fillColor: Colors.white,
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
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Card Widget: [+ Add to Catalog]
  // ---------------------------------------------------------------------------
  Widget _buildAddCatalogCard() {
    return GestureDetector(
      onTap: _openAddToCatalogDialog,
      child: Container(
        width: 105,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF93C5FD),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF0D52CE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "Add to\nCatalog",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D52CE),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card Widget: Catalog Item (Built-in or Uploaded)
  // ---------------------------------------------------------------------------
  Widget _buildCatalogItemCard({
    required String name,
    required bool isSelected,
    required Widget imageWidget,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D52CE) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageWidget,

              // Bottom gradient label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Active Selected Checkmark
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D52CE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                ),

              // Delete button for custom catalog photos
              if (onDelete != null)
                Positioned(
                  top: 4,
                  left: 4,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
