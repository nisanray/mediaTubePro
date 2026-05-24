import 'package:flutter_test/flutter_test.dart';
import 'package:mediatube_pro/data/datasources/process/ytdlp_datasource.dart';
import 'package:mediatube_pro/data/repositories/download_repository_impl.dart';

class _FakeYtDlpDatasource extends YtDlpDatasource {
  _FakeYtDlpDatasource() : super(ytDlpPath: 'yt-dlp', ffmpegPath: 'ffmpeg');

  bool? lastForceKill;
  int cancelCalls = 0;

  @override
  void cancel({bool forceKill = true}) {
    cancelCalls += 1;
    lastForceKill = forceKill;
  }
}

void main() {
  test('cancelDownload forwards forceKill=false to datasource', () {
    final fakeDatasource = _FakeYtDlpDatasource();
    final repository = DownloadRepositoryImpl(fakeDatasource);

    repository.cancelDownload(forceKill: false);

    expect(fakeDatasource.cancelCalls, 1);
    expect(fakeDatasource.lastForceKill, isFalse);
  });

  test('cancelDownload defaults to forceKill=true', () {
    final fakeDatasource = _FakeYtDlpDatasource();
    final repository = DownloadRepositoryImpl(fakeDatasource);

    repository.cancelDownload();

    expect(fakeDatasource.cancelCalls, 1);
    expect(fakeDatasource.lastForceKill, isTrue);
  });
}
