import 'package:flutter/material.dart';
import 'package:messageapp/message/chatscreen.dart';

import 'google/SignInScreen.dart';

class AuthScreen extends StatelessWidget {
  final AuthService authService;

  AuthScreen({required this.authService}); // Require AuthService instance

  @override
  Widget build(BuildContext context) {
    print("🎨 Building AuthScreen UI...");
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final userCredential = await authService.signInWithGoogle();
                if (userCredential != null) {
                  print("✅ Google Sign-In Successful");

                  // Navigate to ChatScreen on success
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ChatScreen()),
                  );
                } else {
                  print("❌ Google Sign-In Failed");
                }
              },
              child: Text("Sign in with Google"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await authService.signOut();
                print("✅ Signed out successfully");
              },
              child: Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }
}
