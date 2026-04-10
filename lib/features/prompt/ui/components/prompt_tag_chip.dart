import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/prompt_tag.dart';

class PromptTagChip extends StatelessWidget {
  final int index;
  final PromptTag tag;
  final VoidCallback onEdit;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onRemove;
  final bool isNegative;

  const PromptTagChip({
    super.key,
    required this.index,
    required this.tag,
    required this.onEdit,
    required this.onWeightChanged,
    required this.onRemove,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final fTheme = FTheme.of(context);
    final isHighWeight = double.parse(tag.weight.toStringAsFixed(2)) > 1.0;

    Color primaryColor = tag.isLora
        ? fTheme.colors.primary
        : (isHighWeight ? fTheme.colors.primary : fTheme.colors.foreground);
    Color backgroundColor = tag.isLora
        ? fTheme.colors.primary.withAlpha(20)
        : (isHighWeight
            ? fTheme.colors.primary.withAlpha(25)
            : fTheme.colors.secondary);
    Color borderColor = tag.isLora
        ? fTheme.colors.primary.withAlpha(40)
        : (isHighWeight
            ? fTheme.colors.primary.withAlpha(50)
            : fTheme.colors.border.withAlpha(30));

    if (isNegative) {
      primaryColor =
          isHighWeight ? fTheme.colors.error : fTheme.colors.foreground;
      backgroundColor = isHighWeight
          ? fTheme.colors.error.withAlpha(25)
          : fTheme.colors.secondary;
      borderColor = isHighWeight
          ? fTheme.colors.error.withAlpha(50)
          : fTheme.colors.border.withAlpha(30);
    }

    return FTappable(
      onPress: onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent &&
                HardwareKeyboard.instance.isShiftPressed) {
              double delta = event.scrollDelta.dy > 0 ? -0.05 : 0.05;
              double newWeight = (tag.weight + delta).clamp(0.1, 5.0);
              newWeight = double.parse(newWeight.toStringAsFixed(2));
              onWeightChanged(newWeight);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: PhosphorIcon(
                    PhosphorIcons.dotsSixVertical(),
                    color: fTheme.colors.mutedForeground,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isNegative && tag.isLora)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PhosphorIcon(
                      PhosphorIcons.swatches(),
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                Expanded(
                  child: Text(
                    !isNegative && tag.isLora ? 'LoRA: ${tag.text}' : tag.text,
                    style: GoogleFonts.geistMono(
                      color: primaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: fTheme.colors.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag.weight.toStringAsFixed(2),
                    style: GoogleFonts.geistMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: fTheme.colors.mutedForeground,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                FTappable(
                  onPress: onRemove,
                  child: PhosphorIcon(
                    PhosphorIcons.x(),
                    size: 16,
                    color: fTheme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
