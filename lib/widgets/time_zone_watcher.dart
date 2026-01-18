import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/event_repository.dart';
import '../services/notification_service.dart';

/// Watches for timezone changes while the app is in the foreground/background
/// and reschedules reminders when a change is detected.
class TimeZoneWatcher extends StatefulWidget {
  const TimeZoneWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<TimeZoneWatcher> createState() => _TimeZoneWatcherState();
}

class _TimeZoneWatcherState extends State<TimeZoneWatcher>
    with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndReschedule();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndReschedule();
    }
  }

  Future<void> _checkAndReschedule() async {
    if (_checking) return;
    _checking = true;

    try {
      final notificationService = context.read<NotificationService>();
      final eventRepository = context.read<EventRepository>();

      final changed = await notificationService.refreshLocalTimeZoneIfChanged();
      if (changed) {
        await eventRepository.rescheduleAllReminders();
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
