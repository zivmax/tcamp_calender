import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// The application title shown in the app bar and window title.
  ///
  /// In en, this message translates to:
  /// **'TCamp Calendar'**
  String get appTitle;

  /// Label for the month view tab.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthLabel;

  /// Label for the week view tab.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekLabel;

  /// Label for the day view tab.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayLabel;

  /// Label for the settings page in the app.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// Displayed when there are no events for the selected date or range.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get noEvents;

  /// Button text for adding a new event.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// Lowercase variant of the add event action.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEventLower;

  /// Button text for editing an existing event.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// Label indicating the event lasts the whole day.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// Label for the event start time.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Label for the event end time.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// Represents no value or selection.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Reminder option: 5 minutes before the event.
  ///
  /// In en, this message translates to:
  /// **'5 minutes before'**
  String get reminder5min;

  /// Reminder option: 10 minutes before the event.
  ///
  /// In en, this message translates to:
  /// **'10 minutes before'**
  String get reminder10min;

  /// Reminder option: 30 minutes before the event.
  ///
  /// In en, this message translates to:
  /// **'30 minutes before'**
  String get reminder30min;

  /// Reminder option: 1 hour before the event.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get reminder1hour;

  /// Label for recurrence/ repeat settings.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// Recurrence option: daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// Recurrence option: weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// Recurrence option: monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// Recurrence option: yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// Label for entering a custom RRULE recurrence string.
  ///
  /// In en, this message translates to:
  /// **'Custom (RRULE)'**
  String get customRrule;

  /// Button text to save changes.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Label for the event title input.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Validation message when title is missing.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// Label for the event description input.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Label for the event location input.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Label for recurrence rule (RRULE) input.
  ///
  /// In en, this message translates to:
  /// **'RRULE'**
  String get rrule;

  /// Example RRULE hint to help the user compose a recurrence string.
  ///
  /// In en, this message translates to:
  /// **'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR'**
  String get rruleHint;

  /// Placeholder title used when an event has no title.
  ///
  /// In en, this message translates to:
  /// **'(Untitled)'**
  String get untitled;

  /// Shows how many minutes before the event the reminder is set.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {minutes} minutes before'**
  String reminderText(Object minutes);

  /// Label for reminder setting.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderLabel;

  /// Displays an RRULE recurrence string.
  ///
  /// In en, this message translates to:
  /// **'RRULE: {rrule}'**
  String rruleText(Object rrule);

  /// Title for the event details screen.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// Note explaining that changes affect all occurrences in a series.
  ///
  /// In en, this message translates to:
  /// **'Edits apply to the entire series.'**
  String get seriesEditsNote;

  /// Label showing the week start date.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String weekOf(Object date);

  /// Menu label for importing and exporting calendars.
  ///
  /// In en, this message translates to:
  /// **'Import & Export'**
  String get importExport;

  /// Action to import an ICS calendar file.
  ///
  /// In en, this message translates to:
  /// **'Import ICS'**
  String get importIcs;

  /// Action to export calendar data as ICS.
  ///
  /// In en, this message translates to:
  /// **'Export ICS'**
  String get exportIcs;

  /// Section label for data management actions.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataManagement;

  /// Button text to clear all app data.
  ///
  /// In en, this message translates to:
  /// **'Clear data'**
  String get clearDataAction;

  /// Dialog title confirming data deletion.
  ///
  /// In en, this message translates to:
  /// **'Clear app data'**
  String get clearDataTitle;

  /// Dialog message warning about data deletion.
  ///
  /// In en, this message translates to:
  /// **'This will delete all events, subscriptions, and settings on this device. This action cannot be undone.'**
  String get clearDataDescription;

  /// Label for cancel actions.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// Snackbar message shown after data is cleared.
  ///
  /// In en, this message translates to:
  /// **'Data cleared.'**
  String get dataCleared;

  /// Label for calendar subscriptions from network sources.
  ///
  /// In en, this message translates to:
  /// **'Network Subscriptions'**
  String get networkSubscriptions;

  /// Label for the subscription URL input.
  ///
  /// In en, this message translates to:
  /// **'Subscribe URL'**
  String get subscribeUrl;

  /// Example URL shown as a hint for subscription input.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/calendar.ics'**
  String get subscribeUrlHint;

  /// Button text to add a network subscription.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get addSubscription;

  /// Shown when no subscriptions have been added.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions added.'**
  String get noSubscriptions;

  /// Action to refresh subscriptions and fetch updates.
  ///
  /// In en, this message translates to:
  /// **'Refresh subscriptions'**
  String get refreshSubscriptions;

  /// Action to save calendar data under a different name.
  ///
  /// In en, this message translates to:
  /// **'Save calendar as'**
  String get saveCalendarAs;

  /// App name used in notifications.
  ///
  /// In en, this message translates to:
  /// **'TCamp Calendar'**
  String get notificationAppName;

  /// Name for the notification channel used for reminders.
  ///
  /// In en, this message translates to:
  /// **'Calendar Reminders'**
  String get notificationChannelName;

  /// Description of the notification channel for reminders.
  ///
  /// In en, this message translates to:
  /// **'Event reminders'**
  String get notificationChannelDescription;

  /// Label for selecting the notification time for all-day events.
  ///
  /// In en, this message translates to:
  /// **'Notification time'**
  String get notificationTime;

  /// Action label used in Linux desktop notifications.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get linuxActionOpen;

  /// Label for the language setting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Option to use the system's default language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// Language option for English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language option for Chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageChinese;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
