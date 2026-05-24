enum DownloadStatus { pending, downloading, merging, done, error, cancelled }

class DownloadTask {
  final String id;
  final String url;
  final String filename;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final String speed;
  final String eta;
  final String errorDetails;
  final int retryCount;
  final String? logPath;
  final List<DownloadTask>? items; // for playlist entries
  final String? channel;
  final String? thumbnail;
  final bool singleVideoOnly;
  final Map<String, dynamic>? metadata;

  DownloadTask({
    required this.id,
    required this.url,
    this.filename = 'Resolving...',
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.speed = '--',
    this.eta = '--',
    this.errorDetails = '',
    this.logPath,
    this.retryCount = 0,
    this.items,
    this.channel,
    this.thumbnail,
    this.singleVideoOnly = true,
    this.metadata,
  });

  DownloadTask copyWith({
    String? filename,
    DownloadStatus? status,
    double? progress,
    String? speed,
    String? eta,
    String? errorDetails,
    String? logPath,
    int? retryCount,
    List<DownloadTask>? items,
    String? channel,
    String? thumbnail,
    bool? singleVideoOnly,
    Map<String, dynamic>? metadata,
  }) {
    return DownloadTask(
      id: id,
      url: url,
      filename: filename ?? this.filename,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
      errorDetails: errorDetails ?? this.errorDetails,
      logPath: logPath ?? this.logPath,
      retryCount: retryCount ?? this.retryCount,
      items: items ?? this.items,
      channel: channel ?? this.channel,
      thumbnail: thumbnail ?? this.thumbnail,
      singleVideoOnly: singleVideoOnly ?? this.singleVideoOnly,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'status': status.index,
      'progress': progress,
      'speed': speed,
      'eta': eta,
      'errorDetails': errorDetails,
      'logPath': logPath,
      'retryCount': retryCount,
      'items': items?.map((e) => e.toJson()).toList(),
      'channel': channel,
      'thumbnail': thumbnail,
      'singleVideoOnly': singleVideoOnly,
      'metadata': metadata,
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String,
      url: json['url'] as String,
      filename: json['filename'] as String? ?? 'Resolving...',
      status: DownloadStatus.values[(json['status'] as int?) ?? 0],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      speed: json['speed'] as String? ?? '--',
      eta: json['eta'] as String? ?? '--',
      errorDetails: json['errorDetails'] as String? ?? '',
      logPath: json['logPath'] as String?,
      retryCount: (json['retryCount'] as int?) ?? 0,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => DownloadTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      channel: json['channel'] as String?,
      thumbnail: json['thumbnail'] as String?,
      singleVideoOnly: json['singleVideoOnly'] as bool? ?? true,
      metadata: (json['metadata'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
  }
}
