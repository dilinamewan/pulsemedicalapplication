import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class HMUIScreen extends StatefulWidget {
  const HMUIScreen({Key? key}) : super(key: key);

  @override
  HMUIScreenState createState() => HMUIScreenState();
}

class HMUIScreenState extends State<HMUIScreen> {
  List<FlSpot> bloodPressureData = [];
  List<FlSpot> cholesterolData = [];
  List<FlSpot> sugarLevelData = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchHealthMetrics();
  }

  Future<void> fetchHealthMetrics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Health Metrics')
          .orderBy('timestamp', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No health metrics found';
        });
        return;
      }

      List<FlSpot> bpData = [];
      List<FlSpot> chData = [];
      List<FlSpot> slData = [];

      int index = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        double bp;
        if (data.containsKey('blood_pressure_systolic')) {
          bp = double.tryParse(data['blood_pressure_systolic']?.toString() ?? '0') ?? 0;
        } else {
          // Try to parse from the string format if needed
          String bpString = data['blood_pressure']?.toString() ?? '0';
          try {
            bp = double.tryParse(bpString.split('/')[0] ?? '0') ?? 0;
          } catch (_) {
            bp = 0;
          }
        }
        double ch = double.tryParse(data['cholesterol_level']?.toString() ?? '0') ?? 0;
        double sl = double.tryParse(data['sugar_level']?.toString() ?? '0') ?? 0;

        bpData.add(FlSpot(index.toDouble(), bp));
        chData.add(FlSpot(index.toDouble(), ch));
        slData.add(FlSpot(index.toDouble(), sl));
        index++;
      }

      setState(() {
        bloodPressureData = bpData;
        cholesterolData = chData;
        sugarLevelData = slData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate proper sizes based on available space
        final availableWidth = constraints.maxWidth;
        final isSmallScreen = availableWidth < 400;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: isSmallScreen ? 1.2 : 1.8,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                      : errorMessage.isNotEmpty
                      ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white70)))
                      : bloodPressureData.isEmpty
                      ? const Center(child: Text("No data available", style: TextStyle(color: Colors.white70)))
                      : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade800,
                            strokeWidth: 0.5,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                            reservedSize: 30,
                            interval: _calculateOptimalInterval(bloodPressureData, cholesterolData, sugarLevelData),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                            reservedSize: 22,
                            interval: _calculateOptimalXInterval(bloodPressureData.length),
                            getTitlesWidget: (value, meta) {
                              // Only show labels at calculated intervals
                              if (value % _calculateOptimalXInterval(bloodPressureData.length) != 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.white10),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: bloodPressureData,
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.blue,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: cholesterolData,
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.yellow,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: sugarLevelData,
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.green,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: false),
                        ),
                      ],
                      minX: 0,
                      maxX: bloodPressureData.isEmpty ? 0 : bloodPressureData.length - 1.0,
                      minY: _calculateMinY(bloodPressureData, cholesterolData, sugarLevelData),
                      maxY: _calculateMaxY(bloodPressureData, cholesterolData, sugarLevelData),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    LegendIndicator(color: Colors.blue, text: "Blood Pressure"),
                    LegendIndicator(color: Colors.yellow, text: "Cholesterol Level"),
                    LegendIndicator(color: Colors.green, text: "Sugar Level"),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to calculate minimum Y value with some padding
  double _calculateMinY(List<FlSpot> data1, List<FlSpot> data2, List<FlSpot> data3) {
    double minY = double.infinity;

    for (var spot in [...data1, ...data2, ...data3]) {
      if (spot.y < minY) minY = spot.y;
    }

    // Add 10% padding below the minimum value
    return minY == double.infinity ? 0 : (minY * 0.9);
  }

  // Helper method to calculate maximum Y value with some padding
  double _calculateMaxY(List<FlSpot> data1, List<FlSpot> data2, List<FlSpot> data3) {
    double maxY = 0;

    for (var spot in [...data1, ...data2, ...data3]) {
      if (spot.y > maxY) maxY = spot.y;
    }

    // Add 10% padding above the maximum value
    return maxY * 1.1;
  }

  // Helper method to calculate optimal Y-axis interval based on data range
  double _calculateOptimalInterval(List<FlSpot> data1, List<FlSpot> data2, List<FlSpot> data3) {
    double min = _calculateMinY(data1, data2, data3);
    double max = _calculateMaxY(data1, data2, data3);
    double range = max - min;

    // Target around 5-7 intervals on the y-axis
    // Ensure it's at least 1.0 to avoid zero interval
    return math.max(1.0, (range / 5).ceilToDouble());
  }

  // Helper method to calculate optimal X-axis interval based on data points
  double _calculateOptimalXInterval(int dataLength) {
    if (dataLength <= 0) return 1; // Handle empty data case
    if (dataLength <= 5) return 1;
    if (dataLength <= 10) return 2;
    if (dataLength <= 20) return 5;
    return math.max(1.0, (dataLength / 5).ceilToDouble());
  }}

class LegendIndicator extends StatelessWidget {
  final Color color;
  final String text;

  const LegendIndicator({Key? key, required this.color, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}