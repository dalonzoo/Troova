import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String title;
  final String description;
  final int rate;
  final List<String> daysAvailable;
  final DateTime startTime;
  final DateTime endTime;
  final GeoPoint location;
  final double radius;
  final DateTime timestamp;
  final String userId;
  final String? imageUrl;

  AdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rate,
    required this.daysAvailable,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.radius,
    required this.timestamp,
    required this.userId,
    this.imageUrl,
  });

  factory AdModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      rate: data['rate'] ?? 0,
      daysAvailable: List<String>.from(data['daysAvailable'] ?? []),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint,
      radius: (data['radius'] as num).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'rate': rate,
      'daysAvailable': daysAvailable,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'radius': radius,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      rate: json['rate'] ?? 0,
      daysAvailable: List<String>.from(json['daysAvailable'] ?? []),
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      location: json['location'] as GeoPoint,
      radius: (json['radius'] as num).toDouble(),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      userId: json['userId'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}