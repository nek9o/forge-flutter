import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../prompt/models/prompt_tag.dart';
import '../../prompt/store/prompt_store.dart';
import '../models/lora.dart';
import '../store/settings_store.dart';

class LoraBrowser extends ConsumerStatefulWidget {
  const LoraBrowser({super.key});

  @override
  ConsumerState<LoraBrowser> createState() => _LoraBrowserState();
}

class _LoraBrowserState extends ConsumerState<LoraBrowser> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lorasAsyncValue = ref.watch(lorasProvider);

    return AlertDialog(
      title: const Text('LoRA ブラウザ'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'LoRAを検索...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: lorasAsyncValue.when(
                data: (loras) {
                  final filteredLoras = loras.where((lora) {
                    return lora.name.toLowerCase().contains(_searchQuery) ||
                        (lora.alias?.toLowerCase().contains(_searchQuery) ??
                            false);
                  }).toList();

                  if (filteredLoras.isEmpty) {
                    return const Center(child: Text('LoRAが見つかりません'));
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: filteredLoras.length,
                    itemBuilder: (context, index) {
                      final lora = filteredLoras[index];
                      return _buildLoraCard(context, lora);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('エラー: $err')),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  Widget _buildLoraCard(BuildContext context, Lora lora) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: () {
          _addLoraToPrompt(lora);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lora.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (lora.alias != null)
                Text(
                  'エイリアス: ${lora.alias}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addLoraToPrompt(Lora lora) {
    final newTag = PromptTag(
      text: lora.alias ?? lora.name,
      weight: 1.0,
      isLora: true,
    );
    ref.read(promptTagsProvider.notifier).addTag(newTag);

    // Sync to prompt string
    final tags = ref.read(promptTagsProvider);
    final text = tags.map((t) => t.formatted).join(', ');
    ref.read(promptProvider.notifier).state = text;
  }
}
