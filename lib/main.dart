import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'core/utils/binary_locator.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() async {
  // Ensure bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage for Settings and History
  await GetStorage.init();
  await GetStorage.init('history_box'); // Separate box for history

  // Extract bundled binaries so yt-dlp and ffmpeg can be executed.
  // Failures are logged and we fall back to system-installed executables.
  try {
    await BinaryLocator.initialize();
  } catch (e) {
    // Initialization should be resilient; log and continue so the app can run
    // in environments where bundled assets are not available (tests, CI).
    print('Warning: BinaryLocator.initialize() failed: $e');
  }

  runApp(const MediaTubeApp());
}

class MediaTubeApp extends StatelessWidget {
  const MediaTubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // Window title simplified to avoid duplicating 'Pro' in the UI
      title: 'MediaTube',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: Routes.MAIN,
      getPages: AppPages.pages,
      defaultTransition: Transition.fadeIn,
    );
  }
}
