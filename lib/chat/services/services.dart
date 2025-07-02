import 'dart:convert';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../../utils/Profile.dart';
import '../models/models.dart';
import 'localDatabaseService.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      return UserModel.fromDocument(doc);
    }
    return null;
  }

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String> getCurrentUserId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }
    return user.uid;
  }
}



class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabaseService _localDB = LocalDatabaseService.instance;

  Future<void> sendMessage(String chatId, MessageModel message) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').add(message.toMap());

    // Update last message in chat document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message.text,
      'lastMessageTime': message.timestamp,
    });

    DocumentSnapshot chatDoc = await _firestore.collection('chats').doc(chatId).get();
    List<String> participants = List<String>.from(chatDoc['participants']);
    String adId = chatDoc['adId'];
    String otherUserId = participants.firstWhere((id) => id != message.senderId);
    String userId = participants.firstWhere((id) => id == message.senderId);
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(otherUserId);
    DataSnapshot userSnapshot = await userRef.get();

    String? fcmToken = userSnapshot.child('token').value as String?;

    if (fcmToken != null) {
      // Send FCM notification
      String name = await userSnapshot.child('name').value as String;
      await FCMService().sendNotification(
        additionalData: {
          'chatId': chatId,
          'userId': userId,
          'otherUserId': otherUserId,
          'adId': adId,
        },
        recipientFCMToken: fcmToken,
        title: 'Nuovo messaggio da $name',
        body: '',
      );
      String accessToken = await FCMService()._getAccessToken();
      //await sendFcmNotification(fcmToken, message.text, chatId,accessToken,userId,otherUserId,adId);
    }
  }

  Future<void> sendFcmNotification(String fcmToken, String messageText, String chatId,String accessToken,String userId,String otherUserId,String adId) async {
    final Uri fcmUrl = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final Map<String, dynamic> notification = {
      'title': 'New Message',
      'body': messageText,
    };

    final Map<String, dynamic> data = {
      'chatId': chatId,
      'userId': userId,
          'otherUserId': otherUserId,
      'adId': adId
    };

    final Map<String, dynamic> payload = {
      'to': fcmToken,
      'notification': notification,
      'data': data,
    };

    final http.Response response = await http.post(
      fcmUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      }
      ,
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      print(response.body.toString());
      throw Exception('Failed to send FCM notification');
    }
  }
  Future<void> updateUserFcmToken(String userId, String fcmToken) async {
    await _firestore.collection('users').doc(userId).update({'token': fcmToken});
  }
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) => MessageModel.fromDocument(doc)).toList();
      // Salva i messaggi localmente
      for (var message in messages) {
        _localDB.saveMessage(chatId, message);
      }
      return messages;
    });
  }

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime',descending: true)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs.map((doc) => ChatModel.fromDocument(doc)).toList();
      // Salva le chat localmente
      for (var chat in chats) {
        _localDB.saveChat(chat);
      }
      return chats;
    });
  }

  Future<String> createOrGetChat(String userId1, String userId2, String adId) async {
    // Controlla se esiste già una chat locale
    String? chatId = await _localDB.getChatId(userId1, userId2, adId);
    print("ottengo chatid:$chatId");
    if (chatId == null || chatId.isEmpty) {
      // Se non esiste localmente, crea una nuova chat su Firestore
      final chatDoc = await _firestore.collection('chats').add({
        'participants': [userId1, userId2],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'adId': adId,
        'id': '',
      });
      chatId = chatDoc.id;
      await chatDoc.update({'id': chatId});
      // Salva la nuova chat localmente
      final newChat = ChatModel(
        id: chatId,
        participants: [userId1, userId2],
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        adId: adId,
      );
      await _localDB.saveChat(newChat);
    }

    if (chatId.isEmpty) {
      throw Exception('Failed to create or retrieve chat ID');
    }

    return chatId;
  }
}

class FCMService {

//get the access token with the .json file downloaded from google cloud console
  Future<String> _getAccessToken() async {
    try {
      //the scope url for the firebase messaging
      String firebaseMessagingScope =
          'https://www.googleapis.com/auth/firebase.messaging';


      final client = await clientViaServiceAccount(
          ServiceAccountCredentials.fromJson({
          "type": "service_account",
              "project_id": dotenv.env['FIREBASE_PROJECT_ID'],
              "private_key_id": dotenv.env['PRIVATE_KEY_ID'],
              "private_key": dotenv.env['PRIVATE_KEY'],
              "client_email": dotenv.env['CLIENT_MAIL'],
              "client_id": dotenv.env['CLIENT_ID'],
              "auth_uri": "https://accounts.google.com/o/oauth2/auth",
              "token_uri": "https://oauth2.googleapis.com/token",
              "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
              "client_x509_cert_url": dotenv.env['CLIENT_X509_CERT_URI'],
              "universe_domain": "googleapis.com"
          }
              ),
          [firebaseMessagingScope]);

      final accessToken = client.credentials.accessToken.data;
      return accessToken;
    } catch (_) {
      //handle your error here
      print('Error: $_');
      throw Exception('Error getting access token');
    }
  }

// SEND NOTIFICATION TO A DEVICE
  Future<bool> sendNotification(
      {required String recipientFCMToken,
        required String title,
        required String body,
        Map<String, dynamic>? additionalData}) async {
    final String accessToken = await _getAccessToken();
    //Input the project_id value in the .json file downloaded from the google cloud console
    final String? projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final String fcmEndpoint = "https://fcm.googleapis.com/v1/projects/${projectId}";
    final url = Uri.parse('$fcmEndpoint/messages:send');
    print("ricevuto $accessToken");
    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final Map<String, dynamic> data = {
      "chatId": additionalData?['chatId'] ?? '',
      "userId": additionalData?['userId'] ?? '',
      "otherUserId": additionalData?['otherUserId'] ?? '',
      "adId": additionalData?['adId'] ?? '',
      // Aggiungi qui altri campi che desideri inviare
    };

    final reqBody = jsonEncode(
      {
        "message": {
          "token": recipientFCMToken,
          "notification": {"body": body, "title": title},
          "android": {
            "notification": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
            }
          },
          "apns": {
            "payload": {
              "aps": {"category": "NEW_NOTIFICATION"}
            }
          },
          "data": data,
        }
      },
    );

    try {
      final response = await http.post(url, headers: headers, body: reqBody);
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (_) {
      //handle your error here
      print("errore in SenfFCM $_");
      return false;
    }
  }
}




class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserData(UserModel user) async {
    await _firestore.collection('users').doc(user.userId).update({
      'fullName': user.fullName,
      'email': user.email,
      'profilePicture': user.profilePicture,
    });
  }

  Future<Profile?> getUserById(String userId) async {
    print("cerco $userId");
    final databaseReference = FirebaseDatabase.instance.ref();
    final snapshot = await databaseReference.child('users').child(userId).get();

    if (snapshot.exists) {
      return Profile.fromMap(snapshot.value as Map<dynamic, dynamic>);
    }
    print("ritorno null");
    return null;
  }

  Future<AdModel?> getAdById(String adId) async {
    DocumentSnapshot doc = await _firestore.collection('ads').doc(adId).get();
    if (doc.exists) {
      return AdModel.fromDocument(doc);
    }
    return null;
  }
}



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
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // Handle iOS foreground notification
        _handleNotificationTap(json.decode(payload ?? '{}'));
      },
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







