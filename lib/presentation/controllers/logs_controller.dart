import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LogEntry {
  final String timestamp;
  final String level;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });
}

class LogsController extends GetxController {
  static const int _initialFilesToLoad = 3;
  static const int _filesLoadStep = 2;
  static const int _maxLinesPerFile = 250;

  final logs = <LogEntry>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final sourceLabel = ''.obs;
  final selectedText = ''.obs;

  int _visibleFileCount = _initialFilesToLoad;

  @override
  void onInit() {
    super.onInit();
    loadLogs();
  }

  Future<void> loadLogs() async {
    isLoading.value = true;
    _visibleFileCount = _initialFilesToLoad;
    try {
      await _reloadVisibleLogs();
    } catch (e) {
      logs.clear();
      sourceLabel.value = 'Failed to load logs: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreLogs() async {
    if (isLoading.value || isLoadingMore.value) {
      return;
    }

    isLoadingMore.value = true;
    try {
      _visibleFileCount += _filesLoadStep;
      await _reloadVisibleLogs();
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> _reloadVisibleLogs() async {
    final supportDir = await getApplicationSupportDirectory();
    final logDir = Directory(p.join(supportDir.path, 'MediaTube_Logs'));

    if (!await logDir.exists()) {
      logs.clear();
      sourceLabel.value = 'No log files found';
      return;
    }

    final files = logDir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    final visibleFiles = files.take(_visibleFileCount).toList();

    final entries = <LogEntry>[];
    for (final file in visibleFiles) {
      final lines = await file.readAsLines();
      final tailLines = lines.length > _maxLinesPerFile
          ? lines.sublist(lines.length - _maxLinesPerFile)
          : lines;

      for (final line in tailLines.reversed) {
        final entry = parseLogLine(line, fallbackSource: p.basename(file.path));
        entries.add(entry);
      }
    }

    logs.assignAll(entries);
    sourceLabel.value = files.isEmpty
        ? 'No log files found'
        : 'Loaded ${logs.length} lines from ${visibleFiles.length} recent file(s)';
  }

  static LogEntry parseLogLine(String rawLine, {String? fallbackSource}) {
    String timestamp = _nowTimestamp();
    String message = rawLine.trim();

    try {
      final decoded = jsonDecode(rawLine);
      if (decoded is Map<String, dynamic>) {
        final tsValue = decoded['ts']?.toString();
        if (tsValue != null && tsValue.isNotEmpty) {
          timestamp = _formatTimestamp(
            DateTime.tryParse(tsValue) ?? DateTime.now(),
          );
        }

        final lineValue =
            decoded['line']?.toString() ?? decoded['message']?.toString();
        if (lineValue != null && lineValue.isNotEmpty) {
          message = lineValue;
        }
      }
    } catch (_) {
      // Raw log line, keep as-is.
    }

    final level = _inferLevel(message);
    final cleanedMessage = _cleanMessage(message);

    return LogEntry(
      timestamp: timestamp,
      level: level,
      message: cleanedMessage,
    );
  }

  static String _inferLevel(String message) {
    final upper = message.toUpperCase();
    if (message.startsWith('[BINARY_ERROR]') ||
        message.startsWith('[EXEC_ERROR]') ||
        message.startsWith('[FATAL]') ||
        upper.contains('ERROR') ||
        upper.contains('FAILED')) {
      return 'ERR';
    }
    if (message.startsWith('WARNING:') || upper.contains('WARN')) {
      return 'WARN';
    }
    return 'INFO';
  }

  static String _cleanMessage(String message) {
    return message
        .replaceFirst('[BINARY_ERROR] ', '')
        .replaceFirst('[EXEC_ERROR] ', '')
        .replaceFirst('[FATAL] ', '')
        .replaceFirst('[ERROR] ', '');
  }

  static String _formatTimestamp(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}.${time.millisecond.toString().padLeft(3, '0')}';
  }

  static String _nowTimestamp() => _formatTimestamp(DateTime.now());

  void addLog(String level, String message) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    logs.add(LogEntry(timestamp: ts, level: level, message: message));
  }

  static String formatLogEntry(LogEntry entry) {
    return '${entry.timestamp} [${entry.level}] ${entry.message}';
  }

  Future<void> clearLogs() async {
    await _clearLogFiles();
  }

  Future<void> _clearLogFiles() async {
    isLoading.value = true;
    try {
      final supportDir = await getApplicationSupportDirectory();
      final logDir = Directory(p.join(supportDir.path, 'MediaTube_Logs'));

      if (await logDir.exists()) {
        final files = logDir.listSync().whereType<File>().toList();
        final deletes = <Future>[];
        for (final file in files) {
          deletes.add(file.delete().catchError((_) => file));
        }
        await Future.wait(deletes);
      }

      logs.clear();
      selectedText.value = '';
      sourceLabel.value = 'Logs cleared';
    } catch (e) {
      sourceLabel.value = 'Failed to clear logs: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void updateSelectedText(String text) {
    selectedText.value = text.trim();
  }

  void copySelectedText() {
    final text = selectedText.value;
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      'Selected text copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      maxWidth: 300,
      margin: const EdgeInsets.only(bottom: 24),
    );
  }
}
