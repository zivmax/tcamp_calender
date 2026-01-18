import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/app_localizations.dart';
import '../models/calendar_event.dart';
import '../services/event_repository.dart';
import '../services/lunar_service.dart';
import '../widgets/event_list_tile.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class MonthView extends StatefulWidget {
  const MonthView({super.key, required this.lunarService});

  final LunarService lunarService;

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<EventRepository>();
    final events = repo.eventsForDay(_selectedDay);

    return Column(
      children: [
        TableCalendar<CalendarEvent>(
          locale: Localizations.localeOf(context).toString(),
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          headerStyle: const HeaderStyle(
            formatButtonShowsNext: false,
          ),
          availableCalendarFormats: {
            CalendarFormat.month: AppLocalizations.of(context)!.monthLabel,
            CalendarFormat.twoWeeks: '2 ${AppLocalizations.of(context)!.weekLabel}',
            CalendarFormat.week: AppLocalizations.of(context)!.weekLabel,
          },
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          eventLoader: repo.eventsForDay,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
             _focusedDay = focusedDay;
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final lunarText = widget.lunarService.formatLunar(day, locale: Localizations.localeOf(context).languageCode);
              return _CalendarCell(day: day, lunarText: lunarText, isSelected: false);
            },
            todayBuilder: (context, day, focusedDay) {
              final lunarText = widget.lunarService.formatLunar(day, locale: Localizations.localeOf(context).languageCode);
              return _CalendarCell(day: day, lunarText: lunarText, isToday: true);
            },
            selectedBuilder: (context, day, focusedDay) {
              final lunarText = widget.lunarService.formatLunar(day, locale: Localizations.localeOf(context).languageCode);
              return _CalendarCell(day: day, lunarText: lunarText, isSelected: true);
            },
            // Custom markerBuilder to place the event dot at the top-right of the cell
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return null;
              final theme = Theme.of(context);
              // Ensure the dot remains visible when the day is selected or today by picking contrasting color
              final bool selected = isSameDay(date, _selectedDay);
              final bool today = isSameDay(date, DateTime.now());
              final Color dotColor = selected || today ? theme.colorScheme.onPrimary : theme.colorScheme.primary;

              return Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, right: 6),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: events.isEmpty
                ? Center(
                    key: ValueKey('empty-$_selectedDay'),
                    child: Text(AppLocalizations.of(context)!.noEvents),
                  )
                : ListView.builder(
                    key: ValueKey('list-$_selectedDay'),
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
                ),
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

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.lunarText,
    this.isSelected = false,
    this.isToday = false,
  });

  final DateTime day;
  final String lunarText;
  final bool isSelected;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isSelected
        ? theme.colorScheme.primary
        : isToday
            ? theme.colorScheme.primaryContainer
            : Colors.transparent;
    final textColor = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              style: (theme.textTheme.titleMedium ?? const TextStyle())
                  .copyWith(color: textColor),
              child: Text('${day.day}'),
            ),
            if (lunarText.isNotEmpty)
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                style: (theme.textTheme.labelSmall ?? const TextStyle())
                    .copyWith(color: textColor),
                child: Text(
                  lunarText,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
