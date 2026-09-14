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
}
