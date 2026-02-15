import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wildcard/ui/wildcard_list.dart';
import '../store/prompt_store.dart';
import 'prompt_editor.dart';

class PromptPane extends ConsumerWidget {
  const PromptPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('プロンプト', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(flex: 3, child: PromptEditor()),
                const SizedBox(width: 16),
                const Expanded(flex: 1, child: WildcardList()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('ネガティブプロンプト', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            height: 100,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: TextField(
              maxLines: null,
              onChanged: (value) {
                ref.read(negativePromptProvider.notifier).state = value;
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'negative prompt...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
