import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/calendar_event.dart';
import '../models/rrule.dart';
import '../services/event_repository.dart';
import '../utils/time_format.dart';

/// Screen for creating or editing calendar events.
///
/// Pass an existing [event] to edit mode, or omit it to create a new event.
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({
    super.key,
    this.event,
    required this.initialDate,
  });

  /// The event to edit, or null to create a new event.
  final CalendarEvent? event;

  /// The initial date for new events.
  final DateTime initialDate;

  /// Whether this is editing an existing event.
  bool get isEditing => event != null;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form state - using mutable draft for form editing
  late _EventDraft _draft;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _rruleController;

  @override
  void initState() {
    super.initState();
    _initializeDraft();
    _initializeControllers();
  }

  void _initializeDraft() {
    if (widget.event != null) {
      _draft = _EventDraft.fromEvent(widget.event!);
    } else {
      final repo = context.read<EventRepository>();
      final empty = repo.createEmpty(widget.initialDate);
      _draft = _EventDraft.fromEvent(empty);
    }
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: _draft.title);
    _descriptionController = TextEditingController(text: _draft.description);
    _locationController = TextEditingController(text: _draft.location);
    _rruleController = TextEditingController(text: _draft.rrule ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _rruleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Date/Time Pickers
  // ---------------------------------------------------------------------------

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _draft.start : _draft.end;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: current,
    );

    if (picked == null) return;

    setState(() {
      final time = _draft.isAllDay
          ? _draft.allDayNotificationTime
          : TimeOfDay.fromDateTime(current);

      final updated = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );

      if (isStart) {
        _draft.start = updated;
        _adjustEndDateIfNeeded();
      } else {
        _draft.end = updated;
        _ensureEndAfterStart();
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _draft.start : _draft.end;
    final use24Hour = shouldUse24HourFormat(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(alwaysUse24HourFormat: use24Hour),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      final updated = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );

      if (isStart) {
        _draft.start = updated;
        if (_draft.end.isBefore(updated)) {
          _draft.end = updated.add(const Duration(hours: 1));
        }
      } else {
        _draft.end = updated;
      }
    });
  }

  Future<void> _pickAllDayNotificationTime() async {
    final use24Hour = shouldUse24HourFormat(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: _draft.allDayNotificationTime,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(alwaysUse24HourFormat: use24Hour),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _draft.allDayNotificationTime = picked;
      _draft.start = DateTime(
        _draft.start.year,
        _draft.start.month,
        _draft.start.day,
        picked.hour,
        picked.minute,
      );
      _draft.end = DateTime(
        _draft.end.year,
        _draft.end.month,
        _draft.end.day,
        picked.hour,
        picked.minute,
      );
      _ensureEndAfterStart();
    });
  }

  void _adjustEndDateIfNeeded() {
    if (_draft.isAllDay) {
      if (!_draft.end.isAfter(_draft.start)) {
        _draft.end = _draft.start.add(const Duration(days: 1));
      } else {
        _draft.end = DateTime(
          _draft.end.year,
          _draft.end.month,
          _draft.end.day,
          _draft.allDayNotificationTime.hour,
          _draft.allDayNotificationTime.minute,
        );
      }
    } else if (_draft.end.isBefore(_draft.start)) {
      _draft.end = _draft.start.add(const Duration(hours: 1));
    }
  }

  void _ensureEndAfterStart() {
    if (_draft.isAllDay && !_draft.end.isAfter(_draft.start)) {
      _draft.end = _draft.start.add(const Duration(days: 1));
    }
  }

  // ---------------------------------------------------------------------------
  // Save Logic
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final event = _draft.toEvent(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      rrule: _buildRrule(),
    );

    final repo = context.read<EventRepository>();

    if (widget.isEditing) {
      await repo.updateEvent(event);
    } else {
      await repo.addEvent(event);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String? _buildRrule() {
    if (_draft.repeatChoice == RepeatChoice.none) return null;
    if (_draft.repeatChoice == RepeatChoice.custom) {
      final value = _rruleController.text.trim();
      return value.isEmpty ? null : value;
    }
    return _draft.repeatChoice.toRrule();
  }

  // ---------------------------------------------------------------------------
  // Build UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale);
    final timeFormat = timeFormatForLocale(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editEvent : l10n.addEvent),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: l10n.save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: l10n.title),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? l10n.titleRequired : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.description),
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Location field
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(labelText: l10n.location),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),

            // All-day toggle
            SwitchListTile(
              title: Text(l10n.allDay),
              value: _draft.isAllDay,
              onChanged: (value) => setState(() {
                _draft.isAllDay = value;
                if (value) {
                  _draft.allDayNotificationTime = TimeOfDay.fromDateTime(_draft.start);
                  _adjustEndDateIfNeeded();
                } else if (!_draft.end.isAfter(_draft.start)) {
                  _draft.end = _draft.start.add(const Duration(hours: 1));
                }
              }),
            ),

            const Divider(height: 24),

            // Start date/time
            _DateTimeTile(
              title: l10n.start,
              dateTime: _draft.start,
              isAllDay: _draft.isAllDay,
              dateFormat: dateFormat,
              timeFormat: timeFormat,
              onDateTap: () => _pickDate(isStart: true),
              onTimeTap: () => _pickTime(isStart: true),
            ),

            // End date/time
            _DateTimeTile(
              title: l10n.end,
              dateTime: _draft.end,
              isAllDay: _draft.isAllDay,
              dateFormat: dateFormat,
              timeFormat: timeFormat,
              onDateTap: () => _pickDate(isStart: false),
              onTimeTap: () => _pickTime(isStart: false),
            ),

            // All-day notification time
            if (_draft.isAllDay)
              ListTile(
                title: Text(l10n.notificationTime),
                subtitle: Text(formatTimeOfDay(context, _draft.allDayNotificationTime)),
                trailing: IconButton(
                  onPressed: _pickAllDayNotificationTime,
                  icon: const Icon(Icons.notifications_active),
                ),
              ),

            const Divider(height: 24),

            // Reminder dropdown
            _ReminderDropdown(
              value: _draft.reminderMinutes,
              onChanged: (value) => setState(() => _draft.reminderMinutes = value),
            ),

            const SizedBox(height: 16),

            // Repeat dropdown
            _RepeatDropdown(
              value: _draft.repeatChoice,
              onChanged: (value) => setState(() {
                _draft.repeatChoice = value ?? RepeatChoice.none;
                if (_draft.repeatChoice != RepeatChoice.custom) {
                  _rruleController.text = _draft.repeatChoice.toRrule() ?? '';
                }
              }),
            ),

            // Custom RRULE field
            if (_draft.repeatChoice == RepeatChoice.custom) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _rruleController,
                decoration: InputDecoration(
                  labelText: l10n.rrule,
                  hintText: l10n.rruleHint,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Save button
            FilledButton(
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Helper Widgets
// -----------------------------------------------------------------------------

/// Tile for displaying and editing date/time.
class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.title,
    required this.dateTime,
    required this.isAllDay,
    required this.dateFormat,
    required this.timeFormat,
    required this.onDateTap,
    required this.onTimeTap,
  });

  final String title;
  final DateTime dateTime;
  final bool isAllDay;
  final DateFormat dateFormat;
  final DateFormat timeFormat;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = isAllDay
        ? dateFormat.format(dateTime)
        : '${dateFormat.format(dateTime)} ${timeFormat.format(dateTime)}';

    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            onPressed: onDateTap,
            icon: const Icon(Icons.calendar_today),
          ),
          IconButton(
            onPressed: isAllDay ? null : onTimeTap,
            icon: const Icon(Icons.access_time),
          ),
        ],
      ),
    );
  }
}

