import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_event.dart';
import 'ics_service.dart';

/// Service for managing calendar URL subscriptions.
///
/// Supports loading events from remote ICS calendar URLs.
class SubscriptionService {
  /// Creates a subscription service.
  ///
  /// Optionally accepts a custom HTTP [client] for testing.
  SubscriptionService({
    required IcsService icsService,
    http.Client? client,
  })  : _icsService = icsService,
        _client = client ?? http.Client();

  static const String _storageKey = 'calendar_subscriptions';

  final IcsService _icsService;
  final http.Client _client;

  /// Loads the list of subscription URLs from storage.
  Future<List<String>> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_storageKey) ?? <String>[];
  }

  /// Saves the list of subscription URLs to storage.
  Future<void> saveSubscriptions(List<String> urls) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, urls);
  }

  /// Clears all saved subscription URLs.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Fetches and parses events from all subscription URLs.
  ///
  /// Silently skips URLs that fail to load.
  Future<List<CalendarEvent>> fetchFromSubscriptions(List<String> urls) async {
    final events = <CalendarEvent>[];

    for (final url in urls) {
      try {
        final fetchedEvents = await _fetchFromUrl(url);
        events.addAll(fetchedEvents);
      } catch (_) {
        // Skip failed subscriptions
        continue;
      }
    }

    return events;
  }

  Future<List<CalendarEvent>> _fetchFromUrl(String url) async {
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch subscription: ${response.statusCode}');
    }

    final content = utf8.decode(response.bodyBytes);
    return _icsService.importFromIcs(content);
  }
}

