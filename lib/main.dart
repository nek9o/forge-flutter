import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';

import 'features/home/ui/home_page.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // M3 Expressive: ダークテーマ
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C4DFF), // Deep Purple Accent
      brightness: Brightness.dark,
    );

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C4DFF),
      brightness: Brightness.light,
    );

    final baseTextTheme = GoogleFonts.ibmPlexSansJpTextTheme(
      ThemeData.dark().textTheme,
    );

    final lightTextTheme = GoogleFonts.ibmPlexSansJpTextTheme(
      ThemeData.light().textTheme,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      visualDensity: VisualDensity.compact,
      textTheme: baseTextTheme,

      // M3 Expressive: Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        color: darkColorScheme.surfaceContainerHigh,
      ),

      // M3 Expressive: Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surfaceContainerHighest.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: darkColorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: darkColorScheme.outlineVariant.withAlpha(60),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // M3 Expressive: FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // M3 Expressive: TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // M3 Expressive: OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // M3 Expressive: Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: darkColorScheme.surfaceContainerHigh,
        elevation: 6,
      ),

      // M3 Expressive: ExpansionTile
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: darkColorScheme.onSurfaceVariant,
        collapsedIconColor: darkColorScheme.onSurfaceVariant,
        backgroundColor: darkColorScheme.surfaceContainerLow,
        collapsedBackgroundColor: Colors.transparent,
      ),

      // M3 Expressive: NavigationRail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: darkColorScheme.surfaceContainerLow,
        indicatorColor: darkColorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(
          color: darkColorScheme.onPrimaryContainer,
          size: 22,
        ),
        unselectedIconTheme: IconThemeData(
          color: darkColorScheme.onSurfaceVariant,
          size: 22,
        ),
        selectedLabelTextStyle: TextStyle(
          color: darkColorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: darkColorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
        labelType: NavigationRailLabelType.all,
        minWidth: 72,
      ),

      // M3 Expressive: TabBar
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: darkColorScheme.outlineVariant.withAlpha(40),
        labelColor: darkColorScheme.primary,
        unselectedLabelColor: darkColorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
      ),

      // M3 Expressive: Slider
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: darkColorScheme.primary,
        inactiveTrackColor: darkColorScheme.surfaceContainerHighest,
        thumbColor: darkColorScheme.primary,
      ),

      // M3 Expressive: AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: darkColorScheme.surfaceContainerLow,
        foregroundColor: darkColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),

      // M3 Expressive: ListTile
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),

      // M3 Expressive: IconButton
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // M3 Expressive: Divider
      dividerTheme: DividerThemeData(
        color: darkColorScheme.outlineVariant.withAlpha(40),
        thickness: 1,
        space: 1,
      ),

      // M3 Expressive: SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Scaffold
      scaffoldBackgroundColor: darkColorScheme.surface,

      // SwitchTheme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkColorScheme.onPrimary;
          }
          return darkColorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkColorScheme.primary;
          }
          return darkColorScheme.surfaceContainerHighest;
        }),
      ),

      // DropdownMenu
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkColorScheme.surfaceContainerHighest.withAlpha(80),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: darkColorScheme.outlineVariant.withAlpha(60),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: darkColorScheme.outlineVariant.withAlpha(60),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      visualDensity: VisualDensity.compact,
      textTheme: lightTextTheme,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Forge Flutter Client',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}
