import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickpost/utilities/usage_limiter.dart';
import 'package:quickpost/view/entry_screen.dart';
import 'package:quickpost/view/location_permission_screen.dart';
import 'package:quickpost/view/splash_screen.dart';
import 'package:quickpost/view/auth_ui/login_screen.dart';
import 'package:quickpost/view/block_screen.dart';
import 'controller/notifications.dart';
import 'firebase_options.dart';
import 'controller/apis.dart';

late Size mq;

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize UsageLimiter first
  await UsageLimiter.instance.init();

  // Set global onLimitReached callback
  UsageLimiter.instance.onLimitReached = () async {
    final nk = navigatorKey.currentState;
    if (nk == null) {
      print('[main] navigatorKey.currentState is null on limit reached');
      return;
    }

    final autoLogout = UsageLimiter.instance.getAutoLogout();

    if (autoLogout) {
      try {
        await Api.auth.signOut();
      } catch (e) {
        print('[main] signOut error: $e');
      }
      nk.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
      );
    } else {
      nk.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BlockScreen()),
            (route) => false,
      );
    }
  };

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Location & notifications
  await _ensureLocationPermission();
  await Notifications.init();
  await Geolocator();
  await GeocodingPlatform.instance;

  // Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // debug for testing
    appleProvider: AppleProvider.deviceCheck,
  );

  // Run app with navigatorKey
  runApp(const MyApp());
}

Future<void> _ensureLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print("Location permission denied");
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print("Location permission permanently denied");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quick Post',
      navigatorKey: navigatorKey, // <- important for UsageLimiter
      initialRoute: '/',
      routes: {
        '/': (context) => const EntryScreen(),
        '/home': (context) => SplashScreen(),
      },
    );
  }
}
