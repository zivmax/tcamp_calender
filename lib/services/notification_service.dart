import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../models/calendar_event.dart';

/// Service for scheduling local notifications for calendar reminders.
///
/// Supports Android, Linux, and Windows platforms.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'calendar_reminders';
  static const _windowsAppId = 'com.tcamp.calendar';
  static const _windowsGuid = '2f4c8c0e-8bd6-4f6b-9f4a-9f0f54c2c501';

  /// Initializes the notification service.
  ///
  /// Must be called before scheduling any notifications.
  Future<void> init() async {
    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    final loc = _getLocalizations();
    final settings = _buildInitSettings(loc);

    await _plugin.initialize(settings);
    await _requestPermissions();
  }

  /// Schedules a reminder notification for an event.
  ///
  /// Does nothing if the event has no reminder or the reminder time has passed.
  Future<void> scheduleEventReminder(CalendarEvent event) async {
    if (!event.hasReminder) return;

    final scheduled = event.start.subtract(
      Duration(minutes: event.reminderMinutes!),
    );

    // Don't schedule past notifications
    if (scheduled.isBefore(DateTime.now())) return;

    final notificationId = _getNotificationId(event.id);
    final loc = _getLocalizations();

    // Convert local DateTime to TZDateTime in the configured local timezone
    final tzScheduled = tz.TZDateTime(
      tz.local,
      scheduled.year,
      scheduled.month,
      scheduled.day,
      scheduled.hour,
      scheduled.minute,
      scheduled.second,
    );

    await _plugin.zonedSchedule(
      notificationId,
      event.title,
      event.description.isEmpty ? event.location : event.description,
      tzScheduled,
      _buildNotificationDetails(loc),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancels a scheduled reminder notification.
  Future<void> cancelEventReminder(String eventId) async {
    await _plugin.cancel(_getNotificationId(eventId));
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  AppLocalizations _getLocalizations() {
    final locale = PlatformDispatcher.instance.locale;
    return lookupAppLocalizations(locale);
  }

  InitializationSettings _buildInitSettings(AppLocalizations loc) {
    return InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      linux: LinuxInitializationSettings(
        defaultActionName: loc.linuxActionOpen,
      ),
      windows: WindowsInitializationSettings(
        appName: loc.notificationAppName,
        appUserModelId: _windowsAppId,
        guid: _windowsGuid,
      ),
    );
  }

  NotificationDetails _buildNotificationDetails(AppLocalizations loc) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        loc.notificationChannelName,
        channelDescription: loc.notificationChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      linux: const LinuxNotificationDetails(),
      windows: const WindowsNotificationDetails(),
    );
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    // Linux and Windows do not require runtime notification permissions.
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      // Use flutter_timezone to get the correct timezone name on all platforms
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // If timezone lookup fails, try to approximate from the local offset
      try {
        final now = DateTime.now();
        final offset = now.timeZoneOffset;
        final locations = tz.timeZoneDatabase.locations;
        for (final entry in locations.entries) {
          final location = entry.value;
          final tzNow = tz.TZDateTime.now(location);
          if (tzNow.timeZoneOffset == offset) {
            tz.setLocalLocation(location);
            return;
          }
        }
      } catch (_) {
        // Last resort: use UTC (notifications may be off by timezone offset)
      }
    }
  }

  /// Generates a stable notification ID from an event ID.
  int _getNotificationId(String eventId) {
    return eventId.hashCode & 0x7fffffff;
  }
}

