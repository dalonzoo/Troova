import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  String lastMessage;
  DateTime lastMessageTime;
  final String adId;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.adId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': jsonEncode(participants),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'adId': adId,
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      participants: List<String>.from(jsonDecode(json['participants'])),
      lastMessage: json['lastMessage'],
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(json['lastMessageTime']),
      adId: json['adId'],
    );
  }

  factory ChatModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      adId: data['adId'] ?? '',
    );
  }
}