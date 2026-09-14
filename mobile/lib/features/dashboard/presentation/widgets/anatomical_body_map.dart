import 'package:flutter/material.dart';

class AnatomicalRegion {
  final String key;
  final String label;
  final Rect relativeBounds;

  const AnatomicalRegion({
    required this.key,
    required this.label,
    required this.relativeBounds,
  });
}

class AnatomicalBodyMap extends StatefulWidget {
  final Map<String, int> physicalSummary;
  final ValueChanged<String>? onRegionSelected;

  const AnatomicalBodyMap({
    super.key,
    required this.physicalSummary,
    this.onRegionSelected,
  });

  @override
  State<AnatomicalBodyMap> createState() => _AnatomicalBodyMapState();
}

class _AnatomicalBodyMapState extends State<AnatomicalBodyMap> {
  String? _selectedRegionKey;

  static const List<AnatomicalRegion> regions = [
    AnatomicalRegion(
      key: 'cabeca_pescoco',
      label: 'Cabeça e Pescoço',
      relativeBounds: Rect.fromLTWH(0.40, 0.05, 0.20, 0.12),
    ),
    AnatomicalRegion(
      key: 'neurologico',
      label: 'Neurológico (Cranial)',
      relativeBounds: Rect.fromLTWH(0.35, 0.02, 0.30, 0.08),
    ),
    AnatomicalRegion(
      key: 'cardiovascular_torax',
      label: 'Cardiovascular / Tórax',
      relativeBounds: Rect.fromLTWH(0.35, 0.18, 0.30, 0.14),
    ),
    AnatomicalRegion(
      key: 'respiratorio',
      label: 'Respiratório (Pulmões)',
      relativeBounds: Rect.fromLTWH(0.30, 0.19, 0.40, 0.12),
    ),
    AnatomicalRegion(
      key: 'gastrointestinal_abdomen',
      label: 'Gastrointestinal / Abdômen',
      relativeBounds: Rect.fromLTWH(0.36, 0.33, 0.28, 0.13),
    ),
    AnatomicalRegion(
      key: 'coluna_dorsal',
      label: 'Coluna e Dor Dorsal',
      relativeBounds: Rect.fromLTWH(0.44, 0.22, 0.12, 0.24),
    ),
    AnatomicalRegion(
      key: 'membros_superiores_d',
      label: 'Membros Superiores (D)',
      relativeBounds: Rect.fromLTWH(0.18, 0.18, 0.16, 0.32),
    ),
    AnatomicalRegion(
      key: 'membros_superiores_e',
      label: 'Membros Superiores (E)',
      relativeBounds: Rect.fromLTWH(0.66, 0.18, 0.16, 0.32),
    ),
    AnatomicalRegion(
      key: 'geniturinario_pelvico',
      label: 'Geniturinário / Pélvico',
      relativeBounds: Rect.fromLTWH(0.38, 0.47, 0.24, 0.10),
    ),
    AnatomicalRegion(
      key: 'membros_inferiores_d',
      label: 'Membros Inferiores (D)',
      relativeBounds: Rect.fromLTWH(0.31, 0.58, 0.16, 0.38),
    ),
    AnatomicalRegion(
      key: 'membros_inferiores_e',
      label: 'Membros Inferiores (E)',
      relativeBounds: Rect.fromLTWH(0.53, 0.58, 0.16, 0.38),
    ),
    AnatomicalRegion(
      key: 'dermatologico',
      label: 'Dermatológico (Geral)',
      relativeBounds: Rect.fromLTWH(0.24, 0.12, 0.52, 0.78),
    ),
  ];

  static Color getHeatColor(int intensity) {
    if (intensity <= 0) return const Color(0xFFCFD8DC);
    if (intensity <= 2) return const Color(0xFFFFD54F);
    if (intensity == 3) return const Color(0xFFFF8A65);
    return const Color(0xFFE53935);
  }

