import 'package:flutter/material.dart';
import 'anatomical_body_map.dart';

/// Card with the 2D body map of the last 14 days of physical entries.
class BodyMapCard extends StatelessWidget {
  final Map<String, int> physicalSummary;
  final ValueChanged<String>? onRegionSelected;

  const BodyMapCard({
    super.key,
    required this.physicalSummary,
    this.onRegionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Icons.accessibility_new_rounded,
                  color: Color(0xFF00796B),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Mapa Corporal 2D (Últimos 14 Dias)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnatomicalBodyMap(
              physicalSummary: physicalSummary,
              onRegionSelected: onRegionSelected,
            ),
          ],
        ),
      ),
    );
  }
}
