import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String fileContent;

  @override
  void initState() {
    super.initState();
    _loadFileContent();
    _clearHistory();
  }

  Future<void> _loadFileContent() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String filePath = '${appDocDir.path}/data.md';
    File markdownFile = File(filePath);
    if (await markdownFile.exists()) {
      fileContent = await markdownFile.readAsString();
    } else {
      fileContent = "";
    }
    _initializeProvider();
  }

  late GeminiProvider _provider;

  void _initializeProvider() {
    _provider = GeminiProvider(
      model: GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: dotenv.env['Gemini_API_KEY'] ?? "",
          systemInstruction: Content.system('''
      You are an advanced medical report analysis AI assistant. 

      Current Medical Report Content:
      $fileContent

      Your task is to:
      1. Carefully analyze the provided markdown file content above
      2. Extract and summarize key medical insights
      3. Provide clear, structured explanations of medical information
      
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
  }

  void _clearHistory() async {
    _provider.history = [];
  }

  @override
  Widget build(BuildContext context) {
    return LlmChatView(
      welcomeMessage:
      "Welcome to Pulse Chat, where you can analyze your medical reports",
      provider: _provider,
      style: LlmChatViewStyle(backgroundColor: Colors.black87),
    );
  }
}