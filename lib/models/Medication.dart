import 'package:uuid/uuid.dart';

class Medication {
  final String id;
  final String name;
  final String category;
  final int frequency; // How many times per day
  final List<DateTime> reminderTimes; // Multiple reminder times
  final List<bool> takenStatus; // Status for each reminder time
  final String? notes;
  final String userId;
  static const List<String> categories = [
    'General',
    'Fever',
    'Diabetes',
    'Pain Relief',
    'Heart',
    'Vitamins',
    'Antibiotics',
    'Other'
  ];
  
  Medication({
    String? id,
    required this.name,
    required this.category,
    required this.reminderTimes,
    this.frequency = 1,
    List<bool>? takenStatus,
    this.notes,
    required this.userId,
  }) : 
    id = id ?? const Uuid().v4(),
    takenStatus = takenStatus ?? List.filled(reminderTimes.length, false);
  
  // Create copy with updated fields
  Medication copyWith({
    String? name,
    String? category,
    List<DateTime>? reminderTimes,
    int? frequency,
    List<bool>? takenStatus,
    String? notes,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      frequency: frequency ?? this.frequency,
      takenStatus: takenStatus ?? this.takenStatus,
      notes: notes ?? this.notes,
      userId: userId,
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'frequency': frequency,
      'reminderTimes': reminderTimes.map((time) => time.millisecondsSinceEpoch).toList(),
      'takenStatus': takenStatus,
      'notes': notes,
      'userId': userId,
    };
  }
  
  // Create from Firestore document
  static Medication fromMap(Map<String, dynamic> map) {
    List<dynamic> timesList = map['reminderTimes'];
    List<DateTime> times = timesList
        .map((time) => DateTime.fromMillisecondsSinceEpoch(time as int))
        .toList();
    List<dynamic> statusList = map['takenStatus'] ?? List.filled(times.length, false);
    List<bool> status = statusList.map((status) => status as bool).toList();
    
    return Medication(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      frequency: map['frequency'] ?? 1,
      reminderTimes: times,
      takenStatus: status,
      notes: map['notes'],
      userId: map['userId'],
    );
  }
}