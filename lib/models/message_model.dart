import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String text;
  final DateTime timestamp;
  final String senderId;

  MessageModel({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.senderId,
  });

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    return MessageModel(
      id: doc.id,
      text: doc['text'],
      timestamp: (doc['timestamp'] as Timestamp).toDate(),
      senderId: doc['senderId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'senderId': senderId,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['senderId'],
      text: json['text'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'senderId': senderId,
    };
  }
}