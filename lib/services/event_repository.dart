import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/calendar_event.dart';
import 'notification_service.dart';

class EventRepository extends ChangeNotifier {
  EventRepository({required NotificationService notificationService})
      : _notificationService = notificationService;

  static const String boxName = 'calendar_events';

  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  Box<CalendarEvent>? _box;

  List<CalendarEvent> get events {
    final box = _box;
    if (box == null) {
      return [];
    }
    return box.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  CalendarEvent? getById(String id) {
    return _box?.get(id);
  }

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CalendarEventAdapter());
    }
    _box = await Hive.openBox<CalendarEvent>(boxName);
    await _scheduleExistingReminders();
    notifyListeners();
  }

  CalendarEvent createEmpty(DateTime initialDate) {
    final start = DateTime(initialDate.year, initialDate.month, initialDate.day,
        initialDate.hour, initialDate.minute);
    return CalendarEvent(
      id: _uuid.v4(),
      title: '',
      description: '',
      location: '',
      start: start,
      end: start.add(const Duration(hours: 1)),
      isAllDay: false,
      reminderMinutes: 10,
      rrule: null,
    );
  }

  Future<void> addEvent(CalendarEvent event) async {
    await _box?.put(event.id, event);
    await _notificationService.scheduleEventReminder(event);
    notifyListeners();
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _box?.put(event.id, event);
    await _notificationService.cancelEventReminder(event.id);
    await _notificationService.scheduleEventReminder(event);
    notifyListeners();
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    await _box?.delete(event.id);
    await _notificationService.cancelEventReminder(event.id);
    notifyListeners();
  }

  List<CalendarEvent> eventsForDay(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final results = <CalendarEvent>[];
    for (final event in events) {
      final occurrence = _occurrenceForDay(event, dayOnly);
      if (occurrence != null) {
        results.add(occurrence);
      }
    }
    return results;
  }

  List<CalendarEvent> eventsForRange(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final results = <CalendarEvent>[];
    for (final event in events) {
      results.addAll(_occurrencesForRange(event, startDay, endDay));
    }
    results.sort((a, b) => a.start.compareTo(b.start));
    return results;
  }

  Future<void> importEvents(List<CalendarEvent> imported) async {
    final box = _box;
    if (box == null) {
      return;
    }
    for (final event in imported) {
      await box.put(event.id, event);
      await _notificationService.scheduleEventReminder(event);
    }
    notifyListeners();
  }

  CalendarEvent? _occurrenceForDay(CalendarEvent event, DateTime day) {
    final startDate = DateTime(event.start.year, event.start.month, event.start.day);
    final endDate = DateTime(event.end.year, event.end.month, event.end.day);
    final effectiveEndDate = event.isAllDay && endDate.isAfter(startDate)
        ? endDate.subtract(const Duration(days: 1))
        : endDate;
    if (event.rrule == null || event.rrule!.isEmpty) {
      if (!day.isBefore(startDate) && !day.isAfter(effectiveEndDate)) {
        return event;
      }
      return null;
    }

    final rule = _RRule.parse(event.rrule!);
    if (rule == null) {
      if (!day.isBefore(startDate) && !day.isAfter(effectiveEndDate)) {
        return event;
      }
      return null;
    }

    if (day.isBefore(startDate)) return null;
    if (rule.until != null) {
      final untilDay = DateTime(rule.until!.year, rule.until!.month, rule.until!.day);
      if (day.isAfter(untilDay)) return null;
    }

    final matches = _matchesRule(event, day, rule);
    if (!matches) return null;

    final duration = event.end.difference(event.start);
    final occurrenceStart = DateTime(
      day.year,
      day.month,
      day.day,
      event.start.hour,
      event.start.minute,
      event.start.second,
    );
    final occurrenceEnd = occurrenceStart.add(duration);
    return event.copyWith(
      start: occurrenceStart,
      end: occurrenceEnd,
    );
  }

  List<CalendarEvent> _occurrencesForRange(
    CalendarEvent event,
    DateTime start,
    DateTime end,
  ) {
    final results = <CalendarEvent>[];
    if (event.rrule == null || event.rrule!.isEmpty) {
      final eventStart = DateTime(event.start.year, event.start.month, event.start.day);
      final eventEnd = DateTime(event.end.year, event.end.month, event.end.day);
      if (!eventEnd.isBefore(start) && !eventStart.isAfter(end)) {
        results.add(event);
      }
      return results;
    }

    var cursor = start;
    while (!cursor.isAfter(end)) {
      final occurrence = _occurrenceForDay(event, cursor);
      if (occurrence != null) {
        results.add(occurrence);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return results;
  }

  bool _matchesRule(CalendarEvent event, DateTime day, _RRule rule) {
    final startDate = DateTime(event.start.year, event.start.month, event.start.day);
    final interval = rule.interval ?? 1;

    switch (rule.freq) {
      case _Frequency.daily:
        final diff = day.difference(startDate).inDays;
        if (diff < 0 || diff % interval != 0) return false;
        final occurrenceIndex = diff ~/ interval + 1;
        if (rule.count != null && occurrenceIndex > rule.count!) return false;
        return true;
      case _Frequency.weekly:
        final diffDays = day.difference(startDate).inDays;
        if (diffDays < 0) return false;
        final weekIndex = diffDays ~/ 7;
        if (weekIndex % interval != 0) return false;
        final allowedWeekdays = rule.byDay ?? {event.start.weekday};
        if (!allowedWeekdays.contains(day.weekday)) return false;
        if (rule.count != null) {
          final count = _countOccurrencesWeekly(event, day, rule);
          if (count > rule.count!) return false;
        }
        return true;
      case _Frequency.monthly:
        final monthsDiff = (day.year - startDate.year) * 12 + (day.month - startDate.month);
        if (monthsDiff < 0 || monthsDiff % interval != 0) return false;
        if (day.day != startDate.day) return false;
        final occurrenceIndex = monthsDiff ~/ interval + 1;
        if (rule.count != null && occurrenceIndex > rule.count!) return false;
        return true;
      case _Frequency.yearly:
        final yearsDiff = day.year - startDate.year;
        if (yearsDiff < 0 || yearsDiff % interval != 0) return false;
        if (day.month != startDate.month || day.day != startDate.day) return false;
        final occurrenceIndex = yearsDiff ~/ interval + 1;
        if (rule.count != null && occurrenceIndex > rule.count!) return false;
        return true;
    }
  }

  int _countOccurrencesWeekly(CalendarEvent event, DateTime day, _RRule rule) {
    final startDate = DateTime(event.start.year, event.start.month, event.start.day);
    final allowedWeekdays = rule.byDay ?? {event.start.weekday};
    var count = 0;
    var cursor = startDate;
    while (!cursor.isAfter(day)) {
      final diffDays = cursor.difference(startDate).inDays;
      final weekIndex = diffDays ~/ 7;
      if (weekIndex % (rule.interval ?? 1) == 0 && allowedWeekdays.contains(cursor.weekday)) {
        count++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }

  Future<void> _scheduleExistingReminders() async {
    final box = _box;
    if (box == null) return;
    for (final event in box.values) {
      await _notificationService.scheduleEventReminder(event);
    }
  }
}

enum _Frequency { daily, weekly, monthly, yearly }

class _RRule {
  _RRule({required this.freq, this.interval, this.count, this.until, this.byDay});

  final _Frequency freq;
  final int? interval;
  final int? count;
  final DateTime? until;
  final Set<int>? byDay;

  static _RRule? parse(String raw) {
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

    _Frequency? freq;
    switch (freqRaw) {
      case 'DAILY':
        freq = _Frequency.daily;
        break;
      case 'WEEKLY':
        freq = _Frequency.weekly;
        break;
      case 'MONTHLY':
        freq = _Frequency.monthly;
        break;
      case 'YEARLY':
        freq = _Frequency.yearly;
        break;
      default:
        return null;
    }

    final interval = int.tryParse(map['INTERVAL'] ?? '1');
    final count = int.tryParse(map['COUNT'] ?? '');
    final until = _parseUntil(map['UNTIL']);
    final byDay = _parseByDay(map['BYDAY']);

    return _RRule(
      freq: freq,
      interval: interval,
      count: count,
      until: until,
      byDay: byDay,
    );
  }

  static DateTime? _parseUntil(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final value = raw.endsWith('Z') ? raw.substring(0, raw.length - 1) : raw;
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
    if (value.length >= 8) {
      final year = int.tryParse(value.substring(0, 4));
      final month = int.tryParse(value.substring(4, 6));
      final day = int.tryParse(value.substring(6, 8));
      if ([year, month, day].contains(null)) return null;
      return DateTime(year!, month!, day!);
    }
    return null;
  }

  static Set<int>? _parseByDay(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final map = {
      'MO': DateTime.monday,
      'TU': DateTime.tuesday,
      'WE': DateTime.wednesday,
      'TH': DateTime.thursday,
      'FR': DateTime.friday,
      'SA': DateTime.saturday,
      'SU': DateTime.sunday,
    };
    final values = raw.split(',');
    final set = <int>{};
    for (final value in values) {
      final key = value.replaceAll(RegExp(r'[^A-Z]'), '');
      if (map.containsKey(key)) {
        set.add(map[key]!);
      }
    }
    return set.isEmpty ? null : set;
  }
}
