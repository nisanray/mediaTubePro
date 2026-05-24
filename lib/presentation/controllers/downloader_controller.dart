import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/utils/binary_locator.dart';
import '../../../domain/entities/download_task.dart';
import 'dart:io';
import 'history_controller.dart';
import 'settings_controller.dart';
import '../../../data/datasources/process/ytdlp_datasource.dart';
import '../../../data/repositories/download_repository_impl.dart';

class DownloaderController extends GetxController {
  static bool persistenceEnabled = true;

  final urlController = TextEditingController();
  final RxString currentUrl = ''.obs;
  final RxBool singleVideoOnly = true.obs;
  final RxString detectedUrlKind = ''.obs;
  final RxString nextAddOverrideKind = ''.obs;

  // Replace the mock map with our strongly-typed Domain Entity
  final RxList<DownloadTask> downloadQueue = <DownloadTask>[].obs;

  // Map of active download subscriptions keyed by task id
  final Map<String, StreamSubscription<DownloadTask>> _activeDownloads = {};
  // Map of repositories to allow per-task cancellation
  final Map<String, DownloadRepositoryImpl> _taskRepositories = {};
  final Set<String> _cancelRequestedTaskIds = <String>{};

  @override
  void onInit() {
    super.onInit();
    if (persistenceEnabled) {
      // Load persisted queue
      try {
        final box = GetStorage();
        final raw = box.read('downloadQueue') as List<dynamic>?;
        if (raw != null) {
          final restored = raw
              .map(
                (e) =>
                    DownloadTask.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
          // Reset non-done tasks to pending
          for (final t in restored) {
            final normalized = (t.status == DownloadStatus.done)
                ? t
                : t.copyWith(status: DownloadStatus.pending);
            downloadQueue.add(normalized);
          }
          // Schedule any pending tasks
          _scheduleNext();
        }
      } catch (_) {}

      // Persist queue on changes
      ever(downloadQueue, (_) => _persistQueue());
    }

    urlController.addListener(() {
      final text = urlController.text.trim();
      currentUrl.value = text;
      _autoDetectUrlMode(text);
    });
  }

  Future<void> addToQueue() async {
    final normalizedUrl = currentUrl.value.trim();
    if (normalizedUrl.isEmpty) return;

    final overrideKind = nextAddOverrideKind.value.trim();
    final detectedKind = _detectUrlKind(normalizedUrl);
    final selectedKind = overrideKind.isNotEmpty
        ? overrideKind
        : (detectedKind ?? await _promptUnknownUrlKind());
    if (selectedKind == null) return;

    final isSingle = selectedKind != 'playlist';
    if (singleVideoOnly.value != isSingle) {
      singleVideoOnly.value = isSingle;
    }

    final detectionMeta = <String, dynamic>{
      'kind': selectedKind,
      'source': overrideKind.isNotEmpty
          ? 'override'
          : (detectedKind == null ? 'prompt' : 'auto'),
      'detectedAt': DateTime.now().toIso8601String(),
    };

    final newTask = DownloadTask(
      id: const Uuid().v4(),
      url: normalizedUrl,
      status: DownloadStatus.pending,
      singleVideoOnly: isSingle,
      metadata: {'linkDetection': detectionMeta},
    );

    downloadQueue.insert(0, newTask);
    urlController.clear();
    detectedUrlKind.value = '';
    nextAddOverrideKind.value = '';

    // Try to schedule downloads according to concurrency limits
    _scheduleNext();
  }

  void setNextAddOverrideKind(String? kind) {
    nextAddOverrideKind.value = (kind ?? '').trim();
  }

  Future<String?> _promptUnknownUrlKind() async {
    return Get.dialog<String>(
      AlertDialog(
        title: const Text('Choose link type'),
        content: const Text(
          'Could not auto-detect this URL. Download as single video or playlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<String?>(result: null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: 'playlist'),
            child: const Text('Playlist'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: 'single'),
            child: const Text('Single'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void _startDownload(DownloadTask task) {
    final settingsController = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;
    final historyController = Get.isRegistered<HistoryController>()
        ? Get.find<HistoryController>()
        : null;

    final repository = _buildRepository(settingsController);
    _taskRepositories[task.id] = repository;

    final outputFolder =
        settingsController?.defaultLocation.value ??
        r'C:\Users\Public\Downloads\MediaTube';
    final qualityLabel = settingsController?.quality.value ?? 'MediaTube';
    final qualityMode =
        settingsController?.videoQualityMode.value ??
        'Probing the video quality';
    final qualityFormat = _resolveQualityFormat(qualityLabel, qualityMode);
    final extractAudio = qualityLabel == 'Audio Only';

    final sub = repository
        .executeDownload(
          task,
          outputFolder,
          qualityFormat,
          qualityLabel,
          extractAudio: extractAudio,
          singleVideoOnly: task.singleVideoOnly,
        )
        .listen(
          (updatedTask) {
            final index = downloadQueue.indexWhere(
              (t) => t.id == updatedTask.id,
            );
            if (index != -1) {
              if (_cancelRequestedTaskIds.contains(updatedTask.id)) {
                downloadQueue[index] = downloadQueue[index].copyWith(
                  status: DownloadStatus.cancelled,
                  speed: 'Cancelled',
                  eta: '--',
                );
                return;
              }

              downloadQueue[index] = updatedTask;

              if (updatedTask.status == DownloadStatus.done) {
                historyController?.addFinishedTask(
                  updatedTask.filename,
                  updatedTask.url,
                  settingsController?.quality.value ?? qualityFormat,
                  false,
                  'Complete',
                  updatedTask.channel,
                  updatedTask.thumbnail,
                );

                if (settingsController?.notifications.value ?? false) {
                  Get.snackbar('Download Complete', updatedTask.filename);
                }
              }
              if (updatedTask.status == DownloadStatus.error) {
                // Show user-facing error
                Get.snackbar(
                  'Download Failed',
                  updatedTask.errorDetails,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.shade700,
                  colorText: Colors.white,
                );
              }
            }
          },
          onError: (err) {
            final index = downloadQueue.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              if (_cancelRequestedTaskIds.contains(task.id)) {
                downloadQueue[index] = downloadQueue[index].copyWith(
                  status: DownloadStatus.cancelled,
                  speed: 'Cancelled',
                  eta: '--',
                );
                return;
              }
              downloadQueue[index] = downloadQueue[index].copyWith(
                status: DownloadStatus.error,
                errorDetails: err.toString(),
              );
            }
          },
          onDone: () {
            // Cleanup and schedule next pending tasks
            _activeDownloads.remove(task.id)?.cancel();
            _taskRepositories.remove(task.id);
            _cancelRequestedTaskIds.remove(task.id);
            _scheduleNext();
          },
        );

    _activeDownloads[task.id] = sub;
  }

  void _scheduleNext() {
    final settingsController = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;
    final maxConcurrent =
        settingsController?.concurrentDownloads.value.toInt() ?? 3;

    while (_activeDownloads.length < maxConcurrent) {
      // Find the next pending task
      final pending = downloadQueue
          .where((t) => t.status == DownloadStatus.pending)
          .toList();
      if (pending.isEmpty) break;
      final next = pending.last; // FIFO: start the oldest pending

      // Mark as starting and begin download
      final idx = downloadQueue.indexWhere((t) => t.id == next.id);
      if (idx != -1) {
        downloadQueue[idx] = downloadQueue[idx].copyWith(
          status: DownloadStatus.downloading,
        );
      }
      _startDownload(next);
    }
  }

  void cancelAll() {
    for (int i = 0; i < downloadQueue.length; i++) {
      final task = downloadQueue[i];
      if (task.status == DownloadStatus.downloading ||
          task.status == DownloadStatus.pending ||
          task.status == DownloadStatus.merging) {
        _cancelRequestedTaskIds.add(task.id);
        downloadQueue[i] = task.copyWith(
          status: DownloadStatus.cancelled,
          speed: 'Cancelled',
          eta: '--',
        );
      }
    }

    // Cancel all active subscriptions and repositories
    for (final sub in _activeDownloads.values) {
      try {
        sub.cancel();
      } catch (_) {}
    }
    _activeDownloads.clear();

    for (final repo in _taskRepositories.values) {
      try {
        repo.cancelDownload();
      } catch (_) {}
    }
    _taskRepositories.clear();
  }

  void cancelTask(String taskId) {
    _cancelRequestedTaskIds.add(taskId);

    final sub = _activeDownloads[taskId];
    if (sub != null) {
      try {
        sub.cancel();
      } catch (_) {}
      _activeDownloads.remove(taskId);
    }

    final repo = _taskRepositories.remove(taskId);
    try {
      repo?.cancelDownload();
    } catch (_) {}

    final idx = downloadQueue.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      downloadQueue[idx] = downloadQueue[idx].copyWith(
        status: DownloadStatus.cancelled,
        speed: 'Cancelled',
        eta: '--',
      );
    }
    _scheduleNext();
  }

  void resumeTask(String taskId) {
    final idx = downloadQueue.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    final task = downloadQueue[idx];
    if (task.status != DownloadStatus.cancelled &&
        task.status != DownloadStatus.error) {
      return;
    }

    _cancelRequestedTaskIds.remove(taskId);

    downloadQueue[idx] = task.copyWith(
      status: DownloadStatus.pending,
      errorDetails: '',
      speed: '--',
      eta: '--',
    );
    _scheduleNext();
  }

  void retryTask(String taskId) {
    final idx = downloadQueue.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    final task = downloadQueue[idx];
    // Reset error state and increment retry count
    final newCount = task.retryCount + 1;
    _cancelRequestedTaskIds.remove(taskId);
    downloadQueue[idx] = task.copyWith(
      status: DownloadStatus.pending,
      errorDetails: '',
      retryCount: newCount,
      speed: '--',
      eta: '--',
    );

    // Exponential backoff before scheduling: min 60s
    final delaySeconds = (1 << (newCount - 1)) * 2; // 2,4,8,...
    final capped = delaySeconds > 60 ? 60 : delaySeconds;
    Future.delayed(Duration(seconds: capped), () {
      _scheduleNext();
    });
  }

  void removeTask(String taskId) {
    cancelTask(taskId);
    _cancelRequestedTaskIds.remove(taskId);
    downloadQueue.removeWhere((t) => t.id == taskId);
  }

  void clearCancelledTasks() {
    final cancelledIds = downloadQueue
        .where((t) => t.status == DownloadStatus.cancelled)
        .map((t) => t.id)
        .toList();
    for (final id in cancelledIds) {
      _cancelRequestedTaskIds.remove(id);
    }
    downloadQueue.removeWhere((t) => t.status == DownloadStatus.cancelled);
  }

  void resumeAll() {
    for (var i = 0; i < downloadQueue.length; i++) {
      final task = downloadQueue[i];
      if (task.status == DownloadStatus.cancelled ||
          task.status == DownloadStatus.error) {
        _cancelRequestedTaskIds.remove(task.id);
        downloadQueue[i] = task.copyWith(
          status: DownloadStatus.pending,
          errorDetails: '',
          speed: '--',
          eta: '--',
        );
      }
    }
    _scheduleNext();
  }

  void moveTaskToTop(String taskId) {
    final idx = downloadQueue.indexWhere((t) => t.id == taskId);
    if (idx <= 0) return;
    final task = downloadQueue.removeAt(idx);
    downloadQueue.insert(0, task);
  }

  void moveTaskToBottom(String taskId) {
    final idx = downloadQueue.indexWhere((t) => t.id == taskId);
    if (idx == -1 || idx == downloadQueue.length - 1) return;
    final task = downloadQueue.removeAt(idx);
    downloadQueue.add(task);
  }

  void restartTask(String taskId) {
    final idx = downloadQueue.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    cancelTask(taskId);
    final task = downloadQueue[idx];
    _cancelRequestedTaskIds.remove(taskId);
    downloadQueue[idx] = task.copyWith(
      status: DownloadStatus.pending,
      progress: 0.0,
      speed: '--',
      eta: '--',
      errorDetails: '',
      filename: 'Resolving...',
      items: task.singleVideoOnly ? task.items : const <DownloadTask>[],
    );
    _scheduleNext();
  }

  DownloadTask? findTaskById(String taskId) {
    final idx = downloadQueue.indexWhere((t) => t.id == taskId);
    if (idx == -1) return null;
    return downloadQueue[idx];
  }

  void _autoDetectUrlMode(String url) {
    final kind = _detectUrlKind(url);
    if (kind == null) {
      detectedUrlKind.value = '';
      return;
    }

    detectedUrlKind.value = kind;
    final shouldBeSingle = kind != 'playlist';
    if (singleVideoOnly.value != shouldBeSingle) {
      singleVideoOnly.value = shouldBeSingle;
    }
  }

  String? _detectUrlKind(String url) {
    if (url.isEmpty) return null;
    final lower = url.toLowerCase();

    if (lower.contains('youtube.com/playlist?') ||
        lower.contains('music.youtube.com/playlist?') ||
        lower.contains('youtube.com/shorts/') ||
        lower.contains('youtu.be/')) {
      if (lower.contains('playlist?') || lower.contains('list=')) {
        return 'playlist';
      }
      return 'single';
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null) return null;

    final hasList = parsed.queryParameters.containsKey('list');
    final hasVideo =
        parsed.queryParameters.containsKey('v') ||
        lower.contains('/watch') ||
        lower.contains('/shorts/');

    if (hasList && !hasVideo) return 'playlist';
    if (hasList && hasVideo) return 'playlist';
    if (hasVideo) return 'single';
    return null;
  }

  void _persistQueue() {
    if (!persistenceEnabled) return;
    try {
      final box = GetStorage();
      final serialized = downloadQueue.map((t) => t.toJson()).toList();
      box.write('downloadQueue', serialized);
    } catch (_) {}
  }

  Future<void> openFolderForTask(String taskId) async {
    final idx = downloadQueue.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = downloadQueue[idx];
    final filename = task.filename;
    if (filename.isEmpty || filename == 'Resolving...') return;

    final settingsController = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;
    final folder =
        settingsController?.defaultLocation.value ??
        r'C:\Users\Public\Downloads\MediaTube';
    final filePath = '$folder\\$filename';

    try {
      if (Platform.isWindows) {
        await Process.start('explorer', ["/select,", filePath]);
      } else if (Platform.isMacOS) {
        await Process.start('open', ['-R', filePath]);
      } else {
        await Process.start('xdg-open', [folder]);
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    cancelAll();
    urlController.dispose();
    super.onClose();
  }

  DownloadRepositoryImpl _buildRepository([SettingsController? settings]) {
    final customYtDlp = settings?.customYtDlp.value.trim() ?? '';
    final customFfmpeg = settings?.customFfmpeg.value.trim() ?? '';
    final ytDlpPath = customYtDlp.isNotEmpty
        ? customYtDlp
        : BinaryLocator.ytDlpPath;
    final ffmpegPath = customFfmpeg.isNotEmpty
        ? customFfmpeg
        : BinaryLocator.ffmpegPath;

    return DownloadRepositoryImpl(
      YtDlpDatasource(ytDlpPath: ytDlpPath, ffmpegPath: ffmpegPath),
    );
  }

  String _resolveQualityFormat(String qualityLabel, String qualityMode) {
    final probing = qualityMode == 'Probing the video quality';

    switch (qualityLabel) {
      case 'Best Available (4K/8K)':
        return probing
            ? 'bestvideo+bestaudio/best'
            : 'bestvideo[height<=4320]+bestaudio/best[height<=4320]';
      case '1080p Premium':
        return probing
            ? 'bestvideo+bestaudio/best'
            : 'bestvideo[height<=1080]+bestaudio/best[height<=1080]';
      case '720p Standard':
        return probing
            ? 'bestvideo+bestaudio/best'
            : 'bestvideo[height<=720]+bestaudio/best[height<=720]';
      case 'Audio Only':
        return 'bestaudio/best';
      default:
        return probing
            ? 'bestvideo+bestaudio/best'
            : 'bestvideo+bestaudio/best';
    }
  }
}
