class PromptTag {
  final String text;
  final double weight;
  final String id; // Unique ID for reordering

  PromptTag({required this.text, this.weight = 1.0, String? id})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  /// Creates a PromptTag from a raw string entry.
  /// Handles formats like "tag", "(tag:1.2)", "(tag)".
  factory PromptTag.parse(String raw) {
    String content = raw.trim();
    double weight = 1.0;

    // Remove surrounding parenthesis if present and extract weight
    // Basic parser for (text:1.1) format
    final regex = RegExp(r'^\((.*):([0-9.]+)\)$');
    final match = regex.firstMatch(content);

    if (match != null) {
      content = match.group(1) ?? "";
      weight = double.tryParse(match.group(2) ?? "1.0") ?? 1.0;
    } else if (content.startsWith('(') && content.endsWith(')')) {
      // Handle (tag) as 1.1 weight (standard A1111 behavior often implies emphasis)
      // For simplicity in this editor, we might just parse the inside,
      // but let's stick to explicit (text:weight) for visual editing or just keep it raw if complex.
      // For now, let's treat simple (tag) as text="tag" weight=1.1
      content = content.substring(1, content.length - 1);
      weight = 1.1;
    }

    return PromptTag(text: content, weight: weight);
  }

  String get formatted {
    if (weight == 1.0) return text;
    // Format to 2 decimal places, strip trailing zeros
    String w = weight.toStringAsFixed(2);
    if (w.endsWith('0')) w = w.substring(0, w.length - 1);
    if (w.endsWith('0')) w = w.substring(0, w.length - 2); // .0 case
    if (w.endsWith('.')) w = w.substring(0, w.length - 1);

    return '($text:$w)';
  }
}
