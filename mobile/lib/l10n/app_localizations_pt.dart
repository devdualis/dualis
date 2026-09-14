// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'DualisCheckUp';

  @override
  String get screen1PrimaryCta => 'Criar Conta';

  @override
  String get screen1SecondaryCta => 'Entrar';

  @override
  String get screen2PrimaryCta => 'Finalizar Cadastro';

  @override
  String get valueCard1Title => 'Triagem Preventiva Unificada';

  @override
  String get valueCard1Body =>
      'Conecte sua saúde física e estado psico-emocional em um único fluxo diário inteligente, garantindo cuidado holístico e sem ruídos.';

  @override
  String get valueCard2Title => 'Registros Médicos Blindados';

  @override
  String get valueCard2Body =>
      'Seu histórico clínico protegido por criptografia AES-256 e custodiado sob os mais rigorosos padrões da LGPD. Você é o único dono dos seus dados.';

  @override
  String get valueCard3Title => 'Orientações Preventivas Precisas';

  @override
  String get valueCard3Body =>
      'Recomendações e artigos de especialistas médicos renomados sem diagnósticos falsos ou alarmismos desnecessários.';

  @override
  String get lgpdConsentCheckbox =>
      'Li e concordo com a Política de Privacidade e consinto expressamente com o tratamento de meus dados pessoais sensíveis de saúde para fins de triagem preventiva e acompanhamento longitudinal, nos termos do Art. 11 da LGPD.';

  @override
  String get privacyVeilTitle => 'Dados de Saúde Protegidos';

  @override
  String get privacyVeilBody =>
      'Autentique-se com biometria ou senha para acessar seu prontuário.';

  @override
  String get formErrorName =>
      'Por favor, informe seu nome completo (nome e sobrenome).';

  @override
  String get formErrorEmail => 'Informe um endereço de e-mail válido.';

  @override
  String get formErrorPassword =>
      'A senha deve ter pelo menos 8 caracteres, incluindo letra maiúscula, minúscula, número e símbolo especial.';

  @override
  String get fullName => 'Nome Completo';

  @override
  String get birthDate => 'Data de Nascimento';

  @override
  String get biologicalSex => 'Sexo Biológico';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get sexMale => 'Masculino';

  @override
  String get sexFemale => 'Feminino';

  @override
  String get sexOther => 'Outro';

  @override
  String get language => 'Idioma';

  @override
  String get portuguese => 'Português';

  @override
  String get spanish => 'Espanhol';

  @override
  String get english => 'Inglês';

  @override
  String get emergencyTitle => 'Alerta de Risco Imediato';

  @override
  String get emergencySubtitle =>
      'Sintomas de gravidade identificados. Procure atendimento médico urgente.';

  @override
  String get emergencyBadgeChestPain => 'Dor Torácica Crítica';

  @override
  String get emergencyBadgeRespiratory => 'Dificuldade Respiratória Aguda';

  @override
  String get emergencyBadgeStroke => 'Suspeita de Déficit Neurológico (AVC)';

  @override
  String get emergencyBadgeHeadache => 'Cefaleia Súbita e Explosiva';

  @override
  String get emergencyBadgeEmotional =>
      'Apoio Emocional Imediato / Risco à Vida';

  @override
  String get emergencyBadgeGeneral => 'Sintoma Crítico (Nível 4–5)';

  @override
  String get emergencyInstructionPhysical1 =>
      'Interrompa qualquer esforço físico e permaneça em repouso.';

  @override
  String get emergencyInstructionPhysical2 =>
      'Não dirija até o hospital. Acione o 192 ou peça ajuda a terceiros.';

  @override
  String get emergencyInstructionPhysical3 =>
      'Afrouxe roupas apertadas e tente manter a calma enquanto o socorro chega.';

  @override
  String get emergencyInstructionEmotional1 =>
      'Você não está sozinho(a). Ajuda qualificada e sigilosa está disponível agora.';

  @override
  String get emergencyInstructionEmotional2 =>
      'O CVV oferece apoio emocional gratuito 24 horas por dia pelo telefone 188.';

  @override
  String get emergencyInstructionEmotional3 =>
      'Se sentir que está em perigo imediato, acione o 192 ou procure a emergência.';

  @override
  String get emergencyCallSamu => 'Ligar SAMU (192)';

  @override
  String get emergencyCallBombeiros => 'Ligar Bombeiros (193)';

  @override
  String get emergencyCallCvv => 'Ligar CVV - Apoio Emocional (188)';

  @override
  String get emergencyCallPolicia => 'Ligar Polícia (190)';

  @override
  String get emergencyFindHospital => 'Buscar Pronto-Socorro Mais Próximo';

  @override
  String get emergencyDispatcherHint =>
      'Ao ligar, informe seu endereço com clareza e mantenha a calma.';

  @override
  String get emergencyExitButton => 'Voltar ao Início (Não recomendado)';

  @override
  String get emergencyExitConfirmTitle => 'Atenção Médica Urgente';

  @override
  String get emergencyExitConfirmBody =>
      'Seus sintomas indicam uma situação de risco à vida. Recomendamos fortemente que você contate um serviço médico antes de sair. Deseja realmente voltar ao início?';

  @override
  String get emergencyExitConfirmStay => 'Permanecer na Emergência';

  @override
  String get emergencyExitConfirmLeave => 'Entendi os Riscos / Sair';

  @override
  String get emergencyFallbackTitle => 'Dispositivo sem Discador';

  @override
  String get emergencyFallbackBody =>
      'Este aparelho não suporta chamadas diretas. Disque manualmente para o número abaixo em outro telefone:';

  @override
  String get emergencyCopyNumber => 'Copiar Número';

  @override
  String get emergencyCopiedToast =>
      'Número copiado para a área de transferência.';

  @override
  String get triageBannerEmotional => 'Iniciando Autoavaliação Psico-Emocional';

  @override
  String get triageBannerPhysical => 'Iniciando Autoavaliação Física';

  @override
  String triageStep(int step, int total) {
    return 'Passo $step de $total';
  }

  @override
  String get triageNext => 'Próximo';

  @override
  String get triageBack => 'Voltar';

  @override
  String get triageConfirm => 'Confirmar';

  @override
  String get triagePreviewTitle => 'Revisão da sua Avaliação';

  @override
  String get triagePreviewSubmit => 'Confirmar e Finalizar';

  @override
  String get triageQ1Emotional =>
      'Olhando para o seu lado emocional e mental, qual palavra descreve melhor o que você está sentindo agora?';

  @override
  String get triageOptAnsiedade => 'Ansiedade / Agitação';

  @override
  String get triageOptTristeza => 'Tristeza / Desânimo';

  @override
  String get triageOptEstresse => 'Estresse / Irritabilidade';

  @override
  String get triageOptCansaco => 'Cansaço Mental';

  @override
  String get triageQ2Emotional =>
      'Você tem se sentido assim frequentemente nos últimos dias ou é algo muito específico de hoje?';

  @override
  String get triageOptComecouHoje => 'Começou hoje';

  @override
  String get triageOptJaFazDias => 'Já faz alguns dias';

  @override
  String get triageOptConstanteSemanas => 'É algo constante há semanas';

  @override
  String get triageQ3Emotional =>
      'Essa sensação está parecendo um leve incômodo de fundo ou algo forte que está acelerando seus pensamentos?';

  @override
  String get triageOptLeveControlavel => 'Leve e controlável';

  @override
  String get triageOptModerada => 'Moderada';

  @override
  String get triageOptMuitoForte => 'Muito forte e difícil de segurar';

  @override
  String get triageQ4Emotional =>
      'Você consegue identificar se existe um motivo principal para isso estar acontecendo hoje?';

  @override
  String get triageOptTrabalho => 'Trabalho / Estudos';

  @override
  String get triageOptFamilia => 'Família / Relacionamentos';

  @override
  String get triageOptNoiteRuim => 'Noite ruim de sono';

  @override
  String get triageOptNaoSei => 'Não sei dizer';

  @override
  String get triagePreviewEmotional =>
      'Revisão da sua Autoavaliação Psico-Emocional';

  @override
  String get triageQ1Physical =>
      'Vamos falar sobre a parte física. Onde você está sentindo esse desconforto ou dor principal?';

  @override
  String get triageOptCabeca => 'Cabeça';

  @override
  String get triageOptCostas => 'Costas / Coluna';

  @override
  String get triageOptArticulacoes => 'Articulações (Joelho, Ombro, etc.)';

  @override
  String get triageOptAbdomen => 'Abdômen / Estômago';

  @override
  String get triageQ2Physical =>
      'Há quanto tempo essa dor ou anomalia persiste?';

  @override
  String get triageOptComecouAgora => 'Começou agora';

  @override
  String get triageOptHaAlgunsDias => 'Há alguns dias';

  @override
  String get triageOptCronica => 'É crônica';

  @override
  String get triageQ3Physical =>
      'Em uma escala de 1 a 5 (onde 1 é quase imperceptível e 5 é insuportável), como está agora?';

  @override
  String get triageQ4Physical =>
      'Você lembra de ter feito algum esforço atípico, exercício pesado ou sofrido alguma batida/queda recentemente?';

  @override
  String get triageOptSimExercicio => 'Sim, exercício intenso';

  @override
  String get triageOptSimQueda => 'Sim, sofri uma queda';

  @override
  String get triageOptNaoComecouNada => 'Não, começou do nada';

  @override
  String get triagePreviewPhysical => 'Revisão da sua Avaliação Física';

  @override
  String triageIntensityLabel(int value) {
    return 'Intensidade: $value';
  }

  @override
  String get triageIntensityMin => 'Quase imperceptível';

  @override
  String get triageIntensityMax => 'Insuportável';

  @override
  String get outcomeScreenTitle => 'Resultado da Triagem';

  @override
  String get outcomeScreenSubtitle =>
      'Avaliação preventiva baseada nas suas respostas';

  @override
  String get outcomeIntensityTitle => 'Intensidade Calculada';

  @override
  String get outcomeIntensityDescription =>
      'Pontuação calculada na escala clínica de 1 a 5';

  @override
  String get outcomeDispositionTitle => 'Recomendação de Cuidado';

  @override
  String get outcomeDispositionSelfCare => 'Auto-cuidado Monitorado';

  @override
  String get outcomeDispositionSelfCareDesc =>
      'Repouso, hidratação adequada e acompanhamento dos sintomas nas próximas 24 horas.';

  @override
  String get outcomeDispositionRoutine => 'Consulta de Rotina';

  @override
  String get outcomeDispositionRoutineDesc =>
      'Agende uma consulta preventiva nos próximos dias com um profissional de saúde.';

  @override
  String get outcomeDispositionUrgent => 'Pronto Atendimento';

  @override
  String get outcomeDispositionUrgentDesc =>
      'Busque avaliação médica presencial em uma unidade de saúde em até 24 horas.';

  @override
  String get outcomeDispositionEmergency => 'Atendimento de Emergência';

  @override
  String get outcomeDispositionEmergencyDesc =>
      'Seus sintomas exigem atenção imediata. Procure um serviço de emergência ou ligue 192.';

  @override
  String get outcomeOrganicPrimacyTitle => 'Atenção: Primazia Orgânica';

  @override
  String get outcomeOrganicPrimacyDesc =>
      'Sintomas físicos concomitantes ao desconforto emocional requerem avaliação médica física prioritária antes de serem atribuídos unicamente ao estresse psicológico.';

  @override
  String get outcomeArticlesTitle => 'Artigos Médicos Recomendados';

  @override
  String get outcomeArticlesSubtitle =>
      'Conteúdos preventivos elaborados por especialistas renomados';

  @override
  String outcomeReadTime(int minutes) {
    return '$minutes min de leitura';
  }

  @override
  String get outcomeDoneButton => 'Concluir e Voltar ao Início';

  @override
  String get antiburlaTitle => 'Verificação Histórica';

  @override
  String antiburlaDialogPrompt(int days) {
    return 'Você registrou um sintoma similar há $days dias. É a mesma sensação que voltou ou algo totalmente novo?';
  }

  @override
  String get antiburlaOptionRecurring => 'É a mesma sensação que voltou';

  @override
  String get antiburlaOptionRecurringDesc =>
      'Ajustaremos o início para \'Há alguns dias\' para manter seu histórico clínico consistente.';

  @override
  String get antiburlaOptionNew => 'É um sentimento completamente novo';

  @override
  String get antiburlaOptionNewDesc =>
      'Manteremos registrado como um evento agudo que começou hoje.';

  @override
  String get antiburlaBiologicalDiscordanceTitle =>
      'Aviso Anatômico Preventivo';

  @override
  String get antiburlaBiologicalDiscordanceDesc =>
      'Notamos uma divergência entre a anatomia informada e os parâmetros do seu perfil. Deseja revisar antes de prosseguir?';

  @override
  String get offlineBannerText =>
      'Modo Offline — Seus check-ins serão salvos localmente e sincronizados automaticamente.';

  @override
  String offlineSyncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros pendentes de sincronização',
      one: '1 registro pendente de sincronização',
    );
    return '$_temp0';
  }

  @override
  String get offlineSyncSuccessText => 'Sincronização concluída com sucesso.';

  @override
  String get offlineModeNotice =>
      'Você está offline. Seu histórico e avaliação continuam funcionando normalmente.';

  @override
  String get historyScreenTitle => 'Histórico & Tendências';

  @override
  String get tabEmotional => 'Psico-Emocional';

  @override
  String get tabPhysical => 'Física';

  @override
  String get bodyMapTitle => 'Mapa Corporal 2D (14 Dias)';

  @override
  String get bodyMapHint => 'Toque em uma região para ver detalhes';

  @override
  String get heatLegendNone => 'Sem dor';

  @override
  String get heatLegendMild => 'Leve (1-2)';

  @override
  String get heatLegendModerate => 'Moderada (3)';

  @override
  String get heatLegendSevere => 'Intensa (4-5)';

  @override
  String get emotionalChartTitle => 'Evolução Emocional (7 Dias)';

  @override
  String get criticalRecurrenceTitle => 'Foco de Atenção';

  @override
  String get retrospectiveFeedTitle => 'Registros Anteriores';

  @override
  String get emptyHistoryTitle => 'Nenhum registro anterior';

  @override
  String get emptyHistorySubtitle =>
      'Seus check-ins diários concluídos aparecerão aqui.';

  @override
  String get readRecommendedArticle => 'Ler Artigo Recomendado';

  @override
  String get privacyCenterTitle => 'Privacidade & Dados (LGPD)';

  @override
  String get exportDataTitle => 'Exportação de Dados';

  @override
  String get exportDataDesc =>
      'Baixe uma cópia completa dos seus dados pessoais e histórico clínico em formato JSON conforme o Art. 18, V da LGPD.';

  @override
  String get exportDataButton => 'Exportar Dados (JSON)';

  @override
  String get exportSuccessMessage => 'Dados exportados com sucesso.';

  @override
  String get deleteAccountTitle => 'Exclusão Permanente da Conta';

  @override
  String get deleteAccountDesc =>
      'Apague definitivamente sua conta e todos os registros de saúde conforme o Art. 18 da LGPD. Esta ação não pode ser desfeita.';

  @override
  String get deleteAccountButton => 'Excluir Minha Conta';

  @override
  String get deleteConfirmTitle => 'Confirmar Exclusão Definitiva';

  @override
  String get deleteConfirmDesc =>
      'Para confirmar a exclusão irreversível da sua conta e de todos os dados de saúde, digite sua senha:';

  @override
  String get deleteSuccessMessage => 'Conta e dados excluídos com sucesso.';

  @override
  String get confirmPermanentDeletion => 'Confirmar Exclusão Irreversível';

  @override
  String get enterPassword => 'Senha de confirmação';

  @override
  String get previewDataTitle => 'Prévia dos Dados Exportados';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Fechar';
}
