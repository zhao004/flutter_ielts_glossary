import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/theme/app_theme.dart';
import 'package:flutter_ielts_glossary/app/widgets/app_viewport_frame.dart';

void main() {
  testWidgets('宽屏将应用内容限制在 Figma 的 430px 视口内', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AppViewportFrame(
          child: const ColoredBox(
            key: ValueKey('viewport-child'),
            color: Colors.white,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    final child = find.byKey(const ValueKey('viewport-child'));
    expect(tester.getSize(child), const Size(AppLayout.maxContentWidth, 700));
    expect(tester.getTopLeft(child).dx, 235);
    expect(tester.takeException(), isNull);
  });
}
