import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickpost/view/splash_screen.dart';
import 'controller/notifications.dart';
import 'firebase_options.dart';

late Size mq;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Notifications.init();
  await Geolocator();
  await GeocodingPlatform.instance;
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Use 'debug' for testing
    appleProvider: AppleProvider.deviceCheck,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quick Post',
      home: const SplashScreen(),
    );
  }
}
