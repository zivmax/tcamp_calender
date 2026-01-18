import 'package:flutter/foundation.dart';

/// Supported recurrence frequencies as per RFC 5545.
enum RecurrenceFrequency {
  /// Daily recurrence.
  daily,

  /// Weekly recurrence.
  weekly,

  /// Monthly recurrence.
  monthly,

  /// Yearly recurrence.
  yearly,
}

/// Parses and represents an iCalendar RRULE (recurrence rule).
///
/// Supports a subset of RFC 5545 RRULE properties:
/// - FREQ (DAILY, WEEKLY, MONTHLY, YEARLY)
/// - INTERVAL
/// - COUNT
/// - UNTIL
/// - BYDAY (for weekly recurrence)
///
/// Example RRULE strings:
/// - `FREQ=DAILY;INTERVAL=1`
/// - `FREQ=WEEKLY;BYDAY=MO,WE,FR`
/// - `FREQ=MONTHLY;COUNT=12`
@immutable
class RRule {
  const RRule._({
    required this.frequency,
    this.interval = 1,
    this.count,
    this.until,
    this.byDay,
  });

  /// The recurrence frequency.
  final RecurrenceFrequency frequency;

  /// The interval between recurrences (default: 1).
  final int interval;

  /// Maximum number of occurrences, or null for unlimited.
  final int? count;

  /// End date for recurrence, or null for no end date.
  final DateTime? until;

  /// Set of weekdays for WEEKLY frequency (using [DateTime.monday] etc.).
  final Set<int>? byDay;

  /// Parses an RRULE string into an [RRule] object.
  ///
  /// Returns null if the RRULE is invalid or unsupported.
  ///
  /// Example:
  /// ```dart
  /// final rule = RRule.parse('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR');
  /// ```
  static RRule? parse(String raw) {
    if (raw.isEmpty) return null;

    final parts = raw.split(';');
    final map = <String, String>{};

    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length == 2) {
        map[kv[0].toUpperCase()] = kv[1].toUpperCase();
      }
    }

    final freqRaw = map['FREQ'];
    if (freqRaw == null) return null;

    final frequency = _parseFrequency(freqRaw);
    if (frequency == null) return null;

    return RRule._(
      frequency: frequency,
      interval: int.tryParse(map['INTERVAL'] ?? '1') ?? 1,
      count: int.tryParse(map['COUNT'] ?? ''),
      until: _parseUntil(map['UNTIL']),
      byDay: _parseByDay(map['BYDAY']),
    );
  }

  /// Creates a simple RRULE string from a frequency.
  static String simple(RecurrenceFrequency frequency, {int interval = 1}) {
    final freqStr = frequency.name.toUpperCase();
    return 'FREQ=$freqStr;INTERVAL=$interval';
  }

  static RecurrenceFrequency? _parseFrequency(String raw) {
    return switch (raw) {
      'DAILY' => RecurrenceFrequency.daily,
      'WEEKLY' => RecurrenceFrequency.weekly,
      'MONTHLY' => RecurrenceFrequency.monthly,
      'YEARLY' => RecurrenceFrequency.yearly,
      _ => null,
    };
  }

  static DateTime? _parseUntil(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final value = raw.endsWith('Z') ? raw.substring(0, raw.length - 1) : raw;

    // Full datetime format: YYYYMMDDTHHmmss
    if (value.length >= 15) {
      final year = int.tryParse(value.substring(0, 4));
      final month = int.tryParse(value.substring(4, 6));
      final day = int.tryParse(value.substring(6, 8));
      final hour = int.tryParse(value.substring(9, 11));
      final minute = int.tryParse(value.substring(11, 13));
      final second = int.tryParse(value.substring(13, 15));

      if ([year, month, day, hour, minute, second].contains(null)) return null;
      return DateTime(year!, month!, day!, hour!, minute!, second!);
    }

    // Date-only format: YYYYMMDD
    if (value.length >= 8) {
      final year = int.tryParse(value.substring(0, 4));
      final month = int.tryParse(value.substring(4, 6));
      final day = int.tryParse(value.substring(6, 8));

      if ([year, month, day].contains(null)) return null;
      return DateTime(year!, month!, day!);
    }

    return null;
  }

  static const _weekdayMap = {
    'MO': DateTime.monday,
    'TU': DateTime.tuesday,
    'WE': DateTime.wednesday,
    'TH': DateTime.thursday,
    'FR': DateTime.friday,
    'SA': DateTime.saturday,
    'SU': DateTime.sunday,
  };

  static Set<int>? _parseByDay(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final values = raw.split(',');
    final result = <int>{};

    for (final value in values) {
      // Remove any numeric prefix (e.g., '1MO' -> 'MO')
      final key = value.replaceAll(RegExp('[^A-Z]'), '');
      final weekday = _weekdayMap[key];
      if (weekday != null) {
        result.add(weekday);
      }
    }

    return result.isEmpty ? null : result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RRule &&
          runtimeType == other.runtimeType &&
          frequency == other.frequency &&
          interval == other.interval &&
          count == other.count &&
          until == other.until &&
          setEquals(byDay, other.byDay);

  @override
  int get hashCode => Object.hash(frequency, interval, count, until, byDay);

  @override
  String toString() => 'RRule(frequency: $frequency, interval: $interval, '
      'count: $count, until: $until, byDay: $byDay)';
}
