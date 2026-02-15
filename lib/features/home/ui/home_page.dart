import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../../preview/ui/preview_pane.dart';
import '../../prompt/ui/prompt_pane.dart';
import '../../settings/ui/settings_pane.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width >= 1200) {
            // デスクトップレイアウト: マルチスプリットビュー
            return MultiSplitView(
              initialAreas: [
                Area(builder: (context, area) => const SettingsPane(), flex: 2),
                Area(builder: (context, area) => const PreviewPane(), flex: 4),
                Area(builder: (context, area) => const PromptPane(), flex: 4),
              ],
            );
          } else if (width >= 600) {
            // タブレットレイアウト: 設定をDrawer等に検討可能だが、一旦2カラム
            return Row(
              children: [
                const Expanded(flex: 1, child: PreviewPane()),
                const Expanded(flex: 1, child: PromptPane()),
              ],
            );
          } else {
            // モバイルレイアウト: タブ切り替え
            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.settings), text: '設定'),
                      Tab(icon: Icon(Icons.image), text: 'プレビュー'),
                      Tab(icon: Icon(Icons.edit), text: 'プロンプト'),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [SettingsPane(), PreviewPane(), PromptPane()],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
