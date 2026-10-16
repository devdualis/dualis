# Auditoría de Uso Previsto (Intended Use) — DualisCheckUp

**Fecha:** 2026-10-15 · **Rama auditada:** `feat/phase-11-multi-profile` (incluye cambios sin commit) · **Alcance:** solo lectura de `mobile/`, `backend/`, `.planning/`, `.agents/`, `CLAUDE.md`.

> **Aviso:** esto no es asesoría legal ni regulatoria. Es un análisis técnico de producto contra el texto público de las normas citadas. Un consultor regulatorio (ANVISA / MDR / FDA) y un abogado de protección de datos deben confirmarlo antes del lanzamiento. Donde hay juicio propio lo marco como **[Juicio]**.

### Normas en las que me apoyo

| Región | Norma | Qué uso de ella |
|---|---|---|
| BR | ANVISA **RDC 657/2022** (SaMD) | Ámbito: software con finalidad médica (diagnóstico, prevención, monitoreo, tratamiento de enfermedad). Excluye de su ámbito el software destinado a **bienestar** (verificar numeración exacta del artículo de exclusiones con el consultor). |
| BR | ANVISA **RDC 751/2022** (clasificación de dispositivos médicos, Clases I–IV) | Reglas de clasificación del Anexo I; el software que alimenta decisiones diagnósticas/terapéuticas o de urgencia cae en clases de riesgo intermedio/alto. |
| EU | **MDR 2017/745**, Art. 2(1), Art. 2(12) y **Anexo VIII Regla 11** | Software que da información para decisiones con fines diagnósticos/terapéuticos = IIa; si la decisión puede causar deterioro grave = IIb; muerte/daño irreversible = III. Art. 2(12): el uso previsto se deduce de etiquetado, instrucciones, **material promocional y documentación técnica**. |
| EU | **MDCG 2019-11** (cualificación y clasificación de software) | Árbol de decisión: (a) ¿realiza una acción sobre los datos distinta de almacenar/archivar/comunicar/búsqueda simple? (b) ¿es en beneficio de un paciente individual? (c) ¿finalidad médica del Art. 2(1)? Si sí → MDSW. |
| EU | **AI Act (Reg. 2024/1689)** | Si el producto es MDSW clase IIa+ sujeto a organismo notificado, el componente de IA pasa a ser de **alto riesgo** (Art. 6(1) + Anexo I). Motivo extra para quedarse en bienestar. |
| US | FDA **General Wellness: Policy for Low Risk Devices** | Categoría 1: mantener/estimular un estado general de salud **sin referencia a enfermedades o condiciones**. Categoría 2: estilo de vida saludable para reducir riesgo de enfermedades crónicas bien establecidas. Fuera de eso → no es wellness. (FDA revisó esta guía y la de CDS recientemente; confirmar versión vigente.) |
| US | FDA **Clinical Decision Support Software** | Los 4 criterios del 520(o)(1)(E) FD&C Act. El criterio 3 exige que el usuario sea **profesional de salud**: CDS orientado a pacientes/legos **no** queda excluido de la definición de dispositivo. |
| US | FDA **Policy for Device Software Functions and Mobile Medical Apps** | Lista de funciones bajo *enforcement discretion* (p. ej. apps que ayudan a autogestionar sin dar recomendaciones de tratamiento específicas; checklists de síntomas con consejo genérico de cuándo consultar). **[Juicio]**: es la única vía por la que el flujo actual podría tolerarse en US, y el bloque de emergencia/IA lo aleja de ella. |
| US | FTC **Health Breach Notification Rule** (16 CFR 318, enmienda 2024) + FTC Act §5 | Apps de salud = vendor de PHR; "breach" incluye divulgación no autorizada (SDKs, IA de terceros). §5: afirmaciones de salud engañosas o sin sustento. |
| Stores | Apple **App Review Guideline 1.4.1** (+ 5.1.1/5.1.3) | Apps médicas que pueden dar datos inexactos se revisan con más rigor; deben divulgar metodología y, si hacen diagnóstico/tratamiento, acreditar autorización regulatoria. Datos de salud no pueden usarse para publicidad. |
| Stores | Google Play **Health apps policy** + Health apps declaration | Declarar la categoría; si no es dispositivo médico regulado, incluir disclaimer claro; afirmaciones médicas engañosas = rechazo. |

---

## 1. Veredicto (5 líneas)

1. **Brasil — riesgo ALTO.** Tal como está, el producto encaja en la definición de SaMD de la RDC 657/2022 (prevención/triaje individual con disposición asistencial) y los propios Términos lo declaran "classificada conforme a RDC 657/2022"; por RDC 751/2022 probablemente Clase II–III **[Juicio]**.
2. **UE — riesgo ALTO.** Pasa los tres pasos del MDCG 2019-11 (procesa datos, por paciente individual, finalidad de triaje); por Regla 11 al menos **IIa**, con argumento fuerte para **IIb** porque decide "Emergência / Pronto Atendimento" **[Juicio]**; arrastra además el AI Act de alto riesgo.
3. **EE. UU. — riesgo MEDIO-ALTO.** No es General Wellness (nombra infarto, AVC, crisis suicida, "emergência"); es CDS orientado a pacientes, que no cumple el criterio 3; la *enforcement discretion* para "symptom checkers" es discutible por la detección algorítmica de emergencias y la IA **[Juicio]**.
4. **Stores:** con el copy actual ("Triagem", "Resultado da Triagem", "Artigos Médicos", "classificação clínica") Apple 1.4.1 pedirá prueba de autorización regulatoria o rechazará.
5. **Driver único más grande:** la **disposición asistencial personalizada** (`intensidade × sistema → Auto-cuidado / Consulta / Pronto Atendimento / Emergência`) más el **interceptor de emergencias tipo Manchester/ESI**, en `backend/src/modules/triage/services/triage-outcome.service.ts:702-718` y `mobile/lib/features/emergency/domain/red_flag_evaluator.dart:130-152`. Sin eso, el resto se arregla mayormente con copy.

---

## 2. Declaración de uso previsto propuesta

**pt-BR**
> O DualisCheckUp é um aplicativo de bem-estar e autoconhecimento. Ele ajuda você a registrar diariamente como se sente física e emocionalmente, acompanhar hábitos como hidratação e sono, visualizar seus próprios registros ao longo do tempo e acessar conteúdos educativos gerais sobre hábitos saudáveis. O DualisCheckUp não é um dispositivo médico: não avalia, não classifica nem interpreta sintomas, não indica nível de urgência, não faz diagnóstico, não recomenda tratamento e não substitui um profissional de saúde. Em caso de emergência, ligue 192 (SAMU). Se você estiver em sofrimento emocional, ligue 188 (CVV).

**en**
> DualisCheckUp is a wellness and self-awareness app. It helps you keep a daily journal of how you feel physically and emotionally, track habits such as hydration and sleep, view your own entries over time, and access general educational content about healthy habits. DualisCheckUp is not a medical device: it does not assess, classify or interpret symptoms, does not indicate urgency levels, does not diagnose, does not recommend treatment and does not replace a healthcare professional. In an emergency, call your local emergency number. If you are in emotional distress, contact your local crisis line.

