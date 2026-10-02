import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/dualis_logo.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Política de Privacidade (LGPD)',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimaryLight,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight),
          onPressed: () => context.canPop() ? context.pop() : context.go(RoutePaths.privacyCenter),
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
                      'Política de Privacidade & Proteção de Dados',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Conformidade com a Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/2018)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.clinicalTealDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      'A sua privacidade e a confidencialidade dos seus dados clínicos são a nossa prioridade absoluta. Esta política descreve como tratamos, protegemos e permitimos que você controle integralmente suas informações de saúde.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.clinicalTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppColors.clinicalTeal, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Encarregado de Dados (DPO): dpo@dualischeckup.com',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1
              _PrivacySectionCard(
                title: '1. Dados Pessoais e Sensíveis Coletados',
                icon: Icons.folder_shared_outlined,
                color: AppColors.clinicalTeal,
                content:
                  'Nos termos do Artigo 11 da LGPD, o tratamento de dados pessoais sensíveis de saúde é realizado com o seu consentimento livre, informado e inequívoco:',
                bullets: const [
                  'Dados de Identificação: Nome completo, endereço de e-mail e data de nascimento.',
                  'Dados Biométricos & Fisiológicos: Sexo biológico e consumo de água para calibragem de metas preventivas.',
                  'Histórico Clínico Subjetivo: Queixas e intensidade de sintomas físicos em 12 sistemas corporais e estado emocional em 7 dimensões.',
                  'Dados de Acesso Técnico: Endereço IP mascarado, registros criptográficos de sessão e tokens de autenticação transitórios.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 2
              _PrivacySectionCard(
                title: '2. Finalidade e Proibição de Venda de Dados',
                icon: Icons.health_and_safety_outlined,
                color: AppColors.softIndigo,
                content:
                  'Todos os dados clínicos coletados têm finalidade preventiva e de autogestão de saúde:',
                bullets: const [
                  'Compromisso Ético: É expressamente PROIBIDA a venda, comercialização ou cessão onerosa dos seus dados para corretoras de seguros, anunciantes ou terceiros.',
                  'Estratificação Preventiva: Análise de sintomas e orientações de autocuidado sem emissão de prescrições.',
                  'Garantia Antiburla: Manutenção de cadeia de integridade criptográfica temporal (14 dias) para prevenção de adulterações históricas.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 3
              _PrivacySectionCard(
                title: '3. Pagamentos e Proteção PCI-DSS',
                icon: Icons.lock_clock_outlined,
                color: AppColors.clinicalTealDark,
                content:
                  'A infraestrutura de pagamentos adota isolamento de dados de cartões:',
                bullets: const [
                  'Processamento Tokenizado: Os pagamentos são intermediados por gateways com certificação PCI-DSS Nível 1.',
                  'Zero Armazenamento: Os servidores da DualisCheckUp NÃO recebem, não processam e não salvam números de cartão de crédito ou códigos CVV.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 4
              _PrivacySectionCard(
                title: '4. Seus Direitos como Titular (Art. 18 da LGPD)',
                icon: Icons.shield_moon_outlined,
                color: AppColors.clinicalTeal,
                content:
                  'Você pode exercer seus direitos legais diretamente pelo aplicativo de forma instantânea:',
                bullets: const [
                  'Exportação de Dados: Baixe todo o seu prontuário em formato estruturado (JSON) com um clique na Central de Privacidade.',
                  'Exclusão Definitiva: Solicite a exclusão irrevogável da sua conta e de todos os dados clínicos associados.',
                  'Revogação do Consentimento: Encerre o uso e retire a autorização a qualquer momento.',
                ],
              ),
              const SizedBox(height: 16),

              // Section 5
              _PrivacySectionCard(
                title: '5. Segurança da Informação & Resposta a Incidentes',
                icon: Icons.security_rounded,
                color: AppColors.softIndigo,
                content:
                  'Medidas técnicas de ponta a ponta protegem seus registros:',
                bullets: const [
                  'Isolamento RLS: Cada consulta ao banco PostgreSQL é blindada pela política de Row-Level Security com chave de usuário isolada.',
                  'Criptografia Forte: Conexões TLS 1.3 obrigatórias e senhas protegidas pelo algoritmo Argon2id.',
                  'Plano de Notificação em até 72h: Protocolo de comunicação imediata à Autoridade Nacional de Proteção de Dados (ANPD) e aos usuários em qualquer evento relevante de segurança (LGPD Art. 48).',
                ],
              ),
              const SizedBox(height: 16),

              // Section 6
              _PrivacySectionCard(
                title: '6. Notificações, Comunicações e Opt-Out',
                icon: Icons.notifications_none_rounded,
                color: AppColors.textPrimaryLight,
                content:
                  'Respeitamos a sua tranquilidade e atenção:',
                bullets: const [
                  'Você tem liberdade total para desativar lembretes de hidratação ou notificações de dicas de bem-estar na aba de Configurações a qualquer momento.',
                  'Avisos de segurança e recuperação de conta são de natureza estritamente transacional e protegidos.',
                ],
              ),
              const SizedBox(height: 24),

              // Quick Action Button to Privacy Center
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.clinicalTeal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.clinicalTeal.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Deseja exportar seus dados ou gerenciar sua conta agora?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.clinicalTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.push(RoutePaths.privacyCenter),
                      icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                      label: const Text('Ir para a Central de Privacidade'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String content;
  final List<String>? bullets;

  const _PrivacySectionCard({
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