/// Dropdown for reminder selection.
class _ReminderDropdown extends StatelessWidget {
  const _ReminderDropdown({
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: InputDecoration(labelText: l10n.reminderLabel),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.none)),
        DropdownMenuItem(value: 5, child: Text(l10n.reminder5min)),
        DropdownMenuItem(value: 10, child: Text(l10n.reminder10min)),
        DropdownMenuItem(value: 30, child: Text(l10n.reminder30min)),
        DropdownMenuItem(value: 60, child: Text(l10n.reminder1hour)),
      ],
      onChanged: onChanged,
    );
  }
}

/// Dropdown for repeat selection.
class _RepeatDropdown extends StatelessWidget {
  const _RepeatDropdown({
    required this.value,
    required this.onChanged,
  });

  final RepeatChoice value;
  final ValueChanged<RepeatChoice?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DropdownButtonFormField<RepeatChoice>(
      initialValue: value,
      decoration: InputDecoration(labelText: l10n.repeat),
      items: [
        DropdownMenuItem(value: RepeatChoice.none, child: Text(l10n.none)),
        DropdownMenuItem(value: RepeatChoice.daily, child: Text(l10n.daily)),
        DropdownMenuItem(value: RepeatChoice.weekly, child: Text(l10n.weekly)),
        DropdownMenuItem(value: RepeatChoice.monthly, child: Text(l10n.monthly)),
        DropdownMenuItem(value: RepeatChoice.yearly, child: Text(l10n.yearly)),
        DropdownMenuItem(value: RepeatChoice.custom, child: Text(l10n.customRrule)),
      ],
      onChanged: onChanged,
    );
  }
}

