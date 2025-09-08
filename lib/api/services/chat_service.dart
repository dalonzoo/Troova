import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:troova/models/chat_model.dart';
import 'package:troova/models/message_model.dart';
import 'package:troova/api/services/local_database_service.dart';
import 'package:troova/api/services/fcm_service.dart';

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
      String accessToken = await FCMService().getAccessToken();
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