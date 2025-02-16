import 'ui/signing_screen.dart';
import 'package:pulse/ui/chatUi.dart';
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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SignInScreen()
    );
  }
}
