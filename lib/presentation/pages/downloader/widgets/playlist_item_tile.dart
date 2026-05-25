import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/download_task.dart';
import '../../../controllers/downloader_controller.dart';

class PlaylistItemTile extends StatelessWidget {
  const PlaylistItemTile({super.key, required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<DownloaderController>()
        ? Get.find<DownloaderController>()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        dense: true,
        title: Text(
          task.filename,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text('Status: ${task.status.name}'),
            Text('Progress: ${(task.progress * 100).toInt()}%'),
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
              child: LinearProgressIndicator(value: task.progress),
            ),
            Text('Speed: ${task.speed}'),
            if ((task.channel ?? '').isNotEmpty)
              Text(task.channel!, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (task.url.isNotEmpty)
              Text(task.url, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (ctrl == null) return;
            switch (value) {
              case 'resume':
                ctrl.resumeTask(task.id);
                break;
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
            const PopupMenuItem(value: 'resume', child: Text('Resume')),
            const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
            const PopupMenuItem(value: 'retry', child: Text('Retry')),
            const PopupMenuItem(value: 'open', child: Text('Open folder')),
            const PopupMenuItem(value: 'copy', child: Text('Copy URL')),
          ],
        ),
      ),
    );
  }
}
