import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/binary_locator.dart';

class YtDlpDatasource {
  Process? _process;
  final String ytDlpPath;
  final String ffmpegPath;

  static const String _appName = 'MediaTube';

  YtDlpDatasource({String? ytDlpPath, String? ffmpegPath})
    : ytDlpPath = ytDlpPath ?? BinaryLocator.ytDlpPath,
      ffmpegPath = ffmpegPath ?? BinaryLocator.ffmpegPath;

  /// Spawns the process and yields a stream of raw string updates
  Stream<String> startDownload({
    required String url,
    required String outputFolder,
    required String qualityFormat,
    required String qualityLabel,
    bool extractAudio = false,
    bool singleVideoOnly = true,
    String? outputNameOverride,
  }) async* {
    Process? startedProcess;
    final safeQualityLabel = _sanitizeFilenamePart(qualityLabel);
    final safeAppName = _sanitizeFilenamePart(_appName);
    final safeOutputName = _sanitizeFilenamePart(outputNameOverride ?? '');
    final filenameStem = safeOutputName.isNotEmpty ? safeOutputName : '%(title)s';
    List<String> args = [
      '--print-json',
      '--no-warnings',
      url,
      '--newline', // Force newlines for easier stream parsing
      '--ignore-errors',
      '--no-colors',
      '-o',
      '$outputFolder/$filenameStem [$safeAppName] [$safeQualityLabel].%(ext)s',
    ];

    if (extractAudio) {
      args.addAll(['-x', '--audio-format', 'mp3', '--audio-quality', '320K']);
    } else {
      args.addAll(['-f', qualityFormat, '--merge-output-format', 'mkv']);
    }

    if (singleVideoOnly) {
      args.add('--no-playlist');
    } else {
      args.add('--yes-playlist');
    }

    if (ffmpegPath.isNotEmpty) {
      final ffmpegFile = File(ffmpegPath);
      final ffmpegDir = Directory(ffmpegPath);
      final ffmpegLocation = ffmpegFile.existsSync()
          ? ffmpegFile.parent.path
          : (ffmpegDir.existsSync()
                ? ffmpegDir.path
                : Directory(ffmpegPath).parent.path);

      args.addAll(['--ffmpeg-location', ffmpegLocation]);
    }

    try {
      if (ytDlpPath.trim().isNotEmpty) {
        final ytFile = File(ytDlpPath);
        final ytDir = Directory(ytDlpPath);
        final looksLikePath =
            ytDlpPath.contains(Platform.pathSeparator) ||
            ytDlpPath.contains('/');
        if (looksLikePath && !ytFile.existsSync() && !ytDir.existsSync()) {
          yield '[BINARY_ERROR] yt-dlp was not found at "$ytDlpPath". Open Settings and select a valid yt-dlp executable.';
          return;
        }
      }

      final process = await Process.start(ytDlpPath, args);
      startedProcess = process;
      _process = process;

      // Merge stdout and stderr into a single stream of lines
      final stream = StreamGroup.merge([
        process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
        process.stderr.transform(utf8.decoder).transform(const LineSplitter()),
      ]);

      await for (final line in stream) {
        yield line;
      }

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        yield '[EXEC_ERROR] yt-dlp exited with code $exitCode. Check the log file for details or verify your custom yt-dlp/FFmpeg paths.';
      } else {
        yield '[DONE]';
      }
    } on ProcessException catch (e) {
      yield '[BINARY_ERROR] Could not start yt-dlp: ${e.message}. Verify the selected executable in Settings.';
    } on FileSystemException catch (e) {
      yield '[BINARY_ERROR] yt-dlp/FFmpeg file access failed: ${e.message}. Check permissions and the selected binary path.';
    } catch (e) {
      yield '[FATAL] Unexpected download failure: $e';
    } finally {
      final process = startedProcess;
      if (process != null) {
        if (identical(_process, process)) {
          _process = null;
        }
      }
    }
  }

  void cancel({bool forceKill = true}) {
    final process = _process;
    _process = null;
    if (process == null) return;

    if (forceKill) {
      _killProcessTree(process);
      return;
    }

    _terminateProcess(process);
  }

  void _terminateProcess(Process process) {
    final terminated = process.kill(ProcessSignal.sigterm);
    if (terminated) {
      return;
    }
    try {
      process.kill(ProcessSignal.sigkill);
    } catch (_) {}
  }

  void _killProcessTree(Process process) {
    final pid = process.pid;

    if (Platform.isWindows) {
      unawaited(
        Process.run('taskkill', ['/PID', '$pid', '/T', '/F']).catchError((_) {
          try {
            process.kill(ProcessSignal.sigkill);
          } catch (_) {}
        }),
      );
      return;
    }

    // Unix/macOS: explicitly terminate child processes (e.g. ffmpeg)
    // spawned by yt-dlp before killing the parent process.
    unawaited(
      Process.run('pkill', [
        '-TERM',
        '-P',
        '$pid',
      ]).catchError((_) {}).whenComplete(() {
        final terminated = process.kill(ProcessSignal.sigterm);
        if (!terminated) {
          try {
            process.kill(ProcessSignal.sigkill);
          } catch (_) {}
          return;
        }

        unawaited(
          process.exitCode
              .timeout(
                const Duration(milliseconds: 400),
                onTimeout: () {
                  unawaited(
                    Process.run('pkill', [
                      '-KILL',
                      '-P',
                      '$pid',
                    ]).catchError((_) {}),
                  );
                  try {
                    process.kill(ProcessSignal.sigkill);
                  } catch (_) {}
                  return -1;
                },
              )
              .catchError((_) {}),
        );
      }),
    );
    return;
  }

  String _sanitizeFilenamePart(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'MediaTube';
    }

    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
  }
}

// Utility to merge streams
class StreamGroup {
  static Stream<T> merge<T>(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>();
    int completed = 0;
    for (final stream in streams) {
      stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          completed++;
          if (completed == streams.length) controller.close();
        },
      );
    }
    return controller.stream;
  }
}
