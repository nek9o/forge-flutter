import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

enum GenerationStatus { idle, generating, completed, error }

class PreviewState {
  final GenerationStatus status;
  final double progress;
  final String? base64Image;
  final String? errorMessage;

  PreviewState({
    this.status = GenerationStatus.idle,
    this.progress = 0.0,
    this.base64Image,
    this.errorMessage,
  });

  PreviewState copyWith({
    GenerationStatus? status,
    double? progress,
    String? base64Image,
    String? errorMessage,
  }) {
    return PreviewState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      base64Image: base64Image ?? this.base64Image,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PreviewStore extends StateNotifier<PreviewState> {
  final Ref ref;
  Timer? _progressTimer;

  PreviewStore(this.ref) : super(PreviewState());

  Future<void> generateImage(String prompt, String negativePrompt) async {
    if (state.status == GenerationStatus.generating) return;

    state = state.copyWith(
      status: GenerationStatus.generating,
      progress: 0.0,
      errorMessage: null,
    );
    _startProgressPolling();

    try {
      final client = ref.read(forgeApiClientProvider);
      final params = {
        'prompt': prompt,
        'negative_prompt': negativePrompt,
        'steps': 20,
        'width': 512,
        'height': 512,
        'cfg_scale': 7,
      };

      final base64Image = await client.txt2img(params);

      _stopProgressPolling();
      if (mounted) {
        state = state.copyWith(
          status: GenerationStatus.completed,
          progress: 1.0,
          base64Image: base64Image,
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
