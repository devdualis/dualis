import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/settings/presentation/screens/photo_crop_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Future<Uint8List> _testPng(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF3366CC),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  Future<void> pumpHost(WidgetTester tester, Uint8List bytes,
      void Function(Uint8List?) onResult) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  onResult(await PhotoCropScreen.open(context, bytes)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the circular crop with zoom viewer and actions',
      (tester) async {
    final bytes = await tester.runAsync(() => _testPng(300, 200));
    await pumpHost(tester, bytes!, (_) {});

    expect(find.text('Ajustar foto'), findsOneWidget);
    expect(find.byKey(const Key('photo_crop_viewer')), findsOneWidget);
    final viewerFinder = find.byKey(const Key('photo_crop_viewer'));
    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    expect(viewer.minScale, 1);
    expect(viewer.maxScale, greaterThan(1));
    final image = tester.widget<Image>(
      find.descendant(
        of: viewerFinder,
        matching: find.byType(Image),
      ),
    );
    expect(image.fit, BoxFit.contain);
    expect(find.byKey(const Key('photo_crop_confirm')), findsOneWidget);
  });

  testWidgets('cancel returns null', (tester) async {
    final bytes = await tester.runAsync(() => _testPng(64, 64));
    Uint8List? result = Uint8List(1);
    await pumpHost(tester, bytes!, (r) => result = r);
    await tester.tap(find.byKey(const Key('photo_crop_cancel')));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('pinch-zoom and drag move the image before cropping',
      (tester) async {
    final bytes = await tester.runAsync(() => _testPng(300, 200));
    await pumpHost(tester, bytes!, (_) {});
    final viewerFinder = find.byKey(const Key('photo_crop_viewer'));
    final center = tester.getCenter(viewerFinder);

    final a = await tester.startGesture(center - const Offset(20, 0));
    final b = await tester.startGesture(center + const Offset(20, 0), pointer: 2);
    await a.moveTo(center - const Offset(80, 0));
    await b.moveTo(center + const Offset(80, 0));
    await a.up();
    await b.up();
    await tester.pumpAndSettle();

    final controller = tester
        .widget<InteractiveViewer>(viewerFinder)
        .transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1.0));
  });

  testWidgets('cropBoundaryToPng saves a square PNG of the output size',
      (tester) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 200,
            height: 200,
            child: ColoredBox(color: Color(0xFF00AA88)),
          ),
        ),
      ),
    );
    final png = await tester.runAsync(() => cropBoundaryToPng(key));
    expect(png, isNotNull);
    final size = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(png!);
      final frame = await codec.getNextFrame();
      return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    });
    expect(size, const Size(PhotoCropScreen.outputSize, PhotoCropScreen.outputSize));
  });
}
