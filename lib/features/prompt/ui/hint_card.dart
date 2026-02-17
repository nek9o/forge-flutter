import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';

class HintCard extends ConsumerWidget {
  const HintCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FTheme.of(context);
    final locale = ref.watch(localeProvider);

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.lightbulbFilament(PhosphorIconsStyle.fill),
                size: 18,
                color: fTheme.colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                L.of(locale, 'hint_title'),
                style: TextStyle(
                  color: fTheme.colors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHintItem(
            context,
            icon: PhosphorIcons.keyboard(),
            text: L.of(locale, 'hint_chip_convert'),
          ),
          const SizedBox(height: 8),
          _buildHintItem(
            context,
            icon: PhosphorIcons.cursorClick(),
            text: L.of(locale, 'hint_edit_chip'),
          ),
          const SizedBox(height: 8),
          _buildHintItem(
            context,
            icon: PhosphorIcons.mouse(),
            text: L.of(locale, 'hint_weight'),
          ),
          const SizedBox(height: 8),
          _buildHintItem(
            context,
            icon: PhosphorIcons.dotsSixVertical(),
            text: L.of(locale, 'hint_reorder'),
          ),
          const SizedBox(height: 8),
          _buildHintItem(
            context,
            icon: PhosphorIcons.swatches(),
            text: L.of(locale, 'hint_lora'),
          ),
        ],
      ),
    );
  }

  Widget _buildHintItem(
    BuildContext context, {
    required PhosphorIconData icon,
    required String text,
  }) {
    final fTheme = FTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhosphorIcon(icon, size: 14, color: fTheme.colors.mutedForeground),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: fTheme.colors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}
