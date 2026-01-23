import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tcamp_calendar/l10n/app_localizations.dart';
import 'package:tcamp_calendar/models/calendar_event.dart';
import 'package:tcamp_calendar/screens/day_view.dart';
import 'package:tcamp_calendar/screens/event_detail_screen.dart';
import 'package:tcamp_calendar/screens/home_screen.dart';
import 'package:tcamp_calendar/services/event_repository.dart';
import 'package:tcamp_calendar/services/ics_service.dart';
import 'package:tcamp_calendar/services/lunar_service.dart';
import 'package:tcamp_calendar/services/notification_service.dart';
import 'package:tcamp_calendar/services/subscription_service.dart';

class _FakeNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleEventReminder(CalendarEvent event) async {}

  @override
  Future<void> cancelEventReminder(String eventId) async {}
}

class _InMemoryEventRepository extends EventRepository {
  _InMemoryEventRepository()
      : super(notificationService: _FakeNotificationService());

  final List<CalendarEvent> _items = [];

  @override
  Future<void> init() async {}

  @override
  List<CalendarEvent> get events {
    final items = List<CalendarEvent>.from(_items);
    items.sort((a, b) => a.start.compareTo(b.start));
    return items;
  }

  @override
  CalendarEvent? getById(String id) {
    for (final event in _items) {
      if (event.id == id) return event;
    }
    return null;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  @override
  Future<void> addEvent(CalendarEvent event) async {
    _items.add(event);
    notifyListeners();
  }

  @override
  Future<void> updateEvent(CalendarEvent event) async {
    final index = _items.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      _items[index] = event;
    } else {
      _items.add(event);
    }
    notifyListeners();
  }

  @override
  Future<void> deleteEvent(CalendarEvent event) async {
    _items.removeWhere((e) => e.id == event.id);
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _InMemoryEventRepository repository;

  setUpAll(() async {
    repository = _InMemoryEventRepository();
  });

  setUp(() async {
    repository.clear();
  });

  tearDownAll(() async {
  });

  testWidgets('home navigation switches between tabs', (tester) async {
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

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    // Week view shows "Jan. Week 1" format
    expect(find.textContaining('Week'), findsWidgets);

    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.text('Add Event'), findsWidgets);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Import & Export'), findsOneWidget);
  });

  testWidgets('add event flow from DayView', (tester) async {
    const lunarService = LunarService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<EventRepository>.value(value: repository),
          Provider<LunarService>.value(value: lunarService),
        ],
        // ignore: prefer_const_constructors
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DayView()),
        ),
      ),
    );

    expect(find.text('No events'), findsOneWidget);
    await tester.tap(find.text('Add Event'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Planning');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text('Planning'), findsOneWidget);
  });

  testWidgets('edit and delete event from detail screen', (tester) async {
    final editRepository = _InMemoryEventRepository();
    final baseEvent = editRepository.createEmpty(DateTime(2026, 1, 17, 9, 0));
    final event = baseEvent.copyWith(title: 'Original');
    await editRepository.addEvent(event);

    Future<void> pumpUntilFound(Finder finder) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (finder.evaluate().isNotEmpty) {
          return;
        }
      }
      fail('Timed out waiting for ${finder.describeMatch(Plurality.one)}');
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<EventRepository>.value(value: editRepository),
          Provider<LunarService>.value(value: const LunarService()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: EventDetailScreen(event: event),
        ),
      ),
    );

    final editButtonFinder = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.icon is Icon && (widget.icon as Icon).icon == Icons.edit,
    );
    final editButton = tester.widget<IconButton>(editButtonFinder);
    editButton.onPressed?.call();
    await tester.pump();

    final titleFieldFinder = find.byType(TextFormField).first;
    await pumpUntilFound(titleFieldFinder);
    await tester.enterText(find.byType(TextFormField).first, 'Updated');
    final saveButtonFinder = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.icon is Icon && (widget.icon as Icon).icon == Icons.save,
    );
    await pumpUntilFound(saveButtonFinder);
    final saveButton = tester.widget<IconButton>(saveButtonFinder);
    saveButton.onPressed?.call();
    await tester.pump();

    expect(editRepository.events.first.title, 'Updated');

    final deleteButtonFinder = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.icon is Icon && (widget.icon as Icon).icon == Icons.delete,
    );
    final deleteButton = tester.widget<IconButton>(deleteButtonFinder);
    deleteButton.onPressed?.call();
    await tester.pump();

    expect(editRepository.events.isEmpty, true);
  });
}
