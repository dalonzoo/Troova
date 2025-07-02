import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/ad_model.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../../api/services/firebase_notification_service.dart';
import '../../ads/screens/AdDetailPage.dart';
import '../../ads/screens/AdDetailPageShared.dart';
import '../../ads/screens/CreateAdPage.dart';
import '../../ads/screens/SupportPage.dart';
import '../../ads/screens/UsersAdPage.dart';
import '../../auth/screens/login_view.dart';
import '../../../shared/constants.dart';
import '../../../api/services/profile_service.dart';
import '../../../shared/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;


class HomeView extends StatefulWidget {

  Profile profile;
  String id;
  HomeView({required this.profile, required this.id});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;
  String userName = '';
  String barText = '';
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late FirebaseNotificationService notificationService;
  List<Widget> _pages = [
  ];
  BannerAd? _bannerAd;
  @override
  void initState() {
    super.initState();

    initializeLocalNotifications();
    checkSavedNotifications();
    notificationService = FirebaseNotificationService(navigatorKey: _navigatorKey);
    _updateFcmToken();
    initializeFirebaseMessaging();
    print("id utente: ");
    print(widget.profile.userId);

    if (widget.id != '') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdDetailPageShared(id: widget.id,profile: widget.profile,)),
        );
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_){
      _loadUserName();
    });

    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-1684693149887110/5721835277', // Sostituisci con il tuo ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }


  void checkSavedNotifications() async{

    final prefs = await SharedPreferences.getInstance();
    final savedNotificationString = prefs.getString('lastNotification');
    if(savedNotificationString != null){
      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListScreen(userId: widget.profile.userId,)));

    }

  }
  void initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("notifica ricevuta");
        onSelectNotification(response.payload);
      },
    );
  }

  void initializeFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      String? token = await messaging.getToken();
      print('FCM Token: $token');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profile.userId)
          .update({'fcmToken': token});
    
      // Gestione messaggi in primo piano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          showNotification(message);
        }
      });

      // Gestione messaggi in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        handleNotification(message.data);
      });

      // Controlla se l'app è stata aperta da una notifica mentre era chiusa
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        handleNotification(initialMessage.data);
      }
    } else {
      print('User declined or has not accepted permission');
    }
  }

  void handleNotification(Map<String, dynamic> data) {
    print("handling notification ----");
    if (data['chatId'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: data['chatId'],
            userId: widget.profile.userId,
            otherUserId: data['senderId'] ?? '',
            adId: data['adId'] ?? '',
          ),
        ),
      );
    }
  }
  Future<void> showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'troova_channel',
      'Troova Notifications',
      channelDescription: 'Notifiche per messaggi e aggiornamenti',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Nuova notifica',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }


  void onSelectNotification(String? payload) {
    if (payload != null) {
      Map<String, dynamic> data = json.decode(payload);
      handleNotification(data);
    }else{
      print("payload nullo");
    }
  }

  Future<void> _updateFcmToken() async {
    FirebaseNotificationService notificationService = FirebaseNotificationService(navigatorKey: _navigatorKey);
    String? fcmToken = await notificationService.getToken();
    print("ottenuto $fcmToken");
    if (fcmToken != null) {
      // Ottieni il riferimento dell'utente nel database
      DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${widget.profile.userId}');

      // Ottieni i dati dell'utente
      DataSnapshot userSnapshot = await userRef.get();

      if (userSnapshot.exists) {
        // Cast del risultato a Map<String, dynamic>?
        Map<dynamic,dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;
        String? existingToken = userData['token'] ;
        print("esistente $existingToken");
        print("nuovo $fcmToken");
        // Se il token non esiste o è diverso, aggiorna il database
        if (existingToken == null || existingToken != fcmToken) {
          await userRef.update({'token': fcmToken});
        }
      } else {
        String userId = widget.profile.userId;
        // Gestisci il caso in cui il documento non esiste
        print("utente $userId non trovato");
      }
    }
  }
  Future<void> _loadUserName() async {

    setState(() {

      barText = ("Bentoranto " + widget.profile.fullName);
    });



  }

  @override
  Widget build(BuildContext context) {
    _pages = [
      ExchangePage(profile : widget.profile),
      SearchPage(userId: widget.profile.userId,),
      ProfilePage(profile: widget.profile),
      SettingsPage(profile: widget.profile, notificationService: notificationService,),
    ];

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 1.0,
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        barText,
                        style: GoogleFonts.poppins(
                          fontSize: 17.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[900],
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_selectedIndex == 2)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'modifica') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(profile: widget.profile),
                        ),
                      );
                    } else if (value == 'logout') {
                      FirebaseAuth.instance.signOut().then((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginView()),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Disconnessione eseguita')),
                        );
                      });
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'modifica',
                        child: Text('Modifica Profilo'),
                      ),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('Disconnetti'),
                      ),
                    ];
                  },
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(15.0),
                child: _pages[_selectedIndex],
              ),
            ),
            if (_bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Scambi'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cerca'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Impostazioni'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue[700],
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              switch (index) {
                case 0:
                  barText = 'Bentornato/a, ' + widget.profile.fullName;
                  break;
                case 1:
                  barText = 'Trova scambio';
                  break;
                case 2:
                  barText = 'Profilo';
                  break;
                case 3:
                  barText = 'Impostazioni';
                  break;
                default:
                  break;
              }
            });
          },
        ),
      ),
    );
  }


  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Uscire dall\'app?'),
        content: Text('Sei sicuro di voler uscire dall\'applicazione?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              SystemNavigator.pop(); // Chiude l'app
            },
            child: Text('Sì'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}

