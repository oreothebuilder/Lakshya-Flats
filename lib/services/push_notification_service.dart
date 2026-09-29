import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

/// Top-level background message handler for Firebase Cloud Messaging.
/// This must be a top-level function annotated with @pragma('vm:entry-point')
/// so that Android and iOS can invoke it even when the application is terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Background Firebase init note: $e");
  }
  debugPrint("Handling background FCM message: ${message.messageId} | ${message.notification?.title}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static const String projectId = "lakshya-flats";
  static const String channelId = "lakshya_high_importance_channel";
  static const String channelName = "Lakshya High Priority Notifications";
  static const String channelDescription =
      "Used for urgent hostel notices, bills, payments, and ticket updates.";

  FirebaseMessaging? _fcmInstance;
  FirebaseMessaging get _fcm {
    if (_fcmInstance != null) return _fcmInstance!;
    if (Firebase.apps.isNotEmpty) {
      _fcmInstance = FirebaseMessaging.instance;
      return _fcmInstance!;
    }
    throw StateError("Firebase must be initialized before accessing FirebaseMessaging");
  }

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentFcmToken;
  String? get currentFcmToken => _currentFcmToken;

  // Cached OAuth2 Access Token for FCM HTTP v1 dispatch
  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  /// Android High Importance Notification Channel
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize Push Notifications (FCM + Local Notifications + Background Handler)
  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) return;

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint("PushNotificationService: Firebase not initialized yet, skipping init.");
        return;
      }

      // 1. Request OS-level notification permissions (Android 13+ & iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint("PushNotificationService permission status: ${settings.authorizationStatus}");

      // 2. Setup Foreground Notification Presentation Options for Apple/Android
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Setup Android Notification Channel
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_androidChannel);
        await androidImplementation.requestNotificationsPermission();
      }

      // 4. Initialize Local Notifications Plugin (for Heads-up display in foreground)
      const initSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: initSettingsAndroid,
        iOS: initSettingsDarwin,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint("User tapped local notification: ${response.payload}");
        },
      );

      // 5. Register Background Message Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 6. Handle Foreground FCM Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Received FCM message in foreground: ${message.notification?.title}");
        final notification = message.notification;
        final android = message.notification?.android;

        // If message has notification payload, display via flutter_local_notifications
        if (notification != null) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channelId,
                channelName,
                channelDescription: channelDescription,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });

      // 7. Handle when user clicks notification and opens app from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("App opened via FCM notification: ${message.data}");
      });

      // 8. Retrieve initial token
      _currentFcmToken = await _fcm.getToken();
      debugPrint("Current device FCM token: $_currentFcmToken");

      // 9. Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        _currentFcmToken = newToken;
        debugPrint("FCM token refreshed: $newToken");
      });

      _initialized = true;
      debugPrint("PushNotificationService successfully initialized.");
    } catch (e) {
      debugPrint("PushNotificationService initialization error: $e");
    }
  }

  /// Clean topic name for Firebase topic requirements: [a-zA-Z0-9-_.~%]+
  static String sanitizeTopic(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// Register user device token and subscribe to relevant topics
  Future<void> registerUser({
    required String uid,
    String? role,
    String? building,
    String? studentId,
  }) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final token = await _fcm.getToken();
      _currentFcmToken = token;

      if (token != null && token.isNotEmpty) {
        // 1. Save token in Firestore user record
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
        await userDocRef.set({
          'fcmToken': token,
          'fcmTokens': FieldValue.arrayUnion([token]),
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        }, SetOptions(merge: true));

        debugPrint("PushNotificationService: Registered FCM token for user $uid");
      }

      // 2. Subscribe to general & role-based topics
      await _fcm.subscribeToTopic('all_users');

      final normalizedRole = (role ?? '').toLowerCase();
      if (normalizedRole == 'student' || normalizedRole.isEmpty) {
        await _fcm.subscribeToTopic('all_students');

        if (building != null && building.trim().isNotEmpty) {
          final buildingTopic = "building_${sanitizeTopic(building)}";
          await _fcm.subscribeToTopic(buildingTopic);
          debugPrint("Subscribed student to topic: $buildingTopic");
        }

        if (studentId != null && studentId.trim().isNotEmpty) {
          final studentTopic = "student_${sanitizeTopic(studentId)}";
          await _fcm.subscribeToTopic(studentTopic);
          debugPrint("Subscribed student to topic: $studentTopic");
        }
      } else if (normalizedRole == 'admin' || normalizedRole == 'management') {
        await _fcm.subscribeToTopic('admin_alerts');
        await _fcm.subscribeToTopic('management_alerts');
        debugPrint("Subscribed admin/management to admin_alerts topic");
      }
    } catch (e) {
      debugPrint("Error registering user for push notifications: $e");
    }
  }

  /// Unsubscribe topics upon logout
  Future<void> unregisterUser(String uid) async {
    if (Firebase.apps.isEmpty) return;

    try {
      if (_currentFcmToken != null) {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
        await userDocRef.update({
          'fcmTokens': FieldValue.arrayRemove([_currentFcmToken]),
        });
      }
      await _fcm.unsubscribeFromTopic('all_users');
      await _fcm.unsubscribeFromTopic('all_students');
      await _fcm.unsubscribeFromTopic('admin_alerts');
      await _fcm.unsubscribeFromTopic('management_alerts');
    } catch (e) {
      debugPrint("Error unregistering user push notification topics: $e");
    }
  }

  // =========================================================================
  // FCM HTTP v1 DISPATCH ENGINE
  // =========================================================================

  /// Obtain valid OAuth2 Bearer Access Token with scope https://www.googleapis.com/auth/firebase.messaging
  Future<String?> _getAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
      return _cachedAccessToken;
    }

    try {
      // 1. Fetch service account credentials from Firestore system_config/fcm_credentials
      final configDoc = await FirebaseFirestore.instance
          .collection('system_config')
          .doc('fcm_credentials')
          .get();

      if (!configDoc.exists || configDoc.data() == null) {
        debugPrint("PushNotificationService: fcm_credentials not found in system_config");
        return null;
      }

      final data = configDoc.data()!;
      final clientEmail = data['client_email']?.toString();
      final privateKey = data['private_key']?.toString();
      final targetProjectId = data['project_id']?.toString() ?? projectId;

      if (clientEmail == null || privateKey == null) {
        debugPrint("PushNotificationService: client_email or private_key missing in credentials");
        return null;
      }

      final creds = auth.ServiceAccountCredentials.fromJson({
        'client_email': clientEmail,
        'private_key': privateKey,
        'project_id': targetProjectId,
        'type': 'service_account',
      });

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(creds, scopes);

      _cachedAccessToken = client.credentials.accessToken.data;
      _tokenExpiry = client.credentials.accessToken.expiry;
      client.close();

      return _cachedAccessToken;
    } catch (e) {
      debugPrint("PushNotificationService: Error acquiring OAuth2 access token: $e");
      return null;
    }
  }

  /// Sends FCM message via HTTP v1 API
  Future<bool> _sendFcmHttpV1(Map<String, dynamic> messagePayload) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint("PushNotificationService: Cannot send push notice - missing access token");
        return false;
      }

      final url = Uri.parse("https://fcm.googleapis.com/v1/projects/$projectId/messages:send");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'message': messagePayload}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint("Push notification dispatched successfully: ${response.body}");
        return true;
      } else {
        debugPrint("FCM HTTP v1 error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("PushNotificationService: Exception sending push notification: $e");
      return false;
    }
  }

  /// Construct standard high-priority payload for Android & iOS
  Map<String, dynamic> _buildMessagePayload({
    String? token,
    String? topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final payload = <String, dynamic>{
      'notification': {
        'title': title,
        'body': body,
      },
      'android': {
        'priority': 'HIGH',
        'notification': {
          'channel_id': channelId,
          'sound': 'default',
          'default_sound': true,
          'default_vibrate_timings': true,
          'notification_priority': 'PRIORITY_MAX',
        },
      },
      'apns': {
        'payload': {
          'aps': {
            'alert': {
              'title': title,
              'body': body,
            },
            'sound': 'default',
            'badge': 1,
            'content-available': 1,
          },
        },
      },
    };

    if (token != null && token.isNotEmpty) {
      payload['token'] = token;
    } else if (topic != null && topic.isNotEmpty) {
      payload['topic'] = topic;
    }

    if (data != null && data.isNotEmpty) {
      payload['data'] = data.map((key, value) => MapEntry(key, value.toString()));
    }

    return payload;
  }

  // =========================================================================
  // PUBLIC DISPATCH METHODS
  // =========================================================================

  /// Dispatch push notification to a topic (e.g. 'all_students', 'building_ishaan')
  Future<bool> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final cleanTopic = sanitizeTopic(topic);
    final payload = _buildMessagePayload(
      topic: cleanTopic,
      title: title,
      body: body,
      data: data,
    );
    return await _sendFcmHttpV1(payload);
  }

  /// Dispatch push notification to a specific device token
  Future<bool> sendToDeviceToken({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final payload = _buildMessagePayload(
      token: token,
      title: title,
      body: body,
      data: data,
    );
    return await _sendFcmHttpV1(payload);
  }

  /// Dispatch push notification directly to a student (via their device tokens & personal topic)
  Future<void> sendToStudent({
    required String studentId,
    required String title,
    required String body,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    final data = <String, dynamic>{
      'studentId': studentId,
      'category': category ?? 'General',
      if (metadata != null) ...metadata,
    };

    // 1. Send via personal topic
    final studentTopic = "student_${sanitizeTopic(studentId)}";
    await sendToTopic(topic: studentTopic, title: title, body: body, data: data);

    // 2. Also look up student's registered device tokens in Firestore for dual-guaranteed delivery
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final d = userDoc.data()!;
        final singleToken = d['fcmToken']?.toString();
        final tokenList = (d['fcmTokens'] as List?)?.map((e) => e.toString()).toList() ?? [];

        final allTokens = <String>{
          if (singleToken != null && singleToken.isNotEmpty) singleToken,
          ...tokenList,
        };

        for (var t in allTokens) {
          await sendToDeviceToken(token: t, title: title, body: body, data: data);
        }
      }
    } catch (e) {
      debugPrint("Error dispatching direct student device push notification: $e");
    }
  }

  /// Dispatch push notification to all admins / management
  Future<void> sendToAdmin({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await sendToTopic(
      topic: 'admin_alerts',
      title: title,
      body: body,
      data: data,
    );
  }

  /// Dispatch broadcast push notification based on audience
  Future<void> sendBroadcastPushNotification({
    required String title,
    required String body,
    required String audience,
    List<String>? selectedBuildings,
    List<String>? selectedStudentIds,
    String? category,
  }) async {
    final data = <String, dynamic>{
      'category': category ?? 'General',
      'audience': audience,
    };

    final aud = audience.toLowerCase();

    // 1. All Students
    if (aud.contains('all student') || aud.isEmpty) {
      await sendToTopic(topic: 'all_students', title: title, body: body, data: data);
      return;
    }

    // 2. Specific Building(s)
    if (selectedBuildings != null && selectedBuildings.isNotEmpty) {
      for (var b in selectedBuildings) {
        if (b.trim().isNotEmpty) {
          final bTopic = "building_${sanitizeTopic(b)}";
          await sendToTopic(topic: bTopic, title: title, body: body, data: data);
        }
      }
    }

    // 3. Specific Student(s)
    if (selectedStudentIds != null && selectedStudentIds.isNotEmpty) {
      for (var sId in selectedStudentIds) {
        if (sId.trim().isNotEmpty) {
          await sendToStudent(
            studentId: sId,
            title: title,
            body: body,
            category: category,
            metadata: data,
          );
        }
      }
    }
  }
}
