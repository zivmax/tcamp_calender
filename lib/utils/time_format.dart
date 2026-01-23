import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

bool shouldUse24HourFormat(BuildContext context) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'zh') return true;
  if (locale.languageCode == 'en') return false;
  return MediaQuery.of(context).alwaysUse24HourFormat;
}

DateFormat timeFormatForLocale(BuildContext context) {
  final locale = Localizations.localeOf(context).toString();
  return shouldUse24HourFormat(context) ? DateFormat.Hm(locale) : DateFormat.jm(locale);
}

String formatTimeOfDay(BuildContext context, TimeOfDay timeOfDay) {
  final localizations = MaterialLocalizations.of(context);
  return localizations.formatTimeOfDay(
    timeOfDay,
    alwaysUse24HourFormat: shouldUse24HourFormat(context),
  );
}
