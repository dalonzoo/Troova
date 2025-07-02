import 'package:age_calculator/age_calculator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import ' ContactInfoPage.dart';
import '../mainScreens/HomeView.dart';
import '../utils/Constants.dart';
import '../utils/Profile.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/people/v1.dart';
import 'package:flutter/foundation.dart';

import 'RegistrationPage.dart';

const List<String> scopes = <String>[
  'email',
  PeopleServiceApi.userBirthdayReadScope,
];

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: scopes,
);

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isLoading = false; // Stato per gestire il caricamento
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Image myImage = Image.asset('assets/icons/exchange64.png');
  Profile profile = Profile(
    password: '',
    email: '',
    userId: '',
    fullName: '',
    age: 0,
    phoneNumber: '',
    address: AddressData(
      street: '',
      city: '',
      state: '',
      postalCode: '',
      latitude: 0.0,
      longitude: 0.0,
    ),
    preferredLanguage: '',
    bio: '',
    profilePicture: '',
    skillsOffered: [],
    skillsNeeded: [],
    credits: 0,
    postedAds: [Ad(adId: "", title: "", description: "")],
    savedAds: [Ad(adId: "", title: "", description: "")],
    scheduledSessions: [Session(sessionId: '', date: DateTime(0), time: 0)],
    receivedReviews: [Review(reviewId: '', fromUserId: '', rating: 0, comment: '', reviewDate: DateTime(0))],
    verificationStatus: '',
    registrationDate: DateTime.now(),
    lastLogin: DateTime.now(),
    notificationPreferences: NotificationPreferences(
      email: true,
      sms: true,
      push: true,
    ),
    privacySettings: PrivacySettings(
      profileVisibility: 'public',
      reviewVisibility: 'public',
    ),
    socialMediaLinks: SocialMediaLinks(
      linkedIn: '',
    ),
    verificationDocuments: [VerificationDocument(documentId: '', type: '', url: '')], token: '', // Valore di default

  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo e motto
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trova e offri servizi con semplicità.',
                          style: GoogleFonts.poppins(
                            fontSize: 24.0,
                            color: Colors.blueGrey[800],
                            fontWeight: FontWeight.w600,
                          ),
                          softWrap: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Campo Email
                    TextFormField(
                      controller: _emailController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Inserisci la tua email';
                        } else if (!RegExp(r'^.+@[a-zA-Z]+\.[a-zA-Z]+$')
                            .hasMatch(value)) {
                          return 'Email non valida';
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
                        prefixIcon:
                        Icon(Icons.email, color: Colors.blueGrey[400]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo Password e Password dimenticata
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Inserisci la tua password';
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
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              if(_emailController.text == ""){
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Inserire una mail per reimpostare la password associata'),
                                  ),
                                );
                              }else {
                                FirebaseAuth.instance.sendPasswordResetEmail(
                                    email: _emailController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Email di reimpostazione password inviata'),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Password dimenticata?',
                              style: TextStyle(color: Colors.blue[400]),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 40),
                    // Pulsante di Login
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 200,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _isLoading = true; // Mostra l'indicatore di caricamento
                                  });
                                  await _login(_emailController.text, _passwordController.text);
                                  setState(() {
                                    _isLoading = false; // Nascondi l'indicatore di caricamento
                                  });
                                }
                              },
                              child: _isLoading
                                  ? CircularProgressIndicator() // Indicatore di caricamento
                                  : const Text('Accedi'),
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
                                Expanded(
                                    child: Divider(color: Colors.blueGrey[300])),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Text(
                                    'Oppure',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16.0,
                                      color: Colors.blueGrey[600],
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(color: Colors.blueGrey[300])),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 250,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                UserCredential? user = await _handleSignIn();
                                if (user != null) {
                                  profile.userId =
                                      FirebaseAuth.instance.currentUser!.uid;
                                  final userRef = FirebaseDatabase.instance.ref(
                                      'users/' +
                                          FirebaseAuth
                                              .instance.currentUser!.uid);
                                  final event = await userRef.once();

                                  if (event.snapshot.value != null) {

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomeView(profile: profile,id: ''),
                                      ),
                                    );
                                  }
                                else {
                                  profile.userId = FirebaseAuth
                                      .instance.currentUser!.uid;
                                  profile.email = user.user?.email as String;
                                  profile.fullName = user.user?.displayName as String;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ContactInfoPage(profile: profile),
                                    ),
                                  );
                                }
                              }},
                              icon: Image.asset(
                                  'assets/icons/googleIcon.png', height: 24),
                              label: const Text('Accedi con Google'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.blue[400]!, width: 2.0),
                                foregroundColor: Colors.blue[400],
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Pulsante "Crea un account"
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RegistrationPage(completeReg: false,),
                              ),
                            );
                          },
                          child: const Text('Crea un account'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue[600],
                            textStyle: GoogleFonts.poppins(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
          'birthdays', // add more fields with comma separated and no space
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
  Future<void> _login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).then((_) {
        getUserData(FirebaseAuth.instance.currentUser!.uid);
      });



    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login fallito. Controlla le credenziali')),
      );
    }
  }


  void getUserData(String userId) async {
    print("cerco : $userId");

    final userRef = FirebaseDatabase.instance.ref('users/' + userId);
    final event = await userRef.once();

    if (event.snapshot.value != null) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeView(profile: Profile.fromMap(data),id: '')),
      );
    }
  }
}
