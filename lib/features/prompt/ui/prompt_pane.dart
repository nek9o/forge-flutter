import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../../../core/layout_preferences.dart';
import '../store/prompt_store.dart';
import 'negative_prompt_editor.dart';
import 'prompt_editor.dart';

class PromptPane extends ConsumerStatefulWidget {
  const PromptPane({super.key});

  @override
  ConsumerState<PromptPane> createState() => _PromptPaneState();
}

class _PromptPaneState extends ConsumerState<PromptPane> {
  double _promptSplit = 0.6; // Positive:Negative = 60:40
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadLayoutPreferences();
  }

  Future<void> _loadLayoutPreferences() async {
    await LayoutPreferences.init();
    if (mounted) {
      setState(() {
        _promptSplit = LayoutPreferences.getPromptSplit();
        _initialized = true;
      });
    }
  }

  Future<void> _saveLayoutPreferences() async {
    if (!_initialized) return;

    await LayoutPreferences.setPromptSplit(_promptSplit);
  }

  @override
  Widget build(BuildContext context) {
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
          // プロンプトエリア（リサイズ可能）
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalHeight = constraints.maxHeight;
                const handleHeight = 12.0;
                const negativeHeaderHeight = 32.0;
                const spacingHeight = 12.0;

                final availableHeight =
                    totalHeight - handleHeight - negativeHeaderHeight - spacingHeight;
                final clampedAvailable =
                    availableHeight < 0 ? 0.0 : availableHeight;

                final positiveHeight = clampedAvailable * _promptSplit;

                return Column(
                  children: [
                    // Positiveプロンプトエリア
                    SizedBox(
                      height: positiveHeight,
                      child: const PromptEditor(),
                    ),
                    // リサイズハンドル
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeRow,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragUpdate: (details) {
                          if (clampedAvailable <= 0) return;
                          setState(() {
                            _promptSplit =
                                (_promptSplit +
                                        (details.delta.dy / clampedAvailable))
                                    .clamp(0.1, 0.9);
                          });
                        },
                        onVerticalDragEnd: (details) {
                          _saveLayoutPreferences();
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: handleHeight,
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 3,
                              decoration: BoxDecoration(
                                color: fTheme.colors.border.withAlpha(160),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                            ref
                                .read(negativePromptTagsProvider.notifier)
                                .setTags([]);
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
                    // Negativeプロンプトエリア
                    const Expanded(
                      child: NegativePromptEditor(),
                    ),
                  ],
                );
              },
            ),
          ),
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
