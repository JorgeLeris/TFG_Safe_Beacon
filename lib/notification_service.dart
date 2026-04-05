import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:safe_beacon/app/monitoring/logging.dart';

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _firebaseMessaging.requestPermission();

    // Foreground: app is open and visible — notification is NOT shown automatically
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      appLogger.info(
        'Foreground message received — must handle display manually: ${message.messageId}',
      );
    });

    // Background: app is open but not visible — user tapped the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      appLogger.info(
        'Background notification tapped — app brought to foreground: ${message.messageId}',
      );
    });
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
}
