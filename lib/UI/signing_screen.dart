import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulse/ui/components/reusable_widget.dart';
import 'package:pulse/utils/color_utils.dart';
import 'package:pulse/ui/home.dart';
import 'package:pulse/ui/signup_screen.dart';
import 'package:pulse/ui/forgot_password_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();
  bool isPasswordType = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  /// **Load saved credentials if Remember Me is checked**
  Future<void> _loadRememberedUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool remember = prefs.getBool('remember_me') ?? false;
    if (remember) {
      String? email = prefs.getString('email');
      String? password = prefs.getString('password');
      if (email != null && password != null) {
        setState(() {
          _emailTextController.text = email;
          _passwordTextController.text = password;
          _rememberMe = true;
        });
      }
    }
  }

  /// **Save User ID and optionally credentials**
  Future<void> saveUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await prefs.setString('user_id', user.uid);
      await prefs.setBool('remember_me', _rememberMe);
      if (_rememberMe) {
        await prefs.setString('email', _emailTextController.text);
        await prefs.setString('password', _passwordTextController.text);
      } else {
        await prefs.remove('email');
        await prefs.remove('password');
      }
    }
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

      /// **Save User ID and credentials if Remember Me is checked**
      await saveUserCredentials();

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
  Widget build(BuildContext context) {
    return Scaffold(
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
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                    ),
                    Text("Remember Me")
                  ],
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
