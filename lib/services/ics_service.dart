import 'package:uuid/uuid.dart';

import '../models/calendar_event.dart';

class IcsService {
  IcsService();

  String exportToIcs(List<CalendarEvent> events) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//TCamp Calendar//EN');
    buffer.writeln('CALSCALE:GREGORIAN');

    for (final event in events) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:${event.id}');
      buffer.writeln('DTSTAMP:${_formatUtc(DateTime.now())}');
      if (event.isAllDay) {
        buffer.writeln('DTSTART;VALUE=DATE:${_formatDate(event.start)}');
        buffer.writeln('DTEND;VALUE=DATE:${_formatDate(event.end)}');
      } else {
        buffer.writeln('DTSTART:${_formatUtc(event.start)}');
        buffer.writeln('DTEND:${_formatUtc(event.end)}');
      }
      buffer.writeln('SUMMARY:${_escapeText(event.title)}');
      if (event.description.isNotEmpty) {
        buffer.writeln('DESCRIPTION:${_escapeText(event.description)}');
      }
      if (event.location.isNotEmpty) {
        buffer.writeln('LOCATION:${_escapeText(event.location)}');
      }
      if (event.rrule != null && event.rrule!.isNotEmpty) {
        buffer.writeln('RRULE:${event.rrule}');
      }
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  List<CalendarEvent> importFromIcs(String content) {
    final unfolded = _unfoldLines(content);
    final events = <CalendarEvent>[];
    final uuid = const Uuid();

    Map<String, String> current = {};
    bool inEvent = false;

    for (final line in unfolded) {
      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        current = {};
        continue;
      }
      if (line == 'END:VEVENT') {
        final event = _parseEvent(current, uuid.v4());
        if (event != null) {
          events.add(event);
        }
        inEvent = false;
        current = {};
        continue;
      }
      if (!inEvent) {
        continue;
      }

      final parts = line.split(':');
      if (parts.length < 2) {
        continue;
      }
      final key = parts.first;
      final value = parts.sublist(1).join(':');
      current[key] = value;
    }

    return events;
  }

  CalendarEvent? _parseEvent(Map<String, String> data, String fallbackId) {
    final uid = data['UID'] ?? fallbackId;
    final summary = _unescapeText(data['SUMMARY'] ?? '');
    final description = _unescapeText(data['DESCRIPTION'] ?? '');
    final location = _unescapeText(data['LOCATION'] ?? '');
    final rrule = data['RRULE'];

    final startKey = data.keys.firstWhere(
      (key) => key.startsWith('DTSTART'),
      orElse: () => '',
    );
    final endKey = data.keys.firstWhere(
      (key) => key.startsWith('DTEND'),
      orElse: () => '',
    );
    if (startKey.isEmpty || endKey.isEmpty) {
      return null;
    }

    final isAllDay = startKey.contains('VALUE=DATE');
    final start = isAllDay
        ? _parseDate(data[startKey] ?? '')
        : _parseDateTime(data[startKey] ?? '');
    final end = isAllDay
        ? _parseDate(data[endKey] ?? '')
        : _parseDateTime(data[endKey] ?? '');

    if (start == null || end == null) {
      return null;
    }

    return CalendarEvent(
      id: uid,
      title: summary,
      description: description,
      location: location,
      start: start,
      end: end,
      isAllDay: isAllDay,
      reminderMinutes: null,
      rrule: rrule,
    );
  }

  String _formatUtc(DateTime dt) {
    final utc = dt.toUtc();
    return '${_formatDateTime(utc)}Z';
  }

  String _formatDateTime(DateTime dt) {
    return '${_four(dt.year)}${_two(dt.month)}${_two(dt.day)}'
        'T${_two(dt.hour)}${_two(dt.minute)}${_two(dt.second)}';
  }

  String _formatDate(DateTime dt) {
    return '${_four(dt.year)}${_two(dt.month)}${_two(dt.day)}';
  }

  DateTime? _parseDateTime(String value) {
    if (value.isEmpty) return null;
    final trimmed = value.endsWith('Z') ? value.substring(0, value.length - 1) : value;
    if (trimmed.length < 15) return null;
    final year = int.tryParse(trimmed.substring(0, 4));
    final month = int.tryParse(trimmed.substring(4, 6));
    final day = int.tryParse(trimmed.substring(6, 8));
    final hour = int.tryParse(trimmed.substring(9, 11));
    final minute = int.tryParse(trimmed.substring(11, 13));
    final second = int.tryParse(trimmed.substring(13, 15));
    if ([year, month, day, hour, minute, second].contains(null)) return null;
    return DateTime(year!, month!, day!, hour!, minute!, second!);
  }

  DateTime? _parseDate(String value) {
    if (value.length < 8) return null;
    final year = int.tryParse(value.substring(0, 4));
    final month = int.tryParse(value.substring(4, 6));
    final day = int.tryParse(value.substring(6, 8));
    if ([year, month, day].contains(null)) return null;
    return DateTime(year!, month!, day!);
  }

  List<String> _unfoldLines(String content) {
    final lines = content.replaceAll('\r\n', '\n').split('\n');
    final unfolded = <String>[];
    for (final line in lines) {
      if (line.startsWith(' ') || line.startsWith('\t')) {
        if (unfolded.isNotEmpty) {
          unfolded[unfolded.length - 1] += line.substring(1);
        }
      } else {
        unfolded.add(line.trim());
      }
    }
    return unfolded.where((line) => line.isNotEmpty).toList();
  }

  String _escapeText(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', '\\n')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;');
  }

  String _unescapeText(String value) {
    return value
        .replaceAll('\\n', '\n')
        .replaceAll('\\,', ',')
        .replaceAll('\\;', ';')
        .replaceAll('\\\\', '\\');
  }

  String _two(int value) => value.toString().padLeft(2, '0');
  String _four(int value) => value.toString().padLeft(4, '0');
}
