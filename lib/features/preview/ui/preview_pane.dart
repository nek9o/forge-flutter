import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:native_context_menu/native_context_menu.dart' as ncm;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
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
            border: Border(bottom: BorderSide(color: fTheme.colors.border)),
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
        onPress: () => setState(() => _selectedIndex = index),
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

    return ColoredBox(
      color: fTheme.colors.background,
      child: Column(
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                      L.of(ref.read(localeProvider), 'generation_preview'),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        fontSize: 20,
                        color: fTheme.colors.foreground,
                      ),
                    ),
                  ],
                ),
                if (previewState.base64Image != null)
                  FButton.icon(
                    onPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: EdgeInsets.zero,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ncm.ContextMenuRegion(
                                onItemSelected: (item) {
                                  if (item.title ==
                                      L.of(ref.read(localeProvider), 'save')) {
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
                                child: InteractiveViewer(
                                  minScale: 0.1,
                                  maxScale: 5.0,
                                  child: Image.memory(
                                    base64Decode(previewState.base64Image!),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 20,
                                right: 20,
                                child: FButton.icon(
                                  onPress: () => Navigator.of(context).pop(),
                                  child: PhosphorIcon(
                                    PhosphorIcons.x(),
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: PhosphorIcon(PhosphorIcons.arrowsOut(), size: 20),
                  ),
              ],
            ),
          ),
          // 画像プレビュー
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: fTheme.colors.muted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: fTheme.colors.border),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: previewState.base64Image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ncm.ContextMenuRegion(
                              onItemSelected: (item) {
                                if (item.title ==
                                    L.of(ref.read(localeProvider), 'save')) {
                                  ref
                                      .read(previewStoreProvider.notifier)
                                      .saveImage();
                                }
                              },
                              menuItems: [
                                ncm.MenuItem(
                                  title: L.of(ref.read(localeProvider), 'save'),
                                ),
                              ],
                              child: Image.memory(
                                base64Decode(previewState.base64Image!),
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PhosphorIcon(
                                  PhosphorIcons.imageSquare(),
                                  size: 56,
                                  color: fTheme.colors.mutedForeground
                                      .withAlpha(80),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  L.of(ref.read(localeProvider), 'no_image'),
                                  style: TextStyle(
                                    color: fTheme.colors.mutedForeground,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          // エラー表示
          if (previewState.errorMessage != null && !isConnectionError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FAlert(
                icon: PhosphorIcon(PhosphorIcons.warning()),
                title: Text(
                  '${L.of(ref.read(localeProvider), 'error')}: ${previewState.errorMessage}',
                ),
              ),
            ),
          // プログレスバー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                if (previewState.status == GenerationStatus.generating) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: previewState.progress,
                      backgroundColor: fTheme.colors.muted,
                      valueColor: AlwaysStoppedAnimation(fTheme.colors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(previewState.progress * 100).toInt()}%',
                    style: TextStyle(
                      color: fTheme.colors.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
          // 生成ボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: previewState.status == GenerationStatus.generating
                    ? null
                    : () {
                        ref.read(previewStoreProvider.notifier).generateImage();
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (previewState.status != GenerationStatus.generating) ...[
                      PhosphorIcon(PhosphorIcons.sparkle(), size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      previewState.status == GenerationStatus.generating
                          ? L.of(ref.read(localeProvider), 'generating')
                          : L.of(ref.read(localeProvider), 'generate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // PNG Info
          const Expanded(
            flex: 2,
            child: SingleChildScrollView(child: PngInfoPane()),
          ),
        ],
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
