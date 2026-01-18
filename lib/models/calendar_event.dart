import 'package:hive/hive.dart';

/// Represents a calendar event with optional recurrence rules.
///
/// Events can be all-day or time-specific, with optional reminders
/// and recurrence patterns following the iCalendar (RFC 5545) RRULE format.
class CalendarEvent extends HiveObject {
  /// Creates a new calendar event.
  ///
  /// All events require an [id], [title], [start], and [end] time.
  /// Optional fields include [description], [location], [reminderMinutes],
  /// and [rrule] for recurrence patterns.
  CalendarEvent({
    required this.id,
    required this.title,
    this.description = '',
    this.location = '',
    required this.start,
    required this.end,
    this.isAllDay = false,
    this.reminderMinutes,
    this.rrule,
  });

  /// Creates an empty event with default values for a given date.
  factory CalendarEvent.empty(String id, DateTime initialDate) {
    final start = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
      initialDate.hour,
      initialDate.minute,
    );
    return CalendarEvent(
      id: id,
      title: '',
      start: start,
      end: start.add(const Duration(hours: 1)),
      reminderMinutes: 10,
    );
  }

  /// Creates an event from a JSON map.
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      location: (json['location'] ?? '') as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      isAllDay: (json['isAllDay'] ?? false) as bool,
      reminderMinutes: json['reminderMinutes'] as int?,
      rrule: json['rrule'] as String?,
    );
  }

  /// Unique identifier for the event.
  final String id;

  /// Event title/summary.
  final String title;

  /// Optional event description.
  final String description;

  /// Optional event location.
  final String location;

  /// Start date and time of the event.
  final DateTime start;

  /// End date and time of the event.
  final DateTime end;

  /// Whether this is an all-day event.
  final bool isAllDay;

  /// Minutes before the event to trigger a reminder, or null for no reminder.
  final int? reminderMinutes;

  /// Optional recurrence rule in iCalendar RRULE format.
  final String? rrule;

  /// Returns the date portion of [start] (time set to midnight).
  DateTime get startDate => DateTime(start.year, start.month, start.day);

  /// Returns the date portion of [end] (time set to midnight).
  DateTime get endDate => DateTime(end.year, end.month, end.day);

  /// Whether this event has a recurrence rule.
  bool get isRecurring => rrule != null && rrule!.isNotEmpty;

  /// Whether this event has a reminder set.
  bool get hasReminder => reminderMinutes != null;

  /// Duration of the event.
  Duration get duration => end.difference(start);

  /// Converts this event to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'isAllDay': isAllDay,
        'reminderMinutes': reminderMinutes,
        'rrule': rrule,
      };

  /// Creates a copy of this event with the given fields replaced.
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? start,
    DateTime? end,
    bool? isAllDay,
    int? reminderMinutes,
    String? rrule,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      start: start ?? this.start,
      end: end ?? this.end,
      isAllDay: isAllDay ?? this.isAllDay,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      rrule: rrule ?? this.rrule,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          location == other.location &&
          start == other.start &&
          end == other.end &&
          isAllDay == other.isAllDay &&
          reminderMinutes == other.reminderMinutes &&
          rrule == other.rrule;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        location,
        start,
        end,
        isAllDay,
        reminderMinutes,
        rrule,
      );

  @override
  String toString() => 'CalendarEvent(id: $id, title: $title, '
      'start: $start, end: $end, isAllDay: $isAllDay)';
}

/// Hive type adapter for [CalendarEvent].
///
/// Handles serialization and deserialization of calendar events
/// for persistent storage using Hive.
class CalendarEventAdapter extends TypeAdapter<CalendarEvent> {
  @override
  final int typeId = 1;

  @override
  CalendarEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return CalendarEvent(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      location: fields[3] as String,
      start: fields[4] as DateTime,
      end: fields[5] as DateTime,
      isAllDay: fields[6] as bool,
      reminderMinutes: fields[7] as int?,
      rrule: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarEvent obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.start)
      ..writeByte(5)
      ..write(obj.end)
      ..writeByte(6)
      ..write(obj.isAllDay)
      ..writeByte(7)
      ..write(obj.reminderMinutes)
      ..writeByte(8)
      ..write(obj.rrule);
  }
}
