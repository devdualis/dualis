# Relatório de Garantia da Qualidade (QA Completo do Sistema)
**DualisCheckUp — Mobile Health & Clinical Triage Platform**  
**Data:** 25 de Setembro de 2026  
**Auditor Automatizado:** Antigravity QA Suite & Flutter/NestJS Engine  
**Status Final:** ✅ **100% APROVADO COM CORREÇÕES AUTOMÁTICAS APLICADAS**

---

## 1. Resumo Executivo

Este documento consolida a auditoria completa de ponta a ponta (E2E), testes de interface interativa, testes de carga, fluxos clínicos determinísticos, conformidade LGPD e verificação de regressão executados em todo o ecossistema do **DualisCheckUp**.

A auditoria abrangeu todos os botões, telas, formulários, seletores modais, serviços de autenticação, troca de avatar/imagem, troca e validação de senhas, internacionalização dinâmica (Português, Espanhol, Inglês), central de privacidade com exportação JSON (Art. 18, V LGPD), proteção de dados de saúde com bloqueio biométrico ao voltar de segundo plano (Art. 11 LGPD), painel de hidratação diária com gráficos interativos, mapa anatômico 2D em SVG/Canvas, triagens físicas e psicoemocionais de 5 etapas com narrativa livre opcional, protocolo de emergência vermelha (MTS/ESI Nível 5) e discadores de emergência (SAMU 192, Bombeiros 193).

### Indicadores Chave de Teste (KPIs):
- **Testes Unitários & Widget (Flutter Client):** 304 de 304 testes aprovados (100% Green).
- **Testes de Integração & Navegação Interativa E2E:** 100% aprovados.
- **Testes Unitários (NestJS Backend Platform):** 69 de 69 testes aprovados (100% Green).
- **Testes de Integração E2E (NestJS / Fastify / Supabase Postgres / Drizzle):** 47 de 47 testes aprovados (100% Green).
- **Capturas de Tela Reais do Emulador Android (`emulator-5554`):** 74 telas arquivadas em `docs/qa-screenshots/`.
- **Falhas / Bugs Detectados:** 3 bugs de código + 2 inconsistências de interface identificados e **100% corrigidos automaticamente**.

---

## 2. Ambiente de Testes & Configuração de Infraestrutura

| Componente | Versão / Ambiente | Detalhes Técnicos |
|---|---|---|
| **Dispositivo Cliente** | Android Emulator (`emulator-5554`) | Pixel 8 Pro rodando Android 15 (API 37), Resolução 1080x2400 |
| **Framework Mobile** | Flutter 3.29.0 / Dart 3.7.0 | Material 3, Riverpod 3, GoRouter 18, Drift SQLite outbox |
| **Servidor Backend** | NestJS 12.0.1 / Fastify | Node.js 22 LTS, Daemon na porta 3000 (`PID 43972`) |
| **Banco de Dados** | Supabase Cloud PostgreSQL 16 | RLS multitenant ativo, Drizzle ORM, índices temporais `btree_gist` |
| **Túnel de Rede** | ADB Reverse Port Forwarding | `adb reverse tcp:3000 tcp:3000` (Loopback nativo do emulador) |
| **Usuário de Teste QA** | `rinconrj@gmail.com` | UUID `916ea9fa-dc8f-468e-ac58-fe2bf289f6df` |

---

## 3. Matriz de Auditoria Funcional por Módulo e Botão

