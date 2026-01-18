// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:tcamp_calender/l10n/app_localizations.dart';
import 'package:tcamp_calender/models/calendar_event.dart';
import 'package:tcamp_calender/screens/home_screen.dart';
import 'package:tcamp_calender/services/event_repository.dart';
import 'package:tcamp_calender/services/ics_service.dart';
import 'package:tcamp_calender/services/lunar_service.dart';
import 'package:tcamp_calender/services/notification_service.dart';
import 'package:tcamp_calender/services/subscription_service.dart';

class _FakeNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleEventReminder(CalendarEvent event) async {}

  @override
  Future<void> cancelEventReminder(String eventId) async {}
}

void main() {
  late Directory tempDir;
  late EventRepository repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('calendar_widget_test');
    Hive.init(tempDir.path);
    repository = EventRepository(notificationService: _FakeNotificationService());
    await repository.init();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Home screen navigation renders views', (WidgetTester tester) async {
    const icsService = IcsService();
    final subscriptionService = SubscriptionService(icsService: icsService);
    const lunarService = LunarService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<EventRepository>.value(value: repository),
          Provider<IcsService>.value(value: icsService),
          Provider<SubscriptionService>.value(value: subscriptionService),
          Provider<LunarService>.value(value: lunarService),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(
            lunarService: lunarService,
            icsService: icsService,
            subscriptionService: subscriptionService,
          ),
        ),
      ),
    );

    expect(find.text('Month'), findsWidgets);
    expect(find.text('Week'), findsWidgets);
    expect(find.text('Day'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}
