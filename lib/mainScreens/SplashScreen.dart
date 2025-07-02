import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import '../firebase_options.dart';
import '../signInUp/RegistrationPage.dart';
import '../signInUp/login_view.dart';
import '../utils/Profile.dart';
import 'HomeView.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool stop = false;
  late Profile profile;
  bool _isLoggedIn = false;
  bool _hasDeepLink = false;
  String? _deepLinkId;
  Image myImage = Image.asset('assets/icons/icona.png');
  final snackBar = SnackBar(
    content: Text("Non hai completato la registrazione."),
  );

  @override
  void initState() {
    super.initState();

    initFirebase();
  }

  void initFirebase() async {
    await Future.delayed(Duration(seconds: 2, milliseconds: 500));
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).whenComplete(() async {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.appAttest,
      );
      checkDeepLink();
      checkLoginStatus();
    });
  }

  void checkDeepLink() async {
    try {
      final appLinks = AppLinks();
      final uri = await appLinks.getInitialAppLink();
      if (uri != null) {
        if (uri.queryParameters.containsKey('code')) {
          setState(() {
            _deepLinkId = uri.queryParameters['code'];
            _hasDeepLink = true;
          });
        }
      }
    } on PlatformException {
      // Handle exception
    }
  }

  void checkLoginStatus() async {

    final User? user = FirebaseAuth.instance.currentUser;


    final prefs = await SharedPreferences.getInstance();
    bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    if (!seenOnboarding) {
      prefs.setBool("seenOnboarding", true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegistrationPage(completeReg: false,)),
      );
    } else {
      if (user != null) {
        getUserData(user.uid);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginView()),
        );
      }
    }




  }

  void getUserData(String userId) async {
    print("cerco : $userId");

    final userRef = FirebaseDatabase.instance.ref('users/' + userId);
    final event = await userRef.once();

    if (event.snapshot.value != null) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      Profile user = Profile.fromMap(data);
      if (_hasDeepLink && _deepLinkId != null && stop != true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeView(profile: user,id: _deepLinkId!)),
        );
      } else if(stop != true){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeView(profile: user,id:'')),
        );
      }
    } else if(stop != true){
    
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegistrationPage(completeReg: true,)),
      );
    }
  }

  Future<void> _checkForSavedNotification() async {


    final prefs = await SharedPreferences.getInstance();
    final savedNotificationString = prefs.getString('lastNotification');

    if (savedNotificationString != null) {
      stop = true;
      final savedNotification = json.decode(savedNotificationString);

      // Rimuovi i dati salvati dopo averli utilizzati
      await prefs.remove('lastNotification');

      // Naviga alla ChatScreen
      Navigator.of(context).pushReplacementNamed('/chat', arguments: {
        'chatId': savedNotification['chatId'],
        'userId': savedNotification['userId'],
        'otherUserId': savedNotification['otherUserId'],
        'adId': savedNotification['adId'],
      });
    } else {
      print("nessuna notifica trovata");
      // Se non ci sono notifiche salvate, naviga alla schermata principale
      checkDeepLink();
      checkLoginStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Colore di sfondo moderno
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(seconds: 2),
              child: SizedBox(
                height: 100,
                width: 100,
                child: myImage,
              ),
            ),
            const SizedBox(height: 20),
            // Aggiungi un'animazione di caricamento personalizzata
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}