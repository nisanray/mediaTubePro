import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../controllers/history_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/downloader_controller.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../widgets/shared/glass_panel.dart';
import '../../widgets/shared/mac_button.dart';
import '../../../core/theme/spacing.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  static const _statusFilters = <({String key, String label, IconData icon})>[
    (key: 'all', label: 'All', icon: Icons.view_list_rounded),
    (key: 'success', label: 'Success', icon: Icons.check_circle_rounded),
    (key: 'failed', label: 'Failed', icon: Icons.error_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HistoryController());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download History',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
              Row(
                children: [
                  Obx(
                    () => Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Text(
                        'Showing ${controller.historyList.length} downloads',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  MacButton(
                    text: 'Clear All',
                    icon: Icons.delete_sweep,
                    onPressed: controller.clearHistory,
                  ),
                  const SizedBox(width: 8),
                  MacButton(
                    text: 'Reset Filter',
                    icon: Icons.filter_alt_off,
                    onPressed: () => controller.setStatusFilter('all'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status chips area (wraps to next line on narrow widths)
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _statusFilters.map((filter) {
                      final isSelected =
                          controller.statusFilter.value == filter.key;
                      final count = controller.countForStatus(filter.key);
                      final backgroundColor = isSelected
                          ? AppColors.primaryContainer
                          : AppColors.surfaceContainerLow;
                      final foregroundColor = isSelected
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant;

                      return InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => controller.setStatusFilter(filter.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.chipHorizontal,
                            vertical: Spacing.chipVertical,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.4)
                                  : AppColors.outlineVariant,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(
                                        0.08,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : const [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                filter.icon,
                                size: 16,
                                color: foregroundColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                filter.label,
                                style: TextStyle(
                                  color: foregroundColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.15)
                                      : AppColors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    color: foregroundColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(width: 12),

                // Channel dropdown (fixed height to match chips)
                SizedBox(
                  height: 36,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.channelFilter.value == 'all'
                            ? 'all'
                            : controller.channelFilter.value,
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All channels'),
                          ),
                          ...controller.availableChannels.map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          controller.setChannelFilter(v);
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox.shrink(),
              ],
            );
          }),

          const SizedBox(height: 12),

          const SizedBox(height: 12),

          // Glass Panel Table
          Expanded(
            child: GlassPanel(
              padding: EdgeInsets.zero,
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
                      border: Border(
                        bottom: BorderSide(color: AppColors.outlineVariant),
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
                            'FILENAME / TITLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'FORMAT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            'QUALITY • SIZE',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: Text(
                            'DATE',
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
                    child: Obx(() {
                      if (controller.historyList.isEmpty) {
                        return const Center(
                          child: Text(
                            'No download history yet.',
                            style: TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                        );
                      }
                      final visibleHistory = controller.filteredHistory;
                      if (visibleHistory.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_alt_off_rounded,
                                color: AppColors.onSurfaceVariant.withOpacity(
                                  0.6,
                                ),
                                size: 28,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No downloads match the selected status.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: visibleHistory.length,
                        itemBuilder: (context, index) {
                          final entry = visibleHistory[index];
                          final key = ValueKey(
                            entry['id'] ?? entry['url'] ?? index,
                          );
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SizeTransition(
                                sizeFactor: anim,
                                axisAlignment: 0.0,
                                child: child,
                              ),
                            ),
                            child: KeyedSubtree(
                              key: key,
                              child: _buildHistoryRow(entry),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // Pagination removed to allow more vertical scrolling space
        ],
      ),
    );
  }

  Widget _buildHistoryRow(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'success').toString();
    final isSuccess = status == 'success';
    final displayTitle = _resolveDisplayTitle(item);
    final displayFormat = _resolveExactFormat(item);
    final isAudio = item['isAudio'] == true || _isAudioFormat(displayFormat);

    final statusLabel = isSuccess ? 'Success' : 'Failed';
    final statusIcon = isSuccess ? Icons.check_circle : Icons.error;
    final statusBg = isSuccess
        ? AppColors.success.withOpacity(0.55)
        : AppColors.errorContainer.withOpacity(0.55);
    final statusFg = isSuccess
        ? AppColors.onPrimaryContainer
        : AppColors.onErrorContainer;

    return AnimatedContainer(
      key: ValueKey(item['id'] ?? item['url'] ?? item['date']),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.transparent
            : AppColors.errorContainer.withOpacity(0.18),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSuccess
                          ? AppColors.success.withOpacity(0.25)
                          : AppColors.error.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusFg, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusFg,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Thumbnail & Title
          Expanded(
            child: Row(
              children: [
                // Thumbnail Container (fixed size for consistent rows)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                    image: item['thumbnail'] != null && isSuccess
                        ? DecorationImage(
                            image: NetworkImage(item['thumbnail']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (item['thumbnail'] == null || !isSuccess)
                      ? Center(
                          child: Icon(
                            isAudio
                                ? Icons.audio_file
                                : Icons.image_not_supported,
                            size: 18,
                            color: AppColors.onSurfaceVariant,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Channel and URL: inline, compact and ellipsized
                      Row(
                        children: [
                          if (item['channel'] != null)
                            Flexible(
                              flex: 2,
                              child: Text(
                                item['channel'],
                                style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (item['channel'] != null) const SizedBox(width: 8),
                          Flexible(
                            flex: 5,
                            child: Text(
                              item['url'],
                              style: TextStyle(
                                color: isSuccess
                                    ? AppColors.onSurfaceVariant
                                    : AppColors.error,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Format Badge
          SizedBox(
            width: 92,
            child: Center(
              child: Container(
                height: 32,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: !isSuccess
                      ? AppColors.surfaceContainerHighest
                      : isAudio
                      ? AppColors.tertiaryContainer
                      : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayFormat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: !isSuccess
                        ? AppColors.onSurfaceVariant
                        : isAudio
                        ? AppColors.onTertiaryContainer
                        : AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),

          // Quality • Size
          SizedBox(
            width: 120,
            child: Text(
              _buildQualitySizeText(item, (item['title'] ?? '').toString()),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),

          // Date
          SizedBox(
            width: 130,
            child: Text(
              item['date'],
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),

          // Action Button
          SizedBox(
            width: 60,
            child: Center(
              child: IconButton(
                icon: Icon(
                  isSuccess ? Icons.folder_open : Icons.refresh,
                  size: 18,
                ),
                color: AppColors.onSurfaceVariant,
                splashRadius: 18,
                tooltip: isSuccess ? 'Open Folder' : 'Retry',
                onPressed: () async {
                  final settingsCtrl = Get.isRegistered<SettingsController>()
                      ? Get.find<SettingsController>()
                      : null;
                  if (isSuccess) {
                    // try to open the default save location
                    final folder = settingsCtrl?.defaultLocation.value;
                    if (folder != null && folder.isNotEmpty) {
                      try {
                        if (Platform.isWindows) {
                          await Process.start('explorer', [folder]);
                        } else if (Platform.isMacOS) {
                          await Process.start('open', [folder]);
                        } else {
                          await Process.start('xdg-open', [folder]);
                        }
                      } catch (_) {}
                    }
                  } else {
                    // Retry via downloader controller
                    final downloader = Get.isRegistered<DownloaderController>()
                        ? Get.find<DownloaderController>()
                        : null;
                    if (downloader != null) {
                      // Use controller API to queue the retry so scheduling works as expected
                      downloader.urlController.text = item['url'] ?? '';
                      await downloader.addToQueue();
                      Get.snackbar(
                        'Retry',
                        'Queued for retry',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveDisplayTitle(Map<String, dynamic> item) {
    final raw = (item['title'] ?? '').toString().trim();
    if (raw.isEmpty) return 'Untitled';

    // Keep the title clean for history rows (remove app tags / premium noise).
    var title = raw;
    title = title.replaceAll(
      RegExp(r'\[[^\]]*(mediatube|premium)[^\]]*\]', caseSensitive: false),
      '',
    );
    title = title.replaceAll('_', ' ');
    title = title.replaceAll(
      RegExp(r'\s*[-_]?\s*MediaTube\s*$', caseSensitive: false),
      '',
    );
    title = title.replaceAll(RegExp(r'\.[A-Za-z0-9]{2,5}$'), '');
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    return title.isEmpty ? raw : title;
  }

  String _resolveExactFormat(Map<String, dynamic> item) {
    final title = (item['title'] ?? '').toString();
    final rawFormat = (item['format'] ?? '').toString().trim();

    final extFromTitle = _extractExtension(title);
    if (extFromTitle.isNotEmpty) return extFromTitle;

    final extFromFormat = _extractExtension(rawFormat);
    if (extFromFormat.isNotEmpty) return extFromFormat;

    if (rawFormat.isNotEmpty &&
        RegExp(r'^[A-Za-z0-9]{2,8}$').hasMatch(rawFormat)) {
      return rawFormat;
    }
    return '--';
  }

  String _extractExtension(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final cleanName = trimmed.split('/').last.split('\\').last;
    final dot = cleanName.lastIndexOf('.');
    if (dot <= 0 || dot == cleanName.length - 1) return '';

    final ext = cleanName.substring(dot + 1).trim();
    if (RegExp(r'^[A-Za-z0-9]{2,8}$').hasMatch(ext)) {
      return ext;
    }
    return '';
  }

  String _buildQualitySizeText(
    Map<String, dynamic> item,
    String fallbackTitle,
  ) {
    final quality = _resolveRealQuality(item, fallbackTitle);
    final rawSize = _resolveDisplaySize(item);
    final hasSize = rawSize.isNotEmpty && rawSize != '--' && rawSize != '—';

    if (quality.isNotEmpty && hasSize) return '$quality • $rawSize';
    if (quality.isNotEmpty) return quality;
    if (hasSize) return rawSize;
    return '--';
  }

  String _resolveDisplaySize(Map<String, dynamic> item) {
    final savedSize = (item['size'] ?? '').toString().trim();
    final needsLookup =
        savedSize.isEmpty ||
        savedSize == '--' ||
        savedSize == '—' ||
        savedSize.toLowerCase() == 'complete';

    if (!needsLookup) return savedSize;

    final rawTitle = (item['title'] ?? '').toString().trim();
    if (rawTitle.isEmpty) return '--';

    final settingsCtrl = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;
    final folder =
        settingsCtrl?.defaultLocation.value ??
        r'C:\Users\Public\Downloads\MediaTube';

    try {
      final file = File(p.join(folder, rawTitle));
      if (file.existsSync()) {
        return _formatBytes(file.lengthSync());
      }
    } catch (_) {}

    return savedSize.toLowerCase() == 'complete' ? '--' : savedSize;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var index = 0;

    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }

    final precision = value >= 100 ? 0 : (value >= 10 ? 1 : 2);
    return '${value.toStringAsFixed(precision)} ${units[index]}';
  }

  String _resolveRealQuality(Map<String, dynamic> item, String fallbackTitle) {
    final candidates = <String>[
      (item['actualQuality'] ?? '').toString(),
      (item['quality'] ?? '').toString(),
      fallbackTitle,
    ];

    for (final raw in candidates) {
      final q = raw.trim();
      if (q.isEmpty) continue;

      final normalized = q.replaceAll('_', ' ');
      final pMatch = RegExp(
        r'(\d{3,4}p)',
        caseSensitive: false,
      ).firstMatch(normalized);
      if (pMatch != null) {
        return pMatch.group(1)!.toLowerCase();
      }

      final lowered = normalized.toLowerCase();
      if (lowered.contains('8k')) return '4320p';
      if (lowered.contains('4k')) return '2160p';
      if (lowered.contains('audio')) return 'Audio';
    }

    return '';
  }

  bool _isAudioFormat(String format) {
    final lowered = format.toLowerCase();
    return lowered == 'mp3' ||
        lowered == 'm4a' ||
        lowered == 'aac' ||
        lowered == 'wav' ||
        lowered == 'flac' ||
        lowered == 'ogg';
  }
}
