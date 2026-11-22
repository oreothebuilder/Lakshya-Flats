import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceSessionModel {
  final String id;
  final String userId;
  final String deviceName;
  final String deviceType;
  final String os;
  final String browser;
  final String ip;
  final String location;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isCurrent;

  DeviceSessionModel({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    required this.os,
    required this.browser,
    required this.ip,
    required this.location,
    required this.createdAt,
    required this.lastActive,
    this.isCurrent = false,
  });

  factory DeviceSessionModel.fromFirestore(
    DocumentSnapshot doc, {
    String? currentSessionId,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return DeviceSessionModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      deviceName: (data['deviceName'] ?? 'Unknown Device').toString(),
      deviceType: (data['deviceType'] ?? 'Desktop').toString(),
      os: (data['os'] ?? 'Unknown OS').toString(),
      browser: (data['browser'] ?? 'Browser').toString(),
      ip: (data['ip'] ?? '').toString(),
      location: (data['location'] ?? 'Active Session').toString(),
      createdAt: parseTime(data['createdAt']),
      lastActive: parseTime(data['lastActive']),
      isCurrent: doc.id == currentSessionId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'os': os,
      'browser': browser,
      'ip': ip,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  DeviceSessionModel copyWith({
    bool? isCurrent,
  }) {
    return DeviceSessionModel(
      id: id,
      userId: userId,
      deviceName: deviceName,
      deviceType: deviceType,
      os: os,
      browser: browser,
      ip: ip,
      location: location,
      createdAt: createdAt,
      lastActive: lastActive,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}
