import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:native_context_menu/native_context_menu.dart' as ncm;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../models/prompt_tag.dart';
import '../store/prompt_store.dart';

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
        ncm.ContextMenuRegion(
          onItemSelected: (item) async {
            if (item.title == L.of(locale, 'paste')) {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null) {
                final current = _textController.text;
                final selection = _textController.selection;
                final newText = current.replaceRange(
                  selection.start == -1 ? current.length : selection.start,
                  selection.end == -1 ? current.length : selection.end,
                  data!.text!,
                );
                _textController.text = newText;
                _textController.selection = TextSelection.collapsed(
                  offset:
                      (selection.start == -1
                          ? current.length
                          : selection.start) +
                      data.text!.length,
                );
                _onTextChanged(newText);
              }
            } else if (item.title == L.of(locale, 'clear')) {
              _textController.clear();
              _onTextChanged('');
            } else if (item.title == L.of(locale, 'select_all')) {
              _textController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _textController.text.length,
              );
              _focusNode.requestFocus();
            }
          },
          menuItems: [
            ncm.MenuItem(title: L.of(locale, 'paste')),
            ncm.MenuItem(title: L.of(locale, 'clear')),
            ncm.MenuItem(title: L.of(locale, 'select_all')),
          ],
          child: FTextField(
            contextMenuBuilder: (context, editableTextState) =>
                const SizedBox.shrink(),
            control: FTextFieldControl.managed(
              controller: _textController,
              onChange: (value) => _onTextChanged(value.text),
            ),
            focusNode: _focusNode,
            hint: L.of(locale, 'negative_prompt_hint'),
            maxLines: null,
          ),
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
                          key: ValueKey('neg_${tag.text}_$index'),
                          margin: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 2,
                          ),
                          child: _buildPromptChip(context, index, tag),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptChip(BuildContext context, int index, PromptTag tag) {
    final fTheme = FTheme.of(context);
    final isHighWeight = double.parse(tag.weight.toStringAsFixed(2)) > 1.0;

    return FTappable(
      onPress: () => _showEditDialog(context, index, tag),
      child: Container(
        decoration: BoxDecoration(
          color: isHighWeight
              ? fTheme.colors.error.withAlpha(15)
              : fTheme.colors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighWeight
                ? fTheme.colors.error.withAlpha(30)
                : fTheme.colors.border.withAlpha(30),
          ),
        ),
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent &&
                HardwareKeyboard.instance.isShiftPressed) {
              double delta = event.scrollDelta.dy > 0 ? -0.05 : 0.05;
              double newWeight = (tag.weight + delta).clamp(0.1, 5.0);
              newWeight = double.parse(newWeight.toStringAsFixed(2));

              ref
                  .read(negativePromptTagsProvider.notifier)
                  .updateTagWeight(index, newWeight);
              _syncTagsToText();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: PhosphorIcon(
                    PhosphorIcons.dotsSixVertical(),
                    color: fTheme.colors.mutedForeground,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tag.text,
                    style: GoogleFonts.geistMono(
                      color: isHighWeight
                          ? fTheme.colors.errorForeground
                          : fTheme.colors.foreground,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: fTheme.colors.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag.weight.toStringAsFixed(2),
                    style: GoogleFonts.geistMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: fTheme.colors.mutedForeground,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                FTappable(
                  onPress: () {
                    ref
                        .read(negativePromptTagsProvider.notifier)
                        .removeTag(index);
                    _syncTagsToText();
                  },
                  child: PhosphorIcon(
                    PhosphorIcons.x(),
                    size: 16,
                    color: fTheme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, int index, PromptTag tag) {
    final locale = ref.read(localeProvider);
    final textController = TextEditingController(text: tag.text);
    final weightController = TextEditingController(
      text: tag.weight.toStringAsFixed(2),
    );

    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style,
        animation: animation,
        direction: Axis.vertical,
        title: Text(L.of(locale, 'edit_chip')),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FLabel(
              axis: Axis.vertical,
              label: Text(L.of(locale, 'negative_prompt')),
              child: FTextField(
                control: FTextFieldControl.managed(controller: textController),
              ),
            ),
            const SizedBox(height: 16),
            FLabel(
              axis: Axis.vertical,
              label: Text(L.of(locale, 'weight')),
              description: Text(L.of(locale, 'weight_range_helper')),
              child: FTextField(
                control: FTextFieldControl.managed(
                  controller: weightController,
                ),
              ),
            ),
          ],
        ),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(),
            child: Text(L.of(locale, 'cancel')),
          ),
          FButton(
            onPress: () {
              final newText = textController.text.trim();
              final newWeight =
                  double.tryParse(weightController.text) ?? tag.weight;

              if (newText.isNotEmpty) {
                final updatedTag = PromptTag(
                  text: newText,
                  weight: newWeight.clamp(0.1, 5.0),
                );
                ref
                    .read(negativePromptTagsProvider.notifier)
                    .updateTag(index, updatedTag);
                _syncTagsToText();
              }

              Navigator.of(context).pop();
            },
            child: Text(L.of(locale, 'save')),
          ),
        ],
      ),
    );
  }
}
