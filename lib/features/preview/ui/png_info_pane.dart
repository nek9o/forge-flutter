import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
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
    final fTheme = FTheme.of(context);
    final locale = ref.watch(localeProvider);

    if (effectiveMetadata == null) {
      return Center(
        child: Text(
          L.of(locale, 'no_png_info'),
          style: TextStyle(
            color: fTheme.colors.mutedForeground,
            fontWeight: FontWeight.w300,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: FCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.info(),
                      size: 18,
                      color: fTheme.colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      L.of(locale, 'png_info'),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        fontSize: 16,
                        color: fTheme.colors.foreground,
                      ),
                    ),
                  ],
                ),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () {
                    _sendToTxt2Img(ref, effectiveMetadata);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(PhosphorIcons.arrowSquareOut(), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        L.of(locale, 'send_to_txt2img'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const FDivider(),
            const SizedBox(height: 12),
            if (effectiveMetadata.containsKey('prompt')) ...[
              Text(
                L.of(locale, 'prompt'),
                style: TextStyle(
                  color: fTheme.colors.mutedForeground,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                effectiveMetadata['prompt'] ?? '',
                style: GoogleFonts.geistMono(
                  fontSize: 12,
                  color: fTheme.colors.foreground,
                ),
              ),
            ],
            if (effectiveMetadata.containsKey('negative_prompt')) ...[
              const SizedBox(height: 16),
              Text(
                L.of(locale, 'negative_prompt'),
                style: TextStyle(
                  color: fTheme.colors.mutedForeground,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                effectiveMetadata['negative_prompt'] ?? '',
                style: GoogleFonts.geistMono(
                  fontSize: 12,
                  color: fTheme.colors.foreground,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              L.of(locale, 'settings'),
              style: TextStyle(
                color: fTheme.colors.mutedForeground,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              effectiveRawParameters
                      ?.split('\n')
                      .lastWhere(
                        (line) => line.startsWith('Steps: '),
                        orElse: () => '',
                      ) ??
                  '',
              style: GoogleFonts.geistMono(
                fontSize: 12,
                color: fTheme.colors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendToTxt2Img(WidgetRef ref, Map<String, dynamic> metadata) {
    if (metadata.containsKey('prompt')) {
      final promptText = metadata['prompt'] as String;
      ref.read(promptProvider.notifier).state = promptText;

      final tags = PromptParser.parse(promptText);
      ref.read(promptTagsProvider.notifier).setTags(tags);
    }

    if (metadata.containsKey('negative_prompt')) {
      final negPromptText = metadata['negative_prompt'] as String;
      ref.read(negativePromptProvider.notifier).state = negPromptText;

      final negTags = PromptParser.parse(negPromptText);
      ref.read(negativePromptTagsProvider.notifier).setTags(negTags);
    }

    ref.read(generationSettingsProvider.notifier).updateFromMetadata(metadata);

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

    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(content: Text(L.of(ref.read(localeProvider), 'params_sent'))),
    );
  }
}
