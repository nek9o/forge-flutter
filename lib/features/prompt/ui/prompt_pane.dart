import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_context_menu/native_context_menu.dart' as ncm;

import 'negative_prompt_editor.dart';
import 'prompt_editor.dart';

class PromptPane extends ConsumerWidget {
  const PromptPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ncm.ContextMenuRegion(
      onItemSelected: (item) {
        if (item.title == 'クリア') {
          // TODO: Implement clear logic if needed
        }
      },
      menuItems: [
        ncm.MenuItem(title: 'クリア'),
        ncm.MenuItem(title: '全選択'),
      ],
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('プロンプト', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Expanded(flex: 3, child: PromptEditor()),
            const SizedBox(height: 16),
            Text('ネガティブプロンプト', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Expanded(flex: 2, child: NegativePromptEditor()),
          ],
        ),
      ),
    );
  }
}
