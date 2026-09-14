import 'package:flutter/material.dart';

enum DashboardTab { emotional, physical }

class DashboardSegmentedTab extends StatelessWidget {
  final DashboardTab selectedTab;
  final ValueChanged<DashboardTab> onTabChanged;

  const DashboardSegmentedTab({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              tab: DashboardTab.emotional,
              label: 'Psico-Emocional',
              icon: Icons.psychology_rounded,
              activeColor: const Color(0xFF3F51B5),
            ),
          ),
          Expanded(
            child: _buildSegmentButton(
              tab: DashboardTab.physical,
              label: 'Física',
              icon: Icons.accessibility_new_rounded,
              activeColor: const Color(0xFF00796B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required DashboardTab tab,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = selectedTab == tab;

    return GestureDetector(
      onTap: () => onTabChanged(tab),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
