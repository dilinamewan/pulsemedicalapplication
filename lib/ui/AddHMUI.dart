import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: AppBarTheme(
    color: Colors.transparent,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.blue[300]!),
    ),
    labelStyle: TextStyle(color: Colors.grey[400]),
    iconColor: Colors.grey[400],
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
);

class AddHMUI extends StatefulWidget {
  final DateTime scheduleDate;
  const AddHMUI({super.key,required this.scheduleDate,});

  @override
  _AddHMUIState createState() => _AddHMUIState();
}

class _AddHMUIState extends State<AddHMUI> {
  final TextEditingController bloodPressureController = TextEditingController();
  final TextEditingController sugarLevelController = TextEditingController();
  final TextEditingController cholesterolLevelController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('d\'th\' MMMM yyyy').format(widget.scheduleDate);
    return  Theme(
        data: darkTheme,
        child:Scaffold(
      appBar: AppBar(
        title: const Text('Add Health Metrics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected day: $formattedDate',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 23,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 14),
            // Blood Pressure Input Field
            _buildTextField(
              controller: bloodPressureController,
              label: 'Blood Pressure',
              hint: 'Input your Blood Pressure',
              icon: Icons.bloodtype,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),

            // Sugar Level Input Field
            _buildTextField(
              controller: sugarLevelController,
              label: 'Sugar Level',
              hint: 'Input your Sugar Level (mg/dL)',
              icon: Icons.local_hospital,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Cholesterol Level Input Field
            _buildTextField(
              controller: cholesterolLevelController,
              label: 'Cholesterol Level',
              hint: 'Input your Cholesterol Level',
              icon: Icons.science,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      print('User not logged in.');
                      return;
                    }
                    await FirebaseFirestore.instance
                        .collection('users') // The existing 'users' collection
                        .doc(user.uid) // The specific user document
                        .collection('Health Metrics') // The health metrics subcollection
                        .add({
                      'blood_pressure': bloodPressureController.text,
                      'sugar_level': sugarLevelController.text,
                      'cholesterol_level': cholesterolLevelController.text,
                      'date': widget.scheduleDate,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Metrics saved successfully!')),
                    );

                    // Clear form after saving
                    bloodPressureController.clear();
                    sugarLevelController.clear();
                    cholesterolLevelController.clear();

                  } catch (e) {
                    print('Error saving metrics: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving metrics: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save Metrics',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // Reusable TextField Widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
      style: const TextStyle(fontSize: 16),
    );
  }
}