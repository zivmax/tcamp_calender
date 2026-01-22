// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TCamp Calendar';

  @override
  String get monthLabel => 'Month';

  @override
  String get weekLabel => 'Week';

  @override
  String get dayLabel => 'Day';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get noEvents => 'No events';

  @override
  String get addEvent => 'Add Event';

  @override
  String get addEventLower => 'Add event';

  @override
  String get editEvent => 'Edit Event';

  @override
  String get allDay => 'All day';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get none => 'None';

  @override
  String get reminder5min => '5 minutes before';

  @override
  String get reminder10min => '10 minutes before';

  @override
  String get reminder30min => '30 minutes before';

  @override
  String get reminder1hour => '1 hour before';

  @override
  String get repeat => 'Repeat';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get customRrule => 'Custom (RRULE)';

  @override
  String get save => 'Save';

  @override
  String get title => 'Title';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get description => 'Description';

  @override
  String get location => 'Location';

  @override
  String get rrule => 'RRULE';

  @override
  String get rruleHint => 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR';

  @override
  String get untitled => '(Untitled)';

  @override
  String reminderText(Object minutes) {
    return 'Reminder: $minutes minutes before';
  }

  @override
  String get reminderLabel => 'Reminder';

  @override
  String rruleText(Object rrule) {
    return 'RRULE: $rrule';
  }

  @override
  String get eventDetails => 'Event Details';

  @override
  String get seriesEditsNote => 'Edits apply to the entire series.';

  @override
  String weekOf(Object date) {
    return 'Week of $date';
  }

  @override
  String get importExport => 'Import & Export';

  @override
  String get importIcs => 'Import ICS';

  @override
  String get exportIcs => 'Export ICS';

  @override
  String get dataManagement => 'Data';

  @override
  String get clearDataAction => 'Clear data';

  @override
  String get clearDataTitle => 'Clear app data';

  @override
  String get clearDataDescription =>
      'This will delete all events, subscriptions, and settings on this device. This action cannot be undone.';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get dataCleared => 'Data cleared.';

  @override
  String get networkSubscriptions => 'Network Subscriptions';

  @override
  String get subscribeUrl => 'Subscribe URL';

  @override
  String get subscribeUrlHint => 'https://example.com/calendar.ics';

  @override
  String get addSubscription => 'Add subscription';

  @override
  String get noSubscriptions => 'No subscriptions added.';

  @override
  String get refreshSubscriptions => 'Refresh subscriptions';

  @override
  String get saveCalendarAs => 'Save calendar as';

  @override
  String get notificationAppName => 'TCamp Calendar';

  @override
  String get notificationChannelName => 'Calendar Reminders';

  @override
  String get notificationChannelDescription => 'Event reminders';

  @override
  String get notificationTime => 'Notification time';

  @override
  String get linuxActionOpen => 'Open';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => 'Chinese';
}
