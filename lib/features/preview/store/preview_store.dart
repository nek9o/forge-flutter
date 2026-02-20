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

enum GenerationStatus { idle, generating, completed, error }

class PreviewState {
  final GenerationStatus status;
  final double progress;
  final Uint8List? imageBytes;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final String? rawParameters;

  PreviewState({
    this.status = GenerationStatus.idle,
    this.progress = 0.0,
    this.imageBytes,
    this.errorMessage,
    this.metadata,
    this.rawParameters,
  });

  PreviewState copyWith({
    GenerationStatus? status,
    double? progress,
    Uint8List? imageBytes,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    String? rawParameters,
  }) {
    return PreviewState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      imageBytes: imageBytes ?? this.imageBytes,
      errorMessage: errorMessage ?? this.errorMessage,
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

      final base64Image = await client.txt2img(params);

      _stopProgressPolling();

      Map<String, dynamic>? metadata;
      String? rawParameters;
      Uint8List? imageBytes;

      try {
        imageBytes = base64Decode(base64Image);
        final pngInfo = PngMetadataParser.parse(imageBytes);
        if (pngInfo.containsKey('parameters')) {
          rawParameters = pngInfo['parameters'];
          metadata = PngMetadataParser.parseParameters(rawParameters!);
        }
      } catch (e) {
        print('Error parsing metadata: $e');
      }

      if (mounted) {
        state = state.copyWith(
          status: GenerationStatus.completed,
          progress: 1.0,
          imageBytes: imageBytes,
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
