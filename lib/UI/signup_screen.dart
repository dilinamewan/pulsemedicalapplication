import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse/ui/components/reusable_widget.dart';
import 'package:pulse/ui/signing_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers for all form fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactNumberController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();

  // Gender variable
  String? _gender;

  // Loading and form validation state
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dark Theme Configuration
    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Colors.blue[300]!,
        secondary: Colors.blue[200]!,
        surface: Colors.grey[850]!,
        background: Colors.grey[900]!,
      ),
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue[300]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey[400]),
        errorStyle: TextStyle(color: Colors.red[300]),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    return Theme(
      data: darkTheme,
      child: Scaffold(
        appBar: AppBar(
          title:  Text(
            "Sign Up",
            style: TextStyle(color: Colors.white,fontSize: 20),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[900]!,
                Colors.grey[850]!,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Full Name Field
                  _buildTextField(
                    controller: _fullNameController,
                    label: "Full Name",
                    icon: Icons.person_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your full name.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    label: "Email ID",
                    icon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email.";
                      }
                      if (!value.contains("@")) {
                        return "Please enter a valid email address.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    label: "Password",
                    icon: Icons.lock_outlined,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a password.";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters long.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password Field
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: "Confirm Password",
                    icon: Icons.lock_outlined,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please confirm your password.";
                      }
                      if (value != _passwordController.text) {
                        return "Passwords do not match.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Phone Number Field
                  _buildTextField(
                    controller: _phoneNumberController,
                    label: "Phone Number",
                    icon: Icons.phone_outlined,
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

                  // Date of Birth Field
                  TextFormField(
                    controller: _dateOfBirthController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Date of Birth (YYYY-MM-DD)",
                      prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[400]),
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: darkTheme.copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Colors.blue[300]!,
                                onPrimary: Colors.white,
                                surface: Colors.grey[850]!,
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        _dateOfBirthController.text = pickedDate.toString().split(" ")[0];
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please select your date of birth.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Gender Dropdown
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.grey[850],
                    decoration: InputDecoration(
                      labelText: "Gender",
                      prefixIcon: Icon(Icons.wc, color: Colors.grey[400]),
                    ),
                    style: TextStyle(color: Colors.white),
                    value: _gender,
                    items: <String>['Male', 'Female', 'Other'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _gender = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please select your gender.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Emergency Contact Name Field
                  _buildTextField(
                    controller: _emergencyContactNameController,
                    label: "Emergency Contact Name",
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter the emergency contact name.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Emergency Contact Number Field
                  _buildTextField(
                    controller: _emergencyContactNumberController,
                    label: "Emergency Contact Number",
                    icon: Icons.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter the emergency contact number.";
                      }
                      if (value.length < 10) {
                        return "Please enter a valid emergency contact number.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Sign Up Button
                  _isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue[300],
                    ),
                  )
                      : signInSignUpButton(context, false, _registerUser),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable TextField Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[400]),
      ),
      validator: validator,
    );
  }

  // User Registration Method
  void _registerUser() async {
    // Validate the form
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection("users").doc(userCredential.user!.uid).set({
          "fullName": _fullNameController.text.trim(),
          "email": _emailController.text.trim(),
          "phoneNumber": _phoneNumberController.text.trim(),
          "dateOfBirth": _dateOfBirthController.text.trim(),
          "gender": _gender,
          "emergencyContactName": _emergencyContactNameController.text.trim(),
          "emergencyContactNumber": _emergencyContactNumberController.text.trim(),
          "uid": userCredential.user!.uid,
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Signup failed. Please try again.";
      if (e.code == "email-already-in-use") {
        errorMessage = "The email address is already in use.";
      } else if (e.code == "weak-password") {
        errorMessage = "The password is too weak.";
      }
      _showError(errorMessage);
    } catch (e) {
      _showError("An unexpected error occurred. Please try again.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Error Display Method
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
      ),
    );
  }
}