import 'dart:convert';
import 'dart:typed_data';

class PngMetadataParser {
  /// Parses PNG data and returns a map of metadata.
  /// Keys are usually 'parameters' for A1111/Forge images.
  static Map<String, String> parse(Uint8List bytes) {
    print('Parsing PNG metadata...');
    final metadata = <String, String>{};

    // PNG signature: 89 50 4E 47 0D 0A 1A 0A
    if (bytes.length < 8 ||
        bytes[0] != 0x89 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x4E ||
        bytes[3] != 0x47 ||
        bytes[4] != 0x0D ||
        bytes[5] != 0x0A ||
        bytes[6] != 0x1A ||
        bytes[7] != 0x0A) {
      print('Invalid PNG signature');
      return metadata;
    }

    var offset = 8; // Skip PNG signature

    while (offset < bytes.length) {
      if (offset + 8 > bytes.length) break;

      final length = _readInt32(bytes, offset);
      final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));

      // print('Chunk found: $type, length: $length');

      if (type == 'tEXt') {
        if (offset + 8 + length > bytes.length) break;
        final data = bytes.sublist(offset + 8, offset + 8 + length);
        final nullSeparatorIndex = data.indexOf(0);
        if (nullSeparatorIndex != -1) {
          // Latin-1 is standard for tEXt chunks, but UTF-8 is often used in practice
          // We'll try UTF-8 first, fallback to Latin-1 if needed, but for simplicity
          // in Dart string decoding, we usually assume compatible encoding.
          try {
            final key = utf8.decode(data.sublist(0, nullSeparatorIndex));
            final value = utf8.decode(data.sublist(nullSeparatorIndex + 1));
            metadata[key] = value;
          } catch (e) {
            print('Error decoding tEXt chunk: $e');
            // Fallback or ignore
            final key = String.fromCharCodes(
              data.sublist(0, nullSeparatorIndex),
            );
            final value = String.fromCharCodes(
              data.sublist(nullSeparatorIndex + 1),
            );
            metadata[key] = value;
          }
        }
      }

      // Move to next chunk: Length (4) + Type (4) + Data (length) + CRC (4)
      offset += 4 + 4 + length + 4;
    }

    return metadata;
  }

  static int _readInt32(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  /// Parses the 'parameters' string from A1111/Forge.
  static Map<String, dynamic> parseParameters(String parameters) {
    final result = <String, dynamic>{};

    // The format roughly is:
    // Prompt
    // Negative prompt: ...
    // Steps: ..., Sampler: ..., ...

    // We strive to find the last line that starts with "Steps: ".
    // Everything before that is Prompt + Negative Prompt.

    final lines = parameters.split('\n');
    int? stepsLineIndex;

    for (var i = lines.length - 1; i >= 0; i--) {
      if (lines[i].trim().startsWith('Steps: ')) {
        stepsLineIndex = i;
        break;
      }
    }

    String promptAndNegative = parameters;
    String settingsLine = '';

    if (stepsLineIndex != null) {
      promptAndNegative = lines.sublist(0, stepsLineIndex).join('\n');
      settingsLine = lines
          .sublist(stepsLineIndex)
          .join(
            '\n',
          ); // Should handle multi-line settings if any? usually single line.
      // Actually strictly speaking, the settings are on the last line(s).
    }

    // Split Prompt and Negative Prompt
    final negativePromptPrefix = 'Negative prompt: ';
    final negativeIndex = promptAndNegative.indexOf(negativePromptPrefix);

    if (negativeIndex != -1) {
      result['prompt'] = promptAndNegative.substring(0, negativeIndex).trim();
      result['negative_prompt'] = promptAndNegative
          .substring(negativeIndex + negativePromptPrefix.length)
          .trim();
    } else {
      result['prompt'] = promptAndNegative.trim();
      result['negative_prompt'] = '';
    }

    // Parse settings line
    if (settingsLine.isNotEmpty) {
      // Create a map from the comma-separated settings
      // Note: Values can contain commas, so simple split by ", " might be risky but is standard for this format.
      // Helper to parse key: value
      final regex = RegExp(r'([\w\s]+):\s*([^,]+)(?:,\s*|$)');
      final matches = regex.allMatches(settingsLine);

      for (final match in matches) {
        final key = match.group(1)?.trim();
        final value = match.group(2)?.trim();

        if (key != null && value != null) {
          switch (key) {
            case 'Steps':
              result['steps'] = int.tryParse(value);
              break;
            case 'Sampler':
              result['sampler'] = value;
              break;
            case 'CFG scale':
              result['cfg_scale'] = double.tryParse(value);
              break;
            case 'Seed':
              result['seed'] = int.tryParse(value);
              break;
            case 'Size':
              final sizeParts = value.split('x');
              if (sizeParts.length == 2) {
                result['width'] = int.tryParse(sizeParts[0]);
                result['height'] = int.tryParse(sizeParts[1]);
              }
              break;
            case 'Model':
              result['model'] = value;
              break;
            case 'Model hash':
              result['model_hash'] = value;
              break;
            case 'Schedule':
              result['scheduler'] = value;
              break;
            // Add other keys as needed
          }
        }
      }
    }

    return result;
  }
}
