import 'package:supabase_flutter/supabase_flutter.dart';
import 'ui/signing_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pulse/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase configuration
    await Firebase.initializeApp();
    // Initialize notifications
    final notificationService = NotificationService();
    await notificationService.initNotifications();
    notificationService.setupNotificationActionListeners();
    // Load .env configuration
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: "https://wpqjyumngwfovncafewt.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwcWp5dW1uZ3dmb3ZuY2FmZXd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzMDI5OTYsImV4cCI6MjA1Nzg3ODk5Nn0.E8aEzKCi3UC-8vMzXazFea_QAd0obgGfPKXVjGpaMpg",
    );
  } catch (e) {
    throw Exception('Error initializing the app: $e');
  }

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Calendar App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SignInScreen(),
    );
  }
}
