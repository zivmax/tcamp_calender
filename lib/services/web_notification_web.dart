// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import '../models/calendar_event.dart';

typedef NotificationSender =
    void Function(String title, String body, String tag);

class WebNotificationAdapter {
  WebNotificationAdapter({
    NotificationSender? sender,
    bool Function()? canNotifyOverride,
  }) : _sender = sender ?? _defaultSender,
       _canNotifyOverride = canNotifyOverride;

  final NotificationSender _sender;
  final bool Function()? _canNotifyOverride;
  final Map<String, Timer> _timers = {};

  Future<void> requestPermission() async {
    if (_canNotifyOverride != null) return;
    if (!_isSupported) return;
    if (_notificationPermission == 'granted') return;
    try {
      await html.Notification.requestPermission();
    } catch (_) {
      // Ignore unsupported or blocked requestPermission calls.
    }
  }

  bool get canNotify =>
      _canNotifyOverride?.call() ??
      (_isSupported && _notificationPermission == 'granted');

  void schedule(CalendarEvent event, DateTime scheduledTime) {
    if (!_isSupported) return;
    cancel(event.id);

    final delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return;

    _timers[event.id] = Timer(delay, () {
      if (!canNotify) return;
      final body = event.description.isEmpty
          ? event.location
          : event.description;
      _sender(event.title, body, event.id);
    });
  }

  void cancel(String eventId) {
    _timers.remove(eventId)?.cancel();
  }

  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  bool get _isSupported => html.Notification.supported;

  String? get _notificationPermission {
    try {
      return html.Notification.permission;
    } catch (_) {
      return null;
    }
  }

  static void _defaultSender(String title, String body, String tag) {
    html.Notification(title, body: body, tag: tag);
  }
}
