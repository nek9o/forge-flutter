import '../models/prompt_tag.dart';

class PromptParser {
  static List<PromptTag> parse(String prompt) {
    if (prompt.trim().isEmpty) return [];

    // Split by comma, but we should be careful about escaped commas or commas inside generic brackets.
    // For MVP Phase 3, simple comma split is acceptable as per plan.
    return prompt.split(',').map((e) => PromptTag.parse(e)).toList();
  }

  static String format(List<PromptTag> tags) {
    return tags.map((t) => t.formatted).join(', ');
  }
}
