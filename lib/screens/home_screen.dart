import 'package:flutter/material.dart';
import 'package:tcamp_calender/l10n/app_localizations.dart';

import '../services/ics_service.dart';
import '../services/lunar_service.dart';
import '../services/subscription_service.dart';
import 'day_view.dart';
import 'month_view.dart';
import 'settings_screen.dart';
import 'week_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.lunarService,
    required this.icsService,
    required this.subscriptionService,
  });

  final LunarService lunarService;
  final IcsService icsService;
  final SubscriptionService subscriptionService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final views = [
      MonthView(lunarService: widget.lunarService),
      const WeekView(),
      const DayView(),
      SettingsScreen(
        icsService: widget.icsService,
        subscriptionService: widget.subscriptionService,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
      ),
      body: Stack(
        children: List.generate(views.length, (index) {
          final active = index == _index;
          return IgnorePointer(
            ignoring: !active,
            child: AnimatedOpacity(
              opacity: active ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: views[index],
            ),
          );
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.calendar_month), label: AppLocalizations.of(context)!.monthLabel),
          NavigationDestination(icon: const Icon(Icons.view_week), label: AppLocalizations.of(context)!.weekLabel),
          NavigationDestination(icon: const Icon(Icons.view_day), label: AppLocalizations.of(context)!.dayLabel),
          NavigationDestination(icon: const Icon(Icons.settings), label: AppLocalizations.of(context)!.settingsLabel),
        ],
      ),
    );
  }
}
