import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../core/l10n.dart';
import '../models/prompt_tag.dart';
import '../store/prompt_store.dart';
import 'components/prompt_edit_dialog.dart';
import 'components/prompt_input_field.dart';
import 'components/prompt_tag_chip.dart';

class NegativePromptEditor extends ConsumerStatefulWidget {
  const NegativePromptEditor({super.key});

  @override
  ConsumerState<NegativePromptEditor> createState() =>
      _NegativePromptEditorState();
}

class _NegativePromptEditorState extends ConsumerState<NegativePromptEditor> {
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
    final tags = ref.read(negativePromptTagsProvider);
    final text = tags.map((t) => t.formatted).join(', ');
    ref.read(negativePromptProvider.notifier).state = text;
  }

  void _onTextChanged(String value) {
    if (value.endsWith(',')) {
      final text = value.substring(0, value.length - 1).trim();
      if (text.isNotEmpty) {
        final newTag = PromptTag(text: text, weight: 1.0);
        ref.read(negativePromptTagsProvider.notifier).addTag(newTag);
        _syncTagsToText();
        _textController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(negativePromptTagsProvider);
    final locale = ref.watch(localeProvider);
    final fTheme = FTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // テキスト入力エリア
        PromptInputField(
          controller: _textController,
          focusNode: _focusNode,
          hintText: L.of(locale, 'negative_prompt_hint'),
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
                        L.of(locale, 'negative_prompt_no_chips'),
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
                            .read(negativePromptTagsProvider.notifier)
                            .reorderTags(oldIndex, newIndex);
                        _syncTagsToText();
                      },
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        return Container(
                          key: ValueKey('neg_${tag.id}_$index'),
                          margin: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 2,
                          ),
                          child: PromptTagChip(
                            index: index,
                            tag: tag,
                            isNegative: true,
                            onEdit: () => showPromptEditDialog(
                              context: context,
                              locale: locale,
                              tag: tag,
                              isNegative: true,
                              onSave: (updatedTag) {
                                ref
                                    .read(negativePromptTagsProvider.notifier)
                                    .updateTag(index, updatedTag);
                                _syncTagsToText();
                              },
                            ),
                            onWeightChanged: (newWeight) {
                              ref
                                  .read(negativePromptTagsProvider.notifier)
                                  .updateTagWeight(index, newWeight);
                              _syncTagsToText();
                            },
                            onRemove: () {
                              ref
                                  .read(negativePromptTagsProvider.notifier)
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
    );
  }
}

