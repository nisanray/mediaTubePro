import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/download_task.dart';
import '../../controllers/downloader_controller.dart';
import 'widgets/playlist_item_tile.dart';
import 'widgets/playlist_selection_dialog.dart';

class DownloadDetailsPage extends StatelessWidget {
  const DownloadDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final initialTask = args is DownloadTask ? args : null;
    final ctrl = Get.isRegistered<DownloaderController>()
        ? Get.find<DownloaderController>()
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          final task = _resolveTask(ctrl, initialTask);
          return Text(
            task?.filename ?? 'Download Details',
            style: const TextStyle(color: AppColors.onSurface),
          );
        }),
      ),
      body: Obx(() {
        final task = _resolveTask(ctrl, initialTask);
        if (task == null) {
          return const Center(child: Text('No download data provided.'));
        }

        final playlistItems = task.items ?? const <DownloadTask>[];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(
                task.filename,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Chip(label: Text(task.status.name)),
                  Chip(
                    label: Text(
                      task.singleVideoOnly ? 'Single video' : 'Playlist',
                    ),
                  ),
                  Chip(label: Text('${(task.progress * 100).toInt()}%')),
                  Chip(label: Text(task.speed)),
                ],
              ),
              const SizedBox(height: 12),
              // Action row (wrap to avoid overflow on narrow viewports)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (ctrl != null) ctrl.resumeTask(task.id);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (ctrl != null) ctrl.cancelTask(task.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (ctrl != null) ctrl.retryTask(task.id);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (ctrl != null) {
                        await ctrl.openFolderForTask(task.id);
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open Folder'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: task.url));
                      Get.snackbar('Copied', 'URL copied to clipboard');
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy URL'),
                  ),
                  
                  // Rename
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ctrlLocal = ctrl;
                      final name = await Get.dialog<String>(
                        AlertDialog(
                          title: const Text('Rename output'),
                          content: TextField(
                            autofocus: true,
                            controller: TextEditingController(
                              text: task.filename,
                            ),
                            onSubmitted: (v) => Get.back(result: v),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Get.back(result: null),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      if (name != null &&
                          name.isNotEmpty &&
                          ctrlLocal != null) {
                        ctrlLocal.renameTask(task.id, name);
                      }
                    },
                    icon: const Icon(Icons.drive_file_rename_outline),
                    label: const Text('Rename'),
                  ),
                  // Quality picker
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final options = [
                        'Best Available (4K/8K)',
                        '1080p Premium',
                        '720p Standard',
                        'Audio Only',
                      ];
                      final picked = await Get.dialog<String>(
                        AlertDialog(
                          title: const Text('Choose quality'),
                          content: SizedBox(
                            width: 300,
                            child: ListView(
                              shrinkWrap: true,
                              children: options
                                  .map(
                                    (o) => RadioListTile<String>(
                                      value: o,
                                      groupValue:
                                          task.metadata?['selectedQuality']
                                              as String?,
                                      title: Text(o),
                                      onChanged: (v) => Get.back(result: v),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      );
                      if (picked != null && ctrl != null) {
                        ctrl.changeTaskQuality(task.id, picked);
                        Get.snackbar('Quality', 'Selected: $picked');
                      }
                    },
                    icon: const Icon(Icons.high_quality),
                    label: const Text('Quality'),
                  ),
                  // Select items (for playlists)
                  if (!task.singleVideoOnly) ...[
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Get.dialog(PlaylistSelectionDialog(parent: task));
                      },
                      icon: const Icon(Icons.playlist_play),
                      label: const Text('Select items'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (playlistItems.isNotEmpty) ...[
                Text(
                  'Playlist videos (${playlistItems.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...playlistItems.map((child) => PlaylistItemTile(task: child)),
                const SizedBox(height: 12),
              ],
              Text('URL', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              SelectableText(task.url),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  if (ctrl != null) {
                    await ctrl.openFolderForTask(task.id);
                  } else {
                    Get.snackbar(
                      'Open Folder',
                      'Unable to locate downloader controller',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Open Folder'),
              ),
            ],
          ),
        );
      }),
    );
  }

  DownloadTask? _resolveTask(
    DownloaderController? controller,
    DownloadTask? initial,
  ) {
    if (initial == null) return null;
    if (controller == null) return initial;

    return controller.findTaskById(initial.id) ?? initial;
  }
}
