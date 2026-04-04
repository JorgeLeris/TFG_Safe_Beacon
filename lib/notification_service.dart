import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
}
