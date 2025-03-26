import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pulse/ui/signing_screen.dart';

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
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactNumberController = TextEditingController();

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
        final userData = await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          final data = userData.data() as Map<String, dynamic>;
          setState(() {
            _fullNameController.text = data['fullName'] ?? '';
            _phoneNumberController.text = data['phoneNumber'] ?? '';
            _emergencyContactNameController.text = data['emergencyContactName'] ?? '';
            _emergencyContactNumberController.text = data['emergencyContactNumber'] ?? '';
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

  Future<String?> _uploadImageToImgur(File imageFile) async {
    const String imgurClientId = 'YOUR_IMGUR_CLIENT_ID';
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
      return responseData['data']['link'];
    } else {
      throw Exception('Failed to upload image to Imgur');
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_imageFile == null) return;

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final imageUrl = await _uploadImageToImgur(_imageFile!);

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
          'emergencyContactNumber': _emergencyContactNumberController.text.trim(),
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dark Theme Configuration


    return  _isLoading
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
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('assets/default_profile.png'),
                        child: _profileImageUrl == null && _imageFile == null
                            ? Icon(Icons.person, size: 70, color: Colors.grey[600])
                            : null,
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
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Email Display
                Text(
                  _auth.currentUser?.email ?? "No email",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 30),

                // Form Fields
                _buildProfileField(
                  controller: _fullNameController,
                  labelText: "Full Name",
                  icon: Icons.person_outlined,
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter your full name"
                      : null,
                ),
                const SizedBox(height: 20),

                _buildProfileField(
                  controller: _phoneNumberController,
                  labelText: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your phone number";
                    }
                    if (value.length < 10) {
                      return "Please enter a valid phone number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Date of Birth (Read-only)
                TextFormField(
                  initialValue: _dateOfBirth,
                  decoration: InputDecoration(
                    labelText: "Date of Birth",
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 20),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Gender",
                    prefixIcon: const Icon(Icons.wc),
                  ),
                  value: _gender,
                  items: ['Male', 'Female', 'Other']
                      .map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  ))
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
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter emergency contact name"
                      : null,
                ),
                const SizedBox(height: 20),

                _buildProfileField(
                  controller: _emergencyContactNumberController,
                  labelText: "Emergency Contact Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty
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
                    onPressed: () => setState(() => _isEditing = true),
                    child: const Text("Edit Profile"),
                  ),
                ),
              ],
            ),
          ),
        );
  }

  // Helper method to build consistent form fields
  Widget _buildProfileField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
      keyboardType: keyboardType,
      enabled: _isEditing,
    );
  }
}