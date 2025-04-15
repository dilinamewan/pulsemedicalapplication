import 'package:uuid/uuid.dart';

class Medication {
  final String id;
  final String name;
  final String category;
  final int frequency;
  final List<DateTime> reminderTimes;
  final List<bool> takenStatus;
  final String? notes;
  final String userId;
  final DateTime? endDate;
  final DateTime startDate;

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
    this.endDate,
    required this.startDate,// Add this parameter
  }) :
        id = id ?? const Uuid().v4(),
        takenStatus = takenStatus ?? List.filled(reminderTimes.length, false);

  // Update copyWith to include endDate
  Medication copyWith({
    String? name,
    String? category,
    List<DateTime>? reminderTimes,
    int? frequency,
    List<bool>? takenStatus,
    String? notes,
    DateTime? endDate,
    DateTime? startDate,
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
      endDate: endDate ?? this.endDate,
      startDate: startDate ?? this.startDate
    );
  }

  // Update toMap to include endDate
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
      'endDate': endDate?.millisecondsSinceEpoch,
      'startDate':startDate?.microsecondsSinceEpoch
      // Store as milliseconds
    };
  }

  static Medication fromMap(Map<String, dynamic> map) {
    List<dynamic> timesList = map['reminderTimes'];
    List<DateTime> times = timesList
        .map((time) => DateTime.fromMillisecondsSinceEpoch(time as int))
        .toList();

    List<dynamic> statusList = map['takenStatus'] ?? List.filled(times.length, false);
    List<bool> status = statusList.map((status) => status as bool).toList();

    DateTime? endDate;
    if (map['endDate'] != null) {
      endDate = DateTime.fromMillisecondsSinceEpoch(map['endDate']);
    }

    DateTime startDate;
    if (map['startDate'] != null) {
      startDate = DateTime.fromMicrosecondsSinceEpoch(map['startDate']);
    } else {
      throw Exception('startDate is required');
    }

    return Medication(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      frequency: map['frequency'] ?? 1,
      reminderTimes: times,
      takenStatus: status,
      notes: map['notes'],
      userId: map['userId'],
      endDate: endDate,
      startDate: startDate,
    );
  }

  // Add a helper method to check if medication is active
  bool isActive() {
    if (endDate == null) return true;

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return endDate!.isAfter(todayEnd);
  }
}