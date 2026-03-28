import '../models/prompt_tag.dart';

class PromptParser {
  static List<PromptTag> parse(String prompt) {
    if (prompt.trim().isEmpty) return [];

    final parts = <String>[];
    int depth = 0;
    int bracketDepth = 0;
    bool escaped = false;
    StringBuffer currentPart = StringBuffer();

    for (int i = 0; i < prompt.length; i++) {
      final c = prompt[i];
      if (escaped) {
        currentPart.write(c);
        escaped = false;
      } else if (c == '\\') {
        currentPart.write(c);
        escaped = true;
      } else if (c == '(') {
        depth++;
        currentPart.write(c);
      } else if (c == ')') {
        if (depth > 0) depth--;
        currentPart.write(c);
      } else if (c == '[') {
        bracketDepth++;
        currentPart.write(c);
      } else if (c == ']') {
        if (bracketDepth > 0) bracketDepth--;
        currentPart.write(c);
      } else if (c == ',' && depth == 0 && bracketDepth == 0) {
        parts.add(currentPart.toString());
        currentPart.clear();
      } else {
        currentPart.write(c);
      }
    }

    if (currentPart.isNotEmpty) {
      parts.add(currentPart.toString());
    }

    return parts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map((p) => PromptTag.parse(p))
        .toList();
  }

  static String format(List<PromptTag> tags) {
    return tags.map((t) => t.formatted).join(', ');
  }
}
