import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/calendar_event.dart';
import '../services/event_repository.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class WeekView extends StatefulWidget {
  const WeekView({super.key});

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  late PageController _pageController;
  DateTime _focusedWeek = DateTime.now();
  late DateTime _baseMonday;
  static const int _initialPage = 10000;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    final now = DateTime.now();
    _baseMonday = now.subtract(Duration(days: now.weekday - 1));
    _baseMonday = DateTime(_baseMonday.year, _baseMonday.month, _baseMonday.day);
    _focusedWeek = _baseMonday;

    // Initial scroll offset approximation
    _scrollOffset = (now.hour * 60.0) - 200;
    if (_scrollOffset < 0) _scrollOffset = 0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<DateTime> _weekDaysForIndex(int index) {
    final diff = index - _initialPage;
    final start = _baseMonday.add(Duration(days: diff * 7));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final firstWeekday = firstDay.weekday; 
    return ((date.day + firstWeekday - 2) ~/ 7) + 1;
  }

  String _getMonthWeekHeaderForWeek(BuildContext context, List<DateTime> weekDays) {
    final locale = Localizations.localeOf(context).toString();
    final groups = <String, DateTime>{};
    for (final day in weekDays) {
      final key = '${day.year}-${day.month}';
      groups.putIfAbsent(key, () => day);
    }
    final parts = <String>[];
    for (final rep in groups.values) {
      final weekNum = _getWeekOfMonth(rep);
      if (locale.startsWith('zh')) {
        parts.add('${rep.month}月 第$weekNum周');
      } else if (locale.startsWith('en')) {
        parts.add('${DateFormat.MMM(locale).format(rep)}. Week $weekNum');
      } else {
        parts.add('${DateFormat.MMMM(locale).format(rep)} Week $weekNum');
      }
    }
    return parts.join(' / ');
  }

  void _onPageChanged(int index) {
    final days = _weekDaysForIndex(index);
    setState(() {
      _focusedWeek = days[0];
    });
  }

  void _nextWeek() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevWeek() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWeekDays = List.generate(7, (i) => _focusedWeek.add(Duration(days: i)));
    final headerText = _getMonthWeekHeaderForWeek(context, currentWeekDays);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevWeek,
                icon: const Icon(Icons.chevron_left),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  headerText, 
                  key: ValueKey(headerText),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: _nextWeek,
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
              return WeekPage(
                weekDays: _weekDaysForIndex(index),
                initialScrollOffset: _scrollOffset,
                onScroll: (offset) {
                  _scrollOffset = offset;
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class WeekPage extends StatefulWidget {
  const WeekPage({
    super.key,
    required this.weekDays,
    this.initialScrollOffset = 0.0,
    this.onScroll,
  });

  final List<DateTime> weekDays;
  final double initialScrollOffset;
  final ValueChanged<double>? onScroll;

  @override
  State<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<WeekPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: widget.initialScrollOffset);
    _scrollController.addListener(() {
      if (widget.onScroll != null) {
        widget.onScroll!(_scrollController.offset);
      }
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<EventRepository>();
    final locale = Localizations.localeOf(context).toString();
    final weekDays = widget.weekDays;

    return Column(
      children: [
        // Days Header
        Row(
          children: [
            const SizedBox(width: 50),
            ...weekDays.map((day) {
              final isToday = day.year == DateTime.now().year && 
                              day.month == DateTime.now().month && 
                              day.day == DateTime.now().day;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: isToday ? BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: Theme.of(context).primaryColor.a * 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ) : null,
                  child: Column(
                    children: [
                      Text(
                        DateFormat.E(locale).format(day),
                        style: TextStyle(
                           fontSize: 12,
                           color: isToday ? Theme.of(context).primaryColor : Colors.grey,
                           fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day.day.toString(),
                         style: TextStyle(
                           fontSize: 16,
                           color: isToday ? Theme.of(context).primaryColor : null,
                           fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        const Divider(height: 1),
        SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 50,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.allDay,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ...weekDays.map((day) {
                final allDayEvents = repo
                    .eventsForDay(day)
                    .where((event) => event.isAllDay)
                    .toList();
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey.withValues(alpha: Colors.grey.a * 0.1))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final event in allDayEvents.take(2))
                          _buildAllDayTag(context, event),
                        if (allDayEvents.length > 2)
                          Text(
                            '+${allDayEvents.length - 2}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const Divider(height: 1),
        
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 50,
                  height: 24 * 60.0,
                  child: Column(
                    children: List.generate(24, (index) {
                      return SizedBox(
                        height: 60.0,
                        child: Text(
                          '$index:00',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                  ),
                ),
                
                Expanded(
                  child: SizedBox(
                    height: 24 * 60.0,
                    child: Stack(
                      children: [
                         ...List.generate(24, (index) {
                            return Positioned(
                              top: index * 60.0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 1,
                                color: Colors.grey.withValues(alpha: Colors.grey.a * 0.1),
                              ),
                            );
                        }),
                        
                         Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: weekDays.map((day) {
                             return Expanded(
                               child: DecoratedBox(
                                 decoration: BoxDecoration(
                                    border: Border(right: BorderSide(color: Colors.grey.withValues(alpha: Colors.grey.a * 0.1))),
                                 ),
                                 child: LayoutBuilder(builder: (context, constraints) {
                                  final events = repo
                                      .eventsForDay(day)
                                      .where((event) => !event.isAllDay)
                                      .toList();
                                  return Stack(
                                    children: [
                                      for (final event in events)
                                        _buildEventBar(context, event, day, constraints.maxWidth),
                                      
                                      Positioned.fill(
                                        child: GestureDetector(
                                           onTapUp: (details) {
                                              final tapMinutes = details.localPosition.dy;
                                              final hour = (tapMinutes / 60).floor();
                                              final minute = (tapMinutes % 60).toInt();
                                              final newEventDate = DateTime(day.year, day.month, day.day, hour, minute);
                                              Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) => EventFormScreen(initialDate: newEventDate),
                                                ),
                                              );
                                           },
                                           behavior: HitTestBehavior.translucent,
                                        ),
                                      )
                                    ],
                                  );
                               }),
                               ),
                             );
                          }).toList(),
                         ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventBar(BuildContext context, CalendarEvent event, DateTime day, double width) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    
    var start = event.start;
    var end = event.end;
    
    if (start.isBefore(dayStart)) start = dayStart;
    if (end.isAfter(dayEnd)) end = dayEnd;
    
    final top = (start.hour * 60.0) + start.minute;
    final durationMinutes = end.difference(start).inMinutes;
    final height = durationMinutes < 15 ? 15.0 : durationMinutes.toDouble();
    
    return Positioned(
      top: top,
      left: 1,
      right: 1,
      height: height,
      child: GestureDetector(
        onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EventDetailScreen(event: event),
              ),
            );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: Theme.of(context).primaryColor.a * 0.7),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Theme.of(context).primaryColor, width: 1),
          ),
          padding: const EdgeInsets.all(2),
          child: Text(
            event.title,
            style: const TextStyle(color: Colors.white, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildAllDayTag(BuildContext context, CalendarEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EventDetailScreen(event: event),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: Theme.of(context).primaryColor.a * 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: Theme.of(context).primaryColor.a * 0.4)),
          ),
          child: Text(
            event.title.isEmpty ? AppLocalizations.of(context)!.untitled : event.title,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