Este texto debe ser idéntico en: Términos, onboarding, ficha de App Store / Google Play, sitio web, pitch deck, `PROJECT.md`, `CLAUDE.md` y docs de agentes. Para el regulador el uso previsto se deduce de **todos** esos materiales (MDR Art. 2(12); FDA 21 CFR 801.4 "objective intent").

---

## 3. Hallazgos

Convenciones: claves `.arb` citadas con su línea en `app_pt.arb`; la misma clave existe en `app_en.arb` / `app_es.arb` y debe cambiarse igual. "Hardcoded" = string pt-BR fuera de l10n (además hay que moverlo a l10n).

### 3.1 Lógica clínica y comportamiento (lo que realmente define la clasificación)

| id | área | file:line | actual | riesgo | acción | cambio concreto |
|---|---|---|---|---|---|---|
| B-01 | Disposición asistencial | `backend/src/modules/triage/services/triage-outcome.service.ts:702-718` | `intensity ≤2 → auto_cuidado; 3 → consulta_rotina; 4 → pronto_atendimento; 5 → emergencia`; primacía orgánica sube a consulta; `isEmergencyCandidate` fuerza `emergencia`. | Alto | REMOVE | Eliminar `careDisposition` del cálculo y de la respuesta. Ningún output individual de "qué nivel de atención necesitas". Sustituir por un bloque **estático igual para todos** (ver S-03). Mantener la columna en BD solo si hay datos históricos; dejar de escribirla. |
| B-02 | Check-in rápido → disposición | `triage-outcome.service.ts:833-840` | `badSick` ⇒ `intensity=4`, `pronto_atendimento`; `soSo` ⇒ `consulta_rotina`. Un "me siento mal" se convierte en recomendación de pronto atención. | Alto | REMOVE | Guardar solo el estado auto-reportado (`bem/mais ou menos/mal`). Sin intensidad inferida ni disposición. |
| B-03 | Interceptor de emergencias estructurado | `mobile/lib/features/emergency/domain/red_flag_evaluator.dart:130-152` (+ `triage_wizard_notifier.dart:92-103`) | Doc dice "Manchester/ESI Level 4–5 criteria … MTS Red / ESI 1"; intensidad 4 en sistemas "vitales" o 5 en cualquiera ⇒ pantalla roja bloqueante. | Alto | REFRAME | Quitar la decisión algorítmica "esto es una emergencia". Si el usuario marca intensidad 5 (o 4 en pecho/respiración/neurológico) mostrar un **aviso no bloqueante e idéntico para todos** con la lista estática de señales de alarma y botones 192/188 (S-02). Sin badges de "Dor Torácica Crítica", sin "Nível 4–5", sin `PopScope(canPop:false)`. Eliminar referencias MTS/ESI de comentarios. |
| B-04 | Interceptor por texto libre (regex) | `red_flag_evaluator.dart:14-60, 68` | Regex de infarto, AVC, vía aérea, cefalea en trueno, suicidio ⇒ pantalla roja con badge diagnóstico ("Suspeita de Déficit Neurológico (AVC)"). | Alto (físico) / Bajo (suicidio) | REFRAME | **Suicidio/autolesión: KEEP** como "safety net" de contenido (práctica estándar de plataformas, no es diagnóstico) **[Juicio]** — mostrar recursos de crisis (188/192) sin bloquear. **Físico:** mantener la detección solo para disparar el **mismo** aviso genérico ("Se isso for uma emergência, ligue 192 agora"), nunca nombrar la condición sospechada. |
| B-05 | IA: esquema de respuesta | `backend/src/modules/ai/services/ai-triage.service.ts:34-54` | Campos `urgencyScore` (1–5), `clinicalConcept`, `isEmergencyCandidate`. | Alto | REMOVE | Esquema nuevo: `{ isOffTopic, vertical, bodyAreaOrMood, layTerm, mentionsSelfHarm }`. Sin urgencia, sin concepto médico, sin candidato a emergencia. |
| B-06 | IA: prompt | `ai-triage.service.ts:111-120` | "Você é o motor de triagem médica preventiva … conceito médico formal … critérios Manchester/ESI nível 1-2". | Alto | REFRAME | Prompt de **etiquetado de diario**: "Você organiza anotações de um diário de bem-estar. Identifique a área do corpo ou o estado emocional mencionado e o termo usado pela pessoa. Não avalie gravidade, não sugira diagnóstico nem conduta. Marque `mentionsSelfHarm` se o texto mencionar desejo de se ferir ou morrer." Además, pasar `dto.text` como contenido separado (no interpolado) para mitigar prompt injection. |
| B-07 | IA: aprendizaje continuo | `ai-triage.service.ts:146`, `symptom-vector.service.ts` | Cada clasificación de Gemini se inserta en la base vectorial y "aprende con el tiempo". | Medio | REFRAME | Aceptable como cache de etiquetado si se aplica B-05. Si alguna vez fuera dispositivo, un algoritmo adaptativo exige plan de cambios predeterminado (PCCP) — otro motivo para no clasificar urgencia. |
| B-08 | Seed de conocimiento | `backend/src/modules/ai/data/symptom-knowledge.seed.ts:20-53…` | Entradas con `urgencyScore: 5`, `isEmergencyCandidate: true`. | Medio | REFRAME | Borrar los campos de urgencia/emergencia del seed; conservar mapeo término→área. |
| B-09 | Primacía orgánica | `triage-outcome.service.ts:633-690`; mobile `triage_outcome_controller.dart:157,234`; `organic_primacy_banner.dart:43,53`; `triage_outcome_remote_data_source.dart:429-453`; `triage_history_detail_modal.dart:322`; `.arb` `outcomeOrganicPrimacyTitle/Desc` (`app_pt.arb:924-928`) | Razonamiento diferencial: "exigem avaliação clínica para descartar causas orgânicas primárias", "somatização". | Alto | REFRAME | Eliminar el banner condicional. Si el usuario registra físico + emocional el mismo día, mostrar nota estática: **"Você registrou sensações no corpo e nas emoções hoje. Se algum desconforto físico persistir ou piorar, converse com um profissional de saúde."** Sin "orgânica", "somatização", "descartar". |
| B-10 | Escala "clínica" e intensidad "calculada" | `backend/src/modules/triage/constants/intensity-tier.constant.ts:1-95` (`ClinicalIntensityTier`, `isCritical`); `.arb` `outcomeIntensityTitle/Description` (`app_pt.arb:880-884`); `intensity_meter.dart:42,72` | "Intensidade Calculada", "escala clínica de 1 a 5", tier `isCritical`. | Medio | REFRAME | La intensidad es **auto-reportada**; decirlo así. `outcomeIntensityTitle`: **"Intensidade que você informou"**; `outcomeIntensityDescription`: **"Sua própria nota de 1 a 5 para como se sentiu"**. Renombrar `ClinicalIntensityTier`→`SelfReportedIntensityBand`, quitar `isCritical`. |
| B-11 | Recurrencia "crítica" | `backend/src/modules/triage/services/triage-history.service.ts:423-500` (texto en `:454-455`, `:489-490`); `mobile/.../critical_recurrence_card.dart`; `.arb` `criticalRecurrenceTitle` (`app_pt.arb:1067`) | ≥2 registros intensidad ≥4 en 10 días ⇒ "Foco de Atenção … desconforto severo". | Medio | REFRAME | Mantener como **insight de diario** sin juicio clínico. Título: **"Padrões nos seus registros"**. Texto: **"Você registrou {categoria} com intensidade alta {n} vezes nos últimos 10 dias. Se isso está atrapalhando seu dia a dia, pode ser útil conversar com um profissional de saúde."** Renombrar `CriticalRecurrenceDto`→`JournalPatternDto`. |
| B-12 | Antiburla: reescritura de datos | `.arb` `antiburlaOptionRecurringDesc` (`app_pt.arb:970`); `antiburla.service.ts` | "Ajustaremos o início para 'Há alguns dias' para manter seu histórico clínico consistente." El sistema "corrige" al usuario. | Bajo | REFRAME | KEEP la función como consistencia de diario. Copy: **"Vamos registrar como algo que voltou, para seu diário ficar organizado."** Título `antiburlaTitle`: **"Isso já apareceu antes?"**. Renombrar internamente "Antiburla" (implica fraude del usuario) → `RecurrenceCheck`. |
| B-13 | Antiburla: frontera biológica por sexo | `backend/src/modules/triage/services/antiburla.service.ts:36-48`; `.arb` `antiburlaBiologicalDiscordanceTitle/Desc` (`app_pt.arb:982-986`) | "discordância anatômica com o seu perfil biológico. Redirecionando a avaliação…" | Medio | REFRAME | No "redirigir evaluación". Si se mantiene, solo sugerencia editable: **"Quer revisar a área do corpo selecionada?"**. Ojo: riesgo de discriminación con usuarios trans/intersex (GDPR Art. 9, LGPD Art. 6 IX no discriminación) **[Juicio]**: recomiendo eliminar la regla. |
| B-14 | Pantalla de emergencia bloqueante | `mobile/lib/features/emergency/presentation/screens/emergency_screen.dart:87-88` (`PopScope canPop:false`); `.arb` `emergencyExitButton/ExitConfirm*` (`app_pt.arb:195-211`) | Bloquea salida; "Voltar ao Início (Não recomendado)", "Seus sintomas indicam uma situação de risco à vida". | Alto | REFRAME | Ver sección 4. Pantalla dismissable; nada de "seus sintomas indicam". |
| B-15 | Números de emergencia solo Brasil | `emergency_screen.dart:175-195` (192/193/188 hardcoded) | Lanzamiento internacional con números BR. | Alto (seguridad) | REFRAME | Tabla por país (BR 192/193/188; US 911/988; UE 112 + línea de crisis nacional; ES 112/024; PT 112/SNS24 808 24 24 24; MX 911). Fallback: 112 + "número local de emergência". |
| B-16 | Clasificación por IA en historial/outcome | `mobile/lib/features/triage_outcome/presentation/widgets/ai_insight_card.dart:27,137-138` | "Informação Clínica Complementar", "Já catalogado na base clínica" + muestra `aiClinicalConcept`. | Alto | REMOVE | No mostrar concepto médico. Si se mantiene la tarjeta: **"Como organizamos sua anotação"** + `layTerm` + área. |
| B-17 | Detección "off-topic" | `.arb` `offTopicNarrative*` (`app_pt.arb:990-1002`) | "Isso parece um sintoma?" | Bajo | REFRAME | **"Não entendemos bem sua anotação"** / **"Seu texto não parece descrever como você está se sentindo. Quer editar ou continuar?"** |
| B-18 | Wizard: "Desfecho/Ação" | `.planning/PROJECT.md:34` (RF-002 "Natureza → Tempo → Intensidade → Causas → Desfecho/Ação") | El paso 5 genera acción asistencial. | Alto | REFRAME | Paso 5 = **"Revisar e salvar seu registro"**. Sin desfecho. |

