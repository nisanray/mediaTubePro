import 'package:flutter_test/flutter_test.dart';
import 'package:mediatube_pro/presentation/controllers/logs_controller.dart';

void main() {
  test('parseLogLine handles JSONL download output', () {
    final entry = LogsController.parseLogLine(
      '{"ts":"2026-05-23T10:15:30.000Z","line":"[download]  42.0% of 10.0MiB at 1.2MiB/s ETA 00:12"}',
    );

    expect(entry.timestamp, isNotEmpty);
    expect(entry.level, 'INFO');
    expect(entry.message, contains('[download]'));
  });

  test('parseLogLine converts explicit binary errors to ERR', () {
    final entry = LogsController.parseLogLine(
      '[BINARY_ERROR] yt-dlp was not found at "C:/Tools/yt-dlp.exe".',
    );

    expect(entry.level, 'ERR');
    expect(entry.message, contains('yt-dlp was not found'));
  });
}
