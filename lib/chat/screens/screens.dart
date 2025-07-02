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

import '../../customWidgets/customWidgets.dart';
import '../../serviceAdv/AdDetailPage.dart';
import '../../utils/Profile.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as Prov;

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

  void _openAdDetailsPage(AdModel adFuture) async {
    final ad = await adFuture;
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

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}



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

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String userId;

  ChatListItem({required this.chat, required this.userId});

  @override
  Widget build(BuildContext context) {
    final otherUserId = chat.participants.firstWhere((id) => id != userId);

    return FutureBuilder<Profile?>(
      future: DatabaseService().getUserById(otherUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(title: Text('Loading...'));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          print('Error: ${snapshot.error}');
          return ListTile(title: Text('Error loading user'));
        }

        final otherUser = snapshot.data!;
        final lastMessageTime = (chat.lastMessageTime);
        final now = DateTime.now();
        String formattedDate;

        if (lastMessageTime.year == now.year &&
            lastMessageTime.month == now.month &&
            lastMessageTime.day == now.day) {
          formattedDate = 'Oggi';
        } else if (lastMessageTime.year == now.year &&
            lastMessageTime.month == now.month &&
            lastMessageTime.day == now.day - 1) {
          formattedDate = 'Ieri';
        } else {
          formattedDate = DateFormat('dd/MM/yyyy').format(lastMessageTime);
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(otherUser.profilePicture),
          ),
          title: Text(otherUser.fullName),
          subtitle: Text(chat.lastMessage),
          trailing: Text(formattedDate),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chat.id,
                  userId: userId,
                  otherUserId: otherUserId,
                  adId: chat.adId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AdDetailScreen extends StatelessWidget {
  final String adId;
  final String sellerId;
  final String userId;
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  AdDetailScreen({required this.adId, required this.sellerId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ad Details')),
      body: Center(
        child: ElevatedButton(
          child: Text('Contact Seller'),
          onPressed: () async {
            final currentUser = await _authService.getCurrentUser();
            if (currentUser != null) {
              final chatId = await _chatService.createOrGetChat(currentUser.userId, sellerId, adId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(chatId: chatId, otherUserId: sellerId, userId: userId, adId: adId,),
                ),
              );
            } else {
              // Gestisci il caso in cui l'utente non è autenticato
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please log in to contact the seller')),
              );
            }
          },
        ),
      ),
    );
  }
}