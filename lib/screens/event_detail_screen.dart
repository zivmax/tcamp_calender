import 'package:flutter/material.dart';
import 'package:tcamp_calender/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/calendar_event.dart';
import '../services/event_repository.dart';
import 'event_form_screen.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale);
    final timeFormat = DateFormat.Hm(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title.isEmpty ? AppLocalizations.of(context)!.eventDetails : event.title),
        actions: [
          IconButton(
            onPressed: () {
              final repo = context.read<EventRepository>();
              final baseEvent = repo.getById(event.id) ?? event;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventFormScreen(
                    event: baseEvent,
                    initialDate: baseEvent.start,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () async {
              final repo = context.read<EventRepository>();
              final baseEvent = repo.getById(event.id) ?? event;
              await repo.deleteEvent(baseEvent);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title.isEmpty ? AppLocalizations.of(context)!.untitled : event.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              event.isAllDay
                  ? AppLocalizations.of(context)!.allDay
                  : '${dateFormat.format(event.start)} ${timeFormat.format(event.start)} - ${dateFormat.format(event.end)} ${timeFormat.format(event.end)}',
            ),
            const SizedBox(height: 12),
            if (event.location.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.place, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.location)),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (event.description.isNotEmpty)
              Text(event.description),
            const SizedBox(height: 12),
            if (event.reminderMinutes != null)
              Text(AppLocalizations.of(context)!.reminderText(event.reminderMinutes!)),  
            if (event.rrule != null && event.rrule!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.rruleText(event.rrule!)),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.seriesEditsNote,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
