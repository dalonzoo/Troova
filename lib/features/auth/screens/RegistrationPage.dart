import 'package:age_calculator/age_calculator.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_webservice/directions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/people/v1.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/ContactInfoPage.dart';
import '../../core/screens/HomeView.dart';
import '../../../shared/profile.dart';
import '../screens/ProfileSkillsPage.dart';
import '../screens/login_view.dart';

class RegistrationPage extends StatefulWidget {
  bool completeReg;
  RegistrationPage({required this.completeReg});
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isFieldDisabled = false;
  bool _isLoading = false;
  Profile profile = Profile(
    password: '',
    userId: '', // Valore di default
    fullName: '',// Valore di default
    age: 0, // Valore di default
    phoneNumber: '', // Valore di default
    address: AddressData(
      street: '', // Valore di default
      city: '', // Valore di default
      state: '', // Valore di default
      postalCode: '', // Valore di default
      latitude: 0.0, // Valore di default
      longitude: 0.0, // Valore di default
    ),
    preferredLanguage: '', // Valore di default
    bio: '', // Valore di default
    profilePicture: '', // Valore di default
    skillsOffered: [], // Valore di default
    skillsNeeded: [], // Valore di default
    credits: 0, // Valore di default
    postedAds: [Ad(adId: "", title: "", description: "")], // Valore di default
    savedAds: [Ad(adId: "", title: "", description: "")], // Valore di default
    scheduledSessions: [Session(sessionId: '', date: DateTime(0), time: 0)], // Valore di default
    receivedReviews: [Review(reviewId: '', fromUserId: '', rating: 0, comment: '', reviewDate: DateTime(0))], // Valore di default
    verificationStatus: '', // Valore di default
    registrationDate: DateTime.now(), // Valore di default
    lastLogin: DateTime.now(), // Valore di default
    notificationPreferences: NotificationPreferences(
      email: true, // Valore di default
      sms: true, // Valore di default
      push: true, // Valore di default
    ),
    privacySettings: PrivacySettings(
      profileVisibility: 'public', // Valore di default
      reviewVisibility: 'public', // Valore di default
    ),
    socialMediaLinks: SocialMediaLinks(
      linkedIn: '', // Valore di default
    ),
    verificationDocuments: [VerificationDocument(documentId: '', type: '', url: '')], email: '', token: '', // Valore di default
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> _handleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

     final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      if(googleUser != null) {
        profile.fullName = (googleUser != null ? googleUser.displayName : '')!;
        profile.profilePicture = (googleUser.photoUrl)!;
        profile.email = googleUser.email;
        var httpClient = (await _googleSignIn.authenticatedClient())!;

        var peopleApi = PeopleServiceApi(httpClient);

        final Person person = await peopleApi.people.get(
          'people/me',
          personFields:
          'birthdays,locales,addresses', // add more fields with comma separated and no space
        );

        DateTime dateTime;

        if (person.birthdays != null && person.birthdays![0].date != null) {
          int year = person.birthdays![0].date!.year ?? 0;
          int month = person.birthdays![0].date!.month ?? 0;
          int days = person.birthdays![0].date!.day ?? 0;
          dateTime = DateTime(
            year,
            month,
            days,
          );

          final age = AgeCalculator.age(dateTime);
          profile.age = age.years;
        }


        profile.fullName = profile.fullName;

        // Obtain the auth details from the request
      }
        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);

    }
    catch (error) {
      print(error);

    }

    return null;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      isFieldDisabled = widget.completeReg;
      if(isFieldDisabled){
        _emailController.text = "Email gia inserita";
        _passwordController.text = "Gia inserita";
        _confirmPasswordController.text = "Gia inserita";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titolo e sottotitolo
                          Text(
                            'Welcome!',
                            style: GoogleFonts.poppins(
                              fontSize: 28.0,
                              color: Colors.blueGrey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Iniziamo con le prime informazioni',
                            style: GoogleFonts.poppins(
                              fontSize: 18.0,
                              color: Colors.blueGrey[600],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              // Campo Nome e Cognome
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _nameController,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Inserisci il tuo nome e cognome';
                                    }
                                    return null;
                                  },
                                  style: TextStyle(color: Colors.blueGrey[800]),
                                  decoration: InputDecoration(
                                    labelText: 'Nome e cognome',
                                    labelStyle: TextStyle(color: Colors.blueGrey[600]),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      borderSide: BorderSide(color: Colors.blueGrey[200]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      borderSide: BorderSide(color: Colors.blueGrey[200]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      borderSide: BorderSide(color: Colors.blue[400]!),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20), // Spazio tra i campi

                              // Campo Età
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Inserisci la tua età';
                                    } else if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                      return 'Età non valida';
                                    }
                                    return null;
                                  },
                                  style: TextStyle(color: Colors.blueGrey[800]),
                                  decoration: InputDecoration(
                                    labelText: 'Età',
                                    labelStyle: TextStyle(color: Colors.blueGrey[600]),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      borderSide: BorderSide(color: Colors.blueGrey[200]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      borderSide: BorderSide(color: Colors.blueGrey[200]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                      borderSide: BorderSide(color: Colors.blue[400]!),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Campo Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if(!isFieldDisabled) {
                                if (value!.isEmpty) {
                                  return 'Inserisci la tua email';
                                } else
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(
                                    value)) {
                                  return 'Inserisci un\'email valida';
                                }
                              }
                              return null;
                            },
                            style: TextStyle(color: Colors.blueGrey[800]),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: Colors.blueGrey[600]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(color: Colors.blueGrey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(color: Colors.blueGrey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(color: Colors.blue[400]!),
                              ),
                              prefixIcon: Icon(Icons.email, color: Colors.blueGrey[400]),
                            ),
                            enabled: !isFieldDisabled,
                            readOnly: isFieldDisabled,
                          ),
                          const SizedBox(height: 20),

// Campo Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            validator: (value) {
                              if(!isFieldDisabled) {
                                if (value!.isEmpty) {
                                  return 'Inserisci la tua password';
                                } else if (value.length < 8 ||
                                    !RegExp(r'[A-Z]').hasMatch(value) ||
                                    !RegExp(r'[a-z]').hasMatch(value) ||
                                    !RegExp(r'[0-9]').hasMatch(value) ||
                                    !RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                                  return 'La password deve avere almeno \n8 caratteri\nuna maiuscola e una minuscola\n un numero e un carattere speciale';
                                }
                              }
                              return null;
                            },
                            style: TextStyle(color: Colors.blueGrey[800]),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.blueGrey[600]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(color: Colors.blueGrey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(color: Colors.blueGrey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(color: Colors.blue[400]!),
                              ),
                              prefixIcon: Icon(Icons.lock, color: Colors.blueGrey[400]),
                            ),
                            enabled: !isFieldDisabled,
                            readOnly: isFieldDisabled,
                          ),
                          const SizedBox(height: 20),

