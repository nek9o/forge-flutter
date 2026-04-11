import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n.dart';
import '../../../core/layout_preferences.dart';
import '../../../core/pane_resize_stripe.dart';
import '../../../core/services/update_service.dart';
import '../../preview/ui/preview_pane.dart';
import '../../prompt/ui/prompt_pane.dart';
import '../../settings/store/settings_store.dart';
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
  bool _isDialogShown = false;
  bool _initialized = false;
  // 接続中ダイアログのContextを保持し、確実にポップできるようにする
  BuildContext? _reconnectDialogContext;
  // アップデートトーストを1回だけ表示するためのフラグ
  bool _isUpdateToastShown = false;

  @override
  void initState() {
    super.initState();
    _loadLayoutPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsStoreProvider.notifier).reconnect();
    });
  }

  Future<void> _loadLayoutPreferences() async {
    await LayoutPreferences.init();
    if (mounted) {
      setState(() {
        _settingsWidth = LayoutPreferences.getSettingsWidth();
        _previewSplit = LayoutPreferences.getPreviewSplit();
        _settingsExpanded = LayoutPreferences.getSettingsExpanded();
        _showMonitor = LayoutPreferences.getShowMonitor();
        _initialized = true;
      });
    }
  }

  Future<void> _saveLayoutPreferences() async {
    if (!_initialized) return;

    await LayoutPreferences.setSettingsWidth(_settingsWidth);
    await LayoutPreferences.setPreviewSplit(_previewSplit);
    await LayoutPreferences.setSettingsExpanded(_settingsExpanded);
    await LayoutPreferences.setShowMonitor(_showMonitor);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final fTheme = FTheme.of(context);

    // アップデート確認のトースト制御
    // 1回だけ右上にトーストを表示し、ユーザーが閉じるまで残す
    ref.listen<AsyncValue<UpdateInfo>>(updateCheckFutureProvider, (
      previous,
      next,
    ) {
      if (next is AsyncData && next.value != null && next.value!.hasUpdate) {
        if (!_isUpdateToastShown) {
          _isUpdateToastShown = true;
          showFToast(
            context: context,
            alignment: FToastAlignment.topRight,
            // 自動で消えさせず、ユーザーが明示的に閉じるか操作するまで表示する
            duration: null,
            icon: Icon(PhosphorIcons.arrowCircleUp()),
            title: Text(L.of(locale, 'update_available')),
            description: Text(
              '${L.of(locale, 'update_available_body')} (${next.value!.latestVersion})',
            ),
            suffixBuilder: (context, entry) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FButton(
                  size: FButtonSizeVariant.sm,
                  onPress: () async {
                    entry.dismiss();
                    final url = Uri.parse(next.value!.releaseUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  child: Text(L.of(locale, 'download_page')),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: entry.dismiss,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      PhosphorIcons.x(),
                      size: 20,
                      color: fTheme.colors.foreground,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    });

    // 接続確認中のダイアログ制御
    // ダイアログ自身のBuildContextをキャプチャして、
    // ナビゲーションスタックの状態に関わらず確実にポップできるようにする
    ref.listen<bool>(isReconnectingProvider, (previous, next) {
      if (next && !_isDialogShown) {
        _isDialogShown = true;
        showFDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext, style, animation) {
            // ダイアログのContextをフィールドに保持しておく
            _reconnectDialogContext = dialogContext;
            return FDialog(
              style: style,
              animation: animation,
              direction: Axis.vertical,
              title: Text(L.of(locale, 'checking_connection')),
              body: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 300),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [FProgress(), SizedBox(height: 16)],
                  ),
                ),
              ),
              actions: const [],
            );
          },
        ).then((_) => _isDialogShown = false);
      } else if (!next && _isDialogShown) {
        // キャプチャしたダイアログのContextが有効であればそこからポップし、
        // そうでなければフォールバックとしてrootNavigatorを使う
        final dialogCtx = _reconnectDialogContext;
        if (dialogCtx != null && dialogCtx.mounted) {
          Navigator.of(dialogCtx).pop();
        } else {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _reconnectDialogContext = null;
        _isDialogShown = false;
      }
    });

    return ColoredBox(
      color: fTheme.colors.background,
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            if (width >= 600) {
              const sidebarWidth = 56.0;
              const dividerWidth = 1.0;
              const minSettingsWidth = 260.0;
              const maxSettingsWidth = 480.0;

              /// 広いウィンドウ向けの目安。狭いときは [clampedAvailable] の半分まで下げる。
              const maxPaneMin = 320.0;

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
              final minHalf = clampedAvailable <= 0
                  ? 0.0
                  : math.min(maxPaneMin, clampedAvailable / 2);
              final minPreviewWidth = minHalf;
              final minPromptWidth = minHalf;

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
                child: Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // サイドツールバー
                        Container(
                          width: sidebarWidth,
                          decoration: BoxDecoration(
                            color: fTheme.colors.background,
                            border: Border(
                              right: BorderSide(
                                color: fTheme.colors.border.withAlpha(120),
                                width: 0.5,
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
                                  color: fTheme.colors.primary,
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
                                    _saveLayoutPreferences();
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
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
                              const SizedBox(height: 12),

                              // 詳細設定ボタン
                              _buildToolbarButton(
                                context,
                                icon: PhosphorIcons.sliders(),
                                isActive: false,
                                tooltip: L.of(
                                  locale,
                                  'detailed_settings_tooltip',
                                ),
                                onPressed: () {
                                  showFDialog(
                                    context: context,
                                    builder: (context, style, animation) =>
                                        DetailedSettingsDialog(
                                          style: style,
                                          animation: animation,
                                        ),
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
                              const SizedBox(height: 12),
                              // ライセンス情報
                              _buildToolbarButton(
                                context,
                                icon: PhosphorIcons.scroll(),
                                isActive: false,
                                tooltip: L.of(locale, 'license_info'),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const OssLicensePage(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        // 設定ペイン（幅はホーム側のリサイズに追従）
                        SizedBox(
                          width: _settingsExpanded ? settingsPaneWidth : 0,
                          child: _settingsExpanded
                              ? SettingsPane(showMonitor: _showMonitor)
                              : const SizedBox.shrink(),
                        ),
                        if (_settingsExpanded)
                          SizedBox(
                            width: dividerWidth,
                            child: const PaneResizeStripe(),
                          ),
                        SizedBox(
                          width: previewWidth,
                          child: const PreviewPane(),
                        ),
                        SizedBox(
                          width: dividerWidth,
                          child: const PaneResizeStripe(),
                        ),
                        SizedBox(width: promptWidth, child: const PromptPane()),
                      ],
                    ),
                    // --- リサイズハンドルのオーバーレイ ---
                    if (_settingsExpanded)
                      Positioned(
                        left: sidebarWidth + settingsPaneWidth - 3.5,
                        top: 0,
                        bottom: 0,
                        width: 8.0,
                        child: MouseRegion(
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
                            onHorizontalDragEnd: (details) {
                              _saveLayoutPreferences();
                            },
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ),
                    Positioned(
                      left:
                          sidebarWidth +
                          (_settingsExpanded
                              ? settingsPaneWidth + dividerWidth
                              : 0.0) +
                          previewWidth -
                          3.5,
                      top: 0,
                      bottom: 0,
                      width: 8.0,
                      child: MouseRegion(
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
                          onHorizontalDragEnd: (details) {
                            _saveLayoutPreferences();
                          },
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return FTabs(
                children: [
                  FTabEntry(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(PhosphorIcons.gear(), size: 16),
                        const SizedBox(width: 6),
                        Text(L.of(locale, 'settings')),
                      ],
                    ),
                    child: const SettingsPane(showMonitor: false),
                  ),
                  FTabEntry(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(PhosphorIcons.image(), size: 16),
                        const SizedBox(width: 6),
                        Text(L.of(locale, 'generation_preview')),
                      ],
                    ),
                    child: const PreviewPane(),
                  ),
                  FTabEntry(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(PhosphorIcons.textAa(), size: 16),
                        const SizedBox(width: 6),
                        Text(L.of(locale, 'prompt')),
                      ],
                    ),
                    child: const PromptPane(),
                  ),
                ],
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
        child: Center(
          child: Material(
            color: isActive
                ? fTheme.colors.primary.withAlpha(20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onPressed,
              hoverColor: fTheme.colors.foreground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: label != null
                    ? Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? fTheme.colors.primary
                              : fTheme.colors.foreground,
                        ),
                      )
                    : PhosphorIcon(
                        icon,
                        size: 20,
                        color: isActive
                            ? fTheme.colors.primary
                            : fTheme.colors.foreground,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
