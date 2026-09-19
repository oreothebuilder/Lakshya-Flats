import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

/// Interactive Digital Signature Pad for capturing student/tenant signatures
/// with clear actions and high-resolution PNG export.
class DigitalSignaturePad extends StatefulWidget {
  final ValueChanged<Uint8List?> onSignatureCaptured;
  final VoidCallback? onClear;
  final String title;
  final String signerName;

  const DigitalSignaturePad({
    super.key,
    required this.onSignatureCaptured,
    this.onClear,
    this.title = "Digital Signature",
    required this.signerName,
  });

  @override
  State<DigitalSignaturePad> createState() => DigitalSignaturePadState();
}

class DigitalSignaturePadState extends State<DigitalSignaturePad> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey<SfSignaturePadState>();
  bool _hasDrawn = false;

  void clear() {
    _signaturePadKey.currentState?.clear();
    setState(() => _hasDrawn = false);
    widget.onSignatureCaptured(null);
    widget.onClear?.call();
  }

  Future<Uint8List?> captureSignatureBytes() async {
    if (!_hasDrawn) return null;
    try {
      final ui.Image image = await _signaturePadKey.currentState!.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final Uint8List bytes = byteData.buffer.asUint8List();
      widget.onSignatureCaptured(bytes);
      return bytes;
    } catch (e) {
      debugPrint("Error capturing signature bytes: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasDrawn ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          width: _hasDrawn ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.draw_rounded, color: Color(0xFF2563EB), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: clear,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF64748B)),
                  label: Text(
                    "Clear",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

          // Drawing Area
          Stack(
            children: [
              Container(
                height: 160,
                color: Colors.white,
                child: SfSignaturePad(
                  key: _signaturePadKey,
                  backgroundColor: Colors.white,
                  strokeColor: const Color(0xFF0F172A),
                  minimumStrokeWidth: 2.2,
                  maximumStrokeWidth: 4.2,
                  onDrawStart: () {
                    if (!_hasDrawn) {
                      setState(() => _hasDrawn = true);
                    }
                    return false;
                  },
                ),
              ),

              // Placeholder guide line and text when empty
              if (!_hasDrawn)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gesture_rounded, size: 28, color: Colors.grey.shade300),
                          const SizedBox(height: 6),
                          Text(
                            "Draw signature here with finger or stylus",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Signing as: ${widget.signerName}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Signature baseline indicator
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: IgnorePointer(
                  child: Row(
                    children: [
                      Text(
                        "X",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Footer info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Icon(
                  _hasDrawn ? Icons.verified_rounded : Icons.info_outline_rounded,
                  size: 14,
                  color: _hasDrawn ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _hasDrawn
                        ? "Signature captured digitally for ${widget.signerName}"
                        : "Signature will be bound to your legal agreement record",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: _hasDrawn ? FontWeight.w600 : FontWeight.w500,
                      color: _hasDrawn ? const Color(0xFF166534) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
