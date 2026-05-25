import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../controllers/logs_controller.dart';
import '../../widgets/shared/mac_button.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  late final LogsController controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LogsController());
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.extentAfter < 260) {
      controller.loadMoreLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'System Logs',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
              Row(
                children: [
                  Obx(
                    () => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        controller.sourceLabel.value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  MacButton(
                    text: 'Refresh',
                    icon: Icons.refresh,
                    onPressed: controller.loadLogs,
                  ),
                  const SizedBox(width: 8),
                  MacButton(
                    text: 'Copy Selected',
                    icon: Icons.content_copy,
                    onPressed: controller.copySelectedText,
                  ),
                  const SizedBox(width: 8),
                  MacButton(
                    text: 'Clear',
                    icon: Icons.delete_sweep,
                    onPressed: () => _confirmClearLogs(context, controller),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Terminal Window
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1e1e1e), // Dark terminal background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF333333)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Terminal Title Bar
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2d2d2d),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF111111)),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Traffic Lights
                        Row(
                          children: [
                            _buildTrafficLight(
                              const Color(0xFFff5f56),
                              const Color(0xFFe0443e),
                            ),
                            const SizedBox(width: 6),
                            _buildTrafficLight(
                              const Color(0xFFffbd2e),
                              const Color(0xFFdea123),
                            ),
                            const SizedBox(width: 6),
                            _buildTrafficLight(
                              const Color(0xFF27c93f),
                              const Color(0xFF1aab29),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'mediatube_core.log',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF888888),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // Live Indicator
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF27c93f),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFF27c93f),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Terminal Output
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (controller.logs.isEmpty) {
                        return Center(
                          child: Text(
                            'No logs available yet.',
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFF888888),
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: controller.loadLogs,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount:
                              controller.logs.length +
                              (controller.isLoadingMore.value ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == controller.logs.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Loading older logs...',
                                        style: GoogleFonts.jetBrainsMono(
                                          color: const Color(0xFF888888),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return _buildLogLine(
                              controller.logs[index],
                              controller,
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearLogs(
    BuildContext context,
    LogsController controller,
  ) async {
    final shouldClear =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Clear Logs?'),
              content: const Text(
                'This will permanently delete the saved log files and clear the log viewer.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Clear'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldClear) {
      await controller.clearLogs();
    }
  }

  Widget _buildTrafficLight(Color color, Color border) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 0.5),
      ),
    );
  }

  Widget _buildLogLine(LogEntry log, LogsController controller) {
    Color levelColor;
    Color textColor = const Color(0xFFd4d4d4);
    bool isError = log.level.trim() == 'ERR';
    final lineText = '${log.timestamp} [${log.level.trim()}] ${log.message}';

    switch (log.level.trim()) {
      case 'INFO':
        levelColor = const Color(0xFF4ec9b0);
        break;
      case 'WARN':
        levelColor = const Color(0xFFce9178);
        break;
      case 'ERR':
        levelColor = const Color(0xFFf44747);
        textColor = const Color(0xFFf44747);
        break;
      default:
        levelColor = const Color(0xFFd4d4d4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      color: isError
          ? const Color(0xFF4d1f1c).withOpacity(0.3)
          : Colors.transparent,
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${log.timestamp} ',
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFF569cd6),
                fontSize: 13,
                backgroundColor: const Color(0xFF223c55),
              ),
            ),
            TextSpan(
              text: '[${log.level.trim()}] ',
              style: GoogleFonts.jetBrainsMono(
                color: levelColor,
                fontSize: 13,
                fontWeight: isError ? FontWeight.bold : FontWeight.normal,
                backgroundColor: levelColor.withOpacity(0.18),
              ),
            ),
            TextSpan(
              text: log.message,
              style: GoogleFonts.jetBrainsMono(color: textColor, fontSize: 13),
            ),
          ],
        ),
        maxLines: 1,
        onSelectionChanged: (selection, cause) {
          if (selection.baseOffset < 0 || selection.extentOffset < 0) {
            controller.updateSelectedText('');
            return;
          }

          final start = selection.start;
          final end = selection.end;
          if (start == end) {
            controller.updateSelectedText('');
            return;
          }

          // Make copy friendly: when user selects any portion of a line,
          // we store the full line (timestamp + level + message) so that
          // the one-click "Copy Selected" action includes badges.
          controller.updateSelectedText(lineText);
        },
      ),
    );
  }
}
