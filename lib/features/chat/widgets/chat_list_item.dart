import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:troova/models/chat_model.dart';
import 'package:troova/api/services/database_service.dart';
import 'package:troova/shared/profile.dart';
import 'package:troova/features/chat/screens/chat_screen.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String userId;
  final String adId;
  final DatabaseService _databaseService = DatabaseService();

  ChatListItem({required this.chat, required this.userId, required this.adId});

  @override
  Widget build(BuildContext context) {
    String otherUserId = chat.participants.firstWhere(
          (id) => id != 'xxx', // Replace with actual current user ID
      orElse: () => '',
    );

    return FutureBuilder(
      future: _databaseService.getUserById(otherUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(title: Text('Loading...'));
        }
        if (snapshot.hasError) {
          print(snapshot.error.toString());
          return ListTile(title: Text('Error loading user'));
        }
        final otherUser = snapshot.data;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(otherUser?.profilePicture ?? ''),
          ),
          title: Text(otherUser?.fullName ?? 'Unknown User'),
          subtitle: Text(
            chat.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            DateFormat('dd/MM/yy').format(chat.lastMessageTime),
            style: TextStyle(color: Colors.grey),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chat.id,
                  otherUserId: otherUserId, userId: userId, adId: adId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}