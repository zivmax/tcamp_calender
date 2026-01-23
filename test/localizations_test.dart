import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tcamp_calendar/l10n/app_localizations.dart';
import 'package:tcamp_calendar/l10n/app_localizations_en.dart';
import 'package:tcamp_calendar/l10n/app_localizations_zh.dart';

void main() {
  void exerciseLocalizations(AppLocalizations l10n) {
    l10n.appTitle;
    l10n.monthLabel;
    l10n.weekLabel;
    l10n.dayLabel;
    l10n.settingsLabel;
    l10n.noEvents;
    l10n.addEvent;
    l10n.addEventLower;
    l10n.editEvent;
    l10n.allDay;
    l10n.start;
    l10n.end;
    l10n.none;
    l10n.reminder5min;
    l10n.reminder10min;
    l10n.reminder30min;
    l10n.reminder1hour;
    l10n.repeat;
    l10n.daily;
    l10n.weekly;
    l10n.monthly;
    l10n.yearly;
    l10n.customRrule;
    l10n.save;
    l10n.title;
    l10n.titleRequired;
    l10n.description;
    l10n.location;
    l10n.rrule;
    l10n.rruleHint;
    l10n.untitled;
    l10n.reminderLabel;
    l10n.eventDetails;
    l10n.seriesEditsNote;
    l10n.importExport;
    l10n.importIcs;
    l10n.exportIcs;
    l10n.networkSubscriptions;
    l10n.subscribeUrl;
    l10n.subscribeUrlHint;
    l10n.addSubscription;
    l10n.noSubscriptions;
    l10n.refreshSubscriptions;
    l10n.saveCalendarAs;
    l10n.notificationAppName;
    l10n.notificationChannelName;
    l10n.notificationChannelDescription;
    l10n.notificationTime;
    l10n.linuxActionOpen;
    l10n.languageLabel;
    l10n.languageSystemDefault;
    l10n.languageEnglish;
    l10n.languageChinese;

    l10n.reminderText(10);
    l10n.rruleText('FREQ=DAILY');
    l10n.weekOf(1);
  }

  test('English and Chinese localizations execute all getters', () {
    exerciseLocalizations(AppLocalizationsEn());
    exerciseLocalizations(AppLocalizationsZh());
  });

  test('AppLocalizations delegate supports locales and loads', () async {
    expect(AppLocalizations.supportedLocales.length, greaterThanOrEqualTo(2));
    expect(AppLocalizations.localizationsDelegates.isNotEmpty, isTrue);

    expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('zh')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('fr')), isFalse);

    expect(AppLocalizations.delegate.shouldReload(AppLocalizations.delegate),
      isFalse);

    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final zh = await AppLocalizations.delegate.load(const Locale('zh'));

    expect(en.localeName, 'en');
    expect(zh.localeName, 'zh');
  });

  testWidgets('AppLocalizations.of returns instance from context',
      (tester) async {
    AppLocalizations? captured;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            captured = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(captured, isNotNull);
  });

  test('lookupAppLocalizations throws for unsupported locale', () {
    expect(() => lookupAppLocalizations(const Locale('fr')),
        throwsA(isA<FlutterError>()));
  });
}
