import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BucketIconItem {
  final String key;
  final String label;
  final IconData icon;

  const BucketIconItem(this.key, this.label, this.icon);
}

const List<BucketIconItem> kSupportedBucketIcons = [
  BucketIconItem('restaurant', 'Mess & Food', Icons.restaurant_rounded),
  BucketIconItem('build', 'Maintenance', Icons.build_rounded),
  BucketIconItem('badge', 'Staff Payment', Icons.badge_rounded),
  BucketIconItem('laundry', 'Laundry', Icons.local_laundry_service_rounded),
  BucketIconItem('petrol', 'Petrol & Fuel', Icons.local_gas_station_rounded),
  BucketIconItem('category', 'General & Others', Icons.category_rounded),
  BucketIconItem('water', 'Water Supply', Icons.water_drop_rounded),
  BucketIconItem('wifi', 'Wi-Fi & Network', Icons.wifi_rounded),
  BucketIconItem('bolt', 'Electricity', Icons.bolt_rounded),
  BucketIconItem('shopping', 'Purchases & Cart', Icons.shopping_cart_rounded),
  BucketIconItem('medical', 'Medical & First Aid', Icons.medical_services_rounded),
  BucketIconItem('security', 'Security & Guard', Icons.security_rounded),
];

class ExpenseBucketModel {
  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final bool isDefault;
  final String description;
  final DateTime createdAt;

  ExpenseBucketModel({
    required this.id,
    required this.name,
    this.iconKey = 'category',
    required this.colorValue,
    this.isDefault = false,
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  IconData get iconData {
    final match = kSupportedBucketIcons.firstWhere(
      (item) => item.key == iconKey,
      orElse: () => const BucketIconItem('category', 'General', Icons.category_rounded),
    );
    return match.icon;
  }

  Color get color => Color(colorValue);

  factory ExpenseBucketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    String resolvedIconKey = data['iconKey']?.toString() ?? '';
    if (resolvedIconKey.isEmpty) {
      resolvedIconKey = _mapLegacyOrNameToKey(data['name']?.toString() ?? '');
    }

    return ExpenseBucketModel(
      id: doc.id,
      name: data['name']?.toString() ?? 'Unnamed Bucket',
      iconKey: resolvedIconKey,
      colorValue: data['colorValue'] is int
          ? data['colorValue'] as int
          : (int.tryParse(data['colorValue']?.toString() ?? '') ?? 0xFF0D52CE),
      isDefault: data['isDefault'] == true,
      description: data['description']?.toString() ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] != null ? DateTime.tryParse(data['createdAt'].toString()) : null) ??
              DateTime.now(),
    );
  }

  static String _mapLegacyOrNameToKey(String name) {
    final n = name.toLowerCase();
    if (n.contains('mess') || n.contains('food')) return 'restaurant';
    if (n.contains('maint') || n.contains('fix')) return 'build';
    if (n.contains('staff') || n.contains('salary')) return 'badge';
    if (n.contains('laundry')) return 'laundry';
    if (n.contains('petrol') || n.contains('transport')) return 'petrol';
    if (n.contains('water')) return 'water';
    if (n.contains('wifi') || n.contains('net')) return 'wifi';
    if (n.contains('electric') || n.contains('power')) return 'bolt';
    return 'category';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'isDefault': isDefault,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ExpenseBucketModel copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? colorValue,
    bool? isDefault,
    String? description,
    DateTime? createdAt,
  }) {
    return ExpenseBucketModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// The 6 initial buckets requested by the user
  static List<ExpenseBucketModel> get defaultBuckets => [
    ExpenseBucketModel(
      id: 'bucket_hostel_mess',
      name: 'Hostel mess',
      iconKey: 'restaurant',
      colorValue: 0xFF10B981, // Emerald green
      isDefault: true,
      description: 'Groceries, vegetables, milk, gas & mess operations',
    ),
    ExpenseBucketModel(
      id: 'bucket_maintenance',
      name: 'Maintenance and fixes',
      iconKey: 'build',
      colorValue: 0xFFF59E0B, // Amber
      isDefault: true,
      description: 'Plumbing, electrical, painting & repairs',
    ),
    ExpenseBucketModel(
      id: 'bucket_staff_payment',
      name: 'Staff payment',
      iconKey: 'badge',
      colorValue: 0xFF3B82F6, // Blue
      isDefault: true,
      description: 'Warden, cooks, cleaners & security salaries',
    ),
    ExpenseBucketModel(
      id: 'bucket_laundry',
      name: 'Laundry',
      iconKey: 'laundry',
      colorValue: 0xFF06B6D4, // Cyan
      isDefault: true,
      description: 'Washing chemicals, dry cleaning & linen care',
    ),
    ExpenseBucketModel(
      id: 'bucket_petrol',
      name: 'Petrol for transportation',
      iconKey: 'petrol',
      colorValue: 0xFFEF4444, // Red / Coral
      isDefault: true,
      description: 'Vehicle fuel, van transport & travel',
    ),
    ExpenseBucketModel(
      id: 'bucket_others',
      name: 'others',
      iconKey: 'category',
      colorValue: 0xFF64748B, // Slate grey
      isDefault: true,
      description: 'Miscellaneous and unallocated expenses',
    ),
  ];
}
