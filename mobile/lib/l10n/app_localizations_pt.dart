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
}
