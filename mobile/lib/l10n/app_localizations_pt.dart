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
  String get forgotPasswordTitle => 'Esqueceu sua senha?';

  @override
  String get forgotPasswordSubtitle =>
      'Informe o e-mail vinculado à sua conta e enviaremos um código para redefinir sua senha.';

  @override
  String get forgotPasswordSendCta => 'Enviar Código';

  @override
  String get forgotPasswordSuccessMessage =>
      'Se esse e-mail estiver cadastrado, enviamos um código de redefinição para ele.';

  @override
  String get forgotPasswordBackToLogin => 'Voltar ao Login';

  @override
  String get resetPasswordTitle => 'Redefina sua senha';

  @override
  String get resetPasswordSubtitle =>
      'Informe o código que enviamos e escolha uma nova senha.';

  @override
  String get resetPasswordCodeLabel => 'Código de Verificação';

  @override
  String get resetPasswordCodeHint => 'Código de 6 dígitos';

  @override
  String get resetPasswordCodeRequired => 'Informe o código de 6 dígitos';

  @override
  String get resetPasswordSubmitCta => 'Redefinir Senha';

  @override
  String get resetPasswordSuccessMessage =>
      'Sua senha foi redefinida. Você já pode fazer login.';

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
  String get loginEmailNotVerified =>
      'Seu e-mail ainda não foi verificado. Digite o código enviado ou peça um novo.';

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
      'Sugerir, com ajuda de IA, uma opção já existente do diário quando você escreve com as suas palavras (sem avaliação de saúde).';

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
      'Google LLC (API Gemini): o texto de \"escrever o meu\" pode ser enviado à Gemini só para sugerir uma opção já existente do diário. A IA não avalia a sua saúde.';

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
  String outcomeWellnessReadingsCount(int count) {
    return '$count leituras';
  }

  @override
  String get journalPatternTitle => 'Padrões nos seus registros';

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
  String get checkInSummaryTitle => 'Registro salvo';

  @override
  String get checkInSummaryBackHome => 'Voltar ao início';

  @override
  String checkInSummaryBackHomeCountdown(int seconds) {
    return 'Voltar ao início ($seconds)';
  }

  @override
  String get jv2FlowTitle => 'Registro do dia';

  @override
  String get jv2Back => 'Voltar';

  @override
  String get jv2Continue => 'Continuar';

  @override
  String get jv2Skip => 'Pular';

  @override
  String get jv2Save => 'Salvar registro';

  @override
  String get jv2Yes => 'Sim';

  @override
  String get jv2No => 'Não, continuar';

  @override
  String get jv2Cancel => 'Cancelar';

  @override
  String get jv2Remove => 'Remover';

  @override
  String jv2HelloName(String name) {
    return 'Olá, $name!';
  }

  @override
  String get jv2Hello => 'Olá!';

  @override
  String get jv2GoodMorning => 'Bom dia.';

  @override
  String get jv2GoodAfternoon => 'Boa tarde.';

  @override
  String get jv2GoodEvening => 'Boa noite.';

  @override
  String get jv2MoodQuestion => 'Como você está se sentindo hoje?';

  @override
  String get jv2MoodBem => 'Bem';

  @override
  String get jv2MoodNormal => 'Normal';

  @override
  String get jv2MoodNaoTaoBem => 'Não tão bem';

  @override
  String get jv2AreaConditions => 'Minhas condições';

  @override
  String jv2ConditionCardQuestion(String label) {
    return 'Como você está com $label hoje?';
  }

  @override
  String get jv2TimeQuestion => 'Isso que você sente tem mais a ver com…';

  @override
  String get jv2TimePassado => 'O que já passou';

  @override
  String get jv2TimePresente => 'O momento atual';

  @override
  String get jv2TimeFuturo => 'O que vem pela frente';

  @override
  String get jv2TimeShortPassado => 'Passado';

  @override
  String get jv2TimeShortPresente => 'Presente';

  @override
  String get jv2TimeShortFuturo => 'Futuro';

  @override
  String get jv2BranchQuestion => 'O que combina mais com você agora?';

  @override
  String get jv2OptionsQuestion => 'Marque o que combina com você.';

  @override
  String get jv2MultiSelectHint => 'Você pode marcar mais de um.';

  @override
  String get jv2WriteMine => 'Escrever o meu';

  @override
  String get jv2WriteMineHint => 'Em poucas palavras';

  @override
  String get jv2WriteMineAdd => 'Adicionar';

  @override
  String get jv2SuggestTitle => 'Isso se parece com uma opção que já existe';

  @override
  String jv2SuggestBody(String option) {
    return 'Quer guardar como \"$option\" em vez do texto escrito?';
  }

  @override
  String get jv2SuggestYes => 'Usar essa opção';

  @override
  String get jv2SuggestNo => 'Manter o que escrevi';

  @override
  String get jv2MoreQuestion => 'Quer registrar mais alguma coisa?';

  @override
  String get jv2MoreBodyQuestion => 'Quer marcar outra parte do corpo?';

  @override
  String get jv2BodyQuestion => 'Onde você sente dor ou incômodo?';

  @override
  String get jv2BodyHint => 'Toque em uma ou mais partes.';

  @override
  String get jv2BodyFront => 'Frente';

  @override
  String get jv2BodyBack => 'Costas';

  @override
  String jv2ItemLimit(int max) {
    return 'Você chegou ao limite de $max itens neste registro.';
  }

  @override
  String get jv2BranchPassadoTristeza => 'Tristeza ou saudade';

  @override
  String get jv2BranchPassadoMemoria => 'Uma memória que incomoda';

  @override
  String get jv2BranchPresenteEnergia => 'Sem energia';

  @override
  String get jv2BranchPresenteSobrecarga => 'Irritado(a) ou sobrecarregado(a)';

  @override
  String get jv2BranchFuturoMente => 'Mente acelerada';

  @override
  String get jv2BranchFuturoMedo => 'Medo de algo dar errado';

  @override
  String get jv2OptPassadoTristezaCulpa => 'Culpa ou arrependimento';

  @override
  String get jv2OptPassadoTristezaSaudade =>
      'Falta de alguém ou de como as coisas eram';

  @override
  String get jv2OptPassadoMemoriaLembranca => 'Uma lembrança ruim que volta';

  @override
  String get jv2OptPassadoMemoriaMagoa => 'Fico remoendo mágoas antigas';

  @override
  String get jv2OptPresenteEnergiaCorpo => 'Corpo pesado, tenso ou dolorido';

  @override
  String get jv2OptPresenteEnergiaDesligado =>
      'No piloto automático, meio desligado';

  @override
  String get jv2OptPresenteSobrecargaPaciencia =>
      'Sem paciência, explodindo por pouco';

  @override
  String get jv2OptPresenteSobrecargaAperto =>
      'Aperto no peito e momentos de desespero';

  @override
  String get jv2OptFuturoMenteAntecipar => 'Fico antecipando problemas';

  @override
  String get jv2OptFuturoMenteCobranca => 'Cobrança por perfeição ou controle';

  @override
  String get jv2OptFuturoMedoJulgamento => 'Medo de falhar ou ser julgado(a)';

  @override
  String get jv2OptFuturoMedoDesanimo => 'Desânimo com o rumo das coisas';

  @override
  String get jv2RegionCabeca => 'Cabeça e pescoço';

  @override
  String get jv2RegionPeito => 'Peito';

  @override
  String get jv2RegionBarriga => 'Barriga';

  @override
  String get jv2RegionCostas => 'Costas';

  @override
  String get jv2RegionMembros => 'Braços, pernas e mãos';

  @override
  String get jv2AxisEmotional => 'Psicoemocional';

  @override
  String get jv2AxisPhysical => 'Físico';

  @override
  String get jv2WholeBody => 'No corpo todo';

  @override
  String get jv2RegionPele => 'Pele';

  @override
  String get jv2RegionMusculos => 'Músculos';

  @override
  String get jv2RegionHormonios => 'Hormônios e metabolismo';

  @override
  String get jv2SensationQuestion => 'É dor ou incômodo?';

  @override
  String get jv2SensationDor => 'Dor';

  @override
  String get jv2SensationIncomodo => 'Incômodo';

  @override
  String get jv2BranchCabecaNuca => 'Nuca';

  @override
  String get jv2BranchPeleCoceira => 'Coceira ou ardência';

  @override
  String get jv2BranchPeleAparencia => 'Aparência da pele';

  @override
  String get jv2BranchMusculosTensao => 'Tensão';

  @override
  String get jv2BranchMusculosCansaco => 'Cansaço muscular';

  @override
  String get jv2BranchHormoniosTemperatura => 'Temperatura';

  @override
  String get jv2BranchHormoniosApetite => 'Apetite e sede';

  @override
  String get jv2OptCabecaNucaRigida => 'Nuca dura ou pesada';

  @override
  String get jv2OptCabecaNucaPontada => 'Pontada na parte de trás';

  @override
  String get jv2OptPeleCoceiraCoceira => 'Coceira';

  @override
  String get jv2OptPeleCoceiraArdencia => 'Ardência';

  @override
  String get jv2OptPeleAparenciaVermelhidao => 'Vermelhidão';

  @override
  String get jv2OptPeleAparenciaManchas => 'Manchas';

  @override
  String get jv2OptMusculosTensaoRigidez => 'Rigidez';

  @override
  String get jv2OptMusculosTensaoCaibra => 'Cãibra';

  @override
  String get jv2OptMusculosCansacoFraqueza => 'Fraqueza';

  @override
  String get jv2OptMusculosCansacoDolorido => 'Dolorido';

  @override
  String get jv2OptHormoniosTemperaturaCalorao => 'Calorões';

  @override
  String get jv2OptHormoniosTemperaturaFrio => 'Frio fora do comum';

  @override
  String get jv2OptHormoniosApetiteSede => 'Sede fora do comum';

  @override
  String get jv2OptHormoniosApetiteFome => 'Fome fora do comum';

  @override
  String get jv2BranchCabecaPressao => 'Aperto, peso ou pressão';

  @override
  String get jv2BranchCabecaSentidos => 'Olhos, boca ou garganta';

  @override
  String get jv2BranchPeitoRespiracao => 'Respiração diferente';

  @override
  String get jv2BranchPeitoIncomodo => 'Incômodo no peito ou costelas';

  @override
  String get jv2BranchBarrigaQueimacao => 'Queimação ou enjoo';

  @override
  String get jv2BranchBarrigaColica => 'Cólica ou estufamento';

  @override
  String get jv2BranchCostasRigidez => 'Rigidez ou travamento';

  @override
  String get jv2BranchCostasFisgada => 'Dor que fisga ao mexer';

  @override
  String get jv2BranchMembrosCansaco => 'Cansaço ou dor';

  @override
  String get jv2BranchMembrosFormigamento => 'Formigamento';

  @override
  String get jv2OptCabecaPressaoTemporas =>
      'Dor ou pressão nas têmporas ou testa';

  @override
  String get jv2OptCabecaPressaoLatejando =>
      'Latejando, com incômodo à luz ou ao barulho';

  @override
  String get jv2OptCabecaSentidosGarganta => 'Garganta arranhando ou seca';

  @override
  String get jv2OptCabecaSentidosOlhos => 'Olhos pesados ou ardendo';

  @override
  String get jv2OptPeitoRespiracaoCurta => 'Respiração curta';

  @override
  String get jv2OptPeitoRespiracaoTosse => 'Tosse ou peito carregado';

  @override
  String get jv2OptPeitoIncomodoBatedeira => 'Coração acelerado ou batedeira';

  @override
  String get jv2OptPeitoIncomodoCostelas =>
      'Pontada nas costelas ao respirar fundo';

  @override
  String get jv2OptBarrigaQueimacaoSubindo => 'Queimação subindo';

  @override
  String get jv2OptBarrigaQueimacaoEnjoo => 'Enjoo';

  @override
  String get jv2OptBarrigaColicaGases => 'Gases ou barriga estufada';

  @override
  String get jv2OptBarrigaColicaPontadas => 'Cólica ou pontadas';

  @override
  String get jv2OptCostasRigidezOmbros => 'Pescoço e ombros duros';

  @override
  String get jv2OptCostasRigidezLombar => 'Peso na lombar';

  @override
  String get jv2OptCostasFisgadaIrradia =>
      'Pontada que desce para braço ou perna';

  @override
  String get jv2OptCostasFisgadaAoMexer => 'Dor ao mexer';

  @override
  String get jv2OptMembrosCansacoJuntas => 'Juntas doloridas';

  @override
  String get jv2OptMembrosCansacoPesados => 'Braços ou pernas cansados';

  @override
  String get jv2OptMembrosFormigamentoDormentes =>
      'Mãos ou pés formigando ou dormentes';

  @override
  String get jv2OptMembrosFormigamentoChoque => 'Sensação de choque';

  @override
  String get jv2PersistenceQuestion => 'Há quanto tempo você percebe isso?';

  @override
  String get jv2PersistenceHoje => 'Começou hoje';

  @override
  String get jv2PersistenceDiasSemanas => 'Alguns dias ou semanas';

  @override
  String get jv2PersistenceMesesAnos => 'Meses ou anos';

  @override
  String get jv2PersistenceOptional => 'Há quanto tempo? (opcional)';

  @override
  String get jv2IntensityQuestion => 'Agora, quanto isso pesa no seu dia?';

  @override
  String get jv2IntensityCompactQuestion =>
      'Para cada item, quanto pesa no seu dia?';

  @override
  String jv2IntensityLevel(int level) {
    return '$level de 5';
  }

  @override
  String get jv2IntensityEmotional1 =>
      'Passa rápido, sigo meu dia normalmente.';

  @override
  String get jv2IntensityEmotional2 => 'Percebo, mas consigo manter o foco.';

  @override
  String get jv2IntensityEmotional3 => 'Está tirando minha energia ou foco.';

  @override
  String get jv2IntensityEmotional4 =>
      'Está mudando minha rotina (sono, tarefas, convívio).';

  @override
  String get jv2IntensityEmotional5 =>
      'Está me travando quase por completo hoje.';

  @override
  String get jv2IntensityPhysical1 => 'Sinto, mas não atrapalha nada.';

  @override
  String get jv2IntensityPhysical2 =>
      'Incomoda, mas mantenho minhas atividades.';

  @override
  String get jv2IntensityPhysical3 => 'Diminuiu meu ritmo ou me fez pausar.';

  @override
  String get jv2IntensityPhysical4 =>
      'Não consigo fazer direito o que preciso.';

  @override
  String get jv2IntensityPhysical5 =>
      'Está me travando quase por completo hoje.';

  @override
  String get jv2EmergencyLine =>
      'Se for uma emergência, use o botão Ajuda ou ligue 192.';

  @override
  String get jv2TriggersQuestion => 'Tem algo que pode ter contribuído hoje?';

  @override
  String get jv2TriggerTrabalho => 'Trabalho ou estudos';

  @override
  String get jv2TriggerFamilia => 'Família ou relações';

  @override
  String get jv2TriggerSono => 'Noite mal dormida';

  @override
  String get jv2TriggerAlimentacao => 'Alimentação';

  @override
  String get jv2TriggerEsforco => 'Esforço físico';

  @override
  String get jv2TriggerQueda => 'Queda ou mau jeito';

  @override
  String get jv2TriggerMedicamento => 'Medicamento novo';

  @override
  String get jv2TriggerClima => 'Clima ou ambiente';

  @override
  String get jv2TriggerNaoSei => 'Não sei';

  @override
  String get jv2TriggerOutro => 'Outro';

  @override
  String get jv2TriggerNoteHint => 'Conte em poucas palavras';

  @override
  String get jv2NoteQuestion => 'Quer contar mais?';

  @override
  String get jv2NoteHint => 'Escreva com suas palavras (opcional)';

  @override
  String get jv2SaveError => 'Não foi possível salvar agora. Tente de novo.';

  @override
  String get jv2SavedOffline =>
      'Registro salvo no aparelho. Ele será enviado quando houver conexão.';

  @override
  String get jv2ConditionsTitle => 'Minhas condições';

  @override
  String get jv2ConditionsSubtitle =>
      'Informadas por você. Escreva com suas palavras; cada uma aparece no seu registro diário com a mesma escala de 1 a 5.';

  @override
  String get jv2ConditionsAdd => 'Adicionar';

  @override
  String get jv2ConditionsFieldHint => 'Ex.: Enxaqueca';

  @override
  String get jv2ConditionsEmpty => 'Você ainda não adicionou nenhuma.';

  @override
  String get jv2ConditionsArchive => 'Arquivar';

  @override
  String jv2ConditionsArchiveConfirm(String label) {
    return 'Arquivar \"$label\"? Seus registros antigos continuam com esse nome.';
  }

  @override
  String jv2ConditionsLimit(int max) {
    return 'Você pode acompanhar até $max.';
  }

  @override
  String get jv2ConditionsOffline =>
      'Sem conexão. Tente de novo quando estiver online.';

  @override
  String get jv2ConditionsError => 'Não foi possível salvar. Tente de novo.';

  @override
  String get jv2ConditionsSettingsSubtitle =>
      'Acompanhe, com suas palavras, algo que você já conhece';

  @override
  String get jv2PhraseTime1 => 'Entendi. Vamos registrar isso com calma.';

  @override
  String get jv2PhraseTime2 => 'Obrigado por contar. Vamos anotar isso.';

  @override
  String get jv2PhraseTime3 => 'Tudo bem. Um passo de cada vez.';

  @override
  String get jv2PhraseTime4 => 'Certo. Vamos registrar do seu jeito.';

  @override
  String get jv2PhrasePassado1 =>
      'A mente às vezes volta no tempo. Vamos anotar isso.';

  @override
  String get jv2PhrasePassado2 => 'Obrigado por contar. Tem a ver com o quê?';

  @override
  String get jv2PhrasePassado3 => 'Vamos registrar isso com calma.';

  @override
  String get jv2PhrasePresente1 => 'Vamos anotar o que está pesando hoje.';

  @override
  String get jv2PhrasePresente2 => 'Entendi. O que combina mais com agora?';

  @override
  String get jv2PhrasePresente3 => 'Obrigado por contar. Vamos registrar isso.';

  @override
  String get jv2PhraseFuturo1 =>
      'Pensar no que vem pela frente faz parte. Vamos anotar.';

  @override
  String get jv2PhraseFuturo2 => 'Entendi. O que combina mais com você?';

  @override
  String get jv2PhraseFuturo3 =>
      'Obrigado por contar. Vamos registrar isso com calma.';

  @override
  String get jv2PhraseBody1 => 'Vamos anotar o que você sente no corpo.';

  @override
  String get jv2PhraseBody2 => 'Toque onde você sente desconforto.';

  @override
  String get jv2PhraseBody3 => 'Obrigado por contar. Onde você sente isso?';

  @override
  String get jv2PhraseRegion1 => 'Vamos anotar o que você sente aqui.';

  @override
  String get jv2PhraseRegion2 => 'Entendi. Como é essa sensação?';

  @override
  String get jv2PhraseRegion3 => 'Obrigado por contar. O que combina mais?';

  @override
  String get jv2PhraseRegion4 =>
      'Registrar ajuda você a acompanhar seu dia a dia.';

  @override
  String get jv2PhraseIntensity1 => 'Você escolhe o número. A escala é sua.';

  @override
  String get jv2PhraseIntensity2 =>
      'Não existe resposta certa. Vale o que você sente.';

  @override
  String get jv2PhraseIntensity3 => 'Quase lá. Só mais um pouco.';

  @override
  String get jv2PhraseTriggers1 =>
      'Se quiser, marque o que pode ter contribuído.';

  @override
  String get jv2PhraseTriggers2 => 'É opcional. Você pode pular.';

  @override
  String get jv2PhraseTriggers3 => 'Quase pronto. Algo marcou o seu dia?';

  @override
  String get xv2CropTitle => 'Ajustar foto';

  @override
  String get xv2CropHint =>
      'Use dois dedos para aproximar e arraste para enquadrar.';

  @override
  String get xv2CropReset => 'Recomeçar';

  @override
  String get xv2CropConfirm => 'Usar foto';

  @override
  String xv2GreetingMorning(String name) {
    return 'Olá, $name! Bom dia';
  }

  @override
  String xv2GreetingAfternoon(String name) {
    return 'Olá, $name! Boa tarde';
  }

  @override
  String xv2GreetingEvening(String name) {
    return 'Olá, $name! Boa noite';
  }

  @override
  String get xv2GreetingMorningNoName => 'Olá! Bom dia';

  @override
  String get xv2GreetingAfternoonNoName => 'Olá! Boa tarde';

  @override
  String get xv2GreetingEveningNoName => 'Olá! Boa noite';

  @override
  String get xv2HydrationOfferTitle => 'Quer lembretes para beber água?';

  @override
  String get xv2HydrationOfferBody =>
      'Você escolhe os horários e a sua meta nos ajustes de hidratação. Dá para mudar quando quiser.';

  @override
  String get xv2HydrationOfferYes => 'Sim, configurar';

  @override
  String get xv2HydrationOfferNo => 'Agora não';

  @override
  String get xv2LibTitle => 'Biblioteca';

  @override
  String get xv2LibIntro =>
      'Textos gerais de fontes públicas sobre hábitos saudáveis. São iguais para todas as pessoas e não são orientação para o seu caso.';

  @override
  String xv2LibSource(String source) {
    return 'Fonte: $source';
  }

  @override
  String xv2LibReadTime(int minutes) {
    return '$minutes min de leitura';
  }

  @override
  String get xv2LibOpen => 'Abrir texto';

  @override
  String get xv2LibOpenError => 'Não foi possível abrir o link agora.';

  @override
  String get xv2LibCatEmocoes => 'Emoções e humor';

  @override
  String get xv2LibCatEstresse => 'Estresse e descanso';

  @override
  String get xv2LibCatSono => 'Sono';

  @override
  String get xv2LibCatCorpo => 'Corpo e movimento';

  @override
  String get xv2LibCatAlimentacao => 'Alimentação e digestão';

  @override
  String get xv2LibCatHidratacao => 'Hidratação';

  @override
  String get xv2LibCatRelacoes => 'Relações e convívio';

  @override
  String get xv2LibCatAjuda => 'Primeiros cuidados e quando procurar ajuda';

  @override
  String get xv2LibArtDesanimoTitle => 'Dias de desânimo e pouca energia';

  @override
  String get xv2LibArtDesanimoSummary =>
      'Pequenas rotinas para dias de desânimo e onde encontrar apoio.';

  @override
  String get xv2LibArtAgitacaoTitle => 'Momentos de agitação: como desacelerar';

  @override
  String get xv2LibArtAgitacaoSummary =>
      'Informações gerais sobre nervosismo e pensamentos acelerados no dia a dia.';

  @override
  String get xv2LibArtTrabalhoTitle =>
      'Cansaço no trabalho e limites saudáveis';

  @override
  String get xv2LibArtTrabalhoSummary =>
      'Informações gerais sobre cansaço emocional no trabalho e pausas na rotina.';

  @override
  String get xv2LibArtRespiracaoTitle => 'Respiração compassada para relaxar';

  @override
  String get xv2LibArtRespiracaoSummary =>
      'Alguns minutos de respiração tranquila podem ajudar a desacelerar em dias exigentes.';

  @override
  String get xv2LibArtSonoTitle => 'Hábitos para dormir melhor';

  @override
  String get xv2LibArtSonoSummary =>
      'Horários regulares e hábitos simples que favorecem noites mais tranquilas.';

  @override
  String get xv2LibArtBracosTitle => 'Braços e ombros: pausas e postura';

  @override
  String get xv2LibArtBracosSummary =>
      'Informações gerais sobre esforço repetitivo e pausas durante o dia.';

  @override
  String get xv2LibArtMovimentoTitle => 'Movimente-se no dia a dia';

  @override
  String get xv2LibArtMovimentoSummary =>
      'Orientações gerais sobre atividade física em todas as idades.';

  @override
  String get xv2LibArtAlimentacaoTitle =>
      'Guia Alimentar para a População Brasileira';

  @override
  String get xv2LibArtAlimentacaoSummary =>
      'Princípios gerais para uma alimentação equilibrada, com comida de verdade.';

  @override
  String get xv2LibArtAguaTitle => 'Água ao longo do dia';

  @override
  String get xv2LibArtAguaSummary =>
      'Beber água ao longo do dia faz parte de hábitos de vida saudáveis.';

  @override
  String get xv2LibArtConvivioTitle => 'Bem-estar emocional e convívio';

  @override
  String get xv2LibArtConvivioSummary =>
      'Informações gerais sobre bem-estar emocional, relações e apoio da comunidade.';

  @override
  String get xv2LibArtSamuTitle => 'SAMU 192: como funciona';

  @override
  String get xv2LibArtSamuSummary =>
      'O serviço móvel gratuito do SUS que atende pelo telefone 192 em todo o país.';

  @override
  String get xv2LibArtCvvTitle => 'CVV 188: apoio emocional';

  @override
  String get xv2LibArtCvvSummary =>
      'Conversa gratuita e sigilosa, 24 horas, por telefone, chat ou e-mail.';

  @override
  String xv2ReportedIntensity(int intensity) {
    return 'Intensidade que você informou: $intensity/5';
  }

  @override
  String get xv2SummaryTitle => 'Seu registro de hoje';

  @override
  String get xv2SummarySaved => 'Seu registro foi salvo.';

  @override
  String get xv2SummaryThanks =>
      'Obrigado por registrar seu dia! 🌿 Na Biblioteca você encontra textos de fontes públicas, como o Ministério da Saúde, sobre hábitos saudáveis.';

  @override
  String get xv2SummaryOpenLibrary => 'Abrir a Biblioteca';

  @override
  String get xv2AdLabel => 'Anúncio';

  @override
  String get xv2AdLearnMore => 'Saiba mais';

  @override
  String get xv2AdPremiumTitle => 'Dualis Premium';

  @override
  String get xv2AdPremiumBody =>
      'Veja seus registros de até 12 meses e escolha seus fundos. Em breve.';

  @override
  String get xv2AdZocTitle => 'ZOC · Cadernos e agendas';

  @override
  String get xv2AdZocBody =>
      'Planeje a semana com calma, no papel. Exemplo de anúncio.';

  @override
  String get xv2AdWgiTitle => 'WGI · Garrafas reutilizáveis';

  @override
  String get xv2AdWgiBody => 'Leve sua água para onde for. Exemplo de anúncio.';

  @override
  String get xv2AdUboTitle => 'UBO · Playlists para relaxar';

  @override
  String get xv2AdUboBody =>
      'Sons de natureza para pausas no dia. Exemplo de anúncio.';

  @override
  String get xv2DashTitle => 'Histórico';

  @override
  String xv2DashWindow(int days) {
    return 'Seus registros dos últimos $days dias';
  }

  @override
  String get xv2DashRetry => 'Tentar novamente';

  @override
  String get xv2DashTimeTitle => 'Passado, presente e futuro';

  @override
  String xv2DashTimeCount(String time, int count) {
    return '$time: $count';
  }

  @override
  String get xv2DashNoEmotional => 'Nenhum registro emocional neste período.';

  @override
  String get xv2DashBodyTitle => 'Partes do corpo que você marcou';

  @override
  String get xv2DashFront => 'Frente';

  @override
  String get xv2DashBack => 'Costas';

  @override
  String xv2DashRegionDays(String region, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
      zero: 'nenhum dia',
    );
    return '$region: $_temp0';
  }

  @override
  String get xv2DashLinesTitle => 'Intensidade por dia';

  @override
  String get xv2DashLinesSubtitle =>
      'A intensidade que você informou em cada registro (1 a 5).';

  @override
  String xv2DashDaysCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get xv2DashSeeMore => 'Ver mais';

  @override
  String get xv2DashSeeLess => 'Ver menos';

  @override
  String get xv2DashNoItems => 'Nenhum item registrado neste período.';

  @override
  String get xv2DashWaterTitle => 'Água por dia';

  @override
  String get xv2DashNoWater => 'Nenhum registro de água neste período.';

  @override
  String get xv2DashTogetherTitle => 'No mesmo dia';

  @override
  String xv2DashCooccurrence(int total, String a, String b, int both) {
    return 'Nos $total dias em que você marcou \'$a\', também marcou \'$b\' em $both.';
  }

  @override
  String get xv2DashEntriesTitle => 'Seus registros';

  @override
  String get xv2DashNoEntries => 'Você ainda não tem registros neste período.';

  @override
  String xv2DashMoodLine(String mood) {
    return 'Como você estava: $mood';
  }

  @override
  String get xv2DashDeleteTitle => 'Excluir registro';

  @override
  String get xv2DashDeleteBody =>
      'Este registro será apagado do seu histórico.';

  @override
  String get xv2DashDeleteConfirm => 'Excluir';

  @override
  String get xv2WaterTitle => 'Hidratação 💧';

  @override
  String get xv2WaterTodayLogs => 'Registros de hoje';

  @override
  String get xv2WaterHistoryTitle => 'Últimos 30 dias';

  @override
  String get xv2WaterRemindersTitle => 'Lembretes de água';

  @override
  String get xv2WaterOther => 'Outro';

  @override
  String xv2WaterStreak(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequência: $count dias',
      one: 'Sequência: 1 dia',
      zero: 'Sequência: 0 dias',
    );
    return '$_temp0';
  }

  @override
  String xv2WaterGoalChip(int ml) {
    return 'Sua meta: $ml ml';
  }

  @override
  String get xv2WaterGoalDialogTitle => 'Sua meta diária';

  @override
  String get xv2WaterGoalHint =>
      'Você escolhe a sua meta, entre 250 e 10000 ml.';

  @override
  String get xv2WaterGoalSave => 'Salvar';

  @override
  String get xv2WaterNoLogsToday =>
      'Nenhum copo de água registrado hoje ainda.';

  @override
  String xv2WaterLoggedAt(String time) {
    return 'Registrado às $time';
  }

  @override
  String xv2WaterLoggedViaReminder(String time) {
    return 'Registrado via lembrete das $time';
  }

  @override
  String get xv2WaterDeleteLog => 'Excluir registro';

  @override
  String get jv2PendingSync => 'Aguardando sincronizar';

  @override
  String get jv2OutboxRejectedNotice =>
      'Um registro não pôde ser enviado. Revise e tente de novo.';

  @override
  String get histTabEmotional => 'Psicoemocional';

  @override
  String get histTabPhysical => 'Físico';

  @override
  String histPeriodDays(int days) {
    return '$days dias';
  }

  @override
  String histEmotionalTitle(int days) {
    return 'Seus últimos $days dias';
  }

  @override
  String histPhysicalTitle(int days) {
    return 'Últimos $days dias';
  }

  @override
  String get histIntensitySubtitle => 'Intensidade que você marcou, de 1 a 5';

  @override
  String get histChipHint => 'Toque num chip para mostrar ou esconder a linha.';

  @override
  String histLineShown(String label) {
    return '$label, linha visível';
  }

  @override
  String histLineHidden(String label) {
    return '$label, linha escondida';
  }

  @override
  String histOverlayChip(String label) {
    return '+ $label';
  }

  @override
  String get histTimeBarTitle => 'Passado · Presente · Futuro';

  @override
  String get histViewMap => 'Mapa';

  @override
  String get histViewLinks => 'Conexões';

  @override
  String get histMapCaption =>
      'Cor = quantos dias você marcou. Toque numa parte do corpo para ver a linha do tempo.';

  @override
  String get histNoPhysical => 'Nenhuma parte do corpo marcada neste período.';

  @override
  String histLinksTop(String time, String region, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return 'Mesmo dia: $time e $region em $_temp0. Só contagem.';
  }

  @override
  String get histLinksEmpty =>
      'Ainda não há dias com registro de tempo emocional e de corpo juntos neste período.';

  @override
  String get histTimelineTitle => 'Linha do tempo';

  @override
  String get histEmotionalTitleWeek => 'Como foi sua semana';

  @override
  String get histPhysicalTitleWeek => 'Esta semana';

  @override
  String get histPhysicalTitleMonth => 'Este mês';

  @override
  String histRegionHeadline(int period, String region, num count, num days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vezes',
      one: '1 vez',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return 'Nos últimos $period dias você marcou $region $_temp0, em $_temp1.';
  }

  @override
  String histRegionSensationTimes(String sensation, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vezes',
      one: '1 vez',
    );
    return '$sensation: $_temp0';
  }

  @override
  String get histRegionMarksTitle => 'Cada vez que você marcou';

  @override
  String histRegionIntensity(int value) {
    return 'Intensidade $value de 5';
  }

  @override
  String get histRegionEmpty =>
      'Você não marcou esta parte do corpo neste período.';

  @override
  String get careHubTitle => 'Meus cuidados';

  @override
  String get careHubToday => 'Hoje';

  @override
  String get careHubNoRemindersToday => 'Nenhum lembrete hoje';

  @override
  String careHubRemindersToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lembretes hoje',
      one: '1 lembrete hoje',
    );
    return '$_temp0';
  }

  @override
  String careHubNext(String name, String time) {
    return 'Próximo: $name · $time';
  }

  @override
  String careHubVaccinesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses registradas',
      one: '1 dose registrada',
      zero: 'Nenhuma dose registrada',
    );
    return '$_temp0';
  }

  @override
  String get careHubNone => 'Nenhuma informada';

  @override
  String careHubMedsActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ativos',
      one: '1 ativo',
      zero: 'Nenhum ativo',
    );
    return '$_temp0';
  }

  @override
  String careHubLowStock(int count) {
    return 'estoque baixo em $count';
  }

  @override
  String get careHubNoUpcoming => 'Nenhuma consulta marcada';

  @override
  String careHubNextAppointment(String date, String who) {
    return 'Próxima: $date · $who';
  }

  @override
  String careHubDocuments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos guardados',
      one: '1 documento guardado',
      zero: 'Nenhum documento',
    );
    return '$_temp0';
  }

  @override
  String get careHubSummarySubtitle =>
      'PDF para levar à consulta, se você quiser';

  @override
  String get careVaccinesTitle => 'Vacinas';

  @override
  String get careAllergiesTitle => 'Alergias informadas';

  @override
  String get careMedicationsTitle => 'Medicamentos e lembretes';

  @override
  String get careAppointmentsTitle => 'Consultas';

  @override
  String get careExamsTitle => 'Exames';

  @override
  String get careSummaryTitle => 'Resumo dos meus registros';

  @override
  String get careLoadError =>
      'Não foi possível carregar. Verifique sua conexão.';

  @override
  String get careRetry => 'Tentar de novo';

  @override
  String get careSave => 'Salvar';

  @override
  String get careSaveError => 'Não foi possível salvar. Tente de novo.';

  @override
  String get careFillRequired => 'Preencha os campos obrigatórios.';

  @override
  String get careCancel => 'Cancelar';

  @override
  String get careDelete => 'Apagar';

  @override
  String get careDeleteTitle => 'Apagar este registro?';

  @override
  String get careDeleteBody => 'Ele será removido deste perfil.';

  @override
  String careDays(int count) {
    return '$count dias';
  }

  @override
  String get careMon => 'Seg';

  @override
  String get careTue => 'Ter';

  @override
  String get careWed => 'Qua';

  @override
  String get careThu => 'Qui';

  @override
  String get careFri => 'Sex';

  @override
  String get careSat => 'Sáb';

  @override
  String get careSun => 'Dom';

  @override
  String get careVaccineRegister => 'Registrar dose';

  @override
  String get careVaccineEdit => 'Editar dose';

  @override
  String get careVaccineTabCalendar => 'Calendário oficial';

  @override
  String get careVaccineTabMine => 'Minhas doses';

  @override
  String careVaccineCalendarNote(String source) {
    return '$source (Brasil), mostrado como publicado. Tire dúvidas na sua UBS ou com quem vacina você.';
  }

  @override
  String get carePniChild => 'Criança';

  @override
  String get carePniTeen => 'Adolescente';

  @override
  String get carePniAdult => 'Adulto';

  @override
  String get carePniElderly => '60+';

  @override
  String get carePniPregnant => 'Gestante';

  @override
  String get careVaccineByCampaign => 'Conforme campanha vigente';

  @override
  String careVaccineDosesInCalendar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses no calendário',
      one: 'Dose única no calendário',
    );
    return '$_temp0';
  }

  @override
  String careVaccineBoosterEvery(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anos',
      one: 'ano',
    );
    return 'Reforço a cada $_temp0 no calendário';
  }

  @override
  String careVaccineLastDose(String date) {
    return 'Sua última dose registrada: $date';
  }

  @override
  String get careVaccineNoRecord => 'Sem registro';

  @override
  String careVaccineCount(int count, int total) {
    return '$count de $total';
  }

  @override
  String careVaccineCountOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses',
      one: '1 dose',
    );
    return '$_temp0';
  }

  @override
  String get careVaccineOfficialLink => 'Ver o calendário completo (gov.br)';

  @override
  String get careVaccineEmpty => 'Nenhuma dose registrada ainda.';

  @override
  String careVaccineBatch(String batch) {
    return 'Lote $batch';
  }

  @override
  String careVaccineBoosterReminder(String date) {
    return 'Lembrete de reforço: $date';
  }

  @override
  String get careDose1 => '1ª dose';

  @override
  String get careDose2 => '2ª dose';

  @override
  String get careDose3 => '3ª dose';

  @override
  String get careDoseBooster => 'Reforço';

  @override
  String get careDoseSingle => 'Dose única';

  @override
  String get careDoseYearly => 'Anual';

  @override
  String get careVaccineField => 'Vacina';

  @override
  String get careVaccineCustom => 'Outra (particular)';

  @override
  String get careVaccineCustomName => 'Nome da vacina';

  @override
  String get careVaccineAppliedOn => 'Data da aplicação';

  @override
  String get careVaccineBatchField => 'Lote (opcional)';

  @override
  String get careVaccinePlace => 'Onde (opcional)';

  @override
  String get careVaccineReceipt => 'Comprovante de vacina';

  @override
  String get careVaccineReceiptAdd => 'Foto do comprovante';

  @override
  String get careVaccineReceiptSaved => 'Comprovante guardado';

  @override
  String get careVaccineReceiptHint => 'Fica guardada só no seu registro';

  @override
  String get careVaccineRemindBooster => 'Lembrar do próximo reforço';

  @override
  String get careVaccineBoosterDate => 'Data do lembrete';

  @override
  String careVaccineBoosterHint(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anos',
      one: '1 ano',
    );
    return 'A data vem do intervalo publicado no calendário oficial ($_temp0). Você pode mudar.';
  }

  @override
  String get careVaccineBoosterHintNone =>
      'O calendário não traz intervalo para esta vacina. Escolha a data que quiser.';

  @override
  String get careAllergiesIntro =>
      'O que você já sabe que causa reação em você. Aparece no seu perfil e no resumo em PDF.';

  @override
  String get careAllergiesNoCrossCheck =>
      'O Dualis guarda o que você escreve. Ele não verifica se um medicamento combina com suas alergias. Confirme sempre com quem receita ou com a farmácia.';

  @override
  String get careAllergiesEmpty => 'Nenhuma alergia informada.';

  @override
  String get careAllergyAdd => 'Adicionar alergia';

  @override
  String get careAllergyEdit => 'Editar alergia';

  @override
  String get careAllergyMedication => 'Medicamentos';

  @override
  String get careAllergyFood => 'Alimentos';

  @override
  String get careAllergyOther => 'Outros';

  @override
  String get careAllergyName => 'Nome (como você conhece)';

  @override
  String get careAllergyReaction => 'Reação, com suas palavras (opcional)';

  @override
  String careAllergyReactionShown(String reaction) {
    return 'Reação que você informou: \"$reaction\"';
  }

  @override
  String careAllergyInformedOn(String date) {
    return 'Informado em $date';
  }

  @override
  String get careAllergyInformedField => 'Desde quando (opcional)';

  @override
  String get careAllergyOnProfile => 'Mostrada no cartão de perfil';

  @override
  String get careAllergyShowOnProfile => 'Mostrar no cartão de perfil';

  @override
  String get careAllergyShowOnProfileHint =>
      'Visível para quem você compartilhar o perfil';

  @override
  String get careMedicationAdd => 'Medicamento';

  @override
  String get careMedicationEdit => 'Editar medicamento';

  @override
  String get careMedTabToday => 'Hoje';

  @override
  String get careMedTabAll => 'Todos';

  @override
  String get careMedEmpty => 'Nenhum medicamento cadastrado.';

  @override
  String get careMedNoneToday => 'Nenhum horário para hoje.';

  @override
  String get careMedMorning => 'Manhã';

  @override
  String get careMedAfternoon => 'Tarde';

  @override
  String get careMedNight => 'Noite';

  @override
  String get careMedNote =>
      'Horários e quantidades são os que você configurou, conforme sua receita. O Dualis não sugere nem altera doses.';

  @override
  String careMedStockTitle(String name) {
    return 'Estoque: $name';
  }

  @override
  String careMedStockBody(int count, int warnAt) {
    return 'Restam $count. Você pediu aviso com $warnAt.';
  }

  @override
  String careMedStockLeft(int count) {
    return 'Estoque: $count';
  }

  @override
  String get careMedNoTimes => 'Sem horários';

  @override
  String get careMedPaused => 'Pausado';

  @override
  String get careMedTaken => 'Tomei';

  @override
  String get careMedSnooze => 'Adiar 15 min';

  @override
  String get careMedSkip => 'Pulei';

  @override
  String careMedTakenAt(String time) {
    return 'tomado $time';
  }

  @override
  String get careMedSkipped => 'não tomado';

  @override
  String get careMedSnoozed => 'adiado';

  @override
  String get careMedFromPrescriptionNote =>
      'Preenchido com o que foi lido na receita. Confira tudo e escolha os horários.';

  @override
  String get careMedName => 'Nome (como está na receita ou na caixa)';

  @override
  String get careMedStrength => 'Concentração';

  @override
  String get careMedForm => 'Forma';

  @override
  String get careMedAmount => 'Quanto tomar por vez (da sua receita)';

  @override
  String get careMedInstructions => 'Como está escrito na receita (opcional)';

  @override
  String get careMedTimes => 'Horários';

  @override
  String get careMedAddTime => 'Horário';

  @override
  String get careMedTimesRequired => 'Escolha pelo menos um horário.';

  @override
  String get careMedDays => 'Dias';

  @override
  String get careMedEveryDay => 'Todos os dias';

  @override
  String get careMedUntil => 'Até quando (opcional)';

  @override
  String get careMedStockSection => 'Estoque (opcional)';

  @override
  String get careMedStockHave => 'Em casa';

  @override
  String get careMedStockPerIntake => 'Por vez';

  @override
  String get careMedStockWarn => 'Aviso com';

  @override
  String get careMedBula => 'Bula oficial';

  @override
  String get careMedBulaHint => 'Abre o Bulário Eletrônico da ANVISA';

  @override
  String get careMedBulaNeedsName => 'Escreva o nome do medicamento primeiro.';

  @override
  String get careMedActive => 'Lembretes ativos';

  @override
  String get careMedSave => 'Salvar lembretes';

  @override
  String get careAppointmentAdd => 'Consulta';

  @override
  String get careAppointmentEdit => 'Editar consulta';

  @override
  String get careAppointmentEmpty => 'Nenhuma consulta registrada.';

  @override
  String get careAppointmentUpcoming => 'Próximas';

  @override
  String get careAppointmentPast => 'Anteriores';

  @override
  String get careAppointmentTitleFallback => 'Consulta';

  @override
  String get careAppointmentQuestions => 'Perguntas que quero fazer';

  @override
  String get careAppointmentNotes => 'Minhas anotações';

  @override
  String get careAppointmentDate => 'Data';

  @override
  String get careAppointmentTime => 'Hora';

  @override
  String get careAppointmentProfessional => 'Profissional (opcional)';

  @override
  String get careAppointmentSpecialty => 'Especialidade';

  @override
  String get careAppointmentPlace => 'Local';

  @override
  String get careAppointmentReminderNone => 'Sem lembrete';

  @override
  String get careAppointmentReminder1d => '1 dia antes';

  @override
  String get careAppointmentReminder2h => '2 horas antes';

  @override
  String get careSectionJournal => 'Diário';

  @override
  String get careSectionConditions => 'Condições';

  @override
  String get careSectionMedications => 'Medicamentos';

  @override
  String get careSectionAllergies => 'Alergias';

  @override
  String get careSectionVaccines => 'Vacinas';

  @override
  String get careSectionExams => 'Exames';

  @override
  String get careSectionNotes => 'Notas';

  @override
  String get careSummaryInclude => 'Incluir';

  @override
  String careSummaryJournal(int count) {
    return 'Registros do diário ($count)';
  }

  @override
  String get careSummaryConditions => 'Minhas condições (informadas por você)';

  @override
  String get careSummaryMedications => 'Medicamentos e horários';

  @override
  String get careSummaryNotes => 'Minhas notas';

  @override
  String careSummaryIntensity(int value) {
    return 'intensidade informada $value/5';
  }

  @override
  String careSummaryTaken(int taken, int marked) {
    return '$taken de $marked marcados como tomados';
  }

  @override
  String careSummaryReference(String text) {
    return 'referência impressa: $text';
  }

  @override
  String get careSummaryNothing => 'Nada registrado no período.';

  @override
  String careSummaryMore(int count) {
    return '+ $count no PDF';
  }

  @override
  String careSummaryHeader(String name, String from, String to) {
    return '$name · $from a $to · gerado pela própria pessoa';
  }

  @override
  String get careSummaryFooter =>
      'Este documento reúne apenas o que a pessoa registrou. Não contém avaliação nem recomendação.';

  @override
  String get careSummaryShare => 'Compartilhar PDF';

  @override
  String get careSummaryPrivacy =>
      'O PDF é criado no seu celular. Você decide com quem compartilhar.';

  @override
  String get careExamAdd => 'Adicionar exame';

  @override
  String get careExamFromCamera => 'Tirar foto';

  @override
  String get careExamFromGallery => 'Escolher da galeria';

  @override
  String get careExamFromPdf => 'Escolher PDF';

  @override
  String get careExamWhatIsIt => 'O que é este documento?';

  @override
  String get careExamKindLab => 'Exame de laboratório';

  @override
  String get careExamKindLabHint => 'Lemos os valores para você conferir';

  @override
  String get careExamKindPrescription => 'Receita';

  @override
  String get careExamKindPrescriptionHint =>
      'Lemos nome e instruções para você conferir';

  @override
  String get careExamKindArchive => 'Só arquivar';

  @override
  String get careExamKindArchiveHint => 'Guarda o arquivo sem ler';

  @override
  String get careExamTooLarge => 'O arquivo passa de 10 MB.';

  @override
  String get careExamReading => 'Lendo seu documento…';

  @override
  String get careExamReadingHint =>
      'Leva até 1 minuto. Você pode sair desta tela.';

  @override
  String get careExamEmpty => 'Nenhum documento guardado.';

  @override
  String get careExamSectionLabs => 'Exames';

  @override
  String get careExamSectionPrescriptions => 'Receitas';

  @override
  String get careExamSectionOther => 'Outros arquivos';

  @override
  String get careExamValuesOverTime => 'Meus valores ao longo do tempo';

  @override
  String get careExamNote =>
      'Os valores e as referências são os do laudo. O Dualis não diz se um resultado está bom ou ruim. Leve suas dúvidas a quem pediu o exame.';

  @override
  String careExamToCheck(int count) {
    return 'Conferir $count';
  }

  @override
  String get careExamCheck => 'Conferir';

  @override
  String get careExamChecked => 'Conferido';

  @override
  String get careExamReadFailed => 'Não lido';

  @override
  String get careExamArchived => 'Arquivado';

  @override
  String get careExamReviewTitle => 'Conferir valores';

  @override
  String get careExamSeeOriginal => 'Ver documento original';

  @override
  String get careExamCompareHint =>
      'Compare com o papel. Toque numa linha para corrigir.';

  @override
  String get careExamArchivedHint => 'Guardado sem leitura.';

  @override
  String get careExamFailedHint =>
      'Não conseguimos ler este arquivo. Você pode digitar os valores ou tentar outra foto, com boa luz e o papel inteiro.';

  @override
  String get careExamTitleField => 'Nome do exame';

  @override
  String get careExamLab => 'Laboratório';

  @override
  String get careExamCollected => 'Data da coleta';

  @override
  String get careExamItem => 'Item';

  @override
  String get careExamValue => 'Valor';

  @override
  String get careExamUnit => 'Unidade';

  @override
  String get careExamDate => 'Data';

  @override
  String get careExamReference => 'Referência impressa no laudo';

  @override
  String get careExamReferencePrinted => 'Referência impressa';

  @override
  String get careExamNoRows =>
      'Nenhum valor lido. Adicione as linhas que quiser guardar.';

  @override
  String get careExamAddRow => 'Adicionar linha';

  @override
  String get careExamEditRow => 'Corrigir linha';

  @override
  String get careExamRowSave => 'Confirmar linha';

  @override
  String get careExamRowRemove => 'Remover linha';

  @override
  String careExamSavePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conferências',
      one: '1 conferência',
    );
    return 'Salvar (faltam $_temp0)';
  }

  @override
  String get careExamSaved => 'Valores guardados.';

  @override
  String get careExamItemIntro =>
      'Valores que você conferiu, do mais recente ao mais antigo. A referência é a que cada laboratório imprimiu.';

  @override
  String get careReadConsentTitle => 'Ler documentos com o Google';

  @override
  String get careReadConsentBody =>
      'Para ler a foto ou o PDF, o arquivo é enviado ao Google Cloud Vision, que extrai o texto em servidores nos Estados Unidos ou na União Europeia. Depois, a Gemini (região São Paulo) organiza esse texto, sem seu nome nem CPF. O Google não usa esses dados para treinar modelos.\n\nIsso é uma transferência internacional de dados de saúde (LGPD Art. 33; RGPD Art. 46). Você pode recusar e usar \"Só arquivar\" ou digitar os valores. Pode retirar este consentimento na Central de Privacidade.';

  @override
  String get careReadConsentAccept => 'Concordo';

  @override
  String get careReadConsentDecline => 'Agora não';

  @override
  String get careRxTitle => 'Conferir receita';

  @override
  String get careRxCompareHint =>
      'Compare com a receita. Toque num campo para corrigir.';

  @override
  String get careRxNothingRead => 'Nenhum medicamento lido.';

  @override
  String get careRxName => 'Nome lido';

  @override
  String get careRxStrength => 'Concentração lida';

  @override
  String get careRxInstructions => 'Como tomar (texto da receita)';

  @override
  String get careRxEditField => 'Corrigir campo';

  @override
  String careRxFieldLabel(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'name': 'Nome',
      'strength': 'Concentração',
      'other': 'Como tomar',
    });
    return '$_temp0';
  }

  @override
  String get careRxTimesYouChoose =>
      'Os horários você escolhe no próximo passo.';

  @override
  String get careRxCheckFirst => 'Confira todos os campos';

  @override
  String get careRxCreateReminder => 'Criar lembrete';

  @override
  String get careRxReminderCreated => 'Lembrete criado';

  @override
  String get careRxNote =>
      'O Dualis copia o texto da receita. Ele não transforma \"12/12h\" em horários nem cria lembretes sozinho.';

  @override
  String get careNotifChannelName => 'Lembretes de cuidados';

  @override
  String get careNotifChannelDescription =>
      'Horários de medicamentos, consultas e reforços de vacina que você configurou.';

  @override
  String get careNotifMedTitle => 'Hora do seu lembrete';

  @override
  String get careNotifAppointmentTitle => 'Lembrete de consulta';

  @override
  String careNotifAppointmentBody(String who, String time) {
    return '$who às $time';
  }

  @override
  String get careNotifBoosterTitle => 'Lembrete de vacina';

  @override
  String careNotifBoosterBody(String name) {
    return 'Data que você escolheu para o reforço: $name';
  }

  @override
  String get careMedicationNew => 'Novo medicamento';
}
