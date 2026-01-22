import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:tcamp_calender/l10n/app_localizations.dart';
import 'package:tcamp_calender/models/calendar_event.dart';
import 'package:tcamp_calender/services/event_repository.dart';
import 'package:tcamp_calender/services/lunar_service.dart';
import 'package:tcamp_calender/services/notification_service.dart';
import 'package:tcamp_calender/services/settings_service.dart';
import 'package:tcamp_calender/services/subscription_service.dart';

class TestNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleEventReminder(CalendarEvent event) async {}

  @override
  Future<void> cancelEventReminder(String eventId) async {}
}

class TestEventRepository extends EventRepository {
  TestEventRepository({
    required super.notificationService,
    List<CalendarEvent>? seed,
  }) : _events = List<CalendarEvent>.from(seed ?? const []);

  final List<CalendarEvent> _events;

  int addedCount = 0;
  int updatedCount = 0;
  int deletedCount = 0;

  @override
  List<CalendarEvent> get events => List<CalendarEvent>.from(_events);

  @override
  CalendarEvent? getById(String id) {
    for (final event in _events) {
      if (event.id == id) return event;
    }
    return null;
  }

  @override
  CalendarEvent createEmpty(DateTime initialDate) {
    return CalendarEvent.empty('test-${_events.length + 1}', initialDate);
  }

  @override
  Future<void> addEvent(CalendarEvent event) async {
    _events.add(event);
    addedCount += 1;
    notifyListeners();
  }

  @override
  Future<void> updateEvent(CalendarEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
    }
    updatedCount += 1;
    notifyListeners();
  }

  @override
  Future<void> deleteEvent(CalendarEvent event) async {
    _events.removeWhere((e) => e.id == event.id);
    deletedCount += 1;
    notifyListeners();
  }

  @override
  Future<void> importEvents(List<CalendarEvent> imported) async {
    _events.addAll(imported);
    notifyListeners();
  }

  @override
  Future<void> clearAll() async {
    _events.clear();
    notifyListeners();
  }

  @override
  List<CalendarEvent> eventsForDay(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    return _events.where((event) {
      final startDate = event.startDate;
      final endDate = event.endDate;
      final effectiveEnd = event.isAllDay && endDate.isAfter(startDate)
          ? endDate.subtract(const Duration(days: 1))
          : endDate;
      return !dayOnly.isBefore(startDate) && !dayOnly.isAfter(effectiveEnd);
    }).toList();
  }

  @override
  List<CalendarEvent> eventsForRange(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return _events.where((event) {
      final eventStart = event.startDate;
      final eventEnd = event.endDate;
      return !eventEnd.isBefore(startDay) && !eventStart.isAfter(endDay);
    }).toList();
  }
}

class TestSubscriptionService extends SubscriptionService {
  TestSubscriptionService({required super.icsService})
      : super(
          client: MockClient((_) async => http.Response('', 200)),
        );

  List<String> stored = [];

  @override
  Future<List<String>> loadSubscriptions() async => List<String>.from(stored);

  @override
  Future<void> saveSubscriptions(List<String> urls) async {
    stored = List<String>.from(urls);
  }

  @override
  Future<List<CalendarEvent>> fetchFromSubscriptions(List<String> urls) async {
    return <CalendarEvent>[];
  }

  @override
  Future<void> clear() async {
    stored = <String>[];
  }
}

Widget buildTestApp({
  required Widget child,
  required EventRepository repo,
  SettingsService? settingsService,
  LunarService? lunarService,
  bool wrapInScaffold = true,
  Locale? locale,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<EventRepository>.value(value: repo),
      Provider<LunarService>.value(value: lunarService ?? const LunarService()),
      if (settingsService != null)
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
    ],
    child: MaterialApp(
      locale: locale ?? const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: wrapInScaffold ? Scaffold(body: child) : child,
    ),
  );
}
