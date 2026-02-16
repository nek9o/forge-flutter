import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../store/preview_store.dart';
import 'png_info_pane.dart';
import 'png_info_tab.dart';

class PreviewPane extends ConsumerWidget {
  const PreviewPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewState = ref.watch(previewStoreProvider);
    final locale = ref.watch(localeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: colorScheme.surfaceContainerLow,
            child: TabBar(
              tabs: [
                Tab(text: L.of(locale, 'generation_preview')),
                Tab(text: 'PNG Info (D&D)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildGenerationPreview(context, ref, previewState),
                const PngInfoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationPreview(
    BuildContext context,
    WidgetRef ref,
    PreviewState previewState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
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
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      L.of(ref.read(localeProvider), 'generation_preview'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (previewState.base64Image != null)
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: EdgeInsets.zero,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              InteractiveViewer(
                                minScale: 0.1,
                                maxScale: 5.0,
                                child: Image.memory(
                                  base64Decode(previewState.base64Image!),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 20,
                                right: 20,
                                child: IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                  ),
                                  icon: PhosphorIcon(
                                    PhosphorIcons.x(),
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: PhosphorIcon(PhosphorIcons.arrowsOut(), size: 20),
                    tooltip: L.of(ref.read(localeProvider), 'fullscreen'),
                  ),
              ],
            ),
          ),
          // 画像プレビュー
          Expanded(
            child: Center(
              child: Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                color: colorScheme.surfaceContainerHighest,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: previewState.base64Image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            base64Decode(previewState.base64Image!),
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PhosphorIcon(
                                PhosphorIcons.imageSquare(),
                                size: 56,
                                color: colorScheme.onSurfaceVariant.withAlpha(
                                  80,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                L.of(ref.read(localeProvider), 'no_image'),
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withAlpha(120),
                                      fontWeight: FontWeight.w300,
                                    ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
          // エラー表示
          if (previewState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                color: colorScheme.errorContainer.withAlpha(60),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.warning(),
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${L.of(ref.read(localeProvider), 'error')}: ${previewState.errorMessage}',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // プログレスバー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                if (previewState.status == GenerationStatus.generating)
                  LinearProgressIndicator(
                    value: previewState.progress,
                    borderRadius: BorderRadius.circular(4),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // 生成ボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: FilledButton.icon(
              onPressed: previewState.status == GenerationStatus.generating
                  ? null
                  : () {
                      ref.read(previewStoreProvider.notifier).generateImage();
                    },
              icon: previewState.status == GenerationStatus.generating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : PhosphorIcon(PhosphorIcons.sparkle(), size: 20),
              label: Text(
                previewState.status == GenerationStatus.generating
                    ? '${L.of(ref.read(localeProvider), 'generate')}...'
                    : L.of(ref.read(localeProvider), 'generate'),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
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
}
