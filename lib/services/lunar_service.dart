import 'package:lunar/lunar.dart';

class LunarService {
  const LunarService();

  bool _isChineseLocale(String? locale) {
    if (locale == null || locale.isEmpty) return false;
    final lang = locale.split('-').first.toLowerCase();
    return lang == 'zh';
  }

  /// Formats the lunar date only when the [locale] indicates Chinese language.
  /// When not Chinese, returns an empty string so callers can choose not to display it.
  String formatLunar(DateTime date, {String? locale}) {
    if (!_isChineseLocale(locale)) return '';

    final solar = Solar.fromDate(date);
    final lunar = solar.getLunar();
    final day = lunar.getDayInChinese();
    if (day == '初一') {
      return '${lunar.getMonthInChinese()}月';
    }
    return day;
  }

  /// Formats the full lunar date (Year + Month + Day)
  String formatFullLunar(DateTime date, {String? locale}) {
    if (!_isChineseLocale(locale)) return '';

    final solar = Solar.fromDate(date);
    final lunar = solar.getLunar();
    return '${lunar.getYearInGanZhi()}(${lunar.getYearShengXiao()})年 ${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
  }
}