### 3.2 Copy de interfaz (`.arb` y hardcoded)

| id | área | file:line | actual | riesgo | acción | cambio concreto (pt-BR) |
|---|---|---|---|---|---|---|
| C-01 | Onboarding | `app_pt.arb:19` `valueCard1Title` | "Triagem Preventiva Unificada" | Alto | REFRAME | **"Diário de Bem-Estar Integrado"** |
| C-02 | Onboarding | `app_pt.arb:23` `valueCard1Body` | "…fluxo diário inteligente, garantindo cuidado holístico…" | Medio | REFRAME | **"Registre como você está no corpo e nas emoções em um único check-in diário de 1 minuto."** |
| C-03 | Onboarding | `app_pt.arb:27-31` `valueCard2*` | "Registros Médicos Blindados", "histórico clínico" | Medio | REFRAME | Título **"Seus Dados Protegidos"**; cuerpo **"Seus registros de bem-estar ficam criptografados e sob seu controle, conforme a LGPD."** |
| C-04 | Onboarding | `app_pt.arb:35-39` `valueCard3*` | "Orientações Preventivas Precisas", "especialistas médicos renomados", "sem diagnósticos falsos" | Alto | REFRAME | Título **"Conteúdos para Hábitos Saudáveis"**; cuerpo **"Leituras curtas e gerais sobre sono, estresse, postura, hidratação e mais."** ("Precisas" = afirmación de exactitud no sustentada, FTC §5). |
| C-05 | Consentimiento LGPD | `app_pt.arb:43` `lgpdConsentCheckbox` | "…para fins de triagem preventiva e acompanhamento longitudinal…" | Alto | REFRAME | **"Li e concordo com a Política de Privacidade e consinto, de forma específica e destacada, com o tratamento dos meus dados pessoais sensíveis de saúde para registrar e visualizar meu diário de bem-estar, nos termos do Art. 11, I da LGPD."** |
| C-06 | Velo privacidad | `app_pt.arb:51` `privacyVeilBody`; hardcoded `shared/widgets/privacy_veil_overlay.dart:145` | "…para acessar seu prontuário." | Medio | REFRAME | **"…para acessar seus registros."** ("prontuário" es término legal del registro médico profesional, CFM 1.638/2002). |
| C-07 | Emergencia | `app_pt.arb:115-119` `emergencyTitle/Subtitle` | "Alerta de Risco Imediato" / "Sintomas de gravidade identificados." | Alto | REFRAME | **"Precisa de ajuda agora?"** / **"Se você ou alguém perto de você estiver em perigo, ligue para a emergência. Não espere."** |
| C-08 | Emergencia | `app_pt.arb:123-143` `emergencyBadge*` | "Dor Torácica Crítica", "Suspeita de Déficit Neurológico (AVC)", "Sintoma Crítico (Nível 4–5)" | Alto | REMOVE | Eliminar badges. Sin etiqueta de condición. |
| C-09 | Emergencia | `app_pt.arb:147-191` instrucciones y botones | Instrucciones de primeros auxilios genéricas, botones 192/193/188/190, buscar PS. | Bajo | KEEP | Son información de seguridad pública genérica. Revisar "Afrouxe roupas…" con fuente oficial (Ministério da Saúde/SAMU) y citarla. |
| C-10 | Emergencia | `app_pt.arb:195-211` | "Voltar ao Início (Não recomendado)", "Seus sintomas indicam uma situação de risco à vida…" | Alto | REFRAME | Botón **"Fechar"**; eliminar diálogo de confirmación. |
| C-11 | Wizard banners | `app_pt.arb:231-235` | "Iniciando Autoavaliação Psico-Emocional/Física" | Medio | REFRAME | **"Registro emocional de hoje"** / **"Registro físico de hoje"** |
| C-12 | Wizard preview | `app_pt.arb:263, 523, 851` | "Revisão da sua Avaliação…" | Medio | REFRAME | **"Revise seu registro"** |
| C-13 | Opciones emocionales | `app_pt.arb:299-323` | "Depressiva / Desânimo", "Estresse / Burnout", "Somática (Psicossomática)", "Sono (Insônia / Hipersônia)", "Ansiosa / Agitação" | Medio | REFRAME | **"Pra baixo / Desanimado(a)"**, **"Estressado(a) / Esgotado(a)"**, **"Tensão no corpo"**, **"Sono ruim ou sono demais"**, **"Inquieto(a) / Agitado(a)"**. Evitar términos que nombran trastornos (depresión, burnout CID-11 QD85, insomnio, hipersomnia). Renombrar keys `depressive_hopelessness`→`low_mood`, `anxious_agitation`→`restless`, `stress_burnout`→`stress_exhaustion`. |
| C-14 | Opciones físicas | `app_pt.arb:547-591` | "Sistema Neurológico", "Endócrino / Metabólico", "Geniturinário / Pélvico", "Cardiovascular / Tórax", "Sistema Dermatológico" | Medio | REFRAME | Áreas del cuerpo en lenguaje lego: **"Cabeça e pescoço"**, **"Peito"**, **"Respiração"**, **"Barriga"**, **"Costas"**, **"Braços"**, **"Pernas"**, **"Pele"**, **"Região íntima / urinária"**, **"Corpo todo / cansaço"**, **"Tontura / formigamento"**, **"Sede, fome ou energia"**. Nada de "sistema X". |
| C-15 | Preguntas Q4 | `app_pt.arb:615-663` | Preguntas de factores asociados (esfuerzo, pantallas, comida, medicamento…). | Bajo | KEEP | Son de contexto de estilo de vida, sin interpretación. Solo cambiar `triageQ2Physical` (`:595`) "dor ou anomalia" → **"esse desconforto"**. |
| C-16 | Escala | `app_pt.arb:864-868` | "Quase imperceptível" / "Insuportável" | Bajo | KEEP | Escala de auto-reporte. |
| C-17 | Outcome título | `app_pt.arb:872-876`; hardcoded `triage_outcome_screen.dart:33` | "Resultado da Triagem" / "Avaliação preventiva baseada nas suas respostas" | Alto | REFRAME | **"Resumo do seu registro"** / **"Um retrato do que você registrou hoje"** |
| C-18 | Disposición | `app_pt.arb:888-920`; hardcoded `disposition_card.dart:38-96`; `today_triage_summary_card.dart:35`; `triage_history_detail_modal.dart:46-71`; `retrospective_list_view.dart:35-36` | "Recomendação de Cuidado", "Auto-cuidado Monitorado", "Consulta de Rotina", "Pronto Atendimento", "Atendimento de Emergência", "Nível 5 - Crítico / Emergência", "Consulta médica ambulatorial … com especialista" | Alto | REMOVE | Eliminar tarjeta de disposición y niveles "Severo/Urgente/Crítico/Emergência" del historial. Reemplazar por bloque estático (S-03). En historial: **"Intensidade informada: {n}/5"**. |
| C-19 | Artículos | `app_pt.arb:932-936`; hardcoded `triage_outcome_screen.dart:180-191`; `today_triage_result_tab.dart:773, 793, 934, 943` | "Artigos Médicos Recomendados", "elaborados por especialistas renomados", "Artigos Sugeridos para Seus Sintomas", "Recomendações clínicas selecionadas de acordo com os sintomas", "recomendadas pela equipe clínica" | Alto | REFRAME | **"Leituras sobre bem-estar"** / **"Conteúdos educativos gerais. Não são orientação para o seu caso."**; **"Leituras relacionadas ao tema que você registrou"**. No "equipe clínica" si no existe. |
| C-20 | Autores de artículos | `mobile/lib/features/triage_outcome/data/triage_outcome_remote_data_source.dart:235-401` (p. ej. `:373` "Psicólogo Clínico (CRP-06/123456)"); `curated_articles_catalog.dart:8-108`; `backend/src/modules/triage/data/medical-articles.seed.pt.ts:28-144` (+ `.en`, `.es`) | Autores "Dr./Dra." con CRM/CRP (p. ej. "CRM-SP 165.340", "CRP-06/123456") cuyos URLs apuntan a gov.br, drauziovarella, etc. | **Alto** | REMOVE | **Si los autores no son reales y no firmaron el contenido, es atribución falsa** (FTC §5, CDC Art. 37, normas de publicidad CFM/CFP; un número CRM inventado puede pertenecer a un médico real). Mostrar solo la **fuente real** del enlace ("Fonte: Ministério da Saúde"). Si quieren autores, contratos firmados con profesionales verificados. |
| C-21 | Contenido de artículos | `backend/src/modules/triage/data/medical-articles.seed.pt.ts:983` y similares; `triage_outcome_remote_data_source.dart:314` | "…exame de sangue … é capaz de diagnosticar precocemente…", "arritmias que requerem eletrocardiograma imediato" | Medio | REFRAME | Educación general está bien (wellness cat. 2 FDA) mientras no se **empareje** a la persona como recomendación. Revisión editorial: quitar imperativos clínicos personalizados. |
| C-22 | Navegación | `app_pt.arb:1396` `navTodayOutcome` | "Resultado do Dia" | Medio | REFRAME | **"Meu Dia"** |
| C-23 | Historial | `app_pt.arb:1027, 1039-1059` | "Histórico & Tendências", "Mapa Corporal 2D", leyenda "Sem dor / Leve / Moderada / Intensa" | Bajo | KEEP | Visualización de datos propios = wellness/PHR. Cambiar "Sem dor" → **"Sem registro"** (no siempre es dolor). |
| C-24 | Body map hints | `mobile/lib/features/dashboard/presentation/widgets/anatomical_body_map.dart:51-155` (`clinicalHint`), `:646-685` | "Dispneia funcional", "Prurido", "Mialgia difusa", "Nível $intensity" | Medio | REFRAME | Lenguaje lego: **"Falta de ar, tosse"**, **"Coceira, manchas"**, **"Dor no corpo todo"**; **"Maior intensidade informada nos últimos 14 dias: {n}/5"**. Renombrar campo `clinicalHint`→`areaHint`. |
| C-25 | Settings / historial | `app_pt.arb:1280, 1288, 1372`; hardcoded `delete_history_item_dialog.dart:135`, `historical_dashboard_screen.dart:31` | "histórico de triagens", "registro de triagem" | Medio | REFRAME | **"histórico de registros"**, **"este registro"** |
| C-26 | Export LGPD | `app_pt.arb:1095` `exportDataDesc` | "…histórico clínico…" | Bajo | REFRAME | **"…seus dados pessoais e registros de bem-estar…"** |
| C-27 | Notificación | `app_pt.arb:1445` `notifCheckinTitleAt` | "🩺 Check-in Diário Dualis" | Bajo | REFRAME | Cambiar 🩺 por ☀️ o 🌿. |
| C-28 | Perfiles | `app_pt.arb:1486`; `:1555` | "Co-gestão (Pode registrar triagens)"; "Perfis de Saúde" | Bajo | REFRAME | **"(Pode adicionar registros)"**; **"Perfis"** |
| C-29 | Dependientes | `app_pt.arb:1551` `addDependentLgpdArt14Consent` | "…dados de saúde preventiva…" | Bajo | REFRAME | **"…dados de bem-estar…"** (mantener resto). |
| C-30 | Home | `mobile/lib/features/home/presentation/screens/home_screen.dart:101` | Nombre fallback **"Paciente"** | Medio | REFRAME | Fallback **"Olá!"** sin nombre. "Paciente" posiciona al usuario como sujeto de atención médica. |
| C-31 | Home | `home_screen.dart:413` | "Prontuário Ativo & Protegido (LGPD Art. 11)" | Medio | REFRAME | **"Seus registros estão protegidos"** |
| C-32 | Resultado del día | `today_triage_result_tab.dart:84, 99, 240, 462, 670, 760` | "Triagem Concluída", "Sintomas de ansiedade, sobrecarga mental ou agitação psicomotora relatados", "Atualizar Triagem de Hoje", "Completar Triagem Clínica Detalhada" | Alto | REFRAME | **"Registro concluído"**, **"Você registrou: {opção escolhida}"** (repetir palabras del usuario, no reinterpretarlas), **"Atualizar registro de hoje"**, **"Fazer registro detalhado"** |
| C-33 | Resumen home | `today_triage_summary_card.dart:96` | "Triagem de Hoje Concluída" | Medio | REFRAME | **"Registro de hoje concluído"** |
| C-34 | Login / registro | `login_screen.dart:110`; `register_screen.dart:224` | "Acesse seu prontuário e histórico de triagens preventivas"; "Informe seus dados clínicos e cadastrais para personalizar sua triagem preventiva." | Medio | REFRAME | **"Acesse seu diário de bem-estar com segurança."**; **"Informe alguns dados para personalizar sua experiência."** |
| C-35 | Settings | `settings_screen.dart:188, 373` | "Avatares Clínicos"; "Seus dados clínicos permanecem seguros" | Bajo | REFRAME | **"Avatares"**; **"Seus dados permanecem seguros"**. También `avatar_selector_sheet.dart:27` "Clínico". |
| C-36 | 404 | `core/presentation/screens/not_found_screen.dart:88` | "…recurso clínico…" | Bajo | REFRAME | **"A página que você tentou acessar não existe."** |
| C-37 | Offline | `triage_outcome_remote_data_source.dart:87-93, 165-171` | "Sem queixas clínicas relatadas", "Avaliação clínica preliminar em modo desconectado" | Medio | REFRAME | **"Você indicou que está bem hoje."** / **"Registro salvo no aparelho; será sincronizado."** |
| C-38 | Wizard narrativa | `triage_wizard_screen.dart:368` | "Descreva como você está se sentindo com base nos sintomas..." | Bajo | REFRAME | **"Se quiser, escreva com suas palavras como você está."** |
| C-39 | Bienestar | `wellness_confirmation_dialog.dart:60` | "Seu check-in preventivo diário…" | Bajo | KEEP | Cambiar solo "preventivo" → nada. |
| C-40 | Ads | `admob_banner_container.dart:37` | "Parceiro Local • Zero rastreamento clínico" | Medio | REFRAME | **"Parceiro local • Anúncio não usa seus dados de saúde"**, y garantizarlo técnicamente (Apple 5.1.3; FTC HBNR). |
| C-41 | iOS permiso | `mobile/ios/Runner/Info.plist` (`NSFaceIDUsageDescription`) | "…dados médicos confidenciais e registros de triagem." | Medio | REFRAME | **"O Dualis usa Face ID para proteger o acesso aos seus registros de bem-estar."** (Lo ve el revisor de Apple.) |

