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

  testWidgets('shows the circular crop with zoom viewer and actions (BoxFit.cover)',
      (tester) async {
    final bytes = await tester.runAsync(() => _testPng(300, 200));
    await pumpHost(tester, bytes!, (_) {});

    expect(find.text('Ajustar foto'), findsOneWidget);
    expect(find.byKey(const Key('photo_crop_viewer')), findsOneWidget);
    final viewerFinder = find.byKey(const Key('photo_crop_viewer'));
    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    expect(viewer.minScale, 1.0);
    expect(viewer.maxScale, greaterThan(1.0));
    final image = tester.widget<Image>(
      find.descendant(
        of: viewerFinder,
        matching: find.byType(Image),
      ),
    );
    expect(image.fit, BoxFit.cover);
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

  testWidgets('initial offset sits near the top third (~35%) for a portrait image',
      (tester) async {
    // 300 wide by 600 tall (aspect ratio 0.5)
    final bytes = await tester.runAsync(() => _testPng(300, 600));
    await pumpHost(tester, bytes!, (_) {});

    final viewerFinder = find.byKey(const Key('photo_crop_viewer'));
    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    final matrix = viewer.transformationController!.value;
    final translation = matrix.getTranslation();

    final imageFinder = find.descendant(of: viewerFinder, matching: find.byType(Image));
    final imageBox = tester.renderObject(imageFinder) as RenderBox;
    final viewerBox = tester.renderObject(viewerFinder) as RenderBox;

    // Horizontally centered
    expect(translation.x, 0.0);

    // Circle centre (viewerBox.size.height / 2) relative to image height sits at ~35%
    final circleCenterInImage = (viewerBox.size.height / 2.0) - translation.y;
    final ratio = circleCenterInImage / imageBox.size.height;
    expect(ratio, closeTo(0.35, 0.05));
  });

  testWidgets('minimum scale covers the circle for a portrait image',
      (tester) async {
    final bytes = await tester.runAsync(() => _testPng(300, 600));
    await pumpHost(tester, bytes!, (_) {});

    final viewerFinder = find.byKey(const Key('photo_crop_viewer'));
    final imageFinder = find.descendant(of: viewerFinder, matching: find.byType(Image));
    final imageBox = tester.renderObject(imageFinder) as RenderBox;
    final viewerBox = tester.renderObject(viewerFinder) as RenderBox;

    // Both dimensions of the image must cover the viewport
    expect(imageBox.size.width, greaterThanOrEqualTo(viewerBox.size.width));
    expect(imageBox.size.height, greaterThanOrEqualTo(viewerBox.size.height));
  });

  testWidgets('minimum scale covers the circle for a landscape image',
      (tester) async {
    final bytes = await tester.runAsync(() => _testPng(600, 300));
    await pumpHost(tester, bytes!, (_) {});

    final viewerFinder = find.byKey(const Key('photo_crop_viewer'));
    final imageFinder = find.descendant(of: viewerFinder, matching: find.byType(Image));
    final imageBox = tester.renderObject(imageFinder) as RenderBox;
    final viewerBox = tester.renderObject(viewerFinder) as RenderBox;

    // Both dimensions must cover the viewport
    expect(imageBox.size.width, greaterThanOrEqualTo(viewerBox.size.width));
    expect(imageBox.size.height, greaterThanOrEqualTo(viewerBox.size.height));

    // Landscape is centered horizontally
    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    final translation = viewer.transformationController!.value.getTranslation();
    expect(translation.x, lessThan(0.0));
  });

  testWidgets('panning clamps so empty area never enters the circle',
      (tester) async {
    // 300x600 portrait photo
    final bytes = await tester.runAsync(() => _testPng(300, 600));
    await pumpHost(tester, bytes!, (_) {});

    final viewerFinder = find.byKey(const Key('photo_crop_viewer'));
    final center = tester.getCenter(viewerFinder);

    // Try dragging horizontally: width == side, so horizontal movement should clamp to 0
    await tester.dragFrom(center, const Offset(100, 0));
    await tester.pumpAndSettle();
    final viewerAfterHorizontal = tester.widget<InteractiveViewer>(viewerFinder);
    expect(viewerAfterHorizontal.transformationController!.value.getTranslation().x, 0.0);

    // Try dragging down excessively (trying to show empty space at top)
    await tester.dragFrom(center, const Offset(0, 500));
    await tester.pumpAndSettle();
    final viewerAfterDragDown = tester.widget<InteractiveViewer>(viewerFinder);
    final tyDown = viewerAfterDragDown.transformationController!.value.getTranslation().y;
    // dy cannot exceed 0 (top of image never below top of circle)
    expect(tyDown, lessThanOrEqualTo(0.001));

    // Try dragging up excessively (trying to show empty space at bottom)
    await tester.dragFrom(center, const Offset(0, -1000));
    await tester.pumpAndSettle();
    final viewerAfterDragUp = tester.widget<InteractiveViewer>(viewerFinder);
    final tyUp = viewerAfterDragUp.transformationController!.value.getTranslation().y;
    final imageFinder = find.descendant(of: viewerFinder, matching: find.byType(Image));
    final imageBox = tester.renderObject(imageFinder) as RenderBox;
    final viewerBox = tester.renderObject(viewerFinder) as RenderBox;
    final minDy = viewerBox.size.height - imageBox.size.height;
    expect(tyUp, greaterThanOrEqualTo(minDy - 0.001));
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
