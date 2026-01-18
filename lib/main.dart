import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tcamp_calender/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/settings_service.dart';

import 'screens/home_screen.dart';
import 'services/event_repository.dart';
import 'services/ics_service.dart';
import 'services/lunar_service.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use google_fonts in offline mode (do not fetch from network).
  GoogleFonts.config.allowRuntimeFetching = false;

  await Hive.initFlutter();

  final notificationService = NotificationService();
  await notificationService.init();

  final eventRepository = EventRepository(
    notificationService: notificationService,
  );
  await eventRepository.init();

  final icsService = IcsService();
  final subscriptionService = SubscriptionService(icsService: icsService);
  const lunarService = LunarService();

  final settingsService = SettingsService();
  await settingsService.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EventRepository>.value(value: eventRepository),
        Provider<NotificationService>.value(value: notificationService),
        Provider<IcsService>.value(value: icsService),
        Provider<SubscriptionService>.value(value: subscriptionService),
        Provider<LunarService>.value(value: lunarService),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
      ],
      child: const TCampCalendarApp(),
    ),
  );
}

class TCampCalendarApp extends StatelessWidget {
  const TCampCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final icsService = context.read<IcsService>();
    final subscriptionService = context.read<SubscriptionService>();
    final lunarService = context.read<LunarService>();

    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
      // Use bundled Noto Sans SC for consistent Chinese rendering.
      fontFamily: 'Noto Sans SC',
    );

    final adjustedTextTheme = baseTheme.textTheme
        .apply(fontFamily: 'Noto Sans SC')
        .applyWeight(FontWeight.w700);

    final appTheme = baseTheme.copyWith(textTheme: adjustedTextTheme);

    return MaterialApp(
      title: AppLocalizations.of(context)?.appTitle ?? 'TCamp Calendar',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: context.watch<SettingsService>().locale,
      theme: appTheme,
      home: HomeScreen(
        lunarService: lunarService,
        icsService: icsService,
        subscriptionService: subscriptionService,
      ),
    );
  }
}

extension TextThemeWeight on TextTheme {
  TextTheme applyWeight(FontWeight weight) {
    return copyWith(
      displayLarge: displayLarge?.copyWith(fontWeight: weight),
      displayMedium: displayMedium?.copyWith(fontWeight: weight),
      displaySmall: displaySmall?.copyWith(fontWeight: weight),
      headlineLarge: headlineLarge?.copyWith(fontWeight: weight),
      headlineMedium: headlineMedium?.copyWith(fontWeight: weight),
      headlineSmall: headlineSmall?.copyWith(fontWeight: weight),
      titleLarge: titleLarge?.copyWith(fontWeight: weight),
      titleMedium: titleMedium?.copyWith(fontWeight: weight),
      titleSmall: titleSmall?.copyWith(fontWeight: weight),
      bodyLarge: bodyLarge?.copyWith(fontWeight: weight),
      bodyMedium: bodyMedium?.copyWith(fontWeight: weight),
      bodySmall: bodySmall?.copyWith(fontWeight: weight),
      labelLarge: labelLarge?.copyWith(fontWeight: weight),
      labelMedium: labelMedium?.copyWith(fontWeight: weight),
      labelSmall: labelSmall?.copyWith(fontWeight: weight),
    );
  }
}
