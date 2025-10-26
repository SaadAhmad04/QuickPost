import 'package:flutter/material.dart';

class BlockScreen extends StatelessWidget {
  final bool signOut; // whether to sign out the user (optional)
  final VoidCallback? onTryAgain; // optional callback to re-check

  const BlockScreen({this.signOut = false, this.onTryAgain});

  @override
  Widget build(BuildContext context) {
    // Prevent back button by intercepting WillPopScope
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, size: 72, color: Colors.purple),
                  SizedBox(height: 20),
                  Text('Daily limit reached', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text('You have reached your allowed watch time for today. Come back tomorrow!', textAlign: TextAlign.center),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (onTryAgain != null) onTryAgain!();
                    },
                    child: Text('OK' , style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
