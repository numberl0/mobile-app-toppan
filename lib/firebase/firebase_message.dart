import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class FirebaseMessage {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // 🛑 Request permission first BEFORE initializing local notifications
    await setupFCM();

    // ✅ Then initialize local notifications
    await initializeLocalNotifications();
  }

  /// Initialize local notifications
  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Set up Firebase Cloud Messaging (FCM)
  Future<void> setupFCM() async {
    // // ✅ Ask for iOS permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ✅ Tell iOS to show notifications while app is in foreground
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // ✅ Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📲 Foreground message received: ${message.notification?.title}");
      // ✅ Avoid showing manually if system already shows it
  if (message.notification != null && message.data.isEmpty) {
    // This message already shows a system notification — skip manual one
    return;
  }

  // ✅ Otherwise show manually (e.g., if it's a data-only message)
  showLocalNotification(message);
    });

    // ✅ Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Show local notification
  Future<void> showLocalNotification(RemoteMessage message) async {
    print('🔔 Showing local notification');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      Random().nextInt(100000),
      message.notification?.title ?? "No Title",
      message.notification?.body ?? "No Body",
      platformChannelSpecifics,
    );
  }
}
