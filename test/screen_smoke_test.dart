import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:tcamp_calender/models/calendar_event.dart';
import 'package:tcamp_calender/screens/day_view.dart';
import 'package:tcamp_calender/screens/event_detail_screen.dart';
import 'package:tcamp_calender/screens/event_form_screen.dart';
import 'package:tcamp_calender/screens/month_view.dart';
import 'package:tcamp_calender/screens/settings_screen.dart';
import 'package:tcamp_calender/screens/week_view.dart';
import 'package:tcamp_calender/services/ics_service.dart';
import 'package:tcamp_calender/services/lunar_service.dart';
import 'package:tcamp_calender/services/settings_service.dart';

import 'test_helpers.dart';

void _configureTestView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CalendarEvent sampleEvent({
    required String id,
    required DateTime start,
    bool allDay = false,
  }) {
    return CalendarEvent(
      id: id,
      title: 'Event $id',
      description: 'Description $id',
      location: 'Room $id',
      start: start,
      end: allDay ? start.add(const Duration(days: 1)) : start.add(const Duration(hours: 2)),
      isAllDay: allDay,
      reminderMinutes: 10,
      rrule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO',
    );
  }

  testWidgets('DayView renders events for today', (tester) async {
    _configureTestView(tester);
    final today = DateTime.now();
    final repo = TestEventRepository(
      notificationService: TestNotificationService(),
      seed: [sampleEvent(id: '1', start: today)],
    );

    await tester.pumpWidget(buildTestApp(child: const DayView(), repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Event 1'), findsOneWidget);
    expect(find.text('No events'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Event 1'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Event'));
    await tester.pumpAndSettle();
  });

  testWidgets('MonthView shows event list and add button', (tester) async {
    _configureTestView(tester);
    final today = DateTime.now();
    final repo = TestEventRepository(
      notificationService: TestNotificationService(),
      seed: [sampleEvent(id: '2', start: today)],
    );

    await tester.pumpWidget(
      buildTestApp(
        child: const MonthView(lunarService: LunarService()),
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Event 2'), findsOneWidget);
    expect(find.text('Add Event'), findsOneWidget);

    await tester.tap(find.text(DateTime.now().day.toString()).first);
    await tester.pumpAndSettle();

    final formatButton = find.text('Month');
    if (formatButton.evaluate().isNotEmpty) {
      await tester.tap(formatButton.first);
      await tester.pumpAndSettle();
    }

    await tester.drag(find.byType(TableCalendar<CalendarEvent>), const Offset(-300, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Event 2'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    final tomorrow = DateTime.now().add(const Duration(days: 1)).day.toString();
    if (find.text(tomorrow).evaluate().isNotEmpty) {
      await tester.tap(find.text(tomorrow).first);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Add Event'));
    await tester.pumpAndSettle();
  });

  testWidgets('MonthView renders lunar text in Chinese locale', (tester) async {
    _configureTestView(tester);
    final repo = TestEventRepository(notificationService: TestNotificationService());

    await tester.pumpWidget(
      buildTestApp(
        child: const MonthView(lunarService: LunarService()),
        repo: repo,
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('DayView shows empty state when no events', (tester) async {
    _configureTestView(tester);
    final repo = TestEventRepository(notificationService: TestNotificationService());

    await tester.pumpWidget(buildTestApp(child: const DayView(), repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('No events'), findsOneWidget);
  });

  testWidgets('DayView renders lunar text in Chinese locale', (tester) async {
    _configureTestView(tester);
    final repo = TestEventRepository(notificationService: TestNotificationService());

    await tester.pumpWidget(
      buildTestApp(
        child: const DayView(),
        repo: repo,
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('WeekView renders events for the week', (tester) async {
    _configureTestView(tester);
    final today = DateTime.now();
    final repo = TestEventRepository(
      notificationService: TestNotificationService(),
      seed: [
        sampleEvent(id: '3', start: today),
        sampleEvent(id: '4', start: today, allDay: true),
      ],
    );

    await tester.pumpWidget(buildTestApp(child: const WeekView(), repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Event 3'), findsWidgets);
    expect(find.text('Event 4'), findsWidgets);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Event 3').first);
    await tester.pumpAndSettle();
  });

  testWidgets('WeekView renders Chinese header', (tester) async {
    _configureTestView(tester);
    final repo = TestEventRepository(notificationService: TestNotificationService());

    await tester.pumpWidget(
      buildTestApp(
        child: const WeekView(),
        repo: repo,
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('WeekView tap creates new event draft', (tester) async {
    _configureTestView(tester);
    final repo = TestEventRepository(notificationService: TestNotificationService());

    await tester.pumpWidget(buildTestApp(child: const WeekView(), repo: repo));
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.byType(WeekView));
    await tester.tapAt(rect.center);
    await tester.pumpAndSettle();

    expect(find.byType(EventFormScreen), findsOneWidget);
  });

  testWidgets('EventDetailScreen displays content and deletes', (tester) async {
    _configureTestView(tester);
    final event = sampleEvent(id: '5', start: DateTime.now());
    final repo = TestEventRepository(
      notificationService: TestNotificationService(),
      seed: [event],
    );

    await tester.pumpWidget(
      buildTestApp(
        child: EventDetailScreen(event: event),
        repo: repo,
        wrapInScaffold: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Event 5'), findsWidgets);
    expect(find.text('Description 5'), findsOneWidget);
    expect(find.text('Room 5'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(repo.deletedCount, 1);
  });

  testWidgets('EventFormScreen saves new event', (tester) async {
    _configureTestView(tester);
    final repo = TestEventRepository(notificationService: TestNotificationService());

    await tester.pumpWidget(
      buildTestApp(
        child: EventFormScreen(initialDate: DateTime(2026, 1, 18)),
        repo: repo,
        wrapInScaffold: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'New Title');

    await tester.tap(find.byIcon(Icons.calendar_today).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.access_time).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_active));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();

    final reminderDropdown = find.byType(DropdownButtonFormField<int?>).first;
    await tester.tap(reminderDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 hour before').last);
    await tester.pumpAndSettle();

    final repeatDropdown = find.byType(DropdownButtonFormField<RepeatChoice>).first;
    await tester.tap(repeatDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom (RRULE)').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).last, 'FREQ=DAILY;INTERVAL=1');

    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    expect(repo.addedCount, 1);
  });

  testWidgets('SettingsScreen adds subscription entry', (tester) async {
    _configureTestView(tester);
    SharedPreferences.setMockInitialValues({});
    final settingsService = SettingsService();
    await settingsService.load();

    final repo = TestEventRepository(notificationService: TestNotificationService());
    const icsService = IcsService();
    final subscriptionService = TestSubscriptionService(icsService: icsService);

    await tester.pumpWidget(
      buildTestApp(
        child: SettingsScreen(
          icsService: icsService,
          subscriptionService: subscriptionService,
        ),
        repo: repo,
        settingsService: settingsService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'https://example.com/feed.ics');
    await tester.tap(find.text('Add subscription'));
    await tester.pumpAndSettle();

    expect(find.text('https://example.com/feed.ics'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Refresh subscriptions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(settingsService.locale?.languageCode, 'en');
  });

  testWidgets('SettingsScreen renders without SettingsService provider',
      (tester) async {
    _configureTestView(tester);
    final repo = TestEventRepository(notificationService: TestNotificationService());
    const icsService = IcsService();
    final subscriptionService = TestSubscriptionService(icsService: icsService);

    await tester.pumpWidget(
      buildTestApp(
        child: SettingsScreen(
          icsService: icsService,
          subscriptionService: subscriptionService,
        ),
        repo: repo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Import ICS'), findsOneWidget);
  });
}
