import 'package:flutter_test/flutter_test.dart';

import 'package:tcamp_calender/screens/event_form_screen.dart';

void main() {
  test('RepeatChoice conversion from/to RRULE', () {
    expect(RepeatChoice.fromRrule(null), RepeatChoice.none);
    expect(RepeatChoice.fromRrule(''), RepeatChoice.none);
    expect(RepeatChoice.fromRrule('FREQ=DAILY'), RepeatChoice.daily);
    expect(RepeatChoice.fromRrule('FREQ=WEEKLY;INTERVAL=2'), RepeatChoice.weekly);
    expect(RepeatChoice.fromRrule('FREQ=MONTHLY'), RepeatChoice.monthly);
    expect(RepeatChoice.fromRrule('FREQ=YEARLY'), RepeatChoice.yearly);

    expect(RepeatChoice.daily.toRrule(), isNotNull);
    expect(RepeatChoice.weekly.toRrule(), isNotNull);
    expect(RepeatChoice.monthly.toRrule(), isNotNull);
    expect(RepeatChoice.yearly.toRrule(), isNotNull);
    expect(RepeatChoice.none.toRrule(), isNull);
    expect(RepeatChoice.custom.toRrule(), isNull);
  });
}
