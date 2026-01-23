import 'package:flutter_test/flutter_test.dart';

import 'package:tcamp_calendar/models/calendar_event.dart';
import 'package:tcamp_calendar/services/web_notification_stub.dart';

CalendarEvent _event(String id) {
  final start = DateTime.now().add(const Duration(hours: 1));
  return CalendarEvent(
    id: id,
    title: 'Test Event',
    description: 'Test Description',
    location: 'Room A',
    start: start,
    end: start.add(const Duration(hours: 1)),
    reminderMinutes: 10,
  );
}

void main() {
  test('stub adapter is safe no-op', () async {
    final adapter = WebNotificationAdapter();

    await adapter.requestPermission();

    expect(adapter.canNotify, isFalse);

    final event = _event('event-1');
    adapter.schedule(event, DateTime.now().add(const Duration(minutes: 5)));
    adapter.cancel(event.id);
    adapter.clear();
  });
}
