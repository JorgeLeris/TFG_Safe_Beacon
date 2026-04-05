import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:safe_beacon/app/monitoring/logging.dart';

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _firebaseMessaging.requestPermission();

    // Background: app is open but not visible — user tapped the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      appLogger.info(
        'Background notification tapped — app brought to foreground: ${message.messageId}',
      );
    });

    // Foreground: app is open and visible — notification is NOT shown automatically
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      appLogger.info(
        'Foreground message received — must handle display manually: ${message.messageId}',
      );
      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'safe_beacon_channel',
              'Safe Beacon Notifications',
              channelDescription: 'Channel for Safe Beacon app notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        appLogger.info('Notification tapped — details: ${details.payload}');
      },
    );

    await createLocalNotificationChannel();
  }

  /// Listens for FCM token rotation and invokes [onRefresh] with the current
  /// uid and new token whenever the token changes.
  void listenToTokenRefresh(
    Future<void> Function(String uid, String token) onRefresh,
  ) {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      try {
        await onRefresh(uid, token);
        appLogger.info('FCM token refreshed and saved for uid: $uid');
      } catch (e) {
        appLogger.warning('Failed to save refreshed FCM token: $e');
      }
    });
  }

  /// Gets a valid access token for the Firebase Cloud Messaging API using a
  /// service account. This is used for server-to-server communication to send
  /// push notifications.
  Future<AccessCredentials> _getAccessToken() async {
    final serviceAccountPath = dotenv.env['PATH_TO_SECRET'];

    final String serviceAccountJson = await rootBundle.loadString(
      serviceAccountPath!,
    );

    final serviceAccount = ServiceAccountCredentials.fromJson(
      serviceAccountJson,
    );

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(serviceAccount, scopes);
    return client.credentials;
  }

  // Sends a push notification to the device with [deviceToken] using the FCM API.
  Future<bool> sendPushNotification({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (deviceToken.isEmpty) return false;

    final credentials = await _getAccessToken();
    final accessToken = credentials.accessToken.data;
    final projectId = dotenv.env['PROJECT_ID'];

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
    );

    final message = {
      'message': {
        'token': deviceToken,
        'notification': {'title': title, 'body': body},
        'data': data ?? {},
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      appLogger.info('Notification sent successfully.');
      return true;
    } else {
      appLogger.warning('Failed to send notification: ${response.body}');
      return false;
    }
  }

  // Creates a local notification channel for Android devices. This is required to
  // display notifications when the app is in the foreground.
  Future<void> createLocalNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'safe_beacon_channel',
      'Safe Beacon Notifications',
      description: 'Channel for Safe Beacon app notifications',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }
}
