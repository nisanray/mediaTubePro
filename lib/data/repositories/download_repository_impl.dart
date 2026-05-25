import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../domain/entities/download_task.dart';
import 'playlist_task_tracker.dart';
import '../datasources/process/ytdlp_datasource.dart';

class DownloadRepositoryImpl {
  final YtDlpDatasource _datasource;

  // Regex patterns to match yt-dlp output
  static final _progressRegex = RegExp(
    r'\[download\]\s+(?<percent>\d+\.\d+)%\s+of\s+~?(?<size>\d+\.\d+[a-zA-Z]+)\s+at\s+(?<speed>\d+\.\d+[a-zA-Z]+/s)\s+ETA\s+(?<eta>\d+:\d+)',
  );
  static final _destRegex = RegExp(
    r'\[download\] Destination: (?<filename>.*)',
  );
  static final _mergeRegex = RegExp(
    r'\[Merger\] Merging formats into "(?<filename>.*)"',
  );

  DownloadRepositoryImpl(this._datasource);

  Stream<DownloadTask> executeDownload(
    DownloadTask initialTask,
    String outputFolder,
    String format,
    String qualityLabel, {
    bool extractAudio = false,
    bool singleVideoOnly = true,
    String? outputNameOverride,
  }) async* {
    DownloadTask currentTask = initialTask.copyWith(
      status: DownloadStatus.downloading,
    );
    final playlistTracker = PlaylistTaskTracker(currentTask.items);
    yield currentTask;

    // Prepare a per-task log file under application support
    final supportDir = await getApplicationSupportDirectory();
    final logDir = Directory(p.join(supportDir.path, 'MediaTube_Logs'));
    if (!await logDir.exists()) await logDir.create(recursive: true);
    final logFile = File(p.join(logDir.path, '${initialTask.id}.jsonl'));
    final logPath = logFile.path;
    // Ensure file exists
    await logFile.create(recursive: true);

    final outputStream = _datasource.startDownload(
      url: initialTask.url,
      outputFolder: outputFolder,
      qualityFormat: format,
      qualityLabel: qualityLabel,
      extractAudio: extractAudio,
      singleVideoOnly: singleVideoOnly,
      outputNameOverride: outputNameOverride,
    );

    await for (final line in outputStream) {
      // append log line as JSON object to the jsonl file
      final entry = jsonEncode({
        'ts': DateTime.now().toIso8601String(),
        'line': line,
      });
      await logFile.writeAsString(
        '$entry\n',
        mode: FileMode.append,
        flush: true,
      );
      // Try to parse structured JSON lines first (yt-dlp can emit JSON
      // progress/status lines). If parsing succeeds, prefer the structured
      // values over brittle regex matches.
      try {
        final trimmed = line.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            if (!singleVideoOnly) {
              if (playlistTracker.upsertFromJson(decoded)) {
                currentTask = currentTask.copyWith(
                  items: playlistTracker.items,
                  logPath: logPath,
                );
                yield currentTask;
              }
            }

            // Capture uploader/channel and thumbnail if present in yt-dlp JSON
            final uploader = decoded['uploader'] ?? decoded['uploader_id'];
            final thumbnail = decoded['thumbnail'];
            if (uploader != null || thumbnail != null) {
              currentTask = currentTask.copyWith(
                channel: uploader?.toString(),
                thumbnail: thumbnail?.toString(),
                logPath: logPath,
              );
              // yield an update so UI/history can pick up channel/thumbnail early
              yield currentTask;
              // continue processing other possible keys
            }

            // Filename / destination
            if (decoded.containsKey('filename') ||
                decoded.containsKey('destination')) {
              final rawFname = decoded['filename'] ?? decoded['destination'];
              final base = rawFname.toString().split('/').last.split('\\').last;
              final decorated = _decorateFilename(
                base,
                qualityLabel,
                outputNameOverride: outputNameOverride,
              );
              currentTask = currentTask.copyWith(filename: decorated);
              if (!singleVideoOnly &&
                  playlistTracker.updateActiveItem(
                    (item) => item.copyWith(
                      filename: decorated,
                      status: DownloadStatus.downloading,
                    ),
                  )) {
                currentTask = currentTask.copyWith(
                  items: playlistTracker.items,
                );
              }
              yield currentTask;
              continue;
            }

            // Progress updates
            final status = decoded['status']?.toString().toLowerCase();
            if (status == 'downloading' ||
                decoded.containsKey('percent') ||
                decoded.containsKey('percentage') ||
                decoded.containsKey('progress')) {
              double progress = 0.0;
              if (decoded['percent'] != null) {
                progress =
                    (double.tryParse(decoded['percent'].toString()) ?? 0.0) /
                    100.0;
              } else if (decoded['percentage'] != null) {
                progress =
                    (double.tryParse(decoded['percentage'].toString()) ?? 0.0) /
                    100.0;
              } else if (decoded['progress'] is num) {
                final p = decoded['progress'] as num;
                progress = (p > 1.0) ? (p / 100.0) : p.toDouble();
              }

              currentTask = currentTask.copyWith(
                progress: progress,
                speed: decoded['speed']?.toString() ?? currentTask.speed,
                eta: decoded['eta']?.toString() ?? currentTask.eta,
                status: DownloadStatus.downloading,
              );
              if (!singleVideoOnly &&
                  playlistTracker.updateActiveItem(
                    (item) => item.copyWith(
                      progress: progress,
                      speed: decoded['speed']?.toString() ?? item.speed,
                      eta: decoded['eta']?.toString() ?? item.eta,
                      status: DownloadStatus.downloading,
                    ),
                  )) {
                currentTask = currentTask.copyWith(
                  items: playlistTracker.items,
                );
              }
              yield currentTask;
              continue;
            }

            if (status == 'finished' || status == 'completed') {
              if (!singleVideoOnly &&
                  playlistTracker.updateActiveItem(
                    (item) => item.copyWith(
                      status: DownloadStatus.done,
                      progress: 1.0,
                      speed: 'Done',
                      eta: '',
                    ),
                  )) {
                currentTask = currentTask.copyWith(
                  items: playlistTracker.items,
                  status: DownloadStatus.downloading,
                );
                yield currentTask;
                continue;
              }

              currentTask = currentTask.copyWith(
                status: DownloadStatus.done,
                progress: 1.0,
                speed: 'Done',
                eta: '',
              );
              yield currentTask;
              continue;
            }
          }
        }
      } catch (_) {
        // Ignore JSON parse errors and fall back to text parsing below.
      }

