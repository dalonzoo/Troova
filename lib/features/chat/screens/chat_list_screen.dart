import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('My Chats')),
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
                  return ChatListItem(
                    chat: chat, 
                    userId: widget.userId,
                    adId: '', // Provide empty adId since we removed ads
                  );
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