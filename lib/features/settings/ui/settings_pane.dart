import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../../preview/store/preview_store.dart';
import '../models/generation_settings.dart';
import '../store/settings_store.dart';
import 'system_monitor.dart';

class SettingsPane extends ConsumerStatefulWidget {
  final bool showMonitor;

  const SettingsPane({super.key, this.showMonitor = false});

  @override
  ConsumerState<SettingsPane> createState() => _SettingsPaneState();
}

class _SettingsPaneState extends ConsumerState<SettingsPane> {
  late TextEditingController _seedController;
  late FocusNode _seedFocusNode;

  @override
  void initState() {
    super.initState();
    final initialSeed = ref.read(generationSettingsProvider).seed;
    _seedController = TextEditingController(text: initialSeed.toString());
    _seedFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _seedController.dispose();
    _seedFocusNode.dispose();
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
    final fTheme = FTheme.of(context);

    // シード値の同期
    if (_seedController.text != settings.seed.toString() &&
        !_seedFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _seedController.text != settings.seed.toString() &&
            !_seedFocusNode.hasFocus) {
          _seedController.text = settings.seed.toString();
        }
      });
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: fTheme.colors.background,
        border: Border(right: BorderSide(color: fTheme.colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.gear(),
                  size: 20,
                  color: fTheme.colors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  L.of(locale, 'settings'),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    fontSize: 20,
                    color: fTheme.colors.foreground,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Divider(
              height: 1,
              thickness: 1,
              color: fTheme.colors.border,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FAccordion(
                    control: FAccordionControl.lifted(
                      expanded: (index) =>
                          ref.watch(accordionExpandedProvider).contains(index),
                      onChange: (index, expanded) {
                        final current = ref.read(accordionExpandedProvider);
                        final next = Set<int>.from(current);
                        if (expanded) {
                          next.add(index);
                        } else {
                          next.remove(index);
                        }
                        ref.read(accordionExpandedProvider.notifier).state =
                            next;
                      },
                    ),
                    children: [
                      // モデル & サンプリング
                      FAccordionItem(
                        title: Text(L.of(locale, 'model_sampling')),
                        child: Column(
                          children: [
                            modelsAsyncValue.when(
                              data: (models) => _buildModelSelect(
                                models,
                                selectedModel,
                                locale,
                              ),
                              loading: () => const FProgress(),
                              error: (err, _) => Text('Error: $err'),
                            ),
                            const SizedBox(height: 16),
                            _buildSdModeSelect(settings),
                            const SizedBox(height: 16),
                            samplersAsyncValue.when(
                              data: (samplers) => _buildSamplerSelect(
                                samplers,
                                settings,
                                locale,
                              ),
                              loading: () => const FProgress(),
                              error: (err, _) => Text('Error: $err'),
                            ),
                            const SizedBox(height: 16),
                            schedulersAsyncValue.when(
                              data: (schedulers) => _buildSchedulerSelect(
                                schedulers,
                                settings,
                                locale,
                              ),
                              loading: () => const FProgress(),
                              error: (err, _) => Text('Error: $err'),
                            ),
                          ],
                        ),
                      ),
                      // 生成パラメータ
                      FAccordionItem(
                        title: Text(L.of(locale, 'image_settings')),
                        child: Column(
                          children: [
                            _buildSlider(
                              context: context,
                              fTheme: fTheme,
                              label: L.of(locale, 'width'),
                              value: settings.width.toDouble(),
                              min: 64,
                              max: 2048,
                              divisions: (2048 - 64) ~/ 8,
                              onChanged: (v) => ref
                                  .read(generationSettingsProvider.notifier)
                                  .updateWidth(v.toInt()),
                            ),
                            _buildSlider(
                              context: context,
                              fTheme: fTheme,
                              label: L.of(locale, 'height'),
                              value: settings.height.toDouble(),
                              min: 64,
                              max: 2048,
                              divisions: (2048 - 64) ~/ 8,
                              onChanged: (v) => ref
                                  .read(generationSettingsProvider.notifier)
                                  .updateHeight(v.toInt()),
                            ),
                            _buildSlider(
                              context: context,
                              fTheme: fTheme,
                              label: L.of(locale, 'sampling_steps'),
                              value: settings.steps.toDouble(),
                              min: 1,
                              max: 100,
                              onChanged: (v) => ref
                                  .read(generationSettingsProvider.notifier)
                                  .updateSteps(v.toInt()),
                            ),
                            _buildSlider(
                              context: context,
                              fTheme: fTheme,
                              label: L.of(locale, 'cfg_scale'),
                              value: settings.cfgScale,
                              min: 1,
                              max: 30,
                              onChanged: (v) => ref
                                  .read(generationSettingsProvider.notifier)
                                  .updateCfgScale(v),
                            ),
                          ],
                        ),
                      ),
                      // バッチ設定
                      FAccordionItem(
                        title: Text(L.of(locale, 'batch_size')),
                        child: Column(
                          children: [
                            _buildSlider(
                              context: context,
                              fTheme: fTheme,
                              label: L.of(locale, 'batch_size'),
                              value: settings.batchSize.toDouble(),
                              min: 1,
                              max: 8,
                              onChanged: (v) => ref
                                  .read(generationSettingsProvider.notifier)
                                  .updateBatchSize(v.toInt()),
                            ),
                            _buildSlider(
                              context: context,
                              fTheme: fTheme,
                              label: L.of(locale, 'batch_count'),
                              value: settings.batchCount.toDouble(),
                              min: 1,
                              max: 100,
                              onChanged: (v) => ref
                                  .read(generationSettingsProvider.notifier)
                                  .updateBatchCount(v.toInt()),
                            ),
                          ],
                        ),
                      ),
                      // シード
                      FAccordionItem(
                        title: Text(L.of(locale, 'seed')),
                        child: FLabel(
                          axis: Axis.vertical,
                          label: Text(L.of(locale, 'seed')),
                          child: Row(
                            children: [
                              Expanded(
                                child: FTextField(
                                  focusNode: _seedFocusNode,
                                  control: FTextFieldControl.managed(
                                    controller: _seedController,
                                    onChange: (value) {
                                      final seed = int.tryParse(value.text);
                                      if (seed != null) {
                                        ref
                                            .read(
                                              generationSettingsProvider
                                                  .notifier,
                                            )
                                            .updateSeed(seed);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              FButton.icon(
                                onPress: () => ref
                                    .read(generationSettingsProvider.notifier)
                                    .updateSeed(-1),
                                child: PhosphorIcon(PhosphorIcons.diceFive()),
                              ),
                              const SizedBox(width: 6),
                              FButton.icon(
                                onPress: () {
                                  final metadata = ref
                                      .read(previewStoreProvider)
                                      .metadata;
                                  if (metadata != null &&
                                      metadata.containsKey('seed')) {
                                    final seed = metadata['seed'];
                                    if (seed is int) {
                                      ref
                                          .read(
                                            generationSettingsProvider.notifier,
                                          )
                                          .updateSeed(seed);
                                    }
                                  }
                                },
                                child: PhosphorIcon(PhosphorIcons.recycle()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // システムモニター
          if (widget.showMonitor) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Divider(
                height: 1,
                thickness: 1,
                color: fTheme.colors.border,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: SystemMonitor(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModelSelect(
    List models,
    String? selectedModel,
    AppLocale locale,
  ) {
    final Map<String, String> items = {
      for (var model in models) model.title: model.modelName,
    };

    if (items.isEmpty) {
      return Text(L.of(locale, 'loading'));
    }

    final initial = items.values.contains(selectedModel)
        ? selectedModel
        : items.values.first;

    return FSelect<String>.rich(
      label: Text(L.of(locale, 'model')),
      control: FSelectControl.managed(
        initial: initial,
        onChange: (value) {
          if (value != null) {
            ref.read(settingsStoreProvider.notifier).selectModel(value);
          }
        },
      ),
      format: (value) => items.entries
          .firstWhere(
            (e) => e.value == value,
            orElse: () => MapEntry(value, value),
          )
          .key,
      children: items.entries
          .map((e) => FSelectItem(title: Text(e.key), value: e.value))
          .toList(),
    );
  }

  Widget _buildSdModeSelect(GenerationSettings settings) {
    const Map<String, String> items = {
      'SD': 'SD',
      'SDXL': 'SDXL',
      'Flux': 'Flux',
    };
    final initial = items.values.contains(settings.sdMode)
        ? settings.sdMode
        : items.values.first;

    return FSelect<String>.rich(
      label: const Text('SD Mode'),
      control: FSelectControl.managed(
        initial: initial,
        onChange: (value) {
          if (value != null) {
            ref.read(generationSettingsProvider.notifier).updateSdMode(value);
          }
        },
      ),
      format: (value) => items.entries
          .firstWhere(
            (e) => e.value == value,
            orElse: () => MapEntry(value, value),
          )
          .key,
      children: items.entries
          .map((e) => FSelectItem(title: Text(e.key), value: e.value))
          .toList(),
    );
  }

  Widget _buildSamplerSelect(
    List samplers,
    GenerationSettings settings,
    AppLocale locale,
  ) {
    final Map<String, String> items = {
      for (var sampler in samplers) sampler.name: sampler.name,
    };

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final initial = items.values.contains(settings.samplerName)
        ? settings.samplerName
        : items.values.first;

    return FSelect<String>.rich(
      label: Text(L.of(locale, 'sampler')),
      control: FSelectControl.managed(
        initial: initial,
        onChange: (value) {
          if (value != null) {
            ref.read(generationSettingsProvider.notifier).updateSampler(value);
          }
        },
      ),
      format: (value) => items.entries
          .firstWhere(
            (e) => e.value == value,
            orElse: () => MapEntry(value, value),
          )
          .key,
      children: items.entries
          .map((e) => FSelectItem(title: Text(e.key), value: e.value))
          .toList(),
    );
  }

  Widget _buildSchedulerSelect(
    List schedulers,
    GenerationSettings settings,
    AppLocale locale,
  ) {
    final Map<String, String?> items = {
      'Automatic': 'Automatic',
      for (var scheduler in schedulers) scheduler.label: scheduler.name,
    };

    // 'Automatic'は常に存在するので、itemsは空になることはない
    final initial = items.values.contains(settings.scheduler ?? 'Automatic')
        ? (settings.scheduler ?? 'Automatic')
        : 'Automatic';

    return FSelect<String?>.rich(
      label: Text(L.of(locale, 'scheduler')),
      control: FSelectControl.managed(
        initial: initial,
        onChange: (value) {
          ref.read(generationSettingsProvider.notifier).updateScheduler(value);
        },
      ),
      format: (value) => items.entries
          .firstWhere(
            (e) => e.value == value,
            orElse: () => MapEntry(value.toString(), value),
          )
          .key,
      children: items.entries
          .map((e) => FSelectItem(title: Text(e.key), value: e.value))
          .toList(),
    );
  }

  Widget _buildSlider({
    required BuildContext context,
    required FThemeData fTheme,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    int? divisions,
  }) {
    // スライダーの値と同期するためのコントローラー
    final controller = TextEditingController(
      text: value.remainder(1) == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(1),
    );
    // カーソルが最後尾にいくように設定
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                // 高さを指定せず、必要最小限の幅だけ確保
                child: FTextField(
                  control: FTextFieldControl.managed(
                    controller: controller,
                    onChange: (v) {
                      final newVal = double.tryParse(v.text);
                      if (newVal != null) {
                        final clamped = newVal.clamp(min, max);
                        onChanged(clamped);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FSlider(
            control: FSliderControl.managedContinuous(
              initial: FSliderValue(max: (value - min) / (max - min)),
              onChange: (v) {
                onChanged(v.max * (max - min) + min);
              },
            ),
          ),
        ],
      ),
    );
  }
}
