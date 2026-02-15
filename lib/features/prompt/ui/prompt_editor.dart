import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderables/reorderables.dart';

import '../models/prompt_tag.dart';
import '../services/prompt_parser.dart';
import '../store/prompt_store.dart';

class PromptEditor extends ConsumerStatefulWidget {
  const PromptEditor({super.key});

  @override
  ConsumerState<PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends ConsumerState<PromptEditor> {
  late TextEditingController _textController;
  bool _isEditingText = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _syncTextToTags() {
    final text = ref.read(promptProvider);
    final tags = PromptParser.parse(text);
    ref.read(promptTagsProvider.notifier).setTags(tags);
  }

  void _syncTagsToText() {
    final tags = ref.read(promptTagsProvider);
    final text = tags.map((t) => t.formatted).join(', ');
    ref.read(promptProvider.notifier).state = text;
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(promptTagsProvider);
    // Initial sync if needed
    if (tags.isEmpty &&
        ref.read(promptProvider).isNotEmpty &&
        !_isEditingText) {
      // Only sync on init or external change?
      // For now, let's rely on manual sync or specific triggers
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncTextToTags();
      });
    }

    return Column(
      children: [
        // Mode Switcher (Icon Button)
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(_isEditingText ? Icons.style : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditingText = !_isEditingText;
                if (_isEditingText) {
                  _syncTagsToText();
                  _textController.text = ref.read(promptProvider);
                } else {
                  _syncTextToTags();
                }
              });
            },
            tooltip: _isEditingText ? 'Switch to Chips' : 'Switch to Text',
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: _isEditingText
                ? TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    onChanged: (value) {
                      ref.read(promptProvider.notifier).state = value;
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter prompt here...',
                    ),
                  )
                : SingleChildScrollView(
                    child: ReorderableWrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      padding: const EdgeInsets.all(8.0),
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(promptTagsProvider.notifier)
                            .reorderTags(oldIndex, newIndex);
                        _syncTagsToText();
                      },
                      children: List.generate(tags.length, (index) {
                        final tag = tags[index];
                        return _buildPromptChip(context, index, tag);
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
          // Shift key for finer control?
          // For now, standard 0.05 step
          double newWeight = (tag.weight + delta).clamp(0.1, 5.0);
          // Round to 2 decimal places to avoid floating point errors
          newWeight = double.parse(newWeight.toStringAsFixed(2));

          ref
              .read(promptTagsProvider.notifier)
              .updateTagWeight(index, newWeight);
          _syncTagsToText();
        }
      },
      child: Chip(
        label: Text('${tag.text} : ${tag.weight.toStringAsFixed(2)}'),
        onDeleted: () {
          ref.read(promptTagsProvider.notifier).removeTag(index);
          _syncTagsToText();
        },
        deleteIcon: const Icon(Icons.close, size: 18),
        backgroundColor: double.parse(tag.weight.toStringAsFixed(2)) > 1.0
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
      ),
    );
  }
}
