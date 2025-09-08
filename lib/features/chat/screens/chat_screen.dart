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
import 'package:troova/models/ad_model.dart';
import 'package:troova/models/message_model.dart';
import 'package:troova/api/services/chat_service.dart';
import 'package:troova/api/services/database_service.dart';
import 'package:troova/features/ads/screens/AdDetailPage.dart';
import 'package:troova/features/chat/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String userId;
  final String adId;

  ChatScreen({
    required this.chatId,
    required this.userId,
    required this.otherUserId,
    required this.adId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  late Future<Profile?> _otherUserFuture;
  late Future<AdModel?> _adFuture;

  @override
  void initState() {
    super.initState();
    _otherUserFuture = DatabaseService().getUserById(widget.otherUserId);
    _adFuture = DatabaseService().getAdById(widget.adId);
  }

  void _openAdDetailsPage(AdModel ad) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdDetailPage(id: widget.adId, ad: ad, userId: widget.userId),
      ),
    );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: FutureBuilder<Profile?>(
          future: _otherUserFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Text('Chat');
            }
            return Text(snapshot.data!.fullName);
          },
        ),
      ),
      body: Column(
        children: [
          // Ad information card
          FutureBuilder<AdModel?>(
            future: _adFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return SizedBox();
              }
              final ad = snapshot.data!;
              return Card(
                margin: EdgeInsets.all(8),
                child: InkWell(
                  onTap: () => _openAdDetailsPage(ad),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        if (ad.imageUrl != null)
                          Image.network(
                            ad.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad.title,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${ad.rate} €/ora',
                                style: TextStyle(color: Colors.green),
                              ),
                              Text(
                                'Dalle ${_formatTime(ad.startTime)} alle ${_formatTime(ad.endTime)}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      isMe: message.senderId == widget.userId,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      final message = MessageModel(
                        id: widget.chatId,
                        senderId: widget.userId,
                        text: _messageController.text,
                        timestamp: DateTime.now(),
                      );
                      _chatService.sendMessage(widget.chatId, message);
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {

    return DateFormat('HH:mm').format(dateTime);
  }
}