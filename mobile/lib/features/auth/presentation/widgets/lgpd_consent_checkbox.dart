import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class LgpdConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const LgpdConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  void _showDisclaimerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Política de Privacidade e Termo de Consentimento (LGPD Art. 11)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'O DualisCheckUp é uma plataforma móvel de auto-monitoramento preventivo e triagem de bem-estar físico e psico-emocional. O aplicativo NÃO realiza diagnósticos médicos, NÃO prescreve medicamentos ou tratamentos e NÃO substitui a consulta clínica presencial ou o aconselhamento de um médico devidamente registrado no CRM.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bases Normativas & Regulatórias:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Anvisa RDC nº 657/2022: Regulamentação de Software como Dispositivo Médico (SaMD).\n'
                    '• CFM Resolução nº 2.314/2022: Normas de Telemedicina no Brasil.\n'
                    '• Lei Federal nº 13.709/2018 (LGPD): Art. 11 - Tratamento de dados pessoais sensíveis de saúde.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.softIndigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Compreendi e Fechar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: const Key('lgpdConsentCheckbox'),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.softIndigo,
      title: Text.rich(
        TextSpan(
          text: 'Li e concordo com a ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textPrimaryLight,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: 'Política de Privacidade',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.softIndigo,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _showDisclaimerBottomSheet(context),
            ),
            const TextSpan(
              text:
                  ' e consinto expressamente com o tratamento de meus dados pessoais sensíveis de saúde para fins de triagem preventiva e acompanhamento longitudinal, nos termos do Art. 11 da LGPD.',
            ),
          ],
        ),
      ),
    );
  }
}
