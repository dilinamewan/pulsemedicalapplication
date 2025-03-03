import 'package:flutter/material.dart';
import 'package:pulse/ui/components/AppBarWidget.dart';

class ScheduleFormScreen extends StatefulWidget {
  final String userId;
  final DateTime scheduleDate;

  const ScheduleFormScreen({
    super.key,
    required this.userId,
    required this.scheduleDate,
  });

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBarWidget(),
        body: Center(
          child: Text("hi"),
        ));
  }
}
