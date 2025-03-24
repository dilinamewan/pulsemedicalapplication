import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReminderTimePicker extends StatelessWidget {
  final DateTime initialTime;
  final Function(DateTime) onTimeChanged;

  const ReminderTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: const Icon(Icons.access_time),
        title: Text(
          timeFormat.format(initialTime),
          style: const TextStyle(fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(initialTime),
            builder: (BuildContext context, Widget? child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  timePickerTheme: TimePickerThemeData(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    hourMinuteShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    dayPeriodShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  colorScheme: ColorScheme.light(
                    primary: Theme.of(context).primaryColor,
                  ),
                ),
                child: child!,
              );
            },
          );
          
          if (picked != null) {
            // Create a new DateTime with the same date but updated time
            final newDateTime = DateTime(
              initialTime.year,
              initialTime.month,
              initialTime.day,
              picked.hour,
              picked.minute,
            );
            onTimeChanged(newDateTime);
          }
        },
      ),
    );
  }
}