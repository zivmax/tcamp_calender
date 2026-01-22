import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcamp_calender/models/calendar_event.dart';
import 'package:tcamp_calender/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String currentTimeZone;
  int callCount = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
    currentTimeZone = 'UTC';
    callCount = 0;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  test('refreshLocalTimeZoneIfChanged returns true when timezone changes', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_timezone_id', 'America/New_York');

    currentTimeZone = 'UTC';
    final service = NotificationService(
      timeZoneProvider: () async => TimezoneInfo(identifier: currentTimeZone),
    );

    final changed = await service.refreshLocalTimeZoneIfChanged();

    expect(changed, isTrue);
    expect(prefs.getString('last_timezone_id'), 'UTC');
  });

  test('refreshLocalTimeZoneIfChanged returns false when unchanged', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_timezone_id', 'UTC');

    currentTimeZone = 'UTC';
    final service = NotificationService(
      timeZoneProvider: () async => TimezoneInfo(identifier: currentTimeZone),
    );

    final changed = await service.refreshLocalTimeZoneIfChanged();

    expect(changed, isFalse);
    expect(prefs.getString('last_timezone_id'), 'UTC');
  });

  test('refreshLocalTimeZoneIfChanged falls back when provider throws', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_timezone_id', 'America/New_York');

    currentTimeZone = 'UTC';
    callCount = 0;

    final service = NotificationService(
      timeZoneProvider: () async {
        callCount += 1;
        if (callCount == 1) {
          return TimezoneInfo(identifier: currentTimeZone);
        }
        throw Exception('Timezone provider failed');
      },
    );

    final changed = await service.refreshLocalTimeZoneIfChanged();

    expect(changed, isTrue);
    expect(prefs.getString('last_timezone_id'), isNotNull);
  });

  test('init configures timezone and initializes plugin on unsupported platform',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final service = NotificationService(
      timeZoneProvider: () async => TimezoneInfo(identifier: 'UTC'),
    );

    await service.init();
  });

  test('init does not crash with unsupported locale', () async {
    final originalLocales = TestWidgetsFlutterBinding.instance.platformDispatcher.locales;
    TestWidgetsFlutterBinding.instance.platformDispatcher.localesTestValue = const [Locale('C')];
    addTearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.localesTestValue = originalLocales;
    });

    final service = NotificationService(
      timeZoneProvider: () async => TimezoneInfo(identifier: 'UTC'),
    );

    await service.init();
  });

  test('schedule and cancel reminders on windows target platform', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final service = NotificationService(
      timeZoneProvider: () async => TimezoneInfo(identifier: 'UTC'),
    );

    await service.init();

    final event = CalendarEvent(
      id: 'event-1',
      title: 'Future Event',
      description: 'Test',
      location: 'Room',
      start: DateTime.now().add(const Duration(days: 2, hours: 1)),
      end: DateTime.now().add(const Duration(days: 2, hours: 2)),
      isAllDay: false,
      reminderMinutes: 10,
      rrule: null,
    );

    await service.scheduleEventReminder(event);
    await service.cancelEventReminder(event.id);
  });
}

class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {
  @override
  Future<void> cancel(int id) async {}
}
