import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/event_repository.dart';
import '../services/lunar_service.dart';
import '../widgets/event_list_tile.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class DayView extends StatefulWidget {
  const DayView({super.key});

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  late PageController _pageController;
  late DateTime _baseDay;
  DateTime _selectedDay = DateTime.now();
  static const int _initialPage = 10000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    final now = DateTime.now();
    _baseDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _baseDay;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _dayForIndex(int index) {
    return _baseDay.add(Duration(days: index - _initialPage));
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedDay = _dayForIndex(index);
    });
  }

  void _prevDay() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextDay() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMMEEEEd(locale);
    final lunarService = context.read<LunarService>();
    final lunarText = lunarService.formatFullLunar(_selectedDay, locale: Localizations.localeOf(context).languageCode);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: _prevDay,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        dateFormat.format(_selectedDay),
                        key: ValueKey('date-$_selectedDay'),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (lunarText.isNotEmpty)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          lunarText,
                          key: ValueKey('lunar-$lunarText'),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _nextDay,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final day = _dayForIndex(index);
              return DayPage(day: day);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EventFormScreen(initialDate: _selectedDay),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addEvent),
            ),
          ),
        ),
      ],
    );
  }
}

class DayPage extends StatelessWidget {
  const DayPage({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<EventRepository>();
    final events = repo.eventsForDay(day);

    if (events.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noEvents));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventListTile(
          event: event,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EventDetailScreen(event: event),
              ),
            );
          },
        );
      },
    );
  }
}
