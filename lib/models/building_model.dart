import 'package:cloud_firestore/cloud_firestore.dart';

class BuildingModel {
  final String id;
  final String name;
  final String category; // 'Boys Hostel', 'Girls Hostel', 'Co-Ed', 'Premium Flats'
  final String campusLocation; // 'Main Campus', 'North Campus', etc.
  final String address;
  final String imageAsset; // e.g. 'assets/buildings/Lakshya.png'
  final String? imageUrl; // optional remote image URL
  final int totalCapacity; // Total beds/students
  final int occupiedCount; // Current occupied students
  final int totalRooms; // Number of rooms
  final double startingRent; // Base monthly rent in ₹
  final String wardenName;
  final String wardenPhone;
  final String? staffId;
  final List<String> amenities;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BuildingModel({
    required this.id,
    required this.name,
    this.category = 'Boys Hostel',
    this.campusLocation = 'Main Campus',
    this.address = '',
    this.imageAsset = 'assets/buildings/Lakshya.png',
    this.imageUrl,
    this.totalCapacity = 100,
    this.occupiedCount = 0,
    this.totalRooms = 50,
    this.startingRent = 12500,
    this.wardenName = 'Warden In-Charge',
    this.wardenPhone = '',
    this.staffId,
    this.amenities = const [
      'High-Speed Wi-Fi',
      'AC Rooms',
      'Attached Washrooms',
      'Mess Included',
      '24/7 Security & CCTV',
      'Power Backup',
      'RO Drinking Water',
    ],
    this.description = '',
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // Computed Properties & Statistics
  // ---------------------------------------------------------------------------

  /// Occupancy fraction clamped between 0.0 and 1.0 (for progress bars)
  double get occupancyRate {
    if (totalCapacity <= 0) return 0.0;
    return (occupiedCount / totalCapacity).clamp(0.0, 1.0);
  }

  /// Occupancy percentage (0% to 100%+)
  int get occupancyPercentage {
    if (totalCapacity <= 0) return 0;
    return ((occupiedCount / totalCapacity) * 100).round();
  }

  /// Number of vacant beds remaining
  int get availableBeds {
    final remaining = totalCapacity - occupiedCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Whether the building has reached or exceeded full capacity
  bool get isFull => occupiedCount >= totalCapacity;

  /// Whether this building is near capacity (>= 90%)
  bool get isNearCapacity => occupancyRate >= 0.90;

  /// Display image identifier (asset or network URL)
  bool get hasRemoteImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  // ---------------------------------------------------------------------------
  // Serialization & Firestore Helpers
  // ---------------------------------------------------------------------------

  factory BuildingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BuildingModel(
      id: doc.id,
      name: data['name']?.toString() ?? 'Unnamed Building',
      category: data['category']?.toString() ?? 'Boys Hostel',
      campusLocation: data['campusLocation']?.toString() ?? 'Main Campus',
      address: data['address']?.toString() ?? '',
      imageAsset: data['imageAsset']?.toString() ?? _defaultAssetFor(data['name']?.toString()),
      imageUrl: data['imageUrl']?.toString(),
      totalCapacity: (data['totalCapacity'] as num?)?.toInt() ?? 100,
      occupiedCount: (data['occupiedCount'] as num?)?.toInt() ?? 0,
      totalRooms: (data['totalRooms'] as num?)?.toInt() ?? 50,
      startingRent: (data['startingRent'] as num?)?.toDouble() ?? 12500.0,
      wardenName: data['wardenName']?.toString() ?? 'Warden In-Charge',
      wardenPhone: data['wardenPhone']?.toString() ?? '',
      staffId: data['staffId']?.toString(),
      amenities: (data['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [
            'High-Speed Wi-Fi',
            'Attached Washrooms',
            'Mess Included',
            '24/7 Security & CCTV',
          ],
      description: data['description']?.toString() ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : (data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'campusLocation': campusLocation,
      'address': address,
      'imageAsset': imageAsset,
      'imageUrl': imageUrl,
      'totalCapacity': totalCapacity,
      'occupiedCount': occupiedCount,
      'totalRooms': totalRooms,
      'startingRent': startingRent,
      'wardenName': wardenName,
      'wardenPhone': wardenPhone,
      'staffId': staffId,
      'amenities': amenities,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BuildingModel copyWith({
    String? id,
    String? name,
    String? category,
    String? campusLocation,
    String? address,
    String? imageAsset,
    String? imageUrl,
    int? totalCapacity,
    int? occupiedCount,
    int? totalRooms,
    double? startingRent,
    String? wardenName,
    String? wardenPhone,
    String? staffId,
    List<String>? amenities,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BuildingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      campusLocation: campusLocation ?? this.campusLocation,
      address: address ?? this.address,
      imageAsset: imageAsset ?? this.imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      occupiedCount: occupiedCount ?? this.occupiedCount,
      totalRooms: totalRooms ?? this.totalRooms,
      startingRent: startingRent ?? this.startingRent,
      wardenName: wardenName ?? this.wardenName,
      wardenPhone: wardenPhone ?? this.wardenPhone,
      staffId: staffId ?? this.staffId,
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _defaultAssetFor(String? buildingName) {
    if (buildingName == null) return 'assets/buildings/Lakshya.png';
    final b = buildingName.toLowerCase().replaceAll(' ', '');
    if (b.contains('ishaan')) return 'assets/buildings/Ishaan.png';
    if (b.contains('shival')) return 'assets/buildings/Shivalay.png';
    if (b.contains('univ')) return 'assets/buildings/univhomes.png';
    if (b.contains('tirupati')) return 'assets/buildings/Tirupati.png';
    if (b.contains('rameshwaram')) return 'assets/buildings/Rameshwaram.png';
    if (b.contains('livano')) return 'assets/buildings/Livano.png';
    if (b.contains('somnath')) return 'assets/buildings/Somnath.png';
    return 'assets/buildings/Lakshya.png';
  }

  // ---------------------------------------------------------------------------
  // Available built-in building assets catalog
  // ---------------------------------------------------------------------------
  static const List<Map<String, String>> builtInAssets = [
    {'name': 'Lakshya', 'asset': 'assets/buildings/Lakshya.png'},
    {'name': 'Ishaan', 'asset': 'assets/buildings/Ishaan.png'},
    {'name': 'Univ Homes', 'asset': 'assets/buildings/univhomes.png'},
    {'name': 'Rameshwaram', 'asset': 'assets/buildings/Rameshwaram.png'},
    {'name': 'Shivalay', 'asset': 'assets/buildings/Shivalay.png'},
    {'name': 'Somnath', 'asset': 'assets/buildings/Somnath.png'},
    {'name': 'Tirupati', 'asset': 'assets/buildings/Tirupati.png'},
    {'name': 'Livano', 'asset': 'assets/buildings/Livano.png'},
  ];

  // ---------------------------------------------------------------------------
  // Default Pre-seeded Buildings based on assets/buildings/
  // ---------------------------------------------------------------------------
  static List<BuildingModel> get defaultBuildings => [
    BuildingModel(
      id: 'bld_lakshya',
      name: 'Lakshya',
      category: 'Boys Hostel',
      campusLocation: 'Main Campus',
      address: 'Plot 12, Main Residency Boulevard, Knowledge Park',
      imageAsset: 'assets/buildings/Lakshya.png',
      totalCapacity: 120,
      occupiedCount: 106,
      totalRooms: 60,
      startingRent: 12500,
      wardenName: 'Rajesh Sharma',
      wardenPhone: '+91 9811223344',
      amenities: [
        'High-Speed Wi-Fi',
        'AC Rooms',
        'Attached Washrooms',
        'Mess Included',
        '24/7 Security & CCTV',
        'Power Backup',
        'RO Drinking Water',
        'Daily Housekeeping',
        'Laundry Facility',
      ],
      description: 'Flagship campus residency with premium amenities and central dining.',
    ),
    BuildingModel(
      id: 'bld_ishaan',
      name: 'Ishaan',
      category: 'Boys Hostel',
      campusLocation: 'North Campus',
      address: 'Lane 4, Academic Enclave, North Sector',
      imageAsset: 'assets/buildings/Ishaan.png',
      totalCapacity: 90,
      occupiedCount: 79,
      totalRooms: 45,
      startingRent: 14000,
      wardenName: 'Manoj Kumar',
      wardenPhone: '+91 9822334455',
      amenities: [
        'High-Speed Wi-Fi',
        'AC Rooms',
        'Attached Washrooms',
        'Mess Included',
        '24/7 Security & CCTV',
        'Gym',
        'Study Lounge',
        'Power Backup',
      ],
      description: 'Modern student residency right next to university north gate with attached gym.',
    ),
    BuildingModel(
      id: 'bld_univhomes',
      name: 'Univ Homes',
      category: 'Co-Ed',
      campusLocation: 'South Campus',
      address: '7B University Road, Sector 62',
      imageAsset: 'assets/buildings/univhomes.png',
      totalCapacity: 150,
      occupiedCount: 138,
      totalRooms: 75,
      startingRent: 13000,
      wardenName: 'Deepak Varma',
      wardenPhone: '+91 9833445566',
      amenities: [
        'High-Speed Wi-Fi',
        'AC Rooms',
        'Attached Washrooms',
        'Mess Included',
        '24/7 Security & CCTV',
        'Power Backup',
        'Cafeteria',
        'Laundry Facility',
      ],
      description: 'Spacious co-ed housing complex featuring multi-cuisine dining hall and recreation area.',
    ),
    BuildingModel(
      id: 'bld_rameshwaram',
      name: 'Rameshwaram',
      category: 'Boys Hostel',
      campusLocation: 'East Block',
      address: 'Near East Gate, Scholar Residency Park',
      imageAsset: 'assets/buildings/Rameshwaram.png',
      totalCapacity: 100,
      occupiedCount: 88,
      totalRooms: 50,
      startingRent: 11500,
      wardenName: 'Suresh Patel',
      wardenPhone: '+91 9844556677',
      amenities: [
        'High-Speed Wi-Fi',
        'Attached Washrooms',
        'Mess Included',
        '24/7 Security & CCTV',
        'Power Backup',
        'RO Drinking Water',
      ],
      description: 'Affordable, serene study environment with round-the-clock power and pure vegetarian mess.',
    ),
    BuildingModel(
      id: 'bld_shivalay',
      name: 'Shivalay',
      category: 'Boys Hostel',
      campusLocation: 'West Block',
      address: 'Crossroad 3, Tech Zone 1',
      imageAsset: 'assets/buildings/Shivalay.png',
      totalCapacity: 80,
      occupiedCount: 72,
      totalRooms: 40,
      startingRent: 12000,
      wardenName: 'Vikram Singh',
      wardenPhone: '+91 9855667788',
      amenities: [
        'High-Speed Wi-Fi',
        'Attached Washrooms',
        'Mess Included',
        '24/7 Security & CCTV',
        'Power Backup',
        'Study Room',
      ],
      description: 'Conveniently located near coaching institutes with dedicated quiet study floors.',
    ),
    BuildingModel(
      id: 'bld_somnath',
      name: 'Somnath',
      category: 'Girls Hostel',
      campusLocation: 'Green Campus',
      address: 'Block C, Garden View Enclave',
      imageAsset: 'assets/buildings/Somnath.png',
      totalCapacity: 75,
      occupiedCount: 64,
      totalRooms: 38,
      startingRent: 13500,
      wardenName: 'Sunita Mehra (Warden)',
      wardenPhone: '+91 9866778899',
      amenities: [
        'High-Speed Wi-Fi',
        'AC Rooms',
        'Attached Washrooms',
        'Mess Included',
        '24/7 Female Security & CCTV',
        'Power Backup',
        'Biometric Access',
      ],
      description: 'Dedicated premium girls residency with high-level biometric access and lush garden views.',
    ),
    BuildingModel(
      id: 'bld_tirupati',
      name: 'Tirupati',
      category: 'Boys Hostel',
      campusLocation: 'Central Block',
      address: 'Avenue 9, City Center Lane',
      imageAsset: 'assets/buildings/Tirupati.png',
      totalCapacity: 110,
      occupiedCount: 95,
      totalRooms: 55,
      startingRent: 12000,
      wardenName: 'Anil Yadav',
      wardenPhone: '+91 9877889900',
      amenities: [
        'High-Speed Wi-Fi',
        'AC Rooms',
        'Attached Washrooms',
        'Mess Included',
        '24/7 Security & CCTV',
        'Power Backup',
        'Gym',
      ],
      description: 'Centrally located with easy transit links, in-house gym and healthy meal options.',
    ),
    BuildingModel(
      id: 'bld_livano',
      name: 'Livano',
      category: 'Premium Co-Ed',
      campusLocation: 'Luxury Residency',
      address: 'Suite Boulevard, Express Highway Circle',
      imageAsset: 'assets/buildings/Livano.png',
      totalCapacity: 65,
      occupiedCount: 58,
      totalRooms: 32,
      startingRent: 18000,
      wardenName: 'Alok Gupta (Manager)',
      wardenPhone: '+91 9888990011',
      amenities: [
        'High-Speed Wi-Fi',
        'All AC Rooms',
        'Attached Washrooms',
        'Gourmet Mess',
        '24/7 Concierge & Security',
        'Gym',
        'Private Balconies',
        'Housekeeping',
      ],
      description: 'Ultra-luxurious flat-style living with designer furnishings, private balconies, and gourmet dining.',
    ),
  ];
}
