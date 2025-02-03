import 'package:flutter/material.dart';

import '../reusable_widgets/reusable_widget.dart';
import '../utils/color_utils.dart';
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("d3d4cb"),  // Correctly quoted hex color strings
              hexStringToColor("3f403d"),  // Correctly quoted hex color strings
            ],begin: Alignment.topCenter,end: Alignment.bottomCenter)),
            child:SingleChildScrollView(
    child: Padding(
    padding: EdgeInsets.fromLTRB(
    20,MediaQuery.of(context).size.height*0.2,20,0),
    child: Column(
    children: <Widget>[
      logoWidget("assets/images/logo.jpeg"),
    ],
          ),
        ),
      ),
      ),
    );
  }

}