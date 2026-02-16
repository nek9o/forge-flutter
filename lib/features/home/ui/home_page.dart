import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../../preview/ui/preview_pane.dart';
import '../../prompt/ui/prompt_pane.dart';
import '../../settings/ui/oss_license_page.dart';
import '../../settings/ui/settings_pane.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _settingsExpanded = true;
  bool _showMonitor = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width >= 1200) {
            // デスクトップレイアウト: ツールバー + Row
            return Row(
              children: [
                // サイドツールバー
                Container(
                  width: 56,
                  color: colorScheme.surfaceContainerLow,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // アプリアイコン
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Icon(
                          PhosphorIcons.diamondsFour(PhosphorIconsStyle.fill),
                          color: colorScheme.primary,
                          size: 26,
                        ),
                      ),
                      // 設定トグル
                      _buildToolbarButton(
                        context,
                        icon: PhosphorIcons.gear(),
                        activeIcon: PhosphorIcons.gear(PhosphorIconsStyle.fill),
                        isActive: _settingsExpanded,
                        tooltip: L.of(locale, 'settings_panel'),
                        onPressed: () {
                          setState(() {
                            _settingsExpanded = !_settingsExpanded;
                          });
                        },
                      ),
                      const SizedBox(height: 4),
                      // システムモニタートグル
                      _buildToolbarButton(
                        context,
                        icon: PhosphorIcons.chartLine(),
                        activeIcon: PhosphorIcons.chartLine(
                          PhosphorIconsStyle.fill,
                        ),
                        isActive: _showMonitor,
                        tooltip: L.of(locale, 'system_monitor'),
                        onPressed: () {
                          setState(() {
                            _showMonitor = !_showMonitor;
                            if (_showMonitor && !_settingsExpanded) {
                              _settingsExpanded = true;
                            }
                          });
                        },
                      ),
                      const Spacer(),
                      // 言語切り替え
                      _buildToolbarButton(
                        context,
                        icon: PhosphorIcons.translate(),
                        activeIcon: PhosphorIcons.translate(
                          PhosphorIconsStyle.fill,
                        ),
                        isActive: false,
                        tooltip: L.of(locale, 'language'),
                        label: locale == AppLocale.ja ? 'JA' : 'EN',
                        onPressed: () {
                          ref
                              .read(localeProvider.notifier)
                              .state = locale == AppLocale.ja
                              ? AppLocale.en
                              : AppLocale.ja;
                        },
                      ),
                      const SizedBox(height: 4),
                      // ライセンス情報
                      _buildToolbarButton(
                        context,
                        icon: PhosphorIcons.scroll(),
                        activeIcon: PhosphorIcons.scroll(
                          PhosphorIconsStyle.fill,
                        ),
                        isActive: false,
                        tooltip: L.of(locale, 'license_info'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const OssLicensePage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                // 縦区切り線
                VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: colorScheme.outlineVariant.withAlpha(40),
                ),
                // 設定ペイン（AnimatedSizeで開閉）
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: _settingsExpanded ? 300 : 0,
                    child: _settingsExpanded
                        ? SettingsPane(showMonitor: _showMonitor)
                        : const SizedBox.shrink(),
                  ),
                ),
                // プレビューペイン
                const Expanded(flex: 4, child: PreviewPane()),
                // 縦区切り線
                VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: colorScheme.outlineVariant.withAlpha(40),
                ),
                // プロンプトペイン
                const Expanded(flex: 4, child: PromptPane()),
              ],
            );
          } else if (width >= 600) {
            return const Row(
              children: [
                Expanded(flex: 1, child: PreviewPane()),
                Expanded(flex: 1, child: PromptPane()),
              ],
            );
          } else {
            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(
                        icon: PhosphorIcon(PhosphorIcons.gear()),
                        text: L.of(locale, 'settings'),
                      ),
                      Tab(
                        icon: PhosphorIcon(PhosphorIcons.image()),
                        text: L.of(locale, 'generation_preview'),
                      ),
                      Tab(
                        icon: PhosphorIcon(PhosphorIcons.textAa()),
                        text: L.of(locale, 'prompt'),
                      ),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        SettingsPane(showMonitor: false),
                        PreviewPane(),
                        PromptPane(),
                      ],
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

  Widget _buildToolbarButton(
    BuildContext context, {
    required PhosphorIconData icon,
    required PhosphorIconData activeIcon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onPressed,
    String? label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: isActive
            ? colorScheme.primaryContainer.withAlpha(120)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: label != null
                  ? Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    )
                  : PhosphorIcon(
                      isActive ? activeIcon : icon,
                      size: 20,
                      color: isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