      // 1. Check for filename resolution
      final destMatch = _destRegex.firstMatch(line);
      if (destMatch != null) {
        final raw = destMatch.namedGroup('filename')!;
        final base = raw.split('/').last.split('\\').last;
        currentTask = currentTask.copyWith(
          filename: _decorateFilename(
            base,
            qualityLabel,
            outputNameOverride: outputNameOverride,
          ),
          logPath: logPath,
        );
        if (!singleVideoOnly &&
            playlistTracker.updateActiveItem(
              (item) => item.copyWith(
                filename: _decorateFilename(
                  base,
                  qualityLabel,
                  outputNameOverride: outputNameOverride,
                ),
                status: DownloadStatus.downloading,
              ),
            )) {
          currentTask = currentTask.copyWith(items: playlistTracker.items);
        }
        yield currentTask;
        continue;
      }

      // 2. Parse Progress, Speed, and ETA
      final progMatch = _progressRegex.firstMatch(line);
      if (progMatch != null) {
        final percentStr = progMatch.namedGroup('percent') ?? '0';
        final speed = progMatch.namedGroup('speed') ?? '--';
        final eta = progMatch.namedGroup('eta') ?? '--';

        currentTask = currentTask.copyWith(
          progress: (double.tryParse(percentStr) ?? 0.0) / 100.0,
          speed: speed,
          eta: eta,
          status: DownloadStatus.downloading,
          logPath: logPath,
        );
        if (!singleVideoOnly &&
            playlistTracker.updateActiveItem(
              (item) => item.copyWith(
                progress: (double.tryParse(percentStr) ?? 0.0) / 100.0,
                speed: speed,
                eta: eta,
                status: DownloadStatus.downloading,
              ),
            )) {
          currentTask = currentTask.copyWith(items: playlistTracker.items);
        }
        yield currentTask;
        continue;
      }

