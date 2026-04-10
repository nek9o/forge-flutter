import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../../settings/ui/lora_browser.dart';
import '../models/prompt_tag.dart';
import '../store/prompt_store.dart';
import 'components/prompt_edit_dialog.dart';
import 'components/prompt_input_field.dart';
import 'components/prompt_tag_chip.dart';
import 'hint_card.dart';

class PromptEditor extends ConsumerStatefulWidget {
  const PromptEditor({super.key});

  @override
  ConsumerState<PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends ConsumerState<PromptEditor> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncTagsToText() {
    final tags = ref.read(promptTagsProvider);
    final text = tags.map((t) => t.formatted).join(', ');
    ref.read(promptProvider.notifier).state = text;
  }

  void _onTextChanged(String value) {
    if (value.endsWith(',')) {
      final text = value.substring(0, value.length - 1).trim();
      if (text.isNotEmpty) {
        final newTag = PromptTag(text: text, weight: 1.0);
        ref.read(promptTagsProvider.notifier).addTag(newTag);
        _syncTagsToText();
        _textController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(promptTagsProvider);
    final locale = ref.watch(localeProvider);
    final fTheme = FTheme.of(context);
    final showHint = ref.watch(promptHintVisibleProvider);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ヘッダー（ボタン群）
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  FButton(
                    onPress: () => showDialog(
                       context: context,
                       builder: (context) => const LoraBrowser(),
                     ),
                    variant: FButtonVariant.ghost,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(PhosphorIcons.swatches(), size: 18),
                        const SizedBox(width: 8),
                        Text(L.of(locale, 'lora_browser')),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildActionButton(
                    context,
                    tooltip: L.of(locale, 'clear_prompt'),
                    onPressed: () {
                      ref.read(promptTagsProvider.notifier).setTags([]);
                      ref.read(promptProvider.notifier).state = '';
                    },
                    icon: PhosphorIcon(
                      PhosphorIcons.trash(),
                      size: 20,
                      color: fTheme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            // テキスト入力エリア
            PromptInputField(
              controller: _textController,
              focusNode: _focusNode,
              hintText: L.of(locale, 'prompt_hint'),
              locale: locale,
              onTextChanged: _onTextChanged,
            ),
            const SizedBox(height: 12),
            // チップ表示エリア
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: fTheme.colors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fTheme.colors.border.withAlpha(50)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: tags.isEmpty
                      ? Center(
                          child: Text(
                            L.of(locale, 'prompt_no_chips'),
                            style: TextStyle(
                              color: fTheme.colors.mutedForeground,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        )
                      : ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: tags.length,
                          onReorder: (oldIndex, newIndex) {
                            ref
                                .read(promptTagsProvider.notifier)
                                .reorderTags(oldIndex, newIndex);
                            _syncTagsToText();
                          },
                          itemBuilder: (context, index) {
                            final tag = tags[index];
                            return Container(
                              key: ValueKey('${tag.id}_$index'),
                              margin: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 2,
                              ),
                              child: PromptTagChip(
                                index: index,
                                tag: tag,
                                onEdit: () => showPromptEditDialog(
                                  context: context,
                                  locale: locale,
                                  tag: tag,
                                  onSave: (updatedTag) {
                                    ref
                                        .read(promptTagsProvider.notifier)
                                        .updateTag(index, updatedTag);
                                    _syncTagsToText();
                                  },
                                ),
                                onWeightChanged: (newWeight) {
                                  ref
                                      .read(promptTagsProvider.notifier)
                                      .updateTagWeight(index, newWeight);
                                  _syncTagsToText();
                                },
                                onRemove: () {
                                  ref
                                      .read(promptTagsProvider.notifier)
                                      .removeTag(index);
                                  _syncTagsToText();
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
        // ヒントオーバーレイ
        if (showHint)
          Positioned(top: 48, right: 0, width: 300, child: const HintCard()),
      ],
    );
  }

  Widget _buildActionButton(
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
          hoverColor: FTheme.of(
            context,
          ).colors.foreground.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          child: Padding(padding: const EdgeInsets.all(8.0), child: icon),
        ),
      ),
    );
  }
}
