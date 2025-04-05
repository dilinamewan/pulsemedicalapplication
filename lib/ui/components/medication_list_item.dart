import 'package:flutter/material.dart';
import 'package:pulse/models/Medication.dart';
import 'package:intl/intl.dart';

class MedicationListItem extends StatelessWidget {
  final Medication medication;
  final Function(int, bool) onTakenStatusChanged;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const MedicationListItem({
    super.key,
    required this.medication,
    required this.onTakenStatusChanged,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final allTaken = medication.takenStatus.every((status) => status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Frequency: ${medication.frequency} time${medication.frequency > 1 ? "s" : ""}/day',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
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
                    color: allTaken ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Colors.red[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
