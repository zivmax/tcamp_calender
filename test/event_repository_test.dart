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
    tempDir = await Directory.systemTemp.createTemp('calendar_repo_test');
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

  test('add/update/delete event', () async {
    final event = repository.createEmpty(DateTime(2026, 1, 17, 9, 0));
    event
      ..title = 'Meeting'
      ..description = 'Discuss roadmap'
      ..location = 'Room A';

    await repository.addEvent(event);
    expect(repository.events.length, 1);
    expect(notificationService.scheduled, 1);

    event.title = 'Updated Meeting';
    await repository.updateEvent(event);
    expect(repository.events.first.title, 'Updated Meeting');
    expect(notificationService.canceled, 1);
    expect(notificationService.scheduled, 2);

    await repository.deleteEvent(event);
    expect(repository.events.isEmpty, true);
    expect(notificationService.canceled, 2);
  });

  test('recurring weekly event expansion', () async {
    final event = repository.createEmpty(DateTime(2026, 1, 12, 9, 0)); // Monday
    event
      ..title = 'Gym'
      ..rrule = 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE';

    await repository.addEvent(event);

    final monday = repository.eventsForDay(DateTime(2026, 1, 12));
    final wednesday = repository.eventsForDay(DateTime(2026, 1, 14));
    final thursday = repository.eventsForDay(DateTime(2026, 1, 15));

    expect(monday.length, 1);
    expect(wednesday.length, 1);
    expect(thursday.isEmpty, true);
  });

  test('import events schedules reminders', () async {
    final event = repository.createEmpty(DateTime(2026, 2, 1, 10, 0));
    await repository.importEvents([event]);

    expect(repository.events.length, 1);
    expect(notificationService.scheduled, 1);
  });

  test('all-day events do not appear on next day', () async {
    final event = repository.createEmpty(DateTime(2026, 1, 17, 0, 0));
    event
      ..title = 'All Day'
      ..isAllDay = true
      ..start = DateTime(2026, 1, 17)
      ..end = DateTime(2026, 1, 18);

    await repository.addEvent(event);

    expect(repository.eventsForDay(DateTime(2026, 1, 17)).length, 1);
    expect(repository.eventsForDay(DateTime(2026, 1, 18)).isEmpty, true);
  });
}
