import 'package:flutter/material.dart';
import 'package:pulse/reusable_widgets/reusable_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/color_utils.dart';
import 'home_screen.dart'; // Assuming this contains your reusableTextField and hexStringToColor

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactNumberController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController(); // For Date of Birth
  String? _gender; // For Gender

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
          padding: const EdgeInsets.all(25.0), // Add padding for better spacing
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align labels to the left
            children: <Widget>[
              const SizedBox(height: 20),

              reusableTextField("Full Name", Icons.person_outlined, false, _fullNameController),
              const SizedBox(height: 20),

              reusableTextField("Username", Icons.person_outlined, false, _usernameController),
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
                  labelText: "Date of Birth (YYYY-MM-DD)", // Or use a date picker
                  icon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.datetime, // For better keyboard input
                onTap: () async {  // Example using showDatePicker
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    _dateOfBirthController.text = pickedDate.toString().split(" ")[0]; // Format
                  }
                },
              ),
              const SizedBox(height: 20),


              // Gender
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Gender",
                  icon: Icon(Icons.wc),
                ),
                value: _gender,
                items: <String>['Male', 'Female', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
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
              signInSignUpButton(context, false, () {
                FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: _emailController.text,
                  password: _passwordController.text,
                ).then((value) {
                  print("User created successfully");
                  // Navigate to the home screen
                  Navigator.push(context, 
                  MaterialPageRoute(builder: (context) => const HomeScreen()));
                }).onError((error, stackTrace) {
                  // Handle error
                  print("Error: ${error.toString()}");
                });
              }),


            ],
          ),
        ),
      ),
    );
  }
}