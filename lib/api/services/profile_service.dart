import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/apigeeregistry/v1.dart';
import 'package:googleapis/servicemanagement/v1.dart';
import 'package:troova/features/core/screens/HomeView.dart';
import 'package:troova/shared/profile.dart';

class ProfileService {
  Future<void> saveUserProfile(Profile profile, BuildContext context) async {
    try {



        profile.password = '';
        var database = FirebaseDatabase.instance;
        DatabaseReference ref = database.ref('users/' + profile.userId);

        await ref.set(profile.toJson()).onError((error, stackTrace) {
          print("Tentativo fallito");
          print(error);
        }).whenComplete(() {
          print("Completato");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeView(profile: profile, id: ''),
            ),
          );
        });

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('L\'indirizzo email è già in uso.');
      } else {
        print(e.message);
      }
    }
  }
}
