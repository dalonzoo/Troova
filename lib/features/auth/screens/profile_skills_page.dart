import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/screens/HomeView.dart';
import '../../../shared/profile.dart';
import '../../../api/services/profile_service.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:image/image.dart' as img;
class ProfileSkillsPage extends StatefulWidget {
  final Profile profile;

  ProfileSkillsPage({required this.profile});

  @override
  _ProfileSkillsPageState createState() => _ProfileSkillsPageState();
}

class _ProfileSkillsPageState extends State<ProfileSkillsPage> {
  TextEditingController _bioController = TextEditingController();
  TextEditingController _skillsOfferedController = TextEditingController();
  TextEditingController _skillsNeededController = TextEditingController();
  List<String> _skillsOffered = [];
  List<String> _skillsNeeded = [];
  XFile? pickedFile;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _skillsOffered = widget.profile.skillsOffered ?? [];
    _skillsNeeded = widget.profile.skillsNeeded ?? [];
    _bioController.text = widget.profile.bio ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Colore di sfondo moderno
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                  onTap: () async {
                    // Logica per modificare l'immagine del profilo
                    pickedFile = (await ImagePicker().pickImage(source: ImageSource.gallery))!;
                    setState(() {
                      widget.profile.profilePicture = pickedFile!.path;
                    });
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: pickedFile != null
                        ? FileImage(File(pickedFile!.path))
                        : NetworkImage(widget.profile.profilePicture ?? 'https://www.example.com/default_profile_picture.png') as ImageProvider,
                  ),
                ),

              const SizedBox(height: 20),
              // Sezione Nome e Campo Biografia
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.1),
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.profile.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    // Campo per la Biografia
                    TextField(
                      controller: _bioController,
                      decoration: InputDecoration(
                        labelText: 'Inserisci una biografia',
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
                      ),
                      maxLines: null, // Consente di scrivere più righe di testo
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Sezione "Cosa offri"
              Text(
                'Cosa offri:',
                style: GoogleFonts.poppins(
                  fontSize: 18.0,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _skillsOfferedController,
                decoration: InputDecoration(
                  labelText: 'Inserisci una skill offerta',
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
                  prefixIcon: Icon(Icons.add, color: Colors.blueGrey[600]),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _skillsOffered.add(value);
                      _skillsOfferedController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _skillsOffered.map((skill) {
                  return Chip(
                    label: Text(skill),
                    labelStyle: const TextStyle(color: Colors.white),
                    backgroundColor: Colors.blue[400],
                    deleteIconColor: Colors.white,
                    onDeleted: () {
                      setState(() {
                        _skillsOffered.remove(skill);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Sezione "Cosa cerchi"
              Text(
                'Cosa cerchi:',
                style: GoogleFonts.poppins(
                  fontSize: 18.0,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _skillsNeededController,
                decoration: InputDecoration(
                  labelText: 'Inserisci una skill cercata',
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
                  prefixIcon: Icon(Icons.add, color: Colors.blueGrey[600]),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _skillsNeeded.add(value);
                      _skillsNeededController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _skillsNeeded.map((skill) {
                  return Chip(
                    label: Text(skill),
                    labelStyle: const TextStyle(color: Colors.white),
                    backgroundColor: Colors.blue[400],
                    deleteIconColor: Colors.white,
                    onDeleted: () {
                      setState(() {
                        _skillsNeeded.remove(skill);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Pulsante per Continuare
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      if (pickedFile != null) {
                        final file = File(pickedFile!.path);
                        final image = img.decodeImage(file.readAsBytesSync())!;
                        var compressedImage = img.encodeJpg(image, quality: 85); // Adjust quality to compress

                        // Ensure the image is under 50KB
                        int quality = 85;
                        while (compressedImage.length > 50000 && quality > 10) {
                          quality -= 5;
                          compressedImage = img.encodeJpg(image, quality: quality);
                        }

                        final tempDir = await path.getTemporaryDirectory();
                        final compressedFile = File('${tempDir.path}/temp.jpg')..writeAsBytesSync(compressedImage);

                        final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${widget.profile.userId}');
                        final uploadTask = storageRef.putFile(compressedFile);

                        final snapshot = await uploadTask.whenComplete(() => {});
                        final downloadUrl = await snapshot.ref.getDownloadURL();

                        setState(() {
                          widget.profile.profilePicture = downloadUrl;
                        });
                      }
                      // Salva le skill e la biografia nel profilo e naviga alla prossima schermata
                      widget.profile.skillsOffered = _skillsOffered;
                      widget.profile.skillsNeeded = _skillsNeeded;
                      widget.profile.bio = _bioController.text;
                      widget.profile.userId = FirebaseAuth.instance.currentUser!.uid;
                      print("salvo utente con id: ");
                      print(widget.profile.userId);
                      await ProfileService().saveUserProfile(widget.profile, context);
                    } catch (e) {
                      // Gestisci eventuali errori
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    backgroundColor: Colors.blue[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : const Text(
                      'Iniziamo!',
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
}
