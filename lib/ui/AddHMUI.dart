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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Add Health Metrics'),
          backgroundColor: Colors.teal,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Input Your Health Metrics',
                style: TextStyle(
                  fontSize: 35,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 30),

              // Blood Pressure Input Field
              _buildTextField(
                controller: bloodPressureController,
                label: 'Blood Pressure',
                hint: 'Input your Blood Pressure',
                icon: Icons.bloodtype,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 20),

              // Sugar Level Input Field
              _buildTextField(
                controller: sugarLevelController,
                label: 'Sugar Level',
                hint: 'Input your Sugar Level (mg/dL)',
                icon: Icons.local_hospital,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),

              // Heart Rate Input Field
              _buildTextField(
                controller: heartRateController,
                label: 'Heart Rate',
                hint: 'Input your Heart Rate (bpm)',
                icon: Icons.favorite,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 40),

              // Save Button
              ElevatedButton(
                onPressed: () async {
                  // Save logic to Firestore
                  try {
                    await FirebaseFirestore.instance.collection('health_metrics').add({
                      'blood_pressure': bloodPressureController.text,
                      'sugar_level': sugarLevelController.text,
                      'heart_rate': heartRateController.text,
                      'timestamp': FieldValue.serverTimestamp(), // Optional: timestamp of when data was added
                    });
                    print('Metrics saved successfully');
                  } catch (e) {
                    print('Error saving metrics: $e');
                  }
                },
                child: Text(
                  'Save Metrics',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Corrected from `primary`
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),


              ),
            ],
          ),
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
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal),
        ),
      ),
      style: TextStyle(fontSize: 18),
    );
  }
}