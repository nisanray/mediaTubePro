import 'package:flutter/material.dart';
import '../../../../domain/entities/download_task.dart';

class PlaylistItemTile extends StatelessWidget {
  const PlaylistItemTile({super.key, required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
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
            Text('Speed: ${task.speed}'),
            if ((task.channel ?? '').isNotEmpty)
              Text(task.channel!, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (task.url.isNotEmpty)
              Text(task.url, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
