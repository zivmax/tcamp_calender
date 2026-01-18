import 'package:lunar/lunar.dart';

/// Service for converting Gregorian dates to Chinese lunar calendar.
///
/// Only displays lunar dates when the locale indicates Chinese language.
class LunarService {
  const LunarService();

  /// Formats the lunar day for display in calendars.
  ///
  /// Returns the month name on the first day of the lunar month,
  /// otherwise returns the day name (e.g., "初一", "十五").
  ///
  /// Returns an empty string if the [locale] is not Chinese.
  String formatLunar(DateTime date, {String? locale}) {
    if (!_isChineseLocale(locale)) return '';

    final lunar = Solar.fromDate(date).getLunar();
    final day = lunar.getDayInChinese();

    // Show month name on the first day
    return day == '初一' ? '${lunar.getMonthInChinese()}月' : day;
  }

  /// Formats the full lunar date including year, month, and day.
  ///
  /// Example output: "甲辰(龙)年 正月初一"
  ///
  /// Returns an empty string if the [locale] is not Chinese.
  String formatFullLunar(DateTime date, {String? locale}) {
    if (!_isChineseLocale(locale)) return '';

    final lunar = Solar.fromDate(date).getLunar();

    return '${lunar.getYearInGanZhi()}'
        '(${lunar.getYearShengXiao()})年 '
        '${lunar.getMonthInChinese()}月'
        '${lunar.getDayInChinese()}';
  }

  bool _isChineseLocale(String? locale) {
    if (locale == null || locale.isEmpty) return false;
    final lang = locale.split('-').first.toLowerCase();
    return lang == 'zh';
  }
}

