import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_context_menu/native_context_menu.dart' as ncm;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
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
        ncm.MenuItem(title: 'Clear'),
        ncm.MenuItem(title: 'Select All'),
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
                  size: 18,
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
              ],
            ),
            const SizedBox(height: 16),
            const Expanded(flex: 2, child: NegativePromptEditor()),
          ],
        ),
      ),
    );
  }
}
