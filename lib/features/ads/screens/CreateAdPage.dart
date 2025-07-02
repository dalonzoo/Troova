
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';

class CreateAdPage extends StatefulWidget {
  String userId;

  CreateAdPage({required this.userId});
  @override
  _CreateAdPageState createState() => _CreateAdPageState();
}

class _CreateAdPageState extends State<CreateAdPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rateController = TextEditingController();
  String _startTime = '09:00';
  String _endTime = '17:00';
  bool _isLoading = false;
  InterstitialAd? _interstitialAd;
  Map<String, bool> _selectedDays = {
    'Lunedì': false,
    'Martedì': false,
    'Mercoledì': false,
    'Giovedì': false,
    'Venerdì': false,
    'Sabato': false,
    'Domenica': false,
  };
  Position? _currentPosition;
  double _radius = 5.0;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _initGoogleMobileAds();
    _loadInterstitialAd();
  }

  void _initGoogleMobileAds() {
    MobileAds.instance.initialize();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-1684693149887110/2489167273',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _showInterstitialAd();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    }
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      _getCurrentLocation();
    } else if (status.isDenied) {
      _showPermissionDeniedDialog();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Errore nel recupero della posizione: $e');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permesso negato'),
          content: Text('Per favore, abilita i permessi di localizzazione.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    TimeOfDay initialTime = isStartTime
        ? TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(hour: 17, minute: 0);
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        String formattedTime = pickedTime.format(context);
        if (isStartTime) {
          _startTime = formattedTime;
        } else {
          _endTime = formattedTime;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      // Crea un riferimento al file su Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('ads_images/${DateTime.now().millisecondsSinceEpoch}');

      // Leggi i dati dell'immagine
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decodifica l'immagine
      final img.Image image = img.decodeImage(imageBytes)!;

      // Ridimensiona e comprimi l'immagine
      final img.Image resizedImage = img.copyResize(image, width: 800, height: 600);
      int quality = 80;
      Uint8List compressedImage = img.encodeJpg(resizedImage, quality: quality);

// Assicurati che l'immagine sia sotto i 50KB
      while (compressedImage.length > 50000 && quality > 10) {
        quality -= 5;
        compressedImage = img.encodeJpg(resizedImage, quality: quality);
      }

      // Carica i dati compressi direttamente su Firebase Storage
      final uploadTask = storageRef.putData(Uint8List.fromList(compressedImage));
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Errore nel caricamento dell\'immagine: $e');
      return null;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Crea annuncio', style: TextStyle(color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black87),),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                color: Colors.grey[200],
                height: 200,
                width: double.infinity,
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : const Center(
                  child: Text('Tocca per selezionare un\'immagine'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titolo'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrizione'),
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: 'Tariffa Oraria (€)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Text(
              'Seleziona Giorni e Orari Disponibili:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children: _selectedDays.keys.map((day) {
                return CheckboxListTile(
                  title: Text(day),
                  value: _selectedDays[day],
                  onChanged: (bool? value) {
                    setState(() {
                      _selectedDays[day] = value ?? false;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _selectTime(context, true),
                  child: Text('Orario di Inizio: $_startTime'),
                ),
                TextButton(
                  onPressed: () => _selectTime(context, false),
                  child: Text('Orario di Fine: $_endTime'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Imposta Raggio di Copertura (km):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            Slider(
              value: _radius,
              min: 1,
              max: 500,
              divisions: 499, // Aumenta il numero di divisioni per maggiore precisione
              label: _radius.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _radius = value;
                });
              },
            ),
            const SizedBox(height: 20),

            Container(
              height: 200,
              width: double.infinity,
              child: _currentPosition != null
                  ? GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  zoom: 14,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId('currentLocation'),
                    position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  ),
                },
                circles: {
                  Circle(
                    circleId: CircleId('coverageRadius'),
                    center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    radius: _radius * 1000, // Convert km to meters
                    fillColor: Colors.blue.withOpacity(0.1),
                    strokeColor: Colors.blue,
                    strokeWidth: 1,
                  ),
                },
              )
                  : Center(child: Text('Recupero posizione...')),
            ),
            const SizedBox(height: 10),
            Text(
              'Nota: La tua posizione esatta non verrà mostrata a nessuno, solo la distanza dagli altri utenti.',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey[600]),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAd,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : const Text(
                    'Crea Annuncio',
                    style: TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAd() async {
    setState(() {
      _isLoading = true;
    });
    // Verifica che la posizione sia stata ottenuta
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossibile ottenere la posizione attuale.'),
        ),
      );
      return;
    }

    List<String> selectedDays = _selectedDays.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seleziona almeno un giorno'),
        ),
      );
      return;
    }

    // Carica l'immagine e ottieni l'URL
    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }
    // Converti _startTime e _endTime in DateTime
    // Converti _startTime e _endTime in DateTime usando il formato HH:mm
    DateTime startDateTime = DateFormat('HH:mm').parse(_startTime);
    DateTime endDateTime = DateFormat('HH:mm').parse(_endTime);

    // Crea il documento da salvare
    Map<String, dynamic> adData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'rate': int.parse(_rateController.text),
      'daysAvailable': selectedDays,
      'startTime': Timestamp.fromDate(startDateTime),
      'endTime': Timestamp.fromDate(endDateTime),
      'location': GeoPoint(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ),
      'radius': _radius,
      'timestamp': FieldValue.serverTimestamp(),
      'userId' : widget.userId,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };

    // Salva l'annuncio nel database
    await FirebaseFirestore.instance.collection('ads').add(adData);

    // Mostra una conferma
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Annuncio creato con successo!'),
      ),
    );
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop(); // Torna alla pagina precedente
  }
}
