import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reorderables/reorderables.dart';

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
    // カンマが入力されたら自動的にチップ化
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

    return Column(
      children: [
        // テキスト入力エリア
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
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
              hintText: 'ネガティブプロンプトを入力... (カンマで区切るとチップに変換)',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            style: GoogleFonts.geistMono(
              textStyle: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // チップ表示エリア
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: tags.isEmpty
                ? Center(
                    child: Text(
                      'チップがありません。上のフィールドにネガティブプロンプトを入力してください。',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: ReorderableWrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      padding: const EdgeInsets.all(8.0),
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(negativePromptTagsProvider.notifier)
                            .reorderTags(oldIndex, newIndex);
                        _syncTagsToText();
                      },
                      children: List.generate(tags.length, (index) {
                        final tag = tags[index];
                        return Container(
                          key: ValueKey('neg_${tag.text}_$index'),
                          child: _buildPromptChip(context, index, tag),
                        );
                      }),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptChip(BuildContext context, int index, PromptTag tag) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          double delta = event.scrollDelta.dy > 0 ? -0.05 : 0.05;
          double newWeight = (tag.weight + delta).clamp(0.1, 5.0);
          newWeight = double.parse(newWeight.toStringAsFixed(2));

          ref
              .read(negativePromptTagsProvider.notifier)
              .updateTagWeight(index, newWeight);
          _syncTagsToText();
        }
      },
      child: InputChip(
        label: Text('${tag.text} : ${tag.weight.toStringAsFixed(2)}'),
        onDeleted: () {
          ref.read(negativePromptTagsProvider.notifier).removeTag(index);
          _syncTagsToText();
        },
        deleteIcon: const Icon(Icons.close, size: 18),
        backgroundColor: double.parse(tag.weight.toStringAsFixed(2)) > 1.0
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          color: double.parse(tag.weight.toStringAsFixed(2)) > 1.0
              ? Theme.of(context).colorScheme.onErrorContainer
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
