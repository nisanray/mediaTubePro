import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../controllers/main_controller.dart';
import '../controllers/history_controller.dart';
import 'downloader/downloader_page.dart';
import 'history/history_page.dart';
import 'logs/logs_page.dart';
import 'settings/settings_page.dart';

class MainLayout extends GetView<MainController> {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                // Main Content Canvas
                Expanded(
                  child: Obx(
                    () => _buildActivePage(controller.currentIndex.value),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildActivePage(int index) {
    switch (index) {
      case 0:
        return const DownloaderPage();
      case 1:
        return const HistoryPage();
      case 2:
        return const SettingsPage();
      case 3:
        return const LogsPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sidebar toggle + app title
          Row(
            children: [
              IconButton(
                icon: Obx(
                  () => Icon(
                    controller.isSidebarCollapsed.value
                        ? Icons.chevron_right
                        : Icons.chevron_left,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                onPressed: controller.toggleSidebar,
                splashRadius: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'MediaTube',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text('Pro', style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          Row(
            children: [
              // Search Input (shows History search when History page active)
              Obx(() {
                if (controller.currentIndex.value == 1) {
                  final historyCtrl = Get.isRegistered<HistoryController>()
                      ? Get.find<HistoryController>()
                      : Get.put(HistoryController());
                  return ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 560,
                      minWidth: 220,
                    ),
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 16,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() {
                              final txt = historyCtrl.searchQuery.value;
                              final tec = TextEditingController(text: txt);
                              return TextField(
                                controller: tec,
                                decoration: const InputDecoration(
                                  hintText: 'Search history...',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(fontSize: 13),
                                onChanged: historyCtrl.setSearchQuery,
                              );
                            }),
                          ),
                          Obx(
                            () => historyCtrl.searchQuery.value.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => historyCtrl.setSearchQuery(''),
                                    child: const Icon(
                                      Icons.clear,
                                      size: 16,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Default app-wide search
                return Container(
                  width: 240,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () => Get.toNamed('/settings'),
                splashRadius: 20,
              ),
              IconButton(
                icon: const Icon(
                  Icons.help_outline,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Help & Documentation'),
                      content: const Text(
                        'Visit the documentation or open the project README for help.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Obx(() {
      final collapsed = controller.isSidebarCollapsed.value;
      return AnimatedContainer(
        width: collapsed ? 64 : 240,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          border: Border(right: BorderSide(color: AppColors.outlineVariant)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: collapsed
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            // Removed sidebar logo to avoid redundant branding above navigation
            const SizedBox(height: 8),
            // Navigation Menu
            _SidebarItem(
              icon: Icons.download_rounded,
              label: 'Downloader',
              isActive: controller.currentIndex.value == 0,
              showLabel: !collapsed,
              onTap: () => controller.changePage(0),
            ),
            _SidebarItem(
              icon: Icons.history_rounded,
              label: 'History',
              isActive: controller.currentIndex.value == 1,
              showLabel: !collapsed,
              onTap: () => controller.changePage(1),
            ),
            _SidebarItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              isActive: controller.currentIndex.value == 2,
              showLabel: !collapsed,
              onTap: () => controller.changePage(2),
            ),
            _SidebarItem(
              icon: Icons.terminal_rounded,
              label: 'Logs',
              isActive: controller.currentIndex.value == 3,
              showLabel: !collapsed,
              onTap: () => controller.changePage(3),
            ),
            const Spacer(),
            // Pro Upgrade Button (compact when collapsed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: collapsed
                  ? const Icon(Icons.star, color: AppColors.primary)
                  : const Text(
                      'Upgrade Pro',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFooter() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Ready to download • Connected to 10.0.1.5',
                style: TextStyle(color: AppColors.secondary, fontSize: 11),
              ),
            ],
          ),
          Row(
            children: const [
              Text(
                'System Status',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'API Docs',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool showLabel;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 44),
        padding: showLabel
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: showLabel
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.onPrimaryContainer
                  : AppColors.onSurfaceVariant,
              size: 20,
            ),
            if (showLabel) ...[
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
