import 'package:flutter_test/flutter_test.dart';

import 'package:tcamp_calender/models/calendar_event.dart';
import 'package:tcamp_calender/services/ics_service.dart';

void main() {
  test('export and import ICS round-trip', () {
    const service = IcsService();
    final event = CalendarEvent(
      id: 'event-1',
      title: 'Demo',
      description: 'Desc',
      location: 'Room B',
      start: DateTime.utc(2026, 1, 17, 8, 30),
      end: DateTime.utc(2026, 1, 17, 9, 30),
      isAllDay: false,
      reminderMinutes: 10,
      rrule: 'FREQ=DAILY;INTERVAL=1',
    );

    final ics = service.exportToIcs([event]);
    final imported = service.importFromIcs(ics);

    expect(imported.length, 1);
    final parsed = imported.first;
    expect(parsed.title, 'Demo');
    expect(parsed.description, 'Desc');
    expect(parsed.location, 'Room B');
    expect(parsed.rrule, 'FREQ=DAILY;INTERVAL=1');
    expect(parsed.start.year, 2026);
    expect(parsed.start.month, 1);
    expect(parsed.start.day, 17);
  });

  test('all-day ICS parsing', () {
    const service = IcsService();
    const content = 'BEGIN:VCALENDAR\n'
        'VERSION:2.0\n'
        'BEGIN:VEVENT\n'
        'UID:all-day-1\n'
        'DTSTAMP:20260117T000000Z\n'
        'DTSTART;VALUE=DATE:20260117\n'
        'DTEND;VALUE=DATE:20260118\n'
        'SUMMARY:All Day\n'
        'END:VEVENT\n'
        'END:VCALENDAR';

    final imported = service.importFromIcs(content);
    expect(imported.length, 1);
    final parsed = imported.first;
    expect(parsed.isAllDay, true);
    expect(parsed.start.year, 2026);
    expect(parsed.start.month, 1);
    expect(parsed.start.day, 17);
  });

  test('ICS escapes and unescapes text', () {
    const service = IcsService();
    final event = CalendarEvent(
      id: 'event-escape',
      title: 'Title,With;Punct\nLine',
      description: 'Desc\\Backslash',
      location: 'Room, A; 2',
      start: DateTime.utc(2026, 1, 17, 8, 30),
      end: DateTime.utc(2026, 1, 17, 9, 30),
      isAllDay: false,
      reminderMinutes: null,
      rrule: null,
    );

    final ics = service.exportToIcs([event]);
    final imported = service.importFromIcs(ics);

    expect(imported.length, 1);
    final parsed = imported.first;
    expect(parsed.title, 'Title,With;Punct\nLine');
    expect(parsed.description, 'Desc\\Backslash');
    expect(parsed.location, 'Room, A; 2');
  });

  test('ICS line unfolding supports folded lines', () {
    const service = IcsService();
    const content = 'BEGIN:VCALENDAR\n'
        'VERSION:2.0\n'
        'BEGIN:VEVENT\n'
        'UID:fold-1\n'
        'DTSTAMP:20260117T000000Z\n'
        'DTSTART:20260117T090000Z\n'
        'DTEND:20260117T100000Z\n'
        'SUMMARY:Folded line\n'
        'DESCRIPTION:First line\n'
        ' second line\n'
        ' third line\n'
        'END:VEVENT\n'
        'END:VCALENDAR';

    final imported = service.importFromIcs(content);
    expect(imported.length, 1);
    expect(imported.first.description, 'First linesecond linethird line');
  });
}