// Pagina degli Scambi
class ExchangePage extends StatefulWidget {
  Profile profile;

  ExchangePage({required this.profile});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 20.0,
        crossAxisSpacing: 20.0,
        children: [
          _buildCard(
            icon: Icons.swap_horiz,
            label: 'I Tuoi Scambi',
            onTap: () async {
              Navigator.push(context, MaterialPageRoute(builder: (context) => UserAdsPage(userId: widget.profile.userId)));
              // Naviga alla schermata degli scambi dell'utente
            },
          ),
          _buildCard(
            icon: Icons.add_circle_outline,
            label: 'Crea Scambio',
            onTap: () {
              // Naviga alla schermata di creazione di un nuovo scambio
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAdPage(userId: widget.profile.userId,)));
            },
          ),
          _buildCard(
            icon: Icons.chat,
            label: 'Messaggi in arrivo',
            onTap: () async {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListScreen(userId: widget.profile.userId,)));

              // Naviga alla schermata dei prodotti dell'utente
            },
          ),
          _buildCard(
            icon: Icons.report_problem_rounded,
            label: 'Segnala Problema',
            onTap: () {
              // Naviga alla schermata di segnalazione di problemi
              Navigator.push(context, MaterialPageRoute(builder: (context) => SupportPage(profile: widget.profile)));

            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required IconData icon, required String label, required Function() onTap}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 8.0,
      shadowColor: Colors.blueGrey[100],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50.0, color: Colors.blue[400]),
            const SizedBox(height: 10.0),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}



class SearchPage extends StatefulWidget {
  String userId;

  SearchPage({required this.userId});
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = '';
  String _selectedSortOption = 'Rilevanza';
  List<String> _sortOptions = ['Rilevanza', 'Prezzo crescente', 'Prezzo decrescente', 'Distanza crescente'];
  RangeValues _priceRange = RangeValues(0, 100);
  double _selectedDistance = 500.0;
  ValueNotifier<List<AdModel>> _adsNotifier = ValueNotifier<List<AdModel>>([]);
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
  bool _isLoading = true;
  bool _hasLocationPermission = false;




  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permesso negato'),
          content: Text('Per favore, concedi il permesso di accesso alla posizione per utilizzare questa funzionalità.'),
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






  @override
  void initState(){
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {
    await _requestLocationPermission();
    await _getCurrentLocation();
    await _applyFilters();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    setState(() {
      _hasLocationPermission = status.isGranted;
    });
    if (!_hasLocationPermission) {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_hasLocationPermission) return;
    try {
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print('Errore nel ottenere la posizione: $e');
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
    });

    List<AdModel> filteredAds = await _getFilteredAds();
    filteredAds = _filterAndSortAds(filteredAds);

    setState(() {
      _adsNotifier.value = filteredAds;
      _isLoading = false;
    });
  }

