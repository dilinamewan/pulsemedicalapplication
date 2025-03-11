import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulse/ui/components/reusable_widget.dart';
import 'package:pulse/utils/color_utils.dart';
import 'package:pulse/ui/home.dart';
import 'package:pulse/ui/signup_screen.dart';
import 'package:pulse/ui/forgot_password_screen.dart';
import 'package:pulse/globals.dart'; // Import global variable

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
  GlobalKey<ScaffoldMessengerState>();
  bool isPasswordType = true;

  /// **Save User ID to SharedPreferences & Global Variable**
  Future<void> saveUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.uid);

      globalUserId = user.uid; // Save User ID in global variable
      print("User ID saved: $globalUserId");
    }
  }

  /// **Retrieve User ID from SharedPreferences**
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    globalUserId = prefs.getString('user_id');
    return globalUserId;
  }

  /// **Sign In Function**
  void _signIn() async {
    String email = _emailTextController.text.trim();
    String password = _passwordTextController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorMessage("Please enter both email and password.");
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      /// **Save User ID after successful login**
      await saveUserId();

      /// **Navigate to Home Page**
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (error) {
      _showErrorMessage("Invalid email or password. Please try again.");
    }
  }


  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.15, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Pulse",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 20),
                logoWidget("assets/images/logo.jpeg"),
                SizedBox(height: 30),
                reusableTextField(
                  "Enter Email",
                  Icons.person_outlined,
                  false,
                  _emailTextController,
                ),
                SizedBox(height: 30),
                reusableTextField(
                  "Enter Password",
                  Icons.lock_outline,
                  isPasswordType,
                  _passwordTextController,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen()),
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                signInSignUpButton(context, true, _signIn),
                SizedBox(height: 20),
                signUpOption()
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// **Sign-Up Option UI**
  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Colors.black87,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignupScreen()),
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