      // 3. Handle Merging state (ffmpeg taking over)
      if (line.contains('[Merger]') || line.contains('Extracting audio')) {
        // Try to capture merged filename via regex
        final mergeMatch = _mergeRegex.firstMatch(line);
        if (mergeMatch != null) {
          final raw = mergeMatch.namedGroup('filename')!;
          final base = raw.split('/').last.split('\\').last;
          currentTask = currentTask.copyWith(
            filename: _decorateFilename(
              base,
              qualityLabel,
              outputNameOverride: outputNameOverride,
            ),
            status: DownloadStatus.merging,
            progress: 1.0,
            speed: 'Merging...',
            eta: '--',
            logPath: logPath,
          );
        } else {
          currentTask = currentTask.copyWith(
            status: DownloadStatus.merging,
            progress: 1.0,
            speed: 'Merging...',
            eta: '--',
            logPath: logPath,
          );
        }
        if (!singleVideoOnly &&
            playlistTracker.updateActiveItem(
              (item) => item.copyWith(
                status: DownloadStatus.merging,
                progress: 1.0,
                speed: 'Merging...',
                eta: '--',
              ),
            )) {
          currentTask = currentTask.copyWith(items: playlistTracker.items);
        }
        yield currentTask;
        continue;
      }

      // 4. Handle Completion or Errors
      if (line == '[DONE]') {
        if (!singleVideoOnly && playlistTracker.hasItems) {
          playlistTracker.markAllDone();
        }
        currentTask = currentTask.copyWith(
          status: DownloadStatus.done,
          progress: 1.0,
          speed: 'Done',
          eta: '',
          logPath: logPath,
          items: playlistTracker.items,
        );
        yield currentTask;
      } else if (line.startsWith('[ERROR]') ||
          line.startsWith('[FATAL]') ||
          line.startsWith('[BINARY_ERROR]') ||
          line.startsWith('[EXEC_ERROR]')) {
        final friendly = _friendlyErrorMessage(line);
        currentTask = currentTask.copyWith(
          status: DownloadStatus.error,
          errorDetails: friendly,
          logPath: logPath,
        );
        yield currentTask;
      }
    }
  }

  String _friendlyErrorMessage(String line) {
    if (line.startsWith('[BINARY_ERROR]')) {
      return line.replaceFirst('[BINARY_ERROR] ', '');
    }
    if (line.startsWith('[EXEC_ERROR]')) {
      return line.replaceFirst('[EXEC_ERROR] ', '');
    }
    if (line.startsWith('[FATAL]')) {
      return line.replaceFirst('[FATAL] ', '');
    }
    if (line.startsWith('[ERROR]')) {
      return line.replaceFirst('[ERROR] ', '');
    }
    return 'Download failed. Open the log file for more details.';
  }

  void cancelDownload({bool forceKill = true}) {
    _datasource.cancel(forceKill: forceKill);
  }

  String _decorateFilename(
    String baseFilename,
    String qualityLabel, {
    String? outputNameOverride,
  }) {
    // Preserve extension
    final dot = baseFilename.lastIndexOf('.');
    final name = dot > 0 ? baseFilename.substring(0, dot) : baseFilename;
    final ext = dot > 0 ? baseFilename.substring(dot) : '';

    // Clean quality label for filename safety
    final q = qualityLabel.trim().isEmpty ? 'Unknown' : qualityLabel.trim();

    // Prefer the requested output name for display if provided.
    final displayName =
        (outputNameOverride != null && outputNameOverride.trim().isNotEmpty)
        ? outputNameOverride.trim()
        : name;

    // Avoid double-appending if already contains app name
    final appTag = 'MediaTube';
    if (baseFilename.toLowerCase().contains(appTag.toLowerCase())) {
      return baseFilename;
    }

    final qSanitized = q.replaceAll(' ', '_');
    var decorated = '${displayName}_$qSanitized_$appTag$ext';
    return decorated;
  }
}
