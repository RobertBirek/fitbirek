import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/widgets/content_layout.dart';
import 'package:fitbirek_training/features/progress/measurements/presentation/pages/add_measurement_page.dart';

void main() {
  for (final width in [320.0, 768.0, 1280.0]) {
    testWidgets('measurement form bounded at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AddMeasurementPage())),
      );
      expect(
        tester.getSize(find.byType(TextFormField).first).width,
        lessThanOrEqualTo(640),
      );
      if (width >= 1000) {
        expect(
          tester.getSize(find.byType(TextFormField).first).width,
          640 - 48,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('pure layout does not add a scroll or impose desktop minimum', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentLayout(maxWidth: 640, child: Text('Treść')),
        ),
      ),
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(
      tester.getSize(find.byType(ContentLayout)).width,
      lessThanOrEqualTo(800),
    );
  });
}