### 3.3 Documentos legales (mobile + backend)

| id | área | file:line | actual | riesgo | acción | cambio concreto |
|---|---|---|---|---|---|---|
| L-01 | Términos | `mobile/lib/features/privacy/presentation/screens/terms_of_service_screen.dart:105-113` | "Limitação de Responsabilidade Médica (SaMD)… estratificação de risco preventivo, **classificada conforme a Resolução RDC Anvisa nº 657/2022** e CFM 2.314/2022" | **Alto** | REFRAME | Es una **auto-declaración de SaMD**. Sustituir por: título **"2. Natureza do Serviço"**; texto = declaración de uso previsto (§2) + bullets: **"O DualisCheckUp não é um dispositivo médico e não está sujeito a registro na Anvisa."** (solo si el consultor lo confirma) / **"Não avalia sintomas, não indica urgência, não diagnostica e não recomenda tratamento."** / **"Em emergência, ligue 192 (SAMU) ou 188 (CVV)."** Eliminar toda referencia a RDC 657, CFM 2.314 y "estratificação de risco". |
| L-02 | Términos (IP) | `terms_of_service_screen.dart:139`; `backend/src/modules/legal/legal.service.ts:202` | "algoritmos heurísticos, árvores de triagem, modelos de IA… algoritmos de triagem da plataforma" | Medio | REFRAME | **"software, conteúdos, marcas e interfaces"** |
| L-03 | Consentimiento modal | `mobile/lib/features/auth/presentation/widgets/lgpd_consent_checkbox.dart:60, 78-79` | "auto-monitoramento preventivo e **triagem** de bem-estar"; "Bases Normativas: Anvisa RDC 657/2022 (SaMD)… CFM 2.314/2022 (Telemedicina)" | Alto | REFRAME | Texto: declaración de §2. Bases: dejar solo **LGPD** (Art. 7, 11, 14, 18) y **CDC**. Citar RDC 657 y CFM 2.314 sugiere que el producto está bajo esas normas. |
| L-04 | Política de privacidad | `privacy_policy_screen.dart:81, 126-127, 139-143, 170-171` | "dados clínicos", "Histórico Clínico Subjetivo", "**Estratificação Preventiva: Análise de sintomas** e orientações de autocuidado", "Garantia Antiburla… prevenção de adulterações", "prontuário" | Alto | REFRAME | Finalidades: **"Registro e visualização do seu diário de bem-estar"**, **"Organização automática das suas anotações por área do corpo ou emoção (com auxílio de IA, sem avaliação de saúde)"**, **"Consistência do histórico"**. Añadir encargados (Google Gemini) y transferencia internacional (ver §6). |
| L-05 | Disclaimer API | `backend/src/modules/legal/legal.service.ts:70, 129, 168, 180-183, 510, 517, 543-546, 558, 565, 591-592, 603-613, 639-640` | "risk stratification tools", "not an **autonomous** diagnostic medical device", "triagem clínica inteligente", "baseada em protocolos clínicos reconhecidos", "Anvisa / International SaMD Standards" | **Alto** | REFRAME | "no es un dispositivo de diagnóstico **autónomo**" implica que sí es un dispositivo (no autónomo). "Basada en protocolos clínicos reconocidos" es afirmación clínica. Reemplazar todo por §2 en los 3 idiomas. Eliminar `regulatoryBody: 'Anvisa / International SaMD Standards'`. |
| L-06 | Base legal | `legal.service.ts:311, 371` | "Tutela da saúde… LGPD Art. 7º, VIII e Art. 11, II, 'f'" | Medio | REFRAME | Art. 11, II, "f" es "tutela da saúde, **exclusivamente em procedimento realizado por profissionais de saúde, serviços de saúde ou autoridade sanitária**". Una app de bienestar no califica. Base correcta: **Art. 11, I (consentimento específico e destacado)**. Confirmar con DPO. |
| L-07 | Privacidad pagos | `privacy_policy_screen.dart:156` | "PCI-DSS Nível 1" | Bajo | KEEP | No regulatorio; verificar que sea cierto antes de afirmarlo. |

