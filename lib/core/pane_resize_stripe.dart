import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// パネル間のリサイズ用当たり域。線は描かず、隣接パネルの [Border] だけが見えるようにする。
class PaneResizeStripe extends StatelessWidget {
  const PaneResizeStripe({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: FTheme.of(context).colors.background);
  }
}
