import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tcamp_calender/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads system locale when unset', () async {
    final service = SettingsService();
    await service.load();

    expect(service.locale, isNull);
  });

  test('persists and loads selected locale', () async {
    final service = SettingsService();
    await service.setLocale(const Locale('en'));

    final newService = SettingsService();
    await newService.load();

    expect(newService.locale?.languageCode, 'en');
  });
}
