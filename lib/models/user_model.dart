import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:troova/shared/profile.dart';

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