import 'package:flutter/material.dart';
import '../../domain/emergency_context.dart';

/// Screen 8: Emergency Risk Alert Screen (RF-006).
///
/// Displayed when a red-flag symptom or clinical emergency is identified.
class EmergencyScreen extends StatelessWidget {
  final EmergencyContext emergencyContext;

  const EmergencyScreen({
    super.key,
    required this.emergencyContext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD32F2F),
      body: SafeArea(
        child: Center(
          child: Text(
            'Emergency: ${emergencyContext.category.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
