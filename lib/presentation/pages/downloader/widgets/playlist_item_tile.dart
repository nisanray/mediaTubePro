import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../download_details_page.dart';
import '../../../../domain/entities/download_task.dart';
import '../../../controllers/downloader_controller.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/filename_utils.dart';

class PlaylistItemTile extends StatelessWidget {
  const PlaylistItemTile({super.key, required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<DownloaderController>()
        ? Get.find<DownloaderController>()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.small),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: GestureDetector(
        onDoubleTap: () {
          // Open details on double-tap (shows info + actions)
          Get.to(() => const DownloadDetailsPage(), arguments: task);
        },
        child: ListTile(
          dense: true,
          title: Text(
            prettyFilename(task.filename),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Spacing.xsmall),
              Text('Status: ${task.status.name}'),
              Text('Progress: ${(task.progress * 100).toInt()}%'),
              Padding(
                padding: const EdgeInsets.only(
                  top: Spacing.xsmall,
                  bottom: Spacing.xsmall,
                ),
                child: LinearProgressIndicator(value: task.progress),
              ),
              Text('Speed: ${task.speed}'),
              if ((task.channel ?? '').isNotEmpty)
                Text(
                  task.channel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (task.url.isNotEmpty)
                Text(task.url, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Single button toggles pause/resume depending on state
              IconButton(
                tooltip: task.status == DownloadStatus.downloading
                    ? 'Pause'
                    : 'Resume',
                icon: Icon(
                  task.status == DownloadStatus.downloading
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                onPressed: () {
                  if (ctrl == null) return;
                  if (task.status == DownloadStatus.downloading) {
                    // Treat pause as canceling the running task (it can be resumed)
                    ctrl.cancelTask(task.id);
                  } else {
                    ctrl.resumeTask(task.id);
                  }
                },
              ),
              // Keep a small overflow menu for other quick actions on long-press or tap
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (ctrl == null) return;
                  switch (value) {
                    case 'cancel':
                      ctrl.cancelTask(task.id);
                      break;
                    case 'retry':
                      ctrl.retryTask(task.id);
                      break;
                    case 'open':
                      await ctrl.openFolderForTask(task.id);
                      break;
                    case 'copy':
                      Clipboard.setData(ClipboardData(text: task.url));
                      Get.snackbar('Copied', 'URL copied to clipboard');
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
                  const PopupMenuItem(value: 'retry', child: Text('Retry')),
                  const PopupMenuItem(
                    value: 'open',
                    child: Text('Open folder'),
                  ),
                  const PopupMenuItem(value: 'copy', child: Text('Copy URL')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