  Future<List<AdModel>> _getFilteredAds() async {
    CollectionReference adsCollection = FirebaseFirestore.instance.collection('ads');
    QuerySnapshot querySnapshot = await adsCollection.get();
    return querySnapshot.docs.map((doc) => AdModel.fromDocument(doc)).toList();
  }

  List<AdModel> _filterAndSortAds(List<AdModel> ads) {
    return ads.where((ad) {
      double rate = ad.rate.toDouble();
      bool matchesSearch = _searchQuery.isEmpty ||
          ad.title.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesPrice = rate >= _priceRange.start && rate <= _priceRange.end;

      bool matchesDistance = (_selectedDistance == 500) ? true : _calculateDistance(ad.location.latitude, ad.location.longitude) <= _selectedDistance;
      bool matchesDays = _selectedDays.values.every((selected) => !selected) ||
          _selectedDays.entries.any((entry) => entry.value && ad.daysAvailable.contains(entry.key));

      return matchesSearch && matchesPrice && matchesDistance && matchesDays;
    }).toList()..sort((a, b) {
      switch (_selectedSortOption) {
        case 'Prezzo crescente':
          return a.rate.compareTo(b.rate);
        case 'Prezzo decrescente':
          return b.rate.compareTo(a.rate);
        case 'Distanza crescente':
          double distanceA = _calculateDistance(a.location.latitude, a.location.longitude);
          double distanceB = _calculateDistance(b.location.latitude, b.location.longitude);
          return distanceA.compareTo(distanceB);
        default:
          return 0;
      }
    });
  }