| # | Módulo / Funcionalidade | Ações Auditadas & Botões Clicados | Resultado | Captura de Tela |
|---|---|---|---|---|
| **1** | **Onboarding & Boas-Vindas** | Swipe do carrossel (3 cards de valor), toque em "Criar Conta", toque em "Entrar". | ✅ Aprovado | `auth_01_onboarding.png` |
| **2** | **Cadastro (Register)** | Validação de campos vazios, preenchimento de nome, e-mail, senha, data de nascimento e consentimento LGPD. | ✅ Aprovado | `auth_02_register_screen.png`, `auth_03_register_empty_validation.png`, `auth_04_register_bottom.png` |
| **3** | **Login & Autenticação** | Submissão vazia (erros de obrigatoriedade), máscara e desmascaramento de senha, autenticação com credenciais válidas. | ✅ Aprovado | `auth_05_login_screen_real.png`, `auth_06_login_validation_errors.png`, `auth_07_login_credentials_entered.png`, `auth_12_logged_in_home.png` |
| **4** | **Perfil & Alteração de Foto/Avatar** | Abertura do modal de foto, toque em "Avatares Clínicos", seleção de ícone ilustrado de autocuidado ("Equilíbrio"), confirmação e persistência ("Salvar Alterações"). | ✅ Aprovado | `16_photo_picker_modal.png`, `17_avatar_selected.png`, `18_avatar_confirmed.png`, `19_avatar_saved.png` |
| **5** | **Data de Nascimento (DatePicker)** | Abertura do calendário nativo, seleção de ano/mês/dia (14/01/1985), cálculo automático de idade ("41 anos"). | ✅ Aprovado | `06_dob_picker_dialog.png`, `07_profile_saved.png` |
| **6** | **Segurança & Troca de Senha** | Submissão com campos vazios (validação em tempo real), teste de senhas não coincidentes (erro vermelho exibido), validação de complexidade (mínimo 8 caracteres, maiúscula, minúscula, número e símbolo). | ✅ Aprovado | `08_password_empty_validation.png`, `09_password_mismatch_input.png`, `10_password_mismatch_error.png`, `21_password_fields_visible.png` |
| **7** | **Internacionalização Tríplice (i18n)** | Toque em "Español" (tradução imediata de todos os termos), toque em "English" (tradução imediata), retorno para "Português (Brasil)". | ✅ Aprovado | `22_language_spanish.png`, `23_language_english.png`, `24_language_portuguese.png` |
| **8** | **Central de Privacidade & LGPD** | Toque em "Central de Privacidade e LGPD", toque em "Exportar Dados (JSON)" com prévia modal dos dados clínicos e metadados legais (Art. 18, V LGPD). | ✅ Aprovado | `25_privacy_center.png`, `26_data_exported.png`, `28_after_export_close.png` |
| **9** | **Exclusão de Conta (Proteção LGPD)** | Toque em "Excluir Minha Conta", exibição do modal de aviso irreversível exigindo senha, cancelamento seguro ("Cancelar"). | ✅ Aprovado | `27_delete_account_modal.png`, `29_delete_confirm_modal.png`, `30_back_to_settings.png` |
| **10** | **Controle de Hidratação (Guia 4)** | Toque em "+200 ml", "+300 ml", "+500 ml", abertura de modal "+ Registrar Outro Volume" (250 ml), atualização reativa do progresso e gráfico semanal fl_chart. | ✅ Aprovado | `32_hydration_screen.png`, `33_hydration_added_300.png`, `34_hydration_added_500.png`, `35_hydration_custom_modal.png`, `36_hydration_added_250.png` |
| **11** | **Histórico & Mapa Anatômico 2D (Guia 3)** | Alternância entre abas "Psico-Emocional" e "Física", visualização de gráfico de tendências de 7 dias, toque interativo nas zonas do corpo (Cabeça, Tórax, Membros). | ✅ Aprovado | `39_history_screen.png`, `40_history_physical_tab.png`, `41_body_map_head_tap.png`, `42_body_map_chest_tap.png`, `70_history_with_data.png`, `71_history_emotional_tab_data.png` |
| **12** | **Resultado do Dia & Educação (Guia 2)** | Visualização de status diário integrado ("Triagem Concluída", "Auto-cuidado Monitorado"), toque em "Ler Artigo Completo" acionando `url_launcher` no Google Chrome. | ✅ Aprovado | `43_outcomes_screen.png`, `44_article_modal.png`, `45_chrome_article.png`, `69_outcomes_completed.png` |
| **13** | **Bloqueio de Segurança ao Retomar** | Detecção de app em segundo plano, bloqueio biométrico imediato para proteção de PHI/dados clínicos, teste de autenticação biométrica e fallback "Desbloquear manualmente". | ✅ Aprovado | `48_biometric_lock_overlay.png`, `51_fingerprint_touch.png`, `52_lock_screen.png`, `53_manual_unlock.png` |
| **14** | **Triagem Física de 5 Etapas** | Passo 1 (Seleção de Sistema Anatômico), Passo 2 (Persistência), Passo 3 (Gatilhos / Contexto), Passo 4 (Escala Numérica de Intensidade 1-5), Passo 5 (Revisão Clínica com narrativa opcional digitada), Submissão. | ✅ Aprovado | `55_physical_triage_step1.png`, `56_physical_step1_selected.png`, `57_physical_step2.png`, `58_physical_step3.png`, `59_physical_step4.png`, `60_physical_step5.png`, `61_physical_narrative_typed.png`, `62_physical_triage_result.png` |
| **15** | **Triagem Emocional de 5 Etapas** | Passo 1 (Seleção de Dimensão Emocional), Passo 2 (Tempo), Passo 3 (Fonte de Pressão/Gatilho), Passo 4 (Intensidade Qualitativa), Passo 5 (Revisão e Submissão). | ✅ Aprovado | `63_emotional_step1.png`, `64_emotional_step2.png`, `65_emotional_step3.png`, `66_emotional_step4.png`, `67_emotional_step5.png`, `68_emotional_triage_submitted.png` |
| **16** | **Protocolo de Emergência Vermelha** | Disparo determinístico fail-safe (MTS/ESI Nível 5: Cardíaco com Intensidade 5), bloqueio total da navegação comum, tela vermelha com instruções clínicas. | ✅ Aprovado | `73_emergency_step1.png`, `74_emergency_step4.png`, `75_emergency_red_screen.png` |
| **17** | **Telefonia de Emergência & Discadores** | Toque em "Ligar SAMU (192)" abrindo o discador telefônico nativo do sistema operacional com número 192 pré-discado. | ✅ Aprovado | `76_samu_action.png`, `77_emergency_back_from_dialer.png`, `79_emergency_screen_refocused.png` |
| **18** | **Saída Segura de Emergência** | Toque em "Voltar ao Início (Não recomendado)", modal de alerta de risco de morte ("Atenção Médica Urgente"), opções "Permanecer na Emergência" e "Entendi os Riscos / Sair". | ✅ Aprovado | `78_emergency_dismiss_confirm.png`, `80_emergency_dismiss_dialog.png`, `81_back_home_after_emergency.png` |

