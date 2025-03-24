import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddHMUI extends StatefulWidget {
  const AddHMUI({Key? key}) : super(key: key);

  @override
  _AddHMUIState createState() => _AddHMUIState();
}

class _AddHMUIState extends State<AddHMUI> {
  final TextEditingController bloodPressureController = TextEditingController();
  final TextEditingController sugarLevelController = TextEditingController();
  final TextEditingController heartRateController = TextEditingController();
  final TextEditingController cholesterolLevelController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Health Metrics'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Input Your Health Metrics',
              style: TextStyle(
                fontSize: 28,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

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
            const SizedBox(height: 20),

            // Heart Rate Input Field
            _buildTextField(
              controller: heartRateController,
              label: 'Heart Rate',
              hint: 'Input your Heart Rate (bpm)',
              icon: Icons.favorite,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  String userId = "yB57HeFJmMbaY8WLyxfg"; // Save logic to Firestore
                  try {
                    await FirebaseFirestore.instance
                        .collection('users') // The existing 'users' collection
                        .doc(userId) // The specific user document
                        .collection('health_metrics') // The health metrics subcollection
                        .add({
                      'blood_pressure': bloodPressureController.text,
                      'sugar_level': sugarLevelController.text,
                      'heart_rate': heartRateController.text,
                      'cholesterol_level': cholesterolLevelController.text,
                      'timestamp': FieldValue.serverTimestamp(), // Automatically add timestamp
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Metrics saved successfully!')),
                    );

                    // Clear form after saving
                    bloodPressureController.clear();
                    sugarLevelController.clear();
                    heartRateController.clear();
                    cholesterolLevelController.clear();

                  } catch (e) {
                    print('Error saving metrics: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving metrics: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
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
    );
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
        prefixIcon: Icon(icon, color: Colors.redAccent),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
      ),
      style: const TextStyle(fontSize: 16),
    );
  }
}