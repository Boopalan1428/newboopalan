import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    listenForNewMessages();
  }

  //  Check Internet Connectivity
  Future<bool> checkInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  //  Send Email using Mailjet API
  Future<void> sendEmailUsingMailjet(
      String recipient, String subject, String message) async {
    const String apiKey =
        "ce4fb4f08d7cd9946acbd135da6e3c9d"; //  Move this to Firebase Functions
    const String apiSecret =
        "456858b3b39fbd760963d805248dac03"; //  Do not expose API keys!
    const int maxRetries = 3;
    int attempt = 0;

    if (!await checkInternet()) {
      showSnackbar(" No internet connection.", Colors.red);
      return;
    }

    while (attempt < maxRetries) {
      try {
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
                "From": {"Email": "boopalanksv@gmail.com", "Name": "Chat App"},
                "To": [
                  {"Email": recipient, "Name": "User"}
                ],
                "Subject": subject,
                "TextPart": message,
                "HTMLPart": "<h3>$message</h3>",
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          print(" Email sent successfully to $recipient");
          return;
        } else {
          print(" Mailjet API error: ${response.body}");
        }
      } catch (e) {
        attempt++;
        print(" Attempt $attempt/$maxRetries failed: $e");
        await Future.delayed(Duration(seconds: 2));
      }
    }

    showSnackbar(
        " Email sending failed after $maxRetries attempts.", Colors.red);
  }

  //  Send Message to Firestore & Notify via Email
  Future<void> sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSnackbar(" User not signed in.", Colors.red);
      return;
    }

    String uid = user.uid;
    String userEmail = user.email ?? "Unknown Email";

    try {
      DocumentReference docRef =
          await FirebaseFirestore.instance.collection('messages').add({
        'uid': uid,
        'email': userEmail,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print(" Message added to Firestore: $message");

      //  Send Email Notification to the message sender
      DocumentSnapshot docSnapshot = await docRef.get();
      Map<String, dynamic>? messageData =
          docSnapshot.data() as Map<String, dynamic>?;

      if (messageData != null) {
        String createdAt = messageData['timestamp'] != null
            ? (messageData['timestamp'] as Timestamp).toDate().toString()
            : "Unknown Timestamp";

        await sendEmailUsingMailjet(
          userEmail,
          "📩 New Chat Message Sent",
          "🆔 User ID: $uid\n📧 Email: $userEmail\n🕒 Sent At: $createdAt\n💬 Message: \"$message\"",
        );

        showSnackbar(
            " Message sent! Email notification sent to you.", Colors.green);
      }

      _messageController.clear();
    } catch (e) {
      print("❌ Error sending message: $e");
      showSnackbar("❌ Error sending message.", Colors.red);
    }
  }

  //  Listen for New Messages in Firestore in Real-time
  void listenForNewMessages() {
    FirebaseFirestore.instance.collection('messages').snapshots().listen(
      (QuerySnapshot snapshot) {
        for (var docChange in snapshot.docChanges) {
          if (docChange.type == DocumentChangeType.added) {
            var data = docChange.doc.data() as Map<String, dynamic>;
            print("🔄 New message detected: ${data['text']}");
          }
        }
      },
      onError: (error) {
        print("❌ Firestore snapshot error: $error");
        showSnackbar("❌ Firestore error.", Colors.red);
      },
    );
  }

  //  Show Snackbar Message
  void showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat Screen")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var data = messages[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['text'] ?? "No message"),
                      subtitle: Text(
                        "Email: ${data['email'] ?? 'Unknown'}\nSent at: ${data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate().toString() : 'Unknown'}",
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration:
                        InputDecoration(labelText: "Enter your message"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
