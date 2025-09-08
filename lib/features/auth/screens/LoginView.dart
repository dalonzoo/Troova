import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../api/services/auth_service.dart';
import '../../../shared/profile.dart';
import '../../core/screens/HomeView.dart';
import '../screens/RegistrationPage.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final AuthService _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        Profile profile = await _getOrCreateProfile(userCredential.user!);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeView(profile: profile, id: ''),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Nessun utente trovato con questa email.';
          break;
        case 'wrong-password':
          errorMessage = 'Password errata.';
          break;
        case 'invalid-email':
          errorMessage = 'Email non valida.';
          break;
        default:
          errorMessage = 'Errore durante il login. Riprova.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore imprevisto: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        
        if (userCredential.user != null) {
          Profile profile = await _getOrCreateProfile(userCredential.user!);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeView(profile: profile, id: ''),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il login con Google: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Profile> _getOrCreateProfile(User user) async {
    final DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    final DataSnapshot snapshot = await userRef.get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
      return Profile.fromMap(userData);
    } else {
      Profile newProfile = Profile(
        userId: user.uid,
        fullName: user.displayName ?? '',
        email: user.email ?? '',
        profilePicture: user.photoURL ?? '',
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
        skillsOffered: [],
        skillsNeeded: [],
        credits: 0,
        postedAds: [],
        savedAds: [],
        scheduledSessions: [],
        receivedReviews: [],
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
        verificationDocuments: [],
        password: '',
        token: '',
      );

      await userRef.set(newProfile.toMap());
      return newProfile;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // Titolo e sottotitolo (stesso stile di RegistrationPage)
                Text(
                  'Bentornato!',
                  style: GoogleFonts.poppins(
                    fontSize: 28.0,
                    color: Colors.blueGrey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Accedi al tuo account per continuare',
                  style: GoogleFonts.poppins(
                    fontSize: 18.0,
                    color: Colors.blueGrey[600],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Campo Email
                _buildModernTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci la tua email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Inserisci un\'email valida';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Campo Password
                _buildModernTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.blueGrey[400],
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci la tua password';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Pulsante Login
                _buildLoginButton(),
                
                const SizedBox(height: 20),
                
                // Testo "oppure" e linea (stesso stile di RegistrationPage)
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
                
                // Pulsante Google
                _buildGoogleButton(),
                
                const SizedBox(height: 20),
                
                // Link registrazione
                _buildRegistrationLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Metodo per creare un campo di testo moderno (stesso stile di RegistrationPage)
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: Colors.blueGrey[800]),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey[600]),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Colors.blueGrey[400]),
        suffixIcon: suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: Colors.red[400]!, width: 2),
        ),
      ),
    );
  }

  // Pulsante Login (stesso stile di RegistrationPage)
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Accedi'),
      ),
    );
  }

  // Pulsante Google (stesso stile di RegistrationPage)
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // Link di registrazione (stesso stile di RegistrationPage)
  Widget _buildRegistrationLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 16.0,
            color: Colors.blueGrey[600],
          ),
          children: [
            const TextSpan(text: 'Non hai un account? '),
            TextSpan(
              text: 'Registrati',
              style: TextStyle(
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrationPage(completeReg: false),
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}
