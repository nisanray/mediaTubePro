import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/downloader_controller.dart';
import '../../../../domain/entities/download_task.dart';

class PlaylistSelectionDialog extends StatefulWidget {
  const PlaylistSelectionDialog({super.key, required this.parent});

  final DownloadTask parent;

  @override
  State<PlaylistSelectionDialog> createState() => _PlaylistSelectionDialogState();
}

class _PlaylistSelectionDialogState extends State<PlaylistSelectionDialog> {
  late final DownloaderController? ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.isRegistered<DownloaderController>() ? Get.find<DownloaderController>() : null;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.parent.items ?? const <DownloadTask>[];
    final parentId = widget.parent.id;

    return AlertDialog(
      title: Text('Select videos from "${widget.parent.filename}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    ctrl?.selectAllPlaylistItems(parentId, true);
                    setState(() {});
                  },
                  child: const Text('Select all'),
                ),
                TextButton(
                  onPressed: () {
                    ctrl?.selectAllPlaylistItems(parentId, false);
                    setState(() {});
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final it = items[index];
                  final selected = ctrl?.selectedPlaylistItems(parentId).contains(it.id) ?? false;
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) {
                      ctrl?.togglePlaylistItemSelection(parentId, it.id);
                      setState(() {});
                    },
                    title: Text(it.filename),
                    subtitle: Text(it.channel ?? ''),
                    secondary: Text('${(it.progress * 100).toInt()}%'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (ctrl != null) {
              await ctrl!.queueSelectedPlaylistItems(parentId);
            }
            Navigator.of(context).pop();
          },
          child: const Text('Download selected'),
        ),
      ],
    );
  }
}
