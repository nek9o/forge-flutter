import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../prompt/services/prompt_parser.dart';
import '../../prompt/store/prompt_store.dart';
import '../../settings/models/sd_model.dart';
import '../../settings/store/settings_store.dart';
import '../store/preview_store.dart';

class PngInfoPane extends ConsumerWidget {
  final Map<String, dynamic>? metadata;
  final String? rawParameters;

  const PngInfoPane({super.key, this.metadata, this.rawParameters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(previewStoreProvider);
    final effectiveMetadata = metadata ?? state.metadata;
    final effectiveRawParameters = rawParameters ?? state.rawParameters;

    if (effectiveMetadata == null) {
      return const Center(child: Text("No PNG Info available"));
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PNG Info',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: () {
                    _sendToTxt2Img(ref, effectiveMetadata);
                  },
                  icon: const Icon(Icons.copy_all),
                  label: const Text('Send to Txt2Img'),
                ),
              ],
            ),
            const Divider(),
            if (effectiveMetadata.containsKey('prompt')) ...[
              const SizedBox(height: 8),
              Text('Prompt', style: Theme.of(context).textTheme.labelMedium),
              SelectableText(
                effectiveMetadata['prompt'] ?? '',
                style: GoogleFonts.geistMono(),
              ),
            ],
            if (effectiveMetadata.containsKey('negative_prompt')) ...[
              const SizedBox(height: 8),
              Text(
                'Negative Prompt',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              SelectableText(
                effectiveMetadata['negative_prompt'] ?? '',
                style: GoogleFonts.geistMono(),
              ),
            ],
            const SizedBox(height: 8),
            Text('Settings', style: Theme.of(context).textTheme.labelMedium),
            SelectableText(
              effectiveRawParameters
                      ?.split('\n')
                      .lastWhere(
                        (line) => line.startsWith('Steps: '),
                        orElse: () => '',
                      ) ??
                  '',
              style: GoogleFonts.geistMono(),
            ),
          ],
        ),
      ),
    );
  }

  void _sendToTxt2Img(WidgetRef ref, Map<String, dynamic> metadata) {
    // 1. Update Prompt
    if (metadata.containsKey('prompt')) {
      final promptText = metadata['prompt'] as String;
      ref.read(promptProvider.notifier).state = promptText;

      // Also update tags (important for UI sync)
      final tags = PromptParser.parse(promptText);
      ref.read(promptTagsProvider.notifier).setTags(tags);
    }

    // 2. Update Negative Prompt
    if (metadata.containsKey('negative_prompt')) {
      final negPromptText = metadata['negative_prompt'] as String;
      ref.read(negativePromptProvider.notifier).state = negPromptText;

      final negTags = PromptParser.parse(negPromptText);
      ref.read(negativePromptTagsProvider.notifier).setTags(negTags);
    }

    // 3. Update Settings
    ref.read(generationSettingsProvider.notifier).updateFromMetadata(metadata);

    // 4. Update Model if available (async)
    if (metadata.containsKey('model') || metadata.containsKey('model_hash')) {
      final modelName = metadata['model'] as String?;
      final modelHash = metadata['model_hash'] as String?;

      ref.read(sdModelsProvider).whenData((models) {
        SDModel? targetModel;

        if (modelHash != null) {
          targetModel = models.firstWhere(
            (m) => m.hash == modelHash || m.sha256.startsWith(modelHash),
            orElse: () => models.firstWhere(
              (m) => m.title.contains(modelHash),
              orElse: () => models.firstWhere(
                (m) => modelName != null && m.modelName == modelName,
                orElse: () => models.firstWhere(
                  (m) => modelName != null && m.title.contains(modelName),
                ),
              ),
            ),
          );
        } else if (modelName != null) {
          targetModel = models.firstWhere(
            (m) => m.modelName == modelName || m.title.contains(modelName),
          );
        }

        if (targetModel != null) {
          ref
              .read(settingsStoreProvider.notifier)
              .selectModel(targetModel.title);
        }
      });
    }

    ScaffoldMessenger.of(
      ref.context,
    ).showSnackBar(const SnackBar(content: Text('Parameters sent to Txt2Img')));
  }
}
