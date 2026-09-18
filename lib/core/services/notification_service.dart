import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../widgets/esport_toast.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize(BuildContext context) async {
    // Request permissions for iOS and newer Android versions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }

    // Get FCM Token
    String? token = await _fcm.getToken();
    debugPrint("FCM Token: $token");
    // Optionally: Update token in Firestore User document here

    // Listen to token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint("FCM Token refreshed: $newToken");
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(context, message);
    });
  }

  void _showForegroundNotification(BuildContext context, RemoteMessage message) {
    if (message.notification != null) {
      // Determine type based on data payload
      ToastType type = ToastType.success;
      final typeStr = message.data['type'];
      if (typeStr == 'urgent') type = ToastType.urgent;
      if (typeStr == 'social') type = ToastType.social;
      if (typeStr == 'wallet') type = ToastType.wallet;

      showTopSnackBar(
        Overlay.of(context),
        ESportToast(
          title: message.notification!.title ?? 'إشعار جديد',
          message: message.notification!.body ?? '',
          type: type,
        ),
        displayDuration: const Duration(seconds: 4),
        animationDuration: const Duration(milliseconds: 500),
      );
    }
  }

  // Sync Topics based on UserSettings
  Future<void> syncTopicSubscriptions(dynamic settings) async {
    try {
      if (settings.tournamentNotifs) {
        await _fcm.subscribeToTopic('tournaments');
        debugPrint('Subscribed to tournaments topic');
      } else {
        await _fcm.unsubscribeFromTopic('tournaments');
        debugPrint('Unsubscribed from tournaments topic');
      }

      if (settings.matchReminders) {
        await _fcm.subscribeToTopic('match_reminders');
      } else {
        await _fcm.unsubscribeFromTopic('match_reminders');
      }

    } catch (e) {
      debugPrint('Error syncing FCM topics: $e');
    }
  }

  // Helper method to show toast manually from inside the app without FCM
  static void showCustomToast(
    BuildContext context, {
    required String title,
    required String message,
    ToastType type = ToastType.success,
  }) {
    showTopSnackBar(
      Overlay.of(context),
      ESportToast(
        title: title,
        message: message,
        type: type,
      ),
      displayDuration: const Duration(seconds: 4),
    );
  }
}