### 3.4 Identificadores que se filtran o que son evidencia de intención

| id | file:line | identificador | riesgo | acción |
|---|---|---|---|---|
| I-01 | `mobile/lib/core/constants/api_endpoints.dart:36-44`; `backend/src/modules/triage/triage.controller.ts:39`; `triage-audit.controller.ts:23`; `ai.controller.ts:6,14` | `/v1/triage/*`, `/v1/triage/emergency-event`, `/v1/ai/classify-symptom` | Bajo (visible en tráfico y para revisores) | Renombrar a `/v1/journal/*`, `/v1/journal/safety-event`, `/v1/ai/tag-entry` con alias temporal. |
| I-02 | `mobile/lib/core/router/route_paths.dart:7-9`; `app_router.dart:111-154` | `/triage`, `/triage-outcome`, `somaticMapping: 'Sintomas autolimitados'` (`app_router.dart:154`) | Bajo / Medio (el último es texto visible) | `/checkin`, `/checkin-summary`; quitar "autolimitados". |
| I-03 | `mobile/lib/core/clinical/clinical_intensity_tier.dart`; `backend/.../intensity-tier.constant.ts` | `ClinicalIntensityTier`, `isCritical` | Bajo | Ver B-10. |
| I-04 | `triage_outcome_models.dart:5, 129, 199`; `symptom_classification.dart:28-31` | `CareDisposition.emergency`, `aiClinicalConcept`, `urgencyScore`, `isEmergencyCandidate` | Medio | Eliminar con B-01/B-05. |
| I-05 | `backend/src/database/schema/triage-emergency-events.schema.ts` | tabla `triage_emergency_events` | Bajo | `safety_resource_views` (registrar solo "usuario abrió recursos de emergencia", sin diagnóstico). |
| I-06 | Nombre del producto "Dual**is CheckUp**" | "Check-up" en pt-BR = examen médico preventivo | Medio **[Juicio]** | El nombre de tienda "Dualis" (Info.plist, AndroidManifest) está bien. En la ficha evitar "CheckUp" como promesa de chequeo médico, o añadir subtítulo "Diário de bem-estar". |

