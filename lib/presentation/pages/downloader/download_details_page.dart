import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/download_task.dart';
import '../../controllers/downloader_controller.dart';
import 'widgets/playlist_item_tile.dart';

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
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            children: [
              Text(
                task.filename,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
              const SizedBox(height: 18),
              if (playlistItems.isNotEmpty) ...[
                Text(
                  'Playlist videos (${playlistItems.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ...playlistItems.map((child) => PlaylistItemTile(task: child)),
                const SizedBox(height: 18),
              ],
              Text('URL', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              SelectableText(task.url),
              const SizedBox(height: 18),
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
