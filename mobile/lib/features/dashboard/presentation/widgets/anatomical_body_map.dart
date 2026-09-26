import 'package:flutter/material.dart';
import '../../../../core/clinical/clinical_intensity_tier.dart';

class AnatomicalRegion {
  final String key;
  final String label;
  final String categoryGroup;
  final IconData icon;
  final String clinicalHint;
  final Rect relativeBounds;

  const AnatomicalRegion({
    required this.key,
    required this.label,
    required this.categoryGroup,
    required this.icon,
    required this.clinicalHint,
    required this.relativeBounds,
  });
}

enum _BodyViewMode {
  map,
  grid,
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
  _BodyViewMode _viewMode = _BodyViewMode.map;

  static const List<AnatomicalRegion> regions = [
    AnatomicalRegion(
      key: 'cabeca_pescoco',
      label: 'Cabeça e Pescoço',
      categoryGroup: 'Cabeça & Nervos',
      icon: Icons.face_rounded,
      clinicalHint: 'Cefaleia, dores cervicais, rigidez no pescoço',
      relativeBounds: Rect.fromLTWH(0.38, 0.07, 0.24, 0.10),
    ),
    AnatomicalRegion(
      key: 'neurologico',
      label: 'Neurológico (Cranial)',
      categoryGroup: 'Cabeça & Nervos',
      icon: Icons.psychology_rounded,
      clinicalHint: 'Tonturas, vertigens, equilíbrio, cefaleias atípicas',
      relativeBounds: Rect.fromLTWH(0.35, 0.01, 0.30, 0.06),
    ),
    AnatomicalRegion(
      key: 'coluna_dorsal',
      label: 'Coluna e Dor Dorsal',
      categoryGroup: 'Tórax & Tronco',
      icon: Icons.view_headline_rounded,
      clinicalHint: 'Dores posturais, coluna dorsal e lombar',
      relativeBounds: Rect.fromLTWH(0.44, 0.17, 0.12, 0.30),
    ),
    AnatomicalRegion(
      key: 'respiratorio',
      label: 'Respiratório (Pulmões)',
      categoryGroup: 'Tórax & Tronco',
      icon: Icons.air_rounded,
      clinicalHint: 'Dispneia funcional, tosse, desconforto pulmonar',
      relativeBounds: Rect.fromLTWH(0.35, 0.18, 0.15, 0.14),
    ),
    AnatomicalRegion(
      key: 'cardiovascular_torax',
      label: 'Cardiovascular / Tórax',
      categoryGroup: 'Tórax & Tronco',
      icon: Icons.favorite_rounded,
      clinicalHint: 'Sensação de aperto torácico, palpitações',
      relativeBounds: Rect.fromLTWH(0.50, 0.18, 0.15, 0.14),
    ),
    AnatomicalRegion(
      key: 'gastrointestinal_abdomen',
      label: 'Gastrointestinal / Abdômen',
      categoryGroup: 'Tórax & Tronco',
      icon: Icons.lunch_dining_rounded,
      clinicalHint: 'Desconforto gástrico, cólicas, refluxo',
      relativeBounds: Rect.fromLTWH(0.36, 0.33, 0.28, 0.13),
    ),
    AnatomicalRegion(
      key: 'geniturinario_pelvico',
      label: 'Geniturinário / Pélvico',
      categoryGroup: 'Tórax & Tronco',
      icon: Icons.health_and_safety_rounded,
      clinicalHint: 'Desconforto pélvico e queixas urinárias',
      relativeBounds: Rect.fromLTWH(0.38, 0.47, 0.24, 0.10),
    ),
    AnatomicalRegion(
      key: 'membros_superiores_d',
      label: 'Membros Superiores (D)',
      categoryGroup: 'Membros',
      icon: Icons.front_hand_rounded,
      clinicalHint: 'Braço, ombro, cotovelo ou punho direito',
      relativeBounds: Rect.fromLTWH(0.18, 0.18, 0.16, 0.32),
    ),
    AnatomicalRegion(
      key: 'membros_superiores_e',
      label: 'Membros Superiores (E)',
      categoryGroup: 'Membros',
      icon: Icons.front_hand_rounded,
      clinicalHint: 'Braço, ombro, cotovelo ou punho esquerdo',
      relativeBounds: Rect.fromLTWH(0.66, 0.18, 0.16, 0.32),
    ),
    AnatomicalRegion(
      key: 'membros_inferiores_d',
      label: 'Membros Inferiores (D)',
      categoryGroup: 'Membros',
      icon: Icons.accessibility_rounded,
      clinicalHint: 'Quadril, coxa, joelho ou tornozelo direito',
      relativeBounds: Rect.fromLTWH(0.31, 0.58, 0.16, 0.38),
    ),
    AnatomicalRegion(
      key: 'membros_inferiores_e',
      label: 'Membros Inferiores (E)',
      categoryGroup: 'Membros',
      icon: Icons.accessibility_rounded,
      clinicalHint: 'Quadril, coxa, joelho ou tornozelo esquerdo',
      relativeBounds: Rect.fromLTWH(0.53, 0.58, 0.16, 0.38),
    ),
    AnatomicalRegion(
      key: 'dermatologico',
      label: 'Dermatológico (Pele)',
      categoryGroup: 'Sistêmico & Pele',
      icon: Icons.spa_rounded,
      clinicalHint: 'Prurido, lesões cutâneas, sensibilidade na pele',
      relativeBounds: Rect.fromLTWH(0.24, 0.12, 0.52, 0.78),
    ),
    AnatomicalRegion(
      key: 'muscular_geral_sistemico',
      label: 'Muscular Geral / Sistêmico',
      categoryGroup: 'Sistêmico & Pele',
      icon: Icons.fitness_center_rounded,
      clinicalHint: 'Mialgia difusa, cansaço muscular corporal amplo',
      relativeBounds: Rect.zero,
    ),
    AnatomicalRegion(
      key: 'endocrino_metabolico',
      label: 'Endócrino / Metabólico',
      categoryGroup: 'Sistêmico & Pele',
      icon: Icons.bolt_rounded,
      clinicalHint: 'Oscilações energéticas, metabolismo e sede',
      relativeBounds: Rect.zero,
    ),
  ];

