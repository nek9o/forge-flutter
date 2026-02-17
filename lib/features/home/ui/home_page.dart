import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../../preview/ui/preview_pane.dart';
import '../../prompt/ui/prompt_pane.dart';
import '../../settings/ui/detailed_settings_dialog.dart';
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
  double _settingsWidth = 280;
  double _previewSplit = 0.5;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            if (width >= 1200) {
              const sidebarWidth = 56.0;
              const dividerWidth = 6.0;
              const minSettingsWidth = 220.0;
              const maxSettingsWidth = 520.0;
              const minPreviewWidth = 360.0;
              const minPromptWidth = 360.0;

              final settingsPaneWidth = _settingsExpanded
                  ? _settingsWidth
                  : 0.0;

              final available =
                  constraints.maxWidth -
                  sidebarWidth -
                  settingsPaneWidth -
                  (_settingsExpanded ? dividerWidth : 0.0) -
                  dividerWidth;

              final clampedAvailable = available < 0 ? 0.0 : available;
              final minSplit = clampedAvailable == 0
                  ? 0.0
                  : (minPreviewWidth / clampedAvailable);
              final maxSplit = clampedAvailable == 0
                  ? 1.0
                  : (1.0 - (minPromptWidth / clampedAvailable));

              final split = _previewSplit.clamp(minSplit, maxSplit);
              final previewWidth = clampedAvailable * split;
              final promptWidth = clampedAvailable - previewWidth;

              return SizedBox.expand(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // サイドツールバー
                    Container(
                      width: sidebarWidth,
                      decoration: BoxDecoration(
                        color: FTheme.of(context).colors.background,
                        border: Border(
                          right: BorderSide(
                            color: FTheme.of(context).colors.border,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          // アプリアイコン
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: PhosphorIcon(
                              PhosphorIcons.diamondsFour(
                                PhosphorIconsStyle.fill,
                              ),
                              color: FTheme.of(context).colors.primary,
                              size: 28,
                            ),
                          ),
                          // 設定トグル
                          _buildToolbarButton(
                            context,
                            icon: PhosphorIcons.gear(),
                            isActive: _settingsExpanded,
                            tooltip: L.of(locale, 'settings_panel'),
                            onPressed: () {
                              setState(() {
                                _settingsExpanded = !_settingsExpanded;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          // システムモニタートグル
                          _buildToolbarButton(
                            context,
                            icon: PhosphorIcons.chartLine(),
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
                          const SizedBox(height: 8),
                          // 詳細設定ボタン
                          _buildToolbarButton(
                            context,
                            icon: PhosphorIcons.sliders(),
                            isActive: false,
                            tooltip: L.of(locale, 'detailed_settings_tooltip'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    const DetailedSettingsDialog(),
                              );
                            },
                          ),
                          const Spacer(),
                          // 言語切り替え
                          _buildToolbarButton(
                            context,
                            icon: PhosphorIcons.translate(),
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
                          const SizedBox(height: 8),
                          // ライセンス情報
                          _buildToolbarButton(
                            context,
                            icon: PhosphorIcons.scroll(),
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
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    // 設定ペイン（AnimatedSizeで開閉）
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: _settingsExpanded ? settingsPaneWidth : 0,
                        child: _settingsExpanded
                            ? SettingsPane(showMonitor: _showMonitor)
                            : const SizedBox.shrink(),
                      ),
                    ),
                    if (_settingsExpanded)
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _settingsWidth =
                                  (_settingsWidth + details.delta.dx).clamp(
                                    minSettingsWidth,
                                    maxSettingsWidth,
                                  );
                            });
                          },
                          child: SizedBox(
                            width: dividerWidth,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: FTheme.of(
                                  context,
                                ).colors.border.withAlpha(60),
                              ),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(width: previewWidth, child: const PreviewPane()),
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragUpdate: (details) {
                          if (clampedAvailable <= 0) return;
                          setState(() {
                            _previewSplit =
                                (_previewSplit +
                                        (details.delta.dx / clampedAvailable))
                                    .clamp(0.0, 1.0);
                          });
                        },
                        child: SizedBox(
                          width: dividerWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: FTheme.of(
                                context,
                              ).colors.border.withAlpha(60),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: promptWidth, child: const PromptPane()),
                  ],
                ),
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
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, {
    required PhosphorIconData icon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onPressed,
    String? label,
  }) {
    final fTheme = FTheme.of(context);

    return FTooltip(
      tipBuilder: (context, controller) => Text(tooltip),
      child: SizedBox(
        width: 56,
        height: 44,
        child: Align(
          alignment: Alignment.center,
          child: Material(
            color: isActive
                ? fTheme.colors.primary.withAlpha(30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Align(
                  alignment: Alignment.center,
                  child: label != null
                      ? Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? fTheme.colors.primary
                                : fTheme.colors.foreground,
                          ),
                        )
                      : PhosphorIcon(
                          icon,
                          size: 24,
                          color: isActive
                              ? fTheme.colors.primary
                              : fTheme.colors.foreground,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
