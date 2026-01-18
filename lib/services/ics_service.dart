import 'package:uuid/uuid.dart';

import '../models/calendar_event.dart';

/// Service for importing and exporting calendar events in ICS format.
///
/// Supports the iCalendar (RFC 5545) format for interoperability
/// with other calendar applications.
class IcsService {
  const IcsService();

  static const _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Exports a list of events to ICS format.
  String exportToIcs(List<CalendarEvent> events) {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//TCamp Calendar//EN')
      ..writeln('CALSCALE:GREGORIAN');

    for (final event in events) {
      _writeEvent(buffer, event);
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  void _writeEvent(StringBuffer buffer, CalendarEvent event) {
    buffer
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${event.id}')
      ..writeln('DTSTAMP:${_formatUtc(DateTime.now())}');

    if (event.isAllDay) {
      buffer
        ..writeln('DTSTART;VALUE=DATE:${_formatDate(event.start)}')
        ..writeln('DTEND;VALUE=DATE:${_formatDate(event.end)}');
    } else {
      buffer
        ..writeln('DTSTART:${_formatUtc(event.start)}')
        ..writeln('DTEND:${_formatUtc(event.end)}');
    }

    buffer.writeln('SUMMARY:${_escapeText(event.title)}');

    if (event.description.isNotEmpty) {
      buffer.writeln('DESCRIPTION:${_escapeText(event.description)}');
    }

    if (event.location.isNotEmpty) {
      buffer.writeln('LOCATION:${_escapeText(event.location)}');
    }

    if (event.isRecurring) {
      buffer.writeln('RRULE:${event.rrule}');
    }

    buffer.writeln('END:VEVENT');
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  /// Imports events from ICS format.
  List<CalendarEvent> importFromIcs(String content) {
    final unfolded = _unfoldLines(content);
    final events = <CalendarEvent>[];

    Map<String, String> current = {};
    var inEvent = false;

    for (final line in unfolded) {
      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        current = {};
        continue;
      }

      if (line == 'END:VEVENT') {
        final event = _parseEvent(current);
        if (event != null) {
          events.add(event);
        }
        inEvent = false;
        current = {};
        continue;
      }

      if (!inEvent) continue;

      final colonIndex = line.indexOf(':');
      if (colonIndex == -1) continue;

      final key = line.substring(0, colonIndex);
      final value = line.substring(colonIndex + 1);
      current[key] = value;
    }

    return events;
  }

  CalendarEvent? _parseEvent(Map<String, String> data) {
    final uid = data['UID'] ?? _uuid.v4();
    final summary = _unescapeText(data['SUMMARY'] ?? '');
    final description = _unescapeText(data['DESCRIPTION'] ?? '');
    final location = _unescapeText(data['LOCATION'] ?? '');
    final rrule = data['RRULE'];

    // Find start and end time keys (may have parameters)
    final startKey = data.keys.firstWhere(
      (key) => key.startsWith('DTSTART'),
      orElse: () => '',
    );
    final endKey = data.keys.firstWhere(
      (key) => key.startsWith('DTEND'),
      orElse: () => '',
    );

    if (startKey.isEmpty || endKey.isEmpty) return null;

    final isAllDay = startKey.contains('VALUE=DATE');
    final start = isAllDay
        ? _parseDate(data[startKey] ?? '')
        : _parseDateTime(data[startKey] ?? '');
    final end = isAllDay
        ? _parseDate(data[endKey] ?? '')
        : _parseDateTime(data[endKey] ?? '');

    if (start == null || end == null) return null;

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

  // ---------------------------------------------------------------------------
  // Formatting Helpers
  // ---------------------------------------------------------------------------

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

  String _two(int value) => value.toString().padLeft(2, '0');
  String _four(int value) => value.toString().padLeft(4, '0');

  // ---------------------------------------------------------------------------
  // Parsing Helpers
  // ---------------------------------------------------------------------------

  DateTime? _parseDateTime(String value) {
    if (value.isEmpty) return null;

    final trimmed = value.endsWith('Z')
        ? value.substring(0, value.length - 1)
        : value;

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

  /// Unfolds ICS lines (continuation lines start with space or tab).
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

  // ---------------------------------------------------------------------------
  // Text Escaping
  // ---------------------------------------------------------------------------

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
}

