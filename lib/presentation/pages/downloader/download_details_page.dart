import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/download_task.dart';
import '../../controllers/downloader_controller.dart';

class DownloadDetailsPage extends StatelessWidget {
  const DownloadDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    DownloadTask? task;
    if (args is DownloadTask) task = args;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Get.back(),
        ),
        title: Text(
          task?.filename ?? 'Download Details',
          style: const TextStyle(color: AppColors.onSurface),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: task == null
            ? const Center(child: Text('No download data provided.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.filename,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(label: Text(task.status.name)),
                      const SizedBox(width: 8),
                      // Show progress and current speed instead of undefined fields
                      Text('${(task.progress * 100).toInt()}%'),
                      const SizedBox(width: 12),
                      Text(task.speed),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // If this task has playlist items, show a collapsible list
                  if (task.items != null && task.items!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ExpansionTile(
                      title: Text('${task.items!.length} items'),
                      children: task.items!.map((child) {
                        return ListTile(
                          dense: true,
                          title: Text(
                            child.filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(child.status.name),
                          trailing: Text('${(child.progress * 100).toInt()}%'),
                          onTap: () {
                            // Navigate to a detail page for the child item
                            Get.toNamed('/download-details', arguments: child);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  Text('URL', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  SelectableText(task.url),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (task == null) return;
                      final ctrl = Get.isRegistered<DownloaderController>()
                          ? Get.find<DownloaderController>()
                          : null;
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
      ),
    );
  }
}
