import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tcamp_calendar/services/ics_service.dart';
import 'package:tcamp_calendar/services/subscription_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and load subscriptions', () async {
    final service = SubscriptionService(icsService: const IcsService());

    await service.saveSubscriptions(['https://example.com/a.ics']);
    final loaded = await service.loadSubscriptions();

    expect(loaded, ['https://example.com/a.ics']);
  });

  test('fetch subscriptions returns events for success responses', () async {
    const icsService = IcsService();
    final client = MockClient((request) async {
      if (request.url.toString().contains('good')) {
        const content = 'BEGIN:VCALENDAR\n'
            'VERSION:2.0\n'
            'BEGIN:VEVENT\n'
            'UID:sub-1\n'
            'DTSTAMP:20260117T000000Z\n'
            'DTSTART:20260117T090000Z\n'
            'DTEND:20260117T100000Z\n'
            'SUMMARY:Subscribed\n'
            'END:VEVENT\n'
            'END:VCALENDAR';
        return http.Response(content, 200);
      }
      return http.Response('Not found', 404);
    });

    final service = SubscriptionService(icsService: icsService, client: client);
    final events = await service.fetchFromSubscriptions([
      'https://example.com/good.ics',
      'https://example.com/bad.ics',
    ]);

    expect(events.length, 1);
    expect(events.first.title, 'Subscribed');
  });
}
