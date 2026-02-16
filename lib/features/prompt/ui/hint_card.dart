import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';

class HintCard extends ConsumerWidget {
  const HintCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = ref.watch(localeProvider);

    return Card(
      elevation: 4,
      shadowColor: colorScheme.shadow.withAlpha(40),
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.lightbulbFilament(PhosphorIconsStyle.fill),
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  L.of(locale, 'hint_title'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
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
      ),
    );
  }

  Widget _buildHintItem(
    BuildContext context, {
    required PhosphorIconData icon,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhosphorIcon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.ibmPlexSansJp(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
