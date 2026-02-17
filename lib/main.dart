import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:window_manager/window_manager.dart';

import 'features/home/ui/home_page.dart';
import 'features/settings/store/settings_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Window Manager initialization for Desktop
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(1000, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Forge Flutter Client',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(generationSettingsProvider);
    // UIデバッグモードの適用
    debugPaintSizeEnabled = settings.uiDebugMode;

    final fThemeData = FThemes.zinc.dark;

    return FTheme(
      data: fThemeData,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Forge Flutter Client',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: fThemeData.colors.background,
          colorScheme: ColorScheme.dark(
            primary: fThemeData.colors.primary,
            onPrimary: fThemeData.colors.primaryForeground,
            surface: fThemeData.colors.background,
            onSurface: fThemeData.colors.foreground,
            error: fThemeData.colors.error,
            onError: fThemeData.colors.errorForeground,
            outline: fThemeData.colors.border,
          ),
          fontFamily: 'packages/forui_assets/Inter',
        ),
        builder: (context, child) =>
            FTheme(data: fThemeData, child: child!),
        home: const HomePage(),
      ),
    );
  }
}
