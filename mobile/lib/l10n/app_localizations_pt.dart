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
  String get triageOptAnsiosaAgitacao => 'Ansiosa / Agitação';

  @override
  String get triageOptDepressivaDesanimo => 'Depressiva / Desânimo';

  @override
  String get triageOptEstresseBurnout => 'Estresse / Burnout';

  @override
  String get triageOptSomatica => 'Somática (Psicossomática)';

  @override
  String get triageOptSono => 'Sono (Insônia / Hipersônia)';

  @override
  String get triageOptCognitivaFoco => 'Cognitiva / Foco';

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
  String get triageOptCabecaPescoco => 'Cabeça e Pescoço';

  @override
  String get triageOptCardiovascularTorax => 'Cardiovascular / Tórax';

  @override
  String get triageOptRespiratorio => 'Sistema Respiratório';

  @override
  String get triageOptGastrointestinalAbdomen => 'Gastrointestinal / Abdômen';

  @override
  String get triageOptColunaDorDorsal => 'Coluna e Dor Dorsal';

  @override
  String get triageOptMembrosSuperiores => 'Membros Superiores D/E';

  @override
  String get triageOptMembrosInferiores => 'Membros Inferiores D/E';

  @override
  String get triageOptNeurologico => 'Sistema Neurológico';

  @override
  String get triageOptGeniturinarioPelvico => 'Geniturinário / Pélvico';

  @override
  String get triageOptDermatologico => 'Sistema Dermatológico';

  @override
  String get triageOptMuscularGeralSistemico => 'Muscular / Geral Sistêmico';

  @override
  String get triageOptEndocrinoMetabolico => 'Endócrino / Metabólico';

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
      'Visualize seu histórico de triagens';

  @override
  String get deleteHistoryItemTitle => 'Descartar registro do histórico';

  @override
  String get deleteHistoryItemConfirm =>
      'Tem certeza de que deseja descartar este registro de triagem do seu histórico? Esta ação é irreversível.';

  @override
  String get deleteHistoryItemSuccess => 'Registro removido com sucesso.';

  @override
  String get deleteHistoryItemError => 'Não foi possível remover o registro.';

  @override
  String get deleteAction => 'Descartar';
}
