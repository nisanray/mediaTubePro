import '../../../domain/entities/download_task.dart';

class PlaylistTaskTracker {
  PlaylistTaskTracker([List<DownloadTask>? initialItems])
    : _items = List<DownloadTask>.from(initialItems ?? const []);

  List<DownloadTask> _items;
  String? _activeItemId;

  List<DownloadTask> get items => List<DownloadTask>.unmodifiable(_items);

  String? get activeItemId => _activeItemId;

  bool get hasItems => _items.isNotEmpty;

  bool upsertFromJson(Map json) {
    final dynamic playlistIndexRaw = json['playlist_index'];
    final int? playlistIndex = playlistIndexRaw is num
        ? playlistIndexRaw.toInt()
        : int.tryParse('${playlistIndexRaw ?? ''}');

    final titleRaw = json['title']?.toString().trim();
    final title = (titleRaw == null || titleRaw.isEmpty)
        ? 'Resolving...'
        : titleRaw;
    final channel = (json['uploader'] ?? json['uploader_id'])?.toString();
    final thumbnail = json['thumbnail']?.toString();
    final webpageUrl =
        (json['webpage_url'] ?? json['url'] ?? json['original_url'])
            ?.toString();

    if (playlistIndex == null && webpageUrl == null) {
      return false;
    }

    final childId = playlistIndex != null
        ? 'playlist-$playlistIndex'
        : 'playlist-${webpageUrl.hashCode}';
    _activeItemId = childId;

    final existingIdx = _items.indexWhere((item) => item.id == childId);
    if (existingIdx == -1) {
      _items.add(
        DownloadTask(
          id: childId,
          url: webpageUrl ?? '',
          filename: title,
          status: DownloadStatus.pending,
          channel: channel,
          thumbnail: thumbnail,
          singleVideoOnly: true,
        ),
      );
      _items.sort((a, b) {
        final ai = _extractPlaylistIndex(a.id);
        final bi = _extractPlaylistIndex(b.id);
        return ai.compareTo(bi);
      });
      return true;
    }

    final existing = _items[existingIdx];
    final newFilename = title == 'Resolving...' ? existing.filename : title;
    final newUrl = (webpageUrl == null || webpageUrl.isEmpty)
        ? existing.url
        : webpageUrl;
    final updated = existing.copyWith(
      filename: newFilename,
      channel: channel ?? existing.channel,
      thumbnail: thumbnail ?? existing.thumbnail,
    );

    _items[existingIdx] = DownloadTask(
      id: existing.id,
      url: newUrl,
      filename: updated.filename,
      status: updated.status,
      progress: updated.progress,
      speed: updated.speed,
      eta: updated.eta,
      errorDetails: updated.errorDetails,
      logPath: updated.logPath,
      retryCount: updated.retryCount,
      items: updated.items,
      channel: updated.channel,
      thumbnail: updated.thumbnail,
      singleVideoOnly: updated.singleVideoOnly,
    );
    return true;
  }

  bool updateActiveItem(DownloadTask Function(DownloadTask item) updater) {
    final id = _activeItemId;
    if (id == null) {
      return false;
    }
    final idx = _items.indexWhere((item) => item.id == id);
    if (idx == -1) {
      return false;
    }
    _items[idx] = updater(_items[idx]);
    return true;
  }

  void markAllDone() {
    _items = _items
        .map(
          (item) => (item.status == DownloadStatus.done)
              ? item
              : item.copyWith(
                  status: DownloadStatus.done,
                  progress: 1.0,
                  speed: 'Done',
                  eta: '',
                ),
        )
        .toList();
  }

  int _extractPlaylistIndex(String id) {
    if (!id.startsWith('playlist-')) {
      return 1 << 20;
    }
    return int.tryParse(id.substring('playlist-'.length)) ?? (1 << 20);
  }
}
