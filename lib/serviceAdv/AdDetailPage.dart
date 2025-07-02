import 'dart:convert';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../chat/models/models.dart';
import '../chat/screens/screens.dart';
import '../chat/services/services.dart';
import '../mainScreens/HomeView.dart';
import '../utils/Profile.dart';

class AdDetailPage extends StatefulWidget {
  final AdModel ad;
  final String id;
  final String userId;

  const AdDetailPage({Key? key, required this.ad, required this.id, required this.userId}) : super(key: key);

  @override
  _AdDetailPageState createState() => _AdDetailPageState();
}

class _AdDetailPageState extends State<AdDetailPage> {
  String locationName = 'Caricamento...';
  String chatId = '';
  String otherUserId = '';
  Profile? otherUser;
  @override
  void initState() {
    super.initState();
    _getLocationName();
    otherUserId = widget.ad.userId;


    getUserData(otherUserId);
  }

  void getUserData(String userId) async{
    final userRef = FirebaseDatabase.instance.ref('users/' + otherUserId);
    final event = await userRef.once();

    if (event.snapshot.value != null) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      otherUser = Profile.fromMap(data);
    }
  }

  Future<void> _getLocationName() async {
    final location = widget.ad.location;
    if (location != null) {
      try {
        final response = await http.get(Uri.parse(
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=AIzaSyBGMVE-QILJSlLfbYQEcs05O6a66CSUops'));

        if (response.statusCode == 200) {
          final decodedResponse = json.decode(response.body);
          if (decodedResponse['results'].isNotEmpty) {
            final addressComponents = decodedResponse['results'][0]['address_components'];
            String locality = '';
            String country = '';

            for (var component in addressComponents) {
              if (component['types'].contains('locality')) {
                locality = component['long_name'];
              }
              if (component['types'].contains('country')) {
                country = component['long_name'];
              }
            }

            setState(() {
              locationName = locality.isNotEmpty && country.isNotEmpty
                  ? '$locality, $country'
                  : decodedResponse['results'][0]['formatted_address'];
            });
          } else {
            setState(() {
              locationName = 'Indirizzo non trovato';
            });
          }
        } else {
          setState(() {
            locationName = 'Errore nel recupero dell\'indirizzo';
          });
        }
      } catch (e) {
        setState(() {
          locationName = 'Errore nel recupero dell\'indirizzo';
        });
      }
    } else {
      setState(() {
        locationName = 'Posizione non disponibile';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.ad.imageUrl ?? '';
    final title = widget.ad.title;
    final description = widget.ad.description;
    final rate = widget.ad.rate;
    final daysAvailable = widget.ad.daysAvailable;
    final location = widget.ad.location;
    final radius = widget.ad.radius;
    final startTime = _formatTime(widget.ad.startTime);
    final endTime = _formatTime(widget.ad.endTime);

    return Scaffold(
      bottomNavigationBar: Container(
        height: 50,
        child: AdWidget(ad: BannerAd(
          adUnitId: 'ca-app-pub-1684693149887110/5721835277', // Replace with your actual ad unit ID
          size: AdSize.banner,
          request: AdRequest(),
          listener: BannerAdListener(),
        )..load()),
      ),
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              String id = widget.id;
              Share.share(
                  'Dai un\'occhiata a questo annuncio: https://exchange-hub-5cdf3.web.app/?code=$id');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    '$rate €/h',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                  ),
                  SizedBox(height: 16.0),
                  _buildInfoSection('Descrizione', description),
                  _buildInfoSection('Disponibilità', '${daysAvailable.join(", ")}'),
                  _buildInfoSection('Orario', '$startTime - $endTime'),
                  _buildInfoSection('Luogo', locationName),
                  _buildInfoSection('Raggio di Copertura', '${radius.toStringAsFixed(1)} km'),
                  SizedBox(height: 24.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) =>
                          ProfilePage(profile: otherUser!)));
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage((otherUser == null)? '' : otherUser!.profilePicture),
                          radius: 20,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          (otherUser == null)? '' :
                          '${otherUser!.fullName}',
                          style: TextStyle(fontSize: 16.0, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.0),
                  if (widget.userId != widget.ad.userId)
                  ElevatedButton(
                    onPressed: () async {
                      chatId = await ChatService().createOrGetChat(
                          widget.userId, widget.ad.userId, widget.id);
                      Navigator.push(context, MaterialPageRoute(builder: (builder) =>
                          ChatScreen(
                            chatId: chatId,
                            otherUserId: otherUserId,
                            userId: widget.userId,
                            adId: widget.ad.id,
                          )));
                    },
                    child: Text('Contatta'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                    ),
                  )
else
  SizedBox(height: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 4.0),
          if (title == 'Disponibilità')
            Wrap(
              spacing: 8.0,
              children: content.split(', ').map((day) =>
                  Chip(
                    label: Text(day),
                    backgroundColor: Colors.blue[700],
                    labelStyle: TextStyle(color: Colors.white),
                  )).toList(),
            )
          else if (title == 'Orario')
            Text(
              content,
              style: TextStyle(fontSize: 16.0, color: Colors.blue[700], fontWeight: FontWeight.bold),
            )
          else
            Text(
              content,
              style: TextStyle(fontSize: 16.0, color: Colors.black54),
            ),
          SizedBox(height: 8.0),
          Divider(color: Colors.grey[300]),
        ],
      ),
    );
  }
}