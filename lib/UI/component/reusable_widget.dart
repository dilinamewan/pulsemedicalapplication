import 'package:flutter/material.dart';

// Logo Widget with Rounded Corners
Widget logoWidget(String imageName) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(120),
    child: Image.asset(
      imageName,
      fit: BoxFit.cover,
      width: 240,
      height: 240,
      alignment: Alignment.center,
    ),
  );
}

// Reusable Text Field Widget
Widget reusableTextField(String text, IconData icon, bool isPasswordType,
    TextEditingController controller) {
  return TextField(
    controller: controller,
    obscureText: isPasswordType,
    enableSuggestions: !isPasswordType,
    autocorrect: !isPasswordType,
    cursorColor: Colors.blueAccent,
    style: TextStyle(color: Colors.black87),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      hintText: text,
      hintStyle: TextStyle(color: Colors.grey[700]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
    ),
    keyboardType:
    isPasswordType ? TextInputType.visiblePassword : TextInputType.text,
  );
}

Container signInSignUpButton(BuildContext context, bool isLogin, Function onTap) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(90),
    ),
    child: ElevatedButton(
      onPressed: () {
        onTap();
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black87;
          }
          return Colors.blueAccent;
        }),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      child: Text(
        isLogin ? "Sign In" : "Sign Up",
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}