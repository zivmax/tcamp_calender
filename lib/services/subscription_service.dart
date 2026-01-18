import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_event.dart';
import 'ics_service.dart';

class SubscriptionService {
  SubscriptionService({required IcsService icsService, http.Client? client})
      : _icsService = icsService,
        _client = client ?? http.Client();

  static const String _prefsKey = 'calendar_subscriptions';
  final IcsService _icsService;
  final http.Client _client;

  Future<List<String>> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey);
    return list ?? <String>[];
  }

  Future<void> saveSubscriptions(List<String> urls) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, urls);
  }

  Future<List<CalendarEvent>> fetchFromSubscriptions(List<String> urls) async {
    final events = <CalendarEvent>[];
    for (final url in urls) {
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        events.addAll(_icsService.importFromIcs(content));
      }
    }
    return events;
  }
}
