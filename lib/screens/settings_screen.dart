import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/event_repository.dart';
import '../services/ics_service.dart';
import '../services/settings_service.dart';
import '../services/subscription_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.icsService, required this.subscriptionService});

  final IcsService icsService;
  final SubscriptionService subscriptionService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _subscriptionController = TextEditingController();
  List<String> _subscriptions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _subscriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptions() async {
    final urls = await widget.subscriptionService.loadSubscriptions();
    setState(() {
      _subscriptions = urls;
    });
  }

  Future<void> _saveSubscriptions() async {
    await widget.subscriptionService.saveSubscriptions(_subscriptions);
  }

  Future<void> _importIcs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ics'],
      withData: kIsWeb,
    );
    if (result == null) return;
    final String content;
    if (kIsWeb) {
      final bytes = result.files.single.bytes;
      if (bytes == null) return;
      content = utf8.decode(bytes);
    } else {
      if (result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      content = await file.readAsString();
    }
    final events = widget.icsService.importFromIcs(content);
    if (!mounted) return;
    final repo = context.read<EventRepository>();
    await repo.importEvents(events);
  }

  Future<void> _exportIcs() async {
    final repo = context.read<EventRepository>();
    final content = widget.icsService.exportToIcs(repo.events);
    if (kIsWeb) {
      final bytes = Uint8List.fromList(utf8.encode(content));
      await FilePicker.platform.saveFile(
        dialogTitle: AppLocalizations.of(context)!.saveCalendarAs,
        fileName: 'calendar.ics',
        type: FileType.custom,
        allowedExtensions: ['ics'],
        bytes: bytes,
      );
    } else {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: AppLocalizations.of(context)!.saveCalendarAs,
        fileName: 'calendar.ics',
        type: FileType.custom,
        allowedExtensions: ['ics'],
      );
      if (path == null) return;
      if (!mounted) return;
      final file = File(path);
      await file.writeAsString(content);
    }
  }

  Future<void> _refreshSubscriptions() async {
    setState(() {
      _loading = true;
    });
    final repo = context.read<EventRepository>();
    final events = await widget.subscriptionService.fetchFromSubscriptions(_subscriptions);
    await repo.importEvents(events);
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  void _addSubscription() {
    final url = _subscriptionController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _subscriptions.add(url);
      _subscriptionController.clear();
    });
    _saveSubscriptions();
  }

  void _removeSubscription(int index) {
    setState(() {
      _subscriptions.removeAt(index);
    });
    _saveSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    SettingsService? settings;
    Locale? currentLocale;
    try {
      settings = context.watch<SettingsService>();
      currentLocale = settings.locale;
    } catch (_) {
      // Provider may not be present in test environment; fall back to null (system)
      settings = null;
      currentLocale = null;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(AppLocalizations.of(context)!.languageLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        RadioGroup<Locale?>(
          groupValue: currentLocale,
          onChanged: (val) => settings?.setLocale(val),
          child: Column(
            children: [
              RadioListTile<Locale?>(
                value: null,
                title: Text(AppLocalizations.of(context)!.languageSystemDefault),
              ),
              RadioListTile<Locale?>(
                value: const Locale('en'),
                title: Text(AppLocalizations.of(context)!.languageEnglish),
              ),
              RadioListTile<Locale?>(
                value: const Locale('zh'),
                title: Text(AppLocalizations.of(context)!.languageChinese),
              ),
            ],
          ),
        ),
        const Divider(height: 32),

        Text(AppLocalizations.of(context)!.importExport, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _importIcs,
          icon: const Icon(Icons.file_open),
          label: Text(AppLocalizations.of(context)!.importIcs),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _exportIcs,
          icon: const Icon(Icons.save),
          label: Text(AppLocalizations.of(context)!.exportIcs),
        ),
        const Divider(height: 32),
        Text(AppLocalizations.of(context)!.networkSubscriptions, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _subscriptionController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.subscribeUrl,
            hintText: AppLocalizations.of(context)!.subscribeUrlHint,
          ),
          onSubmitted: (_) => _addSubscription(),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _addSubscription,
          icon: const Icon(Icons.add_link),
          label: Text(AppLocalizations.of(context)!.addSubscription),
        ),
        const SizedBox(height: 8),
        if (_subscriptions.isEmpty)
          Text(AppLocalizations.of(context)!.noSubscriptions),
        for (final entry in _subscriptions.asMap().entries)
          ListTile(
            title: Text(entry.value),
            trailing: IconButton(
              onPressed: () => _removeSubscription(entry.key),
              icon: const Icon(Icons.delete),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _loading ? null : _refreshSubscriptions,
          icon: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh),
          label: Text(AppLocalizations.of(context)!.refreshSubscriptions),
        ),
      ],
    );
  }
}
