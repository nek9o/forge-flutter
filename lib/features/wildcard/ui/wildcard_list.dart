import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        // Fallback to defaults if no path
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
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wildcards',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _loadWildcards,
                  tooltip: 'Reload',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _wildcards.length,
                itemBuilder: (context, index) {
                  final tag = _wildcards[index];
                  final isWildcard = tag.startsWith('__');

                  return ListTile(
                    title: Text(
                      tag,
                      style: TextStyle(
                        fontStyle: isWildcard ? FontStyle.italic : null,
                        color: isWildcard
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    dense: true,
                    onTap: () {
                      final currentTags = ref.read(promptTagsProvider);
                      final newTag = PromptParser.parse(tag).first;

                      final newTags = [...currentTags, newTag];
                      ref.read(promptTagsProvider.notifier).setTags(newTags);

                      final text = PromptParser.format(newTags);
                      ref.read(promptProvider.notifier).state = text;
                    },
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: () async {
                final service = ref.read(stabilityMatrixServiceProvider);
                final path = await service.selectPath();
                if (path != null) {
                  await _loadWildcards();
                }
              },
              icon: const Icon(Icons.link, size: 16),
              label: const Text(
                'Link StabilityMatrix',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
