import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Reads width and height from a PNG header, if possible.
///
/// JPEG is left to the async decoder on purpose: its header holds the sensor
/// size before the EXIF rotation, so a portrait iPhone photo would read as
/// landscape and the cover frame would cut the head again.
Size? decodeImageSizeSync(Uint8List bytes) {
  // Check PNG signature: 89 50 4E 47 0D 0A 1A 0A
  if (bytes.length >= 24 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    final view = ByteData.sublistView(bytes);
    final width = view.getUint32(16);
    final height = view.getUint32(20);
    if (width > 0 && height > 0) return Size(width.toDouble(), height.toDouble());
  }

  return null;
}

/// Circular crop step shown after picking or taking a profile photo
/// (client spec 1.1 / strategy §13).
///
/// Features:
/// - Initial frame centres horizontally and places the circle's centre at ~35%
///   of the image height (where faces sit in portrait selfies), clamped so the
///   circle never leaves the image.
/// - Minimum scale covers the circle (cover, not contain) for portrait,
///   landscape and square photos, preventing transparent stripes.
/// - Panning is clamped with [boundaryMargin] = [EdgeInsets.zero] so no empty
///   area ever shows inside the circle.
/// - Output is rendered as a square PNG of [outputSize] pixels.
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

  /// Computes the cover dimensions for the given [side] and [imageSize].
  /// The image expands so that both dimensions are at least [side].
  static Size calculateCoverSize({
    required double side,
    required Size imageSize,
  }) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return Size(side, side);
    }
    final aspect = imageSize.width / imageSize.height;
    if (aspect <= 1.0) {
      // Portrait or square: width is side, height expands
      return Size(side, side / aspect);
    } else {
      // Landscape: height is side, width expands
      return Size(side * aspect, side);
    }
  }

  /// Computes the initial transform:
  /// - Horizontally centred
  /// - Circle centre placed at 35% of image height
  /// - Clamped so the circle never leaves the image
  static Matrix4 calculateInitialTransform({
    required double side,
    required Size imageSize,
  }) {
    final coverSize = calculateCoverSize(side: side, imageSize: imageSize);
    final childWidth = coverSize.width;
    final childHeight = coverSize.height;

    // Centre horizontally
    final dxInitial = (side - childWidth) / 2.0;
    final dx = dxInitial.clamp(side - childWidth, 0.0);

    // Place circle centre (side / 2) at 35% of image height
    final targetY = 0.35 * childHeight;
    final dyInitial = (side / 2.0) - targetY;
    final dy = dyInitial.clamp(side - childHeight, 0.0);

    return Matrix4.translationValues(dx, dy, 0.0);
  }

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final TransformationController _transform = TransformationController();
  Size? _imageSize;
  bool _initializedTransform = false;
  double? _lastSide;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _imageSize = decodeImageSizeSync(widget.imageBytes);
    if (_imageSize == null) {
      ui.instantiateImageCodec(widget.imageBytes).then((codec) {
        return codec.getNextFrame();
      }).then((frame) {
        if (mounted) {
          setState(() {
            _imageSize = Size(
              frame.image.width.toDouble(),
              frame.image.height.toDouble(),
            );
            // Frame again with the real (rotated) size.
            _initializedTransform = false;
          });
        }
      }).catchError((_) {});
    }
  }

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

            final effectiveImageSize = _imageSize ?? Size(side, side);
            final coverSize = PhotoCropScreen.calculateCoverSize(
              side: side,
              imageSize: effectiveImageSize,
            );

            if (!_initializedTransform || _lastSide != side) {
              _lastSide = side;
              _initializedTransform = true;
              _transform.value = PhotoCropScreen.calculateInitialTransform(
                side: side,
                imageSize: effectiveImageSize,
              );
            }

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
                              child: SizedBox(
                                width: side,
                                height: side,
                                child: InteractiveViewer(
                                  key: const Key('photo_crop_viewer'),
                                  transformationController: _transform,
                                  constrained: false,
                                  boundaryMargin: EdgeInsets.zero,
                                  minScale: 1.0,
                                  maxScale: 5.0,
                                  clipBehavior: Clip.hardEdge,
                                  child: SizedBox(
                                    width: coverSize.width,
                                    height: coverSize.height,
                                    child: Image.memory(
                                      widget.imageBytes,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    ),
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
                          onPressed: () {
                            _transform.value =
                                PhotoCropScreen.calculateInitialTransform(
                              side: side,
                              imageSize: effectiveImageSize,
                            );
                          },
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
