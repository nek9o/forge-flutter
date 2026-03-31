import 'dart:convert';
import 'dart:io';
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
        final nullLoc = data.indexOf(0);
        if (nullLoc != -1) {
          try {
            final key = utf8.decode(data.sublist(0, nullLoc), allowMalformed: true);
            final value = utf8.decode(data.sublist(nullLoc + 1), allowMalformed: true);
            metadata[key] = value;
          } catch (e) {
            print('Error decoding tEXt chunk: $e');
            final key = String.fromCharCodes(data.sublist(0, nullLoc));
            final value = String.fromCharCodes(data.sublist(nullLoc + 1));
            metadata[key] = value;
          }
        }
      } else if (type == 'iTXt') {
        if (offset + 8 + length > bytes.length) break;
        final data = bytes.sublist(offset + 8, offset + 8 + length);
        var pos = data.indexOf(0);
        if (pos != -1 && pos + 2 <= data.length) {
          final keyword = utf8.decode(data.sublist(0, pos), allowMalformed: true);
          pos++; // skip null
          final compressionFlag = data[pos];
          // final compressionMethod = data[pos + 1];
          pos += 2; // skip flag and method
          
          // skip Language tag
          final langPos = data.indexOf(0, pos);
          if (langPos != -1) {
            pos = langPos + 1; // skip null
            // skip Translated keyword
            final transPos = data.indexOf(0, pos);
            if (transPos != -1) {
              pos = transPos + 1; // skip null
              if (compressionFlag == 0) {
                // Uncompressed
                final textData = data.sublist(pos);
                final text = utf8.decode(textData, allowMalformed: true);
                metadata[keyword] = text;
              } else if (compressionFlag == 1) {
                // Compressed
                try {
                  final textData = data.sublist(pos);
                  final inflated = ZLibDecoder().convert(textData);
                  final text = utf8.decode(inflated, allowMalformed: true);
                  metadata[keyword] = text;
                } catch (e) {
                  print('Error decoding compressed iTXt chunk: $e');
                }
              }
            }
          }
        }
      } else if (type == 'zTXt') {
        if (offset + 8 + length > bytes.length) break;
        final data = bytes.sublist(offset + 8, offset + 8 + length);
        final nullLoc = data.indexOf(0);
        if (nullLoc != -1 && nullLoc + 1 < data.length) {
          final keyword = utf8.decode(data.sublist(0, nullLoc), allowMalformed: true);
          // compression method is at nullLoc + 1
          try {
            final compressedData = data.sublist(nullLoc + 2);
            final inflated = ZLibDecoder().convert(compressedData);
            final text = utf8.decode(inflated, allowMalformed: true);
            metadata[keyword] = text;
          } catch (e) {
            print('Error decoding zTXt chunk: $e');
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

    // JSON 判定
    final trimmed = parameters.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        
        // JSON 各項目を標準的なキーに変換、またはそのままコピー
        result['prompt'] = json['prompt'] ?? '';
        result['negative_prompt'] = json['negative_prompt'] ?? '';
        result['steps'] = json['steps'];
        result['sampler'] = json['sampler_name'];
        result['cfg_scale'] = json['cfg_scale'];
        result['seed'] = json['seed'];
        result['width'] = json['width'];
        result['height'] = json['height'];
        result['scheduler'] = json['scheduler'];
        
        // その他すべての項目を含める
        json.forEach((key, value) {
          if (!result.containsKey(key)) {
            result[key] = value;
          }
        });
        
        return result;
      } catch (e) {
        print('Error decoding JSON info: $e');
        // JSON 解析に失敗した場合はテキスト解析へフォールバック
      }
    }

    // A1111/Forge テキスト形式のパース
    // 形式:
    // Prompt
    // Negative prompt: ...
    // Steps: ..., Sampler: ..., ...

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
      settingsLine = lines.sublist(stepsLineIndex).join('\n');
    }

    // Prompt と Negative Prompt を分割
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

    // 設定行のパース
    if (settingsLine.isNotEmpty) {
      // カンマによる分割だが、引用符内のカンマは無視する必要がある
      // シンプルな正規表現では困難なため、手動で分割するか、強化された正規表現を使用
      // ここでは、よくあるキーのリストを使って分割を改善する例
      final keys = [
        'Steps', 'Sampler', 'CFG scale', 'Seed', 'Size', 'Model hash', 'Model',
        'Batch size', 'Batch pos', 'Denoising strength', 'Clip skip', 
        'ENSD', 'Hires upscale', 'Hires upscaler', 'Hires steps', 
        'Lora hashes', 'TI hashes', 'Schedule', 'Scheduler'
      ];
      
      for (final key in keys) {
        final pattern = RegExp('$key:\\s*([^,]+)(?:,\\s*|\$)');
        final match = pattern.firstMatch(settingsLine);
        if (match != null) {
          final value = match.group(1)?.trim();
          if (value != null) {
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
              case 'Scheduler':
                result['scheduler'] = value;
                break;
              default:
                result[key.toLowerCase().replaceAll(' ', '_')] = value;
            }
          }
        }
      }
    }

    return result;
  }
}
