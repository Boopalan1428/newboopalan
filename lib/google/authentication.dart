import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        bool isNewUser = await saveUserToFirestore(user);
        if (isNewUser) {
          await sendNewUserEmail(user);
        }
      }

      return userCredential;
    } catch (e) {
      print("❌ Google Sign-In Failed: $e");
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    print("✅ User Signed Out");
  }

  // ✅ Save User to Firestore & Check If New
  Future<bool> saveUserToFirestore(User user) async {
    DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    DocumentSnapshot snapshot = await userDoc.get();
    bool isNewUser = !snapshot.exists; // Check if user is new

    await userDoc.set({
      'email': user.email,
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(), // Timestamp of registration
    }, SetOptions(merge: true));

    return isNewUser;
  }

  // ✅ Send Email with New User Details
  Future<void> sendNewUserEmail(User user) async {
    const String apiKey = "your-mailjet-api-key";
    const String apiSecret = "your-mailjet-secret-key";
    const String adminEmail =
        "admin@example.com"; // Change to the recipient email

    final response = await http.post(
      Uri.parse("https://api.mailjet.com/v3.1/send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization":
            "Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}",
      },
      body: jsonEncode({
        "Messages": [
          {
            "From": {"Email": "your-email@example.com", "Name": "Chat App"},
            "To": [
              {"Email": adminEmail, "Name": "Admin"}
            ],
            "Subject": "🚀 New User Signed Up",
            "TextPart":
                "A new user has signed up!\n\nEmail: ${user.email}\nUID: ${user.uid}\nSign-Up Time: ${DateTime.now()}",
            "HTMLPart":
                "<h3>New User Signed Up</h3><p><b>Email:</b> ${user.email}</p><p><b>UID:</b> ${user.uid}</p><p><b>Sign-Up Time:</b> ${DateTime.now()}</p>",
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      print("✅ New user details sent via email");
    } else {
      print("❌ Failed to send new user email: ${response.body}");
    }
  }
}
