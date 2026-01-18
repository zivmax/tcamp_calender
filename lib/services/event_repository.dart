import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/calendar_event.dart';
import '../models/rrule.dart';
import 'notification_service.dart';

/// Repository for managing calendar events with persistent storage.
///
/// Uses Hive for local storage and handles event CRUD operations,
/// recurrence rule expansion, and notification scheduling.
class EventRepository extends ChangeNotifier {
  /// Creates a new event repository.
  ///
  /// Requires a [notificationService] for scheduling reminders.
  EventRepository({required NotificationService notificationService})
      : _notificationService = notificationService;

  /// Name of the Hive box used for storing events.
  static const String boxName = 'calendar_events';

  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  Box<CalendarEvent>? _box;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns all events sorted by start time.
  List<CalendarEvent> get events {
    final box = _box;
    if (box == null) return const [];

    return box.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Returns the event with the given [id], or null if not found.
  CalendarEvent? getById(String id) => _box?.get(id);

  /// Initializes the repository by opening the Hive box.
  ///
  /// Must be called before any other operations.
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CalendarEventAdapter());
    }

    _box = await Hive.openBox<CalendarEvent>(boxName);
    await _scheduleExistingReminders();
    notifyListeners();
  }

  /// Creates an empty event template for the given [initialDate].
  CalendarEvent createEmpty(DateTime initialDate) {
    return CalendarEvent.empty(_uuid.v4(), initialDate);
  }

  /// Adds a new event to the repository.
  Future<void> addEvent(CalendarEvent event) async {
    await _box?.put(event.id, event);
    await _notificationService.scheduleEventReminder(event);
    notifyListeners();
  }

  /// Updates an existing event.
  Future<void> updateEvent(CalendarEvent event) async {
    await _box?.put(event.id, event);
    await _notificationService.cancelEventReminder(event.id);
    await _notificationService.scheduleEventReminder(event);
    notifyListeners();
  }

  /// Reschedules all event reminders, used after timezone changes.
  Future<void> rescheduleAllReminders() async {
    final box = _box;
    if (box == null) return;

    for (final event in box.values) {
      await _notificationService.cancelEventReminder(event.id);
      await _notificationService.scheduleEventReminder(event);
    }
  }

  /// Deletes an event from the repository.
  Future<void> deleteEvent(CalendarEvent event) async {
    await _box?.delete(event.id);
    await _notificationService.cancelEventReminder(event.id);
    notifyListeners();
  }

  /// Returns all events (including recurrence expansions) for a specific day.
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

  /// Returns all events for a date range.
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

  /// Imports multiple events, typically from an ICS file.
  Future<void> importEvents(List<CalendarEvent> imported) async {
    final box = _box;
    if (box == null) return;

    for (final event in imported) {
      await box.put(event.id, event);
      await _notificationService.scheduleEventReminder(event);
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Recurrence Handling
  // ---------------------------------------------------------------------------

  CalendarEvent? _occurrenceForDay(CalendarEvent event, DateTime day) {
    final startDate = event.startDate;
    final endDate = event.endDate;

    // For all-day events that span multiple days, the end date is exclusive
    final effectiveEndDate = event.isAllDay && endDate.isAfter(startDate)
        ? endDate.subtract(const Duration(days: 1))
        : endDate;

    // Non-recurring event
    if (!event.isRecurring) {
      return _isDateInRange(day, startDate, effectiveEndDate) ? event : null;
    }

    // Parse and apply recurrence rule
    final rule = RRule.parse(event.rrule!);
    if (rule == null) {
      return _isDateInRange(day, startDate, effectiveEndDate) ? event : null;
    }

    if (!_matchesRecurrenceRule(event, day, rule)) return null;

    // Create occurrence instance
    return _createOccurrenceInstance(event, day);
  }

  List<CalendarEvent> _occurrencesForRange(
    CalendarEvent event,
    DateTime start,
    DateTime end,
  ) {
    // Non-recurring event
    if (!event.isRecurring) {
      final eventStart = event.startDate;
      final eventEnd = event.endDate;
      if (!eventEnd.isBefore(start) && !eventStart.isAfter(end)) {
        return [event];
      }
      return const [];
    }

    // Expand recurring event
    final results = <CalendarEvent>[];
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

  bool _matchesRecurrenceRule(CalendarEvent event, DateTime day, RRule rule) {
    final startDate = event.startDate;

    // Day must be on or after event start
    if (day.isBefore(startDate)) return false;

    // Check UNTIL constraint
    if (rule.until != null) {
      final untilDay = DateTime(rule.until!.year, rule.until!.month, rule.until!.day);
      if (day.isAfter(untilDay)) return false;
    }

    return switch (rule.frequency) {
      RecurrenceFrequency.daily => _matchesDailyRule(startDate, day, rule),
      RecurrenceFrequency.weekly => _matchesWeeklyRule(event, day, rule),
      RecurrenceFrequency.monthly => _matchesMonthlyRule(startDate, day, rule),
      RecurrenceFrequency.yearly => _matchesYearlyRule(startDate, day, rule),
    };
  }

  bool _matchesDailyRule(DateTime startDate, DateTime day, RRule rule) {
    final diff = day.difference(startDate).inDays;
    if (diff < 0 || diff % rule.interval != 0) return false;

    if (rule.count != null) {
      final occurrenceIndex = diff ~/ rule.interval + 1;
      if (occurrenceIndex > rule.count!) return false;
    }

    return true;
  }

  bool _matchesWeeklyRule(CalendarEvent event, DateTime day, RRule rule) {
    final startDate = event.startDate;
    final diffDays = day.difference(startDate).inDays;
    if (diffDays < 0) return false;

    final weekIndex = diffDays ~/ 7;
    if (weekIndex % rule.interval != 0) return false;

    final allowedWeekdays = rule.byDay ?? {event.start.weekday};
    if (!allowedWeekdays.contains(day.weekday)) return false;

    if (rule.count != null) {
      final count = _countWeeklyOccurrences(event, day, rule);
      if (count > rule.count!) return false;
    }

    return true;
  }

  bool _matchesMonthlyRule(DateTime startDate, DateTime day, RRule rule) {
    final monthsDiff =
        (day.year - startDate.year) * 12 + (day.month - startDate.month);
    if (monthsDiff < 0 || monthsDiff % rule.interval != 0) return false;
    if (day.day != startDate.day) return false;

    if (rule.count != null) {
      final occurrenceIndex = monthsDiff ~/ rule.interval + 1;
      if (occurrenceIndex > rule.count!) return false;
    }

    return true;
  }

  bool _matchesYearlyRule(DateTime startDate, DateTime day, RRule rule) {
    final yearsDiff = day.year - startDate.year;
    if (yearsDiff < 0 || yearsDiff % rule.interval != 0) return false;
    if (day.month != startDate.month || day.day != startDate.day) return false;

    if (rule.count != null) {
      final occurrenceIndex = yearsDiff ~/ rule.interval + 1;
      if (occurrenceIndex > rule.count!) return false;
    }

    return true;
  }

  int _countWeeklyOccurrences(CalendarEvent event, DateTime day, RRule rule) {
    final startDate = event.startDate;
    final allowedWeekdays = rule.byDay ?? {event.start.weekday};
    var count = 0;
    var cursor = startDate;

    while (!cursor.isAfter(day)) {
      final diffDays = cursor.difference(startDate).inDays;
      final weekIndex = diffDays ~/ 7;
      if (weekIndex % rule.interval == 0 &&
          allowedWeekdays.contains(cursor.weekday)) {
        count++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return count;
  }

  CalendarEvent _createOccurrenceInstance(CalendarEvent event, DateTime day) {
    final duration = event.duration;
    final occurrenceStart = DateTime(
      day.year,
      day.month,
      day.day,
      event.start.hour,
      event.start.minute,
      event.start.second,
    );

    return event.copyWith(
      start: occurrenceStart,
      end: occurrenceStart.add(duration),
    );
  }

  bool _isDateInRange(DateTime day, DateTime start, DateTime end) {
    return !day.isBefore(start) && !day.isAfter(end);
  }

  // ---------------------------------------------------------------------------
  // Initialization Helpers
  // ---------------------------------------------------------------------------

  Future<void> _scheduleExistingReminders() async {
    final box = _box;
    if (box == null) return;

    for (final event in box.values) {
      await _notificationService.scheduleEventReminder(event);
    }
  }
}
