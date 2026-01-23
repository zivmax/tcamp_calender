@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:tcamp_calendar/models/calendar_event.dart';
import 'package:tcamp_calendar/services/web_notification_web.dart';

CalendarEvent _event(
  String id, {
  String title = 'Test Event',
  String description = '',
  String location = 'Room A',
}) {
  final start = DateTime.now().add(const Duration(hours: 1));
  return CalendarEvent(
    id: id,
    title: title,
    description: description,
    location: location,
    start: start,
    end: start.add(const Duration(hours: 1)),
    reminderMinutes: 10,
  );
}

void main() {
  test('schedule sends notification with location fallback', () async {
    final sent = <String>[];
    final adapter = WebNotificationAdapter(
      canNotifyOverride: () => true,
      sender: (title, body, tag) {
        sent.add('$title|$body|$tag');
      },
    );

    final event = _event('event-1', description: '', location: 'Lab 1');
    adapter.schedule(
      event,
      DateTime.now().add(const Duration(milliseconds: 50)),
    );

    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(sent, ['${event.title}|Lab 1|${event.id}']);
  });

  test('cancel prevents notification', () async {
    final sent = <String>[];
    final adapter = WebNotificationAdapter(
      canNotifyOverride: () => true,
      sender: (title, body, tag) {
        sent.add('$title|$body|$tag');
      },
    );

    final event = _event('event-2');
    adapter.schedule(
      event,
      DateTime.now().add(const Duration(milliseconds: 50)),
    );
    adapter.cancel(event.id);

    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(sent, isEmpty);
  });

  test('clear cancels all pending notifications', () async {
    final sent = <String>[];
    final adapter = WebNotificationAdapter(
      canNotifyOverride: () => true,
      sender: (title, body, tag) {
        sent.add('$title|$body|$tag');
      },
    );

    final eventA = _event('event-a', location: 'A');
    final eventB = _event('event-b', location: 'B');

    adapter.schedule(
      eventA,
      DateTime.now().add(const Duration(milliseconds: 50)),
    );
    adapter.schedule(
      eventB,
      DateTime.now().add(const Duration(milliseconds: 80)),
    );

    adapter.clear();

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(sent, isEmpty);
  });
}
