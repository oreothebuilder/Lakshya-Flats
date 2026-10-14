import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/payment_details_model.dart';
import '../models/user_role_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import 'app_toast.dart';
import 'document_viewer_modal.dart';

class ChangePaymentDetailsDialog extends StatefulWidget {
  final String? initialBuilding;
  final AppUser? currentUser;

  const ChangePaymentDetailsDialog({
    super.key,
    this.initialBuilding,
    this.currentUser,
  });

  /// Helper to show the dialog responsively (dialog on wide screens, bottom sheet on mobile)
  static Future<bool?> show(
    BuildContext context, {
    String? initialBuilding,
    AppUser? currentUser,
  }) {
    final isWide = MediaQuery.of(context).size.width >= 650;
    if (isWide) {
      return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
            child: ChangePaymentDetailsDialog(
              initialBuilding: initialBuilding,
              currentUser: currentUser,
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.92,
            ),
            child: ChangePaymentDetailsDialog(
              initialBuilding: initialBuilding,
              currentUser: currentUser,
            ),
          ),
        ),
      );
    }
  }

  @override
  State<ChangePaymentDetailsDialog> createState() => _ChangePaymentDetailsDialogState();
}

class _ChangePaymentDetailsDialogState extends State<ChangePaymentDetailsDialog> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _buildings = [
    "All Buildings (Global Default)",
    "Lakshya",
    "Shivalya",
    "Ishaan",
    "Univ homes",
    "Tirupati",
    "Rameshwaram",
    "Livano",
    "Somnath",
  ];

  late String _selectedScope;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingQr = false;
  bool _showPreview = true;

  late TextEditingController _accountHolderController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _confirmAccountController;
  late TextEditingController _ifscController;
  late TextEditingController _upiIdController;
  late TextEditingController _instructionsController;
  String? _qrCodeUrl;

  @override
  void initState() {
    super.initState();
    final initB = widget.initialBuilding?.trim();
    if (initB != null && initB.isNotEmpty && initB.toLowerCase() != 'all' && initB.toLowerCase() != 'all buildings') {
      final match = _buildings.firstWhere(
        (b) => b.toLowerCase().contains(initB.toLowerCase()) || initB.toLowerCase().contains(b.toLowerCase()),
        orElse: () => "All Buildings (Global Default)",
      );
      _selectedScope = match;
    } else {
      _selectedScope = "All Buildings (Global Default)";
    }

    _accountHolderController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _confirmAccountController = TextEditingController();
    _ifscController = TextEditingController();
    _upiIdController = TextEditingController();
    _instructionsController = TextEditingController();

    _loadDetailsForSelectedScope();
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _upiIdController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  String? get _currentBuildingName {
    if (_selectedScope == "All Buildings (Global Default)") return null;
    return _selectedScope;
  }

  Future<void> _loadDetailsForSelectedScope() async {
    setState(() => _isLoading = true);
    try {
      final bName = _currentBuildingName;
      final details = await FirestoreService().getPaymentDetails(buildingName: bName);

      if (mounted) {
        setState(() {
          _accountHolderController.text = details.accountHolderName;
          _bankNameController.text = details.bankName;
          _accountNumberController.text = details.accountNumber;
          _confirmAccountController.text = details.accountNumber;
          _ifscController.text = details.ifscCode;
          _upiIdController.text = details.upiId;
          _instructionsController.text = details.instructions ?? '';
          _qrCodeUrl = details.qrCodeUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, "Failed to load payment details: $e");
      }
    }
  }

  Future<void> _pickAndUploadQrCode() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingQr = true);
      final bytes = await image.readAsBytes();
      final uploadedUrl = await CloudinaryService.uploadBytes(
        bytes,
        fileName: 'payment_qr_${DateTime.now().millisecondsSinceEpoch}.png',
        folder: 'payment_qr_codes',
      );

      if (uploadedUrl != null && mounted) {
        setState(() {
          _qrCodeUrl = uploadedUrl;
          _isUploadingQr = false;
        });
        AppToast.showSuccess(context, "QR code uploaded successfully!");
      } else if (mounted) {
        setState(() => _isUploadingQr = false);
        AppToast.showError(context, "Failed to upload QR code image. Please try again.");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingQr = false);
        AppToast.showError(context, "Error selecting QR code: $e");
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final accNum = _accountNumberController.text.trim();
    final confirmNum = _confirmAccountController.text.trim();
    if (accNum != confirmNum) {
      AppToast.showError(context, "Account numbers do not match!");
      return;
    }

    setState(() => _isSaving = true);
    try {
      final bName = _currentBuildingName;
      final isBuilding = bName != null && bName.isNotEmpty;

      final updatedDetails = PaymentDetailsModel(
        scope: isBuilding ? 'building' : 'global',
        buildingName: bName,
        accountHolderName: _accountHolderController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: accNum,
        ifscCode: _ifscController.text.trim().toUpperCase(),
        upiId: _upiIdController.text.trim().toLowerCase(),
        qrCodeUrl: _qrCodeUrl,
        instructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        updatedAt: DateTime.now(),
        updatedBy: widget.currentUser?.email ?? 'admin',
      );

      await FirestoreService().savePaymentDetails(updatedDetails);

      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.showSuccess(
          context,
          isBuilding
              ? "Payment details for $bName updated! Students will see these details while paying."
              : "Global payment details updated! All students will see these details while paying.",
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.showError(context, "Failed to save payment details: $e");
      }
    }
  }

  Future<void> _handleResetToDefault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Reset Payment Details?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          _currentBuildingName != null
              ? "Reset payment details for $_currentBuildingName to global defaults?"
              : "Reset global payment details to standard default values?",
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Reset", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await FirestoreService().resetPaymentDetails(buildingName: _currentBuildingName);
      await _loadDetailsForSelectedScope();
      if (mounted) {
        AppToast.showSuccess(context, "Payment details reset successfully.");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, "Reset failed: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dialog Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF003896),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Details Settings",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Details students see while paying any bill",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
                tooltip: "Close",
              ),
            ],
          ),
        ),

        // Body Content
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF003896)),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scope / Building Selector
                        Text(
                          "Configure Payment Details For:",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedScope,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              items: _buildings.map((b) {
                                final isGlobal = b.contains("Global");
                                return DropdownMenuItem<String>(
                                  value: b,
                                  child: Row(
                                    children: [
                                      Icon(
                                        isGlobal ? Icons.public_rounded : Icons.apartment_rounded,
                                        size: 16,
                                        color: isGlobal ? const Color(0xFF003896) : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          b,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null && val != _selectedScope) {
                                  setState(() => _selectedScope = val);
                                  _loadDetailsForSelectedScope();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedScope.contains("Global")
                              ? "Students from all buildings will see these details unless a building-specific override is configured."
                              : "Students residing in $_selectedScope will see these specific payment details while paying.",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form Inputs
                        _buildInputField(
                          label: "Account Holder / Payee Name",
                          controller: _accountHolderController,
                          hint: "Lakshya Student Residences",
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.trim().isEmpty ? "Account name cannot be empty" : null,
                        ),
                        const SizedBox(height: 14),

                        _buildInputField(
                          label: "Bank Name",
                          controller: _bankNameController,
                          hint: "ICICI Bank",
                          icon: Icons.account_balance_rounded,
                          validator: (v) => v == null || v.trim().isEmpty ? "Bank name cannot be empty" : null,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: "Account Number",
                                controller: _accountNumberController,
                                hint: "002105018921",
                                icon: Icons.numbers_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInputField(
                                label: "Confirm Account No.",
                                controller: _confirmAccountController,
                                hint: "Re-enter Account No.",
                                icon: Icons.check_circle_outline_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Required";
                                  if (v.trim() != _accountNumberController.text.trim()) return "Mismatch";
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: "IFSC Code",
                                controller: _ifscController,
                                hint: "ICIC0000021",
                                icon: Icons.pin_outlined,
                                textCapitalization: TextCapitalization.characters,
                                validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInputField(
                                label: "Hostel UPI ID",
                                controller: _upiIdController,
                                hint: "lakshyastays@icici",
                                icon: Icons.qr_code_2_rounded,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Required";
                                  if (!v.contains('@')) return "Invalid UPI format";
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // QR Code Image Uploader Section
                        Text(
                          "Official UPI QR Code (Optional)",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              // QR Code Preview / Placeholder
                              if (_qrCodeUrl != null && _qrCodeUrl!.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _qrCodeUrl!,
                                    width: 58,
                                    height: 58,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, e, st) => Container(
                                      width: 58,
                                      height: 58,
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "QR Code Attached",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Students can scan this directly from payment modal",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    DocumentViewerModal.show(
                                      context,
                                      url: _qrCodeUrl!,
                                      title: "Payment QR Code",
                                    );
                                  },
                                  icon: const Icon(Icons.visibility_rounded, color: Color(0xFF003896), size: 20),
                                  tooltip: "Preview Full QR",
                                ),
                                IconButton(
                                  onPressed: () => setState(() => _qrCodeUrl = null),
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                                  tooltip: "Remove QR",
                                ),
                              ] else ...[
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.qr_code_rounded, color: Color(0xFF003896), size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Upload QR Code",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "GPay, PhonePe, Paytm, or BHIM QR screenshot",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isUploadingQr ? null : _pickAndUploadQrCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF003896),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: _isUploadingQr
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.upload_rounded, size: 16),
                                  label: Text(
                                    _isUploadingQr ? "Uploading..." : "Upload",
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Instructions / Notes to Student
                        _buildInputField(
                          label: "Payment Instructions For Students",
                          controller: _instructionsController,
                          hint: "Please transfer exact fee amount and submit transaction ref / UTR number for verification.",
                          icon: Icons.info_outline_rounded,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),

                        // Student View Live Preview Card
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.remove_red_eye_rounded, size: 16, color: Color(0xFF003896)),
                                const SizedBox(width: 6),
                                Text(
                                  "Student View Preview",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF003896),
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => setState(() => _showPreview = !_showPreview),
                              child: Text(
                                _showPreview ? "Hide Preview" : "Show Preview",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_showPreview) ...[
                          const SizedBox(height: 8),
                          _buildStudentViewPreview(),
                        ],
                      ],
                    ),
                  ),
                ),
        ),

        // Bottom Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _isSaving ? null : _handleResetToDefault,
                icon: const Icon(Icons.restore_rounded, size: 16, color: Color(0xFF64748B)),
                label: Text(
                  "Reset",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003896),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _isSaving ? "Saving..." : "Save Payment Details",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF003896), width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildStudentViewPreview() {
    final name = _accountHolderController.text.trim().isNotEmpty
        ? _accountHolderController.text.trim()
        : "Lakshya Student Residences";
    final bank = _bankNameController.text.trim().isNotEmpty
        ? _bankNameController.text.trim()
        : "ICICI Bank";
    final acc = _accountNumberController.text.trim().isNotEmpty
        ? _accountNumberController.text.trim()
        : "002105018921";
    final ifsc = _ifscController.text.trim().isNotEmpty
        ? _ifscController.text.trim().toUpperCase()
        : "ICIC0000021";
    final upi = _upiIdController.text.trim().isNotEmpty
        ? _upiIdController.text.trim()
        : "lakshyastays@icici";
    final instructions = _instructionsController.text.trim().isNotEmpty
        ? _instructionsController.text.trim()
        : "Please transfer or hand over the exact fee amount through your preferred method, then select the method below and submit proof to notify administration.";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.account_balance_rounded, color: Color(0xFF2563EB), size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Official Hostel Bank & UPI Details",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (_currentBuildingName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _currentBuildingName!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPreviewRow("Account Name", name),
          const SizedBox(height: 4),
          _buildPreviewRow("Bank Name", bank),
          const SizedBox(height: 4),
          _buildPreviewRow("Account Number", acc, copyable: true),
          const SizedBox(height: 4),
          _buildPreviewRow("IFSC Code", ifsc, copyable: true),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hostel UPI ID", style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF64748B))),
                  Text(upi, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      "Copy UPI",
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_qrCodeUrl != null && _qrCodeUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(_qrCodeUrl!, width: 36, height: 36, fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                Text(
                  "QR Code available for instant UPI scanning",
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    instructions,
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF1E40AF)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, {bool copyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700),
            ),
            if (copyable) ...[
              const SizedBox(width: 4),
              const Icon(Icons.copy_rounded, size: 11, color: Color(0xFF2563EB)),
            ],
          ],
        ),
      ],
    );
  }
}
