import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/calendar_event.dart';
import '../services/event_repository.dart';
import 'event_form_screen.dart';

/// Screen displaying event details with edit and delete actions.
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale);
    final timeFormat = DateFormat.Hm(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title.isEmpty ? l10n.eventDetails : event.title),
        actions: [
          IconButton(
            onPressed: () => _editEvent(context),
            icon: const Icon(Icons.edit),
            tooltip: l10n.editEvent,
          ),
          IconButton(
            onPressed: () => _deleteEvent(context),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              event.title.isEmpty ? l10n.untitled : event.title,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Date/Time
            _DetailRow(
              icon: Icons.schedule,
              text: _formatDateTime(event, dateFormat, timeFormat, l10n),
            ),

            // Location
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.place,
                text: event.location,
              ),
            ],

            // Description
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                event.description,
                style: theme.textTheme.bodyLarge,
              ),
            ],

            // Reminder
            if (event.hasReminder) ...[
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.notifications,
                text: l10n.reminderText(event.reminderMinutes!),
              ),
            ],

            // Recurrence
            if (event.isRecurring) ...[
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.repeat,
                text: l10n.rruleText(event.rrule!),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.seriesEditsNote,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(
    CalendarEvent event,
    DateFormat dateFormat,
    DateFormat timeFormat,
    AppLocalizations l10n,
  ) {
    if (event.isAllDay) {
      return l10n.allDay;
    }

    final startStr = '${dateFormat.format(event.start)} ${timeFormat.format(event.start)}';
    final endStr = '${dateFormat.format(event.end)} ${timeFormat.format(event.end)}';
    return '$startStr - $endStr';
  }

  void _editEvent(BuildContext context) {
    final repo = context.read<EventRepository>();
    final baseEvent = repo.getById(event.id) ?? event;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventFormScreen(
          event: baseEvent,
          initialDate: baseEvent.start,
        ),
      ),
    );
  }

  Future<void> _deleteEvent(BuildContext context) async {
    final repo = context.read<EventRepository>();
    final baseEvent = repo.getById(event.id) ?? event;

    await repo.deleteEvent(baseEvent);

    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

/// A row displaying an icon with text.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

