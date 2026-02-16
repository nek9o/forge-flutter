import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/l10n.dart';
import '../services/png_metadata_parser.dart';
import 'png_info_pane.dart';

class PngInfoTab extends ConsumerStatefulWidget {
  const PngInfoTab({super.key});

  @override
  ConsumerState<PngInfoTab> createState() => _PngInfoTabState();
}

class _PngInfoTabState extends ConsumerState<PngInfoTab>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _droppedFileBytes;
  Map<String, dynamic>? _metadata;
  String? _rawParameters;
  bool _dragging = false;

  @override
  bool get wantKeepAlive => true;

  void _clearState() {
    setState(() {
      _droppedFileBytes = null;
      _metadata = null;
      _rawParameters = null;
    });
  }

  Future<void> _processFile(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final pngInfo = PngMetadataParser.parse(bytes);

      Map<String, dynamic>? metadata;
      String? rawParameters;

      if (pngInfo.containsKey('parameters')) {
        rawParameters = pngInfo['parameters'];
        metadata = PngMetadataParser.parseParameters(rawParameters!);
      }

      setState(() {
        _droppedFileBytes = bytes;
        _metadata = metadata;
        _rawParameters = rawParameters;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${L.of(ref.read(localeProvider), 'file_read_error')}: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final locale = ref.watch(localeProvider);

    return DropTarget(
      onDragDone: (detail) {
        debugPrint('DropTarget: onDragDone - ${detail.files.length} files');
        if (detail.files.isNotEmpty) {
          _processFile(detail.files.first);
        }
      },
      onDragEntered: (detail) {
        debugPrint('DropTarget: onDragEntered');
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        debugPrint('DropTarget: onDragExited');
        setState(() {
          _dragging = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _dragging
            ? colorScheme.primaryContainer.withAlpha(40)
            : colorScheme.surface,
        child: _droppedFileBytes == null
            ? Center(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surfaceContainerHigh,
                          border: Border.all(
                            color: colorScheme.outlineVariant.withAlpha(60),
                            width: 2,
                          ),
                        ),
                        child: PhosphorIcon(
                          PhosphorIcons.uploadSimple(),
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withAlpha(100),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        L.of(locale, 'drop_image_here'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant.withAlpha(
                                160,
                              ),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        L.of(locale, 'drag_drop_png'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withAlpha(100),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Card(
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                              child: Image.memory(
                                _droppedFileBytes!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: PngInfoPane(
                            metadata: _metadata,
                            rawParameters: _rawParameters,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton.filled(
                      onPressed: _clearState,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      icon: PhosphorIcon(
                        PhosphorIcons.x(),
                        size: 18,
                        color: Colors.white,
                      ),
                      tooltip: L.of(locale, 'close_image'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
