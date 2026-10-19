import 'dart:ui' as ui;

import 'package:fitbirek_training/app/theme.dart';
import 'package:fitbirek_training/features/home/presentation/pages/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const labels = ['Dziś', 'Baza', 'Trening', 'Postępy', 'Ustawienia'];

double contrast(Color foreground, Color background) {
  final a = Color.alphaBlend(foreground, background).computeLuminance();
  final b = background.computeLuminance();
  return (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
}

Future<void> mount(
  WidgetTester tester,
  ThemeData theme,
  double width,
  double scale,
  int selected,
) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: StatefulBuilder(
        builder: (context, setState) => RepaintBoundary(
          key: const ValueKey('painted-shell'),
          child: MainShell(
            currentIndex: selected,
            onTabSelected: (index) => setState(() => selected = index),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// Sample the rasterized surface, not a ThemeData assumption (including elevation).
Future<Color> paintedSurface(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('painted-shell')),
  );
  final image = await boundary.toImage();
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final offset = ((image.height - 2) * image.width + 2) * 4;
  final color = Color.fromARGB(
    bytes.getUint8(offset + 3),
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
  );
  image.dispose();
  return color;
}

void checkItems(WidgetTester tester, Color surface, int selected) {
  final nav = find.byType(BottomNavigationBar);
  final colors = <Color>[];
  for (final label in labels) {
    final text = find.descendant(of: nav, matching: find.text(label));
    expect(text, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    );
    final color = paragraph.text.style!.color!;
    colors.add(color);
    expect(contrast(color, surface), greaterThanOrEqualTo(4.5), reason: label);
    // Hidden shifting labels still exist in the tree: verify their opacity too.
    for (final fade in tester.widgetList<FadeTransition>(
      find.ancestor(of: text, matching: find.byType(FadeTransition)),
    )) {
      expect(fade.opacity.value, 1, reason: '$label must be visible');
    }
    expect(tester.getRect(nav).contains(tester.getCenter(text)), isTrue);
  }
  expect(colors[selected], isNot(colors[(selected + 1) % 5]));
  final icons = find.descendant(of: nav, matching: find.byType(Icon));
  expect(icons, findsNWidgets(5));
  for (final element in icons.evaluate()) {
    final icon = element.widget as Icon;
    final inherited = IconTheme.of(element);
    final color = icon.color ?? inherited.color!;
    expect(
      contrast(
        color.withValues(alpha: color.a * (inherited.opacity ?? 1)),
        surface,
      ),
      greaterThanOrEqualTo(3),
    );
  }
  expect(tester.takeException(), isNull);
}

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? FitBirekTheme.dark : FitBirekTheme.light;
    for (final width in [320.0, 1280.0]) {
      for (final scale in [1.0, 2.0]) {
        for (var selected = 0; selected < 5; selected++) {
          testWidgets(
            'painted nav dark=$dark width=$width text=$scale selected=$selected',
            (tester) async {
              await mount(tester, theme, width, scale, selected);
              final surface = await tester.runAsync(
                () => paintedSurface(tester),
              );
              checkItems(tester, surface!, selected);
            },
          );
        }
      }
    }
    testWidgets('keyboard navigation dark=$dark at 320px text2', (
      tester,
    ) async {
      await mount(tester, theme, 320, 2, 4);
      for (var index = 0; index < 5; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, isNotNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
              .currentIndex,
          index,
        );
        final surface = await tester.runAsync(() => paintedSurface(tester));
        checkItems(tester, surface!, index);
      }
    });
  }
}
