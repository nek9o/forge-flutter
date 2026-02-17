import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:native_context_menu/native_context_menu.dart' as ncm;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../../../core/providers.dart';
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
  bool _apiDialogOpen = false;
  bool _apiDialogPending = false;
  DateTime? _lastApiDialogAt;

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

    // 手動再接続完了時の処理
    ref.listen(isReconnectingProvider, (prev, next) {
      if (prev == true && next == false) {
        if (_hasOngoingApiConnectionError()) {
          // すでに1.5秒待機済みなので即座にダイアログを表示
          _showApiConnectionErrorDialog(context, immediate: true);
        }
      }
    });

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
          Expanded(child: _buildMainContent(context, locale, settings)),
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

    if (ref.watch(isReconnectingProvider)) {
      return const Center(child: FProgress());
    }

    if (items.isEmpty) {
      return Text(L.of(locale, 'loading'));
    }

    final initial = items.values.contains(selectedModel)
        ? selectedModel
        : items.values.first;

    return FSelect<String>.rich(
      key: ValueKey('model_${selectedModel ?? initial}'),
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
      key: ValueKey('sd_mode_${settings.sdMode}'),
      label: Text(L.of(ref.watch(localeProvider), 'sd_mode')),
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

    if (ref.watch(isReconnectingProvider)) {
      return const Center(child: FProgress());
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final initial = items.values.contains(settings.samplerName)
        ? settings.samplerName
        : items.values.firstWhere(
            (s) => settings.samplerName.startsWith(s),
            orElse: () => items.values.isNotEmpty ? items.values.first : '',
          );

    return FSelect<String>.rich(
      key: ValueKey('sampler_${settings.samplerName}'),
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
      for (var scheduler in schedulers)
        if (scheduler.label != 'Automatic' && scheduler.name != 'Automatic')
          scheduler.label: scheduler.name,
    };

    if (ref.watch(isReconnectingProvider)) {
      return const Center(child: FProgress());
    }

    // 'Automatic'は常に存在するので、itemsは空になることはない
    final initial = items.values.contains(settings.scheduler ?? 'Automatic')
        ? (settings.scheduler ?? 'Automatic')
        : 'Automatic';

    return FSelect<String?>.rich(
      key: ValueKey('scheduler_${settings.scheduler}'),
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

  Widget _buildMainContent(
    BuildContext context,
    AppLocale locale,
    GenerationSettings settings,
  ) {
    if (ref.watch(isReconnectingProvider) || _apiDialogPending) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [FProgress(), SizedBox(height: 16)],
          ),
        ),
      );
    }

    if (_hasOngoingApiConnectionError()) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                PhosphorIcons.cloudSlash(),
                size: 48,
                color: FTheme.of(context).colors.mutedForeground,
              ),
              const SizedBox(height: 16),
              Text(
                L.of(locale, 'api_connection_error_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                L.of(locale, 'api_connection_error_body'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FTheme.of(context).colors.mutedForeground,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              FButton(
                onPress: () =>
                    ref.read(settingsStoreProvider.notifier).reconnect(),
                child: Text(L.of(locale, 'reconnect')),
              ),
            ],
          ),
        ),
      );
    }

    final modelsAsyncValue = ref.watch(sdModelsProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final samplersAsyncValue = ref.watch(samplersProvider);
    final schedulersAsyncValue = ref.watch(schedulersProvider);

    return SingleChildScrollView(
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
                ref.read(accordionExpandedProvider.notifier).state = next;
              },
            ),
            children: [
              // モデル & サンプリング
              FAccordionItem(
                title: Text(L.of(locale, 'model_sampling')),
                child: Column(
                  children: [
                    modelsAsyncValue.when(
                      data: (models) =>
                          _buildModelSelect(models, selectedModel, locale),
                      loading: () => const SizedBox.shrink(),
                      error: (err, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),
                    _buildSdModeSelect(settings),
                    const SizedBox(height: 16),
                    samplersAsyncValue.when(
                      data: (samplers) =>
                          _buildSamplerSelect(samplers, settings, locale),
                      loading: () => const SizedBox.shrink(),
                      error: (err, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),
                    schedulersAsyncValue.when(
                      data: (schedulers) =>
                          _buildSchedulerSelect(schedulers, settings, locale),
                      loading: () => const SizedBox.shrink(),
                      error: (err, _) => const SizedBox.shrink(),
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
                                      .read(generationSettingsProvider.notifier)
                                      .updateSeed(seed);
                                }
                              }
                            } else if (item.title == L.of(locale, 'clear')) {
                              _seedController.clear();
                            } else if (item.title ==
                                L.of(locale, 'select_all')) {
                              _seedController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _seedController.text.length,
                              );
                              _seedFocusNode.requestFocus();
                            }
                          },
                          menuItems: [
                            ncm.MenuItem(title: L.of(locale, 'paste')),
                            ncm.MenuItem(title: L.of(locale, 'clear')),
                            ncm.MenuItem(title: L.of(locale, 'select_all')),
                          ],
                          child: FTextField(
                            focusNode: _seedFocusNode,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9-]'),
                              ),
                            ],
                            contextMenuBuilder: (context, editableTextState) =>
                                const SizedBox.shrink(),
                            control: FTextFieldControl.managed(
                              controller: _seedController,
                              onChange: (value) {
                                final seed = int.tryParse(value.text);
                                if (seed != null) {
                                  ref
                                      .read(generationSettingsProvider.notifier)
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
                                  .read(generationSettingsProvider.notifier)
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
    );
  }

  bool _looksLikeApiConnectionFailure(String message) {
    if (ref.read(isReconnectingProvider)) return false;
    final m = message.toLowerCase();
    return m.contains('failed to connect') ||
        m.contains('socketexception') ||
        m.contains('connection refused') ||
        m.contains('errno = 111') ||
        m.contains('errno = 61') ||
        m.contains('os error');
  }

  void _showApiConnectionErrorDialog(
    BuildContext context, {
    bool immediate = false,
  }) {
    _scheduleApiConnectionErrorDialog(context, immediate: immediate);
  }

  void _scheduleApiConnectionErrorDialog(
    BuildContext context, {
    bool immediate = false,
  }) {
    if (_apiDialogOpen) return;
    if (_apiDialogPending) return;
    final now = DateTime.now();
    final last = _lastApiDialogAt;

    // throttling
    if (!immediate &&
        last != null &&
        now.difference(last).inMilliseconds < 1500) {
      return;
    }
    _lastApiDialogAt = now;

    if (immediate) {
      // 即座に表示
      _apiDialogOpen = true;
      showFDialog(
        context: context,
        builder: (context, style, animation) =>
            _ApiConnectionErrorDialog(style: style, animation: animation),
      ).then((_) {
        if (mounted) _apiDialogOpen = false;
      });
      return;
    }

    setState(() {
      _apiDialogPending = true;
    });

    () async {
      // 背景エラーの場合は1.5秒待機
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      setState(() {
        _apiDialogPending = false;
      });

      if (_apiDialogOpen) return;
      if (!_hasOngoingApiConnectionError()) return;

      _apiDialogOpen = true;
      await showFDialog(
        context: context,
        builder: (context, style, animation) =>
            _ApiConnectionErrorDialog(style: style, animation: animation),
      );
      if (!mounted) return;
      _apiDialogOpen = false;
    }();
  }

  bool _hasOngoingApiConnectionError() {
    final values = [
      ref.read(sdModelsProvider),
      ref.read(samplersProvider),
      ref.read(schedulersProvider),
      ref.read(lorasProvider),
    ];

    for (final v in values) {
      if (v.isLoading) return false;
      if (v.hasError) {
        final err = v.error;
        if (err != null && _looksLikeApiConnectionFailure(err.toString())) {
          return true;
        }
      }
    }
    return false;
  }
}

