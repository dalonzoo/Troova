import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:troova/shared/profile.dart';

class SupportPage extends StatefulWidget {
  final Profile profile;

  SupportPage({required this.profile});

  @override
  _SupportPageState createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.profile.fullName;
  }
  void _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'exchubcustomers@gmail.com',
      query: {
        'subject': 'problema nell\'app',
        'body': 'Nome utente: ${_usernameController.text}\n\nDescrivi il tuo problema qui: ${_problemController.text}'
      }.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&'),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Non è stato possibile aprire l\'app di posta elettronica.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Assistenza Utente'),
        backgroundColor: Colors.blue[400],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hai bisogno di assistenza?',
              style: GoogleFonts.poppins(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Nome utente',
                labelStyle: GoogleFonts.poppins(color: Colors.blueGrey[600]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _problemController,
              decoration: InputDecoration(
                labelText: 'Descrivi il tuo problema',
                labelStyle: GoogleFonts.poppins(color: Colors.blueGrey[600]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              maxLines: 5,
              maxLength: 250,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendEmail,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15.0),
                backgroundColor: Colors.blue[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                'Invia una mail di assistenza',
                style: GoogleFonts.poppins(
                  fontSize: 18.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}