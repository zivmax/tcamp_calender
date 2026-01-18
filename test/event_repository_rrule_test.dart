import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:tcamp_calender/models/calendar_event.dart';
import 'package:tcamp_calender/services/event_repository.dart';
import 'package:tcamp_calender/services/notification_service.dart';

class _FakeNotificationService extends NotificationService {
  int scheduled = 0;
  int canceled = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleEventReminder(CalendarEvent event) async {
    scheduled += 1;
  }

  @override
  Future<void> cancelEventReminder(String eventId) async {
    canceled += 1;
  }
}

void main() {
  late Directory tempDir;
  late EventRepository repository;
  late _FakeNotificationService notificationService;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('calendar_repo_rrule_test');
    Hive.init(tempDir.path);
    notificationService = _FakeNotificationService();
    repository = EventRepository(notificationService: notificationService);
    await repository.init();
  });

  setUp(() async {
    final box = Hive.box<CalendarEvent>(EventRepository.boxName);
    await box.clear();
    notificationService.scheduled = 0;
    notificationService.canceled = 0;
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('createEmpty sets defaults', () {
    final date = DateTime(2026, 1, 17, 9, 30);
    final event = repository.createEmpty(date);

    expect(event.title, '');
    expect(event.description, '');
    expect(event.location, '');
    expect(event.isAllDay, false);
    expect(event.reminderMinutes, 10);
    expect(event.end.difference(event.start), const Duration(hours: 1));
  });

  test('daily recurrence respects interval and count', () async {
    final event = repository.createEmpty(DateTime(2026, 1, 1, 9, 0));
    event
      ..title = 'Routine'
      ..rrule = 'FREQ=DAILY;INTERVAL=2;COUNT=3';

    await repository.addEvent(event);

    expect(repository.eventsForDay(DateTime(2026, 1, 1)).length, 1);
    expect(repository.eventsForDay(DateTime(2026, 1, 2)).isEmpty, true);
    expect(repository.eventsForDay(DateTime(2026, 1, 3)).length, 1);
    expect(repository.eventsForDay(DateTime(2026, 1, 5)).length, 1);
    expect(repository.eventsForDay(DateTime(2026, 1, 7)).isEmpty, true);

    final range = repository.eventsForRange(DateTime(2026, 1, 1), DateTime(2026, 1, 7));
    expect(range.length, 3);
  });

  test('daily recurrence respects until', () async {
    final event = repository.createEmpty(DateTime(2026, 1, 1, 10, 0));
    event.rrule = 'FREQ=DAILY;UNTIL=20260103T000000Z';

    await repository.addEvent(event);

    expect(repository.eventsForDay(DateTime(2026, 1, 1)).length, 1);
    expect(repository.eventsForDay(DateTime(2026, 1, 3)).length, 1);
    expect(repository.eventsForDay(DateTime(2026, 1, 4)).isEmpty, true);
  });

  test('monthly and yearly recurrence', () async {
    final monthly = repository.createEmpty(DateTime(2026, 1, 15, 9, 0));
    monthly
      ..title = 'Monthly'
      ..rrule = 'FREQ=MONTHLY;INTERVAL=1';

    final yearly = repository.createEmpty(DateTime(2026, 6, 2, 12, 0));
    yearly
      ..title = 'Yearly'
      ..rrule = 'FREQ=YEARLY;INTERVAL=1';

    await repository.importEvents([monthly, yearly]);

    expect(repository.eventsForDay(DateTime(2026, 2, 15)).length, 1);
    expect(repository.eventsForDay(DateTime(2027, 6, 2)).length, 1);
    expect(repository.eventsForDay(DateTime(2027, 6, 3)).isEmpty, true);
  });

  test('range includes multi-day non-rrule events', () async {
    final event = repository.createEmpty(DateTime(2026, 1, 10, 9, 0));
    event
      ..title = 'Conference'
      ..start = DateTime(2026, 1, 10, 9, 0)
      ..end = DateTime(2026, 1, 12, 18, 0)
      ..rrule = null;

    await repository.addEvent(event);

    final range = repository.eventsForRange(DateTime(2026, 1, 11), DateTime(2026, 1, 11));
    expect(range.length, 1);
  });
}
