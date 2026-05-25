import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mediatube_pro/main.dart';
import 'package:mediatube_pro/domain/entities/download_task.dart';
import 'package:mediatube_pro/presentation/controllers/downloader_controller.dart';

void main() {
  testWidgets('double-tap opens details and action buttons work', (
    WidgetTester tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    DownloaderController.persistenceEnabled = false;

    await tester.pumpWidget(const MediaTubeApp());
    await tester.pumpAndSettle();

    // Ensure downloader page created controller
    final ctrl = Get.find<DownloaderController>();

    // Create a playlist task with one child
    final child = DownloadTask(
      id: 'child-1',
      url: 'https://youtu.be/child',
      filename: 'Child Video',
      status: DownloadStatus.pending,
      singleVideoOnly: true,
    );

    final parent = DownloadTask(
      id: 'parent-1',
      url: 'https://youtube.com/playlist?list=PL',
      filename: 'My Playlist',
      status: DownloadStatus.cancelled,
      singleVideoOnly: false,
      items: [child],
    );

    // Insert into queue and rebuild
    ctrl.downloadQueue.insert(0, parent);
    await tester.pumpAndSettle();

    // Find the queue row by filename
    final finder = find.text('My Playlist');
    expect(finder, findsOneWidget);

    // Double-tap the row (two quick taps)
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(finder);
    await tester.pumpAndSettle();

    // Details page should show playlist count and child item
    expect(find.textContaining('Playlist videos'), findsOneWidget);
    expect(find.text('Child Video'), findsOneWidget);

    // Tap the Resume button to change status from cancelled -> not-cancelled
    final resumeBtn = find.widgetWithText(ElevatedButton, 'Resume');
    expect(resumeBtn, findsOneWidget);
    await tester.tap(resumeBtn);
    await tester.pumpAndSettle();

    // The controller may schedule the task immediately; assert it's no longer cancelled
    expect(ctrl.downloadQueue.first.status != DownloadStatus.cancelled, isTrue);
  });
}