// -----------------------------------------------------------------------------
// Form State Model
// -----------------------------------------------------------------------------

/// Repeat frequency choices.
enum RepeatChoice {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom;

  /// Converts this choice to an RRULE string.
  String? toRrule() => switch (this) {
        RepeatChoice.none => null,
        RepeatChoice.daily => RRule.simple(RecurrenceFrequency.daily),
        RepeatChoice.weekly => RRule.simple(RecurrenceFrequency.weekly),
        RepeatChoice.monthly => RRule.simple(RecurrenceFrequency.monthly),
        RepeatChoice.yearly => RRule.simple(RecurrenceFrequency.yearly),
        RepeatChoice.custom => null,
      };

  /// Infers the repeat choice from an RRULE string.
  static RepeatChoice fromRrule(String? rrule) {
    if (rrule == null || rrule.isEmpty) return RepeatChoice.none;
    final upper = rrule.toUpperCase();
    if (upper.startsWith('FREQ=DAILY')) return RepeatChoice.daily;
    if (upper.startsWith('FREQ=WEEKLY')) return RepeatChoice.weekly;
    if (upper.startsWith('FREQ=MONTHLY')) return RepeatChoice.monthly;
    if (upper.startsWith('FREQ=YEARLY')) return RepeatChoice.yearly;
    return RepeatChoice.custom;
  }
}

/// Mutable draft state for event editing.
class _EventDraft {
  _EventDraft({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.start,
    required this.end,
    required this.isAllDay,
    required this.reminderMinutes,
    required this.rrule,
    required this.repeatChoice,
    required this.allDayNotificationTime,
  });

  factory _EventDraft.fromEvent(CalendarEvent event) {
    return _EventDraft(
      id: event.id,
      title: event.title,
      description: event.description,
      location: event.location,
      start: event.start,
      end: event.end,
      isAllDay: event.isAllDay,
      reminderMinutes: event.reminderMinutes,
      rrule: event.rrule,
      repeatChoice: RepeatChoice.fromRrule(event.rrule),
      allDayNotificationTime: TimeOfDay.fromDateTime(event.start),
    );
  }

  final String id;
  String title;
  String description;
  String location;
  DateTime start;
  DateTime end;
  bool isAllDay;
  int? reminderMinutes;
  String? rrule;
  RepeatChoice repeatChoice;
  TimeOfDay allDayNotificationTime;

  CalendarEvent toEvent({
    required String title,
    required String description,
    required String location,
    required String? rrule,
  }) {
    return CalendarEvent(
      id: id,
      title: title,
      description: description,
      location: location,
      start: start,
      end: end,
      isAllDay: isAllDay,
      reminderMinutes: reminderMinutes,
      rrule: rrule,
    );
  }
}

