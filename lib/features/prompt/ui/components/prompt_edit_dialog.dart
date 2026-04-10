import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../../core/l10n.dart';
import '../../models/prompt_tag.dart';

Future<void> showPromptEditDialog({
  required BuildContext context,
  required AppLocale locale,
  required PromptTag tag,
  required ValueChanged<PromptTag> onSave,
  bool isNegative = false,
}) {
  final textController = TextEditingController(text: tag.text);
  final weightController =
      TextEditingController(text: tag.weight.toStringAsFixed(2));

  return showFDialog(
    context: context,
    builder: (context, style, animation) => FDialog(
      style: style,
      animation: animation,
      direction: Axis.vertical,
      title: Text(L.of(locale, 'edit_chip')),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FLabel(
            axis: Axis.vertical,
            label:
                Text(L.of(locale, isNegative ? 'negative_prompt' : 'prompt')),
            child: FTextField(
              control: FTextFieldControl.managed(controller: textController),
            ),
          ),
          const SizedBox(height: 16),
          FLabel(
            axis: Axis.vertical,
            label: Text(L.of(locale, 'weight')),
            description: Text(L.of(locale, 'weight_range_helper')),
            child: FTextField(
              control: FTextFieldControl.managed(controller: weightController),
            ),
          ),
        ],
      ),
      actions: [
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(context).pop(),
          child: Text(L.of(locale, 'cancel')),
        ),
        FButton(
          onPress: () {
            final newText = textController.text.trim();
            final newWeight =
                double.tryParse(weightController.text) ?? tag.weight;

            if (newText.isNotEmpty) {
              final updatedTag = PromptTag(
                text: newText,
                weight: newWeight.clamp(0.1, 5.0),
                isLora: tag.isLora,
                id: tag.id,
              );
              onSave(updatedTag);
            }

            Navigator.of(context).pop();
          },
          child: Text(L.of(locale, 'save')),
        ),
      ],
    ),
  );
}
