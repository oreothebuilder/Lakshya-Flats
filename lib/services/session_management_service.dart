import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/device_session_model.dart';
import 'session_device_info.dart';
import 'firebase_auth_service.dart';

class SessionManagementService {
  static final SessionManagementService _instance = SessionManagementService._internal();
  factory SessionManagementService() => _instance;
  SessionManagementService._internal();

  static const String _prefSessionKey = 'lakshya_device_session_id';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _cachedSessionId;
  DateTime? _currentSessionCreatedAt;
  StreamSubscription<DocumentSnapshot>? _sessionSub;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  Future<String> getOrCreateSessionId() async {
    if (_cachedSessionId != null && _cachedSessionId!.isNotEmpty) {
      return _cachedSessionId!;
    }
    final prefs = await SharedPreferences.getInstance();
    String? sid = prefs.getString(_prefSessionKey);
    if (sid == null || sid.isEmpty) {
      final rand = Random().nextInt(899999) + 100000;
      sid = "sess_${DateTime.now().millisecondsSinceEpoch}_$rand";
      await prefs.setString(_prefSessionKey, sid);
    }
    _cachedSessionId = sid;
    return sid;
  }

  Map<String, String> detectDeviceDetails() {
    String deviceType = "Desktop";
    String os = "Unknown OS";
    String browser = "Browser";
    String deviceName = "Computer";

    if (kIsWeb) {
      final ua = getWebUserAgent();
      final uaLower = ua.toLowerCase();

      // OS Detection
      if (uaLower.contains('iphone')) {
        os = "iOS";
        deviceType = "Mobile";
        deviceName = "iPhone";
      } else if (uaLower.contains('ipad')) {
        os = "iPadOS";
        deviceType = "Tablet";
        deviceName = "iPad";
      } else if (uaLower.contains('android')) {
        os = "Android";
        deviceType = uaLower.contains('mobile') ? "Mobile" : "Tablet";
        deviceName = "Android Device";
      } else if (uaLower.contains('windows nt 10.0') || uaLower.contains('windows nt 11.0') || uaLower.contains('windows')) {
        os = "Windows";
        deviceType = "Desktop";
        deviceName = "Windows PC";
      } else if (uaLower.contains('macintosh') || uaLower.contains('mac os')) {
        os = "macOS";
        deviceType = "Desktop";
        deviceName = "Mac";
      } else if (uaLower.contains('linux')) {
        os = "Linux";
        deviceType = "Desktop";
        deviceName = "Linux PC";
      }

      // Browser Detection
      if (uaLower.contains('edg/')) {
        browser = "Microsoft Edge";
      } else if (uaLower.contains('chrome/') && !uaLower.contains('edg/')) {
        browser = "Google Chrome";
      } else if (uaLower.contains('safari/') && !uaLower.contains('chrome/')) {
        browser = "Safari";
      } else if (uaLower.contains('firefox/')) {
        browser = "Mozilla Firefox";
      } else if (uaLower.contains('opera') || uaLower.contains('opr/')) {
        browser = "Opera";
      } else {
        browser = "Web Browser";
      }
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          os = "iOS";
          deviceType = "Mobile";
          deviceName = "iPhone";
          browser = "Lakshya App";
          break;
        case TargetPlatform.android:
          os = "Android";
          deviceType = "Mobile";
          deviceName = "Android Phone";
          browser = "Lakshya App";
          break;
        case TargetPlatform.macOS:
          os = "macOS";
          deviceType = "Desktop";
          deviceName = "Mac Desktop";
          browser = "Lakshya App";
          break;
        case TargetPlatform.windows:
          os = "Windows";
          deviceType = "Desktop";
          deviceName = "Windows App";
          browser = "Lakshya App";
          break;
        case TargetPlatform.linux:
          os = "Linux";
          deviceType = "Desktop";
          deviceName = "Linux App";
          browser = "Lakshya App";
          break;
        default:
          os = "Unknown";
          deviceType = "Desktop";
          deviceName = "Lakshya App";
          browser = "Lakshya App";
      }
    }