### 3.5 Documentación interna (cuenta como evidencia de uso previsto)

| id | file:line | actual | riesgo | acción |
|---|---|---|---|---|
| D-01 | `CLAUDE.md` (Core Value, Constraints, "AI triage classification", "Level 4/5 symptoms into emergency red screen", "19-category clinical taxonomy") | Todo el posicionamiento es triaje clínico. | Alto | REFRAME con §2. Cambiar "Clinical Safety" por "Safety: emergency resources always reachable". |
| D-02 | `.planning/PROJECT.md:5, 9, 20, 33-38, 73, 85-86, 99` | "clinically consistent daily health triage", "100% emergency trigger fidelity", "classifies risk" | Alto | REFRAME. `:73` "classifies risk and categorizes symptoms" contradice cualquier argumento de wellness. |
| D-03 | `.planning/REQUIREMENTS.md:39, 75-80, 94-96, 105` | TRG-02 "formal clinical matrices", SOM-02 Organic Primacy, OUT-01 disposition, REC-01 "matched to the exact diagnosed theme", EMRG-01..03, DISC-01 "compliant with RDC 657/2022" | Alto | Reescribir requisitos conforme a B-01…B-18. |
| D-04 | `.planning/ROADMAP.md:5, 15-16, 78-97` | "clinically consistent triage", Phase 3 "deterministic clinical emergency interceptor (MTS/ESI)" | Alto | Reescribir Phase 3 como "Always-on emergency resources". |
| D-05 | `.agents/agents/doctor.md:3, 29`; `.agents/agents/doctor/agent.md:3, 29`; `doctor/clinical_test_cases.json` (p. ej. CASE-EMERG-001 "síndrome coronariana aguda… Exige SAMU 192"); `doctor/system_prompt.md` | Agente "Médico Clínico… protocolos Manchester, ESI, SUS"; casos con `expectedUrgency` y racional diagnóstico | Alto | Convertir en **agente de seguridad de contenido**: verifica que (a) los recursos de emergencia sean accesibles, (b) la app **no** emita urgencia/diagnóstico, (c) el copy no tenga términos prohibidos. Casos de prueba nuevos: "texto con dolor de pecho → app muestra recursos genéricos y NO nombra condición". |
| D-06 | `.agents/agents/agent-battery-report.md:14`; `CLAUDE.md` ("concordancia médica") | "Concordancia Clínica (Doctor) 11/11 (100.0%)" | Alto | Una métrica de concordancia clínica es exactamente la evidencia de desempeño de un SaMD. Eliminar; reemplazar por "tasa de copy prohibido = 0" y "recursos de emergencia accesibles en ≤1 tap desde cualquier pantalla". |
| D-07 | `.agents/agents/ai_reviewer*` | Calibración de `AiTriageService` | Medio | Renombrar a `AiTaggingService`; métricas de etiquetado, no de triaje. |

---

## 4. Seguridad de emergencia sin triaje algorítmico personalizado

**Problema hoy:** la pantalla roja solo es alcanzable **dentro del wizard** (`emergency_controller.dart:23` → `context.push(RoutePaths.emergency…)`, disparado solo desde `triage_wizard_notifier.dart:92-103`). No hay botón de emergencia en Home, historial ni settings (verificado: ninguna referencia a 192/188 en `mobile/lib/features/home`). O sea: el usuario solo ve ayuda si el algoritmo decide que la necesita. Eso es lo peor de ambos mundos: es triaje (regulado) y además no es accesible de forma universal.

**Diseño propuesto (no personalizado, igual para todos):**

