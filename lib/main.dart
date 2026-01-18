import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/event_repository.dart';
import 'services/ics_service.dart';
import 'services/lunar_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/subscription_service.dart';
import 'theme/app_theme.dart';

/// Application entry point.
///
/// Initializes all services before running the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching for offline use
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize storage
  await Hive.initFlutter();

  // Initialize services
  final services = await _initializeServices();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: services.eventRepository),
        Provider.value(value: services.notificationService),
        Provider.value(value: services.icsService),
        Provider.value(value: services.subscriptionService),
        Provider.value(value: services.lunarService),
        ChangeNotifierProvider.value(value: services.settingsService),
      ],
      child: const TCampCalendarApp(),
    ),
  );
}

/// Container for all application services.
class AppServices {
  const AppServices({
    required this.eventRepository,
    required this.notificationService,
    required this.icsService,
    required this.subscriptionService,
    required this.lunarService,
    required this.settingsService,
  });

  final EventRepository eventRepository;
  final NotificationService notificationService;
  final IcsService icsService;
  final SubscriptionService subscriptionService;
  final LunarService lunarService;
  final SettingsService settingsService;
}

/// Initializes all application services.
Future<AppServices> _initializeServices() async {
  final notificationService = NotificationService();
  await notificationService.init();

  final eventRepository = EventRepository(
    notificationService: notificationService,
  );
  await eventRepository.init();

  const icsService = IcsService();
  final subscriptionService = SubscriptionService(icsService: icsService);
  const lunarService = LunarService();

  final settingsService = SettingsService();
  await settingsService.load();

  return AppServices(
    eventRepository: eventRepository,
    notificationService: notificationService,
    icsService: icsService,
    subscriptionService: subscriptionService,
    lunarService: lunarService,
    settingsService: settingsService,
  );
}

/// The root widget of the TCamp Calendar application.
class TCampCalendarApp extends StatelessWidget {
  const TCampCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final icsService = context.read<IcsService>();
    final subscriptionService = context.read<SubscriptionService>();
    final lunarService = context.read<LunarService>();

    return MaterialApp(
      title: 'TCamp Calendar',
      debugShowCheckedModeBanner: false,
      
      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settingsService.locale,
      
      // Theming
      theme: AppTheme.light(),
      
      home: HomeScreen(
        lunarService: lunarService,
        icsService: icsService,
        subscriptionService: subscriptionService,
      ),
    );
  }
}