    return {
      'deviceType': deviceType,
      'os': os,
      'browser': browser,
      'deviceName': "$deviceName ($browser)",
    };
  }

  Future<Map<String, String>> fetchIpAndLocation() async {
    try {
      final res = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final city = data['city']?.toString() ?? '';
        final region = data['region']?.toString() ?? '';
        final country = data['country_name']?.toString() ?? '';
        final ip = data['ip']?.toString() ?? '';

        final locParts = [city, region, country].where((s) => s.isNotEmpty).toSet().toList();
        final loc = locParts.isNotEmpty ? locParts.join(', ') : 'India';
        return {'ip': ip, 'location': loc};
      }
    } catch (_) {}

    // Fallback: simple IP lookup
    try {
      final res = await http.get(Uri.parse('https://api.ipify.org?format=json')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final ip = data['ip']?.toString() ?? '';
        return {'ip': ip, 'location': 'India'};
      }
    } catch (_) {}

    return {'ip': '', 'location': 'Active Session'};
  }

  /// Register or update the current active session in Firestore
  Future<void> registerCurrentSession(String uid) async {
    if (uid.isEmpty) return;

    try {
      final sid = await getOrCreateSessionId();
      final device = detectDeviceDetails();
      final network = await fetchIpAndLocation();
      final now = DateTime.now();
      _currentSessionCreatedAt ??= now;

      final sessionRef = _db.collection('users').doc(uid).collection('active_sessions').doc(sid);
      final existingDoc = await sessionRef.get();

      final data = {
        'userId': uid,
        'sessionId': sid,
        'deviceName': device['deviceName'] ?? 'Active Device',
        'deviceType': device['deviceType'] ?? 'Desktop',
        'os': device['os'] ?? 'Unknown OS',
        'browser': device['browser'] ?? 'Browser',
        'ip': network['ip'] ?? '',
        'location': network['location'] ?? 'Active Session',
        'lastActive': FieldValue.serverTimestamp(),
      };

      if (!existingDoc.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await sessionRef.set(data, SetOptions(merge: true));
      debugPrint("Registered active session: $sid for user: $uid");
    } catch (e) {
      debugPrint("Session registration error: $e");
    }
  }

  /// Watch for remote session revocation or force-logout trigger
  void listenToSessionRevocation(String uid, {required VoidCallback onForceLogout}) {
    if (uid.isEmpty) return;

    _sessionSub?.cancel();
    _userDocSub?.cancel();

    getOrCreateSessionId().then((sid) {
      final sessionRef = _db.collection('users').doc(uid).collection('active_sessions').doc(sid);

      // 1. Listen to this specific session document: if deleted, force logout
      _sessionSub = sessionRef.snapshots().listen((snap) {
        if (!snap.exists) {
          debugPrint("Session $sid was revoked remotely.");
          onForceLogout();
        }
      }, onError: (_) {});

      // 2. Listen to parent user document for global forceLogoutBefore timestamp
      final userRef = _db.collection('users').doc(uid);
      _userDocSub = userRef.snapshots().listen((userSnap) {
        if (userSnap.exists && userSnap.data() != null) {
          final data = userSnap.data()!;
          if (data['forceLogoutBefore'] != null) {
            DateTime? forceTime;
            if (data['forceLogoutBefore'] is Timestamp) {
              forceTime = (data['forceLogoutBefore'] as Timestamp).toDate();
            } else if (data['forceLogoutBefore'] is String) {
              forceTime = DateTime.tryParse(data['forceLogoutBefore']);
            }

            if (forceTime != null && _currentSessionCreatedAt != null) {
              if (forceTime.isAfter(_currentSessionCreatedAt!)) {
                debugPrint("Global force logout triggered for all sessions.");
                onForceLogout();
              }
            }
          }
        }
      }, onError: (_) {});
    });
  }

  /// Real-time stream of all active sessions for this administrator
  Stream<List<DeviceSessionModel>> getActiveSessionsStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .collection('active_sessions')
        .orderBy('lastActive', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final currentSid = await getOrCreateSessionId();
      final list = snap.docs.map((doc) {
        return DeviceSessionModel.fromFirestore(doc, currentSessionId: currentSid);
      }).toList();

      // Ensure current session is always placed at top
      list.sort((a, b) {
        if (a.isCurrent) return -1;
        if (b.isCurrent) return 1;
        return b.lastActive.compareTo(a.lastActive);
      });

      return list;
    });
  }

  /// Terminate a specific device session
  Future<void> logoutSpecificSession(String uid, String sessionId) async {
    final currentSid = await getOrCreateSessionId();
    await _db
        .collection('users')
        .doc(uid)
        .collection('active_sessions')
        .doc(sessionId)
        .delete();

    if (sessionId == currentSid) {
      await FirebaseAuthService().signOut();
    }
  }

  /// Log out from all devices EXCEPT the current device
  Future<void> logoutAllOtherDevices(String uid) async {
    final currentSid = await getOrCreateSessionId();
    final colRef = _db.collection('users').doc(uid).collection('active_sessions');
    final snap = await colRef.get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      if (doc.id != currentSid) {
        batch.delete(doc.reference);
      }
    }

    // Refresh current session's createdAt and update parent user doc
    final now = DateTime.now();
    _currentSessionCreatedAt = now;

    batch.set(_db.collection('users').doc(uid), {
      'forceLogoutBefore': Timestamp.fromDate(now.subtract(const Duration(seconds: 1))),
    }, SetOptions(merge: true));

    batch.set(colRef.doc(currentSid), {
      'createdAt': Timestamp.fromDate(now),
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Log out from ALL devices including this current device
  Future<void> logoutAllDevices(String uid) async {
    try {
      final colRef = _db.collection('users').doc(uid).collection('active_sessions');
      final snap = await colRef.get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }

      batch.set(_db.collection('users').doc(uid), {
        'forceLogoutBefore': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint("Error logging out all devices: $e");
    }

    // Clear local session ID cache and sign out
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefSessionKey);
    _cachedSessionId = null;
    _currentSessionCreatedAt = null;

    _sessionSub?.cancel();
    _userDocSub?.cancel();

    await FirebaseAuthService().signOut();
  }

  void dispose() {
    _sessionSub?.cancel();
    _userDocSub?.cancel();
  }
}
