import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings with persistence.
///
/// Currently supports locale/language settings.
class SettingsService extends ChangeNotifier {
  static const String _localeKey = 'language_code';
  static const String _systemLocaleValue = 'system';

  Locale? _locale;

  /// The current locale, or null for system default.
  Locale? get locale => _locale;

  /// Loads settings from persistent storage.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);

    _locale = (code == null || code == _systemLocaleValue)
        ? null
        : Locale(code);

    notifyListeners();
  }

  /// Sets the app locale.
  ///
  /// Pass null to use the system default locale.
  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _localeKey,
      locale?.languageCode ?? _systemLocaleValue,
    );

    _locale = locale;
    notifyListeners();
  }
}