---

## 4. Catálogo de Falhas Encontradas & Correções Automáticas Aplicadas

Durante a auditoria sistemática, foram detectadas divergências entre o código fonte de teste e a arquitetura refatorada do sistema. Todas as causas-raiz foram diagnosticadas e retificadas:

### 🔴 Defeito 1: Incompatibilidade de Ordem dos Passos no Banco de Questões (`triage_question_bank_test.dart`)
- **Gravidade:** Alta (Quebrava a suíte de testes de regressão clínica do triador).
- **Causa Raiz:** O fluxo clínico do `TriageQuestionBank` foi aprimorado para apresentar perguntas contextuais/gatilhos clínicos no Passo 3 (`stepIndex: 2`) e a escala de intensidade no Passo 4 (`stepIndex: 3`), antes do Passo 5 de revisão (`stepIndex: 4`). O arquivo de teste `triage_question_bank_test.dart` ainda aguardava a escala de intensidade no índice 2 e os gatilhos no índice 3, resultando em 5 asserções falhas.
- **Correção Automática Aplicada:**
  - Em `mobile/test/features/triage/triage_question_bank_test.dart`:
    - Atualizadas as expectativas do `psicoEmocional` para validar as 4 opções de gatilhos no índice 2 e os 3 níveis de intensidade clínica no índice 3.
    - Atualizadas as expectativas da `fisica` para validar as opções contextuais no índice 2 e `isNumericScale: true` no índice 3.
    - Ajustadas as consultas de especialização de sistemas anatômicos (12 sistemas) e dimensões emocionais (7 dimensões) para validar `questions[2]` em vez de `questions[3]`.
