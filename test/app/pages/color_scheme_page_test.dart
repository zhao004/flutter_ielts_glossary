import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/pages/color_scheme/color_scheme_page.dart';

void main() {
  test('配色选择页从内置配色映射的枚举键构建目录', () {
    final expected = FlexColor.schemes.keys
        .where(
          (scheme) =>
              scheme != FlexScheme.material && scheme != FlexScheme.materialHc,
        )
        .toList(growable: false);

    expect(ColorSchemePage.schemes, orderedEquals(expected));
  });
}