  void _handleTap(Offset localPosition, Size size) {
    final relX = localPosition.dx / size.width;
    final relY = localPosition.dy / size.height;

    String? foundKey;
    for (final reg in regions) {
      if (reg.key == 'dermatologico') continue;
      if (reg.relativeBounds.contains(Offset(relX, relY))) {
        foundKey = reg.key;
        break;
      }
    }

    foundKey ??= 'dermatologico';

    setState(() {
      _selectedRegionKey = foundKey;
    });

    if (widget.onRegionSelected != null) {
      widget.onRegionSelected!(foundKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRegion = regions.firstWhere(
      (r) => r.key == _selectedRegionKey,
      orElse: () => regions.first,
    );
    final selectedIntensity = widget.physicalSummary[_selectedRegionKey] ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth = constraints.maxWidth.clamp(200.0, 320.0);
            final canvasHeight = canvasWidth * 1.35;
            final canvasSize = Size(canvasWidth, canvasHeight);

            return GestureDetector(
              key: const Key('body_map_gesture_detector'),
              onTapUp: (details) => _handleTap(details.localPosition, canvasSize),
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: CustomPaint(
                  size: canvasSize,
                  painter: _BodyMapPainter(
                    physicalSummary: widget.physicalSummary,
                    selectedRegionKey: _selectedRegionKey,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildLegendBar(),
        const SizedBox(height: 12),
        if (_selectedRegionKey != null)
          _buildRegionDetailCard(selectedRegion, selectedIntensity),
      ],
    );
  }

  Widget _buildLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Sem dor', const Color(0xFFCFD8DC)),
          _buildLegendItem('Leve (1-2)', const Color(0xFFFFD54F)),
          _buildLegendItem('Moderada (3)', const Color(0xFFFF8A65)),
          _buildLegendItem('Intensa (4-5)', const Color(0xFFE53935)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildRegionDetailCard(AnatomicalRegion region, int intensity) {
    final heatColor = getHeatColor(intensity);
    return Card(
      key: const Key('body_map_detail_card'),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: heatColor.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: heatColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.accessibility_new, color: heatColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    intensity > 0
                        ? 'Intensidade máxima nos últimos 14 dias: Nível $intensity'
                        : 'Nenhum sintoma registrado nos últimos 14 dias',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (intensity > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: heatColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$intensity/5',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BodyMapPainter extends CustomPainter {
  final Map<String, int> physicalSummary;
  final String? selectedRegionKey;

  _BodyMapPainter({
    required this.physicalSummary,
    this.selectedRegionKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final basePaint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final headRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.10),
      width: w * 0.20,
      height: h * 0.12,
    );
    final headIntensity = physicalSummary['cabeca_pescoco'] ?? 0;
    final headPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(headIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawOval(headRect, basePaint);
    canvas.drawOval(headRect, headPaint);
    canvas.drawOval(headRect, outlinePaint);

    final chestRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.35, h * 0.18, w * 0.30, h * 0.14),
      const Radius.circular(8),
    );
    final chestIntensity = physicalSummary['cardiovascular_torax'] ?? 0;
    final chestPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(chestIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(chestRect, basePaint);
    canvas.drawRRect(chestRect, chestPaint);
    canvas.drawRRect(chestRect, outlinePaint);

    final abdRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.36, h * 0.33, w * 0.28, h * 0.13),
      const Radius.circular(8),
    );
    final abdIntensity = physicalSummary['gastrointestinal_abdomen'] ?? 0;
    final abdPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(abdIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(abdRect, basePaint);
    canvas.drawRRect(abdRect, abdPaint);
    canvas.drawRRect(abdRect, outlinePaint);

    final pelvicRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.47, w * 0.24, h * 0.10),
      const Radius.circular(6),
    );
    final pelvicIntensity = physicalSummary['geniturinario_pelvico'] ?? 0;
    final pelvicPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(pelvicIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(pelvicRect, basePaint);
    canvas.drawRRect(pelvicRect, pelvicPaint);
    canvas.drawRRect(pelvicRect, outlinePaint);

    final rArmRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.15, h * 0.32),
      const Radius.circular(8),
    );
    final rArmIntensity = physicalSummary['membros_superiores_d'] ?? 0;
    final rArmPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(rArmIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rArmRect, basePaint);
    canvas.drawRRect(rArmRect, rArmPaint);
    canvas.drawRRect(rArmRect, outlinePaint);

    final lArmRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.67, h * 0.18, w * 0.15, h * 0.32),
      const Radius.circular(8),
    );
    final lArmIntensity = physicalSummary['membros_superiores_e'] ?? 0;
    final lArmPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(lArmIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(lArmRect, basePaint);
    canvas.drawRRect(lArmRect, lArmPaint);
    canvas.drawRRect(lArmRect, outlinePaint);

    final rLegRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.32, h * 0.58, w * 0.16, h * 0.38),
      const Radius.circular(10),
    );
    final rLegIntensity = physicalSummary['membros_inferiores_d'] ?? 0;
    final rLegPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(rLegIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rLegRect, basePaint);
    canvas.drawRRect(rLegRect, rLegPaint);
    canvas.drawRRect(rLegRect, outlinePaint);

    final lLegRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.52, h * 0.58, w * 0.16, h * 0.38),
      const Radius.circular(10),
    );
    final lLegIntensity = physicalSummary['membros_inferiores_e'] ?? 0;
    final lLegPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(lLegIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(lLegRect, basePaint);
    canvas.drawRRect(lLegRect, lLegPaint);
    canvas.drawRRect(lLegRect, outlinePaint);

    final spineLine = Path()
      ..moveTo(w * 0.50, h * 0.17)
      ..lineTo(w * 0.50, h * 0.46);
    final spineIntensity = physicalSummary['coluna_dorsal'] ?? 0;
    final spinePaint = Paint()
      ..color = spineIntensity > 0
          ? _AnatomicalBodyMapState.getHeatColor(spineIntensity)
          : const Color(0xFF78909C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = spineIntensity > 0 ? 5.0 : 2.5;
    canvas.drawPath(spineLine, spinePaint);

    if (selectedRegionKey != null) {
      final selectedRegion = _AnatomicalBodyMapState.regions.firstWhere(
        (r) => r.key == selectedRegionKey,
        orElse: () => _AnatomicalBodyMapState.regions.first,
      );
      final bounds = selectedRegion.relativeBounds;
      final highlightRect = Rect.fromLTWH(
        bounds.left * w,
        bounds.top * h,
        bounds.width * w,
        bounds.height * h,
      );
      final highlightPaint = Paint()
        ..color = const Color(0xFF00796B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BodyMapPainter oldDelegate) {
    return oldDelegate.physicalSummary != physicalSummary ||
        oldDelegate.selectedRegionKey != selectedRegionKey;
  }
}
