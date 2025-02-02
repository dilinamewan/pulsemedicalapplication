import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void initState() {
    super.initState();
    _clearHistory();
  }

  final _provider = GeminiProvider(
    model: GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: dotenv.env['Gemini_API_KEY'] ?? "",
      systemInstruction: Content.system(
          '''your a professional medicle assitent that analyze reports and 
            give insides but your not a doctor so just explain things but 
            remeber your just a bot soo advice only'''),
    ),
  );

  void _clearHistory() {
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