  double _calculateDistance(double adLat, double adLong) {
    if (_currentPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      adLat,
      adLong,
    ) / 1000; // Convert to kilometers
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading ? _buildShimmerLoading() : _buildAdsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Cerca annunci...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.filter_list),
                label: Text('Filtri'),
                onPressed: _showFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.sort),
                label: Text('Ordina'),
                onPressed: _showSortOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16) + MediaQuery.of(context).viewInsets,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filtri',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text('Prezzo (€/h)', style: TextStyle(fontSize: 18)),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.white,
                    labels: RangeLabels(
                      _priceRange.start.round().toString(),
                      _priceRange.end.round().toString(),
                    ),
                    onChanged: (RangeValues values) {
                      setModalState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Text('Distanza massima (km)', style: TextStyle(fontSize: 18)),
                  Slider(
                    value: _selectedDistance,
                    min: 1,
                    max: 500,
                    divisions: 50,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.white,
                    label: _selectedDistance.round().toString(),
                    onChanged: (double value) {
                      setModalState(() {
                        _selectedDistance = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Text('Giorni disponibili', style: TextStyle(fontSize: 18)),
                  ..._selectedDays.keys.map((String day) {
                    return CheckboxListTile(
                      title: Text(day),
                      value: _selectedDays[day],
                      onChanged: (bool? value) {
                        setModalState(() {
                          _selectedDays[day] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        child: Text('Applica',style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          textStyle: TextStyle(color: Colors.white),
                          backgroundColor: Colors.lightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        child: Text('Azzera',style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          setModalState(() {
                            _priceRange = RangeValues(0, 100);
                            _selectedDistance = 500.0;
                            _selectedDays.updateAll((key, value) => false);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: _sortOptions.map((option) {
            return ListTile(
              title: Text(option),
              leading: Radio<String>(
                value: option,
                groupValue: _selectedSortOption,
                onChanged: (String? value) {
                  setState(() {
                    _selectedSortOption = value!;
                  });
                  Navigator.pop(context);
                  _applyFilters();
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAdsList() {
    return ValueListenableBuilder<List<AdModel>>(
      valueListenable: _adsNotifier,
      builder: (context, ads, child) {
        if (ads.isEmpty) {
          return Center(
            child: Text('Nessun annuncio trovato'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: ads.length,
          itemBuilder: (context, index) {
            return _buildAdCard(ads[index]);
          },
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              height: 250,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    width: 200,
                    height: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    width: 100,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildAdCard(AdModel ad) {
    double distance = _calculateDistance(ad.location.latitude, ad.location.longitude);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdDetailPage(ad: ad, id: ad.id, userId: widget.userId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: ad.imageUrl != null
                    ? Image.network(
                  ad.imageUrl!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: double.infinity,
                  height: 150,
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                ad.title,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                '${ad.rate} €/h',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                ad.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${distance.toStringAsFixed(2)} km',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  Icon(Icons.location_on, color: Colors.grey[600]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pagina delle Impostazioni
class SettingsPage extends StatefulWidget {
  final FirebaseNotificationService notificationService;

  final Profile profile;

  SettingsPage({required this.profile,required this.notificationService});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _buildSettingsSection('Account', [
            _buildSettingsTile(Icons.person, 'Profilo', 'Modifica il tuo profilo', () {
              // Naviga alla pagina di modifica del profilo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(profile: widget.profile),
                ),
              );
            }),
        _buildSettingsTile(Icons.delete, 'Profilo', 'Elimina il tuo profilo', () async {
          bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Conferma eliminazione'),
              content: Text('Sei sicuro di voler eliminare il tuo profilo? Questa azione è irreversibile.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Annulla'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Elimina'),
                ),
              ],
            ),
          );

          if (confirm) {
            try {
              // Elimina l'immagine del profilo da Firebase Storage
              // Controlla se l'immagine del profilo esiste in Firebase Storage
              final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${widget.profile.userId}');
              try {
                await storageRef.getDownloadURL();
                await storageRef.delete();
              } catch (e) {
                print('Immagine del profilo non trovata o errore durante l\'eliminazione: $e');
              }

              // Elimina i dati dell'utente da Firebase Realtime Database
              final userRef = FirebaseDatabase.instance.ref('users/${widget.profile.userId}');
              await userRef.remove();

              // Elimina i dati dell'utente da Firestore
              final firestoreRef = FirebaseFirestore.instance.collection('users').doc(widget.profile.userId);
              await firestoreRef.delete();

// Elimina tutti gli annunci dell'utente da Firestore
              final adsQuerySnapshot = await FirebaseFirestore.instance
                  .collection('ads')
                  .where('userId', isEqualTo: widget.profile.userId)
                  .get();

              for (var doc in adsQuerySnapshot.docs) {
                await doc.reference.delete();
              }

              // Elimina l'utente da Firebase Auth
              await FirebaseAuth.instance.currentUser!.delete();

              // Naviga alla schermata di login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginView()),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profilo eliminato con successo')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Errore durante l\'eliminazione del profilo: $e')),
              );
            }
          }
        }),
          ]),
          _buildSettingsSection('Notifiche', [
            _buildSettingsTile(Icons.notifications, 'Notifiche Push', 'Gestisci le notifiche push', () {
              // Naviga alla pagina di gestione notifiche
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsWidget(notificationService: widget.notificationService,),
                ),
              );
            }),
          ]),
          _buildSettingsSection('Altro', [
            _buildSettingsTile(Icons.info, 'Informazioni', 'Informazioni sull\'app', () {
              // Naviga alla pagina di informazioni
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppInfoPage(),
                ),
              );
            }),
            _buildSettingsTile(Icons.logout, 'Logout', 'Esci dal tuo account', () {
              // Logica per il logout
              FirebaseAuth.instance.signOut().then((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginView()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Disconnessione eseguita')),
                );
              });
            }),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: GoogleFonts.poppins(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
          ),
        ),
        ...tiles,
        Divider(color: Colors.grey[300]),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey[700]),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 16.0, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 14.0, color: Colors.grey[600])),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.blueGrey[700], size: 16.0),
      onTap: onTap,
    );
  }
}
class NotificationSettingsWidget extends StatefulWidget {
  final FirebaseNotificationService notificationService;

  NotificationSettingsWidget({required this.notificationService});

  @override
  _NotificationSettingsWidgetState createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends State<NotificationSettingsWidget> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      // Richiedi i permessi usando il servizio
      await widget.notificationService.initialize();

      // Controlla lo stato delle autorizzazioni dopo l'inizializzazione
      final prefs = await SharedPreferences.getInstance();
      bool authorized = prefs.getBool('notificationsEnabled') ?? false;

      setState(() {
        _notificationsEnabled = authorized;
      });

      if (!authorized) {
        // Se l'autorizzazione non è stata concessa, mostra un messaggio all'utente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le notifiche non sono state autorizzate. Controlla le impostazioni del tuo dispositivo.')),
        );
      }
    } else {
      // Per iOS e Android, guida l'utente alle impostazioni del dispositivo
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Disabilitare le notifiche'),
            content: Text('Per disabilitare le notifiche, vai alle impostazioni del dispositivo e disattiva le notifiche per questa app.'),
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

    // Salva lo stato delle notifiche
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Impostazioni Notifiche'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Abilita Notifiche Push'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
        ],
      ),
    );
  }
}


class ProfilePage extends StatefulWidget {
  Profile profile;

  ProfilePage({required this.profile});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isImageLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    print("carico profilo ${widget.profile.fullName}");
  }

  void getUserData(String userId) async {
    print("cerco : $userId");

    final userRef = FirebaseDatabase.instance.ref('users/' + userId);
    final event = await userRef.once();

    if (event.snapshot.value != null) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {

        widget.profile = Profile.fromMap(data);

      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("ricarico dati");
    // Chiama setState per forzare il refresh
    getUserData(widget.profile.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Immagine del profilo
            Stack(
            alignment: Alignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200], // Colore di sfondo mentre l'immagine carica
                    child: ClipOval(
                      child: Image.network(
                        widget.profile.profilePicture,
                        width: 120.0,
                        height: 120.0,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            // L'immagine è completamente caricata
                            WidgetsBinding.instance.addPostFrameCallback((_){

                              // Add Your Code here.
                              setState(() {
                                _isImageLoading = false;
                              });

                            });

                            return child;
                          } else {
                            // Mostra l'indicatore di caricamento
                            return CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                            );
                          }
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // In caso di errore nel caricamento dell'immagine, mostra un'icona di default
                          return Icon(
                            Icons.account_circle,
                            size: 60,
                            color: Colors.blueGrey[600],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (_isImageLoading) // Mostra l'indicatore solo se l'immagine è in fase di caricamento
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                ),
            ],
          ),
              const SizedBox(height: 20),

              // Nome e Cognome
              Text(
                widget.profile.fullName,
                style: GoogleFonts.poppins(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 10),

              // Bio
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
                child: Text(
                  widget.profile.bio,
                  style: GoogleFonts.poppins(
                    fontSize: 16.0,
                    color: Colors.blueGrey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Skills offerte
              _buildSectionTitle('Competenze Offerte'),
              _buildSkillsSection(widget.profile.skillsOffered),
              const SizedBox(height: 20),

              // Skills cercate
              _buildSectionTitle('Competenze Cercate'),
              _buildSkillsSection(widget.profile.skillsNeeded),
              const SizedBox(height: 20),

              // Residenza
              _buildSectionTitle('Residenza'),
              Text(
                '${widget.profile.address.city}, ${widget.profile.address.state}',
                style: GoogleFonts.poppins(
                  fontSize: 18.0,
                  color: Colors.blueGrey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Costruzione del titolo della sezione
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[800],
        ),
      ),
    );
  }

  // Costruzione della sezione delle skills
  Widget _buildSkillsSection(List<String> skills) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: skills.map((skill) {
        return Chip(
          label: Text(skill),
          backgroundColor: Colors.blueGrey[50],
          labelStyle: GoogleFonts.poppins(color: Colors.blueGrey[800]),
        );
      }).toList(),
    );
  }
}


class EditProfilePage extends StatefulWidget {
  final Profile profile;

  EditProfilePage({required this.profile});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillsOfferedController = TextEditingController();
  final TextEditingController _skillsNeededController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  List<String> _skillsOffered = [];
  List<String> _skillsNeeded = [];
  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bioController.text = widget.profile.bio;
    _skillsOffered = widget.profile.skillsOffered;
    _skillsNeeded = widget.profile.skillsNeeded;
    _addressController.text = widget.profile.address.city;
    print("carico dati: " + widget.profile.fullName);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("ricarico dati");
    // Chiama setState per forzare il refresh
    setState(() {

    });
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final firebase_auth.User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final String fileName = 'profile_pictures/${user.uid}.png';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(image);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Errore nel caricamento dell\'immagine: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }

    final firebase_auth.User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${user.uid}');

      // Aggiorna il database con la nuova immagine del profilo e altre informazioni
      await userRef.update({
        'bio': _bioController.text,
        'skillsOffered': _skillsOffered,
        'skillsNeeded': _skillsNeeded,
        'address': _addressController.text,
        if (imageUrl != null) 'profilePicture': imageUrl,
      });

      // Aggiorna il profilo locale
      setState(() {
        widget.profile.bio = _bioController.text;
        widget.profile.skillsOffered = _skillsOffered;
        widget.profile.skillsNeeded = _skillsNeeded;
        widget.profile.address.city = _addressController.text;
        if (imageUrl != null) {
          widget.profile.profilePicture = imageUrl;
        }
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: Text(
          'Modifica Profilo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Chiude la pagina senza apportare modifiche
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Immagine del profilo
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : widget.profile.profilePicture.isNotEmpty
                          ? NetworkImage(widget.profile.profilePicture) as ImageProvider
                          : AssetImage('assets/default_profile.png'),
                      child: _imageFile == null && widget.profile.profilePicture.isEmpty
                          ? Icon(
                        Icons.camera_alt,
                        color: Colors.blue,
                        size: 40,
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

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
                      prefixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            if (_skillsOfferedController.text.isNotEmpty) {
                              _skillsOffered.add(_skillsOfferedController.text);
                              _skillsOfferedController.clear();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: _skillsOffered.map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor: Colors.blueGrey[50],
                        labelStyle: GoogleFonts.poppins(color: Colors.blueGrey[800]),
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
                      prefixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            if (_skillsNeededController.text.isNotEmpty) {
                              _skillsNeeded.add(_skillsNeededController.text);
                              _skillsNeededController.clear();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: _skillsNeeded.map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor: Colors.blueGrey[50],
                        labelStyle: GoogleFonts.poppins(color: Colors.blueGrey[800]),
                        onDeleted: () {
                          setState(() {
                            _skillsNeeded.remove(skill);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Campo per la Residenza
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Inserisci la tua residenza',
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
                  ),
                  const SizedBox(height: 30),

                  // Bottone per Salvare le modifiche
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _isSaving = true; // Inizia il caricamento
                      });

                      try {
                        // Caricamento dell'immagine e salvataggio del profilo
                        await _saveProfile();
                        await ProfileService().saveUserProfile(widget.profile, context);
                        Navigator.of(context).pop('success'); // Chiudi la pagina
                      } catch (e) {
                        setState(() {
                          _isSaving = false; // Fine del caricamento
                        });
                        _showErrorDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      backgroundColor: Colors.blue[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text(
                      'Salva',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isSaving)
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Errore'),
          content: Text('Qualcosa è andato storto. Per favore, riprova.'),
          actions: [
            TextButton(
              child: Text('Riprova'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}



class AppInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Informazioni sull\'app'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Benvenuto/a nella nostra App!',
              style: GoogleFonts.poppins(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'La nostra app offre una piattaforma innovativa per connettere persone con competenze diverse. Puoi trovare e offrire servizi in modo semplice e veloce.',
              style: GoogleFonts.poppins(
                fontSize: 16.0,
                color: Colors.blueGrey[600],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Caratteristiche principali:',
              style: GoogleFonts.poppins(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 10),
            _buildFeatureItem(Icons.search, 'Ricerca avanzata', 'Trova esattamente ciò di cui hai bisogno con i nostri filtri di ricerca avanzati.'),
            _buildFeatureItem(Icons.notifications, 'Notifiche in tempo reale', 'Ricevi aggiornamenti immediati sulle tue attività e messaggi.'),
            _buildFeatureItem(Icons.security, 'Sicurezza', 'La tua sicurezza è la nostra priorità. Tutti i dati sono protetti e criptati.'),
            const SizedBox(height: 20),
            Text(
              "Versione $version",
              style: GoogleFonts.poppins(
                fontSize: 16.0,
                color: Colors.blueGrey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sviluppato da: Daniele D\'Alonzo \n'
                  'Icone da ',
              style: GoogleFonts.poppins(
                fontSize: 16.0,
                color: Colors.blueGrey[600],
              ),
            ),
            GestureDetector(
              onTap: () async {
                const url = 'https://www.flaticon.com';
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
              child: Text(
                'flaticon.com',
                style: GoogleFonts.poppins(
                  fontSize: 16.0,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(child:
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
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          const url = 'https://easy-lesson.web.app/troova/termsofservice.html';
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
                          const url = 'https://easy-lesson.web.app/troova/privacypolicy.html';
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        },
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[700], size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14.0,
                    color: Colors.blueGrey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





