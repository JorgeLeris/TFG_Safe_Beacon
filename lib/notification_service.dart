import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _firebaseMessaging.requestPermission();

    // TODO: change saving token to login and register, also delete token on logout
    final token = await _firebaseMessaging.getToken();
    print('Firebase Messaging Token: $token');

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
}
