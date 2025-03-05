import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Start/splashscreen.dart'; // Import SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print(" Initializing Firebase...");
  try {
    await Firebase.initializeApp();
    print(" Firebase initialized successfully.");
  } catch (e) {
    print(" Firebase initialization error: $e");
  }

  //  Mailjet API Keys
  String apiKey = 'ce4fb4f08d7cd9946acbd135da6e3c9d';
  String secretKey = '456858b3b39fbd760963d805248dac03';

  //  Check Internet Connectivity with Mailjet API
  try {
    String credentials = base64Encode(utf8.encode('$apiKey:$secretKey'));

    final response = await http.get(
      Uri.parse("https://api.mailjet.com/v3/REST/contact"), // Mailjet endpoint
      headers: {
        "Authorization": "Basic $credentials",
        "Content-Type": "application/json",
      },
    );

    print(" Mailjet API Response: ${response.statusCode} - ${response.body}");
  } catch (e) {
    print(" Internet connection error: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print(" MyApp is being built.");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: Firebase.initializeApp(), //  Ensure Firebase is ready
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SplashScreen(); //  Load SplashScreen once Firebase is ready
          }
          return Scaffold(
            body:
                Center(child: CircularProgressIndicator()), //  Loading screen
          );
        },
      ),
    );
  }
}
