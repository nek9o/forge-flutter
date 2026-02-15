import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error reading file: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
      child: Container(
        // Ensure the entire area is hit-testable even when "transparent"
        color: _dragging
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha(80)
            : Colors.black.withAlpha(1),
        child: _droppedFileBytes == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_upload_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ここに画像をドロップ\n(ファイルをドラッグして離してください)',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(50),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _droppedFileBytes!,
                                  fit: BoxFit.contain,
                                ),
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
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withAlpha(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _clearState,
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.white,
                        tooltip: '画像を閉じる',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
