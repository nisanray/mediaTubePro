import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import 'package:file_selector/file_selector.dart';
import '../../controllers/settings_controller.dart';
import '../../widgets/shared/glass_panel.dart';
import '../../widgets/shared/mac_button.dart';
import '../../widgets/shared/mac_dropdown.dart';
import '../../widgets/shared/mac_switch.dart';
import '../../widgets/shared/mac_text_field.dart';
import '../../../core/theme/spacing.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Preferences', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),

          // Two-Column Layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: ListView(
                    children: [
                      _buildGeneralCard(controller),
                      const SizedBox(height: 12),
                      _buildAdvancedCard(controller),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right Column
                Expanded(
                  child: ListView(
                    children: [
                      _buildVideoAudioCard(controller),
                      const SizedBox(height: 12),
                      _buildAppearanceCard(controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralCard(SettingsController controller) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.tune, 'General'),
          const SizedBox(height: Spacing.medium),
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text(
              'Default Save Location',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.panel),
                child: _fieldRow(
                  'Save Location',
                  Obx(() => MacTextField(
                        hintText: '',
                        controller: TextEditingController(
                          text: controller.defaultLocation.value,
                        ),
                      )),
                  trailing: MacButton(
                    text: 'Browse...',
                    onPressed: () async {
                      final directoryPath = await getDirectoryPath();
                      if (directoryPath != null && directoryPath.isNotEmpty) {
                        controller.defaultLocation.value = directoryPath;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.medium),
          _fieldRow(
            'Launch at Login',
            const SizedBox.shrink(),
            trailing: Obx(() => MacSwitch(value: controller.launchAtLogin.value, onChanged: (v) => controller.launchAtLogin.value = v)),
            subtitle: 'Start MediaTube automatically',
          ),
          const SizedBox(height: Spacing.small),
          _fieldRow(
            'Notifications',
            const SizedBox.shrink(),
            trailing: Obx(() => MacSwitch(value: controller.notifications.value, onChanged: (v) => controller.notifications.value = v)),
            subtitle: 'Show alerts when done',
          ),
          const SizedBox(height: Spacing.small),
          _fieldRow(
            'Force Kill on Cancel',
            const SizedBox.shrink(),
            trailing: Obx(() => MacSwitch(value: controller.forceKillOnCancel.value, onChanged: (v) => controller.forceKillOnCancel.value = v)),
            subtitle: 'Instantly terminate yt-dlp + child processes',
          ),
        ],
      ),
    );
  }

  Widget _buildVideoAudioCard(SettingsController controller) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.movie_outlined, 'Video & Audio'),
          const SizedBox(height: Spacing.medium),
          _fieldRow('Quality', Obx(() => MacDropdown(value: controller.quality.value, items: controller.qualityOptions, onChanged: (v) { if (v != null) controller.quality.value = v; }))),
          const SizedBox(height: Spacing.small),
          _fieldRow('Quality Mode', Obx(() => MacDropdown(value: controller.videoQualityMode.value, items: controller.videoQualityModeOptions, onChanged: (v) { if (v != null) controller.videoQualityMode.value = v; }))),
          const SizedBox(height: Spacing.small),
          _fieldRow('Format', Obx(() => MacDropdown(value: controller.format.value, items: controller.formatOptions, onChanged: (v) { if (v != null) controller.format.value = v; }))),
          const SizedBox(height: Spacing.small),
          _fieldRow('Codec', Obx(() => MacDropdown(value: controller.codec.value, items: controller.codecOptions, onChanged: (v) { if (v != null) controller.codec.value = v; }))),
        ],
      ),
    );
  }

  Widget _buildAdvancedCard(SettingsController controller) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.memory, 'Advanced'),
          const SizedBox(height: Spacing.medium),
          const Text(
            'Custom yt-dlp Path',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: Spacing.small),
          _fieldRow(
            'yt-dlp',
            Obx(() => MacTextField(hintText: 'C:/Tools/yt-dlp.exe', controller: TextEditingController(text: controller.customYtDlp.value))),
            trailing: MacButton(
              text: 'Browse...',
              onPressed: () async {
                final file = await openFile(
                  acceptedTypeGroups: [
                    XTypeGroup(label: 'exe', extensions: ['exe']),
                  ],
                );
                if (file != null) {
                  controller.customYtDlp.value = file.path;
                }
              },
            ),
          ),
          const SizedBox(height: Spacing.small),
          Obx(() => Text(
                controller.customYtDlp.value.trim().isEmpty
                    ? 'Leave blank to use the bundled yt-dlp.'
                    : 'Custom yt-dlp is active.',
                style: TextStyle(
                  fontSize: 11,
                  color: controller.customYtDlp.value.trim().isEmpty
                      ? AppColors.success
                      : AppColors.primary,
                ),
              )),
          const SizedBox(height: Spacing.medium),
          const Text(
            'Custom FFmpeg Path',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: Spacing.small),
          _fieldRow(
            'ffmpeg',
            Obx(() => MacTextField(hintText: '/usr/local/bin/ffmpeg', controller: TextEditingController(text: controller.customFfmpeg.value))),
            trailing: MacButton(
              text: 'Browse...',
              onPressed: () async {
                final file = await openFile(
                  acceptedTypeGroups: [
                    XTypeGroup(label: 'exe', extensions: ['exe']),
                  ],
                );
                if (file != null) {
                  controller.customFfmpeg.value = file.path;
                }
              },
            ),
          ),
          const SizedBox(height: Spacing.small),
          Obx(() => Text(
                controller.customFfmpeg.value.trim().isEmpty
                    ? 'Leave blank to use the bundled FFmpeg.'
                    : 'Custom FFmpeg is active.',
                style: TextStyle(
                  fontSize: 11,
                  color: controller.customFfmpeg.value.trim().isEmpty
                      ? AppColors.success
                      : AppColors.primary,
                ),
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Concurrent Downloads',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Obx(
                () => Text(
                  '${controller.concurrentDownloads.value.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          Obx(
            () => SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.outlineVariant,
                thumbColor: Colors.white,
                overlayColor: AppColors.primary.withOpacity(0.1),
              ),
              child: Slider(
                value: controller.concurrentDownloads.value,
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (val) => controller.concurrentDownloads.value = val,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '1 (Slower)',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                '10 (Faster)',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(SettingsController controller) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.palette_outlined, 'Appearance & App'),
          const SizedBox(height: 16),
          _buildDropdownRow('Theme', controller.theme, controller.themeOptions),
          const SizedBox(height: 12),
          _buildDropdownRow(
            'Language',
            controller.language,
            controller.languageOptions,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: controller.resetDefaults,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Reset Defaults',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _fieldRow(String label, Widget control, {Widget? trailing, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xsmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: Spacing.medium),
          Expanded(child: control),
          if (trailing != null) ...[
            const SizedBox(width: Spacing.small),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildCardHeader(IconData icon, String title) {
    // Removed bottom border - card header uses spacing only now
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, String subtitle, RxBool rxValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Obx(
          () => MacSwitch(
            value: rxValue.value,
            onChanged: (val) => rxValue.value = val,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow(
    String label,
    RxString rxValue,
    List<String> options,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 2,
          child: Obx(
            () => MacDropdown(
              value: rxValue.value,
              items: options,
              onChanged: (val) {
                if (val != null) rxValue.value = val;
              },
            ),
          ),
        ),
      ],
    );
  }
}
