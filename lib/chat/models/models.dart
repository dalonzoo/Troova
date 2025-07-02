import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/Profile.dart';
class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String profilePicture;
  final String phoneNumber;
  final String preferredLanguage;
  final String bio;
  final int age;
  final List<String> skillsOffered;
  final List<String> skillsNeeded;
  final int credits;
  final String verificationStatus;
  final DateTime registrationDate;
  final DateTime lastLogin;
  final NotificationPreferences notificationPreferences;
  final PrivacySettings privacySettings;
  final SocialMediaLinks socialMediaLinks;
  final List<VerificationDocument> verificationDocuments;
  String? fcmToken;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.profilePicture,
    required this.phoneNumber,
    required this.preferredLanguage,
    required this.bio,
    required this.age,
    required this.skillsOffered,
    required this.skillsNeeded,
    required this.credits,
    required this.verificationStatus,
    required this.registrationDate,
    required this.lastLogin,
    required this.notificationPreferences,
    required this.privacySettings,
    required this.socialMediaLinks,
    required this.verificationDocuments,
    this.fcmToken,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      fullName: data['name'] ?? '',
      email: data['email'] ?? '',
      profilePicture: data['profilePicture'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      preferredLanguage: data['preferredLanguage'] ?? '',
      bio: data['bio'] ?? '',
      age: data['age'] ?? 0,
      skillsOffered: List<String>.from(data['skillsOffered'] ?? []),
      skillsNeeded: List<String>.from(data['skillsNeeded'] ?? []),
      credits: data['credits'] ?? 0,
      verificationStatus: data['verificationStatus'] ?? '',
      registrationDate: DateTime.parse(data['registrationDate']),
      lastLogin: DateTime.parse(data['lastLogin']),
      notificationPreferences: NotificationPreferences.fromMap(data['notificationPreferences']),
      privacySettings: PrivacySettings.fromMap(data['privacySettings']),
      socialMediaLinks: SocialMediaLinks.fromMap(data['socialMediaLinks']),
      verificationDocuments: (data['verificationDocuments'] as List).map((doc) => VerificationDocument.fromMap(doc)).toList(),
      fcmToken: data['fcmToken'],
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      fullName: json['name'] as String,
      email: json['email'] as String,
      profilePicture: json['profilePicture'] as String,
      phoneNumber: json['phoneNumber'] as String,
      preferredLanguage: json['preferredLanguage'] as String,
      bio: json['bio'] as String,
      age: json['age'] as int,
      skillsOffered: List<String>.from(json['skillsOffered']),
      skillsNeeded: List<String>.from(json['skillsNeeded']),
      credits: json['credits'] as int,
      verificationStatus: json['verificationStatus'] as String,
      registrationDate: DateTime.parse(json['registrationDate']),
      lastLogin: DateTime.parse(json['lastLogin']),
      notificationPreferences: NotificationPreferences.fromMap(json['notificationPreferences']),
      privacySettings: PrivacySettings.fromMap(json['privacySettings']),
      socialMediaLinks: SocialMediaLinks.fromMap(json['socialMediaLinks']),
      verificationDocuments: (json['verificationDocuments'] as List).map((doc) => VerificationDocument.fromMap(doc)).toList(),
      fcmToken: json['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': fullName,
      'email': email,
      'profilePicture': profilePicture,
      'phoneNumber': phoneNumber,
      'preferredLanguage': preferredLanguage,
      'bio': bio,
      'age': age,
      'skillsOffered': skillsOffered,
      'skillsNeeded': skillsNeeded,
      'credits': credits,
      'verificationStatus': verificationStatus,
      'registrationDate': registrationDate.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'notificationPreferences': notificationPreferences.toMap(),
      'privacySettings': privacySettings.toMap(),
      'socialMediaLinks': socialMediaLinks.toMap(),
      'verificationDocuments': verificationDocuments.map((doc) => doc.toMap()).toList(),
      'fcmToken': fcmToken,
    };
  }
}

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