import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/ics_service.dart';
import '../services/lunar_service.dart';
import '../services/subscription_service.dart';
import 'day_view.dart';
import 'month_view.dart';
import 'settings_screen.dart';
import 'week_view.dart';

/// Main home screen with bottom navigation.
///
/// Provides navigation between month, week, day, and settings views.
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
  int _selectedIndex = 0;

  // Lazily built views to preserve state
  late final List<Widget> _views = [
    MonthView(lunarService: widget.lunarService),
    const WeekView(),
    const DayView(),
    SettingsScreen(
      icsService: widget.icsService,
      subscriptionService: widget.subscriptionService,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: _AnimatedViewSwitcher(
        index: _selectedIndex,
        children: _views,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_month),
            label: l10n.monthLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_week),
            label: l10n.weekLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_day),
            label: l10n.dayLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: l10n.settingsLabel,
          ),
        ],
      ),
    );
  }
}

/// Animated view switcher with cross-fade transitions.
class _AnimatedViewSwitcher extends StatelessWidget {
  const _AnimatedViewSwitcher({
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeOut;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(children.length, (i) {
        final isActive = i == index;
        return IgnorePointer(
          ignoring: !isActive,
          child: AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.0,
            duration: _duration,
            curve: _curve,
            child: children[i],
          ),
        );
      }),
    );
  }
}