  static Color getHeatColor(int intensity) {
    return ClinicalIntensityTier.fromIntensity(intensity).color;
  }

  void _handleTap(Offset localPosition, Size size) {
    final relX = localPosition.dx / size.width;
    final relY = localPosition.dy / size.height;

    String? foundKey;
    final spineRegion = regions.firstWhere((r) => r.key == 'coluna_dorsal');
    if (spineRegion.relativeBounds.contains(Offset(relX, relY))) {
      foundKey = 'coluna_dorsal';
    } else if (relY < 0.08 && relX >= 0.35 && relX <= 0.65) {
      foundKey = 'neurologico';
    } else if (relY >= 0.08 && relY < 0.17 && relX >= 0.36 && relX <= 0.64) {
      foundKey = 'cabeca_pescoco';
    } else if (relY >= 0.18 && relY <= 0.32 && relX >= 0.35 && relX <= 0.65) {
      if (relX >= 0.48 && relX <= 0.58 && relY >= 0.20 && relY <= 0.28) {
        foundKey = 'cardiovascular_torax';
      } else {
        foundKey = 'respiratorio';
      }
    } else {
      for (final reg in regions) {
        if (reg.key == 'dermatologico' ||
            reg.key == 'coluna_dorsal' ||
            reg.key == 'neurologico' ||
            reg.key == 'cabeca_pescoco' ||
            reg.key == 'cardiovascular_torax' ||
            reg.key == 'respiratorio' ||
            reg.relativeBounds == Rect.zero) {
          continue;
        }
        if (reg.relativeBounds.contains(Offset(relX, relY))) {
          foundKey = reg.key;
          break;
        }
      }
    }

    foundKey ??= 'dermatologico';

    _selectRegion(foundKey);
  }

  void _selectRegion(String key) {
    setState(() {
      _selectedRegionKey = key;
    });

    if (widget.onRegionSelected != null) {
      widget.onRegionSelected!(key);
    }
  }

