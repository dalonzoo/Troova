import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../signInUp/RegistrationPage.dart';
import '../signInUp/login_view.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentPage = 0;
  late PageController controller;
  final List<Widget> _pages = [
    OnboardingScreen1(),
    OnboardingScreen2(),
    OnboardingScreen3(),
  ];
  String _buttonText = 'Avanti';
  bool _buttonEnabled = true;

  void _nextPage() {
    setState(() {
      _currentPage = (_currentPage + 1) % _pages.length;
    });
  }

  void _skipToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('seenOnboarding', true);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginView()),
    );
  }

  void _skipToRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('seenOnboarding', true);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrationPage(completeReg: false,)),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Benvenuto in Exchange Hub'),
        actions: [
          TextButton(
            onPressed: _skipToRegistration,
            child: Text('Salta', style: TextStyle(color: Colors.lightBlue),),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: controller,
            children: _pages,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
                _buttonText = page < _pages.length - 1 ? 'Avanti' : 'Inizia';
                _buttonEnabled = page < _pages.length - 1;
              });
            },
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _pages.length; i++)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Indicator(
                      isActive: i == _currentPage,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: ElevatedButton(
              onPressed: _buttonEnabled ? _nextPage : _skipToLogin,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                backgroundColor: Colors.blue[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                _buttonText,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Indicator extends StatelessWidget {
  final bool isActive;

  Indicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: isActive ? 12 : 8,
      height: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class OnboardingScreen1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/onboarding1.png', height: 200),
          SizedBox(height: 20),
          Text(
            'Benvenuto in Exchange Hub',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Trova e offri servizi in modo rapido e sicuro.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingScreen2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('', height: 200),
          SizedBox(height: 20),
          Text(
            'Personalizza la tua esperienza',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Scegli le impostazioni che preferisci per adattarle alle tue esigenze.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingScreen3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('', height: 200),
          SizedBox(height: 20),
          Text(
            'Inizia il tuo viaggio!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Sei pronto a esplorare tutte le possibilità che ti offre Exchange Hub?',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}