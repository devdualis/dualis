import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/dualis_logo.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Termos de Uso do SaaS',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimaryLight,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight),
          onPressed: () => context.canPop() ? context.pop() : context.go(RoutePaths.settings),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DualisLogo(
                      variant: DualisLogoVariant.horizontal,
                      width: 140,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Termos e Condições de Uso',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Versão 2026.1 • Atualizado em 01/10/2026',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      'Contrato de prestação de serviços de software em nuvem (SaaS) celebrado entre o Usuário e a DualisCheckUp Saúde e Tecnologia Ltda., inscrita no CNPJ sob o nº 48.291.834/0001-92, com sede em São Paulo/SP, Brasil.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1
              _LegalSectionCard(
                title: '1. Aceitação e Capacidade Civil',
                icon: Icons.assignment_turned_in_outlined,
                color: AppColors.clinicalTeal,
                content:
                    'Ao cadastrar-se ou utilizar o DualisCheckUp, você declara possuir capacidade civil plena (maior de 18 anos ou emancipado) e manifesta concordância integral com estes Termos de Uso e com nossa Política de Privacidade.',
              ),
              const SizedBox(height: 16),

              // Section 2
              _LegalSectionCard(
                title: '2. Limitação de Responsabilidade Médica (SaMD)',
                icon: Icons.medical_services_outlined,
                color: AppColors.emergencyCrimson,
                content:
                    'O DualisCheckUp é uma plataforma tecnológica de suporte ao bem-estar e estratificação de risco preventivo, classificada conforme a Resolução RDC Anvisa nº 657/2022 e a Resolução CFM nº 2.314/2022:',
                bullets: const [
                  'O software NÃO realiza diagnósticos nosológicos e NÃO prescreve medicações.',
                  'A triagem NÃO substitui consultas médicas presenciais ou pareceres de especialistas.',
                  'Em caso de dor aguda intensa, sintomas neurológicos súbitos ou risco de vida, ligue imediatamente para o SAMU (192) ou compareça à emergência hospitalar mais próxima.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 3
              _LegalSectionCard(
                title: '3. Planos SaaS, Cobrança e Reembolso',
                icon: Icons.credit_card_outlined,
                color: AppColors.softIndigo,
                content:
                    'O serviço oferece planos com renovação automática periódica geridos por intermediadores com certificação PCI-DSS:',
                bullets: const [
                  'Cancelamento Facilitado: Você pode cancelar sua assinatura a qualquer momento no app com um toque, sem fidelidade ou taxas de cancelamento.',
                  'Direito de Arrependimento (CDC Art. 49): Garantia de reembolso integral em até 7 (sete) dias corridos a partir da contratação inicial.',
                  'Acesso Contínuo: O cancelamento interrompe faturas subsequentes e preserva seu acesso até o término do ciclo mensal contratado.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 4
              _LegalSectionCard(
                title: '4. Propriedade Intelectual',
                icon: Icons.copyright_outlined,
                color: AppColors.clinicalTealDark,
                content:
                    'Todos os direitos de propriedade intelectual sobre os algoritmos heurísticos, árvores de triagem, modelos de IA, interfaces e marcas pertencem com exclusividade à DualisCheckUp Saúde e Tecnologia Ltda. É estritamente vedada a reprodução, engenharia reversa ou mineração de dados.',
              ),
              const SizedBox(height: 16),

              // Section 5
              _LegalSectionCard(
                title: '5. Suspensão por Violação de Segurança',
                icon: Icons.shield_outlined,
                color: AppColors.softIndigo,
                content:
                    'Contas que executarem tentativas de invasão, ataques de força bruta, testes de penetração não autorizados ou submissão de dados fraudulentos serão imediatamente bloqueadas, com encaminhamento às autoridades competentes.',
              ),
              const SizedBox(height: 16),

              // Section 6
              _LegalSectionCard(
                title: '6. Foro e Contato Jurídico',
                icon: Icons.gavel_outlined,
                color: AppColors.textPrimaryLight,
                content:
                    'Estes termos são regidos pelas leis brasileiras. Fica eleito o Foro da Comarca de São Paulo/SP como único competente para dirimir litígios decorrentes deste contrato.\n\nPara dúvidas ou notificações legais: legal@dualischeckup.com.',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String content;
  final List<String>? bullets;

  const _LegalSectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
    this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          if (bullets != null && bullets!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...bullets!.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bullet,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
