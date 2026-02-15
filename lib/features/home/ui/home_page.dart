import 'package:flutter/material.dart';

import '../../preview/ui/preview_pane.dart';
import '../../prompt/ui/prompt_pane.dart';
import '../../settings/ui/settings_pane.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Ensure a minimum width for the 3-pane layout to prevent crushing
          // If the window is too small, we might want to switch via media query,
          // but here we just constrain the minimum width of the content
          // so it becomes scrollable or just clipped rather than erroring?
          // Actually, overflow is acceptable or we should use SingleChildScrollView with scrollDirection: Axis.horizontal?
          // For a desktop app, usually we just set minimum window size (done in main.dart).
          // But to be safe, let's wrap in a constrained box or allow scrolling if absolutely needed?
          // Since windowManager sets minimum size, we might not need this if it works.
          // But let's check the user request "Make sure layout doesn't break".
          // If the user forcibly resizes smaller than min size (some OS allow this), or if min size is too small.
          return ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 1000,
            ), // Match min size in main.dart
            child: Row(
              children: [
                // Left: Settings Panel
                const SettingsPane(),

                // Center: Prompt Area
                const Expanded(flex: 2, child: PromptPane()),

                // Right: Preview Area
                const Expanded(flex: 2, child: PreviewPane()),
              ],
            ),
          );
        },
      ),
    );
  }
}
