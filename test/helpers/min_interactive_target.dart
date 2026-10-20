import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mierzy samą powierzchnię i hitbox, nie padding zewnętrznego rodzica.
void expectMinInteractiveTarget(WidgetTester tester, Finder control) {
  final ink = find.descendant(
    of: control,
    matching: find.byWidgetPredicate((w) => w is InkResponse),
  );
  final surface = find.descendant(of: control, matching: find.byType(Material));
  expect(ink, findsOneWidget);
  expect(surface, findsOneWidget);
  for (final finder in [control, surface, ink]) {
    expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
  }
  expect(tester.getSemantics(control).rect.height, greaterThanOrEqualTo(48));
  final box = tester.renderObject<RenderBox>(ink);
  final rect = tester.getRect(ink);
  for (final dy in [1.0, 47.0]) {
    final hits = tester.hitTestOnBinding(Offset(rect.center.dx, rect.top + dy));
    expect(hits.path.any((entry) => identical(entry.target, box)), isTrue);
  }
  debugPrint(
    'target ${tester.widget(control).runtimeType}: surface=${tester.getSize(surface)}, hitbox=${rect.size}',
  );
}
