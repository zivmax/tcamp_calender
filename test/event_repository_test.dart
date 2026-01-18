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
    final baseEvent = repository.createEmpty(DateTime(2026, 1, 17, 9, 0));
    final event = baseEvent.copyWith(
      title: 'Meeting',
      description: 'Discuss roadmap',
      location: 'Room A',
    );

    await repository.addEvent(event);
    expect(repository.events.length, 1);
    expect(notificationService.scheduled, 1);

    final updatedEvent = event.copyWith(title: 'Updated Meeting');
    await repository.updateEvent(updatedEvent);
    expect(repository.events.first.title, 'Updated Meeting');
    expect(notificationService.canceled, 1);
    expect(notificationService.scheduled, 2);

    await repository.deleteEvent(updatedEvent);
    expect(repository.events.isEmpty, true);
    expect(notificationService.canceled, 2);
  });

  test('recurring weekly event expansion', () async {
    final baseEvent = repository.createEmpty(DateTime(2026, 1, 12, 9, 0)); // Monday
    final event = baseEvent.copyWith(
      title: 'Gym',
      rrule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE',
    );

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

  test('rescheduleAllReminders cancels and schedules each event', () async {
    final event = repository.createEmpty(DateTime(2026, 3, 1, 9, 0));
    await repository.addEvent(event);

    notificationService.scheduled = 0;
    notificationService.canceled = 0;

    await repository.rescheduleAllReminders();

    expect(notificationService.canceled, 1);
    expect(notificationService.scheduled, 1);
  });

  test('all-day events do not appear on next day', () async {
    final baseEvent = repository.createEmpty(DateTime(2026, 1, 17, 0, 0));
    final event = baseEvent.copyWith(
      title: 'All Day',
      isAllDay: true,
      start: DateTime(2026, 1, 17),
      end: DateTime(2026, 1, 18),
    );

    await repository.addEvent(event);

    expect(repository.eventsForDay(DateTime(2026, 1, 17)).length, 1);
    expect(repository.eventsForDay(DateTime(2026, 1, 18)).isEmpty, true);
  });

  test('eventsForRange returns events within range', () async {
    final event = repository.createEmpty(DateTime(2026, 4, 10, 9, 0)).copyWith(
      title: 'Range Event',
    );
    await repository.addEvent(event);

    final results = repository.eventsForRange(
      DateTime(2026, 4, 9),
      DateTime(2026, 4, 11),
    );

    expect(results.length, 1);
    expect(results.first.title, 'Range Event');
  });

  test('monthly and yearly recurrence rules', () async {
    final monthly = repository.createEmpty(DateTime(2026, 1, 15, 9, 0)).copyWith(
      title: 'Monthly',
      rrule: 'FREQ=MONTHLY;INTERVAL=1;COUNT=2',
    );
    final yearly = repository.createEmpty(DateTime(2026, 2, 20, 9, 0)).copyWith(
      title: 'Yearly',
      rrule: 'FREQ=YEARLY;INTERVAL=1;COUNT=1',
    );

    await repository.addEvent(monthly);
    await repository.addEvent(yearly);

    expect(repository.eventsForDay(DateTime(2026, 2, 15)).length, 1);
    expect(repository.eventsForDay(DateTime(2026, 3, 15)).isEmpty, true);

    expect(repository.eventsForDay(DateTime(2027, 2, 20)).isEmpty, true);
  });

  test('daily and weekly recurrence rules respect interval and count', () async {
    final daily = repository.createEmpty(DateTime(2026, 5, 1, 9, 0)).copyWith(
      title: 'Daily',
      rrule: 'FREQ=DAILY;INTERVAL=2;COUNT=2',
    );
    final weekly = repository.createEmpty(DateTime(2026, 5, 4, 9, 0)).copyWith(
      title: 'Weekly',
      rrule: 'FREQ=WEEKLY;INTERVAL=1;COUNT=1;BYDAY=MO,WE',
    );

    await repository.addEvent(daily);
    await repository.addEvent(weekly);

    expect(repository.eventsForDay(DateTime(2026, 5, 1)).length, 1);
    expect(repository.eventsForDay(DateTime(2026, 5, 2)).isEmpty, true);
    expect(repository.eventsForDay(DateTime(2026, 5, 3)).length, 1);
    expect(repository.eventsForDay(DateTime(2026, 5, 5)).isEmpty, true);

    expect(repository.eventsForDay(DateTime(2026, 5, 4)).length, 1);
    expect(repository.eventsForDay(DateTime(2026, 5, 6)).isEmpty, true);
  });

  test('eventsForRange expands recurring events', () async {
    final recurring = repository.createEmpty(DateTime(2026, 6, 1, 9, 0)).copyWith(
      title: 'Recurring',
      rrule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE',
    );

    await repository.addEvent(recurring);

    final results = repository.eventsForRange(
      DateTime(2026, 6, 1),
      DateTime(2026, 6, 7),
    );

    expect(results.length, 2);
  });
}
