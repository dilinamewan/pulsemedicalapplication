import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pulse/ui/components/reusable_widget.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailTextController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  void _resetPassword() async {
    String email = _emailTextController.text.trim();

    if (email.isEmpty) {
      _showMessage("Please enter your email address.", isError: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage(
        "Password reset link has been sent to your email.",
        isError: false
      );
      
      // Wait for a moment before popping the screen
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred. Please try again.";
      if (e.code == 'user-not-found') {
        message = "No user found with this email address.";
      }
      _showMessage(message, isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue[900]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.1, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Reset Password",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  "Enter your email address and we'll send you a link to reset your password.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 30),
                reusableTextField(
                  "Enter Email",
                  Icons.person_outlined,
                  false,
                  _emailTextController,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Send Reset Link",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}