import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prompt_tag.dart';

final promptProvider = StateProvider<String>((ref) => "");
final negativePromptProvider = StateProvider<String>((ref) => "");

// Notifier for handling tag operations
class PromptTagsNotifier extends StateNotifier<List<PromptTag>> {
  PromptTagsNotifier() : super([]);

  void setTags(List<PromptTag> tags) {
    state = tags;
  }

  void addTag(PromptTag tag) {
    final newState = List<PromptTag>.from(state);
    newState.add(tag);
    state = newState;
  }

  void updateTagWeight(int index, double newWeight) {
    if (index >= 0 && index < state.length) {
      final oldTag = state[index];
      final newTag = PromptTag(
        text: oldTag.text,
        weight: newWeight,
        isLora: oldTag.isLora,
        id: oldTag.id,
      );
      final newState = List<PromptTag>.from(state);
      newState[index] = newTag;
      state = newState;
    }
  }

  void updateTag(int index, PromptTag newTag) {
    if (index >= 0 && index < state.length) {
      final newState = List<PromptTag>.from(state);
      newState[index] = newTag;
      state = newState;
    }
  }

  void reorderTags(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final newState = List<PromptTag>.from(state);
    final item = newState.removeAt(oldIndex);
    newState.insert(newIndex, item);
    state = newState;
  }

  void removeTag(int index) {
    final newState = List<PromptTag>.from(state);
    newState.removeAt(index);
    state = newState;
  }
}

final promptTagsProvider =
    StateNotifierProvider<PromptTagsNotifier, List<PromptTag>>((ref) {
      return PromptTagsNotifier();
    });

final negativePromptTagsProvider =
    StateNotifierProvider<PromptTagsNotifier, List<PromptTag>>((ref) {
      return PromptTagsNotifier();
    });
