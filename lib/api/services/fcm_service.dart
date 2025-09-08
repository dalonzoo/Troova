import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FCMService {

//get the access token with the .json file downloaded from google cloud console
  Future<String> getAccessToken() async {
    try {
      //the scope url for the firebase messaging
      String firebaseMessagingScope =
          'https://www.googleapis.com/auth/firebase.messaging';


      final client = await clientViaServiceAccount(
          ServiceAccountCredentials.fromJson({
          "type": "service_account",
              "project_id": dotenv.env['FIREBASE_PROJECT_ID'],
              "private_key_id": dotenv.env['PRIVATE_KEY_ID'],
              "private_key": dotenv.env['PRIVATE_KEY'],
              "client_email": dotenv.env['CLIENT_MAIL'],
              "client_id": dotenv.env['CLIENT_ID'],
              "auth_uri": "https://accounts.google.com/o/oauth2/auth",
              "token_uri": "https://oauth2.googleapis.com/token",
              "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
              "client_x509_cert_url": dotenv.env['CLIENT_X509_CERT_URI'],
              "universe_domain": "googleapis.com"
          }
              ),
          [firebaseMessagingScope]);

      final accessToken = client.credentials.accessToken.data;
      return accessToken;
    } catch (_) {
      //handle your error here
      print('Error: $_');
      throw Exception('Error getting access token');
    }
  }

// SEND NOTIFICATION TO A DEVICE
  Future<bool> sendNotification(
      {required String recipientFCMToken,
        required String title,
        required String body,
        Map<String, dynamic>? additionalData}) async {
    final String accessToken = await getAccessToken();
    //Input the project_id value in the .json file downloaded from the google cloud console
    final String? projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final String fcmEndpoint = "https://fcm.googleapis.com/v1/projects/${projectId}";
    final url = Uri.parse('$fcmEndpoint/messages:send');
    print("ricevuto $accessToken");
    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final Map<String, dynamic> data = {
      "chatId": additionalData?['chatId'] ?? '',
      "userId": additionalData?['userId'] ?? '',
      "otherUserId": additionalData?['otherUserId'] ?? '',
      "adId": additionalData?['adId'] ?? '',
      // Aggiungi qui altri campi che desideri inviare
    };

    final reqBody = jsonEncode(
      {
        "message": {
          "token": recipientFCMToken,
          "notification": {"body": body, "title": title},
          "android": {
            "notification": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
            }
          },
          "apns": {
            "payload": {
              "aps": {"category": "NEW_NOTIFICATION"}
            }
          },
          "data": data,
        }
      },
    );

    try {
      final response = await http.post(url, headers: headers, body: reqBody);
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (_) {
      //handle your error here
      print("errore in SenfFCM $_");
      return false;
    }
  }
}