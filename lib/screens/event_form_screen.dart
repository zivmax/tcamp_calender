import 'package:flutter/material.dart';
import 'package:tcamp_calender/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/calendar_event.dart';
import '../services/event_repository.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.event, required this.initialDate});

  final CalendarEvent? event;
  final DateTime initialDate;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late CalendarEvent _draft;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _rruleController;
  String _repeatChoice = 'none';
  late TimeOfDay _allDayNotificationTime;

  @override
  void initState() {
    super.initState();
    final repo = context.read<EventRepository>();
    _draft = widget.event ?? repo.createEmpty(widget.initialDate);

    _titleController = TextEditingController(text: _draft.title);
    _descriptionController = TextEditingController(text: _draft.description);
    _locationController = TextEditingController(text: _draft.location);
    _rruleController = TextEditingController(text: _draft.rrule ?? '');
    _repeatChoice = _inferRepeatChoice(_draft.rrule);
    _allDayNotificationTime = TimeOfDay.fromDateTime(_draft.start);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _rruleController.dispose();
    super.dispose();
  }

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
          ? _allDayNotificationTime
          : TimeOfDay.fromDateTime(current);
      final updated = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
      if (isStart) {
        _draft.start = updated;
        if (_draft.isAllDay) {
          if (!_draft.end.isAfter(updated)) {
            _draft.end = updated.add(const Duration(days: 1));
          } else {
            _draft.end = DateTime(
              _draft.end.year,
              _draft.end.month,
              _draft.end.day,
              time.hour,
              time.minute,
            );
          }
        } else if (_draft.end.isBefore(updated)) {
          _draft.end = updated.add(const Duration(hours: 1));
        }
      } else {
        _draft.end = updated;
        if (_draft.isAllDay && !_draft.end.isAfter(_draft.start)) {
          _draft.end = _draft.start.add(const Duration(days: 1));
        }
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _draft.start : _draft.end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null) return;
    setState(() {
      final updated = DateTime(current.year, current.month, current.day, picked.hour, picked.minute);
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
    final picked = await showTimePicker(
      context: context,
      initialTime: _allDayNotificationTime,
    );
    if (picked == null) return;
    setState(() {
      _allDayNotificationTime = picked;
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
      if (!_draft.end.isAfter(_draft.start)) {
        _draft.end = _draft.start.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _draft
      ..title = _titleController.text.trim()
      ..description = _descriptionController.text.trim()
      ..location = _locationController.text.trim();

    _draft.rrule = _buildRrule();

    final repo = context.read<EventRepository>();
    if (widget.event == null) {
      await repo.addEvent(_draft);
    } else {
      await repo.updateEvent(_draft);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale);
    final timeFormat = DateFormat.Hm(locale);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? AppLocalizations.of(context)!.addEvent : AppLocalizations.of(context)!.editEvent),
        actions: [ 
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
              validator: (value) => value == null || value.trim().isEmpty ? AppLocalizations.of(context)!.titleRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.location),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.allDay),
              value: _draft.isAllDay,
              onChanged: (value) {
                setState(() {
                  _draft.isAllDay = value;
                  if (value) {
                    _allDayNotificationTime = TimeOfDay.fromDateTime(_draft.start);
                    _draft.start = DateTime(
                      _draft.start.year,
                      _draft.start.month,
                      _draft.start.day,
                      _allDayNotificationTime.hour,
                      _allDayNotificationTime.minute,
                    );
                    if (!_draft.end.isAfter(_draft.start)) {
                      _draft.end = _draft.start.add(const Duration(days: 1));
                    } else {
                      _draft.end = DateTime(
                        _draft.end.year,
                        _draft.end.month,
                        _draft.end.day,
                        _allDayNotificationTime.hour,
                        _allDayNotificationTime.minute,
                      );
                    }
                  } else if (!_draft.end.isAfter(_draft.start)) {
                    _draft.end = _draft.start.add(const Duration(hours: 1));
                  }
                });
              },
            ),
            const Divider(height: 24),
            ListTile(
              title: Text(AppLocalizations.of(context)!.start),
              subtitle: Text(
                _draft.isAllDay
                    ? dateFormat.format(_draft.start)
                    : '${dateFormat.format(_draft.start)} ${timeFormat.format(_draft.start)}',
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.calendar_today),
                  ),
                  IconButton(
                    onPressed: _draft.isAllDay ? null : () => _pickTime(isStart: true),
                    icon: const Icon(Icons.access_time),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.end),
              subtitle: Text(
                _draft.isAllDay
                    ? dateFormat.format(_draft.end)
                    : '${dateFormat.format(_draft.end)} ${timeFormat.format(_draft.end)}',
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.calendar_today),
                  ),
                  IconButton(
                    onPressed: _draft.isAllDay ? null : () => _pickTime(isStart: false),
                    icon: const Icon(Icons.access_time),
                  ),
                ],
              ),
            ),
            if (_draft.isAllDay) ...[
              ListTile(
                title: Text(AppLocalizations.of(context)!.notificationTime),
                subtitle: Text(_allDayNotificationTime.format(context)),
                trailing: IconButton(
                  onPressed: _pickAllDayNotificationTime,
                  icon: const Icon(Icons.notifications_active),
                ),
              ),
            ],
            const Divider(height: 24),
            DropdownButtonFormField<int?>(
              initialValue: _draft.reminderMinutes,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.reminderLabel),
              items: [
                DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.none)),
                DropdownMenuItem(value: 5, child: Text(AppLocalizations.of(context)!.reminder5min)),
                DropdownMenuItem(value: 10, child: Text(AppLocalizations.of(context)!.reminder10min)),
                DropdownMenuItem(value: 30, child: Text(AppLocalizations.of(context)!.reminder30min)),
                DropdownMenuItem(value: 60, child: Text(AppLocalizations.of(context)!.reminder1hour)),
              ],
              onChanged: (value) {
                setState(() {
                  _draft.reminderMinutes = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _repeatChoice,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.repeat),
              items: [
                DropdownMenuItem(value: 'none', child: Text(AppLocalizations.of(context)!.none)),
                DropdownMenuItem(value: 'daily', child: Text(AppLocalizations.of(context)!.daily)),
                DropdownMenuItem(value: 'weekly', child: Text(AppLocalizations.of(context)!.weekly)),
                DropdownMenuItem(value: 'monthly', child: Text(AppLocalizations.of(context)!.monthly)),
                DropdownMenuItem(value: 'yearly', child: Text(AppLocalizations.of(context)!.yearly)),
                DropdownMenuItem(value: 'custom', child: Text(AppLocalizations.of(context)!.customRrule)),
              ],
              onChanged: (value) {
                setState(() {
                  _repeatChoice = value ?? 'none';
                  if (_repeatChoice != 'custom') {
                    _rruleController.text = _buildRruleFromChoice(_repeatChoice) ?? '';
                  }
                });
              },
            ),
            if (_repeatChoice == 'custom') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _rruleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.rrule,
                  hintText: AppLocalizations.of(context)!.rruleHint,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  String _inferRepeatChoice(String? rrule) {
    if (rrule == null || rrule.isEmpty) return 'none';
    final upper = rrule.toUpperCase();
    if (upper.startsWith('FREQ=DAILY')) return 'daily';
    if (upper.startsWith('FREQ=WEEKLY')) return 'weekly';
    if (upper.startsWith('FREQ=MONTHLY')) return 'monthly';
    if (upper.startsWith('FREQ=YEARLY')) return 'yearly';
    return 'custom';
  }

  String? _buildRrule() {
    if (_repeatChoice == 'none') return null;
    if (_repeatChoice == 'custom') {
      final value = _rruleController.text.trim();
      return value.isEmpty ? null : value;
    }
    return _buildRruleFromChoice(_repeatChoice);
  }

  String? _buildRruleFromChoice(String choice) {
    switch (choice) {
      case 'daily':
        return 'FREQ=DAILY;INTERVAL=1';
      case 'weekly':
        return 'FREQ=WEEKLY;INTERVAL=1';
      case 'monthly':
        return 'FREQ=MONTHLY;INTERVAL=1';
      case 'yearly':
        return 'FREQ=YEARLY;INTERVAL=1';
      default:
        return null;
    }
  }
}
