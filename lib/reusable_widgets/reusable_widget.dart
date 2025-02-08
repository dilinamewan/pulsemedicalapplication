import 'package:flutter/material.dart';

// Logo Widget with Rounded Corners
Widget logoWidget(String imageName) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(120), // Makes the logo circular
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
    cursorColor: Colors.blueAccent, // Improved cursor visibility
    style: TextStyle(color: Colors.black87), // Input text color
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blueAccent), // Icon color
      hintText: text,
      hintStyle: TextStyle(color: Colors.grey[700]), // Improved hint text visibility
      filled: true,
      fillColor: Colors.white, // White background for better contrast
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0), // Rounded text field
        borderSide: BorderSide.none, // Removes default border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide(color: Colors.blueAccent, width: 1.5), // Highlighted border
      ),
    ),
    keyboardType:
        isPasswordType ? TextInputType.visiblePassword : TextInputType.text,
  );
}