// Campo Conferma Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            validator: (value) {
                              if(!isFieldDisabled) {
                                if (value!.isEmpty) {
                                  return 'Conferma la tua password';
                                } else if (value != _passwordController.text) {
                                  return 'Le password non coincidono';
                                }
                              }
                              return null;
                            },
                            style: TextStyle(color: Colors.blueGrey[800]),
                            decoration: InputDecoration(
                              labelText: 'Conferma Password',
                              labelStyle: TextStyle(color: Colors.blueGrey[600]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(color: Colors.blueGrey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(color: Colors.blueGrey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(color: Colors.blue[400]!),
                              ),
                              prefixIcon: Icon(Icons.lock, color: Colors.blueGrey[400]),
                            ),
                            enabled: !isFieldDisabled,
                            readOnly: isFieldDisabled,
                          ),
                          const SizedBox(height: 40),

                          // Pulsante Avanti
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _isLoading = true;
                                  });

                                  try {
                                    if(!isFieldDisabled) {
                                      UserCredential userCredential = await FirebaseAuth
                                          .instance
                                          .createUserWithEmailAndPassword(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                      );

                                      profile.fullName = _nameController.text;
                                      profile.age =
                                          int.parse(_ageController.text);
                                      profile.email = _emailController.text;
                                      profile.password =
                                          _passwordController.text;
                                      profile.userId = userCredential.user!.uid;
                                    }else{
                                      profile.userId = FirebaseAuth.instance.currentUser!.uid;
                                      profile.fullName = _nameController.text;
                                      profile.age =
                                          int.parse(_ageController.text);
                                    }
                                    // Procedi alla schermata successiva
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ContactInfoPage(profile: profile),
                                      ),
                                    );
                                  } on FirebaseAuthException catch (e) {
                                    String errorMessage;
                                    if (e.code == 'weak-password') {
                                      errorMessage = 'La password fornita è troppo debole.';
                                    } else if (e.code == 'email-already-in-use') {
                                      errorMessage = 'L\'account esiste già per questa email.';
                                    } else {
                                      errorMessage = 'Si è verificato un errore. Riprova più tardi.';
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(errorMessage)),
                                    );
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },
                              child: const Text('Avanti'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[400],
                                foregroundColor: Colors.white,
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Testo "oppure" e linea
                          Center(
                            child: Row(
                              children: [
                                Expanded(child: Divider(color: Colors.blueGrey[300])),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  child: Text(
                                    'Oppure',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16.0,
                                      color: Colors.blueGrey[600],
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.blueGrey[300])),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Pulsante Continua con Google
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                setState(() {
                                  _isLoading = true;
                                });

                                UserCredential? user = await _handleSignIn();

                                setState(() {
                                  _isLoading = false;
                                });

                                if (user != null && user.user?.displayName != null) {
                                  profile.userId = FirebaseAuth.instance.currentUser!.uid;
                                  final userRef = FirebaseDatabase.instance.ref('users/' + FirebaseAuth.instance.currentUser!.uid);
                                  final event = await userRef.once();

                                  if (event.snapshot.value != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => HomeView(profile: profile, id: '')),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ContactInfoPage(profile: profile)),
                                    );
                                  }
                                }
                              },
                              icon: Image.asset('assets/icons/googleIcon.png', height: 24),
                              label: Text(
                                'Continua con Google',
                                style: GoogleFonts.poppins(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginView(),
                                  ),
                                );
                              },
                              label: Text(
                                'Ho già un account',
                                style: GoogleFonts.poppins(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),

                // Policy e Terms of Service fissi in basso
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 12.0,
                        color: Colors.blueGrey[600],
                      ),
                      children: [
                        const TextSpan(text: 'Continuando, accetti i nostri '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              const url = 'http://troova.lovestoblog.com/termsofservice.html';
                              if (await canLaunch(url)) {
                                await launch(url);
                              }
                            },
                        ),
                        const TextSpan(text: ' e la '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final Uri url = Uri.parse('https://easy-lesson.web.app/troova/privacypolicy.html');
                              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                throw Exception('Could not launch $url');
                              }
                            },
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
