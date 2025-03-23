import 'package:supabase_flutter/supabase_flutter.dart';

import 'ui/signing_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();


  try {
    //firebase configuration
    await Firebase.initializeApp();
    //.env configuration
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: "https://wpqjyumngwfovncafewt.supabase.co",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwcWp5dW1uZ3dmb3ZuY2FmZXd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzMDI5OTYsImV4cCI6MjA1Nzg3ODk5Nn0.E8aEzKCi3UC-8vMzXazFea_QAd0obgGfPKXVjGpaMpg",
    );
  } catch (e) {
    throw Exception('Error $e');
  }
  
  //notification configuration
  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'basic_channel',
      channelName: 'Basic Notifications',
      channelDescription: 'Notification channel for basic tests',
      defaultColor: Colors.blue,
      importance: NotificationImportance.High,
    ),

  ]);
  
  runApp(MyApp());
}
final supabase = Supabase.instance.client;
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Calendar App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SignInScreen()
    );
  }
}
