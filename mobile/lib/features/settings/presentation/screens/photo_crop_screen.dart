import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Circular crop step shown after picking or taking a profile photo
/// (strategy §13). The person pinches to zoom and drags to frame the face;
/// the square under the circle is saved as a PNG of [outputSize] pixels.
/// Built with InteractiveViewer and RenderRepaintBoundary only (no plugins).
class PhotoCropScreen extends StatefulWidget {
  static const double outputSize = 512;

  final Uint8List imageBytes;

  const PhotoCropScreen({super.key, required this.imageBytes});

  /// Opens the crop screen and returns the cropped PNG, or null on cancel.
  static Future<Uint8List?> open(BuildContext context, Uint8List bytes) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoCropScreen(imageBytes: bytes),
      ),
    );
  }

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final TransformationController _transform = TransformationController();
  bool _saving = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    final bytes = await cropBoundaryToPng(_boundaryKey);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          l10n.xv2CropTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          key: const Key('photo_crop_cancel'),
          tooltip: l10n.cancel,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [SizedBox(width: 56)],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = (constraints.maxWidth < constraints.maxHeight - 160
                    ? constraints.maxWidth
                    : constraints.maxHeight - 160)
                .clamp(160.0, 520.0) -
                32;
            return Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  l10n.xv2CropHint,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RepaintBoundary(
                            key: _boundaryKey,
                            child: ClipRect(
                              child: InteractiveViewer(
                                key: const Key('photo_crop_viewer'),
                                transformationController: _transform,
                                minScale: 1,
                                maxScale: 5,
                                clipBehavior: Clip.hardEdge,
                                child: SizedBox(
                                  width: side,
                                  height: side,
                                  child: Image.memory(
                                    widget.imageBytes,
                                    // Contain keeps the whole picture (heads included).
                                    // Cover was cropping the top before the person could zoom.
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const IgnorePointer(
                            child: CustomPaint(painter: _CircleMaskPainter()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            minimumSize: const Size.fromHeight(52),
                          ),
                          onPressed: () => _transform.value = Matrix4.identity(),
                          child: Text(l10n.xv2CropReset),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const Key('photo_crop_confirm'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.clinicalTeal,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                          ),
                          onPressed: _saving ? null : _confirm,
                          child: Text(l10n.xv2CropConfirm),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Renders the boundary (the square under the circle) to a PNG of
/// [PhotoCropScreen.outputSize] pixels. Returns null if it is not laid out.
Future<Uint8List?> cropBoundaryToPng(GlobalKey boundaryKey) async {
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary || !boundary.hasSize) return null;
  final ratio = PhotoCropScreen.outputSize / boundary.size.width;
  final ui.Image image = await boundary.toImage(pixelRatio: ratio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Dims everything outside the crop circle.
class _CircleMaskPainter extends CustomPainter {
  const _CircleMaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Path()..addOval(rect.deflate(2));
    final mask = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      circle,
    );
    canvas.drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawPath(
      circle,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleMaskPainter oldDelegate) => false;
}
