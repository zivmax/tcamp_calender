import 'package:flutter/material.dart';
import 'package:tcamp_calender/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../models/calendar_event.dart';

class EventListTile extends StatelessWidget {
  const EventListTile({super.key, required this.event, this.onTap});

  final CalendarEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final timeRange = event.isAllDay
        ? AppLocalizations.of(context)!.allDay
        : '${DateFormat.Hm(locale).format(event.start)} - ${DateFormat.Hm(locale).format(event.end)}';

    return ListTile(
      title: Text(event.title.isEmpty ? AppLocalizations.of(context)!.untitled : event.title),
      subtitle: Text(timeRange),
      trailing: event.location.isEmpty ? null : Text(event.location),
      onTap: onTap,
    );
  }
}
