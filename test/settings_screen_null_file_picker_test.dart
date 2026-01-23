import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tcamp_calendar/screens/settings_screen.dart';
import 'package:tcamp_calendar/services/ics_service.dart';

import 'test_helpers.dart';

class _NullFilePicker extends FilePicker {
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return null;
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool lockParentWindow = false,
    String? initialDirectory,
    Uint8List? bytes,
  }) async {
    return null;
  }
}

void main() {
  testWidgets('SettingsScreen handles null file picker results', (tester) async {
    FilePicker.platform = _NullFilePicker();

    const icsService = IcsService();

    await tester.pumpWidget(
      buildTestApp(
        child: SettingsScreen(
          icsService: icsService,
          subscriptionService: TestSubscriptionService(icsService: icsService),
        ),
        repo: TestEventRepository(notificationService: TestNotificationService()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import ICS'));
    await tester.pump();

    await tester.tap(find.text('Export ICS'));
    await tester.pump();
  });
}
