import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../store/settings_store.dart';

class DetailedSettingsDialog extends ConsumerWidget {
  final FDialogStyle style;
  final Animation<double> animation;

  const DetailedSettingsDialog({
    super.key,
    required this.style,
    required this.animation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(generationSettingsProvider);
    final locale = ref.watch(localeProvider);
    return FDialog(
      style: style,
      animation: animation,
      direction: Axis.vertical,
      title: Text(L.of(locale, 'detailed_settings')),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FLabel(
            axis: Axis.vertical,
            label: Text(L.of(locale, 'api_url')),
            child: FTextField(
              control: FTextFieldControl.managed(
                initial: TextEditingValue(text: ref.read(apiUrlProvider)),
                onChange: (value) {
                  ref.read(apiUrlProvider.notifier).state = value.text;
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          FLabel(
            axis: Axis.horizontal,
            label: Text(L.of(locale, 'save_to_server')),
            child: FCheckbox(
              value: settings.saveImages,
              onChange: (value) {
                ref
                    .read(generationSettingsProvider.notifier)
                    .updateSaveImages(value);
              },
            ),
          ),
          const SizedBox(height: 16),
          FLabel(
            axis: Axis.horizontal,
            label: Text(L.of(locale, 'ui_debug_mode')),
            child: FCheckbox(
              value: settings.uiDebugMode,
              onChange: (value) {
                ref
                    .read(generationSettingsProvider.notifier)
                    .updateUiDebugMode(value);
              },
            ),
          ),
        ],
      ),
      actions: [
        FButton(
          onPress: () => Navigator.of(context).pop(),
          child: Text(L.of(locale, 'close')),
        ),
      ],
    );
  }
}