  int _resolveIntensity(String? key) {
    if (key == null) return 0;
    int intensity = widget.physicalSummary[key] ?? 0;
    if (intensity == 0) {
      if (key == 'coluna_dorsal') {
        intensity = widget.physicalSummary['coluna_dor_dorsal'] ?? 0;
      } else if (key == 'membros_superiores_d' || key == 'membros_superiores_e') {
        final hasSpecificArm =
            (widget.physicalSummary['membros_superiores_d'] ?? 0) > 0 ||
                (widget.physicalSummary['membros_superiores_e'] ?? 0) > 0;
        if (!hasSpecificArm) {
          intensity = widget.physicalSummary['membros_superiores'] ?? 0;
        }
      } else if (key == 'membros_inferiores_d' || key == 'membros_inferiores_e') {
        final hasSpecificLeg =
            (widget.physicalSummary['membros_inferiores_d'] ?? 0) > 0 ||
                (widget.physicalSummary['membros_inferiores_e'] ?? 0) > 0;
        if (!hasSpecificLeg) {
          intensity = widget.physicalSummary['membros_inferiores'] ?? 0;
        }
      }
    }
    return intensity;
  }

  @override
  Widget build(BuildContext context) {
    final selectedRegion = regions.firstWhere(
      (r) => r.key == _selectedRegionKey,
      orElse: () => regions.first,
    );
    final selectedIntensity = _resolveIntensity(_selectedRegionKey);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildViewModeToggle(),
        const SizedBox(height: 8),
        if (_viewMode == _BodyViewMode.map) ...[
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasWidth = constraints.maxWidth.clamp(150.0, 190.0);
                final canvasHeight = canvasWidth * 1.30;
                final canvasSize = Size(canvasWidth, canvasHeight);

                return GestureDetector(
                  key: const Key('body_map_gesture_detector'),
                  onTapUp: (details) => _handleTap(details.localPosition, canvasSize),
                  child: SizedBox(
                    width: canvasWidth,
                    height: canvasHeight,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: canvasSize,
                        painter: _BodyMapPainter(
                          physicalSummary: widget.physicalSummary,
                          selectedRegionKey: _selectedRegionKey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendBar(),
          const SizedBox(height: 10),
          _buildSystemicSection(),
        ] else ...[
          _buildCompleteSystemsMatrix(),
          const SizedBox(height: 8),
          _buildLegendBar(),
        ],
        const SizedBox(height: 10),
        if (_selectedRegionKey != null)
          _buildRegionDetailCard(selectedRegion, selectedIntensity),
      ],
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              title: 'Mapa Anatômico',
              icon: Icons.accessibility_new_rounded,
              isSelected: _viewMode == _BodyViewMode.map,
              onTap: () => setState(() => _viewMode = _BodyViewMode.map),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              title: 'Todos os 12 Sistemas',
              icon: Icons.grid_view_rounded,
              isSelected: _viewMode == _BodyViewMode.grid,
              onTap: () => setState(() => _viewMode = _BodyViewMode.grid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF00796B) : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF00796B) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: ClinicalIntensityTier.values.map((tier) {
          return _buildLegendItem(tier.label, tier.color);
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSystemicSection() {
    final systemicKeys = [
      'dermatologico',
      'muscular_geral_sistemico',
      'endocrino_metabolico',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.layers_outlined, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 5),
            Text(
              'Sistemas Gerais & Cutâneos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: systemicKeys.map((key) {
            final reg = regions.firstWhere((r) => r.key == key);
            final intensity = _resolveIntensity(key);
            final heatColor = getHeatColor(intensity);
            final isSelected = _selectedRegionKey == key;

            return Expanded(
              child: GestureDetector(
                onTap: () => _selectRegion(key),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00796B).withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00796B)
                          : Colors.grey.shade300,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: heatColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(reg.icon, size: 16, color: heatColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        key == 'dermatologico'
                            ? 'Pele'
                            : key == 'muscular_geral_sistemico'
                                ? 'Muscular'
                                : 'Endócrino',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: const Color(0xFF263238),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: heatColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          intensity > 0 ? '$intensity/5' : 'Normal',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompleteSystemsMatrix() {
    final groups = <String, List<AnatomicalRegion>>{};
    for (final reg in regions) {
      groups.putIfAbsent(reg.categoryGroup, () => []).add(reg);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00796B),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              ...entry.value.map((reg) {
                final intensity = _resolveIntensity(reg.key);
                final heatColor = getHeatColor(intensity);
                final isSelected = _selectedRegionKey == reg.key;

                return InkWell(
                  onTap: () => _selectRegion(reg.key),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00796B).withValues(alpha: 0.08)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00796B)
                            : Colors.grey.shade200,
                        width: isSelected ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: heatColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(reg.icon, size: 16, color: heatColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reg.label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: const Color(0xFF263238),
                                ),
                              ),
                              Text(
                                reg.clinicalHint,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: heatColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            intensity > 0 ? '$intensity/5' : 'Sem dor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRegionDetailCard(AnatomicalRegion region, int intensity) {
    final heatColor = getHeatColor(intensity);
    String subtitle;
    VoidCallback? onSelectOpposite;
    String? oppositeActionLabel;

    if (intensity > 0) {
      subtitle = 'Intensidade máxima nos últimos 14 dias: Nível $intensity\n${region.clinicalHint}';
    } else {
      if (region.key == 'membros_superiores_e' &&
          (widget.physicalSummary['membros_superiores_d'] ?? 0) > 0) {
        final other = widget.physicalSummary['membros_superiores_d']!;
        subtitle =
            'Sem sintomas no lado esquerdo nos últimos 14 dias.\n(Membro Superior Direito possui registro Nível $other)';
        oppositeActionLabel = 'Ver Membro Direito (D)';
        onSelectOpposite = () {
          _selectRegion('membros_superiores_d');
        };
      } else if (region.key == 'membros_superiores_d' &&
          (widget.physicalSummary['membros_superiores_e'] ?? 0) > 0) {
        final other = widget.physicalSummary['membros_superiores_e']!;
        subtitle =
            'Sem sintomas no lado direito nos últimos 14 dias.\n(Membro Superior Esquerdo possui registro Nível $other)';
        oppositeActionLabel = 'Ver Membro Esquerdo (E)';
        onSelectOpposite = () {
          _selectRegion('membros_superiores_e');
        };
      } else if (region.key == 'membros_inferiores_e' &&
          (widget.physicalSummary['membros_inferiores_d'] ?? 0) > 0) {
        final other = widget.physicalSummary['membros_inferiores_d']!;
        subtitle =
            'Sem sintomas no lado esquerdo nos últimos 14 dias.\n(Membro Inferior Direito possui registro Nível $other)';
        oppositeActionLabel = 'Ver Membro Direito (D)';
        onSelectOpposite = () {
          _selectRegion('membros_inferiores_d');
        };
      } else if (region.key == 'membros_inferiores_d' &&
          (widget.physicalSummary['membros_inferiores_e'] ?? 0) > 0) {
        final other = widget.physicalSummary['membros_inferiores_e']!;
        subtitle =
            'Sem sintomas no lado direito nos últimos 14 dias.\n(Membro Inferior Esquerdo possui registro Nível $other)';
        oppositeActionLabel = 'Ver Membro Esquerdo (E)';
        onSelectOpposite = () {
          _selectRegion('membros_inferiores_e');
        };
      } else {
        subtitle = 'Nenhum sintoma registrado nos últimos 14 dias';
      }
    }

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
              child: Icon(region.icon, color: heatColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          region.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          region.categoryGroup,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (onSelectOpposite != null && oppositeActionLabel != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onSelectOpposite,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            oppositeActionLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00796B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Color(0xFF00796B),
                          ),
                        ],
                      ),
                    ),
                  ],
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

  static final Paint _basePaint = Paint()
    ..color = const Color(0xFFECEFF1)
    ..style = PaintingStyle.fill;

  static final Paint _outlinePaint = Paint()
    ..color = const Color(0xFFB0BEC5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 0. Dermatológico (Pele) Aura
    final skinIntensity = physicalSummary['dermatologico'] ?? 0;
    if (skinIntensity > 0) {
      final skinColor = _AnatomicalBodyMapState.getHeatColor(skinIntensity);
      final skinAuraPaint = Paint()
        ..color = skinColor.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0;
      final bodyAuraRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.05, w * 0.68, h * 0.90),
        const Radius.circular(20),
      );
      canvas.drawRRect(bodyAuraRect, skinAuraPaint);
    }

    // 1. Cabeça e Pescoço
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.10),
      width: w * 0.20,
      height: h * 0.12,
    );
    final headIntensity = physicalSummary['cabeca_pescoco'] ?? 0;
    final headPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(headIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawOval(headRect, _basePaint);
    canvas.drawOval(headRect, headPaint);
    canvas.drawOval(headRect, _outlinePaint);

    // 1b. Neurológico (Cranial Crown / Brain indicator)
    final neuroIntensity = physicalSummary['neurologico'] ?? 0;
    final neuroRect = Rect.fromLTWH(w * 0.42, h * 0.045, w * 0.16, h * 0.038);
    final neuroPaint = Paint()
      ..color = neuroIntensity > 0
          ? _AnatomicalBodyMapState.getHeatColor(neuroIntensity)
          : const Color(0xFF90A4AE).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final neuroStroke = Paint()
      ..color = neuroIntensity > 0 ? Colors.white : const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
        RRect.fromRectAndRadius(neuroRect, const Radius.circular(6)), neuroPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(neuroRect, const Radius.circular(6)), neuroStroke);

    // 2. Tórax Container Base
    final chestRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.35, h * 0.18, w * 0.30, h * 0.14),
      const Radius.circular(8),
    );
    canvas.drawRRect(chestRect, _basePaint);
    canvas.drawRRect(chestRect, _outlinePaint);

    // 2b. Respiratório (Lóbulos Pulmonares Direito e Esquerdo)
    final respIntensity = physicalSummary['respiratorio'] ?? 0;
    final respPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(respIntensity)
      ..style = PaintingStyle.fill;
    final lungBorderPaint = Paint()
      ..color = respIntensity > 0
          ? Colors.white.withValues(alpha: 0.8)
          : const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Pulmão Direito (lado esquerdo do observador)
    final rightLung = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.365, h * 0.19, w * 0.105, h * 0.12),
      const Radius.circular(6),
    );
    canvas.drawRRect(rightLung, respPaint);
    canvas.drawRRect(rightLung, lungBorderPaint);

    // Pulmão Esquerdo (lado direito do observador)
    final leftLung = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.53, h * 0.19, w * 0.105, h * 0.12),
      const Radius.circular(6),
    );
    canvas.drawRRect(leftLung, respPaint);
    canvas.drawRRect(leftLung, lungBorderPaint);

    // 2c. Cardiovascular (Área Precordial Cardíaca)
    final cardioIntensity = physicalSummary['cardiovascular_torax'] ?? 0;
    final cardioRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.525, h * 0.245),
        width: w * 0.085,
        height: h * 0.065,
      ),
      const Radius.circular(5),
    );
    final cardioPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(cardioIntensity)
      ..style = PaintingStyle.fill;
    final cardioStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(cardioRect, cardioPaint);
    canvas.drawRRect(cardioRect, cardioStroke);

    // 3. Abdômen
    final abdRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.36, h * 0.33, w * 0.28, h * 0.13),
      const Radius.circular(8),
    );
    final abdIntensity = physicalSummary['gastrointestinal_abdomen'] ?? 0;
    final abdPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(abdIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(abdRect, _basePaint);
    canvas.drawRRect(abdRect, abdPaint);
    canvas.drawRRect(abdRect, _outlinePaint);

    // 4. Geniturinário / Pélvico
    final pelvicRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.47, w * 0.24, h * 0.10),
      const Radius.circular(6),
    );
    final pelvicIntensity = physicalSummary['geniturinario_pelvico'] ?? 0;
    final pelvicPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(pelvicIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(pelvicRect, _basePaint);
    canvas.drawRRect(pelvicRect, pelvicPaint);
    canvas.drawRRect(pelvicRect, _outlinePaint);

    // 5. Membros Superiores (D)
    final rArmRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.15, h * 0.32),
      const Radius.circular(8),
    );
    final rArmIntensity = physicalSummary['membros_superiores_d'] ??
        ((physicalSummary['membros_superiores_e'] ?? 0) == 0
            ? physicalSummary['membros_superiores']
            : 0) ??
        0;
    final rArmPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(rArmIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rArmRect, _basePaint);
    canvas.drawRRect(rArmRect, rArmPaint);
    canvas.drawRRect(rArmRect, _outlinePaint);

    // 6. Membros Superiores (E)
    final lArmRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.67, h * 0.18, w * 0.15, h * 0.32),
      const Radius.circular(8),
    );
    final lArmIntensity = physicalSummary['membros_superiores_e'] ??
        ((physicalSummary['membros_superiores_d'] ?? 0) == 0
            ? physicalSummary['membros_superiores']
            : 0) ??
        0;
    final lArmPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(lArmIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(lArmRect, _basePaint);
    canvas.drawRRect(lArmRect, lArmPaint);
    canvas.drawRRect(lArmRect, _outlinePaint);

    // 7. Membros Inferiores (D)
    final rLegRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.32, h * 0.58, w * 0.16, h * 0.38),
      const Radius.circular(10),
    );
    final rLegIntensity = physicalSummary['membros_inferiores_d'] ??
        ((physicalSummary['membros_inferiores_e'] ?? 0) == 0
            ? physicalSummary['membros_inferiores']
            : 0) ??
        0;
    final rLegPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(rLegIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rLegRect, _basePaint);
    canvas.drawRRect(rLegRect, rLegPaint);
    canvas.drawRRect(rLegRect, _outlinePaint);

    // 8. Membros Inferiores (E)
    final lLegRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.52, h * 0.58, w * 0.16, h * 0.38),
      const Radius.circular(10),
    );
    final lLegIntensity = physicalSummary['membros_inferiores_e'] ??
        ((physicalSummary['membros_inferiores_d'] ?? 0) == 0
            ? physicalSummary['membros_inferiores']
            : 0) ??
        0;
    final lLegPaint = Paint()
      ..color = _AnatomicalBodyMapState.getHeatColor(lLegIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(lLegRect, _basePaint);
    canvas.drawRRect(lLegRect, lLegPaint);
    canvas.drawRRect(lLegRect, _outlinePaint);

    // 9. Coluna e Dor Dorsal
    final spineIntensity = physicalSummary['coluna_dor_dorsal'] ??
        physicalSummary['coluna_dorsal'] ??
        0;
    final spineColor = spineIntensity > 0
        ? _AnatomicalBodyMapState.getHeatColor(spineIntensity)
        : const Color(0xFFB0BEC5);

    final spineCanalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.47, h * 0.17, w * 0.06, h * 0.29),
      const Radius.circular(4),
    );
    final canalPaint = Paint()
      ..color = spineIntensity > 0
          ? spineColor.withValues(alpha: 0.25)
          : ClinicalIntensityTier.none.color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(spineCanalRect, canalPaint);

    const int vertebraeCount = 7;
    final vWidth = w * 0.09;
    final vHeight = h * 0.025;
    final vLeft = (w - vWidth) / 2;
    final startY = h * 0.175;
    final stepY = (h * 0.28 - vHeight) / (vertebraeCount - 1);

    for (int i = 0; i < vertebraeCount; i++) {
      final vRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(vLeft, startY + i * stepY, vWidth, vHeight),
        const Radius.circular(3),
      );
      final vFill = Paint()
        ..color = spineIntensity > 0 ? spineColor : const Color(0xFFECEFF1)
        ..style = PaintingStyle.fill;
      final vStroke = Paint()
        ..color = spineIntensity > 0
            ? Colors.white.withValues(alpha: 0.9)
            : const Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawRRect(vRect, vFill);
      canvas.drawRRect(vRect, vStroke);

      final centerCirclePaint = Paint()
        ..color = spineIntensity > 0
            ? Colors.white.withValues(alpha: 0.8)
            : const Color(0xFF90A4AE)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(w * 0.50, startY + i * stepY + vHeight / 2),
        1.5,
        centerCirclePaint,
      );
    }

    // 10. Destaque de Região Selecionada
    if (selectedRegionKey != null) {
      final selectedRegion = _AnatomicalBodyMapState.regions.firstWhere(
        (r) =>
            r.key == selectedRegionKey ||
            (selectedRegionKey == 'coluna_dor_dorsal' &&
                r.key == 'coluna_dorsal'),
        orElse: () => _AnatomicalBodyMapState.regions.first,
      );
      final bounds = selectedRegion.relativeBounds;
      if (bounds != Rect.zero) {
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
  }

  @override
  bool shouldRepaint(covariant _BodyMapPainter oldDelegate) {
    return oldDelegate.physicalSummary != physicalSummary ||
        oldDelegate.selectedRegionKey != selectedRegionKey;
  }
}
