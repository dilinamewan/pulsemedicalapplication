import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulse/ui/components/reusable_widget.dart';
import 'package:pulse/utils/color_utils.dart';
import 'package:pulse/ui/home.dart';
import 'package:pulse/ui/signup_screen.dart';
import 'package:pulse/ui/forgot_password_screen.dart';
import 'package:local_auth/local_auth.dart';

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
        // Automatically attempt biometric authentication after loading credentials
        if (_canCheckBiometrics && _rememberMe) {
          _authenticateWithBiometrics();
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

      if (!_canCheckBiometrics) {
        _showErrorMessage('Biometrics not supported on this device');
      }
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

  Future<void> _authenticateWithBiometrics() async {
    try {
      String? savedEmail = _prefs.getString('email');
      String? savedPassword = _prefs.getString('password');
      if (savedEmail == null || savedPassword == null) {
        _showErrorMessage('No saved credentials found. Please sign in first.');
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to sign in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: savedEmail,
          password: savedPassword,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        _showErrorMessage('Biometric authentication cancelled');
      }
    } catch (e) {
      _showErrorMessage('Biometric authentication failed: $e');
    }
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

      await saveUserCredentials();
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
                TextField(
                  controller: _passwordTextController,
                  obscureText: isPasswordType,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: "Enter Password",
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.black54),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordType
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordType = !isPasswordType;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: Colors.blue[900],
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        Text(
                          "Remember Me",
                          style: TextStyle(color: Colors.black87),
                        ),
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
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
                signUpOption(),
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

  @override
  void dispose() {
    _emailTextController.dispose();
    _passwordTextController.dispose();
    super.dispose();
  }
}
