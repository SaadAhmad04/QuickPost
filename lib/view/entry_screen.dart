import 'package:flutter/material.dart';
import 'package:quickpost/utilities/usage_limiter.dart';

import 'block_screen.dart';
import 'location_permission_screen.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});


  @override
  Widget build(BuildContext context) {

    final blocked = UsageLimiter.instance.isBlockedToday();

    // If blocked, go to BlockScreen
    if (blocked) {
      // Use pushReplacement to replace current screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BlockScreen()),
        );
      });
      // Return empty container while navigation happens
      return Container(color: Colors.white);
    } else {
      // Not blocked → proceed to LocationPermissionScreen
      return LocationPermissionScreen();
    }
  }
}
