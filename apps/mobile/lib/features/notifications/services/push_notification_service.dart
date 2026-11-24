import 'dart:convert';
import '../../auth/models/user_profile.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../notification_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/notification_repository.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return PushNotificationService(repo, () => ref.read(authNotifierProvider).userProfile?.primaryRole);
});

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase initialization fallback in background isolate
  }
  if (kDebugMode) {
    print('[FCM Background] Message received: ${message.messageId}');
  }
}

class PushNotificationService {
  final NotificationRepository _notificationRepository;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  final AppUserRole? Function() _currentRole;

  PushNotificationService(this._notificationRepository, this._currentRole);

  /// Callback when a notification is tapped to perform safe deep linking
  void Function(String route)? onNotificationTapped;

  /// Initialize Firebase messaging, permissions, local notification channels & listeners
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Safe Firebase Core initialization
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request POST_NOTIFICATIONS permission on Android 13+ / iOS
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('[FCM] Permission status: ${settings.authorizationStatus}');
      }

      // 3. Initialize Flutter Local Notifications & Android Channels
      await _initializeLocalNotifications();

      // 4. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 5. Terminated / background click handlers
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message.data);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage.data);
      }

      // 6. Token registration & listener
      await _registerCurrentToken();
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen(_onTokenRefreshed);

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('[PushNotificationService] Firebase offline / unconfigured: $e');
      }
    }
  }

  /// Setup Android notification channels for high reliability
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _handleNotificationClick(data);
          } catch (_) {}
        }
      },
    );

    // Create 3 targeted Android Notification Channels
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'job_alerts',
          'Job Alerts / कार्य सूचनाएं',
          description: 'Instant notifications when new shifts match your skills and locality in Ghazipur.',
          importance: Importance.high,
          playSound: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'booking_updates',
          'Booking Updates / बुकिंग सूचनाएं',
          description: 'Confirmations and updates for your accepted shifts and staff assignments.',
          importance: Importance.high,
          playSound: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'shift_reminders',
          'Shift Reminders / शिफ्ट स्मरण',
          description: 'Urgent 24-hour and 2-hour duty pass alerts prior to shift gate arrival.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  /// Handle foreground message with local push banner
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final channelId = message.data['channel_id'] ?? 'job_alerts';

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _getChannelName(channelId),
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'shift_reminders':
        return 'Shift Reminders / शिफ्ट स्मरण';
      case 'booking_updates':
        return 'Booking Updates / बुकिंग सूचनाएं';
      case 'job_alerts':
      default:
        return 'Job Alerts / कार्य सूचनाएं';
    }
  }

  /// Safe deep link resolver mapping notification payloads to canonical routes
  void _handleNotificationClick(Map<String, dynamic> data) {
    onNotificationTapped?.call(notificationRoute(
      data['entity_type']?.toString(), data['entity_id']?.toString(), _currentRole(),
      jobId: data['job_id']?.toString(), event: data['event_type']?.toString(),
    ));
  }

  /// Register current FCM token into Supabase device_tokens registry
  Future<void> _registerCurrentToken() async {
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _notificationRepository.registerDeviceToken(
          installationId: 'mobile-app-${DateTime.now().millisecondsSinceEpoch}',
          fcmToken: token,
          platform: 'android',
          appVersion: '1.0.0',
        );
      }
    } catch (_) {}
  }

  /// Handle token refresh
  Future<void> _onTokenRefreshed(String newToken) async {
    await _notificationRepository.registerDeviceToken(
      installationId: 'mobile-app-refresh',
      fcmToken: newToken,
      platform: 'android',
      appVersion: '1.0.0',
    );
  }

  /// Deactivate device token on sign out
  Future<void> onSignOut() async {
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _notificationRepository.deactivateDeviceToken(token);
      }
    } catch (_) {}
  }
}
