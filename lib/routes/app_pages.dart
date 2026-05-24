import 'package:get/get.dart';
import '../presentation/bindings/main_binding.dart';
import '../presentation/pages/main_layout.dart';
import '../presentation/pages/downloader/download_details_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: Routes.MAIN,
      page: () => const MainLayout(),
      binding: MainBinding(),
    ),
    GetPage(
      name: Routes.DOWNLOAD_DETAILS,
      page: () => const DownloadDetailsPage(),
    ),
    // Additional deeply linked routes can go here if needed
  ];
}
