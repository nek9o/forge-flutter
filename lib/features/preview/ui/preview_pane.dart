import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:native_context_menu/native_context_menu.dart' as ncm;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../../../core/layout_preferences.dart';
import '../../../core/providers.dart';
import '../store/preview_store.dart';
import 'png_info_pane.dart';
import 'png_info_tab.dart';

class PreviewPane extends ConsumerStatefulWidget {
  const PreviewPane({super.key});

  @override
  ConsumerState<PreviewPane> createState() => _PreviewPaneState();
}

class _PreviewPaneState extends ConsumerState<PreviewPane> {
  int _selectedIndex = 0;
  String? _lastShownConnectionError;
  double _previewVerticalSplit = 0.5;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadLayoutPreferences();
  }

  Future<void> _loadLayoutPreferences() async {
    await LayoutPreferences.init();
    if (mounted) {
      setState(() {
        _selectedIndex = LayoutPreferences.getPreviewTabIndex();
        _previewVerticalSplit = LayoutPreferences.getPreviewVerticalSplit();
        _initialized = true;
      });
    }
  }

  Future<void> _saveLayoutPreferences() async {
    if (!_initialized) return;

    await LayoutPreferences.setPreviewTabIndex(_selectedIndex);
    await LayoutPreferences.setPreviewVerticalSplit(_previewVerticalSplit);
  }

  @override
  Widget build(BuildContext context) {
    final previewState = ref.watch(previewStoreProvider);
    final locale = ref.watch(localeProvider);
    final fTheme = FTheme.of(context);

    final errorMessage = previewState.errorMessage;
    final isConnectionError =
        errorMessage != null && _looksLikeApiConnectionFailure(errorMessage);

    if (isConnectionError && _lastShownConnectionError != errorMessage) {
      _lastShownConnectionError = errorMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showApiConnectionErrorDialog(context);
      });
    }

    return Column(
      children: [
        // カスタムタブヘッダー
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: fTheme.colors.border.withAlpha(120),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildTabButton(
                context,
                index: 0,
                label: L.of(locale, 'generation_preview'),
                icon: PhosphorIcons.image(),
              ),
              _buildTabButton(
                context,
                index: 1,
                label: L.of(locale, 'png_info_tab'),
                icon: PhosphorIcons.info(),
              ),
            ],
          ),
        ),
        // コンテンツエリア
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildGenerationPreview(context, ref, previewState),
              const PngInfoTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required int index,
    required String label,
    required IconData icon,
  }) {
    final fTheme = FTheme.of(context);
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: FTappable(
        onPress: () {
          setState(() {
            _selectedIndex = index;
            _saveLayoutPreferences();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? fTheme.colors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? fTheme.colors.primary
                    : fTheme.colors.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? fTheme.colors.foreground
                      : fTheme.colors.mutedForeground,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerationPreview(
    BuildContext context,
    WidgetRef ref,
    PreviewState previewState,
  ) {
    final fTheme = FTheme.of(context);
    final errorMessage = previewState.errorMessage;
    final isConnectionError =
        errorMessage != null && _looksLikeApiConnectionFailure(errorMessage);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        const headerHeight = 60.0;
        const toolbarHeight = 100.0;
        const dividerHeight = 12.0;

        final availableHeight =
            totalHeight - headerHeight - toolbarHeight - dividerHeight;
        final clampedAvailable = availableHeight < 0 ? 0.0 : availableHeight;

        final previewHeight = clampedAvailable * _previewVerticalSplit;

        return ColoredBox(
          color: fTheme.colors.background,
          child: Column(
            children: [
              // ヘッダー
              SizedBox(
                height: headerHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.image(),
                            size: 20,
                            color: fTheme.colors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            L.of(
                              ref.read(localeProvider),
                              'generation_preview',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                              fontSize: 18,
                              color: fTheme.colors.foreground,
                            ),
                          ),
                        ],
                      ),
                      if (previewState.imageBytes != null)
                        FButton.icon(
                          onPress: () {
                            showDialog(
                              context: context,
                              builder: (context) => Consumer(
                                builder: (context, ref, _) {
                                  final state = ref.watch(previewStoreProvider);
                                  return Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: EdgeInsets.zero,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (state.imageBytes != null)
                                          ncm.ContextMenuRegion(
                                            onItemSelected: (item) {
                                              if (item.title ==
                                                  L.of(
                                                    ref.read(localeProvider),
                                                    'save',
                                                  )) {
                                                ref
                                                    .read(
                                                      previewStoreProvider
                                                          .notifier,
                                                    )
                                                    .saveImage();
                                              }
                                            },
                                            menuItems: [
                                              ncm.MenuItem(
                                                title: L.of(
                                                  ref.read(localeProvider),
                                                  'save',
                                                ),
                                              ),
                                            ],
                                            child: InteractiveViewer(
                                              minScale: 0.1,
                                              maxScale: 10.0,
                                              child: Image.memory(
                                                state.imageBytes!,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        if (state.images.length > 1) ...[
                                          // 左右のナビゲーションボタン
                                          Positioned.fill(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                _buildNavigationButton(
                                                  context,
                                                  icon:
                                                      PhosphorIcons.caretLeft(),
                                                  onPressed:
                                                      state.currentIndex > 0
                                                      ? () => ref
                                                            .read(
                                                              previewStoreProvider
                                                                  .notifier,
                                                            )
                                                            .setIndex(
                                                              state.currentIndex -
                                                                  1,
                                                            )
                                                      : null,
                                                ),
                                                _buildNavigationButton(
                                                  context,
                                                  icon:
                                                      PhosphorIcons.caretRight(),
                                                  onPressed:
                                                      state.currentIndex <
                                                          state.images.length -
                                                              1
                                                      ? () => ref
                                                            .read(
                                                              previewStoreProvider
                                                                  .notifier,
                                                            )
                                                            .setIndex(
                                                              state.currentIndex +
                                                                  1,
                                                            )
                                                      : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // インデックス表示
                                          Positioned(
                                            bottom: 30,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${state.currentIndex + 1} / ${state.images.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        Positioned(
                                          top: 20,
                                          right: 20,
                                          child: FButton.icon(
                                            onPress: () =>
                                                Navigator.of(context).pop(),
                                            child: PhosphorIcon(
                                              PhosphorIcons.x(),
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          child: PhosphorIcon(
                            PhosphorIcons.arrowsOut(),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // 画像プレビュー
              SizedBox(
                height: previewHeight,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: fTheme.colors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: fTheme.colors.border.withAlpha(120),
                          width: 0.5,
                        ),
                      ),
                      child: previewState.imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  ncm.ContextMenuRegion(
                                    onItemSelected: (item) {
                                      if (item.title ==
                                          L.of(
                                            ref.read(localeProvider),
                                            'save',
                                          )) {
                                        ref
                                            .read(previewStoreProvider.notifier)
                                            .saveImage();
                                      }
                                    },
                                    menuItems: [
                                      ncm.MenuItem(
                                        title: L.of(
                                          ref.read(localeProvider),
                                          'save',
                                        ),
                                      ),
                                    ],
                                    child: Center(
                                      child: Image.memory(
                                        previewState.imageBytes!,
                                        fit: BoxFit.contain,
                                        gaplessPlayback: true,
                                        cacheWidth: 1024,
                                      ),
                                    ),
                                  ),
                                  if (previewState.images.length > 1) ...[
                                    // 左右のナビゲーションボタン
                                    Positioned.fill(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildNavigationButton(
                                            context,
                                            icon: PhosphorIcons.caretLeft(),
                                            onPressed:
                                                previewState.currentIndex > 0
                                                ? () => ref
                                                      .read(
                                                        previewStoreProvider
                                                            .notifier,
                                                      )
                                                      .setIndex(
                                                        previewState
                                                                .currentIndex -
                                                            1,
                                                      )
                                                : null,
                                          ),
                                          _buildNavigationButton(
                                            context,
                                            icon: PhosphorIcons.caretRight(),
                                            onPressed:
                                                previewState.currentIndex <
                                                    previewState.images.length -
                                                        1
                                                ? () => ref
                                                      .read(
                                                        previewStoreProvider
                                                            .notifier,
                                                      )
                                                      .setIndex(
                                                        previewState
                                                                .currentIndex +
                                                            1,
                                                      )
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // インデックス表示
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${previewState.currentIndex + 1} / ${previewState.images.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  PhosphorIcon(
                                    PhosphorIcons.imageSquare(),
                                    size: 48,
                                    color: fTheme.colors.mutedForeground
                                        .withAlpha(80),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    L.of(ref.read(localeProvider), 'no_image'),
                                    style: TextStyle(
                                      color: fTheme.colors.mutedForeground,
                                      fontWeight: FontWeight.w300,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              // リサイズ境界線
              MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (details) {
                    if (clampedAvailable <= 0) return;
                    setState(() {
                      _previewVerticalSplit =
                          (_previewVerticalSplit +
                                  (details.delta.dy / clampedAvailable))
                              .clamp(0.05, 0.95);
                    });
                  },
                  onVerticalDragEnd: (details) {
                    _saveLayoutPreferences();
                  },
                  child: SizedBox(
                    height: dividerHeight,
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                          color: fTheme.colors.border.withAlpha(160),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 下部エリア（コントロールと情報）
              Expanded(
                child: Column(
                  children: [
                    // エラー表示
                    if (previewState.errorMessage != null && !isConnectionError)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FAlert(
                          icon: PhosphorIcon(PhosphorIcons.warning()),
                          title: Text(
                            '${L.of(ref.read(localeProvider), 'error')}: ${previewState.errorMessage}',
                          ),
                        ),
                      ),
                    // プログレスバー
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          if (previewState.status ==
                              GenerationStatus.generating) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: previewState.progress,
                                backgroundColor: fTheme.colors.muted,
                                valueColor: AlwaysStoppedAnimation(
                                  fTheme.colors.primary,
                                ),
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(previewState.progress * 100).toInt()}%',
                              style: TextStyle(
                                color: fTheme.colors.mutedForeground,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // 生成ボタン
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: FButton(
                          onPress:
                              previewState.status == GenerationStatus.generating
                              ? null
                              : () {
                                  ref
                                      .read(previewStoreProvider.notifier)
                                      .generateImage();
                                },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (previewState.status !=
                                  GenerationStatus.generating) ...[
                                PhosphorIcon(PhosphorIcons.sparkle(), size: 20),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                previewState.status ==
                                        GenerationStatus.generating
                                    ? L.of(
                                        ref.read(localeProvider),
                                        'generating',
                                      )
                                    : L.of(
                                        ref.read(localeProvider),
                                        'generate',
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // PNG Info
                    const Expanded(
                      child: SingleChildScrollView(child: PngInfoPane()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.black.withOpacity(0.3),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: 24,
              color: onPressed != null
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  bool _looksLikeApiConnectionFailure(String message) {
    final m = message.toLowerCase();
    return m.contains('failed to connect') ||
        m.contains('socketexception') ||
        m.contains('connection refused') ||
        m.contains('errno = 111') ||
        m.contains('errno = 61') ||
        m.contains('os error');
  }

  void _showApiConnectionErrorDialog(BuildContext context) {
    final dialogLocale = ref.read(localeProvider);

    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style,
        animation: animation,
        direction: Axis.vertical,
        title: Text(L.of(dialogLocale, 'api_connection_error_title')),
        body: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 520, maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(L.of(dialogLocale, 'api_connection_error_body')),
              const SizedBox(height: 12),
              Text(L.of(dialogLocale, 'api_connection_error_body2')),
              const SizedBox(height: 16),
              FLabel(
                axis: Axis.vertical,
                label: Text(L.of(dialogLocale, 'api_url')),
                child: FTextField(
                  control: FTextFieldControl.managed(
                    initial: TextEditingValue(text: ref.read(apiUrlProvider)),
                    onChange: (value) {
                      ref.read(apiUrlProvider.notifier).state = value.text;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(),
            child: Text(L.of(dialogLocale, 'close')),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () {
              Navigator.of(context).pop();
              ref.invalidate(previewStoreProvider);
              ref.read(previewStoreProvider.notifier).generateImage();
            },
            child: Text(L.of(dialogLocale, 'reconnect')),
          ),
          FButton(
            onPress: () {
              Navigator.of(context).pop();
              ref.read(previewStoreProvider.notifier).generateImage();
            },
            child: Text(L.of(dialogLocale, 'retry')),
          ),
        ],
      ),
    );
  }
}
