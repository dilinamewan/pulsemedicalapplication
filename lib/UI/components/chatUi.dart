import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pulse/services/pdf_service.dart';
import 'dart:convert';
import 'package:pulse/models/Schedules.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/Medication.dart';



class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? fileContent;
  GeminiProvider? _provider;
  bool _isInitialized = false;
  String? _error;
  String? scheduleData;
  String currentDateTime = '';
  String? healthMetricsData;
  String? medicationsData;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      currentDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      await _loadFileContent();
      await _loadScheduleData();
      await _loadHealthMetrics();
      await _loadMedications();
      _initializeProvider();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _loadMedications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .get();

      final dateFormat = DateFormat('yyyy-MM-dd');

      int normalizeTimestamp(dynamic value) {
        if (value is int) {
          if (value > 10000000000000) return (value / 1000).round();
          if (value < 100000000000) return value * 1000;
          return value;
        }
        return 0;
      }

      final meds = snapshot.docs.map((doc) {
        final med = Medication.fromMap(doc.data());
        final medMap = med.toMap();
        medMap.remove('id');
        medMap.remove('reminderTimes');

        if (medMap['startDate'] is int) {
          final startDate = DateTime.fromMillisecondsSinceEpoch(
            normalizeTimestamp(medMap['startDate']),
          );
          medMap['startDate'] = dateFormat.format(startDate);
        }

        if (medMap['endDate'] is int) {
          final endDate = DateTime.fromMillisecondsSinceEpoch(
            normalizeTimestamp(medMap['endDate']),
          );
          medMap['endDate'] = dateFormat.format(endDate);
        }

        return medMap;
      }).toList();

      medicationsData = jsonEncode(meds);
      print(medicationsData);
    } catch (e) {
      print("💊 Failed to load medications: $e");
    }
  }

  Future<void> _loadHealthMetrics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Health Metrics')
          .get();

      final metrics = snapshot.docs.map((doc) {
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

        return data;
      }).toList();


      healthMetricsData = jsonEncode(metrics);
    } catch (e) {
      print("🔥 Failed to load health metrics: $e");
    }
  }

  Future<void> _loadScheduleData() async {
    try {
      final scheduleService = ScheduleService();
      final schedules = await scheduleService.getAllSchedules();
      final mapped = schedules.map((s) => {
        'id':s.scheduleId,
        'title': s.title,
        'date': s.date,
        'start_time': s.startTime,
        'end_time': s.endTime,
        'location': {
          'lat': s.location.latitude,
          'lng': s.location.longitude,
        },
        'alert': s.alert,
        'color': s.color,
        'notes': s.notes,
        'documents': s.documents,
      }).toList();
      scheduleData = jsonEncode(mapped);
    } catch (e) {
      print("🔥 Failed to load schedules: $e");
    }
  }

  Future<void> _loadFileContent() async {
    final parser = DocumentParser();
    try {
      final response = await parser.getAllDocuments(); // returns List<Map<String, dynamic>>
      fileContent = jsonEncode(response); // should work now
    } catch (e) {
      print("🔥 Failed to encode response: $e");
    }
  }

  void _initializeProvider() {

    _provider = GeminiProvider(
      model: GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: dotenv.env['Gemini_API_KEY'] ?? "",
          systemInstruction: Content.system('''
     You are an advanced medical data analysis AI assistant focused on providing comprehensive healthcare insights.
      
      Current Date and Time: $currentDateTime
      
      Available Patient Data:
      1. Medical Reports: $fileContent
      2. Appointment Schedule: $scheduleData
      3. Health Metrics: $healthMetricsData
      4. Medication Information: $medicationsData
      
      Your primary tasks include:
      1. Analyzing and interpreting medical reports (in markdown format)
      2. Tracking health metrics and identifying trends or concerning values
      3. Managing appointment schedules and providing timely reminders
      4. Monitoring medication adherence and offering appropriate guidance
      
      Data Analysis Priorities:
      
      FOR MEDICAL REPORTS:
      - Extract key diagnoses, test results, and physician recommendations
      - Highlight critical values or concerning findings
      - Translate medical terminology into patient-friendly language
      - Connect report findings with current medications and health metrics
      - Cross-reference document_id with schedule data (format: documentfilename_scheduleid)
      
      FOR HEALTH METRICS:
      - Track blood pressure, sugar levels, and cholesterol measurements over time
      - Identify trends, improvements, or deteriorations in health metrics
      - Compare values against normal ranges and previously recorded metrics
      - Suggest potential correlations between health metrics and medications/treatments
      
      FOR APPOINTMENT SCHEDULES:
      - Provide reminders about upcoming medical appointments
      - Suggest preparation steps for specific appointment types
      - Connect appointments with relevant medical reports or test results
      - Organize appointment information by priority and timeline
      
      FOR MEDICATION MANAGEMENT:
      - Track current medications, dosages, and administration schedules
      - Alert about potential medication interactions or side effects
      - Provide timely medication reminders based on reminder times
      - Correlate medication usage with changes in health metrics
      
      Response Requirements:
      - Prioritize clarity and accessibility in all explanations
      - Organize information logically based on urgency and relevance
      - Provide contextual information about medical terms and values
      - Present information in a supportive, non-alarming manner
      - Offer practical, actionable insights when appropriate
      - The response should not include anything in JSON format — only the details.
      
      Important Disclaimer:
      - You are an AI assistant providing informational support only
      - You are NOT a licensed medical professional
      - Always recommend consulting qualified healthcare providers for medical advice
      - Never suggest changing medications or treatments without physician approval
      
      When analyzing data:
      1. First understand which type of data the user is inquiring about
      2. Process and interpret the relevant data format (markdown for reports, JSON for others)
      3. Connect information across different data sources when relevant
      4. Present findings in a structured, easy-to-understand format
''')),
    );

    _provider?.history = [];
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _error!,
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
        body: LlmChatView(
          enableAttachments: false,
      welcomeMessage:
      "Welcome to Pulse Chat, where you can analyze your medical reports",
      provider: _provider!,
      style: LlmChatViewStyle(
          backgroundColor: Colors.black,
      ),
    ));
  }
}