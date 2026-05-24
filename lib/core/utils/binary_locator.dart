import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class BinaryLocator {
  static String ytDlpPath = 'yt-dlp';
  static String ffmpegPath = 'ffmpeg';
  static String? initError;

  /// Extracts bundled binaries to the local file system so they can be executed.
  static Future<void> initialize() async {
    final supportDir = await getApplicationSupportDirectory();
    final binDir = Directory(p.join(supportDir.path, 'MediaTube_Binaries'));

    if (!await binDir.exists()) {
      await binDir.create(recursive: true);
    }

    // Determine OS-specific filenames
    final isWindows = Platform.isWindows;
    final ytDlpName = isWindows ? 'yt-dlp.exe' : 'yt-dlp';
    final ffmpegName = isWindows ? 'ffmpeg.exe' : 'ffmpeg';

    // Prefer extracted bundled binaries in app support, but gracefully
    // fall back to system-provided executables if extraction fails.
    final candidateYtDlpPath = p.join(binDir.path, ytDlpName);
    final candidateFfmpegPath = p.join(binDir.path, ffmpegName);

    try {
      await _extractBundledBinary(
        targetPath: candidateYtDlpPath,
        assetCandidates: ['assets/bin/$ytDlpName', 'asset/bin/$ytDlpName'],
        makeExecutable: !isWindows,
      );
      ytDlpPath = candidateYtDlpPath;
    } catch (e) {
      // Extraction failed; fallback to system-wide executable name.
      final msg = 'BinaryLocator: failed to extract $ytDlpName: $e';
      print(msg);
      initError = (initError ?? '') + msg + '\n';
      ytDlpPath = 'yt-dlp';
    }

    try {
      await _extractBundledBinary(
        targetPath: candidateFfmpegPath,
        assetCandidates: ['assets/bin/$ffmpegName', 'asset/bin/$ffmpegName'],
        makeExecutable: !isWindows,
      );
      ffmpegPath = candidateFfmpegPath;
    } catch (e) {
      final msg = 'BinaryLocator: failed to extract $ffmpegName: $e';
      print(msg);
      initError = (initError ?? '') + msg + '\n';
      ffmpegPath = 'ffmpeg';
    }
  }

  static Future<void> _extractBundledBinary({
    required String targetPath,
    required List<String> assetCandidates,
    required bool makeExecutable,
  }) async {
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      return;
    }

    for (final assetPath in assetCandidates) {
      try {
        final bytes = await rootBundle.load(assetPath);
        await targetFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
        if (makeExecutable) {
          await Process.run('chmod', ['+x', targetFile.path]);
        }
        return;
      } catch (error) {
        // try next candidate
      }
    }

    // If we reach here, no asset candidate was found. Throw so callers
    // can decide how to handle it (initialize() handles and falls back).
    throw Exception('No bundled asset found for ${targetFile.path}');
  }
}
