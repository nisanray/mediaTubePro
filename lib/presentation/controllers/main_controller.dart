import 'package:get/get.dart';

class MainController extends GetxController {
  // 0: Downloader, 1: History, 2: Settings, 3: Logs
  final RxInt currentIndex = 0.obs;
  // Sidebar collapsed state
  final RxBool isSidebarCollapsed = false.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }
}
