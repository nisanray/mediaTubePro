import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final _box = GetStorage();

  // Reactive variables initialized from storage (or defaults)
  late final RxString defaultLocation;
  late final RxBool launchAtLogin;
  late final RxBool notifications;
  late final RxBool forceKillOnCancel;
  late final RxString quality;
  late final RxString videoQualityMode;
  late final RxString format;
  late final RxString codec;
  late final RxString customYtDlp;
  late final RxString customFfmpeg;
  late final RxDouble concurrentDownloads;
  late final RxString theme;
  late final RxString language;

  // Options
  final qualityOptions = [
    'Best Available (4K/8K)',
    '1080p Premium',
    '720p Standard',
    'Audio Only',
  ];
  final videoQualityModeOptions = [
    'Probing the video quality',
    'Default fixed',
  ];
  final formatOptions = ['MP4 (Most Compatible)', 'MKV (Advanced)', 'WebM'];
  final codecOptions = ['H.264 (Default)', 'H.265 / HEVC', 'AV1'];
  final themeOptions = ['System Default', 'Light (Aqua)', 'Dark (Graphite)'];
  final languageOptions = [
    'English (US)',
    'Spanish',
    'French',
    'German',
    'Japanese',
  ];

  @override
  void onInit() {
    super.onInit();
    // Load from storage or set defaults
    defaultLocation = RxString(
      (_box.read('defaultLocation') ?? _defaultDownloadPath()).toString(),
    );
    launchAtLogin = RxBool(_box.read('launchAtLogin') as bool? ?? false);
    notifications = RxBool(_box.read('notifications') as bool? ?? true);
    forceKillOnCancel = RxBool(_box.read('forceKillOnCancel') as bool? ?? true);
    quality = RxString(_readOption('quality', qualityOptions, '1080p Premium'));
    videoQualityMode = RxString(
      _readOption(
        'videoQualityMode',
        videoQualityModeOptions,
        'Probing the video quality',
      ),
    );
    format = RxString(
      _readOption('format', formatOptions, 'MP4 (Most Compatible)'),
    );
    codec = RxString(_readOption('codec', codecOptions, 'H.264 (Default)'));
    customYtDlp = RxString((_box.read('customYtDlp') ?? '').toString());
    customFfmpeg = RxString((_box.read('customFfmpeg') ?? '').toString());
    concurrentDownloads = RxDouble(
      (_box.read('concurrentDownloads') as num? ?? 3.0).toDouble(),
    );
    theme = RxString(_readOption('theme', themeOptions, 'System Default'));
    language = RxString(
      _readOption('language', languageOptions, 'English (US)'),
    );

    // Listen to changes and save to storage automatically
    ever(defaultLocation, (value) => _box.write('defaultLocation', value));
    ever(launchAtLogin, (value) => _box.write('launchAtLogin', value));
    ever(notifications, (value) => _box.write('notifications', value));
    ever(forceKillOnCancel, (value) => _box.write('forceKillOnCancel', value));
    ever(quality, (value) => _box.write('quality', value));
    ever(videoQualityMode, (value) => _box.write('videoQualityMode', value));
    ever(format, (value) => _box.write('format', value));
    ever(codec, (value) => _box.write('codec', value));
    ever(customYtDlp, (value) => _box.write('customYtDlp', value));
    ever(customFfmpeg, (value) => _box.write('customFfmpeg', value));
    ever(
      concurrentDownloads,
      (value) => _box.write('concurrentDownloads', value),
    );
    ever(theme, (value) => _box.write('theme', value));
    ever(language, (value) => _box.write('language', value));
  }

  void resetDefaults() {
    defaultLocation.value = _defaultDownloadPath();
    launchAtLogin.value = false;
    notifications.value = true;
    forceKillOnCancel.value = true;
    quality.value = '1080p Premium';
    videoQualityMode.value = 'Probing the video quality';
    format.value = 'MP4 (Most Compatible)';
    codec.value = 'H.264 (Default)';
    customYtDlp.value = '';
    customFfmpeg.value = '';
    concurrentDownloads.value = 3.0;
    theme.value = 'System Default';
    language.value = 'English (US)';
    customYtDlp.value = '';
  }

  String _readOption(String key, List<String> allowedValues, String fallback) {
    final storedValue = _box.read(key)?.toString();
    if (storedValue != null && allowedValues.contains(storedValue)) {
      return storedValue;
    }
    return fallback;
  }

  String _defaultDownloadPath() {
    if (Platform.isWindows) {
      return r'C:\Users\Public\Downloads\MediaTube';
    }
    if (Platform.isMacOS) {
      return '/Users/Shared/Downloads/MediaTube';
    }
    final home = Platform.environment['HOME'] ?? '/home';
    return '$home/Downloads/MediaTube';
  }
}
