import 'package:flutter_test/flutter_test.dart';

import 'package:tcamp_calender/services/lunar_service.dart';

void main() {
  test('formatLunar returns non-empty output for Chinese locale and empty for non-Chinese', () {
    const service = LunarService();
    final resultZh = service.formatLunar(DateTime(2026, 1, 17), locale: 'zh');
    expect(resultZh.isNotEmpty, true);

    final resultEn = service.formatLunar(DateTime(2026, 1, 17), locale: 'en');
    expect(resultEn, '');
  });

  test('formatFullLunar returns correct string for Chinese locale', () {
    const service = LunarService();
    // 2026-01-17 is 2025-11-29 in Lunar (approx check based on previous run)
    // Previous run said: 二〇二五年冬月廿九, YearGanZhi: 乙巳, YearShengXiao: 蛇
    // formatFullLunar format: 乙巳(蛇)年 冬月廿九
    final resultZh = service.formatFullLunar(DateTime(2026, 1, 17), locale: 'zh');
    expect(resultZh, contains('乙巳'));
    expect(resultZh, contains('蛇'));
    expect(resultZh, contains('冬月'));
    expect(resultZh, contains('廿九'));

    final resultEn = service.formatFullLunar(DateTime(2026, 1, 17), locale: 'en');
    expect(resultEn, '');
  });
}
