import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../../prompt/models/prompt_tag.dart';
import '../../prompt/store/prompt_store.dart';
import '../models/lora.dart';
import '../store/settings_store.dart';

class LoraBrowser extends ConsumerStatefulWidget {
  const LoraBrowser({super.key});

  @override
  ConsumerState<LoraBrowser> createState() => _LoraBrowserState();
}

class _LoraBrowserState extends ConsumerState<LoraBrowser> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lorasAsyncValue = ref.watch(lorasProvider);
    final locale = ref.watch(localeProvider);
    final fTheme = FTheme.of(context);

    return Dialog(
      backgroundColor: fTheme.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: fTheme.colors.border),
      ),
      child: SizedBox(
        width: 600,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              Row(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.swatches(),
                    size: 22,
                    color: fTheme.colors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    L.of(locale, 'lora_browser'),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      fontSize: 18,
                      color: fTheme.colors.foreground,
                    ),
                  ),
                  const Spacer(),
                  FTooltip(
                    tipBuilder:
                        (context, controller) => Text(L.of(locale, 'refresh')),
                    child: FButton.icon(
                      variant: FButtonVariant.ghost,
                      onPress:
                          () => ref.read(settingsStoreProvider.notifier).refreshAll(),
                      child: PhosphorIcon(PhosphorIcons.arrowsClockwise()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 検索フィールド
              FTextField(
                control: FTextFieldControl.managed(
                  controller: _searchController,
                  onChange: (value) {
                    setState(() {
                      _searchQuery = value.text.toLowerCase();
                    });
                  },
                ),
                hint: L.of(locale, 'search_lora'),
              ),
              const SizedBox(height: 20),
              // コンテンツ
              Expanded(
                child: lorasAsyncValue.when(
                  data: (loras) {
                    final filteredLoras = loras.where((lora) {
                      return lora.name.toLowerCase().contains(_searchQuery) ||
                          (lora.alias?.toLowerCase().contains(_searchQuery) ??
                              false);
                    }).toList();

                    if (filteredLoras.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.magnifyingGlass(),
                              size: 40,
                              color: fTheme.colors.mutedForeground.withAlpha(
                                80,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              L.of(locale, 'no_lora'),
                              style: TextStyle(
                                color: fTheme.colors.mutedForeground,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemCount: filteredLoras.length,
                      itemBuilder: (context, index) {
                        final lora = filteredLoras[index];
                        return _buildLoraCard(context, lora);
                      },
                    );
                  },
                  loading: () => const Center(child: FProgress()),
                  error: (err, stack) =>
                      Center(child: Text('${L.of(locale, 'error')}: $err')),
                ),
              ),
              const SizedBox(height: 16),
              // アクション
              Align(
                alignment: Alignment.centerRight,
                child: FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => Navigator.of(context).pop(),
                  child: Text(L.of(locale, 'close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoraCard(BuildContext context, Lora lora) {
    final fTheme = FTheme.of(context);

    return FTappable(
      onPress: () {
        _addLoraToPrompt(lora);
        Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: fTheme.colors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fTheme.colors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              lora.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: fTheme.colors.secondaryForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (lora.alias != null)
              Text(
                '${L.of(ref.read(localeProvider), 'alias')}: ${lora.alias}',
                style: TextStyle(
                  color: fTheme.colors.mutedForeground,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  void _addLoraToPrompt(Lora lora) {
    final newTag = PromptTag(
      text: lora.alias ?? lora.name,
      weight: 1.0,
      isLora: true,
    );
    ref.read(promptTagsProvider.notifier).addTag(newTag);

    final tags = ref.read(promptTagsProvider);
    final text = tags.map((t) => t.formatted).join(', ');
    ref.read(promptProvider.notifier).state = text;
  }
}
