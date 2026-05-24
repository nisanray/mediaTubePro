import 'package:flutter_test/flutter_test.dart';
import 'package:mediatube_pro/domain/entities/download_task.dart';

void main() {
  test('DownloadTask serialization roundtrip', () {
    final t = DownloadTask(
      id: 'abc',
      url: 'https://example.com',
      filename: 'video.mp4',
      status: DownloadStatus.pending,
      progress: 0.5,
      speed: '1MB/s',
      eta: '00:01:23',
      errorDetails: '',
      logPath: '/tmp/log.jsonl',
      retryCount: 2,
      metadata: {
        'linkDetection': {'kind': 'playlist', 'source': 'auto'},
      },
    );

    final json = t.toJson();
    final t2 = DownloadTask.fromJson(json);

    expect(t2.id, t.id);
    expect(t2.url, t.url);
    expect(t2.filename, t.filename);
    expect(t2.status, t.status);
    expect(t2.progress, t.progress);
    expect(t2.speed, t.speed);
    expect(t2.eta, t.eta);
    expect(t2.logPath, t.logPath);
    expect(t2.retryCount, t.retryCount);
    expect(t2.metadata?['linkDetection']?['kind'], 'playlist');
    expect(t2.metadata?['linkDetection']?['source'], 'auto');
  });
}
