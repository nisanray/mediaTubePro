import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../controllers/settings_controller.dart';
import 'package:file_selector/file_selector.dart';
import 'shared/mac_button.dart';
import 'shared/mac_switch.dart';

class MainRightSidebar extends StatefulWidget {
  const MainRightSidebar({super.key});

  @override
  State<MainRightSidebar> createState() => _MainRightSidebarState();
}

class _MainRightSidebarState extends State<MainRightSidebar> {
  SettingsController? controller;
  late String qualityValue;
  late String saveLocation;
  late bool forceAudioOnly;
  late bool embedSubtitles;
  late bool autoStart;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : null;

    qualityValue = controller != null
        ? _mappedQuality(controller!.quality.value)
        : '1080p Premium';
    saveLocation = controller?.defaultLocation.value ?? _defaultDownloadPath();
    forceAudioOnly = controller?.quality.value == 'Audio Only';
    embedSubtitles = controller?.notifications.value ?? true;
    autoStart = controller?.launchAtLogin.value ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 288,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(left: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant),
              ),
            ),
            child: const Text(
              'DEFAULT SETTINGS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Preferred Quality',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: qualityValue,
                  decoration: _inputDecoration(),
                  items: const [
                    DropdownMenuItem(
                      value: 'Best Available (4K/8K)',
                      child: Text('Best Available (4K/8K)'),
                    ),
                    DropdownMenuItem(
                      value: '1080p Premium',
                      child: Text('1080p Premium'),
                    ),
                    DropdownMenuItem(
                      value: '720p Standard',
                      child: Text('720p Standard'),
                    ),
                    DropdownMenuItem(
                      value: 'Audio Only',
                      child: Text('Audio Only'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      qualityValue = value;
                    });
                    if (controller != null) {
                      controller!.quality.value = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Save Location',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        controller: TextEditingController(text: saveLocation),
                        decoration: _inputDecoration(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MacButton(
                      text: 'Browse',
                      icon: Icons.folder_open,
                      onPressed: () async {
                        try {
                          final directoryPath = await getDirectoryPath();
                          if (directoryPath != null &&
                              directoryPath.isNotEmpty) {
                            setState(() {
                              saveLocation = directoryPath;
                            });
                            if (controller != null) {
                              controller!.defaultLocation.value = directoryPath;
                            }
                          }
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.outlineVariant),
                const SizedBox(height: 8),
                _SidebarToggleRow(
                  label: 'Force Audio Only',
                  value: forceAudioOnly,
                  onChanged: (value) {
                    setState(() {
                      forceAudioOnly = value;
                      qualityValue = value ? 'Audio Only' : '1080p Premium';
                    });
                    if (controller != null) {
                      controller!.quality.value = qualityValue;
                    }
                  },
                ),
                _SidebarToggleRow(
                  label: 'Embed Subtitles',
                  value: embedSubtitles,
                  onChanged: (value) {
                    setState(() {
                      embedSubtitles = value;
                    });
                    if (controller != null) {
                      controller!.notifications.value = value;
                    }
                  },
                ),
                _SidebarToggleRow(
                  label: 'Auto-start Downloads',
                  value: autoStart,
                  onChanged: (value) {
                    setState(() {
                      autoStart = value;
                    });
                    if (controller != null) {
                      controller!.launchAtLogin.value = value;
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _mappedQuality(String quality) {
    if (quality.contains('4K')) return 'Best Available (4K/8K)';
    if (quality.contains('1080')) return '1080p Premium';
    if (quality.contains('720')) return '720p Standard';
    if (quality.toLowerCase().contains('audio')) return 'Audio Only';
    return '1080p Premium';
  }

  static String _defaultDownloadPath() {
    if (Platform.isWindows) {
      return r'C:\Users\Public\Downloads\MediaTube';
    }
    if (Platform.isMacOS) {
      return '/Users/Shared/Downloads/MediaTube';
    }
    final home = Platform.environment['HOME'] ?? '/home';
    return '$home/Downloads/MediaTube';
  }

  static InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

class _SidebarToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SidebarToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          MacSwitch(value: value, onChanged: onChanged),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
