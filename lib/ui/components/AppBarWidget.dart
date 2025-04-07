import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pulse/UI/notification_logs_screen.dart';
import 'package:pulse/UI/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

  @override
  State<AppBarWidget> createState() => _AppBarWidgetState();

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _AppBarWidgetState extends State<AppBarWidget> {
  String? _profileImageUrl;
  String? _fullName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return;

    setState(() {
      _profileImageUrl = data['profileImageUrl'];
      _fullName = data['fullName'];
    });
  }

  Future<void> _navigateToProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
    await _loadUserData(); // Refresh data after returning
  }

  Future<void> _handleEmergency(BuildContext context) async {
    try {
      final Position position = await _getLiveLocation();

      final String liveLocationUrl =
          'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

      final String emergencyContactNumber = await _getEmergencyContactNumber();

      final String message = 'EMERGENCY! I need help. My live location is: $liveLocationUrl';

      await _sendEmergencySMS(emergencyContactNumber, message);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency SMS sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

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

  Future<void> _sendEmergencySMS(String number, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw Exception('Could not launch SMS.');
    }
  }

  Future<String> _getEmergencyContactNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: user.uid)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('User data not found.');
    }

    final userDoc = querySnapshot.docs.first;
    return userDoc['emergencyContactNumber'];
  }

  @override
  Widget build(BuildContext context) {
    String? avatarUrl;

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      avatarUrl = _profileImageUrl!;
    } else if (_fullName != null && _fullName!.isNotEmpty) {
      final encodedName = Uri.encodeComponent(_fullName!);
      avatarUrl = 'https://ui-avatars.com/api/?name=$encodedName';
    }

    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : const AssetImage('assets/default_profile.png') as ImageProvider,
            ),
          ),
          ElevatedButton(
            onPressed: () => _handleEmergency(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9534F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(100, 40),
            ),
            child: const Text(
              "Emergency",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationLogsScreen()),
              );
            },
            icon: const Icon(Icons.notifications, color: Colors.white, size: 24),
          ),
        ],
      ),
      toolbarHeight: 56,
    );
  }
}
