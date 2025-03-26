import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

import 'package:pulse/UI/signing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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

  // ImgBB API Configuration
  static const String imgBBApiKey =
      '8673672be15fcfc18a1ec1f2506ba56a'; // Replace with your actual ImgBB API key

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load existing user data from Firestore
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

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Upload the selected image to ImgBB
  Future<String?> _uploadImageToImgBB(File imageFile) async {
    try {
      // Prepare the multipart request
      final request = http.MultipartRequest(
          'POST', Uri.parse('https://api.imgbb.com/1/upload?key=$imgBBApiKey'));

      // Add the file to the request
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // Parse the response
      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(responseBody);
        return parsedResponse['data']['url'];
      } else {
        _showError('Image upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _showError("Failed to upload image: $e");
      return null;
    }
  }

  // Update the profile with the new image and data
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        String? newImageUrl = _profileImageUrl;

        // Upload new image if selected
        if (_imageFile != null) {
          newImageUrl = await _uploadImageToImgBB(_imageFile!);
        }

        // Update Firestore document
        await _firestore.collection('users').doc(user.uid).update({
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'emergencyContactName': _emergencyContactNameController.text.trim(),
          'emergencyContactNumber':
              _emergencyContactNumberController.text.trim(),
          'gender': _gender,
          'profileImageUrl': newImageUrl,
        });

        setState(() {
          _isEditing = false;
          _profileImageUrl = newImageUrl;
          _imageFile = null;
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

  // Logout functionality
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const SignInScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      _showError("Failed to log out: $e");
    }
  }

  // Show error messages
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image with Edit Option
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!) as ImageProvider
                                : _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : const AssetImage(
                                        'assets/default_profile.png'),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[700],
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

                    // Email Display
                    Text(_auth.currentUser?.email ?? "No email",
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 30),

                    // Form Fields
                    _buildProfileField(
                      controller: _fullNameController,
                      labelText: "Full Name",
                      icon: Icons.person_outlined,
                      validator: (value) =>
                          value!.isEmpty ? "Please enter your full name" : null,
                    ),
                    const SizedBox(height: 20),

                    _buildProfileField(
                      controller: _phoneNumberController,
                      labelText: "Phone Number",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty
                          ? "Please enter your phone number"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      initialValue: _dateOfBirth,
                      decoration: const InputDecoration(
                        labelText: "Date of Birth",
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Gender",
                        prefixIcon: Icon(Icons.wc),
                      ),
                      value: _gender,
                      items: ['Male', 'Female', 'Other']
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text(value)))
                          .toList(),
                      onChanged: _isEditing
                          ? (newValue) => setState(() => _gender = newValue)
                          : null,
                      validator: (value) =>
                          value == null ? "Please select your gender" : null,
                    ),
                    const SizedBox(height: 20),

                    _buildProfileField(
                      controller: _emergencyContactNameController,
                      labelText: "Emergency Contact Name",
                      icon: Icons.person_outline,
                      validator: (value) => value!.isEmpty
                          ? "Please enter emergency contact name"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    _buildProfileField(
                      controller: _emergencyContactNumberController,
                      labelText: "Emergency Contact Number",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty
                          ? "Please enter emergency contact number"
                          : null,
                    ),
                    const SizedBox(height: 30),

                    // Edit/Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isEditing
                          ? ElevatedButton(
                              onPressed: _updateProfile,
                              child: const Text("Save Changes"),
                            )
                          : ElevatedButton(
                              onPressed: () =>
                                  setState(() => _isEditing = true),
                              child: const Text("Edit Profile"),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper method to build form fields
  Widget _buildProfileField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText, prefixIcon: Icon(icon)),
      validator: validator,
      keyboardType: keyboardType,
      enabled: _isEditing,
    );
  }
}
