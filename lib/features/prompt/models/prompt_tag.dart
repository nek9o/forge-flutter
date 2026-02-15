class PromptTag {
  final String text;
  final double weight;
  final bool isLora;
  final String id; // Unique ID for reordering

  PromptTag({
    required this.text,
    this.weight = 1.0,
    this.isLora = false,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  /// Creates a PromptTag from a raw string entry.
  /// Handles formats like "tag", "(tag:1.2)", "(tag)".
  factory PromptTag.parse(String raw) {
    String content = raw.trim();
    double weight = 1.0;

    if (content.startsWith('<lora:') && content.endsWith('>')) {
      // Handle <lora:name:weight>
      final loraContent = content.substring(6, content.length - 1);
      final parts = loraContent.split(':');
      if (parts.length >= 2) {
        content = parts[0];
        weight = double.tryParse(parts[1]) ?? 1.0;
      } else {
        content = loraContent;
        weight = 1.0;
      }
      return PromptTag(text: content, weight: weight, isLora: true);
    }

    // Remove surrounding parenthesis if present and extract weight
    // Basic parser for (text:1.1) format
    final regex = RegExp(r'^\((.*):([0-9.]+)\)$');
    final match = regex.firstMatch(content);

    if (match != null) {
      content = match.group(1) ?? "";
      weight = double.tryParse(match.group(2) ?? "1.0") ?? 1.0;
    } else if (content.startsWith('(') &&
        content.endsWith(')') &&
        !content.endsWith('\\)')) {
      // Handle (tag) as 1.1 weight (standard A1111 behavior often implies emphasis)
      // BUT only if the closing paren is NOT escaped.
      content = content.substring(1, content.length - 1);
      weight = 1.1;
    }

    return PromptTag(text: content, weight: weight);
  }

  String get formatted {
    if (isLora) {
      // Format weight to strip unnecessary precision
      String w = weight.toStringAsFixed(2);
      if (w.endsWith('0')) w = w.substring(0, w.length - 1);
      if (w.endsWith('0')) w = w.substring(0, w.length - 2);
      if (w.endsWith('.')) w = w.substring(0, w.length - 1);
      return '<lora:$text:$w>';
    }

    if (weight == 1.0) return text;
    if (weight == 1.1) return '($text)';

    // Format to 2 decimal places, strip trailing zeros
    String w = weight.toStringAsFixed(2);
    if (w.endsWith('0')) w = w.substring(0, w.length - 1);
    if (w.endsWith('0')) w = w.substring(0, w.length - 2); // .0 case
    if (w.endsWith('.')) w = w.substring(0, w.length - 1);

    return '($text:$w)';
  }
}
