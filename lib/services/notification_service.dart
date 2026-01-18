import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:tcamp_calender/l10n/app_localizations.dart';

import '../models/calendar_event.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    // Use system locale and generated localizations to pick notification strings.
    final locale = PlatformDispatcher.instance.locale;
    final loc = lookupAppLocalizations(locale);

    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final linuxSettings = LinuxInitializationSettings(defaultActionName: loc.linuxActionOpen);
    final windowsSettings = WindowsInitializationSettings(
      appName: loc.notificationAppName,
      appUserModelId: 'com.tcamp.calendar',
      guid: '2f4c8c0e-8bd6-4f6b-9f4a-9f0f54c2c501',
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    await _plugin.initialize(initSettings);

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    // Linux and Windows do not require runtime notification permissions.
  }

  Future<void> scheduleEventReminder(CalendarEvent event) async {
    if (event.reminderMinutes == null) {
      return;
    }
    final scheduled = event.start.subtract(
      Duration(minutes: event.reminderMinutes ?? 0),
    );
    if (scheduled.isBefore(DateTime.now())) {
      return;
    }

    final notificationId = _notificationId(event.id);

    final locale = PlatformDispatcher.instance.locale;
    final loc = lookupAppLocalizations(locale);

    await _plugin.zonedSchedule(
      notificationId,
      event.title,
      event.description.isEmpty ? event.location : event.description,
      tz.TZDateTime.from(scheduled, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'calendar_reminders',
          loc.notificationChannelName,
          channelDescription: loc.notificationChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        linux: const LinuxNotificationDetails(),
        windows: const WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancelEventReminder(String eventId) async {
    await _plugin.cancel(_notificationId(eventId));
  }

  int _notificationId(String eventId) {
    return eventId.hashCode & 0x7fffffff;
  }
}
