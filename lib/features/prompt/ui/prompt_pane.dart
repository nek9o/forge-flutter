import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../store/prompt_store.dart';
import 'negative_prompt_editor.dart';
import 'prompt_editor.dart';

class PromptPane extends ConsumerWidget {
  const PromptPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fTheme = FTheme.of(context);
    final locale = ref.watch(localeProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: fTheme.colors.background,
        border: Border(
          left: BorderSide(
            color: fTheme.colors.border.withAlpha(80),
            width: 0.5,
          ),
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
                color: fTheme.colors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                L.of(locale, 'prompt'),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  fontSize: 18,
                  color: fTheme.colors.foreground,
                ),
              ),
              const Spacer(),
              _buildHeaderButton(
                context,
                tooltip: L.of(locale, 'hint'),
                onPressed: () {
                  final current = ref.read(promptHintVisibleProvider);
                  ref.read(promptHintVisibleProvider.notifier).state = !current;
                },
                icon: PhosphorIcon(
                  ref.watch(promptHintVisibleProvider)
                      ? PhosphorIcons.lightbulbFilament(PhosphorIconsStyle.fill)
                      : PhosphorIcons.lightbulbFilament(),
                  size: 20,
                  color: fTheme.colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Expanded(flex: 3, child: PromptEditor()),
          const SizedBox(height: 16),
          // ネガティブプロンプトヘッダー
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.prohibit(),
                size: 20,
                color: fTheme.colors.error.withAlpha(180),
              ),
              const SizedBox(width: 10),
              Text(
                L.of(locale, 'negative_prompt'),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  fontSize: 16,
                  color: fTheme.colors.foreground,
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
                  color: fTheme.colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Expanded(flex: 2, child: NegativePromptEditor()),
        ],
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
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          hoverColor: FTheme.of(context).colors.foreground.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          child: Padding(padding: const EdgeInsets.all(8.0), child: icon),
        ),
      ),
    );
  }
}
