import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../prompt/store/prompt_store.dart';
import '../../settings/store/settings_store.dart';
import '../services/png_metadata_parser.dart';

const _sentinel = Object();

enum GenerationStatus { idle, generating, completed, error }

class PreviewState {
  final GenerationStatus status;
  final double progress;
  final List<Uint8List> images;
  final int currentIndex;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final String? rawParameters;

  PreviewState({
    this.status = GenerationStatus.idle,
    this.progress = 0.0,
    this.images = const [],
    this.currentIndex = 0,
    this.errorMessage,
    this.metadata,
    this.rawParameters,
  });

  Uint8List? get imageBytes =>
      images.isNotEmpty && currentIndex < images.length
          ? images[currentIndex]
          : null;

  PreviewState copyWith({
    GenerationStatus? status,
    double? progress,
    List<Uint8List>? images,
    int? currentIndex,
    Object? errorMessage = _sentinel,
    Map<String, dynamic>? metadata,
    String? rawParameters,
  }) {
    return PreviewState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      images: images ?? this.images,
      currentIndex: currentIndex ?? this.currentIndex,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : (errorMessage as String?),
      metadata: metadata ?? this.metadata,
      rawParameters: rawParameters ?? this.rawParameters,
    );
  }
}

class PreviewStore extends StateNotifier<PreviewState> {
  final Ref ref;
  Timer? _progressTimer;

  PreviewStore(this.ref) : super(PreviewState());

  Future<void> generateImage() async {
    if (state.status == GenerationStatus.generating) return;

    final prompt = ref.read(promptProvider);
    final negativePrompt = ref.read(negativePromptProvider);
    final settings = ref.read(generationSettingsProvider);

    state = state.copyWith(
      status: GenerationStatus.generating,
      progress: 0.0,
      errorMessage: null,
    );
    _startProgressPolling();

    try {
      final client = ref.read(forgeApiClientProvider);
      final Map<String, dynamic> params = {
        'prompt': prompt,
        'negative_prompt': negativePrompt,
        ...settings.toJson(),
      };

      final response = await client.txt2img(params);
      final List<String> base64Images = List<String>.from(response['images'] ?? []);
      final String? infoString = response['info'];

      _stopProgressPolling();

      Map<String, dynamic>? metadata;
      String? rawParameters;
      final List<Uint8List> decodedImages = [];

      for (final base64Image in base64Images) {
        try {
          final imageBytes = base64Decode(base64Image);
          decodedImages.add(imageBytes);

          // APIのinfoから、または最初の画像からメタデータを取得
          if (decodedImages.length == 1) {
            if (infoString != null && infoString.isNotEmpty) {
              rawParameters = infoString;
              metadata = PngMetadataParser.parseParameters(infoString);
            } else {
              // フォールバック: 画像バイナリから取得を試みる
              final pngInfo = PngMetadataParser.parse(imageBytes);
              if (pngInfo.containsKey('parameters')) {
                rawParameters = pngInfo['parameters'];
                metadata = PngMetadataParser.parseParameters(rawParameters!);
              }
            }
          }
        } catch (e) {
          print('Error parsing image: $e');
        }
      }

      if (mounted) {
        state = state.copyWith(
          status: GenerationStatus.completed,
          progress: 1.0,
          images: decodedImages,
          currentIndex: 0,
          metadata: metadata,
          rawParameters: rawParameters,
        );
      }
    } catch (e) {
      _stopProgressPolling();
      if (mounted) {
        state = state.copyWith(
          status: GenerationStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  void _startProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      try {
        final client = ref.read(forgeApiClientProvider);
        final progressData = await client.getProgress();
        if (mounted && state.status == GenerationStatus.generating) {
          state = state.copyWith(progress: progressData['progress'] ?? 0.0);
        }
      } catch (_) {
        // Ignore progress errors
      }
    });
  }

  void _stopProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void setIndex(int index) {
    if (index >= 0 && index < state.images.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  Future<void> saveImage() async {
    if (state.imageBytes == null) return;

    try {
      final bytes = state.imageBytes!;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'generation_$timestamp.png';

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Image',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsBytes(bytes);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(errorMessage: 'Failed to save image: $e');
      }
    }
  }

  @override
  void dispose() {
    _stopProgressPolling();
    super.dispose();
  }
}

final previewStoreProvider = StateNotifierProvider<PreviewStore, PreviewState>((
  ref,
) {
  return PreviewStore(ref);
});
