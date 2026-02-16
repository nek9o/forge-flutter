import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../store/settings_store.dart';
import 'lora_browser.dart';
import 'system_monitor.dart';

class SettingsPane extends ConsumerStatefulWidget {
  final bool showMonitor;

  const SettingsPane({super.key, this.showMonitor = false});

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
    final locale = ref.watch(localeProvider);
    final modelsAsyncValue = ref.watch(sdModelsProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final samplersAsyncValue = ref.watch(samplersProvider);
    final schedulersAsyncValue = ref.watch(schedulersProvider);
    final settings = ref.watch(generationSettingsProvider);
    final apiUrl = ref.watch(apiUrlProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.slidersHorizontal(),
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  L.of(locale, 'settings'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: colorScheme.outlineVariant.withAlpha(40)),
          // 設定コンテンツ（スクロール可能）
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  // API 設定
                  _buildSection(
                    context,
                    icon: PhosphorIcons.plugsConnected(),
                    title: L.of(locale, 'api_settings'),
                    initiallyExpanded: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(context, L.of(locale, 'api_url')),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            hintText: 'http://127.0.0.1:7861',
                          ),
                          onChanged: (value) {
                            ref.read(apiUrlProvider.notifier).state = value;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // モデル & サンプリング
                  _buildSection(
                    context,
                    icon: PhosphorIcons.cube(),
                    title: L.of(locale, 'model_sampling'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(
                          context,
                          '${L.of(locale, 'model')} (Checkpoint)',
                        ),
                        const SizedBox(height: 8),
                        modelsAsyncValue.when(
                          data: (models) {
                            return DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: selectedModel,
                              hint: Text(L.of(locale, 'select_model')),
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
                          loading: () => LinearProgressIndicator(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          error: (err, stack) =>
                              Text('${L.of(locale, 'error')}: $err'),
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel(context, L.of(locale, 'sampler')),
                        const SizedBox(height: 8),
                        samplersAsyncValue.when(
                          data: (samplers) {
                            return DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: settings.samplerName,
                              items: samplers.map((sampler) {
                                return DropdownMenuItem<String>(
                                  value: sampler.name,
                                  child: Text(sampler.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  ref
                                      .read(generationSettingsProvider.notifier)
                                      .updateSampler(value);
                                }
                              },
                            );
                          },
                          loading: () => LinearProgressIndicator(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          error: (err, stack) =>
                              Text('${L.of(locale, 'error')}: $err'),
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel(context, L.of(locale, 'scheduler')),
                        const SizedBox(height: 8),
                        schedulersAsyncValue.when(
                          data: (schedulers) {
                            return DropdownButtonFormField<String?>(
                              isExpanded: true,
                              value: settings.scheduler,
                              hint: Text(L.of(locale, 'auto')),
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text(L.of(locale, 'auto')),
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
                                    .read(generationSettingsProvider.notifier)
                                    .updateScheduler(value);
                              },
                            );
                          },
                          loading: () => LinearProgressIndicator(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          error: (err, stack) =>
                              Text('${L.of(locale, 'error')}: $err'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 画像設定
                  _buildSection(
                    context,
                    icon: PhosphorIcons.imageSquare(),
                    title: L.of(locale, 'image_settings'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(
                          context,
                          '${L.of(locale, 'width')} × ${L.of(locale, 'height')}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _widthController,
                                decoration: InputDecoration(
                                  labelText: L.of(locale, 'width'),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final width = int.tryParse(value);
                                  if (width != null) {
                                    ref
                                        .read(
                                          generationSettingsProvider.notifier,
                                        )
                                        .updateWidth(width);
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '×',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _heightController,
                                decoration: InputDecoration(
                                  labelText: L.of(locale, 'height'),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final height = int.tryParse(value);
                                  if (height != null) {
                                    ref
                                        .read(
                                          generationSettingsProvider.notifier,
                                        )
                                        .updateHeight(height);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionLabel(
                              context,
                              L.of(locale, 'sampling_steps'),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withAlpha(
                                  60,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                settings.steps.toString(),
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionLabel(context, L.of(locale, 'cfg_scale')),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withAlpha(
                                  60,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                settings.cfgScale.toStringAsFixed(1),
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 20),
                        _sectionLabel(context, L.of(locale, 'seed')),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _seedController,
                          decoration: InputDecoration(
                            hintText: L.of(locale, 'seed_hint'),
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
                  const SizedBox(height: 4),

                  // 拡張機能 & その他
                  _buildSection(
                    context,
                    icon: PhosphorIcons.puzzlePiece(),
                    title: L.of(locale, 'extensions_others'),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(L.of(locale, 'save_to_server')),
                          value: settings.saveImages,
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onChanged: (value) {
                            ref
                                .read(generationSettingsProvider.notifier)
                                .updateSaveImages(value);
                          },
                        ),
                        const SizedBox(height: 4),
                        ListTile(
                          title: Text(L.of(locale, 'browse_lora')),
                          leading: PhosphorIcon(
                            PhosphorIcons.magnifyingGlass(),
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () => _showLoraBrowser(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // システムモニター（下部固定）
          if (widget.showMonitor) ...[
            Divider(color: colorScheme.outlineVariant.withAlpha(40)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.chartLine(),
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'システムモニター',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SystemMonitor(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required PhosphorIconData icon,
    required String title,
    required Widget child,
    bool initiallyExpanded = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ExpansionTile(
      leading: PhosphorIcon(
        icon,
        size: 18,
        color: colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
      ),
      initiallyExpanded: initiallyExpanded,
      children: [child],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _showLoraBrowser(BuildContext context) {
    showDialog(context: context, builder: (context) => const LoraBrowser());
  }
}
