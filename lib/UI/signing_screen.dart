import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pulse/ui/components/reusable_widget.dart';
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
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool isPasswordType = true;
  bool _rememberMe = false;
  late SharedPreferences _prefs;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials().then((_) {
      _checkBiometricSupport().then((_) {
        if (_canCheckBiometrics) {
          _authenticateWithBiometrics(); // Auto-launch biometric authentication
        }
      });
    });
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canCheckBiometrics || isDeviceSupported;
      });
    } catch (e) {
      _showErrorMessage('Error checking biometrics: $e');
    }
  }

  Future<void> _loadSavedCredentials() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = _prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _emailTextController.text = _prefs.getString('email') ?? '';
        _passwordTextController.text = _prefs.getString('password') ?? '';
      }
    });
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await _prefs.setString('email', _emailTextController.text);
      await _prefs.setString('password', _passwordTextController.text);
      await _prefs.setBool('rememberMe', true);
    } else {
      await _prefs.remove('email');
      await _prefs.remove('password');
      await _prefs.setBool('rememberMe', false);
    }
  }

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
      await _saveCredentials();
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

  Future<void> _authenticateWithBiometrics() async {
    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to sign in',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated &&
          _rememberMe &&
          _emailTextController.text.isNotEmpty &&
          _passwordTextController.text.isNotEmpty) {
        _signIn();
      } else if (authenticated) {
        _showErrorMessage(
            "Please enable Remember Me and fill in credentials first");
      }
    } catch (e) {
      _showErrorMessage("Biometric authentication failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Colors.white],
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
                      color: Colors.blue[900]),
                ),
                SizedBox(height: 20),
                logoWidget("assets/images/logo.jpeg"),
                SizedBox(height: 30),
                reusableTextField("Enter Email", Icons.person_outlined, false,
                    _emailTextController),
                SizedBox(height: 30),
                reusableTextField("Enter Password", Icons.lock_outline, true,
                    _passwordTextController),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    GestureDetector(
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
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                signInSignUpButton(context, true, _signIn),
                SizedBox(height: 20),
                signUpOption(),
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
        Text("Don't have an account? ",
            style: TextStyle(color: Colors.black87)),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignupScreen()),
            );
          },
          child: Text(
            "Sign Up",
            style: TextStyle(
                color: Colors.blueAccent, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailTextController.dispose();
    _passwordTextController.dispose();
    super.dispose();
  }
}
