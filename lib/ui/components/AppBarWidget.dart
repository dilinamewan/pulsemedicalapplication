import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

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
      final String message = 'EMERGENCY! I need help. My live location is: $liveLocationUrl';

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
  Future<void> _sendEmergencySMS(String emergencyContactNumber, String message) async {
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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 16, 
          ),
          ElevatedButton(
            onPressed: () async {
              await _handleEmergency(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), 
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
            ),
            child: Text(
              "Emergency",
              style: TextStyle(color: Colors.white, fontSize: 14), 
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications, color: Colors.black, size: 20), 
          ),
        ],
      ),
      toolbarHeight: 48, 
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48); 
}
