import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import './screens/HomePage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message == null) {
    return;
  }
  return;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Loading environment variables
  await DotEnv.load(fileName: ".env");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawFeeder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        backgroundColor: Color(0xFFffffff),
        primaryColor: Color(0xFFffc34d),
        accentColor: Color(0xFFffc34d),
        fontFamily: 'Nunito',
        textTheme: TextTheme(
          bodyText1: TextStyle(
              color: Color(0xFF0e2a47),
              fontSize: 14.00,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2),
          bodyText2: TextStyle(
              color: Color(0xFF5f7d95),
              fontSize: 16.00,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2),
        ),
      ),
      home: HomePage(),
    );
  }
}
