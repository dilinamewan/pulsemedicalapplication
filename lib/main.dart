import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:pulse/models/Users.dart';
import 'package:pulse/models/Schedules.dart';
import 'package:pulse/models/Notes.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase initialization
  await Firebase.initializeApp();
  // Notification configuration
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
      ),
    ],
  );

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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String userId = 'ir4cVfO1ASPuTiHpMammsQLnU8t2'; // User ID to fetch schedules for
  String date = '2024-02-01'; // Date to fetch schedules for
  late Future<List<User>> usersFuture;
  late Future<List<Schedule>> schedulesFuture;
  late Future<List<Note>> notesFuture;

  @override
  void initState() {
    super.initState();

    // Request notification permission
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    // Fetch users
    usersFuture = UserService().getUsers();
    // Fetch schedules
    schedulesFuture = ScheduleService().getSchedule(userId, date);
    notesFuture = NoteServices().getNotes('HDsuCopfQCdbDCP4RgrS', userId);
    // Fetch notes once schedules are loaded
    // schedulesFuture.then((schedules) {
    //   if (schedules.isNotEmpty) {
    //     setState(() {
    //       notesFuture = NoteServices().getNotes('HDsuCopfQCdbDCP4RgrS');
    //     });
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Pulse"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Users List
              const Text(
                "Users:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 200,
                child: FutureBuilder<List<User>>(
                  future: usersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text("No users found.");
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final user = snapshot.data![index];
                          return ListTile(
                            title: Text(user.userId),
                          );
                        },
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Schedules List
              const Text(
                "Schedules:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 300,
                child: FutureBuilder<List<Schedule>>(
                  future: schedulesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text("No schedules found.");
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final schedule = snapshot.data![index];
                          return ListTile(
                            title: Text('${schedule.title}  - ${schedule.scheduleId}'),
                            subtitle: Text(
                                '${schedule.date} ${schedule.startTime} - ${schedule.endTime} - ${schedule.alert} - '
                                    'Location: ${schedule.location.latitude}'
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Notes List
              const Text(
                "Notes:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 200,
                child: FutureBuilder<List<Note>>(
                  future: notesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text("No notes found.");
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final note = snapshot.data![index];
                          return ListTile(
                            title: Text(note.title),
                            subtitle: Text('${note.content} ${note.noteId}'),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
