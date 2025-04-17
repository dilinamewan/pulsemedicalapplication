import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

class HealthMetricsPage extends StatefulWidget {
  const HealthMetricsPage({super.key});

  @override
  State<HealthMetricsPage> createState() => _HealthMetricsPageState();
}

class _HealthMetricsPageState extends State<HealthMetricsPage> {
  String healthMetricsData = '';
  bool isLoading = true;
  List<Map<String, dynamic>> metrics = [];

  @override
  void initState() {
    super.initState();
    _loadHealthMetrics();
  }

  Future<void> _loadHealthMetrics() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Health Metrics')
          .orderBy('date', descending: true)
          .get();

      final loadedMetrics = snapshot.docs.map((doc) {
        final data = <String, dynamic>{};

        if (doc['blood_pressure']?.toString().trim().isNotEmpty ?? false) {
          data['blood_pressure'] = doc['blood_pressure'];
        }
        if (doc['sugar_level']?.toString().trim().isNotEmpty ?? false) {
          data['sugar_level'] = doc['sugar_level'];
        }
        if (doc['cholesterol_level']?.toString().trim().isNotEmpty ?? false) {
          data['cholesterol_level'] = doc['cholesterol_level'];
        }
        data['date'] = (doc['date'] as Timestamp).toDate().toIso8601String();
        data['id'] = doc.id; // Store document ID for deletion

        return data;
      }).toList();

      setState(() {
        metrics = loadedMetrics;
        healthMetricsData = jsonEncode(loadedMetrics);
        isLoading = false;
      });
    } catch (e) {
      print("🔥 Failed to load health metrics: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteMetric(String docId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Health Metrics')
          .doc(docId)
          .delete();

      // Refresh the list
      _loadHealthMetrics();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Health metric deleted successfully'))
      );
    } catch (e) {
      print("🔥 Failed to delete health metric: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete health metric'))
      );
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return
      Theme(data: darkTheme, child:
      Scaffold(
      appBar: AppBar(
        title: Text('Health Metrics'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadHealthMetrics,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : metrics.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.healing_outlined,
              size: 80,
              color: Colors.grey[600],
            ),
            SizedBox(height: 16),
            Text(
              'No health metrics available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to add health metric page
                // You can implement navigation to your add metric form here
              },
              child: Text('Add Health Metrics'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: metrics.length,
        itemBuilder: (context, index) {
          final metric = metrics[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(metric['date']),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[300],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Health Metric'),
                              content: Text('Are you sure you want to delete this health metric?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteMetric(metric['id']);
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red[300]),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey[700]),
                  SizedBox(height: 8),
                  if (metric.containsKey('blood_pressure'))
                    _buildMetricRow(
                      Icons.favorite,
                      'Blood Pressure',
                      metric['blood_pressure'],
                      Colors.red[300]!,
                    ),
                  if (metric.containsKey('sugar_level'))
                    _buildMetricRow(
                      Icons.water_drop,
                      'Sugar Level',
                      metric['sugar_level'],
                      Colors.amber[300]!,
                    ),
                  if (metric.containsKey('cholesterol_level'))
                    _buildMetricRow(
                      Icons.science,
                      'Cholesterol Level',
                      metric['cholesterol_level'],
                      Colors.green[300]!,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ),);
  }

  Widget _buildMetricRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}