import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/providers.dart';
import '../store/settings_store.dart';
import 'lora_browser.dart';

class SettingsPane extends ConsumerStatefulWidget {
  const SettingsPane({super.key});

  @override
  ConsumerState<SettingsPane> createState() => _SettingsPaneState();
}

class _SettingsPaneState extends ConsumerState<SettingsPane> {
  late TextEditingController _urlController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _seedController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _seedController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsyncValue = ref.watch(sdModelsProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final samplersAsyncValue = ref.watch(samplersProvider);
    final schedulersAsyncValue = ref.watch(schedulersProvider);
    final settings = ref.watch(generationSettingsProvider);
    final apiUrl = ref.watch(apiUrlProvider);

    // Sync controllers with state if not focused (to avoid overwriting user input while typing)
    // Or just check if value is different.
    if (_urlController.text != apiUrl) {
      _urlController.text = apiUrl;
    }
    if (_widthController.text != settings.width.toString()) {
      _widthController.text = settings.width.toString();
    }
    if (_heightController.text != settings.height.toString()) {
      _heightController.text = settings.height.toString();
    }
    if (_seedController.text != settings.seed.toString()) {
      _seedController.text = settings.seed.toString();
    }

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ShadAccordion<String>.multiple(
                children:
                    [
                      (
                        title: 'API 設定',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'API URL',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _urlController,
                              decoration: InputDecoration(
                                hintText: 'http://127.0.0.1:7861',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) {
                                ref.read(apiUrlProvider.notifier).state = value;
                              },
                            ),
                          ],
                        ),
                      ),
                      (
                        title: 'モデル & サンプリング',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'モデル (Checkpoint)',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            modelsAsyncValue.when(
                              data: (models) {
                                return DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: selectedModel,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  hint: const Text('モデルを選択'),
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
                              loading: () => const LinearProgressIndicator(),
                              error: (err, stack) => Text('エラー: $err'),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'サンプラー',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            samplersAsyncValue.when(
                              data: (samplers) {
                                return DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: settings.samplerName,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: samplers.map((sampler) {
                                    return DropdownMenuItem<String>(
                                      value: sampler.name,
                                      child: Text(sampler.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      ref
                                          .read(
                                            generationSettingsProvider.notifier,
                                          )
                                          .updateSampler(value);
                                    }
                                  },
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (err, stack) => Text('エラー: $err'),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'スケジューラ',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            schedulersAsyncValue.when(
                              data: (schedulers) {
                                return DropdownButtonFormField<String?>(
                                  isExpanded: true,
                                  initialValue: settings.scheduler,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  hint: const Text('自動'),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('自動'),
                                    ),
                                    ...schedulers.map((scheduler) {
                                      return DropdownMenuItem<String?>(
                                        value: scheduler.name,
                                        child: Text(scheduler.label),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    ref
                                        .read(
                                          generationSettingsProvider.notifier,
                                        )
                                        .updateScheduler(value);
                                  },
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (err, stack) => Text('エラー: $err'),
                            ),
                          ],
                        ),
                      ),
                      (
                        title: '画像設定',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '画像サイズ',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _widthController,
                                    decoration: InputDecoration(
                                      labelText: '幅',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final width = int.tryParse(value);
                                      if (width != null) {
                                        ref
                                            .read(
                                              generationSettingsProvider
                                                  .notifier,
                                            )
                                            .updateWidth(width);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('×'),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _heightController,
                                    decoration: InputDecoration(
                                      labelText: '高さ',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final height = int.tryParse(value);
                                      if (height != null) {
                                        ref
                                            .read(
                                              generationSettingsProvider
                                                  .notifier,
                                            )
                                            .updateHeight(height);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ステップ数',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(settings.steps.toString()),
                              ],
                            ),
                            Slider(
                              value: settings.steps.toDouble(),
                              min: 1,
                              max: 100,
                              divisions: 99,
                              onChanged: (value) {
                                ref
                                    .read(generationSettingsProvider.notifier)
                                    .updateSteps(value.toInt());
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'CFGスケール',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(settings.cfgScale.toStringAsFixed(1)),
                              ],
                            ),
                            Slider(
                              value: settings.cfgScale,
                              min: 1.0,
                              max: 30.0,
                              divisions: 58,
                              onChanged: (value) {
                                ref
                                    .read(generationSettingsProvider.notifier)
                                    .updateCfgScale(value);
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'シード',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _seedController,
                              decoration: InputDecoration(
                                hintText: '-1 (ランダム)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final seed = int.tryParse(value);
                                if (seed != null) {
                                  ref
                                      .read(generationSettingsProvider.notifier)
                                      .updateSeed(seed);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      (
                        title: '拡張機能 & その他',
                        content: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('サーバーに保存'),
                              value: settings.saveImages,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) {
                                ref
                                    .read(generationSettingsProvider.notifier)
                                    .updateSaveImages(value);
                              },
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text('LoRAをブラウズ'),
                              leading: const Icon(Icons.search),
                              onTap: () => _showLoraBrowser(context),
                            ),
                          ],
                        ),
                      ),
                    ].map((item) {
                      return ShadAccordionItem(
                        value: item.title,
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: item.content,
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoraBrowser(BuildContext context) {
    showDialog(context: context, builder: (context) => const LoraBrowser());
  }
}
