import 'package:hive/hive.dart';

class CalendarEvent extends HiveObject {
  final String id;

  String title;

  String description;

  String location;

  DateTime start;

  DateTime end;

  bool isAllDay;

  int? reminderMinutes;

  String? rrule;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.start,
    required this.end,
    required this.isAllDay,
    required this.reminderMinutes,
    required this.rrule,
  });

  DateTime get startDate => DateTime(start.year, start.month, start.day);
  DateTime get endDate => DateTime(end.year, end.month, end.day);

  Map<String, dynamic> toJson() {
    return {
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
  }

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

  static CalendarEvent fromJson(Map<String, dynamic> json) {
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
}

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
