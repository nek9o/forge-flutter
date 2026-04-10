import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:native_context_menu/native_context_menu.dart' as ncm;

import '../../../../core/l10n.dart';

class PromptInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onTextChanged;
  final AppLocale locale;

  const PromptInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onTextChanged,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return ncm.ContextMenuRegion(
      onItemSelected: (item) async {
        if (item.title == L.of(locale, 'paste')) {
          final data = await Clipboard.getData('text/plain');
          if (data?.text != null) {
            final current = controller.text;
            final selection = controller.selection;
            final newText = current.replaceRange(
              selection.start == -1 ? current.length : selection.start,
              selection.end == -1 ? current.length : selection.end,
              data!.text!,
            );
            controller.text = newText;
            controller.selection = TextSelection.collapsed(
              offset:
                  (selection.start == -1 ? current.length : selection.start) +
                  data.text!.length,
            );
            onTextChanged(newText);
          }
        } else if (item.title == L.of(locale, 'clear')) {
          controller.clear();
          onTextChanged('');
        } else if (item.title == L.of(locale, 'select_all')) {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
          focusNode.requestFocus();
        }
      },
      menuItems: [
        ncm.MenuItem(title: L.of(locale, 'paste')),
        ncm.MenuItem(title: L.of(locale, 'clear')),
        ncm.MenuItem(title: L.of(locale, 'select_all')),
      ],
      child: FTextField(
        contextMenuBuilder: (context, editableTextState) =>
            const SizedBox.shrink(),
        control: FTextFieldControl.managed(
          controller: controller,
          onChange: (value) => onTextChanged(value.text),
        ),
        focusNode: focusNode,
        hint: hintText,
        maxLines: null,
      ),
    );
  }
}
