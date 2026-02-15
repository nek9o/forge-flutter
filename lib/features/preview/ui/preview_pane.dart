import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../store/preview_store.dart';
import 'png_info_pane.dart';
import 'png_info_tab.dart';

class PreviewPane extends ConsumerWidget {
  const PreviewPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewState = ref.watch(previewStoreProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: const TabBar(
              tabs: [
                Tab(text: '生成プレビュー'),
                Tab(text: 'PNG Info (D&D)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Generation Preview
                _buildGenerationPreview(context, ref, previewState),
                // Tab 2: PNG Info Drag & Drop
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(26),
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '生成結果',
                  style: Theme.of(context).textTheme.titleLarge,
                ), // Changed text
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
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fullscreen),
                    tooltip: 'フルスクリーン表示',
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(77),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
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
                              Icon(
                                Icons.image_outlined,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '画像が生成されていません',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (previewState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'エラー: ${previewState.errorMessage}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: previewState.status == GenerationStatus.generating
                  ? null
                  : () {
                      ref.read(previewStoreProvider.notifier).generateImage();
                    },
              icon: previewState.status == GenerationStatus.generating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                previewState.status == GenerationStatus.generating
                    ? '生成中...'
                    : '画像を生成',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: SingleChildScrollView(child: PngInfoPane()),
          ),
        ],
      ),
    );
  }
}
