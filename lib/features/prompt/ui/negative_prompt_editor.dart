import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../models/prompt_tag.dart';
import '../services/prompt_parser.dart';
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

  void _syncTextToTags() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final tags = PromptParser.parse(text);
    ref.read(negativePromptTagsProvider.notifier).setTags(tags);
    _textController.clear();
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // テキスト入力エリア
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withAlpha(100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              onChanged: _onTextChanged,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _syncTextToTags();
                }
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: L.of(locale, 'negative_prompt_hint'),
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withAlpha(120),
                  fontWeight: FontWeight.w300,
                ),
              ),
              style: GoogleFonts.geistMono(
                textStyle: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // チップ表示エリア
        Expanded(
          child: Card(
            elevation: 0,
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: tags.isEmpty
                  ? Center(
                      child: Text(
                        'チップがありません。上のフィールドにネガティブプロンプトを入力してください。',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withAlpha(120),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isHighWeight = double.parse(tag.weight.toStringAsFixed(2)) > 1.0;

    return Card(
      elevation: 0,
      color: isHighWeight
          ? colorScheme.errorContainer.withAlpha(60)
          : colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHighWeight
              ? colorScheme.error.withAlpha(30)
              : colorScheme.outlineVariant.withAlpha(30),
        ),
      ),
      child: InkWell(
        onDoubleTap: () => _showEditDialog(context, index, tag),
        borderRadius: BorderRadius.circular(12),
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
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: ReorderableDragStartListener(
              index: index,
              child: PhosphorIcon(
                PhosphorIcons.dotsSixVertical(),
                color: colorScheme.onSurfaceVariant.withAlpha(120),
                size: 18,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    tag.text,
                    style: GoogleFonts.geistMono(
                      color: isHighWeight
                          ? colorScheme.onErrorContainer
                          : colorScheme.onSurface,
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
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag.weight.toStringAsFixed(2),
                    style: GoogleFonts.geistMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: PhosphorIcon(
                PhosphorIcons.x(),
                size: 16,
                color: colorScheme.onSurfaceVariant.withAlpha(140),
              ),
              onPressed: () {
                ref.read(negativePromptTagsProvider.notifier).removeTag(index);
                _syncTagsToText();
              },
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L.of(locale, 'edit_chip')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'ネガティブプロンプト'),
              style: GoogleFonts.geistMono(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(
                labelText: 'Weight',
                helperText: '0.1 ~ 5.0',
              ),
              keyboardType: TextInputType.number,
              style: GoogleFonts.geistMono(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L.of(locale, 'cancel')),
          ),
          FilledButton(
            onPressed: () {
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
