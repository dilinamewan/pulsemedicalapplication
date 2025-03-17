import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pulse/ui/signing_screen.dart';
import 'package:pulse/ui/component/reusable_widget.dart';
import '../utils/color_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emergencyContactNameController =
      TextEditingController();
  final TextEditingController _emergencyContactNumberController =
      TextEditingController();
  String? _gender;
  String? _dateOfBirth;
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isEditing = false;
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          final data = userData.data() as Map<String, dynamic>;
          setState(() {
            _fullNameController.text = data['fullName'] ?? '';
            _phoneNumberController.text = data['phoneNumber'] ?? '';
            _emergencyContactNameController.text =
                data['emergencyContactName'] ?? '';
            _emergencyContactNumberController.text =
                data['emergencyContactNumber'] ?? '';
            _gender = data['gender'];
            _dateOfBirth = data['dateOfBirth'];
            _profileImageUrl = data['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      _showError("Failed to load user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImageToImgur(File imageFile) async {
    const String imgurClientId =
        'YOUR_IMGUR_CLIENT_ID'; // Replace with your Imgur client ID
    final url = Uri.parse('https://api.imgur.com/3/image');
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Client-ID $imgurClientId',
      },
      body: {
        'image': base64Image,
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['data']['link']; // Return the image URL
    } else {
      throw Exception('Failed to upload image to Imgur');
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_imageFile == null) return;

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final imageUrl = await uploadImageToImgur(_imageFile!);

        await _firestore.collection('users').doc(user.uid).update({
          'profileImageUrl': imageUrl,
        });

        setState(() {
          _profileImageUrl = imageUrl;
          _imageFile = null;
        });
      }
    } catch (e) {
      _showError("Failed to upload image: $e");
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Upload image if selected
        if (_imageFile != null) {
          await _uploadProfileImage();
        }

        // Update user data
        await _firestore.collection('users').doc(user.uid).update({
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'emergencyContactName': _emergencyContactNameController.text.trim(),
          'emergencyContactNumber':
              _emergencyContactNumberController.text.trim(),
          'gender': _gender,
        });

        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      _showError("Failed to update profile: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    } catch (e) {
      _showError("Failed to log out: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("E3F2FD"),
              hexStringToColor("FFFFFF"),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Image
                      GestureDetector(
                        onTap: _isEditing ? _pickImage : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!) as ImageProvider
                                  : _profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : const AssetImage(
                                          'assets/default_profile.png'),
                              child:
                                  _profileImageUrl == null && _imageFile == null
                                      ? const Icon(Icons.person,
                                          size: 70, color: Colors.blue)
                                      : null,
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Display current user email
                      Text(
                        _auth.currentUser?.email ?? "No email",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),

                      // Full Name Field
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          labelStyle: TextStyle(color: Colors.black54),
                          icon: Icon(Icons.person_outlined,
                              color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your full name.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Phone Number Field
                      TextFormField(
                        controller: _phoneNumberController,
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          labelStyle: TextStyle(color: Colors.black54),
                          icon:
                              Icon(Icons.phone_outlined, color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your phone number.";
                          }
                          if (value.length < 10) {
                            return "Please enter a valid phone number.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Date of Birth Field (read-only)
                      TextFormField(
                        initialValue: _dateOfBirth,
                        decoration: InputDecoration(
                          labelText: "Date of Birth",
                          labelStyle: TextStyle(color: Colors.black54),
                          icon:
                              Icon(Icons.calendar_today, color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        enabled: false, // Read-only, cannot be edited
                      ),
                      const SizedBox(height: 20),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Gender",
                          labelStyle: TextStyle(color: Colors.black54),
                          icon: Icon(Icons.wc, color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        value: _gender,
                        items: ['Male', 'Female', 'Other'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: _isEditing
                            ? (String? newValue) {
                                setState(() {
                                  _gender = newValue;
                                });
                              }
                            : null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select your gender.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Emergency Contact Name Field
                      TextFormField(
                        controller: _emergencyContactNameController,
                        decoration: InputDecoration(
                          labelText: "Emergency Contact Name",
                          labelStyle: TextStyle(color: Colors.black54),
                          icon: Icon(Icons.person, color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter the emergency contact name.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Emergency Contact Number Field
                      TextFormField(
                        controller: _emergencyContactNumberController,
                        decoration: InputDecoration(
                          labelText: "Emergency Contact Number",
                          labelStyle: TextStyle(color: Colors.black54),
                          icon: Icon(Icons.phone, color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter the emergency contact number.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      _isEditing
                          ? ElevatedButton(
                              onPressed: _updateProfile,
                              child: const Text("Save"),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              child: const Text("Edit"),
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
