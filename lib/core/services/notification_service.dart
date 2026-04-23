import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'database_repository.dart';
import '../../features/auth/data/auth_repository.dart';

part 'notification_service.g.dart';

@riverpod
class NotificationService extends _$NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  @override
  void build() {
    // Automatically register device when user logs in
    ref.listen(authStateChangesProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        registerDevice(user.uid);
      }
    });
  }

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Handle background messages (Android mostly)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // You could show a local notification here if needed
      }
    });

    // 4. Handle notification click when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // Navigate to the group if groupId is present
    });
  }

  Future<void> registerDevice(String userId) async {
    try {
      String? token;
      if (Platform.isIOS) {
        token = await _fcm.getAPNSToken();
      } else {
        token = await _fcm.getToken();
      }

      if (token != null) {
        debugPrint('FCM Token: $token');
        await ref.read(databaseRepositoryProvider).saveDeviceToken(userId, token);
      }
    } catch (e) {
      debugPrint('Error registering device token: $e');
    }
  }
}

// Global background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
