import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 80),
              const Text(
                "Sign Up",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
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

              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: "Date of Birth (YYYY-MM-DD)",
                  icon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
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

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Gender",
                  icon: Icon(Icons.wc),
                  border: OutlineInputBorder(),
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
                  ? Center(child: CircularProgressIndicator())
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
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
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
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
//done