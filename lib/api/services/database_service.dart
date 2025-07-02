import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:troova/models/user_model.dart';
import 'package:troova/models/ad_model.dart';
import 'package:troova/shared/profile.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserData(UserModel user) async {
    await _firestore.collection('users').doc(user.userId).update({
      'fullName': user.fullName,
      'email': user.email,
      'profilePicture': user.profilePicture,
    });
  }

  Future<Profile?> getUserById(String userId) async {
    print("cerco $userId");
    final databaseReference = FirebaseDatabase.instance.ref();
    final snapshot = await databaseReference.child('users').child(userId).get();

    if (snapshot.exists) {
      return Profile.fromMap(snapshot.value as Map<dynamic, dynamic>);
    }
    print("ritorno null");
    return null;
  }

  Future<AdModel?> getAdById(String adId) async {
    DocumentSnapshot doc = await _firestore.collection('ads').doc(adId).get();
    if (doc.exists) {
      return AdModel.fromDocument(doc);
    }
    return null;
  }
}