import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/binary_locator.dart';
import '../../../core/utils/filename_utils.dart';
import '../../../domain/entities/download_task.dart';
import '../../controllers/downloader_controller.dart';
// settings_controller import removed; use Settings in sidebar
import '../../controllers/logs_controller.dart';
import 'dart:io';
import '../../widgets/main_right_sidebar.dart';
import '../../widgets/shared/mac_button.dart';
import '../../widgets/shared/mac_text_field.dart';

class DownloaderPage extends StatelessWidget {
  const DownloaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate controller locally for this view
    final controller = Get.put(DownloaderController());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar = constraints.maxWidth >= 980;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show binary initialization warnings if present
                    if (BinaryLocator.initError != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Binary setup needs attention. Open Settings and set custom yt-dlp / FFmpeg paths if bundled binaries are not available.',
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            MacButton(
                              text: 'Open Settings',
                              onPressed: () => Get.toNamed('/settings'),
                            ),
                          ],
                        ),
                      ),
                    // Header
                    LayoutBuilder(
                      builder: (context, headerConstraints) {
                        final isCompact = headerConstraints.maxWidth < 600;

                        final title = Text(
                          'Download Queue',
                          style: Theme.of(context).textTheme.titleLarge,
                        );

                        // (save location row removed - use Settings sidebar to change default)

                        final actions = Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            MacButton(
                              text: 'Resume All',
                              icon: Icons.play_arrow,
                              onPressed: () {
                                final ctrl = Get.find<DownloaderController>();
                                ctrl.resumeAll();
                                Get.snackbar(
                                  'Downloads',
                                  'Resumed cancelled and failed downloads',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                            MacButton(
                              text: 'Pause All',
                              icon: Icons.pause,
                              onPressed: () {
                                final ctrl = Get.find<DownloaderController>();
                                ctrl.cancelAll();
                                Get.snackbar(
                                  'Downloads',
                                  'All active downloads cancelled',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                            MacButton(
                              text: 'Clear Finished',
                              icon: Icons.clear_all,
                              onPressed: () {
                                final ctrl = Get.find<DownloaderController>();
                                ctrl.downloadQueue.removeWhere(
                                  (t) => t.status == DownloadStatus.done,
                                );
                                Get.snackbar(
                                  'Queue',
                                  'Cleared finished downloads',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                            MacButton(
                              text: 'Clear Cancelled',
                              icon: Icons.remove_circle_outline,
                              onPressed: () async {
                                final ctrl = Get.find<DownloaderController>();
                                final mode = await showDialog<String>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text(
                                      'Clear cancelled downloads',
                                    ),
                                    content: const Text(
                                      'Choose whether to clear only queue entries or also delete downloaded/partial files for cancelled tasks.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, 'queue_only'),
                                        child: const Text('Queue only'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, 'delete_files'),
                                        child: const Text('Delete files too'),
                                      ),
                                    ],
                                  ),
                                );

                                if (mode == null) return;

                                final result = await ctrl.clearCancelledTasks(
                                  deleteFiles: mode == 'delete_files',
                                );
                                final cleared = result['clearedTasks'] ?? 0;
                                final deletedFiles =
                                    result['deletedFiles'] ?? 0;
                                final deletedLogs = result['deletedLogs'] ?? 0;

                                Get.snackbar(
                                  'Queue',
                                  mode == 'delete_files'
                                      ? 'Cleared $cleared cancelled downloads, deleted $deletedFiles files and $deletedLogs logs'
                                      : 'Cleared $cleared cancelled downloads from queue',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                          ],
                        );

                        if (isCompact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              const SizedBox(height: 12),
                              actions,
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [title, actions],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // URL Input Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: MacTextField(
                                  controller: controller.urlController,
                                  hintText: 'Paste URL here...',
                                  prefixIcon: Icons.link,
                                ),
                              ),
                              const SizedBox(width: 12),
                              PopupMenuButton<String?>(
                                tooltip: 'Override next add',
                                onSelected: controller.setNextAddOverrideKind,
                                itemBuilder: (_) => const [
                                  PopupMenuItem<String?>(
                                    value: '',
                                    child: Text('Auto detect (default)'),
                                  ),
                                  PopupMenuItem<String?>(
                                    value: 'single',
                                    child: Text('Force single for next add'),
                                  ),
                                  PopupMenuItem<String?>(
                                    value: 'playlist',
                                    child: Text('Force playlist for next add'),
                                  ),
                                ],
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.outlineVariant,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.tune, size: 16),
                                      SizedBox(width: 6),
                                      Text('Mode'),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              MacButton(
                                text: 'Add to Queue',
                                isPrimary: true,
                                onPressed: () {
                                  controller.addToQueue();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Obx(() {
                            final kind = controller.detectedUrlKind.value;
                            final override =
                                controller.nextAddOverrideKind.value;
                            if (kind.isEmpty && override.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final parts = <String>[];
                            if (kind.isNotEmpty) {
                              parts.add(
                                kind == 'playlist'
                                    ? 'Detected: Playlist URL (playlist mode enabled)'
                                    : 'Detected: Single-video URL (single mode enabled)',
                              );
                            }
                            if (override.isNotEmpty) {
                              parts.add(
                                override == 'playlist'
                                    ? 'Override next add: Playlist'
                                    : 'Override next add: Single video',
                              );
                            }
                            return Text(
                              parts.join(' • '),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Queue Table
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'STATUS',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'FILENAME',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      'PROGRESS',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      'SPEED',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      'ACTION',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Table Body
                            Expanded(
                              child: Obx(
                                () => ListView.builder(
                                  itemCount: controller.downloadQueue.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        controller.downloadQueue[index];
                                    return GestureDetector(
                                      onDoubleTap: () => Get.toNamed(
                                        '/download-details',
                                        arguments: item,
                                      ),
                                      child: _buildQueueRow(context, item),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showSidebar) ...[
                const SizedBox(width: 16),
                const MainRightSidebar(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildQueueRow(BuildContext context, DownloadTask item) {
    final isDone = item.status == DownloadStatus.done;
    final isDownloading = item.status == DownloadStatus.downloading;
    final isMerging = item.status == DownloadStatus.merging;
    final hasError = item.status == DownloadStatus.error;
    final isCancelled = item.status == DownloadStatus.cancelled;

    IconData statusIcon = Icons.schedule;
    Color statusColor = AppColors.onSurfaceVariant;

    if (isDownloading) {
      statusIcon = Icons.downloading;
      statusColor = AppColors.primary;
    } else if (isMerging) {
      statusIcon = Icons.sync;
      statusColor = AppColors.tertiary;
    } else if (isDone) {
      statusIcon = Icons.done_all;
      statusColor = AppColors.success;
    } else if (hasError) {
      statusIcon = Icons.error_outline;
      statusColor = AppColors.error;
    } else if (isCancelled) {
      statusIcon = Icons.pause_circle_outline;
      statusColor = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDownloading
            ? AppColors.primaryContainer.withOpacity(0.05)
            : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status Icon
          SizedBox(
            width: 80,
            child: Center(
              child: isDone
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.folder_open, color: statusColor, size: 16),
                      ],
                    )
                  : Icon(statusIcon, color: statusColor, size: 20),
            ),
          ),

          // Filename & Meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prettyFilename(item.filename),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.retryCount > 0)
                  Text(
                    'Retries: ${item.retryCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                Text(
                  item.url,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                // Quality, Size, and Format badges
                Builder(
                  builder: (context) {
                    final meta = item.metadata ?? {};
                    String qualityRaw = '';
                    if (meta['quality'] is String &&
                        (meta['quality'] as String).isNotEmpty) {
                      qualityRaw = meta['quality'] as String;
                    } else if (meta['selectedQuality'] is String) {
                      qualityRaw = meta['selectedQuality'] as String;
                    }
                    String qualityShort = '';
                    final qMatch = RegExp(r"\d+p").firstMatch(qualityRaw);
                    if (qMatch != null) {
                      qualityShort = qMatch.group(0)!;
                    } else if (qualityRaw.toLowerCase().contains('audio')) {
                      qualityShort = 'Audio';
                    } else if (qualityRaw.isNotEmpty) {
                      qualityShort = qualityRaw.split(' ').first;
                    }

                    final size = (meta['size'] as String?) ?? '--';
                    final format = (meta['format'] as String?) ??
                        (item.filename.split('.').length > 1
                            ? item.filename.split('.').last
                            : '');

                    return Row(
                      children: [
                        if (qualityShort.isNotEmpty || size != '--')
                          Chip(
                            label: Text(
                              (qualityShort.isNotEmpty ? qualityShort : '') +
                                  (size != '--' ? ' • $size' : ''),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (format.isNotEmpty)
                          Chip(
                            label: Text(
                              format.toLowerCase(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (_detectedKindLabel(item) != null)
                  Text(
                    _detectedKindLabel(item)!,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Progress Bar
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isDone
                      ? '100%'
                      : isDownloading
                      ? '${(item.progress * 100).toInt()}%'
                      : isCancelled
                      ? 'Cancelled'
                      : 'Pending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDownloading
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: item.progress,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  color: isDone ? AppColors.success : AppColors.primary,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),

          // Speed & ETA
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.speed,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  item.eta,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Action Button: quick pause/resume + overflow menu
          SizedBox(
            width: 100,
            child: Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isDownloading ? 'Pause' : 'Resume',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    icon: Icon(
                      isDownloading ? Icons.pause : Icons.play_arrow,
                      size: 15,
                    ),
                    onPressed: () {
                      final controller = Get.find<DownloaderController>();
                      if (isDownloading) {
                        controller.cancelTask(item.id);
                      } else {
                        controller.resumeTask(item.id);
                      }
                    },
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    icon: Icon(
                      isDone
                          ? Icons.folder_open
                          : (hasError
                                ? Icons.refresh
                                : (isCancelled
                                      ? Icons.play_arrow
                                      : Icons.more_vert)),
                      size: 15,
                    ),
                    onSelected: (value) async {
                      final controller = Get.find<DownloaderController>();
                      if (value == 'open') {
                        await controller.openFolderForTask(item.id);
                      } else if (value == 'details') {
                        Get.toNamed('/download-details', arguments: item);
                      } else if (value == 'copy_url') {
                        await Clipboard.setData(ClipboardData(text: item.url));
                        Get.snackbar(
                          'Copied',
                          'URL copied to clipboard',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } else if (value == 'cancel') {
                        controller.cancelTask(item.id);
                      } else if (value == 'resume') {
                        controller.resumeTask(item.id);
                      } else if (value == 'retry') {
                        controller.retryTask(item.id);
                      } else if (value == 'restart') {
                        controller.restartTask(item.id);
                      } else if (value == 'move_top') {
                        controller.moveTaskToTop(item.id);
                      } else if (value == 'move_bottom') {
                        controller.moveTaskToBottom(item.id);
                      } else if (value == 'remove') {
                        controller.removeTask(item.id);
                      } else if (value == 'logs') {
                        // Read logs from the task's log file asynchronously and show dialog
                        if (item.logPath != null) {
                          try {
                            final f = File(item.logPath!);
                            if (await f.exists()) {
                              final lines = await f.readAsLines();
                              final parsedEntries = lines
                                  .map(
                                    (line) => LogsController.parseLogLine(
                                      line,
                                      fallbackSource: 'task:${item.id}',
                                    ),
                                  )
                                  .toList();

                              if (parsedEntries.isNotEmpty) {
                                final logsController = Get.put(
                                  LogsController(),
                                );

                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Logs'),
                                    content: SizedBox(
                                      width: 600,
                                      height: 300,
                                      child: SelectionArea(
                                        child: SingleChildScrollView(
                                          child: SelectableText.rich(
                                            TextSpan(
                                              children: parsedEntries
                                                  .map(
                                                    (entry) => TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              '${entry.timestamp} ',
                                                          style: const TextStyle(
                                                            fontFamily:
                                                                'JetBrains Mono',
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '[${entry.level}] ',
                                                          style: const TextStyle(
                                                            fontFamily:
                                                                'JetBrains Mono',
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${entry.message}\n',
                                                          style: const TextStyle(
                                                            fontFamily:
                                                                'JetBrains Mono',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                            style: const TextStyle(
                                              fontFamily: 'JetBrains Mono',
                                              fontSize: 13,
                                            ),
                                            onSelectionChanged:
                                                (selection, cause) {
                                                  if (selection.baseOffset <
                                                          0 ||
                                                      selection.extentOffset <
                                                          0) {
                                                    logsController
                                                        .updateSelectedText('');
                                                    return;
                                                  }

                                                  final start = selection.start;
                                                  final end = selection.end;
                                                  if (start == end) {
                                                    logsController
                                                        .updateSelectedText('');
                                                    return;
                                                  }

                                                  final plain = parsedEntries
                                                      .map(
                                                        LogsController
                                                            .formatLogEntry,
                                                      )
                                                      .join('\n');
                                                  logsController
                                                      .updateSelectedText(
                                                        plain,
                                                      );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Close'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          final txt =
                                              logsController.selectedText.value;
                                          if (txt.isNotEmpty) {
                                            Clipboard.setData(
                                              ClipboardData(text: txt),
                                            );
                                            Get.snackbar(
                                              'Copied',
                                              'Selected text copied to clipboard',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                            );
                                          }
                                        },
                                        child: const Text('Copy Selected'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          final all = parsedEntries
                                              .map(
                                                LogsController.formatLogEntry,
                                              )
                                              .join('\n');
                                          Clipboard.setData(
                                            ClipboardData(text: all),
                                          );
                                          Get.snackbar(
                                            'Copied',
                                            'All logs copied to clipboard',
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                        },
                                        child: const Text('Copy All'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          } catch (_) {}
                        }
                      }
                    },
                    itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                      const PopupMenuItem(
                        value: 'details',
                        child: Text('Details'),
                      ),
                      const PopupMenuItem(
                        value: 'copy_url',
                        child: Text('Copy URL'),
                      ),
                      const PopupMenuDivider(),
                      if (isDone)
                        const PopupMenuItem(
                          value: 'open',
                          child: Text('Open Folder'),
                        ),
                      if (!isDone && !isCancelled)
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Text('Cancel'),
                        ),
                      if (isCancelled)
                        const PopupMenuItem(
                          value: 'resume',
                          child: Text('Resume'),
                        ),
                      if (hasError)
                        const PopupMenuItem(
                          value: 'retry',
                          child: Text('Retry'),
                        ),
                      if (!isDownloading)
                        const PopupMenuItem(
                          value: 'restart',
                          child: Text('Restart'),
                        ),
                      if (!isDownloading)
                        const PopupMenuItem(
                          value: 'move_top',
                          child: Text('Move to Top'),
                        ),
                      if (!isDownloading)
                        const PopupMenuItem(
                          value: 'move_bottom',
                          child: Text('Move to Bottom'),
                        ),
                      if (isDone || isCancelled || hasError)
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove'),
                        ),
                      const PopupMenuItem(
                        value: 'logs',
                        child: Text('Show Logs'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _detectedKindLabel(DownloadTask item) {
    final metadata = item.metadata;
    if (metadata == null) return null;
    final linkDetection = metadata['linkDetection'];
    if (linkDetection is! Map) return null;
    final kind = linkDetection['kind']?.toString();
    if (kind == null || kind.isEmpty) return null;
    return kind == 'playlist' ? 'Type: Playlist' : 'Type: Single video';
  }
}
