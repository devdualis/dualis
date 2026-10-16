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
  String get valueCard1Title => 'Diário de Bem-Estar Integrado';

  @override
  String get valueCard1Body =>
      'Registre como você está no corpo e nas emoções em um único check-in diário de 1 minuto.';

  @override
  String get valueCard2Title => 'Seus Dados Protegidos';

  @override
  String get valueCard2Body =>
      'Seus registros de bem-estar ficam criptografados e sob seu controle, conforme a LGPD.';

  @override
  String get valueCard3Title => 'Conteúdos para Hábitos Saudáveis';

  @override
  String get valueCard3Body =>
      'Leituras curtas e gerais sobre sono, estresse, postura, hidratação e mais.';

  @override
  String get lgpdConsentCheckbox =>
      'Li e concordo com a Política de Privacidade e consinto, de forma específica e destacada, com o tratamento dos meus dados pessoais sensíveis de saúde para registrar e visualizar meu diário de bem-estar, nos termos do Art. 11, I da LGPD.';

  @override
  String get privacyVeilTitle => 'Dados de Saúde Protegidos';

  @override
  String get privacyVeilBody =>
      'Autentique-se com biometria ou senha para acessar seus registros.';

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
  String get emergencyTitle => 'Precisa de ajuda agora?';

  @override
  String get emergencySubtitle =>
      'Se você ou alguém perto de você estiver em perigo, ligue para a emergência. Não espere.';

  @override
  String get emergencyFindHospital => 'Buscar pronto-socorro mais próximo';

  @override
  String get emergencyDispatcherHint =>
      'Ao ligar, informe seu endereço com clareza e mantenha a calma.';

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
  String get triageBannerEmotional => 'Registro emocional de hoje';

  @override
  String get triageBannerPhysical => 'Registro físico de hoje';

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
  String get triagePreviewTitle => 'Revise seu registro';

  @override
  String get triagePreviewSubmit => 'Confirmar e Finalizar';

  @override
  String get triageQ1Emotional =>
      'Olhando para o seu lado emocional e mental, qual palavra descreve melhor o que você está sentindo agora?';

  @override
  String get triageOptNormal => 'Normal / Me sinto bem';

  @override
  String get triageSaveNormal => 'Concluir como Normal / Bem';

  @override
  String get triageOptAnsiedade => 'Ansiedade / Agitação';

  @override
  String get triageOptTristeza => 'Tristeza / Desânimo';

  @override
  String get triageOptEstresse => 'Estresse / Irritabilidade';

  @override
  String get triageOptCansaco => 'Cansaço Mental';

  @override
  String get triageOptAnsiosaAgitacao => 'Inquieto(a) / Agitado(a)';

  @override
  String get triageOptDepressivaDesanimo => 'Pra baixo / Desanimado(a)';

  @override
  String get triageOptEstresseBurnout => 'Estressado(a) / Esgotado(a)';

  @override
  String get triageOptSomatica => 'Tensão no corpo';

  @override
  String get triageOptSono => 'Sono ruim ou sono demais';

  @override
  String get triageOptCognitivaFoco => 'Dificuldade de foco';

  @override
  String get triageOptAutoestima => 'Autoestima / Autoimagem';

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
  String get triageQ4Ansiedade =>
      'O que parece estar disparando essa sensação de ansiedade, agitação ou aperto?';

  @override
  String get triageQ4Depressao =>
      'Você consegue identificar se algum acontecimento recente ou sentimento pesou mais no seu desânimo?';

  @override
  String get triageQ4EstresseBurnout =>
      'De onde vem a maior parte da pressão ou esgotamento que você está sentindo?';

  @override
  String get triageQ4Somatica =>
      'Essa tensão no corpo ou aperto físico costuma piorar em quais situações?';

  @override
  String get triageQ4Sono =>
      'Qual tem sido a principal dificuldade que atrapalha suas noites de sono?';

  @override
  String get triageQ4CognitivaFoco =>
      'O que mais parece estar prejudicando sua concentração ou clareza mental?';

  @override
  String get triageQ4Autoestima =>
      'O que tem despertado com mais intensidade essa sensação de insegurança ou autocrítica?';

  @override
  String get triageOptTrabalho => 'Trabalho / Estudos';

  @override
  String get triageOptFamilia => 'Família / Relacionamentos';

  @override
  String get triageOptNoiteRuim => 'Noite ruim de sono';

  @override
  String get triageOptNaoSei => 'Não sei dizer';

  @override
  String get triageOptSimCobrancaPrazos =>
      'Sobrecarga de tarefas, prazos ou expectativas';

  @override
  String get triageOptSimConflitoRelacionamento =>
      'Conflito ou discussão com pessoa próxima';

  @override
  String get triageOptSimIncertezaFuturo =>
      'Medo de mudanças, notícias ou incerteza futura';

  @override
  String get triageOptSimExcessoEstimulantes =>
      'Excesso de café, energéticos ou ambiente agitado';

  @override
  String get triageOptNaoSeiDizerEmocional =>
      'Não sei identificar, surgiu de repente';

  @override
  String get triageOptSimPerdaLuto =>
      'Perda, término de relacionamento ou luto';

  @override
  String get triageOptSimSolidaoIsolamento =>
      'Sensação de solidão, isolamento ou incompreensão';

  @override
  String get triageOptSimFrustracaoDesilusao =>
      'Frustração com algo que não saiu como esperado';

  @override
  String get triageOptSimCansacoAcumulado =>
      'Cansaço prolongado sem pausas para recuperação';

  @override
  String get triageOptSimPressaoTrabalho =>
      'Excesso de carga horária, cobranças ou prazos no trabalho';

  @override
  String get triageOptSimResponsabilidadesCasa =>
      'Cuidados familiares, finanças ou tarefas domésticas';

  @override
  String get triageOptSimFaltaDescanso =>
      'Sem tempo livre para lazer, repouso ou desconectar';

  @override
  String get triageOptSimAmbienteToxico =>
      'Relações difíceis ou ambiente diário desgastante';

  @override
  String get triageOptSimDuranteTrabalho =>
      'Durante a jornada de trabalho ou momentos de pressão';

  @override
  String get triageOptSimDiscussaoConflito =>
      'Logo após discussões, desentendimentos ou sustos';

  @override
  String get triageOptSimFinalDoDia =>
      'No fim do dia, ao tentar relaxar ou deitar';

  @override
  String get triageOptSimPreocupacaoConstante =>
      'Em qualquer momento ao pensar nos problemas';

  @override
  String get triageOptSimDificuldadePegarSono =>
      'Cabeça acelerada / pensamentos na hora de dormir';

  @override
  String get triageOptSimAcordaMadrugada =>
      'Acordar no meio da noite e não conseguir voltar a dormir';

  @override
  String get triageOptSimSonoAgitadoPesadelos =>
      'Sono leve, agitado, com pesadelos ou despertares';

  @override
  String get triageOptSimHorarioIrregularTelas =>
      'Uso de celular/telas até tarde ou horários irregulares';

  @override
  String get triageOptSimSobrecargaMultitarefas =>
      'Muitas coisas para fazer ao mesmo tempo / excesso de estímulos';

  @override
  String get triageOptSimPreocupacaoIntrusiva =>
      'Pensamentos de preocupação que interrompem o raciocínio';

  @override
  String get triageOptSimExaustaoMental =>
      'Cansaço mental acumulado após muitas horas de esforço';

  @override
  String get triageOptSimFaltaMotivacao =>
      'Desinteresse, falta de energia ou apatia com as tarefas';

  @override
  String get triageOptSimComparacaoRedes =>
      'Comparação com outras pessoas (redes sociais ou colegas)';

  @override
  String get triageOptSimMedoFalharJulgamento =>
      'Medo de errar, não corresponder ou ser julgado';

  @override
  String get triageOptSimCriticaRejeicao =>
      'Crítica recente recebida ou sensação de rejeição';

  @override
  String get triageOptSimDesvalorizacaoPropria =>
      'Dificuldade em reconhecer suas próprias conquistas';

  @override
  String get triagePreviewEmotional => 'Revise seu registro';

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
  String get triageOptCabecaPescoco => 'Cabeça e pescoço';

  @override
  String get triageOptCardiovascularTorax => 'Peito';

  @override
  String get triageOptRespiratorio => 'Respiração';

  @override
  String get triageOptGastrointestinalAbdomen => 'Barriga';

  @override
  String get triageOptColunaDorDorsal => 'Costas';

  @override
  String get triageOptMembrosSuperiores => 'Braços';

  @override
  String get triageOptMembrosInferiores => 'Pernas';

  @override
  String get triageOptNeurologico => 'Tontura / formigamento';

  @override
  String get triageOptGeniturinarioPelvico => 'Região íntima / urinária';

  @override
  String get triageOptDermatologico => 'Pele';

  @override
  String get triageOptMuscularGeralSistemico => 'Corpo todo / cansaço';

  @override
  String get triageOptEndocrinoMetabolico => 'Sede, fome ou energia';

  @override
  String get triageQ2Physical => 'Há quanto tempo você sente esse desconforto?';

  @override
  String get triageOptComecouAgora => 'Começou agora';

  @override
  String get triageOptHaAlgunsDias => 'Há alguns dias';

  @override
  String get triageOptCronica => 'Já faz bastante tempo';

  @override
  String get triageQ3Physical =>
      'Em uma escala de 1 a 5 (onde 1 é quase imperceptível e 5 é insuportável), como está agora?';

  @override
  String get triageQ4Physical =>
      'Você lembra de ter feito algum esforço atípico, exercício pesado ou sofrido alguma batida/queda recentemente?';

  @override
  String get triageQ4CabecaPescoco =>
      'Você notou algum fator associado, como estresse intenso, muitas horas em telas, noite mal dormida ou sinusite/resfriado?';

  @override
  String get triageQ4CardiovascularTorax =>
      'O desconforto no peito ou palpitação começou após esforço físico, estresse emocional ou consumo de estimulantes?';

  @override
  String get triageQ4Respiratorio =>
      'Você teve contato com poeira, fumaça, ar frio ou está com sintomas de gripe/resfriado?';

  @override
  String get triageQ4Gastrointestinal =>
      'Você ingeriu algum alimento diferente ou pesado, tomou remédios recentes ou ficou muito tempo em jejum?';

  @override
  String get triageQ4ColunaDorDorsal =>
      'Você carregou peso excessivo, permaneceu muito tempo em má postura ou sofreu algum impacto/queda?';

  @override
  String get triageQ4MembrosSuperiores =>
      'Você realizou movimentos repetitivos (digitação, esforço manual), treino de braço/ombro ou sofreu impacto/queda?';

  @override
  String get triageQ4MembrosInferiores =>
      'Você fez caminhada longa, corrida, ficou muito tempo em pé/sentado ou sofreu torção/tropeço?';

  @override
  String get triageQ4Neurologico =>
      'O sintoma surgiu após levantar-se rápido, ficar sem comer/beber água, crise de ansiedade ou posição desconfortável?';

  @override
  String get triageQ4Geniturinario =>
      'Você percebeu relação com pouca água/reter urina, ciclo menstrual, relação íntima ou uso de roupas úmidas?';

  @override
  String get triageQ4Dermatological =>
      'Você notou algo que possa ter causado isso, como um produto novo, exposição ao sol/calor ou contato com algo (planta, inseto, substância)?';

  @override
  String get triageQ4MuscularGeral =>
      'Você sente isso associado a cansaço extremo, início de gripe/virose, falta de descanso ou desidratação?';

  @override
  String get triageQ4EndocrinoMetabolico =>
      'Você notou relação com jejum prolongado, refeição açucarada, alteração de medicamento ou calor excessivo?';

  @override
  String get triageOptSimExercicio => 'Sim, exercício intenso';

  @override
  String get triageOptSimQueda => 'Sim, sofri uma queda';

  @override
  String get triageOptNaoComecouNada => 'Não, começou do nada';

  @override
  String get triageOptSimProdutoNovo =>
      'Sim, usei um produto novo (cosmético, sabonete, etc.)';

  @override
  String get triageOptSimExposicaoSolCalor =>
      'Sim, houve exposição ao sol, calor ou suor intenso';

  @override
  String get triageOptSimPicadaContato =>
      'Sim, tive contato com planta, inseto ou substância';

  @override
  String get triageOptSimEstresseSono => 'Estresse ou sono irregular';

  @override
  String get triageOptSimTelasEsforcoVisual =>
      'Muitas horas em telas / esforço visual';

  @override
  String get triageOptSimPosturaPescoco =>
      'Tensão muscular ou má postura no pescoço';

  @override
  String get triageOptSimResfriadoSinusite =>
      'Sintomas de resfriado ou sinusite';

  @override
  String get triageOptSimEsforcoFisico =>
      'Logo após esforço físico ou caminhada';

  @override
  String get triageOptSimEstresseAnsiedade =>
      'Momento de forte ansiedade ou estresse';

  @override
  String get triageOptSimCafeinaEstimulante =>
      'Consumo de café, energético ou estimulante';

  @override
  String get triageOptNaoSurgiuEmRepouso =>
      'Não, surgiu espontaneamente ou em repouso';

  @override
  String get triageOptSimAlergiaAmbiente =>
      'Exposição a poeira, mofo, fumaça ou ar-condicionado';

  @override
  String get triageOptSimGripeInfeccao =>
      'Sintomas de gripe, resfriado ou dor de garganta';

  @override
  String get triageOptSimMudancaClima =>
      'Mudança brusca de temperatura ou ar frio';

  @override
  String get triageOptSimAlimentacaoDiferente =>
      'Alimento diferente, pesado ou suspeito';

  @override
  String get triageOptSimMedicamentoRecente =>
      'Uso recente de medicamento ou anti-inflamatório';

  @override
  String get triageOptSimJejumEstresse =>
      'Longo período de jejum ou estresse intenso';

  @override
  String get triageOptNaoSemRelacaoAlimento =>
      'Não, começou sem relação com alimentação';

  @override
  String get triageOptSimCarregouPeso => 'Pegou peso ou fez esforço lombar';

  @override
  String get triageOptSimPosturaProlongada =>
      'Muito tempo sentado ou má postura ao dormir';

  @override
  String get triageOptSimMauJeitoQueda =>
      'Movimento brusco (\'mau jeito\') ou impacto/queda';

  @override
  String get triageOptSimMovimentoRepetitivo =>
      'Movimentos repetitivos (digitação, celular, trabalho manual)';

  @override
  String get triageOptSimTreinoSobrecarga =>
      'Exercício físico ou sobrecarga nos braços/ombros';

  @override
  String get triageOptSimTraumaPancada =>
      'Pancada, queda ou dormiu de mau jeito sobre o braço';

  @override
  String get triageOptSimCaminhadaCorrida =>
      'Caminhada longa, corrida ou esporte recente';

  @override
  String get triageOptSimTempoEmPeSentado =>
      'Muitas horas em pé ou muito tempo sentado';

  @override
  String get triageOptSimTorcaoTropeco =>
      'Torção no tornozelo/joelho, tropeço ou queda';

  @override
  String get triageOptSimLevantarRapido =>
      'Ao levantar-se rapidamente ou mudar de posição';

  @override
  String get triageOptSimJejumDesidratacao =>
      'Horas sem se alimentar ou pouca ingestão de água';

  @override
  String get triageOptSimAnsiedadeHiperventilacao =>
      'Durante momento de tensão ou respiração acelerada';

  @override
  String get triageOptSimCompressaoPostural =>
      'Membro pressionado ou postura comprimindo nervo';

  @override
  String get triageOptSimBaixaIngestaoUrina =>
      'Pouca ingestão de água ou segurou urina por muito tempo';

  @override
  String get triageOptSimCicloMenstrual => 'Período pré-menstrual ou menstrual';

  @override
  String get triageOptSimPosRelacaoIntima =>
      'Após relação íntima ou troca de produtos íntimos';

  @override
  String get triageOptSimRoupasUmidas =>
      'Uso de roupas úmidas ou muito apertadas';

  @override
  String get triageOptSimCansacoEsgotamento =>
      'Cansaço extremo, sobrecarga ou noites sem dormir';

  @override
  String get triageOptSimSintomasGripeVirose =>
      'Sensação de febre, calafrio ou início de virose';

  @override
  String get triageOptSimAtividadeGlobal =>
      'Atividade física atípica (mudança, faxina pesada)';

  @override
  String get triageOptSimDesidratacaoCalor =>
      'Pouca hidratação ou exposição prolongada ao calor';

  @override
  String get triageOptSimJejumAlimentacao =>
      'Horas sem comer ou após refeição pesada/açucarada';

  @override
  String get triageOptSimAjusteMedicamento =>
      'Esqueceu ou alterou dose de medicamento habitual';

  @override
  String get triageOptSimCalorDesidratacao =>
      'Ambiente muito quente ou baixa ingestão de líquidos';

  @override
  String get triageOptSimEstresseSobrecarga =>
      'Pico recente de estresse ou quebra de rotina';

  @override
  String get triagePreviewPhysical => 'Revise seu registro';

  @override
  String triageIntensityLabel(int value) {
    return 'Intensidade: $value';
  }

  @override
  String get triageIntensityMin => 'Quase imperceptível';

  @override
  String get triageIntensityMax => 'Insuportável';

  @override
  String get outcomeScreenTitle => 'Resumo do seu registro';

  @override
  String get outcomeScreenSubtitle => 'Um retrato do que você registrou hoje';

  @override
  String get outcomeIntensityTitle => 'Intensidade que você informou';

  @override
  String get outcomeIntensityDescription =>
      'Sua própria nota de 1 a 5 para como se sentiu';

  @override
  String get outcomeArticlesTitle => 'Leituras sobre bem-estar';

  @override
  String get outcomeArticlesSubtitle =>
      'Conteúdos educativos gerais. Não são orientação para o seu caso.';

  @override
  String outcomeReadTime(int minutes) {
    return '$minutes min de leitura';
  }

  @override
  String get outcomeDoneButton => 'Concluir e Voltar ao Início';

  @override
  String get antiburlaTitle => 'Isso já apareceu antes?';

  @override
  String antiburlaDialogPrompt(int days) {
    return 'Você registrou um sintoma similar há $days dias. É a mesma sensação que voltou ou algo totalmente novo?';
  }

  @override
  String get antiburlaOptionRecurring => 'É a mesma sensação que voltou';

  @override
  String get antiburlaOptionRecurringDesc =>
      'Vamos registrar como algo que voltou, para seu diário ficar organizado.';

  @override
  String get antiburlaOptionNew => 'É um sentimento completamente novo';

  @override
  String get antiburlaOptionNewDesc =>
      'Manteremos registrado como um evento agudo que começou hoje.';

  @override
  String get offTopicNarrativeTitle => 'Isso parece um sintoma?';

  @override
  String get offTopicNarrativeDesc =>
      'O texto que você escreveu não parece descrever um sintoma físico ou emocional. Deseja revisar sua descrição ou continuar mesmo assim?';

  @override
  String get offTopicNarrativeEditButton => 'Editar Descrição';

  @override
  String get offTopicNarrativeContinueButton => 'Continuar Mesmo Assim';

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
      'Você está offline. Seus registros continuam funcionando normalmente.';

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
  String get heatLegendNone => 'Sem registro';

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
  String get readRecommendedArticle => 'Ler artigo';

  @override
  String get privacyCenterTitle => 'Privacidade & Dados (LGPD)';

  @override
  String get exportDataTitle => 'Exportação de Dados';

  @override
  String get exportDataDesc =>
      'Baixe uma cópia completa dos seus dados pessoais e registros de bem-estar em formato JSON conforme o Art. 18, V da LGPD.';

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

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get profileSection => 'Perfil e Identificação';

  @override
  String get changeAvatar => 'Alterar Foto';

  @override
  String get selectAvatar => 'Escolha seu Avatar';

  @override
  String get nameLabel => 'Nome Completo';

  @override
  String get dateOfBirthLabel => 'Data de Nascimento';

  @override
  String get ageLabel => 'Idade';

  @override
  String yearsOld(int age) {
    return '$age anos';
  }

  @override
  String get saveProfile => 'Salvar Alterações';

  @override
  String get profileUpdatedSuccess => 'Perfil atualizado com sucesso!';

  @override
  String get securitySection => 'Segurança e Acesso';

  @override
  String get changePassword => 'Alterar Senha';

  @override
  String get currentPassword => 'Senha Atual';

  @override
  String get newPassword => 'Nova Senha';

  @override
  String get confirmNewPassword => 'Confirmar Nova Senha';

  @override
  String get currentPasswordHint => 'Digite sua senha atual';

  @override
  String get newPasswordHint => 'Nova senha segura';

  @override
  String get confirmPasswordHint => 'Repita a nova senha';

  @override
  String get passwordChangedSuccess => 'Senha alterada com sucesso!';

  @override
  String get passwordsDoNotMatch => 'As novas senhas não coincidem.';

  @override
  String get passwordComplexityHint =>
      'Mínimo de 8 caracteres, com letra maiúscula, minúscula, número e símbolo.';

  @override
  String get privacyShortcut => 'Central de Privacidade e LGPD';

  @override
  String get logoutButton => 'Sair da Conta';

  @override
  String get settingsLanguageSection => 'Idioma do Aplicativo';

  @override
  String get settingsLanguagePortuguese => 'Português (Brasil)';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsPrivacySection => 'Privacidade e Dados';

  @override
  String get settingsPrivacyCenterTile => 'Central de Privacidade e LGPD';

  @override
  String get settingsPrivacyCenterSubtitle =>
      'Acesse e gerencie seus dados de saúde';

  @override
  String get settingsDataHistoryTile => 'Histórico e Tendências';

  @override
  String get settingsDataHistorySubtitle =>
      'Visualize seu histórico de registros';

  @override
  String get deleteHistoryItemTitle => 'Descartar registro do histórico';

  @override
  String get deleteHistoryItemConfirm =>
      'Tem certeza de que deseja descartar este registro do seu histórico? Esta ação é irreversível.';

  @override
  String get deleteHistoryItemSuccess => 'Registro removido com sucesso.';

  @override
  String get deleteHistoryItemError => 'Não foi possível remover o registro.';

  @override
  String get deleteAction => 'Descartar';

  @override
  String get errorNetworkConnection =>
      'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.';

  @override
  String get errorConnectionTimeout =>
      'A comunicação com o servidor demorou muito. Tente novamente.';

  @override
  String get errorInvalidCredentials =>
      'E-mail ou senha incorretos. Por favor, verifique suas credenciais.';

  @override
  String get errorEmailAlreadyExists =>
      'Este e-mail já está cadastrado em nossa plataforma.';

  @override
  String get errorSessionExpired =>
      'Sua sessão expirou. Por favor, acesse novamente.';

  @override
  String get errorEmailVerificationCodeInvalid =>
      'Código de verificação incorreto ou expirado. Verifique os dígitos ou solicite um novo código.';

  @override
  String get emailVerificationSuccess =>
      'E-mail verificado com sucesso! Bem-vindo ao DualisCheckUp.';

  @override
  String get newCodeSentSuccess => 'Novo código enviado para seu e-mail.';

  @override
  String get errorUpdateProfile =>
      'Não foi possível atualizar o perfil. Tente novamente.';

  @override
  String get errorChangePassword =>
      'Não foi possível alterar a senha. Verifique sua senha atual.';

  @override
  String get errorCameraGalleryAccess =>
      'Não foi possível acessar a câmera ou galeria do dispositivo.';

  @override
  String get errorFieldRequired => 'Este campo é obrigatório.';

  @override
  String get errorCurrentPasswordRequired => 'Informe sua senha atual.';

  @override
  String get errorNewPasswordMinLength =>
      'A nova senha deve ter pelo menos 8 caracteres.';

  @override
  String get errorPasswordLettersAndDigits =>
      'A senha deve conter letras e números.';

  @override
  String get errorNameMinLength => 'Nome deve ter pelo menos 2 caracteres.';

  @override
  String get selectDateOfBirthHint => 'Selecione sua data de nascimento';

  @override
  String get errorLoadHistory =>
      'Não foi possível carregar o histórico de registros no momento.';

  @override
  String get errorArticleLinkUnavailable => 'Link do artigo não disponível.';

  @override
  String get errorUnableToOpenLink =>
      'Não foi possível abrir o link solicitado.';

  @override
  String get errorServerInternal =>
      'Nossos serviços estão passando por uma instabilidade temporária. Tente novamente em instantes.';

  @override
  String get errorUnexpected =>
      'Ocorreu uma instabilidade inesperada. Por favor, tente novamente.';

  @override
  String get navHome => 'Início';

  @override
  String get navTodayOutcome => 'Meu Dia';

  @override
  String get navHistory => 'Histórico & Mapa';

  @override
  String get navHydration => 'Água';

  @override
  String get notifWaterTitle => '💧 Hora de Beber Água';

  @override
  String notifWaterTitleAt(String time) {
    return '💧 Hora de Beber Água ($time)';
  }

  @override
  String get notifWaterBodyTracking =>
      'Toque para registrar a quantidade de água consumida.';

  @override
  String get notifWaterBodyReminder =>
      'Mantenha seu corpo hidratado e saudável!';

  @override
  String get notifWaterChimeChannelName => 'Lembretes de Água (Aviso Suave)';

  @override
  String get notifWaterChimeChannelDescription =>
      'Aviso de chegada estilo mensagem para lembrete de hidratação';

  @override
  String get notifWaterAlarmChannelName => 'Lembretes de Água (Alarme Sonoro)';

  @override
  String get notifWaterAlarmChannelDescription =>
      'Alarme sonoro para lembrar de beber água a cada 2 horas';

  @override
  String notifCheckinTitleAt(String time) {
    return '🌿 Check-in Diário Dualis ($time)';
  }

  @override
  String get notifCheckinBody =>
      'Você ainda não fez seu registro de hoje. Toque para fazer seu check-in!';

  @override
  String get notifCheckinChannelName => 'Lembretes de Check-in Diário';

  @override
  String get notifCheckinChannelDescription =>
      'Notificações a cada 2 horas para lembrar do seu check-in diário de bem-estar';

  @override
  String get outcomeAxisPhysicalNumbered => '1. Eixo Avaliação Física';

  @override
  String get outcomeAxisEmotionalNumbered =>
      '2. Eixo Avaliação Psico-emocional';

  @override
  String get familySharingTitle => 'Compartilhamento Familiar';

  @override
  String get familySharingTabOutgoing => 'Quem acessa meus dados';

  @override
  String get familySharingTabIncoming => 'Dados compartilhados comigo';

  @override
  String get familySharingUnavailableTitle => 'Recurso ainda não disponível';

  @override
  String get familySharingUnavailableBody =>
      'O compartilhamento familiar chegará em uma próxima versão do DualisCheckUp.';

  @override
  String get familySharingInviteButton => 'Convidar Familiar ou Acompanhante';

  @override
  String get familySharingEnterCodeButton =>
      'Possui um código de convite? Inserir e Aceitar';

  @override
  String get familySharingEmptyOutgoing =>
      'Ninguém tem acesso aos seus dados no momento.';

  @override
  String get familySharingEmptyIncoming =>
      'Nenhum familiar compartilhou dados com você ainda.';

  @override
  String get familySharingScopeViewOnly => 'Somente Leitura';

  @override
  String get familySharingScopeCoManage => 'Co-gestão';

  @override
  String get familySharingScopeViewOnlyOption =>
      'Somente Leitura (Recomendado)';

  @override
  String get familySharingScopeCoManageOption =>
      'Co-gestão (Pode adicionar registros)';

  @override
  String familySharingActiveSince(String date) {
    return 'Ativo desde $date';
  }

  @override
  String get familySharingActive => 'Acesso ativo';

  @override
  String familySharingPendingUntil(String code, String date) {
    return 'Código $code · aguardando aceite até $date';
  }

  @override
  String get familySharingExpired => 'Convite expirado';

  @override
  String get familySharingRevokeButton => 'Revogar Acesso';

  @override
  String get familySharingRevokeConfirmTitle => 'Revogar acesso?';

  @override
  String get familySharingRevokeConfirmBody =>
      'Tem certeza? O acesso será interrompido imediatamente.';

  @override
  String get familySharingCancel => 'Cancelar';

  @override
  String get familySharingRevoked => 'Acesso revogado.';

  @override
  String get familySharingRevokeError =>
      'Não foi possível revogar o acesso. Tente novamente.';

  @override
  String get familySharingInviteTitle => 'Convidar Familiar ou Acompanhante';

  @override
  String get familySharingInviteProfileLabel => 'Perfil a compartilhar';

  @override
  String get familySharingInviteScopeLabel => 'Permissão';

  @override
  String get familySharingInviteGenerate => 'Gerar Código';

  @override
  String get familySharingInviteError =>
      'Não foi possível gerar o convite. Tente novamente.';

  @override
  String get familySharingInviteCodeHint =>
      'Envie este código para o familiar. Ele expira em 72 horas.';

  @override
  String familySharingInviteDeadline(String date) {
    return 'Válido até $date';
  }

  @override
  String get familySharingCopyCode => 'Copiar Código';

  @override
  String get familySharingCodeCopied => 'Código copiado.';

  @override
  String get familySharingDone => 'Concluir';

  @override
  String get familySharingAcceptTitle => 'Inserir código de convite';

  @override
  String get familySharingAcceptFieldLabel => 'Código de 6 caracteres';

  @override
  String get familySharingAcceptSubmit => 'Aceitar Convite';

  @override
  String get familySharingAcceptError => 'Código inválido ou expirado.';

  @override
  String get familySharingAccepted =>
      'Convite aceito. O perfil já aparece na sua lista.';

  @override
  String get addDependentTitle => 'Cadastrar Dependente Legal';

  @override
  String get addDependentNameLabel => 'Nome Completo do Dependente';

  @override
  String get addDependentDobLabel => 'Data de Nascimento';

  @override
  String get addDependentDobHint => 'Toque para selecionar';

  @override
  String get addDependentDobPickerHelp => 'Selecione a data de nascimento';

  @override
  String get addDependentDobInvalid => 'Informe uma data de nascimento válida.';

  @override
  String get addDependentDobFuture =>
      'A data de nascimento não pode estar no futuro.';

  @override
  String get addDependentRelationshipLabel =>
      'Grau de Parentesco / Representação';

  @override
  String get addDependentRelationshipHint => 'Selecione o vínculo legal';

  @override
  String get addDependentRelationshipParent =>
      'Filho(a) menor de idade (Poder Familiar)';

  @override
  String get addDependentRelationshipCurator =>
      'Curador(a) de maior incapaz (Curatela)';

  @override
  String get addDependentRelationshipLegalGuardian =>
      'Tutor(a) legal de menor (Tutela)';

  @override
  String get addDependentLgpdArt14Consent =>
      'Declaro, sob as penas da lei, que sou pai, mãe ou representante legal deste dependente e autorizo expressamente a coleta e tratamento dos seus dados de bem-estar na plataforma DualisCheckUp, em estrita conformidade com o Artigo 14 da LGPD (Lei 13.709/2018).';

  @override
  String get addDependentSubmit => 'Cadastrar Dependente';

  @override
  String get addDependentSuccess => 'Dependente cadastrado com sucesso.';

  @override
  String get addDependentGenericError =>
      'Não foi possível cadastrar o dependente. Tente novamente.';

  @override
  String get profileSwitcherSheetTitle => 'Perfis';

  @override
  String get profileSwitcherMyProfile => 'Meu Perfil';

  @override
  String get profileSwitcherDependents => 'Meus Dependentes (Permissão Legal)';

  @override
  String get profileSwitcherShared => 'Perfis Compartilhados (Opcional)';

  @override
  String get profileSwitcherAddDependent => '+ Adicionar Dependente (Legal)';

  @override
  String get profileSwitcherManageSharing =>
      'Gerenciar Compartilhamento Familiar';

  @override
  String get profileSwitcherRenameTitle => 'Renomear Perfil';

  @override
  String get profileSwitcherRenameLabel => 'Nome do perfil';

  @override
  String get profileSwitcherRenameSave => 'Salvar';

  @override
  String get profileSwitcherRenameCancel => 'Cancelar';

  @override
  String get profileSwitcherDeleteTitle => 'Excluir Perfil?';

  @override
  String profileSwitcherDeleteConfirm(String name) {
    return 'Tem certeza que deseja excluir o perfil \"$name\"? Esta ação não pode ser desfeita.';
  }

  @override
  String get profileSwitcherDeleteAction => 'Excluir';

  @override
  String get profileSwitcherClose => 'Fechar';

  @override
  String get profileSwitcherBadgeMinor => 'Menor de idade';

  @override
  String get profileSwitcherBadgeAdult => 'Maior sob tutela';

  @override
  String get profileSwitcherBadgeViewOnly => 'Somente leitura';

  @override
  String get profileSwitcherBadgeCoManage => 'Co-gestão';

  @override
  String get profileSwitcherBadgePrimary => 'Titular';

  @override
  String get profileSwitcherNoDependents => 'Nenhum dependente cadastrado.';

  @override
  String get profileSwitcherNoShared => 'Nenhum perfil compartilhado com você.';

  @override
  String get profileSwitcherActionError =>
      'Não foi possível concluir a ação. Tente novamente.';

  @override
  String get familySharingCancelInvite => 'Cancelar Convite';

  @override
  String activeProfileBannerDataOf(String profileName) {
    return 'Exibindo dados de $profileName';
  }

  @override
  String get activeProfileBannerSwitchToMine => 'Meu perfil';

  @override
  String get activeProfileReadOnlyNote => 'Somente leitura';

  @override
  String activeProfileCardTitle(String profileName) {
    return 'Perfil de $profileName';
  }

  @override
  String get emergencyMapsQuery => 'pronto-socorro';

  @override
  String get safetyClose => 'Fechar';

  @override
  String safetyCallLine(String name, String number) {
    return 'Ligar $name ($number)';
  }

  @override
  String get safetyKindEmergency => 'Emergência';

  @override
  String get safetyKindAmbulance => 'Ambulância';

  @override
  String get safetyKindFire => 'Bombeiros';

  @override
  String get safetyKindPolice => 'Polícia';

  @override
  String get safetyKindEmotionalSupport => 'Apoio emocional';

  @override
  String get safetyKindHealthLine => 'Linha de saúde';

  @override
  String get safetyFree24h => '24h, gratuito';

  @override
  String safetyWarningSignsTitle(String number) {
    return 'Ligue $number imediatamente se você ou alguém tiver:';
  }

  @override
  String get safetyWarningSign1 => 'dor ou pressão forte no peito';

  @override
  String get safetyWarningSign2 => 'falta de ar intensa';

  @override
  String get safetyWarningSign3 =>
      'rosto torto, fraqueza num lado do corpo ou fala enrolada';

  @override
  String get safetyWarningSign4 =>
      'a pior dor de cabeça da vida, de início súbito';

  @override
  String get safetyWarningSign5 => 'desmaio ou convulsão';

  @override
  String get safetyWarningSign6 => 'sangramento que não para';

  @override
  String get safetyWarningSignsSource => 'Fonte: Ministério da Saúde / SAMU';

  @override
  String safetyCrisisWithLine(String crisis, String emergency) {
    return 'Se você está pensando em se machucar ou em tirar a própria vida, ligue $crisis ou $emergency.';
  }

  @override
  String safetyCrisisNoLine(String emergency) {
    return 'Se você está pensando em se machucar ou em tirar a própria vida, ligue $emergency ou procure a linha de apoio emocional do seu país.';
  }

  @override
  String safetyLocalNumberHint(String number) {
    return 'Se o $number não funcionar onde você está, ligue para o número local de emergência.';
  }

  @override
  String safetyNoticeGeneral(String number) {
    return 'Se isso for uma emergência, não use o app: ligue $number agora.';
  }

  @override
  String get safetyNoticeOpenResources => 'Ver contatos de ajuda';

  @override
  String get urgentHelpButton => 'Ajuda urgente';

  @override
  String get lgpdConsentPrefix => 'Li e concordo com os ';

  @override
  String get lgpdConsentTermsLink => 'Termos de Uso';

  @override
  String get lgpdConsentAnd => ' e a ';

  @override
  String get lgpdConsentPrivacyLink => 'Política de Privacidade';

  @override
  String get lgpdConsentSuffix =>
      ', e consinto, de forma específica e destacada, com o tratamento dos meus dados pessoais sensíveis de saúde para registrar e visualizar meu diário de bem-estar, nos termos do Art. 11, I da LGPD. ';

  @override
  String get lgpdConsentLearnMore => '(Saiba mais)';

  @override
  String get lgpdConsentSheetTitle =>
      'Política de Privacidade e Termo de Consentimento (LGPD Art. 11, I)';

  @override
  String get lgpdConsentSheetBody =>
      'O DualisCheckUp é um aplicativo de bem-estar e autoconhecimento. Ele ajuda você a registrar diariamente como se sente física e emocionalmente, acompanhar hábitos como hidratação e sono, visualizar seus próprios registros ao longo do tempo e acessar conteúdos educativos gerais sobre hábitos saudáveis. O DualisCheckUp não é um dispositivo médico: não avalia, não classifica nem interpreta sintomas, não indica nível de urgência, não faz diagnóstico, não recomenda tratamento e não substitui um profissional de saúde. Em caso de emergência, ligue 192 (SAMU). Se você estiver em sofrimento emocional, ligue 188 (CVV).';

  @override
  String get lgpdConsentSheetBasesTitle => 'Bases normativas:';

  @override
  String get lgpdConsentSheetBases =>
      '• Lei nº 13.709/2018 (LGPD): Art. 7 e Art. 11 (tratamento de dados pessoais e de dados sensíveis de saúde), Art. 14 (dados de crianças e adolescentes) e Art. 18 (direitos do titular).\n• Código de Defesa do Consumidor (CDC): Art. 49 - Direito de Arrependimento em 7 dias.';

  @override
  String get lgpdConsentViewTerms => 'Ver Termos de Uso';

  @override
  String get lgpdConsentViewPolicy => 'Ver Política Completa';

  @override
  String get termsAppBarTitle => 'Termos de Uso do SaaS';

  @override
  String get termsHeaderTitle => 'Termos e Condições de Uso';

  @override
  String get termsVersionLine => 'Versão 2026.2 • Atualizado em 16/10/2026';

  @override
  String get termsIntro =>
      'Contrato de prestação de serviços de software em nuvem (SaaS) celebrado entre o Usuário e a DualisCheckUp Saúde e Tecnologia Ltda., inscrita no CNPJ sob o nº 48.291.834/0001-92, com sede em São Paulo/SP, Brasil.';

  @override
  String get termsSection1Title => '1. Aceitação e Capacidade Civil';

  @override
  String get termsSection1Body =>
      'Ao cadastrar-se ou utilizar o DualisCheckUp, você declara possuir capacidade civil plena (maior de 18 anos ou emancipado) e manifesta concordância integral com estes Termos de Uso e com nossa Política de Privacidade.';

  @override
  String get termsSection2Title => '2. Natureza do Serviço';

  @override
  String get termsSection2Body =>
      'O DualisCheckUp é um aplicativo de bem-estar e autoconhecimento. Ele ajuda você a registrar diariamente como se sente física e emocionalmente, acompanhar hábitos como hidratação e sono, visualizar seus próprios registros ao longo do tempo e acessar conteúdos educativos gerais sobre hábitos saudáveis. O DualisCheckUp não é um dispositivo médico: não avalia, não classifica nem interpreta sintomas, não indica nível de urgência, não faz diagnóstico, não recomenda tratamento e não substitui um profissional de saúde. Em caso de emergência, ligue 192 (SAMU). Se você estiver em sofrimento emocional, ligue 188 (CVV).';

  @override
  String get termsSection2Bullet1 =>
      'Não avalia sintomas, não indica urgência, não diagnostica e não recomenda tratamento.';

  @override
  String get termsSection2Bullet2 =>
      'As intensidades e demais informações exibidas são as que você mesmo registrou.';

  @override
  String get termsSection2Bullet3 =>
      'Em emergência, ligue 192 (SAMU) ou 188 (CVV).';

  @override
  String get termsSection3Title => '3. Planos SaaS, Cobrança e Reembolso';

  @override
  String get termsSection3Body =>
      'Recursos adicionais podem ser oferecidos em planos com renovação automática periódica, processados por intermediadores de pagamento terceiros:';

  @override
  String get termsSection3Bullet1 =>
      'Cancelamento Facilitado: Você pode cancelar sua assinatura a qualquer momento no app com um toque, sem fidelidade ou taxas de cancelamento.';

  @override
  String get termsSection3Bullet2 =>
      'Direito de Arrependimento (CDC Art. 49): Garantia de reembolso integral em até 7 (sete) dias corridos a partir da contratação inicial.';

  @override
  String get termsSection3Bullet3 =>
      'Acesso Contínuo: O cancelamento interrompe faturas subsequentes e preserva seu acesso até o término do ciclo mensal contratado.';

  @override
  String get termsSection4Title => '4. Propriedade Intelectual';

  @override
  String get termsSection4Body =>
      'Todos os direitos de propriedade intelectual sobre software, conteúdos, marcas e interfaces pertencem com exclusividade à DualisCheckUp Saúde e Tecnologia Ltda. É estritamente vedada a reprodução, engenharia reversa ou mineração de dados.';

  @override
  String get termsSection5Title => '5. Suspensão por Violação de Segurança';

  @override
  String get termsSection5Body =>
      'Contas que executarem tentativas de invasão, ataques de força bruta, testes de penetração não autorizados ou submissão de dados fraudulentos serão imediatamente bloqueadas, com encaminhamento às autoridades competentes.';

  @override
  String get termsSection6Title => '6. Foro e Contato Jurídico';

  @override
  String get termsSection6Body =>
      'Estes termos são regidos pelas leis brasileiras. Fica eleito o Foro da Comarca de São Paulo/SP como único competente para dirimir litígios decorrentes deste contrato.\n\nPara dúvidas ou notificações legais: legal@dualischeckup.com.';

  @override
  String get privacyPolicyAppBarTitle => 'Política de Privacidade (LGPD)';

  @override
  String get privacyPolicyHeaderTitle =>
      'Política de Privacidade & Proteção de Dados';

  @override
  String get privacyPolicyHeaderSubtitle =>
      'Conformidade com a Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/2018)';

  @override
  String get privacyPolicyIntro =>
      'A sua privacidade e a confidencialidade dos seus dados de saúde são a nossa prioridade absoluta. Esta política descreve como tratamos, protegemos e permitimos que você controle integralmente suas informações.';

  @override
  String get privacyPolicyDpoLine =>
      'Encarregado de Dados (DPO): dpo@dualischeckup.com';

  @override
  String get privacyPolicySection1Title =>
      '1. Dados Pessoais e Sensíveis Coletados';

  @override
  String get privacyPolicySection1Body =>
      'Nos termos do Artigo 11 da LGPD, o tratamento de dados pessoais sensíveis de saúde é realizado com o seu consentimento específico e destacado (Art. 11, I):';

  @override
  String get privacyPolicySection1Bullet1 =>
      'Dados de Identificação: Nome completo, endereço de e-mail e data de nascimento.';

  @override
  String get privacyPolicySection1Bullet2 =>
      'Dados de Perfil: Sexo biológico e consumo de água, usados para ajustar suas metas de hidratação.';

  @override
  String get privacyPolicySection1Bullet3 =>
      'Diário de Bem-Estar: Anotações sobre como você se sente física e emocionalmente e a intensidade informada por você.';

  @override
  String get privacyPolicySection1Bullet4 =>
      'Dados de Acesso Técnico: Endereço IP mascarado, registros criptográficos de sessão e tokens de autenticação transitórios.';

  @override
  String get privacyPolicySection2Title =>
      '2. Finalidades e Proibição de Venda de Dados';

  @override
  String get privacyPolicySection2Body =>
      'Seus dados de saúde são tratados somente para:';

  @override
  String get privacyPolicySection2Bullet1 =>
      'Registro e visualização do seu diário de bem-estar.';

  @override
  String get privacyPolicySection2Bullet2 =>
      'Organização automática das suas anotações por área do corpo ou emoção (com auxílio de IA, sem avaliação de saúde).';

  @override
  String get privacyPolicySection2Bullet3 => 'Consistência do histórico.';

  @override
  String get privacyPolicySection2Bullet4 =>
      'Compromisso Ético: É expressamente PROIBIDA a venda, comercialização ou cessão onerosa dos seus dados para corretoras de seguros, anunciantes ou terceiros.';

  @override
  String get privacyPolicySection3Title =>
      '3. Operadores e Transferência Internacional';

  @override
  String get privacyPolicySection3Body =>
      'Para prestar o serviço, compartilhamos dados apenas com:';

  @override
  String get privacyPolicySection3Bullet1 =>
      'Google LLC (API Gemini): O texto das suas anotações é enviado à API Gemini do Google para organizá-las automaticamente. A IA não avalia a sua saúde.';

  @override
  String get privacyPolicySection3Bullet2 =>
      'Transferência Internacional: Esse processamento pode ocorrer em servidores localizados fora do Brasil (LGPD Art. 33).';

  @override
  String get privacyPolicySection3Bullet3 =>
      'Infraestrutura em Nuvem: Provedores de hospedagem e banco de dados, sujeitos a obrigações de confidencialidade e segurança.';

  @override
  String get privacyPolicySection4Title => '4. Pagamentos';

  @override
  String get privacyPolicySection4Body =>
      'Quando houver planos pagos, os dados de cartão ficam isolados dos nossos servidores:';

  @override
  String get privacyPolicySection4Bullet1 =>
      'Processamento por Terceiros: Os pagamentos são intermediados por gateways de pagamento especializados.';

  @override
  String get privacyPolicySection4Bullet2 =>
      'Zero Armazenamento: Os servidores da DualisCheckUp NÃO recebem, não processam e não salvam números de cartão de crédito ou códigos CVV.';

  @override
  String get privacyPolicySection5Title =>
      '5. Seus Direitos como Titular (Art. 18 da LGPD)';

  @override
  String get privacyPolicySection5Body =>
      'Você pode exercer seus direitos legais diretamente pelo aplicativo de forma instantânea:';

  @override
  String get privacyPolicySection5Bullet1 =>
      'Exportação de Dados: Baixe todos os seus registros em formato estruturado (JSON) com um clique na Central de Privacidade.';

  @override
  String get privacyPolicySection5Bullet2 =>
      'Exclusão Definitiva: Solicite a exclusão irrevogável da sua conta e de todos os dados associados.';

  @override
  String get privacyPolicySection5Bullet3 =>
      'Revogação do Consentimento: Encerre o uso e retire a autorização a qualquer momento.';

  @override
  String get privacyPolicySection6Title =>
      '6. Segurança da Informação & Resposta a Incidentes';

  @override
  String get privacyPolicySection6Body =>
      'Medidas técnicas de ponta a ponta protegem seus registros:';

  @override
  String get privacyPolicySection6Bullet1 =>
      'Isolamento RLS: Cada consulta ao banco PostgreSQL é blindada pela política de Row-Level Security com chave de usuário isolada.';

  @override
  String get privacyPolicySection6Bullet2 =>
      'Criptografia Forte: Conexões TLS 1.3 obrigatórias e senhas protegidas pelo algoritmo Argon2id.';

  @override
  String get privacyPolicySection6Bullet3 =>
      'Plano de Notificação em até 72h: Protocolo de comunicação imediata à Autoridade Nacional de Proteção de Dados (ANPD) e aos usuários em qualquer evento relevante de segurança (LGPD Art. 48).';

  @override
  String get privacyPolicySection7Title =>
      '7. Notificações, Comunicações e Opt-Out';

  @override
  String get privacyPolicySection7Body =>
      'Respeitamos a sua tranquilidade e atenção:';

  @override
  String get privacyPolicySection7Bullet1 =>
      'Você tem liberdade total para desativar lembretes de hidratação ou notificações de dicas de bem-estar na aba de Configurações a qualquer momento.';

  @override
  String get privacyPolicySection7Bullet2 =>
      'Avisos de segurança e recuperação de conta são de natureza estritamente transacional e protegidos.';

  @override
  String get privacyPolicyCtaQuestion =>
      'Deseja exportar seus dados ou gerenciar sua conta agora?';

  @override
  String get privacyPolicyCtaButton => 'Ir para a Central de Privacidade';

  @override
  String get onboardingIntendedUseNote =>
      'O DualisCheckUp é um aplicativo de bem-estar e autoconhecimento. Não é um dispositivo médico e não substitui um profissional de saúde.';

  @override
  String get privacyVeilBiometricReason =>
      'Autentique-se para acessar seus registros.';

  @override
  String get privacyVeilUnlock => 'Desbloquear';

  @override
  String get privacyVeilUnlockManually => 'Desbloquear manualmente';

  @override
  String get wizardNarrativeLabel => 'Descrição opcional (em suas palavras)';

  @override
  String get wizardNarrativeHint =>
      'Se quiser, escreva com suas palavras como você está.';

  @override
  String deleteHistoryItemIntensity(int value) {
    return 'Intensidade informada: $value/5';
  }

  @override
  String get bodyMapRegionHeadNeck => 'Cabeça e pescoço';

  @override
  String get bodyMapRegionHeadNeckHint =>
      'Dor de cabeça, dor ou rigidez no pescoço';

  @override
  String get bodyMapRegionDizziness => 'Tontura / formigamento';

  @override
  String get bodyMapRegionDizzinessHint =>
      'Tontura, sensação de desequilíbrio, formigamento';

  @override
  String get bodyMapRegionBack => 'Costas';

  @override
  String get bodyMapRegionBackHint => 'Dor nas costas, na coluna ou na lombar';

  @override
  String get bodyMapRegionBreathing => 'Respiração';

  @override
  String get bodyMapRegionBreathingHint => 'Falta de ar, tosse';

  @override
  String get bodyMapRegionChest => 'Peito';

  @override
  String get bodyMapRegionChestHint =>
      'Aperto ou desconforto no peito, coração acelerado';

  @override
  String get bodyMapRegionBelly => 'Barriga';

  @override
  String get bodyMapRegionBellyHint => 'Desconforto na barriga, cólica, azia';

  @override
  String get bodyMapRegionPelvic => 'Região íntima / urinária';

  @override
  String get bodyMapRegionPelvicHint =>
      'Desconforto na região pélvica ou ao urinar';

  @override
  String get bodyMapRegionRightArm => 'Braço direito';

  @override
  String get bodyMapRegionRightArmHint =>
      'Braço, ombro, cotovelo ou punho direito';

  @override
  String get bodyMapRegionLeftArm => 'Braço esquerdo';

  @override
  String get bodyMapRegionLeftArmHint =>
      'Braço, ombro, cotovelo ou punho esquerdo';

  @override
  String get bodyMapRegionRightLeg => 'Perna direita';

  @override
  String get bodyMapRegionRightLegHint =>
      'Quadril, coxa, joelho ou tornozelo direito';

  @override
  String get bodyMapRegionLeftLeg => 'Perna esquerda';

  @override
  String get bodyMapRegionLeftLegHint =>
      'Quadril, coxa, joelho ou tornozelo esquerdo';

  @override
  String get bodyMapRegionSkin => 'Pele';

  @override
  String get bodyMapRegionSkinHint => 'Coceira, manchas';

  @override
  String get bodyMapRegionWholeBody => 'Corpo todo / cansaço';

  @override
  String get bodyMapRegionWholeBodyHint => 'Dor no corpo todo, cansaço';

  @override
  String get bodyMapRegionEnergy => 'Sede, fome ou energia';

  @override
  String get bodyMapRegionEnergyHint => 'Mudanças de energia, sede ou fome';

  @override
  String get bodyMapGroupHead => 'Cabeça';

  @override
  String get bodyMapGroupTrunk => 'Tronco';

  @override
  String get bodyMapGroupLimbs => 'Braços e pernas';

  @override
  String get bodyMapGroupWholeBody => 'Corpo todo e pele';

  @override
  String get bodyMapViewMap => 'Mapa do corpo';

  @override
  String get bodyMapViewAll => 'Todas as áreas';

  @override
  String get bodyMapShortSkin => 'Pele';

  @override
  String get bodyMapShortWholeBody => 'Corpo todo';

  @override
  String get bodyMapShortEnergy => 'Energia';

  @override
  String bodyMapMaxIntensity(int value) {
    return 'Maior intensidade informada nos últimos 14 dias: $value/5';
  }

  @override
  String bodyMapNoEntriesThisSide(String otherArea, int value) {
    return 'Sem registros deste lado nos últimos 14 dias.\n($otherArea: intensidade informada $value/5)';
  }

  @override
  String bodyMapViewOtherSide(String area) {
    return 'Ver $area';
  }

  @override
  String get bodyMapNoEntries14Days => 'Nenhum registro nos últimos 14 dias';

  @override
  String get settingsChangePhotoSubtitle =>
      'Escolha como deseja selecionar sua foto de perfil.';

  @override
  String get settingsPhotoCamera => 'Câmera';

  @override
  String get settingsPhotoCameraSubtitle => 'Tirar uma nova foto';

  @override
  String get settingsPhotoGallery => 'Galeria';

  @override
  String get settingsPhotoGallerySubtitle => 'Escolher da biblioteca de fotos';

  @override
  String get settingsPhotoPresets => 'Avatares';

  @override
  String get settingsPhotoPresetsSubtitle =>
      'Escolher um ícone ilustrado de autocuidado';

  @override
  String get settingsLogoutConfirmBody =>
      'Deseja realmente encerrar sua sessão? Seus dados permanecem seguros e criptografados.';

  @override
  String get settingsLogoutConfirmAction => 'Sair';

  @override
  String get settingsNameHint => 'Seu nome completo';

  @override
  String get settingsRemindersTile => 'Lembretes e Hidratação';

  @override
  String get settingsRemindersSubtitle =>
      'Horários de notificações, alarmes e teste com app fechado';

  @override
  String get settingsTermsTile => 'Termos de Uso';

  @override
  String get settingsTermsSubtitle =>
      'Condições de uso, planos, cancelamento e reembolso';

  @override
  String get settingsPrivacyPolicyTile => 'Política de Privacidade (LGPD)';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'Tratamento de dados, direitos do titular e DPO';

  @override
  String get settingsCommunicationsSection => 'Comunicações e Notificações';

  @override
  String get settingsEducationalTipsTile =>
      'Dicas de Bem-Estar e Notificações Educativas';

  @override
  String get settingsEducationalTipsSubtitle =>
      'Dicas gerais de bem-estar. Você pode desativar (opt-out) a qualquer momento.';

  @override
  String get settingsEducationalTipsOn => 'Notificações educativas ativadas.';

  @override
  String get settingsEducationalTipsOff =>
      'Opt-out confirmado: Notificações educativas desativadas.';

  @override
  String get settingsOperatorInfo =>
      'Operado por DualisCheckUp Saúde e Tecnologia Ltda.\nCNPJ 48.291.834/0001-92 • São Paulo - SP, Brasil\nDPO: dpo@dualischeckup.com';

  @override
  String get avatarSelectorSubtitle =>
      'Selecione um ícone de autocuidado para personalizar seu perfil.';

  @override
  String get avatarConfirm => 'Confirmar Avatar';

  @override
  String get avatarPresetSelfCare => 'Autocuidado';

  @override
  String get avatarPresetBalance => 'Equilíbrio';

  @override
  String get avatarPresetProtection => 'Proteção';

  @override
  String get avatarPresetVitality => 'Vitalidade';

  @override
  String get avatarPresetWellbeing => 'Bem-estar';

  @override
  String get avatarPresetEnergy => 'Energia';

  @override
  String get avatarPresetFocus => 'Foco Mental';

  @override
  String get avatarPresetRadiant => 'Radiante';

  @override
  String get loginTitle => 'Entrar no DualisCheckUp';

  @override
  String get loginSubtitle => 'Acesse seu diário de bem-estar com segurança.';

  @override
  String get authEmailHint => 'seu.email@exemplo.com';

  @override
  String get loginPasswordRequired => 'Senha é obrigatória.';

  @override
  String get loginNoAccountPrompt => 'Ainda não possui conta? ';

  @override
  String get registerTitle => 'Criar sua conta';

  @override
  String get registerSubtitle =>
      'Informe alguns dados para personalizar sua experiência.';

  @override
  String get registerNameHint => 'Ex: Carlos Silva';

  @override
  String get registerDobHint => 'DD/MM/AAAA';

  @override
  String get registerDobHelper =>
      'Ex: 15/08/1990 ou selecione pelo calendário.';

  @override
  String get registerDobPickerHelp => 'Selecione a data de nascimento';

  @override
  String get registerDobPickerConfirm => 'Confirmar';

  @override
  String get registerPasswordHint => 'Mínimo 8 caracteres';

  @override
  String get registerPasswordHelper =>
      'Use 8+ caracteres com maiúscula, número e símbolo.';

  @override
  String get registerHydrationTitle => 'Lembretes e Controle de Hidratação';

  @override
  String get registerHydrationSubtitle =>
      'Configure seus hábitos de hidratação';

  @override
  String get registerWaterReminderTitle => 'Alerta para tomar água a cada 2h';

  @override
  String get registerWaterReminderSubtitle =>
      'Horários pares: 8h, 10h, 12h, 14h, 16h, 18h e 20h';

  @override
  String get registerReminderStyleLabel => 'Tipo de lembrete / som:';

  @override
  String get registerReminderStyleChime => 'Aviso (Mensagem)';

  @override
  String get registerReminderStyleAlarm => 'Alarme Telefônico';

  @override
  String get registerWaterTrackingTitle => 'Controle de quantidade consumida';

  @override
  String get registerWaterTrackingOnDesc =>
      'Ao tocar no alarme, o app abre para registrar a quantidade de água';

  @override
  String get registerWaterTrackingOffDesc =>
      'Apenas soa o lembrete no horário, sem abrir preenchimento';

  @override
  String get registerHaveAccountPrompt => 'Já possui uma conta? ';

  @override
  String homeGreeting(String name) {
    return 'Olá, $name';
  }

  @override
  String get homeGreetingNoName => 'Olá!';

  @override
  String get homeSessionActive => 'Sessão ativa';

  @override
  String get homeDataProtectedBadge => 'Seus registros estão protegidos';

  @override
  String get homeTodayEntryDone => 'Registro de hoje concluído';

  @override
  String get notFoundErrorCode => 'ERRO 404';

  @override
  String get notFoundTitle => 'Página Não Encontrada';

  @override
  String get notFoundBody => 'A página que você tentou acessar não existe.';

  @override
  String get notFoundBackToDashboard => 'Voltar para o Painel';

  @override
  String get notFoundGoHome => 'Ir para o Início';

  @override
  String get notFoundGoBack => 'Voltar à tela anterior';

  @override
  String get wellnessConfirmTitle => 'Tudo Bem por Aqui!';

  @override
  String get wellnessConfirmBody =>
      'Que excelente notícia! Você indicou estar se sentindo bem tanto física quanto emocionalmente hoje.\n\nSeu check-in diário foi concluído com sucesso e seus dados estão protegidos. Continue cultivando bons hábitos de autocuidado!';

  @override
  String get wellnessConfirmButton => 'Concluir Check-in';

  @override
  String get adBannerHeader =>
      'Parceiro local • Anúncio não usa seus dados de saúde';

  @override
  String get adBannerSampleBody =>
      'Itens de primeiros socorros e higiene pessoal com até 20% off.';

  @override
  String get outcomeStaticGuidance =>
      'Este app não avalia sua saúde. Se algum desconforto persistir, piorar ou te preocupar, procure um profissional de saúde. Em emergência, ligue 192.';

  @override
  String get outcomeDualAxisNote =>
      'Você registrou sensações no corpo e nas emoções hoje. Se algum desconforto físico persistir ou piorar, converse com um profissional de saúde.';

  @override
  String get outcomeAiInsightTitle => 'Como organizamos sua anotação';

  @override
  String outcomeAiInsightLayTerm(String term) {
    return 'Termo que você usou: $term';
  }

  @override
  String outcomeAiInsightArea(String area) {
    return 'Área ou emoção: $area';
  }

  @override
  String get outcomeWellnessReadingsTitle => 'Leituras sobre bem-estar';

  @override
  String get outcomeWellnessReadingsDisclaimer =>
      'Conteúdos educativos gerais. Não são orientação para o seu caso.';

  @override
  String get outcomeWellnessReadingsRelatedTitle =>
      'Leituras relacionadas ao tema que você registrou';

  @override
  String outcomeWellnessReadingsCount(int count) {
    return '$count leituras';
  }

  @override
  String get outcomeArticlesEmpty => 'Nenhuma leitura disponível no momento.';

  @override
  String get journalPatternTitle => 'Padrões nos seus registros';

  @override
  String journalPatternDescription(String category, int count, int windowDays) {
    return 'Você registrou $category com intensidade alta $count vezes nos últimos $windowDays dias. Se isso está atrapalhando seu dia a dia, pode ser útil conversar com um profissional de saúde.';
  }

  @override
  String historyIntensityInformed(int n) {
    return 'Intensidade informada: $n/5';
  }

  @override
  String get todayOutcomeCompletedBadge => 'Registro concluído';

  @override
  String get todayOutcomeUpdateButton => 'Atualizar registro de hoje';

  @override
  String get todayOutcomeDetailedCheckinButton => 'Fazer registro detalhado';

  @override
  String get appUpdateTitle => 'Atualize o aplicativo';

  @override
  String appUpdateMessage(String minVersion) {
    return 'Esta versão não é mais suportada. Instale a versão $minVersion ou mais recente na loja de aplicativos.';
  }

  @override
  String get appUpdateButton => 'Abrir loja de aplicativos';

  @override
  String outcomeSummaryIntensity(int value) {
    return 'Intensidade informada: $value/5';
  }

  @override
  String outcomeSummaryRecordedAt(String time) {
    return 'Registrado às $time';
  }

  @override
  String outcomeTodayYouLogged(String option) {
    return 'Você registrou: $option';
  }

  @override
  String get outcomeTodayStatusGood => 'Bem';

  @override
  String get outcomeTodayStatusSoSo => 'Mais ou menos';

  @override
  String get outcomeTodayStatusBad => 'Mal';

  @override
  String get outcomeHistoryDetailTitle => 'Detalhes do registro';

  @override
  String get outcomeHistoryNoNarrative =>
      'Você não adicionou uma descrição neste registro.';
}
