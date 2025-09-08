import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'features/chat/screens/chat_screen.dart';
import 'api/services/auth_service.dart';
import 'api/services/chat_service.dart';
import 'api/services/firebase_notification_service.dart';
import 'features/core/screens/SplashScreen.dart';



final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  
  // Gestione sicura del caricamento .env
  try {
    await dotenv.load(fileName: ".env");
    print("✅ File .env caricato dalla root");
  } catch (e) {
    try {
      // Prova a caricare dalle assets
      await dotenv.load(fileName: "assets/.env");
      print("✅ File .env caricato da assets");
    } catch (e2) {
      print("⚠️ File .env non trovato: $e2");
      // Procediamo comunque senza .env
    }
  }
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ChatService>(create: (_) => ChatService()),
        Provider<FirebaseNotificationService>(create: (_) => FirebaseNotificationService(navigatorKey: navigatorKey)),
      ],
      child: MyApp(navigatorKey: navigatorKey),
    ),
  );
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  MyApp({required this.navigatorKey});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    // Rimuoviamo l'inizializzazione qui perché viene fatta nel SplashScreen
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: widget.navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ChatScreen(
            chatId: args['chatId'] as String,
            userId: args['otherUserId'] as String,
            otherUserId: args['userId'] as String,
            adId: args['adId'] as String,
          );
        }
      },
    );
  }
}