class _ApiConnectionErrorDialog extends ConsumerStatefulWidget {
  final FDialogStyle style;
  final Animation<double> animation;

  const _ApiConnectionErrorDialog({
    required this.style,
    required this.animation,
  });

  @override
  ConsumerState<_ApiConnectionErrorDialog> createState() =>
      _ApiConnectionErrorDialogState();
}

class _ApiConnectionErrorDialogState
    extends ConsumerState<_ApiConnectionErrorDialog> {
  bool _isReconnecting = false;
  AppLocale get _dialogLocale => ref.watch(localeProvider);

  Future<void> _reconnect() async {
    setState(() {
      _isReconnecting = true;
    });

    await ref.read(settingsStoreProvider.notifier).reconnect();

    if (!mounted) return;

    if (!_hasOngoingError()) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isReconnecting = false;
      });
    }
  }

  bool _hasOngoingError() {
    final values = [
      ref.read(sdModelsProvider),
      ref.read(samplersProvider),
      ref.read(schedulersProvider),
      ref.read(lorasProvider),
    ];

    for (final v in values) {
      if (v.hasError) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FDialog(
      style: widget.style,
      animation: widget.animation,
      direction: Axis.vertical,
      title: Text(L.of(_dialogLocale, 'api_connection_error_title')),
      body: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 520, maxWidth: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isReconnecting) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: FProgress(),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text(L.of(_dialogLocale, 'reconnecting'))),
            ] else ...[
              Text(L.of(_dialogLocale, 'api_connection_error_body')),
              const SizedBox(height: 12),
              Text(L.of(_dialogLocale, 'api_connection_error_body2')),
              const SizedBox(height: 16),
              FLabel(
                axis: Axis.vertical,
                label: Text(L.of(_dialogLocale, 'api_url')),
                child: FTextField(
                  control: FTextFieldControl.managed(
                    initial: TextEditingValue(text: ref.read(apiUrlProvider)),
                    onChange: (value) {
                      ref.read(apiUrlProvider.notifier).state = value.text;
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isReconnecting) ...[
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(),
            child: Text(L.of(_dialogLocale, 'close')),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: _reconnect,
            child: Text(L.of(_dialogLocale, 'reconnect')),
          ),
        ],
      ],
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