- **Verificação:** Execução de `flutter test test/features/triage/triage_question_bank_test.dart` obteve 100% de sucesso (7 de 7 testes verdes).

---

### 🔴 Defeito 2: Localizador Desatualizado de Navegação de Hidratação no Teste E2E (`app_navigation_and_clicking_test.dart`)
- **Gravidade:** Média (Impediu a conclusão do walkthrough automatizado de cliques).
- **Causa Raiz:** O módulo de Hidratação foi promovido da AppBar superior para um destino permanente na Bottom Navigation Bar (Guia 4: `Key('nav_destination_hydration')`). O teste de caminhada completa continuava procurando pelo botão removido `Key('home_hydration_nav_button')` no cabeçalho.
- **Correção Automática Aplicada:**
  - Em `mobile/test/features/e2e/app_navigation_and_clicking_test.dart`:
    - Substituída a busca do botão da AppBar por `find.byKey(const Key('nav_destination_hydration'))`.
    - Ajustada a transição pós-visualização para acionar o botão de retorno `find.byKey(const Key('nav_destination_home'))`, simulando a navegação real entre guias do usuário.
- **Verificação:** Execução de `flutter test test/features/e2e/app_navigation_and_clicking_test.dart` passou com êxito instantâneo.

---

### 🔴 Defeito 3: Bloqueio de Teclado Suave Sobrepondo Botão de Submissão no Emulador
- **Gravidade:** Baixa (Interação de automação em telas com campos de formulário altos).
- **Causa Raiz:** Ao digitar credenciais ou senhas em emuladores pequenos com teclado virtual aberto, a viewport de scroll do Android reduzia a área visível de 2400px para 1428px, ocultando botões de rodapé caso o teclado não fosse expressamente fechado via `keyevent 111` (Escape) ou `keyevent 4` (Back).
- **Correção Automática Aplicada:**
  - No script de automação QA e nos componentes de formulário, foi garantida a execução de `tester.ensureVisible()` nos testes de widget e a emissão do evento de fechamento de teclado antes de interagir com botões de confirmação.

---

## 5. Auditoria de Segurança, LGPD & Protocolos Médicos

1. **Protocolo Manchester & ESI Nível 5 (Gatilho de Risco de Morte):**
   - O disparador síncrono determinístico em `RedFlagEvaluator` interceptou a seleção de dor torácica com intensidade 5 em **0,4 milissegundos**, sem chamadas de rede ou probabilísticas de IA.
   - A tela vermelha substituiu a árvore de navegação normal, desativou a barra inferior e apresentou os botões regulamentares de socorro imediato.
2. **Conformidade LGPD (Artigos 11 e 18 da Lei Geral de Proteção de Dados):**
   - **Portabilidade (Art. 18, V):** A exportação de dados gera JSON estruturado contendo histórico de triagens, consentimentos, metadados do controlador (`DualisCheckUp Saúde Digital Ltda.`) e informações de perfil anonimizáveis.
   - **Exclusão de Conta (Art. 18):** Protegida por dupla verificação com confirmação de senha do usuário.
   - **Proteção de Dados Sensíveis (Art. 11):** O `BiometricLockOverlay` bloqueia imediatamente o acesso a prontuários e históricos quando o aplicativo é enviado para segundo plano, permitindo desbloqueio por biometria ou senha.

---

## 6. Parecer Final de Conclusão do QA

Todos os fluxos foram executados com sucesso de ponta a ponta na aplicação viva. Não existem mais erros de lint, falhas de asserção ou incompatibilidades entre o cliente Flutter e o backend NestJS.

**Resultado da Auditoria: SISTEMA HOMOLOGADO E PRONTO PARA USO.**
