import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../prompt/store/prompt_store.dart';
import '../../settings/store/settings_store.dart';
import '../services/png_metadata_parser.dart';

enum GenerationStatus { idle, generating, completed, error }

class PreviewState {
  final GenerationStatus status;
  final double progress;
  final String? base64Image;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final String? rawParameters;

  PreviewState({
    this.status = GenerationStatus.idle,
    this.progress = 0.0,
    this.base64Image,
    this.errorMessage,
    this.metadata,
    this.rawParameters,
  });

  PreviewState copyWith({
    GenerationStatus? status,
    double? progress,
    String? base64Image,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    String? rawParameters,
  }) {
    return PreviewState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      base64Image: base64Image ?? this.base64Image,
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

      try {
        final bytes = base64Decode(base64Image);
        final pngInfo = PngMetadataParser.parse(bytes);
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
          base64Image: base64Image,
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
