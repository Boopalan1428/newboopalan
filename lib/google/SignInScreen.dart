import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // ✅ Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 🔹 Step 1: Start Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("⚠️ Google Sign-In canceled by user");
        return null;
      }

      // 🔹 Step 2: Get Google Authentication Tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print("❌ Google authentication tokens are null");
        return null;
      }

      // 🔹 Step 3: Authenticate with Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // 🔹 Step 4: Save User to Firestore
      await _saveUserToFirestore(userCredential.user);

      print("✅ Google Sign-In Successful: ${userCredential.user?.email}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.message}");
      return null;
    } catch (e) {
      print("❌ Google Sign-In Failed: $e");
      return null;
    }
  }

  // ✅ Store User Data in Firestore
  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;

    try {
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('messages').doc(user.uid);

      await userDoc.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? 'Unknown',
        'photoURL': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ User data saved to Firestore");
    } catch (e) {
      print("❌ Error saving user to Firestore: $e");
    }
  }

  // ✅ Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print("✅ User Signed Out");
    } catch (e) {
      print("❌ Sign Out Failed: $e");
    }
  }
}