1. **Botón "Ajuda urgente" siempre visible** (icono de teléfono/SOS en el AppBar o en la barra de navegación, todas las pantallas autenticadas, y en login). Abre la pantalla de recursos. Esto no depende de ningún dato del usuario → no es una función de decisión clínica.
2. **Pantalla de recursos estática** (reutilizar `emergency_screen.dart` sin `EmergencyContext`):
   - Título: **"Precisa de ajuda agora?"**
   - Botones según país del dispositivo (B-15): BR **SAMU 192**, **CVV 188**, **Bombeiros 193**, **Polícia 190**; buscar pronto-socorro.
   - **Lista estática de sinais de alerta**, igual para todos, con fuente oficial citada (Ministério da Saúde / SAMU), p. ej.:
     **"Ligue 192 imediatamente se você ou alguém tiver: dor ou pressão forte no peito; falta de ar intensa; rosto torto, fraqueza num lado do corpo ou fala enrolada; a pior dor de cabeça da vida, de início súbito; desmaio ou convulsão; sangramento que não para."**
     **"Se você está pensando em se machucar ou em tirar a própria vida, ligue 188 (CVV, 24h, gratuito) ou 192."**
   - Dismissable (sin `PopScope(canPop:false)`), sin "Não recomendado", sin "seus sintomas indicam".
3. **Triggers de contexto (permitidos [Juicio])**: cuando el usuario marca intensidad 5, o 4 en pecho/respiración/cabeza, o escribe texto que coincide con las regex, mostrar **la misma tarjeta genérica** inline: **"Se isso for uma emergência, não use o app: ligue 192 agora."** + botón a la pantalla de recursos. No se nombra condición, no se interrumpe el registro obligatoriamente, no se clasifica nivel. Es el patrón de "safety messaging" que usan buscadores y redes sociales. Mantener la regex de suicidio sin cambios funcionales (solo el copy).
4. **Offline**: la pantalla de recursos y la lista de alertas deben estar en el bundle (ya lo están las strings), funcionar sin red.
5. **Auditoría**: `triage-emergency-events` pasa a registrar solo "recursos abiertos / llamada iniciada", sin `severityLevel` ni categoría clínica (I-05). Minimiza datos (LGPD Art. 6 III).
6. **Nunca detrás de paywall** (Phase 15 tiers).

Lo que se pierde: el "interceptor zero-failure" como promesa. Eso es intencional: prometer fidelidad del 100% en detectar emergencias **es** una afirmación de desempeño clínico. La promesa nueva es "ayuda a 1 toque desde cualquier pantalla".

---

## 5. Impacto en el roadmap

| Fase / feature | Veredicto | Detalle |
|---|---|---|
| **Phase 3** (Emergency Risk Alert) | REFRAME | Ver §4. Re-especificar como "Always-on Safety Resources". |
| **Phase 4–7, 9** (wizard, home, outcome, antiburla, dashboard) | REFRAME | Aplicar B-01…B-18 y copy de §3.2. El wizard de 5 pasos y el mapa corporal sobreviven como **diario**. |
| **Phase 11** (multi-perfil / dependientes) | KEEP | Revisar COPPA (EE. UU., <13), GDPR Art. 8 (edad de consentimiento por país), LGPD Art. 14. Curatela de adulto "enfermo/dependiente" (REQUIREMENTS `:120`) — copy sin "enfermo". |
| **Phase 12** — Carteira de vacinação | KEEP | Registro personal = PHR (no MD: MDCG 2019-11 "almacenamiento/archivo"; FDA PHR). Recordatorios de refuerzo: solo si vienen del calendario oficial publicado (PNI) mostrado tal cual, sin cálculo personalizado por condición. |
| **Phase 12** — Alergias **con verificación cruzada** | REMOVE el cross-check / KEEP el registro | "Automated warnings if a logged symptom or medication conflicts with a registered drug allergy" (ROADMAP Phase 12 criterio 3) es una función de detección de interacción/alergia = MDSW (UE IIa+, FDA device). Mantener solo la lista de alergias que el usuario escribe y muestra en su perfil/export. |
| **Phase 13** — Condiciones CID-10/11 | KEEP (reframe) | Que el usuario anote diagnósticos **que ya le dio su médico** es PHR. Nombrar la pestaña **"Minhas condições (informadas por você)"**, no "Prontuário Estruturado". No sugerir códigos CID a partir de síntomas. |
| **Phase 13** — Alarmas de medicamento y stock | KEEP | Recordatorio de lo que el usuario configuró = no MD (FDA lo lista como no-device/enforcement discretion; MDCG trata recordatorios simples como no MDSW). Sin ajuste de dosis automático. |
| **Phase 13** — PDF "Doctor's Brief" SBAR | REFRAME | SBAR incluye **Assessment** y **Recommendation**: generaría juicio clínico. Exportar **"Resumo dos meus registros"**: datos tal como se registraron (fechas, intensidades auto-reportadas, notas, medicación y alergias informadas). Sin secciones A/R, sin interpretación. |
| **Phase 14** — OCR de exámenes / biomarcadores | REFRAME o PARTNER | Transcribir y archivar = aceptable **si**: (a) el usuario confirma cada valor, (b) se muestra el rango de referencia **impreso por el laboratorio**, (c) **sin** colores normal/alterado, alertas, tendencias interpretadas ni comentario de IA. Cualquier interpretación ("glicemia alta", "PSA elevado") = MDSW (UE IIa+; FDA device; ANVISA). Si el negocio necesita interpretación → **socio regulado** (laboratorio o plataforma con registro ANVISA/CE) o producto separado. |
| **Phase 14** — Lector de receta → agenda de dosis | REFRAME (alto riesgo) | Un error de OCR que crea una dosis equivocada es daño directo. Solo pre-llenar formulario editable, confirmación obligatoria campo por campo, nunca crear alarmas automáticamente. **[Juicio]**: recomiendo posponer hasta tener consultor; la línea entre "transcripción" y "gestión de medicación" es fina. |
| **Phase 14** — Resumen de bula con IA (5 puntos: posología, contraindicaciones, efectos, dosis olvidada) | **REMOVE / PARTNER** | IA generativa resumiendo posología y contraindicaciones = información de medicamento derivada, con riesgo de alucinación en dosis. En BR además roza la regulación de información de medicamentos. Alternativa: enlazar al **Bulário Eletrônico de ANVISA** (texto oficial, sin reescritura) o licenciar contenido de un proveedor de información farmacológica regulado. |
| **Phase 15** — Voz | REFRAME | "Voice triage" → **"registro por voz"**. Misma lógica de diario. Si la voz se usa para identificar/autenticar = dato biométrico (GDPR Art. 9, LGPD Art. 5 II). No guardar audio salvo necesidad. |
| **Phase 15** — Biometría avanzada | KEEP | Seguridad, no clínica. |
| **Phase 15** — Suscripciones | KEEP | Ficha de tienda y paywall sin promesas clínicas ("Advanced: interpretación de exámenes" sería claim de MD). Recursos de emergencia gratuitos siempre. |
| AdMob (RF-009 / AD-01) | KEEP con condiciones | Hoy es placeholder sin SDK. Al integrar: solo anuncios contextuales, ningún dato de salud a la red publicitaria (Apple 5.1.3, Google Play, FTC HBNR — casos GoodRx/BetterHelp). Evitar anuncios de farmacia junto a registros de síntomas **[Juicio]**. |

---

## 6. Obligaciones de datos que permanecen aunque sea wellness

Ser wellness **no** reduce la categoría de los datos: síntomas, estado emocional y condiciones siguen siendo datos de salud.

