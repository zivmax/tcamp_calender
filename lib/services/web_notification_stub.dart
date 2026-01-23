import '../models/calendar_event.dart';

class WebNotificationAdapter {
  Future<void> requestPermission() async {}

  bool get canNotify => false;

  void schedule(CalendarEvent event, DateTime scheduledTime) {}

  void cancel(String eventId) {}

  void clear() {}
}
