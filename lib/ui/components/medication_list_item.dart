import 'package:flutter/material.dart';
import 'package:pulse/models/medication.dart';
import 'package:pulse/ui/medication_details_screen.dart';
import 'package:intl/intl.dart';

class MedicationListItem extends StatelessWidget {
  final Medication medication;
  final Function(int, bool) onTakenStatusChanged;
  final VoidCallback onDelete;

  const MedicationListItem({
    super.key,
    required this.medication,
    required this.onTakenStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final allTaken = medication.takenStatus.every((status) => status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicationDetailsScreen(
                medication: medication,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          medication.category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: Colors.red[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Frequency: ${medication.frequency} time${medication.frequency > 1 ? "s" : ""}/day',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: allTaken ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      allTaken ? 'Taken' : 'Pending',
                      style: TextStyle(
                        color:
                            allTaken ? Colors.green[700] : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (medication.reminderTimes.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: List.generate(
                    medication.reminderTimes.length,
                    (index) => GestureDetector(
                      onTap: () => onTakenStatusChanged(
                          index, !medication.takenStatus[index]),
                      child: Chip(
                        backgroundColor: medication.takenStatus[index]
                            ? Colors.green[100]
                            : Colors.grey[200],
                        label: Text(
                          timeFormat.format(medication.reminderTimes[index]),
                          style: TextStyle(
                            color: medication.takenStatus[index]
                                ? Colors.green[700]
                                : Colors.grey[700],
                          ),
                        ),
                        avatar: Icon(
                          medication.takenStatus[index]
                              ? Icons.check_circle
                              : Icons.access_time,
                          size: 18,
                          color: medication.takenStatus[index]
                              ? Colors.green[700]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              if (medication.notes != null && medication.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Notes: ${medication.notes}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
