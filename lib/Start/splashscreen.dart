import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messageapp/message/chatscreen.dart';

import '../authwrapper.dart';
import '../google/SignInScreen.dart'; // Import AuthService

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService =
      AuthService(); // Create an instance of AuthService

  @override
  void initState() {
    super.initState();
    print("🟡 SplashScreen started.");
    _navigateToNextScreen(); // Check authentication and navigate
  }

  // Check authentication status and navigate accordingly
  void _navigateToNextScreen() {
    Timer(Duration(seconds: 3), () {
      User? user = FirebaseAuth.instance.currentUser;

      if (mounted) {
        if (user != null) {
          print("✅ User is already logged in. Navigating to ChatScreen...");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen()),
          );
        } else {
          print("🔒 No user found. Navigating to AuthScreen...");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AuthScreen(authService: _authService)), // Pass authService
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 Building SplashScreen UI...");
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/image/logo.png',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
