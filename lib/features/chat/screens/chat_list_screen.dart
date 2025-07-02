import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

// File: chat_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:googleapis/connectors/v1.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:troova/shared/profile.dart';
import 'package:troova/models/chat_model.dart';
import 'package:troova/api/services/auth_service.dart';
import 'package:troova/api/services/chat_service.dart';
import 'package:troova/features/chat/widgets/chat_list_item.dart';
import 'package:troova/features/chat/screens/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String userId;

  ChatListScreen({required this.userId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Prov.Provider.of<AuthService>(context, listen: false);
    final chatService = Prov.Provider.of<ChatService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('My Chats')),
      bottomNavigationBar: Container(
        height: 50,
        child: AdWidget(ad: BannerAd(
          adUnitId: 'ca-app-pub-1684693149887110/5721835277', // Replace with your actual ad unit ID
          size: AdSize.banner,
          request: AdRequest(),
          listener: BannerAdListener(),
        )..load()),
      ),
      body: FutureBuilder<String>(
        future: authService.getCurrentUserId(),
        builder: (context, snapshot) {


          final currentUserId = widget.userId;

          return StreamBuilder<List<ChatModel>>(
            stream: chatService.getUserChats(currentUserId),
            builder: (context, chatSnapshot) {
              if (chatSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (chatSnapshot.hasError) {
                return Center(child: Text('Error loading chats: ${chatSnapshot.error}'));
              }

              final chats = chatSnapshot.data ?? [];

              if (chats.isEmpty) {
                return Center(child: Text('No chats available'));
              }

              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return ChatListItem(chat: chat, userId: widget.userId);
                },
              );
            },
          );
        },
      ),
    );
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    checkSavedNotifications();

  }

  void checkSavedNotifications() async{
    final prefs = await SharedPreferences.getInstance();
    final savedNotificationString = prefs.getString('lastNotification');
    if(savedNotificationString != null){
      // Rimuovi i dati salvati dopo averli utilizzati
      await prefs.remove('lastNotification');
      final savedNotification = json.decode(savedNotificationString);
      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(userId: widget.userId, chatId: savedNotification['chatId'], otherUserId: savedNotification['otherUserId'], adId: savedNotification['adId'],)));

    }
  }
}