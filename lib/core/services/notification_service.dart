import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../widgets/esport_toast.dart';
import '../../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications such as team updates and match reminders.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  StreamSubscription<QuerySnapshot>? _userNotifSubscription;
  StreamSubscription<User?>? _authSubscription;
  final Set<String> _seenNotificationIds = <String>{};

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Initialize Flutter Local Notifications for system status bar / notification drawer
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    try {
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Create Notification Channel for Android
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_channel);
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }

    // 2. Request FCM permissions
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      }
    } catch (e) {
      debugPrint('Error requesting FCM permission: $e');
    }

    // 3. Get and save FCM Token
    try {
      String? token = await _fcm.getToken();
      debugPrint("FCM Token: $token");
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // 4. Subscribe to general topic
    try {
      await _fcm.subscribeToTopic('general');
    } catch (_) {}

    // 5. Listen to token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM Token refreshed: $newToken");
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'fcmToken': newToken,
        }, SetOptions(merge: true));
      }
    });

    // 6. Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 7. Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    // 8. Auth state listener to automatically listen to user notifications
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        startListeningToUserNotifications(user.uid);
      } else {
        stopListeningToUserNotifications();
      }
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      startListeningToUserNotifications(currentUser.uid);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    if (message.notification != null) {
      final title = message.notification!.title ?? 'إشعار جديد';
      final body = message.notification!.body ?? '';

      ToastType type = ToastType.success;
      final typeStr = message.data['type'];
      if (typeStr == 'urgent' || typeStr == 'team_rejected') type = ToastType.urgent;
      if (typeStr == 'social' || typeStr == 'team_accepted') type = ToastType.social;
      if (typeStr == 'wallet') type = ToastType.wallet;

      showSystemNotification(
        title: title,
        body: body,
        type: type,
        payload: message.data.toString(),
      );
    }
  }

  Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
    ToastType type = ToastType.success,
  }) async {
    try {
      // 1. Show notification in phone's notification bar (شريط الإشعارات)
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error displaying local notification: $e');
    }

    // 2. Also show in-app toast if context is mounted
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      final overlay = Overlay.maybeOf(context);
      if (overlay != null) {
        showTopSnackBar(
          overlay,
          ESportToast(
            title: title,
            message: body,
            type: type,
          ),
          displayDuration: const Duration(seconds: 4),
          animationDuration: const Duration(milliseconds: 500),
        );
      }
    }
  }

  void startListeningToUserNotifications(String uid) {
    _userNotifSubscription?.cancel();
    final DateTime sessionStartTime = DateTime.now().subtract(const Duration(seconds: 10));

    _userNotifSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(15)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final docId = change.doc.id;
          if (_seenNotificationIds.contains(docId)) continue;
          _seenNotificationIds.add(docId);

          final data = change.doc.data();
          if (data == null) continue;

          // If marked read, skip showing in notification bar
          if (data['isRead'] == true) continue;

          // Check if notification was created within this session or very recently
          final createdAt = data['createdAt'];
          if (createdAt is Timestamp) {
            final notifTime = createdAt.toDate();
            if (notifTime.isBefore(sessionStartTime)) {
              continue;
            }
          }

          final title = data['title']?.toString() ?? 'إشعار جديد';
          final body = data['body']?.toString() ?? '';
          final typeStr = data['type']?.toString();

          ToastType toastType = ToastType.success;
          if (typeStr == 'urgent' || typeStr == 'team_rejected') toastType = ToastType.urgent;
          if (typeStr == 'social' || typeStr == 'team_accepted') toastType = ToastType.social;
          if (typeStr == 'wallet') toastType = ToastType.wallet;

          showSystemNotification(
            title: title,
            body: body,
            type: toastType,
          );
        }
      }
    }, onError: (e) {
      debugPrint('Error listening to user notifications: $e');
    });
  }

  void stopListeningToUserNotifications() {
    _userNotifSubscription?.cancel();
    _userNotifSubscription = null;
    _seenNotificationIds.clear();
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
