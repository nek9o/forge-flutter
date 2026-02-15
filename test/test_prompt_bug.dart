import 'package:flutter_forge/features/prompt/models/prompt_tag.dart';

void main() {
  // Case 1: Simple tag
  final t1 = PromptTag.parse('1girl');
  print('T1: ${t1.text}, ${t1.weight} -> ${t1.formatted}');
  assert(t1.text == '1girl');
  assert(t1.weight == 1.0);

  // Case 2: Standard weight
  final t2 = PromptTag.parse('(1girl:1.2)');
  print('T2: ${t2.text}, ${t2.weight} -> ${t2.formatted}');
  assert(t2.text == '1girl');
  assert(t2.weight == 1.2);

  // Case 3: Implicit weight (buggy one?)
  final t3 = PromptTag.parse('(1girl)');
  print('T3: ${t3.text}, ${t3.weight} -> ${t3.formatted}');
  assert(t3.text == '1girl');
  assert(t3.weight == 1.1);

  // Case 4: Escaped paren (The bug)
  final t4 = PromptTag.parse('(akashi \\(azur lane\\))');
  print('T4: ${t4.text}, ${t4.weight} -> ${t4.formatted}');
  // User says: (akashi \(azur lane\) -> (akashi \(azur lane\:1.1)
  // If input is (akashi \(azur lane\), it should probably stay as is if the outer parens are NOT matched.
  // Actually if the input comes from A1111 metadata, it might be:
  // "prompt, (akashi \(azur lane\):1.1), ..."
  // Wait, if it's (akashi \(azur lane\)), my parser sees starts with ( and ends with ).
  // It strips THEM. Text becomes "akashi \(azur lane\)". weight 1.1.
  // Then formatted becomes "(akashi \(azur lane\):1.1)".

  final t5 = PromptTag.parse('(akashi \\(azur lane\\))');
  print('T5: ${t5.text}, ${t5.weight} -> ${t5.formatted}');

  print('Done.');
}
