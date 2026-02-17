import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:native_context_menu/native_context_menu.dart' as ncm;
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
                            _buildNumberInput(
                              context,
                              ref: ref,
                              label: L.of(locale, 'width'),
                              value: settings.width.toDouble(),
                              min: 64,
                              max: 2048,
                              onChanged: (v) => ref
                                  .read(generationSettingsProvider.notifier)
                                  .updateWidth(v.toInt()),
                            ),
                            const SizedBox(height: 16),
                            _buildNumberInput(
                              context,
                              ref: ref,
                              label: L.of(locale, 'height'),
                              value: settings.height.toDouble(),
                              min: 64,
                              max: 2048,
                              onChanged: (v) => ref
                                  .read(generationSettingsProvider.notifier)
                                  .updateHeight(v.toInt()),
                            ),
                            const SizedBox(height: 16),
                            _buildNumberInput(
                              context,
                              ref: ref,
                              label: L.of(locale, 'sampling_steps'),
                              value: settings.steps.toDouble(),
                              min: 1,
                              max: 100,
                              onChanged: (v) => ref
                                  .read(generationSettingsProvider.notifier)
                                  .updateSteps(v.toInt()),
                            ),
                            const SizedBox(height: 16),
                            _buildNumberInput(
                              context,
                              ref: ref,
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
                            _buildNumberInput(
                              context,
                              ref: ref,
                              label: L.of(locale, 'batch_size'),
                              value: settings.batchSize.toDouble(),
                              min: 1,
                              max: 8,
                              onChanged: (v) => ref
                                  .read(generationSettingsProvider.notifier)
                                  .updateBatchSize(v.toInt()),
                            ),
                            const SizedBox(height: 16),
                            _buildNumberInput(
                              context,
                              ref: ref,
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
                                child: ncm.ContextMenuRegion(
                                  onItemSelected: (item) async {
                                    if (item.title == L.of(locale, 'paste')) {
                                      final data = await Clipboard.getData(
                                        'text/plain',
                                      );
                                      if (data?.text != null) {
                                        _seedController.text = data!.text!;
                                        final seed = int.tryParse(data.text!);
                                        if (seed != null) {
                                          ref
                                              .read(
                                                generationSettingsProvider
                                                    .notifier,
                                              )
                                              .updateSeed(seed);
                                        }
                                      }
                                    } else if (item.title ==
                                        L.of(locale, 'clear')) {
                                      _seedController.clear();
                                    } else if (item.title ==
                                        L.of(locale, 'select_all')) {
                                      _seedController.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset:
                                            _seedController.text.length,
                                      );
                                      _seedFocusNode.requestFocus();
                                    }
                                  },
                                  menuItems: [
                                    ncm.MenuItem(title: L.of(locale, 'paste')),
                                    ncm.MenuItem(title: L.of(locale, 'clear')),
                                    ncm.MenuItem(
                                      title: L.of(locale, 'select_all'),
                                    ),
                                  ],
                                  child: FTextField(
                                    focusNode: _seedFocusNode,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9-]'),
                                      ),
                                    ],
                                    contextMenuBuilder:
                                        (context, editableTextState) =>
                                            const SizedBox.shrink(),
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

  Widget _buildNumberInput(
    BuildContext context, {
    required WidgetRef ref,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    String? tooltip,
  }) {
    return FLabel(
      axis: Axis.vertical,
      label: tooltip != null
          ? Row(
              children: [
                Text(label),
                const SizedBox(width: 4),
                FTooltip(
                  tipBuilder: (context, controller) => Text(tooltip),
                  child: PhosphorIcon(PhosphorIcons.info(), size: 14),
                ),
              ],
            )
          : Text(label),
      child: _SliderInput(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
        isDecimal: label.contains('CFG') || label.contains('Scale'),
      ),
    );
  }
}

class _SliderInput extends ConsumerStatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final bool isDecimal;

  const _SliderInput({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.isDecimal = false,
  });

  @override
  ConsumerState<_SliderInput> createState() => _SliderInputState();
}

class _SliderInputState extends ConsumerState<_SliderInput> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.isDecimal
          ? widget.value.toStringAsFixed(1)
          : widget.value.toInt().toString(),
    );
  }

  @override
  void didUpdateWidget(_SliderInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isFocused) {
      final newText = widget.isDecimal
          ? widget.value.toStringAsFixed(1)
          : widget.value.toInt().toString();
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return ncm.ContextMenuRegion(
      onItemSelected: (item) async {
        if (item.title == L.of(locale, 'paste')) {
          final data = await Clipboard.getData('text/plain');
          if (data?.text != null) {
            _controller.text = data!.text!;
            final newVal = double.tryParse(data.text!);
            if (newVal != null) {
              widget.onChanged(newVal.clamp(widget.min, widget.max));
            }
          }
        } else if (item.title == L.of(locale, 'clear')) {
          _controller.clear();
        } else if (item.title == L.of(locale, 'select_all')) {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
        }
      },
      menuItems: [
        ncm.MenuItem(title: L.of(locale, 'paste')),
        ncm.MenuItem(title: L.of(locale, 'clear')),
        ncm.MenuItem(title: L.of(locale, 'select_all')),
      ],
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
          if (!hasFocus) {
            // フォーカスが外れた時に値を正規化
            final val = double.tryParse(_controller.text) ?? widget.value;
            final clamped = val.clamp(widget.min, widget.max);
            widget.onChanged(clamped);
            _controller.text = widget.isDecimal
                ? clamped.toStringAsFixed(1)
                : clamped.toInt().toString();
          }
        },
        child: FTextField(
          keyboardType: widget.isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: [
            if (widget.isDecimal)
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          contextMenuBuilder: (context, editableTextState) =>
              const SizedBox.shrink(),
          control: FTextFieldControl.managed(
            controller: _controller,
            onChange: (v) {
              final newVal = double.tryParse(v.text);
              if (newVal != null) {
                widget.onChanged(newVal.clamp(widget.min, widget.max));
              }
            },
          ),
        ),
      ),
    );
  }
}
