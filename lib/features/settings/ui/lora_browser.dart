import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
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
    final locale = ref.watch(localeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.swatches(),
            size: 22,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Text(
            L.of(locale, 'lora_browser'),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            // M3 SearchBar スタイル
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: L.of(locale, 'search_lora'),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: PhosphorIcon(
                    PhosphorIcons.magnifyingGlass(),
                    size: 20,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: lorasAsyncValue.when(
                data: (loras) {
                  final filteredLoras = loras.where((lora) {
                    return lora.name.toLowerCase().contains(_searchQuery) ||
                        (lora.alias?.toLowerCase().contains(_searchQuery) ??
                            false);
                  }).toList();

                  if (filteredLoras.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.magnifyingGlass(),
                            size: 40,
                            color: colorScheme.onSurfaceVariant.withAlpha(80),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            L.of(locale, 'no_lora'),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant.withAlpha(
                                120,
                              ),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    );
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
                error: (err, stack) =>
                    Center(child: Text('${L.of(locale, 'error')}: $err')),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(L.of(locale, 'close')),
        ),
      ],
    );
  }

  Widget _buildLoraCard(BuildContext context, Lora lora) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () {
          _addLoraToPrompt(lora);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lora.name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (lora.alias != null)
                Text(
                  '${L.of(ref.read(localeProvider), 'alias')}: ${lora.alias}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(160),
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

    final tags = ref.read(promptTagsProvider);
    final text = tags.map((t) => t.formatted).join(', ');
    ref.read(promptProvider.notifier).state = text;
  }
}
