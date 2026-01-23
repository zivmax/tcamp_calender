import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/calendar_event.dart';
import '../utils/time_format.dart';

/// A list tile for displaying calendar event summary.
///
/// Shows event title, time range, and optional location.
class EventListTile extends StatelessWidget {
  const EventListTile({
    super.key,
    required this.event,
    this.onTap,
  });

  /// The event to display.
  final CalendarEvent event;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final timeFormat = timeFormatForLocale(context);

    final timeRange = event.isAllDay
        ? l10n.allDay
        : '${timeFormat.format(event.start)} - ${timeFormat.format(event.end)}';

    final title = event.title.isEmpty ? l10n.untitled : event.title;

    return ListTile(
      leading: _buildLeadingIndicator(theme),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(timeRange),
      trailing: event.location.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.place,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    event.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
      onTap: onTap,
    );
  }

  Widget _buildLeadingIndicator(ThemeData theme) {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: event.isRecurring
            ? theme.colorScheme.secondary
            : theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

