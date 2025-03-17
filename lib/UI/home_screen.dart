import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse/ui/signing_screen.dart'; // Adjust import based on your project structure
import 'package:pulse/ui/profile_screen.dart'; // Import the ProfileScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        automaticallyImplyLeading: false,
        title: Text("Home"),
        actions: [
          // Profile Button
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          // Logout Button
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emergency Button
            ElevatedButton(
              onPressed: () async {
                await _handleEmergency(context);
              },
              child: Text(
                'Emergency Button',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            SizedBox(height: 40), // Spacing
            Text(
              "Welcome to Pulse",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Current User: ${user?.email ?? "No user logged in"}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 30),
            // Profile Button as a Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 28,
                        color: Colors.blue[900],
                      ),
                      SizedBox(width: 10),
                      Text(
                        "View Profile",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sign Out Method
  void _signOut() {
    FirebaseAuth.instance.signOut().then((_) {
      print("Signed out");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    }).catchError((error) {
      print("Sign out error: $error");
    });
  }

  // Handle Emergency Button Click
  Future<void> _handleEmergency(BuildContext context) async {
    try {
      // Get live location
      final Position position = await _getLiveLocation();

      // Generate Google Maps URL
      final String liveLocationUrl =
          'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

      // Get emergency contact number from Firestore
      final String emergencyContactNumber = await _getEmergencyContactNumber();

      // Prepare SMS message with the Google Maps URL
      final String message =
          'EMERGENCY! I need help. My live location is: $liveLocationUrl';

      // Send SMS
      await _sendEmergencySMS(emergencyContactNumber, message);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emergency SMS sent!')),
      );
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Get Live Location
  Future<Position> _getLiveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Send SMS
  Future<void> _sendEmergencySMS(
      String emergencyContactNumber, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: emergencyContactNumber,
      queryParameters: {'body': message},
    );

    if (await canLaunch(smsUri.toString())) {
      await launch(smsUri.toString());
    } else {
      throw Exception('Could not launch SMS.');
    }
  }

  // Get Emergency Contact Number from Firestore
  Future<String> _getEmergencyContactNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    print('Current User UID: ${user.uid}'); // Debug log

    // Query Firestore using the uid field
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: user.uid)
        .get();

    print('Firestore Query Results: ${querySnapshot.docs}'); // Debug log

    if (querySnapshot.docs.isEmpty) {
      print('User document not found in Firestore.'); // Debug log
      throw Exception('User data not found.');
    }

    final userDoc = querySnapshot.docs.first;
    print('User document found: ${userDoc.data()}'); // Debug log

    return userDoc['emergencyContactNumber'];
  }
}
