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

      final meds = snapshot.docs.map((doc) {
        final med = Medication.fromMap(doc.data());

        final medMap = med.toMap();
        medMap.remove('id');

        return medMap;
      }).toList();

      medicationsData = jsonEncode(meds);
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
          model: 'gemini-1.5-flash',
          apiKey: dotenv.env['Gemini_API_KEY'] ?? "",
          systemInstruction: Content.system('''
      You are an advanced medical report analysis AI assistant. 
      
      Current Date and Time: $currentDateTime

      Current Medical Report Content: 
      $fileContent
      
      Schedule Data:
      $scheduleData
      
       Health Metrics Data:
      $healthMetricsData
      
      Medication Reminder Data:
      $medicationsData

      Your task is to:
      1. Carefully analyze the provided markdown file content above
      2. Extract and summarize key medical insights
      3. Provide clear, structured explanations of medical information
      4. Alert the user about upcoming medical appointments, tests, or procedures
      5. use id of schedule data as sheduleid and make relationship with Current 
         Medical Report Content because document_id is docuementfilename_sheduleid
         if there any.
      6. manage health matrix and provide information and advice about those if user ask. 
      
      Markdown File Content Guidelines:
      - Critically examine all sections of the medical document
      - Pay special attention to diagnosis, test results, treatments
      - Identify potential medical trends or significant health indicators
      
      Response Requirements:
      - Present findings in a clear, organized manner
      - Highlight important medical details
      - Explain medical terminology in accessible language
      - Provide context and potential implications of the findings
      
      Important Disclaimer: 
      - You are an AI assistant, NOT a licensed medical professional
      - Recommendations are for informational purposes only
      - Always advise consulting a qualified healthcare provider for personalized medical advice
      
      Analysis Process:
      - Systematically review each section of the markdown document
      - Cross-reference medical information for consistency
      - Identify potential areas requiring further medical investigation
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