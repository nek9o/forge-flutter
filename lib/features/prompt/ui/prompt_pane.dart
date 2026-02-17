import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:native_context_menu/native_context_menu.dart' as ncm;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../store/prompt_store.dart';
import 'negative_prompt_editor.dart';
import 'prompt_editor.dart';

class PromptPane extends ConsumerWidget {
  const PromptPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = ref.watch(localeProvider);

    return ncm.ContextMenuRegion(
      onItemSelected: (item) {},
      menuItems: [
        ncm.MenuItem(title: L.of(locale, 'clear')),
        ncm.MenuItem(title: L.of(locale, 'select_all')),
      ],
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            left: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プロンプトヘッダー
            Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.textAa(),
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  L.of(locale, 'prompt'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                _buildHeaderButton(
                  context,
                  tooltip: L.of(locale, 'hint'),
                  onPressed: () {
                    final current = ref.read(promptHintVisibleProvider);
                    ref.read(promptHintVisibleProvider.notifier).state =
                        !current;
                  },
                  icon: PhosphorIcon(
                    ref.watch(promptHintVisibleProvider)
                        ? PhosphorIcons.lightbulbFilament(
                            PhosphorIconsStyle.fill,
                          )
                        : PhosphorIcons.lightbulbFilament(),
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Expanded(flex: 3, child: PromptEditor()),
            const SizedBox(height: 24),
            // ネガティブプロンプトヘッダー
            Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.prohibit(),
                  size: 20,
                  color: colorScheme.error.withAlpha(180),
                ),
                const SizedBox(width: 10),
                Text(
                  L.of(locale, 'negative_prompt'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                _buildHeaderButton(
                  context,
                  tooltip: L.of(locale, 'clear'),
                  onPressed: () {
                    ref.read(negativePromptTagsProvider.notifier).setTags([]);
                    ref.read(negativePromptProvider.notifier).state = '';
                  },
                  icon: PhosphorIcon(
                    PhosphorIcons.trash(),
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Expanded(flex: 2, child: NegativePromptEditor()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required String tooltip,
    required VoidCallback onPressed,
    required Widget icon,
  }) {
    return FTooltip(
      tipBuilder: (context, controller) => Text(tooltip),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(padding: const EdgeInsets.all(8.0), child: icon),
        ),
      ),
    );
  }
}
