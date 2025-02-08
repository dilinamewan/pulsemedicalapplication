import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pulse/ui/component/reusable_widget.dart';
import '../utils/color_utils.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  bool isPasswordType = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("E3F2FD"), // Light blue (medical feel)
              hexStringToColor("FFFFFF"), // White (clean look)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.15, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // App Name "Pulse"
                Text(
                  "Pulse",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900], // Darker blue for visibility
                  ),
                ),
                SizedBox(height: 20),

                logoWidget("assets/images/logo.jpeg"),
                SizedBox(height: 30),

                reusableTextField(
                  "Enter Username", 
                  Icons.person_outlined, 
                  false, 
                  _emailTextController
                ),
                SizedBox(height: 30),

                reusableTextField(
                  "Enter Password", 
                  Icons.lock_outline, 
                  isPasswordType, 
                  _passwordTextController
                ),
                SizedBox(height: 30),
                signInSignUpButton(context, true, () {
                  FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: _emailTextController.text,
                    password: _passwordTextController.text
                  ).then((value) {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (context) => HomeScreen())
                    );
                  }).catchError((error) {
                    print("Sign in error: $error");
                  });
                }),
                SizedBox(height: 20),  // Added spacing before the sign up option
                signUpOption()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",  // Added space after question mark
          style: TextStyle(
            color: Colors.black87,    // Changed from white70 to black87
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => SignupScreen())
            );
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}