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
  List<DateTime> dateTimes = [];
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
          .orderBy('date', descending: false)
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
      List<DateTime> dates = [];

      // Get the first document's date to use as day 0
      DateTime? firstDate;
      if (snapshot.docs.isNotEmpty) {
        var firstDoc = snapshot.docs.first.data() as Map<String, dynamic>;
        if (firstDoc.containsKey('date') && firstDoc['date'] is Timestamp) {
          firstDate = (firstDoc['date'] as Timestamp).toDate();
        }
      }

      // If we can't find a valid first date, use current date as fallback
      firstDate ??= DateTime.now();

      // Do not force add zero points - let the data speak for itself

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        DateTime entryDate;
        if (data.containsKey('date') && data['date'] is Timestamp) {
          entryDate = (data['date'] as Timestamp).toDate();
        } else {
          // Fallback to current date if no date is provided
          entryDate = DateTime.now();
        }

        // Calculate days since first date
        int daysSinceFirst = entryDate.difference(firstDate).inDays;
        if (daysSinceFirst < 0) daysSinceFirst = 0; // Safety check

        // Only add data points if they exist (non-zero and non-null)
        double? bp;
        if (data.containsKey('blood_pressure_systolic')) {
          String? bpStr = data['blood_pressure_systolic']?.toString();
          if (bpStr != null && bpStr.isNotEmpty) {
            bp = double.tryParse(bpStr);
          }
        } else {
          // Try to parse from the string format if needed
          String? bpString = data['blood_pressure']?.toString();
          if (bpString != null && bpString.isNotEmpty) {
            try {
              bp = double.tryParse(bpString.split('/')[0]);
            } catch (_) {
              // Ignore parsing errors
            }
          }
        }

        double? ch;
        String? chStr = data['cholesterol_level']?.toString();
        if (chStr != null && chStr.isNotEmpty) {
          ch = double.tryParse(chStr);
        }

        double? sl;
        String? slStr = data['sugar_level']?.toString();
        if (slStr != null && slStr.isNotEmpty) {
          sl = double.tryParse(slStr);
        }

        // Add data points only if they have valid values
        if (bp != null && bp > 0) {
          bpData.add(FlSpot(daysSinceFirst.toDouble(), bp));
        }

        if (ch != null && ch > 0) {
          chData.add(FlSpot(daysSinceFirst.toDouble(), ch));
        }

        if (sl != null && sl > 0) {
          slData.add(FlSpot(daysSinceFirst.toDouble(), sl));
        }

        dates.add(entryDate);
      }

      setState(() {
        bloodPressureData = bpData;
        cholesterolData = chData;
        sugarLevelData = slData;
        dateTimes = dates;
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

        // Check if we have any data to display
        bool hasData = bloodPressureData.isNotEmpty ||
            cholesterolData.isNotEmpty ||
            sugarLevelData.isNotEmpty;

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
                      : !hasData
                      ? const Center(child: Text("No data available", style: TextStyle(color: Colors.white70)))
                      : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade800,
                            strokeWidth: 0.5,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade900,
                            strokeWidth: 0.5,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _calculateOptimalInterval(),
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
                          axisNameWidget: const Text('Days', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          axisNameSize: 22,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: _calculateOptimalXInterval(),
                            getTitlesWidget: (value, meta) {
                              // Only show labels at calculated intervals
                              if (value % _calculateOptimalXInterval() != 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Day ${value.toInt()}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.white24),
                      ),
                      lineBarsData: [
                        if (bloodPressureData.isNotEmpty)
                          LineChartBarData(
                            spots: bloodPressureData,
                            isCurved: false,
                            barWidth: 3,
                            color: Colors.blue,
                            belowBarData: BarAreaData(show: false),
                            dotData: FlDotData(show: true),
                          ),
                        if (cholesterolData.isNotEmpty)
                          LineChartBarData(
                            spots: cholesterolData,
                            isCurved: false,
                            barWidth: 3,
                            color: Colors.yellow,
                            belowBarData: BarAreaData(show: false),
                            dotData: FlDotData(show: true),
                          ),
                        if (sugarLevelData.isNotEmpty)
                          LineChartBarData(
                            spots: sugarLevelData,
                            isCurved: false,
                            barWidth: 3,
                            color: Colors.green,
                            belowBarData: BarAreaData(show: false),
                            dotData: FlDotData(show: true),
                          ),
                      ],
                      minX: 0, // Start from day 0
                      maxX: _getMaxDays(),
                      minY: 0, // Start y from 0
                      maxY: _calculateMaxY(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (bloodPressureData.isNotEmpty)
                      LegendIndicator(color: Colors.blue, text: "Blood Pressure"),
                    if (cholesterolData.isNotEmpty)
                      LegendIndicator(color: Colors.yellow, text: "Cholesterol Level"),
                    if (sugarLevelData.isNotEmpty)
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

  // Helper method to get the maximum day value
  double _getMaxDays() {
    double maxDay = 0;

    for (var spot in [...bloodPressureData, ...cholesterolData, ...sugarLevelData]) {
      if (spot.x > maxDay) maxDay = spot.x;
    }

    // Add 10% padding to the right
    return math.max(1.0, maxDay + (maxDay * 0.1));
  }

  // Helper method to calculate maximum Y value with some padding
  double _calculateMaxY() {
    double maxY = 0;

    for (var spot in [...bloodPressureData, ...cholesterolData, ...sugarLevelData]) {
      if (spot.y > maxY) maxY = spot.y;
    }

    // Add 10% padding above the maximum value
    return math.max(1.0, maxY * 1.1);
  }

  // Helper method to calculate optimal Y-axis interval based on data range
  double _calculateOptimalInterval() {
    double max = _calculateMaxY();

    // Target around 5-7 intervals on the y-axis
    // Ensure it's at least 1.0 to avoid zero interval
    return math.max(1.0, (max / 5).ceilToDouble());
  }

  // Helper method to calculate optimal X-axis interval based on data points
  double _calculateOptimalXInterval() {
    double maxDays = _getMaxDays();

    if (maxDays <= 7) return 1; // Show every day if less than a week
    if (maxDays <= 14) return 2; // Every other day for 2 weeks
    if (maxDays <= 30) return 5; // Every 5 days for a month

    // For longer periods, calculate appropriately
    return math.max(1.0, (maxDays / 5).ceilToDouble());
  }
}

class LegendIndicator extends StatelessWidget {
  final Color color;
  final String text;

  const LegendIndicator({super.key, required this.color, required this.text});

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