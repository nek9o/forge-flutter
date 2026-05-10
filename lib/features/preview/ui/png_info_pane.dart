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
            const SizedBox(height: 8),
            ..._buildMetadataSections(context, effectiveMetadata),
            if (!effectiveMetadata.containsKey('steps') && effectiveRawParameters != null) ...[
              const SizedBox(height: 6),
              SelectableText(
                effectiveRawParameters
                        .split('\n')
                        .lastWhere(
                          (line) => line.trim().startsWith('Steps: '),
                          orElse: () => '',
                        ),
                style: GoogleFonts.geistMono(
                  fontSize: 12,
                  color: fTheme.colors.foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMetadataSections(BuildContext context, Map<String, dynamic> metadata) {
    final chips = <Widget>[];
    final longItems = <Widget>[];

    final displayedKeys = <String>{
      'prompt',
      'negative_prompt',
      'steps',
      'sampler',
      'cfg_scale',
      'seed',
      'width',
      'height',
      'model',
      'model_hash',
      'scheduler',
      'parameters',
      // 標準チップとして表示する項目の元キー名も除外対象にする
      'Steps',
      'Sampler',
      'CFG scale',
      'cfg scale',
      'Seed',
      'Size',
      'size',
      'Model',
      'Model hash',
      'model hash',
      'Schedule',
      'schedule',
      'Scheduler',
      'Schedule type',
      'schedule_type',
    };

    // Build standard chips in order
    void addChip(String label, String value) {
      chips.add(_buildSettingChip(context, label, value));
    }

    if (metadata.containsKey('steps')) {
      addChip('Steps', metadata['steps'].toString());
    }
    if (metadata.containsKey('sampler')) {
      addChip('Sampler', metadata['sampler'].toString());
    }
    if (metadata.containsKey('scheduler')) {
      addChip('Schedule', metadata['scheduler'].toString());
    }
    if (metadata.containsKey('cfg_scale')) {
      addChip('CFG', metadata['cfg_scale'].toString());
    }
    if (metadata.containsKey('seed')) {
      addChip('Seed', metadata['seed'].toString());
    }
    if (metadata.containsKey('width') && metadata.containsKey('height')) {
      addChip('Size', '${metadata['width']}x${metadata['height']}');
    }
    if (metadata.containsKey('model')) {
      addChip('Model', metadata['model'].toString());
    }

    // Build chips for everything else
    final sortedKeys = metadata.keys.toList()..sort();
    for (final key in sortedKeys) {
      final snakeKey = key.toLowerCase().replaceAll(' ', '_');
      if (displayedKeys.contains(key) || displayedKeys.contains(snakeKey)) {
        continue;
      }

      final value = metadata[key];
      if (value == null || value.toString().isEmpty) continue;

      final valueStr = value.toString();

      // 先に両方のキーを displayedKeys に登録して重複を防ぐ
      displayedKeys.add(key);
      displayedKeys.add(snakeKey);

      // If value is long or contains many commas/special chars, treat as long item
      if (valueStr.length > 50 || key.toLowerCase().contains('hashes')) {
        longItems.add(_buildLongSettingItem(context, _formatKey(key), valueStr));
      } else {
        chips.add(_buildSettingChip(context, _formatKey(key), valueStr));
      }
    }

    return [
      if (chips.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
      if (longItems.isNotEmpty) ...[
        const SizedBox(height: 16),
        ...longItems,
      ],
    ];
  }

  Widget _buildLongSettingItem(BuildContext context, String label, String value) {
    final fTheme = FTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fTheme.colors.mutedForeground,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: GoogleFonts.geistMono(
              fontSize: 11,
              color: fTheme.colors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    // If it's already CamelCase or has spaces, keep it
    if (key.contains(' ') || RegExp(r'[A-Z]').hasMatch(key)) {
      return key;
    }
    // Otherwise convert snake_case to Title Case
    return key.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Widget _buildSettingChip(BuildContext context, String label, String value) {
    final fTheme = FTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fTheme.colors.secondary.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fTheme.colors.border.withAlpha(40)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fTheme.colors.mutedForeground,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.geistMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
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
