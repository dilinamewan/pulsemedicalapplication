import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse/ui/component/reusable_widget.dart';
import '../utils/color_utils.dart';
import 'home_screen.dart'; 

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactNumberController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  String? _gender;
  
  bool _isLoading = false; // To show loading indicator

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sign Up",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              reusableTextField("Full Name", Icons.person_outlined, false, _fullNameController),
              const SizedBox(height: 20),
              reusableTextField("Email ID", Icons.email_outlined, false, _emailController),
              const SizedBox(height: 20),
              reusableTextField("Password", Icons.lock_outlined, true, _passwordController),
              const SizedBox(height: 20),
              reusableTextField("Confirm Password", Icons.lock_outlined, true, _confirmPasswordController),
              const SizedBox(height: 20),
              reusableTextField("Phone Number", Icons.phone_outlined, false, _phoneNumberController),
              const SizedBox(height: 20),

              // Date of Birth
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: "Date of Birth (YYYY-MM-DD)",
                  icon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.datetime,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    _dateOfBirthController.text = pickedDate.toString().split(" ")[0];
                  }
                },
              ),
              const SizedBox(height: 20),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Gender",
                  icon: Icon(Icons.wc),
                ),
                value: _gender,
                items: <String>['Male', 'Female', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _gender = newValue;
                  });
                },
              ),
              const SizedBox(height: 20),

              reusableTextField("Emergency Contact Name", Icons.person, false, _emergencyContactNameController),
              const SizedBox(height: 20),
              reusableTextField("Emergency Contact Number", Icons.phone, false, _emergencyContactNumberController),
              const SizedBox(height: 20),

              _isLoading 
                ? Center(child: CircularProgressIndicator()) // Show loading spinner
                : signInSignUpButton(context, false, _registerUser),
            ],
          ),
        ),
      ),
    );
  }

  void _registerUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        print("User created successfully: ${userCredential.user!.email}");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }
}
