import 'dart:convert';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_autocomplete_text_field/model/prediction.dart';

import '../utils/Profile.dart';
import 'ProfileSkillsPage.dart';
const String googleApiKey = 'AIzaSyB-pXAgFOG-ipJCOFO63ZazQ4_8OpoKm_w';

class ContactInfoPage extends StatefulWidget {
  final Profile profile;

  ContactInfoPage({required this.profile});

  @override
  _ContactInfoPageState createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  String _selectedLanguage = 'Italiano';
  List<String> languages = ['Italiano', 'English', 'Español'];
  final _googleAPIKey = 'AIzaSyB-pXAgFOG-ipJCOFO63ZazQ4_8OpoKm_w';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titolo
              Text(
                'Contatti e Indirizzo',
                style: GoogleFonts.poppins(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 20),

              // Campo Indirizzo con Google Places Autocomplete
              _buildCittaTextField(),
              const SizedBox(height: 20),

              // Campo Lingua Preferita
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                items: languages.map((String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Lingua Preferita',
                  labelStyle: TextStyle(color: Colors.blueGrey[600]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blueGrey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blueGrey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blue[400]!),
                  ),
                  prefixIcon: Icon(Icons.language, color: Colors.blueGrey[600]),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue!;
                  });
                },
              ),
              const Spacer(),

              // Pulsante Avanti
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Validazione dei campi e navigazione alla prossima schermata
                    if (_addressController.text.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileSkillsPage(
                            profile: widget.profile,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Compila tutti i campi per continuare')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15.0),
                    backgroundColor: Colors.blue[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    'Avanti',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCittaTextField() {
    return GooglePlacesAutoCompleteTextFormField(
      textEditingController: _addressController,
      googleAPIKey: _googleAPIKey,
      decoration: InputDecoration(
        labelText: 'Inserisci la tua posizione',
        labelStyle: TextStyle(color: Colors.blueGrey[600]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.blueGrey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.blueGrey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.blue[400]!),
        ),
        prefixIcon: Icon(Icons.location_on, color: Colors.blueGrey[600]),
      ),
      countries: ['it'],
      isLatLngRequired: true,
      getPlaceDetailWithLatLng: (Prediction prediction) async {
        final placeDetails = await getPlaceDetails(prediction.placeId!);
        widget.profile.address.city = prediction.description!;
        widget.profile.address.latitude = placeDetails['lat'] ?? 0.0;
        widget.profile.address.longitude = placeDetails['lng'] ?? 0.0;
        print('Latitudine: ${placeDetails['lat']}, Longitudine: ${placeDetails['lng']}');
      },
      itmClick: (Prediction prediction) {
        _addressController.text = prediction.description!;
        _addressController.selection = TextSelection.fromPosition(
          TextPosition(offset: prediction.description!.length),
        );
      },
    );
  }

  Future<Map<String, double>> getPlaceDetails(String placeId) async {
    final response = await http.get(
      Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=$_googleAPIKey'),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final location = json['result']['geometry']['location'];
      return {
        'lat': location['lat'],
        'lng': location['lng'],
      };
    } else {
      throw Exception('Failed to load place details');
    }
  }
}

class AddressSearch extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
