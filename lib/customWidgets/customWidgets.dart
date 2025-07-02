import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../chat/models/models.dart';
import '../chat/screens/screens.dart';
import '../chat/services/services.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Material(
            borderRadius: BorderRadius.circular(30.0),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 5.0),
            child: Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


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