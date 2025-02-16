import 'package:flutter/material.dart';

Color hexStringToColor(String hexColor) {
  hexColor = hexColor.replaceAll('#', ''); // Remove the "#" if it's present
  if (hexColor.length == 6) {
    hexColor = 'FF' + hexColor; // Add FF for full opacity if it's a 6-digit hex code
  }
  return Color(int.parse('0x$hexColor')); // Parse the hex code and return the color
}
