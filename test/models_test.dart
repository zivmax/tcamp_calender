import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';

import 'package:tcamp_calendar/models/calendar_event.dart';
import 'package:tcamp_calendar/models/rrule.dart';

void main() {
  test('CalendarEvent getters and json', () {
    final start = DateTime(2026, 1, 18, 9, 0);
    final end = DateTime(2026, 1, 18, 10, 30);
    final event = CalendarEvent(
      id: 'id-1',
      title: 'Meeting',
      description: 'Discuss',
      location: 'Room A',
      start: start,
      end: end,
      isAllDay: false,
      reminderMinutes: 15,
      rrule: 'FREQ=DAILY;INTERVAL=1',
    );

    expect(event.startDate, DateTime(2026, 1, 18));
    expect(event.endDate, DateTime(2026, 1, 18));
    expect(event.duration, const Duration(hours: 1, minutes: 30));
    expect(event.hasReminder, isTrue);
    expect(event.isRecurring, isTrue);

    final json = event.toJson();
    final restored = CalendarEvent.fromJson(json);

    expect(restored, event);
  });

  test('CalendarEvent.fromJson applies defaults for missing fields', () {
    final json = {
      'id': 'id-6',
      'title': null,
      'start': DateTime(2026, 1, 18, 9, 0).toIso8601String(),
      'end': DateTime(2026, 1, 18, 10, 0).toIso8601String(),
    };

    final restored = CalendarEvent.fromJson(json);

    expect(restored.title, '');
    expect(restored.description, '');
    expect(restored.location, '');
    expect(restored.isAllDay, isFalse);
    expect(restored.reminderMinutes, isNull);
    expect(restored.rrule, isNull);
  });

  test('CalendarEvent copyWith and equality', () {
    final event = CalendarEvent(
      id: 'id-2',
      title: 'Title',
      description: 'Desc',
      location: 'Loc',
      start: DateTime(2026, 1, 18, 9, 0),
      end: DateTime(2026, 1, 18, 10, 0),
      isAllDay: false,
      reminderMinutes: null,
      rrule: null,
    );

    final updated = event.copyWith(title: 'Updated', reminderMinutes: 5);
    expect(updated.title, 'Updated');
    expect(updated.reminderMinutes, 5);
    expect(updated == event, isFalse);
    expect(updated.hashCode == event.hashCode, isFalse);
  });

  test('CalendarEvent flags and toString', () {
    final event = CalendarEvent(
      id: 'id-4',
      title: '',
      description: '',
      location: '',
      start: DateTime(2026, 1, 18, 9, 0),
      end: DateTime(2026, 1, 18, 9, 30),
      isAllDay: false,
      reminderMinutes: null,
      rrule: '',
    );

    expect(event.hasReminder, isFalse);
    expect(event.isRecurring, isFalse);
    expect(event.toString(), contains('CalendarEvent'));
    expect(event, isNot(equals(42)));
  });

  test('CalendarEvent.empty creates defaults', () {
    final empty = CalendarEvent.empty('id-5', DateTime(2026, 1, 18, 14, 0));
    expect(empty.id, 'id-5');
    expect(empty.title, isEmpty);
    expect(empty.reminderMinutes, 10);
    expect(empty.end.isAfter(empty.start), isTrue);
  });

  test('CalendarEvent adapter round-trip', () async {
    final event = CalendarEvent(
      id: 'id-3',
      title: 'Adapter',
      description: 'Test',
      location: 'Room',
      start: DateTime(2026, 1, 18, 9, 0),
      end: DateTime(2026, 1, 18, 11, 0),
      isAllDay: false,
      reminderMinutes: 30,
      rrule: 'FREQ=WEEKLY;BYDAY=MO,FR',
    );

    final tempDir = await Directory.systemTemp.createTemp('calendar_event_adapter');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CalendarEventAdapter());
    }

    final box = await Hive.openBox<CalendarEvent>('event_adapter_test');
    await box.put('key', event);
    final decoded = box.get('key');

    expect(decoded, event);

    await box.close();
    await tempDir.delete(recursive: true);
  });

  test('CalendarEvent adapter read/write with binary reader/writer', () {
    final event = CalendarEvent(
      id: 'id-7',
      title: 'Binary',
      description: 'Direct',
      location: 'Desk',
      start: DateTime(2026, 1, 19, 10, 0),
      end: DateTime(2026, 1, 19, 11, 0),
      isAllDay: false,
      reminderMinutes: 20,
      rrule: 'FREQ=DAILY;COUNT=2',
    );

    final typeRegistry = TypeRegistryImpl();
    typeRegistry.registerAdapter<DateTime>(DateTimeAdapter());

    final adapter = CalendarEventAdapter();
    final writer = BinaryWriterImpl(typeRegistry);
    adapter.write(writer, event);

    final reader = BinaryReaderImpl(writer.toBytes(), typeRegistry);
    final decoded = adapter.read(reader);

    expect(decoded, event);
  });

  test('RRule parsing and formatting', () {
    final rule = RRule.parse('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR');

    expect(rule, isNotNull);
    expect(rule!.frequency, RecurrenceFrequency.weekly);
    expect(rule.interval, 2);
    expect(rule.byDay, containsAll(<int>{DateTime.monday, DateTime.friday}));

    final simple = RRule.simple(RecurrenceFrequency.monthly, interval: 3);
    expect(simple, 'FREQ=MONTHLY;INTERVAL=3');
  });

  test('RRule count, equality, hashCode, and toString', () {
    final rule1 = RRule.parse('FREQ=DAILY;INTERVAL=2;COUNT=5');
    final rule2 = RRule.parse('FREQ=DAILY;INTERVAL=2;COUNT=5');

    expect(rule1, rule2);
    expect(rule1.hashCode, rule2.hashCode);
    expect(rule1.toString(), contains('RRule'));
  });

  test('RRule BYDAY parsing supports numeric prefixes', () {
    final rule = RRule.parse('FREQ=WEEKLY;BYDAY=1MO,-1FR');
    expect(rule, isNotNull);
    expect(rule!.byDay, containsAll(<int>{DateTime.monday, DateTime.friday}));
  });

  test('RRule UNTIL parsing supports dates and datetimes', () {
    final ruleDate = RRule.parse('FREQ=DAILY;UNTIL=20260131');
    final ruleDateTime = RRule.parse('FREQ=DAILY;UNTIL=20260131T120000Z');

    expect(ruleDate!.until, DateTime(2026, 1, 31));
    expect(ruleDateTime!.until, DateTime(2026, 1, 31, 12, 0, 0));
  });

  test('RRule invalid inputs return null', () {
    expect(RRule.parse(''), isNull);
    expect(RRule.parse('FREQ=INVALID'), isNull);
    expect(RRule.parse('INTERVAL=2'), isNull);
    expect(RRule.parse('FREQ=DAILY;UNTIL=BAD'), isNotNull);
    expect(RRule.parse('FREQ=DAILY;UNTIL=BAD')!.until, isNull);
    expect(RRule.parse('FREQ=WEEKLY;BYDAY=??')!.byDay, isNull);
  });
}
