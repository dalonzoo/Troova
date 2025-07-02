import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class GooglePlacesSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(double lat, double lng, String address) onPlaceSelected;

  const GooglePlacesSearchWidget({
    Key? key,
    required this.controller,
    required this.onPlaceSelected,
  }) : super(key: key);

  @override
  _GooglePlacesSearchWidgetState createState() => _GooglePlacesSearchWidgetState();
}

class _GooglePlacesSearchWidgetState extends State<GooglePlacesSearchWidget> {
  final uuid = const Uuid();
  String _sessionToken = '1234567890';
  List<dynamic> _placeList = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      _onChanged();
    });
  }

  void _onChanged() {
    if (_sessionToken == '1234567890') {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    _getSuggestion(widget.controller.text);
  }

  void _getSuggestion(String input) async {
    const String PLACES_API_KEY = "YOUR_API_KEY_HERE";
    String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String request = '$baseURL?input=$input&key=$PLACES_API_KEY&sessiontoken=$_sessionToken&components=country:it&language=it';

    try {
      var response = await http.get(Uri.parse(request));
      if (response.statusCode == 200) {
        setState(() {
          _placeList = json.decode(response.body)['predictions'];
          _showSuggestions = _placeList.isNotEmpty;
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    const String PLACES_API_KEY = "YOUR_API_KEY_HERE";
    String baseURL = 'https://maps.googleapis.com/maps/api/place/details/json';
    String request = '$baseURL?place_id=$placeId&key=$PLACES_API_KEY';

    try {
      var response = await http.get(Uri.parse(request));
      if (response.statusCode == 200) {
        var result = json.decode(response.body)['result'];
        double lat = result['geometry']['location']['lat'];
        double lng = result['geometry']['location']['lng'];
        String formattedAddress = result['formatted_address'];
        widget.onPlaceSelected(lat, lng, formattedAddress);
      } else {
        throw Exception('Failed to load place details');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: widget.controller,
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
            suffixIcon: Icon(Icons.search, color: Colors.blueGrey[600]),
          ),
          onChanged: (value) {
            setState(() {
              _showSuggestions = true;
            });
          },
        ),
        if (_showSuggestions)
          Container(
            color: Colors.white,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _placeList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_placeList[index]["description"]),
                  onTap: () {
                    widget.controller.text = _placeList[index]["description"];
                    _getPlaceDetails(_placeList[index]["place_id"]);
                    setState(() {
                      _showSuggestions = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}