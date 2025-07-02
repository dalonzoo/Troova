import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:troova/api/services/auth_service.dart';
import 'package:troova/api/services/chat_service.dart';
import 'package:troova/features/chat/screens/chat_screen.dart';

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