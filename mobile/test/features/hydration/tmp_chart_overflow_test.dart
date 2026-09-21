import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dualis_mobile/features/hydration/presentation/widgets/water_consumption_chart.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('no overflow at narrow width', (tester) async {
    tester.view.physicalSize = const Size(391 * 2.75, 800 * 2.75);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final today = DateTime(2026, 9, 21);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: WaterConsumptionChart(last7DaysTotals: {
            for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)): i == 0 ? 250 : 0,
          }),
        ),
      ),
    ));
    await tester.pump();
    final e = tester.takeException(); if (e is FlutterError) { debugPrint(e.toStringDeep()); } expect(e, isNull);
  });
}
