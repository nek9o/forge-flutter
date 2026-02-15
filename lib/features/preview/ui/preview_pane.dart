import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../prompt/store/prompt_store.dart';
import '../store/preview_store.dart';

class PreviewPane extends ConsumerWidget {
  const PreviewPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewState = ref.watch(previewStoreProvider);
    // prompt and negativePrompt are only needed for the button action,
    // so we don't watch them here to avoid rebuilds on every keystroke.

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(51),
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('生成プレビュー', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  onPressed: () {
                    if (previewState.base64Image != null) {
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
                    }
                  },
                  icon: const Icon(Icons.fullscreen),
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
                  borderRadius: BorderRadius.circular(12),
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
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(previewState.base64Image!),
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                        )
                      : const Center(child: Text('No Image Generated')),
                ),
              ),
            ),
          ),
          if (previewState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error: ${previewState.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: LinearProgressIndicator(value: previewState.progress),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: previewState.status == GenerationStatus.generating
                  ? null
                  : () {
                      final prompt = ref.read(promptProvider);
                      final negativePrompt = ref.read(negativePromptProvider);
                      ref
                          .read(previewStoreProvider.notifier)
                          .generateImage(prompt, negativePrompt);
                    },
              icon: previewState.status == GenerationStatus.generating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                previewState.status == GenerationStatus.generating
                    ? 'Generating...'
                    : 'Generate',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
