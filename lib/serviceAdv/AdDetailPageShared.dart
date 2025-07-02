import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:googleapis/cloudsearch/v1.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../chat/screens/screens.dart';
import '../chat/services/services.dart';
import '../mainScreens/HomeView.dart';
import '../mainScreens/SplashScreen.dart';
import '../utils/Profile.dart';

class AdDetailPageShared extends StatefulWidget {
  final String id;
  final Profile profile;

  const AdDetailPageShared({Key? key, required this.id,required this.profile}) : super(key: key);

  @override
  _AdDetailPageSharedState createState() => _AdDetailPageSharedState();
}

class _AdDetailPageSharedState extends State<AdDetailPageShared> {
  String locationName = 'Caricamento...';
  bool isLocationLoaded = false;
  bool isDataLoaded = false;
  Map<String, dynamic> adData = {};

  @override
  void initState() {
    super.initState();

    _loadAdData();
  }

  Future<void> _loadAdData() async {
    if (widget.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ID annuncio non valido')),
      );
      setState(() {
        isDataLoaded = true;
      });
      return;
    }

      print('ottenuto id : ${widget.id}');

    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('ads').doc(widget.id).get();
      if (docSnapshot.exists) {
        setState(() {
          adData = docSnapshot.data() as Map<String, dynamic>;
          isDataLoaded = true;
        });
        _getLocationName(adData['location'] as GeoPoint?);
      } else {
        setState(() {
          isDataLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading ad data: $e');
      setState(() {
        isDataLoaded = true;
      });
    }
  }

  Future<void> _getLocationName(GeoPoint? location) async {
    if (location != null && !isLocationLoaded) {
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

            if (mounted) {
              setState(() {
                locationName = locality.isNotEmpty && country.isNotEmpty
                    ? '$locality, $country'
                    : decodedResponse['results'][0]['formatted_address'];
                isLocationLoaded = true;
              });
            }
          } else {
            _setLocationError('Indirizzo non trovato');
          }
        } else {
          _setLocationError('Errore nel recupero dell\'indirizzo');
        }
      } catch (e) {
        _setLocationError('Errore nel recupero dell\'indirizzo');
      }
    } else if (location == null) {
      _setLocationError('Posizione non disponibile');
    }
  }

  void _setLocationError(String errorMessage) {
    if (mounted) {
      setState(() {
        locationName = errorMessage;
        isLocationLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeView(profile: widget.profile, id: '')),
        );
        return false;
      },
      child: Scaffold(
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
          title: Text('Dettagli Annuncio', style: TextStyle(color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        body: isDataLoaded ? _buildAdDetails() : Center(child: CircularProgressIndicator()),
      ),
    );
  }



  Widget _buildAdDetails() {
    if (adData.isEmpty) {
      return Center(child: Text('Annuncio non trovato ${widget.id}'));
    }

    final imageUrl = adData['imageUrl'] ?? '';
    final title = adData['title'] ?? 'Titolo non disponibile';
    final description = adData['description'] ?? 'Descrizione non disponibile';
    final rate = adData['rate'] ?? 0;
    final daysAvailable = adData['daysAvailable'] ?? [];
    final startTime = _formatTime((adData['startTime'] as Timestamp).toDate());
    final endTime = _formatTime((adData['endTime'] as Timestamp).toDate()) ;
    final radius = adData['radius'] ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
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
                Center(
                  child:
                  ElevatedButton(
                    onPressed: () async{
                      // Implementa l'apertura della chat con l'utente
                      String chatId = await ChatService().createOrGetChat(
                          widget.profile.userId, adData['userId'], widget.id);
                      Navigator.push(context, MaterialPageRoute(builder: (builder) =>
                          ChatScreen(
                            chatId: chatId,
                            otherUserId: adData['userId'],
                            userId: widget.profile.userId,
                            adId:widget.id,
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
                  )),
              ],
            ),
          ),
        ],
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
              children: content.split(', ').map((day) => Chip(
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