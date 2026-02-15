import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../models/sd_model.dart';

final sdModelsProvider = FutureProvider<List<SDModel>>((ref) async {
  final client = ref.watch(forgeApiClientProvider);
  return client.getSDModels();
});

final selectedModelProvider = StateProvider<String?>((ref) => null);

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
