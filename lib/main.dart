import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pulse/ui/AddHMUI.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("Firebase initialized successfully");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.redAccent,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const DashboardScreen(),
    const AddHMUI(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add Metrics',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<FlSpot> bloodPressureData = [];
  List<FlSpot> cholesterolData = [];
  List<FlSpot> sugarLevelData = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    print("DashboardScreen initialized");
    fetchHealthMetrics();
  }

  Future<void> fetchHealthMetrics() async {
    print("Starting to fetch health metrics");
    String userId = "yB57HeFJmMbaY8WLyxfg";

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('health_metrics')
          .orderBy('timestamp', descending: false)
          .get();

      print("Firestore query completed. Documents count: ${snapshot.docs.length}");

      if (snapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No health metrics found';
        });
        return;
      }

      // Print all field names from the first document to check what's available
      if (snapshot.docs.isNotEmpty) {
        print("First document fields: ${(snapshot.docs.first.data() as Map<String, dynamic>).keys.join(', ')}");
      }

      List<FlSpot> bpData = [];
      List<FlSpot> chData = [];
      List<FlSpot> slData = [];

      int index = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Try different possible field names for blood pressure
        double bp = 0;
        if (data.containsKey('blood_pressure')) {
          bp = double.tryParse(data['blood_pressure'].toString()) ?? 0;
        }

        double ch = 0;
        // Try different possible field names for cholesterol
        if (data.containsKey('cholesterol_level')) {
          ch = double.tryParse(data['cholesterol_level'].toString()) ?? 0;
        } else if (data.containsKey('cholesterol')) {
          ch = double.tryParse(data['cholesterol'].toString()) ?? 0;
        }

        double sl = 0;
        if (data.containsKey('sugar_level')) {
          sl = double.tryParse(data['sugar_level'].toString()) ?? 0;
        } else if (data.containsKey('sugar')) {
          sl = double.tryParse(data['sugar'].toString()) ?? 0;
        }

        bpData.add(FlSpot(index.toDouble(), bp));
        chData.add(FlSpot(index.toDouble(), ch));
        slData.add(FlSpot(index.toDouble(), sl));

        index++;
      }

      print("Data processing completed");
      print("Blood pressure data points: ${bpData.length}");
      print("Cholesterol data points: ${chData.length}");
      print("Sugar level data points: ${slData.length}");

      setState(() {
        bloodPressureData = bpData;
        cholesterolData = chData;
        sugarLevelData = slData;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching health metrics: $e");
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building DashboardScreen");
    print("Chart data - BP: ${bloodPressureData.length}, Cholesterol: ${cholesterolData.length}, Sugar: ${sugarLevelData.length}");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Welcome to", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pulse",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Health Matrices",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                        : errorMessage.isNotEmpty
                        ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.white70)))
                        : bloodPressureData.isEmpty
                        ? const Center(child: Text("No data available", style: TextStyle(color: Colors.white70)))
                        : LineChart(
                      LineChartData(
                        backgroundColor: Colors.black,
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
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(color: Colors.white70),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(color: Colors.white70),
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
                          ),
                          LineChartBarData(
                            spots: cholesterolData,
                            isCurved: true,
                            barWidth: 3,
                            color: Colors.yellow,
                            belowBarData: BarAreaData(show: false),
                          ),
                          LineChartBarData(
                            spots: sugarLevelData,
                            isCurved: true,
                            barWidth: 3,
                            color: Colors.green,
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LegendIndicator(color: Colors.blue, text: "Blood Pressure"),
                        const SizedBox(width: 10),
                        LegendIndicator(color: Colors.yellow, text: "Cholesterol Level"),
                        const SizedBox(width: 10),
                        LegendIndicator(color: Colors.green, text: "Sugar Level"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegendIndicator extends StatelessWidget {
  final Color color;
  final String text;

  const LegendIndicator({Key? key, required this.color, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
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