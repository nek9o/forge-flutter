import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../models/generation_settings.dart';
import '../models/lora.dart';
import '../models/sampler.dart';
import '../models/scheduler.dart';
import '../models/sd_model.dart';

final sdModelsProvider = FutureProvider<List<SDModel>>((ref) async {
  final client = ref.watch(forgeApiClientProvider);
  return client.getSDModels();
});

final samplersProvider = FutureProvider<List<Sampler>>((ref) async {
  final client = ref.watch(forgeApiClientProvider);
  return client.getSamplers();
});

final schedulersProvider = FutureProvider<List<Scheduler>>((ref) async {
  final client = ref.watch(forgeApiClientProvider);
  return client.getSchedulers();
});

final lorasProvider = FutureProvider<List<Lora>>((ref) async {
  final client = ref.watch(forgeApiClientProvider);
  return client.getLoras();
});

final selectedModelProvider = StateProvider<String?>((ref) => null);

class GenerationSettingsNotifier extends StateNotifier<GenerationSettings> {
  GenerationSettingsNotifier() : super(GenerationSettings());

  void updateSampler(String sampler) {
    state = state.copyWith(samplerName: sampler);
  }

  void updateScheduler(String? scheduler) {
    state = state.copyWith(scheduler: scheduler);
  }

  void updateWidth(int width) {
    state = state.copyWith(width: width);
  }

  void updateHeight(int height) {
    state = state.copyWith(height: height);
  }

  void updateSteps(int steps) {
    state = state.copyWith(steps: steps);
  }

  void updateCfgScale(double cfgScale) {
    state = state.copyWith(cfgScale: cfgScale);
  }

  void updateSeed(int seed) {
    state = state.copyWith(seed: seed);
  }

  void updateSaveImages(bool saveImages) {
    state = state.copyWith(saveImages: saveImages);
  }

  void updateFromMetadata(Map<String, dynamic> metadata) {
    var newState = state;
    if (metadata.containsKey('width')) {
      newState = newState.copyWith(width: metadata['width']);
    }
    if (metadata.containsKey('height')) {
      newState = newState.copyWith(height: metadata['height']);
    }
    if (metadata.containsKey('steps')) {
      newState = newState.copyWith(steps: metadata['steps']);
    }
    if (metadata.containsKey('cfg_scale')) {
      newState = newState.copyWith(cfgScale: metadata['cfg_scale']);
    }
    if (metadata.containsKey('seed')) {
      newState = newState.copyWith(seed: metadata['seed']);
    }
    if (metadata.containsKey('sampler')) {
      newState = newState.copyWith(samplerName: metadata['sampler']);
    }
    if (metadata.containsKey('scheduler')) {
      newState = newState.copyWith(scheduler: metadata['scheduler']);
    }
    if (metadata.containsKey('save_images')) {
      newState = newState.copyWith(saveImages: metadata['save_images']);
    }
    // Add other fields as needed
    state = newState;
  }
}

final generationSettingsProvider =
    StateNotifierProvider<GenerationSettingsNotifier, GenerationSettings>((
      ref,
    ) {
      return GenerationSettingsNotifier();
    });

class SettingsStore extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  SettingsStore(this.ref) : super(const AsyncValue.data(null));

  Future<void> selectModel(String modelTitle) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(forgeApiClientProvider);
      await client.setSDModel(modelTitle);
      ref.read(selectedModelProvider.notifier).state = modelTitle;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final settingsStoreProvider =
    StateNotifierProvider<SettingsStore, AsyncValue<void>>((ref) {
      return SettingsStore(ref);
    });
