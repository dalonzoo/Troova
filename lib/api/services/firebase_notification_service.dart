import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troova/firebase_options.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey;

  FirebaseNotificationService({required this.navigatorKey});

  Future<void> initialize() async {
    print("init del notification service");
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await _firebaseMessaging.requestPermission().then((settings) {
      print("richiedo i permessi");
      _saveNotificationSettings(settings.authorizationStatus == AuthorizationStatus.authorized);
    });;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
    const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print("Handling notification tap");
        _handleNotificationTap(json.decode(response.payload ?? '{}'));
      },
    );

    // Handle incoming messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Handling foreground message");
      _showNotification(message);
    });

    // Handle notification tap when the app is in the background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Handling background tap");
      _handleNotificationTap(message.data);
    });

    // Check if the app was opened from a notification while it was terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print("Handling initial message");
      _handleNotificationTap(initialMessage.data);
    }

    // Check for saved notifications
    await _checkSavedNotification();
  }

  Future<void> _saveNotificationSettings(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', isEnabled);
  }

  Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_id',
            'channel_name',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) async{
    print("Handling notification tap with data: $data");

    if (data.isNotEmpty && data['chatId'] != null) {
      print("Navigating to chat screen");
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // Save the notification data for later handling
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastNotification', json.encode(data));

      // Read and print the saved notification data for verification
      final savedNotificationString = prefs.getString('lastNotification');
      print("Saved notification data: $savedNotificationString");
    } else {
      print("Invalid notification data");
    }
  }

  Future<void> _checkSavedNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotificationString = prefs.getString('lastNotification');
    if (savedNotificationString != null) {
      final savedNotification = json.decode(savedNotificationString);
      _handleNotificationTap(savedNotification);
    }
  }

  Future<void> _clearSavedNotificationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastNotification');
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

}