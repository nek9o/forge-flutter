import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../../../core/services/stability_matrix_service.dart';
import '../../prompt/services/prompt_parser.dart';
import '../../prompt/store/prompt_store.dart';

class WildcardList extends ConsumerStatefulWidget {
  const WildcardList({super.key});

  @override
  ConsumerState<WildcardList> createState() => _WildcardListState();
}

class _WildcardListState extends ConsumerState<WildcardList> {
  List<String> _wildcards = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWildcards();
  }

  Future<void> _loadWildcards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(stabilityMatrixServiceProvider);
      final savedPath = await service.getSavedPath();

      if (savedPath == null || !(await service.validatePath(savedPath))) {
        _loadDefaultTags();
        return;
      }

      final wildcardDir = await service.getWildcardsDirectory(savedPath);
      if (wildcardDir == null) {
        _loadDefaultTags();
        return;
      }

      final files = await wildcardDir.list(recursive: true).toList();
      final txtFiles = files.whereType<File>().where(
        (f) => f.path.endsWith('.txt'),
      );

      final List<String> loadedTags = [];
      loadedTags.addAll(_defaultTags);

      for (var file in txtFiles) {
        final filename = file.uri.pathSegments.last;
        final name = filename.replaceAll('.txt', '');
        loadedTags.add('__${name}__');
      }

      if (mounted) {
        setState(() {
          _wildcards = loadedTags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loadDefaultTags();
        });
      }
    }
  }

  static const List<String> _defaultTags = [
    '1girl',
    'masterpiece',
    'best quality',
    'simple background',
    'white background',
  ];

  void _loadDefaultTags() {
    if (mounted) {
      setState(() {
        _wildcards = [..._defaultTags];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FTheme.of(context);
    final locale = ref.watch(localeProvider);

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: fTheme.colors.background,
        border: Border(
          left: BorderSide(color: fTheme.colors.border.withAlpha(40)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  L.of(locale, 'wildcards'),
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                    fontSize: 16,
                    color: fTheme.colors.foreground,
                  ),
                ),
                FButton.icon(
                  onPress: _loadWildcards,
                  child: FTooltip(
                    tipBuilder: (context, controller) =>
                        Text(L.of(locale, 'reload')),
                    child: PhosphorIcon(
                      PhosphorIcons.arrowClockwise(),
                      size: 16,
                      color: fTheme.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const FDivider(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: fTheme.colors.error, fontSize: 12),
              ),
            ),
          if (_isLoading)
            const Expanded(child: Center(child: FProgress()))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _wildcards.length,
                itemBuilder: (context, index) {
                  final tag = _wildcards[index];
                  final isWildcard = tag.startsWith('__');

                  return FTappable(
                    onPress: () {
                      final currentTags = ref.read(promptTagsProvider);
                      final newTag = PromptParser.parse(tag).first;

                      final newTags = [...currentTags, newTag];
                      ref.read(promptTagsProvider.notifier).setTags(newTags);

                      final text = PromptParser.format(newTags);
                      ref.read(promptProvider.notifier).state = text;
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontStyle: isWildcard ? FontStyle.italic : null,
                          color: isWildcard
                              ? fTheme.colors.primary
                              : fTheme.colors.foreground,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: FButton(
                variant: FButtonVariant.ghost,
                onPress: () async {
                  final service = ref.read(stabilityMatrixServiceProvider);
                  final path = await service.selectPath();
                  if (path != null) {
                    await _loadWildcards();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PhosphorIcon(PhosphorIcons.link(), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      L.of(locale, 'link_stability_matrix'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
