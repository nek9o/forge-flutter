import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../store/settings_store.dart';

class SettingsPane extends ConsumerWidget {
  const SettingsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsyncValue = ref.watch(sdModelsProvider);
    final selectedModel = ref.watch(selectedModelProvider);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow.withAlpha(128),
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('設定', style: Theme.of(context).textTheme.titleLarge),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'モデル選択 (Checkpoint)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                modelsAsyncValue.when(
                  data: (models) {
                    return DropdownButton<String>(
                      isExpanded: true,
                      value: selectedModel,
                      hint: const Text('Select Model'),
                      items: models.map((model) {
                        return DropdownMenuItem<String>(
                          value: model.title,
                          child: Text(
                            model.modelName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(settingsStoreProvider.notifier)
                              .selectModel(value);
                        }
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error: $err'),
                ),
                const SizedBox(height: 20),
                Text('サンプラー', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                Text('画像サイズ', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                Text(
                  'LoRA / VAE',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
