import 'package:flutter/material.dart';
import '../../domain/triage_vertical.dart';

/// Placeholder scaffold for the 5-Step Triage Wizard.
/// Full implementation is built in Phase 4 Plan 02 (04-02).
class TriageWizardScreen extends StatelessWidget {
  final TriageVertical vertical;

  const TriageWizardScreen({
    super.key,
    this.vertical = TriageVertical.psicoEmocional,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          vertical == TriageVertical.psicoEmocional
              ? 'Autoavaliação Psico-Emocional'
              : 'Autoavaliação Física',
        ),
      ),
      body: const Center(
        child: Text('Triage Wizard — Phase 4 implementation in progress'),
      ),
    );
  }
}
