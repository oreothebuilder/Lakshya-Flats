import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentDetailsModel {
  final String id;
  final String scope; // 'global' or 'building'
  final String? buildingName; // null if global, or building name if building-specific
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String upiId;
  final String? qrCodeUrl;
  final String? instructions;
  final DateTime updatedAt;
  final String? updatedBy;

  PaymentDetailsModel({
    this.id = 'default',
    this.scope = 'global',
    this.buildingName,
    this.accountHolderName = 'Lakshya Student Residences',
    this.bankName = 'ICICI Bank',
    this.accountNumber = '002105018921',
    this.ifscCode = 'ICIC0000021',
    this.upiId = 'lakshyastays@icici',
    this.qrCodeUrl,
    this.instructions =
        'Please transfer or hand over the exact fee amount through your preferred method, then select the method below and submit proof to notify administration.',
    DateTime? updatedAt,
    this.updatedBy,
  }) : updatedAt = updatedAt ?? DateTime.now();

  static PaymentDetailsModel defaultDetails({String? buildingName}) {
    final isBuilding = buildingName != null && buildingName.trim().isNotEmpty && buildingName != 'All Buildings';
    return PaymentDetailsModel(
      id: isBuilding
          ? 'building_${buildingName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
          : 'default',
      scope: isBuilding ? 'building' : 'global',
      buildingName: isBuilding ? buildingName.trim() : null,
      accountHolderName: isBuilding ? '$buildingName (Lakshya Residences)' : 'Lakshya Student Residences',
      bankName: 'ICICI Bank',
      accountNumber: '002105018921',
      ifscCode: 'ICIC0000021',
      upiId: 'lakshyastays@icici',
      qrCodeUrl: null,
      instructions:
          'Please transfer or hand over the exact fee amount through your preferred method, then select the method below and submit proof to notify administration.',
    );
  }

  factory PaymentDetailsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedUpdatedAt = DateTime.now();
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        parsedUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else {
        parsedUpdatedAt = DateTime.tryParse(data['updatedAt'].toString()) ?? DateTime.now();
      }
    }

    return PaymentDetailsModel(
      id: doc.id,
      scope: data['scope']?.toString() ?? 'global',
      buildingName: data['buildingName']?.toString(),
      accountHolderName: data['accountHolderName']?.toString() ?? 'Lakshya Student Residences',
      bankName: data['bankName']?.toString() ?? 'ICICI Bank',
      accountNumber: data['accountNumber']?.toString() ?? '002105018921',
      ifscCode: data['ifscCode']?.toString() ?? 'ICIC0000021',
      upiId: data['upiId']?.toString() ?? 'lakshyastays@icici',
      qrCodeUrl: data['qrCodeUrl']?.toString(),
      instructions: data['instructions']?.toString() ??
          'Please transfer or hand over the exact fee amount through your preferred method, then select the method below and submit proof to notify administration.',
      updatedAt: parsedUpdatedAt,
      updatedBy: data['updatedBy']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scope': scope,
      if (buildingName != null) 'buildingName': buildingName,
      'accountHolderName': accountHolderName,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'upiId': upiId,
      'qrCodeUrl': qrCodeUrl,
      'instructions': instructions,
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }

  PaymentDetailsModel copyWith({
    String? id,
    String? scope,
    String? buildingName,
    String? accountHolderName,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
    String? qrCodeUrl,
    String? instructions,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return PaymentDetailsModel(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      buildingName: buildingName ?? this.buildingName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      instructions: instructions ?? this.instructions,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