**Brasil (LGPD)**
- **Art. 11, I**: consentimiento específico y destacado para datos sensibles. Corregir base legal (L-06).
- **Art. 14**: datos de niños/adolescentes con consentimiento de un responsable; mejor interés.
- **Art. 33**: **transferencia internacional**. El backend llama a Gemini por **API key** (`backend/src/common/ai/gemini.service.ts:8-14`, modelo por defecto `gemini-2.5-flash` en `:5`, no 1.5 como dice `CLAUDE.md`), es decir, la **Gemini Developer API**, no Vertex AI en `southamerica-east1`. La narrativa del usuario sale de Brasil. Esto **contradice** la promesa de residencia en São Paulo (`.planning/PROJECT.md:28`, política de privacidad). Acciones: migrar a Vertex AI con región BR/UE o declarar la transferencia + cláusulas contractuales (Res. CD/ANPD 19/2024).
- **Riesgo adicional**: en el nivel **gratuito** de la Gemini Developer API, Google puede usar el contenido para mejorar productos. Confirmar que se usa nivel de pago / Vertex con no-entrenamiento y DPA firmado. Si no, es divulgación no autorizada de datos de salud.
- **Art. 37–38**: registro de operaciones y **RIPD** (informe de impacto) — obligatorio en la práctica para datos sensibles a escala.
- **Art. 41**: encargado (DPO) publicado.
- **Art. 48** + Res. CD/ANPD 15/2024: comunicar incidentes a la ANPD y titulares (plazo de 3 días hábiles).
- **Art. 18**: derechos (export y borrado ya implementados en Phase 10 — KEEP).

**UE (GDPR)**
- **Art. 9(2)(a)**: consentimiento explícito para datos de salud.
- **Art. 8**: edad de consentimiento digital (13–16 según país) para dependientes/menores.
- **Art. 35**: DPIA obligatoria (datos de salud a gran escala + IA).
- **Art. 27**: representante en la UE si no hay establecimiento.
- **Art. 28 / 44-49**: DPA con Google y cualquier encargado; mecanismo de transferencia (BR no tiene adecuación UE).
- **Art. 33-34**: notificación de brechas en 72 h.
- **Art. 22**: evitar decisiones automatizadas con efectos significativos (otra razón para quitar la disposición asistencial).
- AI Act **Art. 50**: si hay interacción conversacional (voz, Phase 15), informar que es IA.

**EE. UU.**
- **FTC Health Breach Notification Rule** (16 CFR 318, enmienda 2024): la app es un vendor de PHR. "Breach" incluye compartir datos sin autorización (SDKs de analítica/ads, IA de terceros que entrene con ellos). Notificar a individuos, FTC (y medios si >500 en un estado) en ≤60 días.
- **FTC Act §5**: claims de salud con sustento (C-04 "Precisas", C-20 autores).
- **Leyes estatales de datos de salud del consumidor**: Washington **My Health My Data Act**, Nevada SB 370, Connecticut (CTDPA) — consentimiento separado para recolectar y para compartir, prohibición de geofencing alrededor de centros de salud. Relevante para AdMob con "geolocalización aproximada" (REQUIREMENTS `:41`).
- **COPPA**: perfiles de menores de 13 años (Phase 11).
- HIPAA: probablemente **no** aplica (no hay covered entity) **[Juicio]**; deja de ser cierto si se integra con prestadores/planes de salud.

**Tiendas**
- Apple: privacy nutrition label con "Health & Fitness", 5.1.1(ix) apps altamente reguladas, 5.1.3 sin uso de datos de salud para publicidad ni venta.
- Google Play: Health apps declaration, Data safety form, política de datos sensibles.

---

## 7. Plan de acción ordenado

| # | Acción | Hallazgos | Esfuerzo |
|---|---|---|---|
| 1 | **Detener la publicación de autores con CRM/CRP no verificados**; mostrar solo fuente real del enlace. | C-20 | S |
| 2 | Reescribir Términos, consentimiento, política de privacidad y disclaimer del backend con la declaración de §2; quitar toda referencia a RDC 657, CFM 2.314, "estratificação de risco", "protocolos clínicos", "não autônomo"; corregir base legal a Art. 11, I. | L-01…L-06, C-05 | S |
| 3 | Copy de interfaz pt/en/es: onboarding, outcome, home, historial, settings, login/registro, Info.plist, "Paciente", "prontuário", "triagem" → "registro". Mover hardcoded a l10n. | C-01…C-41 | M |
| 4 | Botón "Ajuda urgente" siempre visible + pantalla de recursos estática dismissable + lista estática de sinais de alerta + números por país. | §4, B-14, B-15, C-07…C-10 | M |
| 5 | Quitar disposición asistencial (backend + mobile + historial) y reemplazar por bloque estático: **"Este app não avalia sua saúde. Se algum desconforto persistir, piorar ou te preocupar, procure um profissional de saúde. Em emergência, ligue 192."** | B-01, B-02, C-18 | M |
| 6 | Cambiar esquema y prompt de Gemini a etiquetado de diario; eliminar `urgencyScore`/`clinicalConcept`/`isEmergencyCandidate` en seed, DTOs y UI. | B-05…B-08, B-16, I-04 | M |
| 7 | Convertir interceptor estructurado y regex físicas en aviso genérico no bloqueante; mantener safety net de suicidio con nuevo copy. | B-03, B-04 | M |
| 8 | Primacía orgánica → nota estática; recurrencia crítica → "Padrões nos seus registros"; intensidad "calculada" → "informada"; antiburla copy y eliminar regla por sexo. | B-09…B-13 | S–M |
| 9 | Gemini: Vertex AI en región adecuada o transferencia declarada; confirmar no-entrenamiento + DPA. RIPD/DPIA. | §6 | M |
| 10 | Reescribir `CLAUDE.md`, `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, agente doctor y métricas de batería (quitar "concordancia clínica"). | D-01…D-07 | M |
| 11 | Renombrar identificadores (`/triage`→`/journal`, `ClinicalIntensityTier`, tabla de eventos) con alias de compatibilidad. | I-01…I-05 | L |
| 12 | Roadmap: quitar cross-check de alergias (P12), SBAR sin A/R (P13), OCR solo transcripción confirmada y bula vía Bulário ANVISA o partner (P14), voz como registro (P15). | §5 | S (decisión) / L (ejecución) |
| 13 | Revisión por consultor regulatorio (BR/UE/US) con este documento + build reescrito; preparar ficha de tienda alineada a §2 y respuesta a revisión 1.4.1. | Todos | — (externo) |

Orden lógico: 1-3 se pueden hacer en una semana y ya eliminan la mayor parte de la evidencia escrita de uso médico. 4-8 cambian el comportamiento que hoy define la clasificación; sin ellos, cambiar el copy no basta (el regulador mira lo que el software **hace**, no solo lo que dice). 9 es independiente del estatus wellness y obligatorio igual.

**Decisión de negocio que queda abierta:** si la propuesta de valor central es "decirle al usuario qué tan urgente es lo que siente", eso no cabe en wellness en ninguna de las tres regiones. La alternativa es lanzar el diario de bienestar ahora y desarrollar el triaje como producto regulado separado (o con un socio que ya tenga registro ANVISA / marcado CE / autorización FDA).
