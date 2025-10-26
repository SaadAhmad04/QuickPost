import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/apis.dart';
import '../model/user_model.dart';
import 'admin_home_screen.dart';
import 'auth_ui/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

const colorizeColors = [
  Colors.white,         // White for contrast
  Colors.purpleAccent,  // Lighter purple
  Colors.deepPurple,    // Deep purple for richness
  Colors.orangeAccent,  // A contrasting pop color
];

const colorizeTextStyle = TextStyle(
  fontSize: 50.0,
  fontFamily: 'Horizon',
  fontWeight: FontWeight.bold, // Make the text bold to stand out more
);


class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    if (Api.auth.currentUser != null) {
      final pref = await SharedPreferences.getInstance();
      String? currentUser = pref.getString('user');
      final wasAdmin = pref.getBool('isAdmin') ?? false;

      if (currentUser != null) {
        Api.user = UserModel.fromJson(jsonDecode(currentUser));
      }

      // set API role flag
      Api.isAdmin = wasAdmin;

      Future.delayed(Duration(seconds: 3), () {
        if (Api.isAdmin) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const AdminHomeScreen()));
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      });
    } else {
      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient background for a vibrant look
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.purple.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QuickPost icon (QP inside circle, inside square)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple.shade800,
                  ),
                  child: Text(
                    'QP',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Animated text for "QuickPost"
              SizedBox(
                width: 300.0,
                child: Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      ColorizeAnimatedText(
                        'QuickPost',
                        textStyle: colorizeTextStyle,
                        colors: colorizeColors,
                        speed: Duration(milliseconds: 1000),
                      ),
                    ],
                    isRepeatingAnimation: true,
                  ),
                ),
              ),
              SizedBox(height: 30),
              // Lottie animation for added dynamic effect
              Center(
                child: Container(
                  child: Lottie.asset(
                    'animations/splash_animation.json',
                    height: 200,
                    width: 200,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Tagline text
              Text(
                'Connecting the World with Shorts',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Optional: Loading indicator while checking login status
              // Uncomment to show a progress indicator
              // SizedBox(height: 20),
              // CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
