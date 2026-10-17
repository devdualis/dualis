# DualisCheckUp: Plan Técnico de Reposicionamiento a Bienestar

**Versión:** 1.0 | **Fecha:** 15/10/2026 | **Base:** rama `feat/phase-11-multi-profile` (commit `58849fc`) y auditoría de uso previsto (`ANEXO-AUDITORIA-USO-PREVISTO.md`)
**Destinatario:** equipo técnico, producto y consultoría regulatoria

> **Aviso.** Este plan no es asesoría legal ni regulatoria. Es un plan de ingeniería para que el producto deje de cumplir la definición de *software como dispositivo médico* (SaMD). Un consultor regulatorio (ANVISA, MDR UE, FDA) y un abogado de protección de datos deben validarlo antes del lanzamiento.

---

## 1. Objetivo

Reposicionar DualisCheckUp como **aplicación de bienestar y autoconocimiento** (categoría "Salud y bienestar" / *general wellness*). Así puede lanzarse en Brasil, la Unión Europea y Estados Unidos sin registro como dispositivo médico.

La clasificación regulatoria depende del **uso previsto**, y el regulador lo deduce de dos cosas:
- **lo que el software hace**: lógica, salidas y algoritmos;
- **lo que la empresa dice**: interfaz, términos, ficha de tienda, documentación interna y material comercial.

Este plan cambia las dos.

### 1.1 Declaración de uso previsto (texto canónico)

Debe aparecer idéntica en Términos, onboarding, fichas de tienda, sitio web, pitch y documentación interna.

**pt-BR**
> O DualisCheckUp é um aplicativo de bem-estar e autoconhecimento. Ele ajuda você a registrar diariamente como se sente física e emocionalmente, acompanhar hábitos como hidratação e sono, visualizar seus próprios registros ao longo do tempo e acessar conteúdos educativos gerais sobre hábitos saudáveis. O DualisCheckUp não é um dispositivo médico: não avalia, não classifica nem interpreta sintomas, não indica nível de urgência, não faz diagnóstico, não recomenda tratamento e não substitui um profissional de saúde. Em caso de emergência, ligue 192 (SAMU). Se você estiver em sofrimento emocional, ligue 188 (CVV).

**en**
> DualisCheckUp is a wellness and self-awareness app. It helps you keep a daily journal of how you feel physically and emotionally, track habits such as hydration and sleep, view your own entries over time, and access general educational content about healthy habits. DualisCheckUp is not a medical device: it does not assess, classify or interpret symptoms, does not indicate urgency levels, does not diagnose, does not recommend treatment and does not replace a healthcare professional. In an emergency, call your local emergency number. If you are in emotional distress, contact your local crisis line.

---

## 2. Reglas de diseño (aplican a todo cambio futuro)

| # | Regla | Ejemplo permitido | Ejemplo prohibido |
|---|---|---|---|
| R1 | La app **no emite juicio individual** sobre la salud de la persona. | "Você registrou dor de cabeça 4 dias esta semana." | "Seu nível de risco é 4", "Procure pronto atendimento". |
| R2 | Todo número clínico es **auto-reportado** y se presenta así. | "Intensidade que você informou: 4/5" | "Intensidade calculada", "escala clínica". |
| R3 | **No se nombran condiciones** a partir de lo que registra el usuario. | "Peito", "Cabeça e pescoço" | "Suspeita de AVC", "Dor torácica crítica", "Sistema cardiovascular". |
| R4 | La **seguridad es estática y universal**: igual para todos y siempre visible. | Botón "Ajuda urgente" en toda pantalla | Pantalla roja que aparece solo si el algoritmo decide. |
| R5 | La IA **organiza** las anotaciones; no evalúa nada. | Etiquetar área del cuerpo y término usado | `urgencyScore`, `clinicalConcept`, `isEmergencyCandidate`. |
| R6 | El contenido educativo es **general** y con **fuente real**. | "Fonte: Ministério da Saúde" | Autores con CRM/CRP no verificados; "recomendado para seus sintomas". |
| R7 | Los datos siguen siendo **datos sensibles de salud**. | Consentimiento Art. 11 I LGPD, RLS, cifrado | Usar datos de salud para publicidad. |

**Términos vetados en la interfaz y en material externo:** triagem/triaje/triage, diagnóstico, prontuário, clínico/a (como adjetivo del producto), paciente, risco/gravidade/crítico (sobre el usuario), urgência (como salida), "recomendação de cuidado", Manchester, ESI, SaMD, RDC 657, CFM 2.314, "concordância clínica", "precisas".

**Excepción:** "emergência", "192", "188" y "pronto-socorro" solo pueden aparecer en la pantalla de recursos de ayuda (frente F3).

---

## 3. Inventario completo de cambios

Cada frente indica qué cambia, dónde, cómo y el criterio de aceptación. Los IDs entre corchetes remiten a la auditoría (B = lógica, C = copy, L = legal, I = identificadores, D = documentación).

Esfuerzo:
- **S:** 1 a 2 días-persona.
- **M:** 3 a 5 días-persona.
- **L:** 6 a 10 días-persona.

### F0. Contenido educativo y atribución de autores (URGENTE) — S

| Cambio | Dónde | Detalle |
|---|---|---|
| Quitar autores con CRM/CRP no verificados [C-20] | `backend/src/modules/triage/data/medical-articles.seed.{pt,en,es}.ts`; `mobile/lib/features/triage_outcome/data/triage_outcome_remote_data_source.dart:235-401`; `curated_articles_catalog.dart` | Hoy hay **48 menciones** de CRM/CRP en estos archivos (p. ej. "CRM-SP 165.340", "CRP-06/123456"). Los enlaces apuntan a gov.br, Drauzio Varella, etc. Mostrar solo la **fuente real del enlace** ("Fonte: Ministério da Saúde"). Si se quieren autores, deben existir contratos con profesionales verificados. |
| Revisión editorial [C-21] | seeds de artículos | Quitar imperativos clínicos personalizados ("requerem eletrocardiograma imediato", "capaz de diagnosticar"). |
| Cambiar cómo se presentan [C-19] | `.arb` `outcomeArticles*`; hardcoded en `triage_outcome_screen.dart:180-191`, `today_triage_result_tab.dart:773-943` | "Artigos Médicos Recomendados" pasa a **"Leituras sobre bem-estar"**, con la nota **"Conteúdos educativos gerais. Não são orientação para o seu caso."** Eliminar "equipe clínica" y "especialistas renomados". |

**Aceptación:** ningún nombre de profesional ni número de registro en la app ni en la API. Cada artículo muestra una fuente verificable.

### F1. Documentos legales y consentimiento — S

| Cambio | Dónde | Detalle |
|---|---|---|
| Términos de uso [L-01, L-02] | `mobile/lib/features/privacy/presentation/screens/terms_of_service_screen.dart:105-139` | Hoy dice "estratificação de risco preventivo, **classificada conforme a Resolução RDC Anvisa nº 657/2022** e CFM 2.314/2022", una auto-declaración de SaMD. Reemplazar por la sección "2. Natureza do Serviço" con la declaración §1.1. Eliminar RDC 657, CFM 2.314, "árvores de triagem" y "algoritmos de triagem". |
| Consentimiento en registro [L-03, C-05] | `lgpd_consent_checkbox.dart:60-79`; `.arb` `lgpdConsentCheckbox` | Finalidad: **"registrar e visualizar meu diário de bem-estar"**. Bases normativas citadas: solo LGPD (Art. 7, 11, 14, 18) y CDC. |
| Política de privacidad [L-04] | `privacy_policy_screen.dart:81-171` | Nuevas finalidades: diario de bienestar; organización automática de anotaciones con IA **sin evaluación de salud**; consistencia del historial. Agregar encargados (Google) y la transferencia internacional (F9). |
| Disclaimer de la API [L-05] | `backend/src/modules/legal/legal.service.ts` (líneas 70-640) | Eliminar "risk stratification tools", "not an **autonomous** diagnostic medical device" (que implica que sí es un dispositivo, aunque no autónomo), "protocolos clínicos reconhecidos" y `regulatoryBody: 'Anvisa / International SaMD Standards'`. Reemplazar por la §1.1 en 3 idiomas. Subir `DISCLAIMER_VERSION` para forzar el re-consentimiento. |
| Base legal LGPD [L-06] | `legal.service.ts:311, 371` | Cambiar Art. 11, II, "f" (tutela de la salud, que exige profesional o servicio de salud) por **Art. 11, I (consentimiento específico y destacado)**. Validar con el DPO. |
| Afirmaciones comerciales [L-07] | `privacy_policy_screen.dart:156` | Verificar "PCI-DSS Nível 1" antes de mantenerlo. |

**Aceptación:**
- Ningún texto legal cita RDC 657, CFM 2.314, SaMD ni "estratificação".
- Al subir `DISCLAIMER_VERSION`, todos los usuarios vuelven a aceptar.

### F2. Textos de la interfaz (pt/en/es) — M

Todos los cambios se aplican en `mobile/lib/l10n/app_{pt,en,es}.arb`. Los textos fijos en código (hardcoded) se mueven a l10n.

| Pantalla | IDs | Cambios principales (pt-BR) |
|---|---|---|
| Onboarding | C-01…C-04 | "Triagem Preventiva Unificada" → **"Diário de Bem-Estar Integrado"**; "Registros Médicos Blindados" → **"Seus Dados Protegidos"**; "Orientações Preventivas Precisas" → **"Conteúdos para Hábitos Saudáveis"**. |
| Login / registro | C-34 | "Acesse seu prontuário e histórico de triagens" → **"Acesse seu diário de bem-estar com segurança."** |
| Home | C-30, C-31, C-33 | Nombre de respaldo "Paciente" → **"Olá!"**; "Prontuário Ativo & Protegido" → **"Seus registros estão protegidos"**; "Triagem de Hoje Concluída" → **"Registro de hoje concluído"**. |
| Wizard | C-11…C-15, C-38 | "Autoavaliação" → **"Registro de hoje"**. Opciones emocionales sin nombres de trastornos ("Depressiva", "Burnout", "Insônia" pasan a **"Pra baixo"**, **"Esgotado(a)"**, **"Sono ruim"**). Áreas físicas en lenguaje común ("Sistema Cardiovascular" → **"Peito"**). |
| Resultado | C-17, C-18, C-22, C-32 | "Resultado da Triagem" → **"Resumo do seu registro"**. Se elimina la tarjeta de recomendación de atención (F4). Navegación "Resultado do Dia" → **"Meu Dia"**. |
| Historial y mapa corporal | C-23…C-25 | "Sem dor" → **"Sem registro"**; "Dispneia funcional" → **"Falta de ar, tosse"**; "histórico de triagens" → **"histórico de registros"**. |
| Ajustes, export, notificaciones | C-26…C-29, C-35, C-36 | "histórico clínico" → **"registros de bem-estar"**; emoji 🩺 → 🌿; "Avatares Clínicos" → **"Avatares"**; "Perfis de Saúde" → **"Perfis"**. |
| Offline | C-37 | "Avaliação clínica preliminar em modo desconectado" → **"Registro salvo no aparelho; será sincronizado."** |
| Anuncios | C-40 | "Zero rastreamento clínico" → **"Anúncio não usa seus dados de saúde"** (garantizarlo técnicamente, ver F9). |
| iOS | C-41 | `Info.plist` `NSFaceIDUsageDescription`: **"…proteger o acesso aos seus registros de bem-estar."** El revisor de Apple lo ve. |

**Aceptación:**
- El test de vocabulario (§5) pasa sin excepciones fuera de la pantalla de ayuda.
- No quedan textos en pt-BR fijos en el código de las pantallas tocadas.

### F3. Seguridad: recursos de ayuda siempre disponibles — M

Hoy la pantalla de emergencia solo se abre **dentro del check-in**, cuando el algoritmo decide (`emergency_controller.dart:23`, disparado desde `triage_wizard_notifier.dart:92-103`). Eso es triaje regulado y, además, no está disponible para todos.

| Cambio | Dónde | Detalle |
|---|---|---|
| Botón **"Ajuda urgente"** global | AppBar / barra inferior de todas las pantallas autenticadas + login | Abre la pantalla de recursos. No depende de ningún dato del usuario. |
| Pantalla de recursos estática [B-14, C-07…C-10] | `emergency_screen.dart` | Se puede cerrar (quitar `PopScope(canPop:false)` y el diálogo "Não recomendado"). Título **"Precisa de ajuda agora?"**. Lista **estática** de señales de alarma con fuente oficial (Ministério da Saúde / SAMU). Botones de llamada. Sin badges de condición. |
| Números por país [B-15] | `emergency_screen.dart:175-195` (hoy 192/193/188 fijos) | Tabla por región del dispositivo: BR 192/193/188/190; US 911/988; UE 112 + línea de crisis nacional; ES 112/024; PT 112/808 24 24 24; MX 911. Si no se reconoce el país: 112 y "número local de emergência". |
| Aviso contextual genérico [B-03, B-04] | `red_flag_evaluator.dart`; `triage_wizard_notifier.dart` | Si el usuario marca intensidad 5 (o 4 en pecho, respiración o cabeza), o escribe texto que coincide con las expresiones de alarma, se muestra **la misma tarjeta para todos**: "Se isso for uma emergência, não use o app: ligue 192 agora." No bloquea, no nombra la condición y no asigna nivel. Se eliminan las referencias a Manchester/ESI. |
| Red de seguridad de suicidio [B-04] | `red_flag_evaluator.dart` | **Se mantiene** la detección como seguridad de contenido; solo cambia el texto: recursos 188/192, sin bloquear. |
| Registro de auditoría mínimo [I-05] | tabla `triage_emergency_events` → `safety_resource_events` | Registrar solo "recursos abiertos / llamada iniciada", el perfil y la fecha. Se eliminan `severity_level` y `trigger_category` (LGPD Art. 6 III, minimización). Se mantiene la garantía actual: el registro **nunca falla**, ni sin sesión ni con token vencido. |
| Funcionamiento offline | assets / l10n | Pantalla, lista y números incluidos en la app, sin red. |
| Nunca detrás de un muro de pago | fase 15 | Los recursos de ayuda son gratuitos en todos los planes. |

**Aceptación:**
- Un widget test confirma que desde **cada** pantalla principal se llega a la pantalla de recursos en 1 toque.
- La pantalla funciona en modo avión.
- Ningún flujo bloquea al usuario.

### F4. Motor de resultados: de "triaje" a "diario" — M

| Cambio | Dónde | Detalle |
|---|---|---|
| Eliminar la recomendación de atención [B-01] | `backend/src/modules/triage/services/triage-outcome.service.ts:700-718` | Hoy convierte la intensidad en "auto_cuidado / consulta_rotina / pronto_atendimento / emergencia", y la IA puede forzar "emergencia". Se elimina el cálculo, y `careDisposition` deja de escribirse y de devolverse. En su lugar va un **bloque estático igual para todos**: "Este app não avalia sua saúde. Se algum desconforto persistir, piorar ou te preocupar, procure um profissional de saúde. Em emergência, ligue 192." |
| Check-in rápido [B-02] | `triage-outcome.service.ts:833-840` | Guardar solo el estado declarado (bem / mais ou menos / mal). Sin intensidad inferida ni recomendación. |
| Quitar la tarjeta de recomendación en la app [C-18] | `disposition_card.dart`, `today_triage_summary_card.dart`, `triage_history_detail_modal.dart`, `retrospective_list_view.dart` | El historial muestra **"Intensidade informada: n/5"**. |
| Primacía orgánica [B-09] | `triage-outcome.service.ts:633-690`; `organic_primacy_banner.dart`; `.arb` `outcomeOrganicPrimacy*` | Se elimina el razonamiento diferencial ("descartar causas orgânicas", "somatização"). Nota estática si hay registro físico y emocional el mismo día. |
| Intensidad auto-reportada [B-10] | `intensity-tier.constant.ts`; `mobile/lib/core/clinical/clinical_intensity_tier.dart`; `intensity_meter.dart` | `ClinicalIntensityTier` pasa a `SelfReportedIntensityBand`; se quita `isCritical`. Textos: "Intensidade que você informou". |
| Recurrencia "crítica" [B-11] | `triage-history.service.ts:423-500`; `critical_recurrence_card.dart` | Se convierte en el insight **"Padrões nos seus registros"**, con texto descriptivo y sin juicio clínico. `CriticalRecurrenceDto` pasa a `JournalPatternDto`. |
| Antiburla [B-12] | `antiburla.service.ts`; `.arb` `antiburla*` | Se mantiene como consistencia del diario. Copy: "Isso já apareceu antes?". Renombrar internamente a `RecurrenceCheck`. |
| Regla por sexo biológico [B-13] | `antiburla.service.ts:36-48` | **Eliminar.** Hoy "redirige la evaluación" por discordancia anatómica, lo que es juicio clínico y tiene riesgo de discriminación (LGPD Art. 6 IX). |
| Paso 5 del wizard [B-18] | wizard | "Desfecho/Ação" → **"Revisar e salvar seu registro"**. |

**Aceptación:**
- Las respuestas de `/v1/journal/*` (o `/v1/triage/*` durante la transición) no contienen `careDisposition`, `urgency`, `isCritical` ni `organicPrimacy`.
- Hay un test de contrato que lo verifica.

### F5. Inteligencia artificial — M

| Cambio | Dónde | Detalle |
|---|---|---|
| Nuevo esquema de respuesta [B-05] | `backend/src/modules/ai/services/ai-triage.service.ts:34-54` | `{ isOffTopic, vertical, bodyAreaOrMood, layTerm, mentionsSelfHarm }`. Se eliminan `urgencyScore`, `clinicalConcept` e `isEmergencyCandidate`. |
| Nuevo prompt [B-06] | `ai-triage.service.ts:111-120` | Prompt de "etiquetado de diario": identificar área o emoción y el término usado, **sin** evaluar gravedad, diagnosticar ni sugerir conducta. El texto del usuario va como contenido separado, no interpolado (mitiga *prompt injection*). |
| Base de conocimiento [B-07, B-08] | `symptom-knowledge.schema.ts` (`urgency_score`, `clinical_concept`, `is_emergency_candidate`); `symptom-knowledge.seed.ts` | Migración: eliminar esas columnas o dejar de usarlas, y limpiar el seed. **Verificar además** que `input_text` no guarde texto literal de usuarios en una tabla compartida entre usuarios. Si lo hace, guardar solo términos normalizados (minimización). |
| Tarjeta de IA en la app [B-16] | `ai_insight_card.dart` | "Informação Clínica Complementar" pasa a **"Como organizamos sua anotação"**. Muestra `layTerm` y el área, nunca un concepto médico. |
| Renombrar servicio [D-07] | `AiTriageService` → `AiTaggingService`; endpoint `/v1/ai/classify-symptom` → `/v1/ai/tag-entry` (con alias) | |
| Proveedor y residencia (ver F9) | `backend/src/common/ai/gemini.service.ts` | Hoy usa **Gemini Developer API por API key** (`gemini-2.5-flash`), no Vertex AI en São Paulo. |

**Aceptación:**
- El JSON Schema del modelo no tiene campos de urgencia ni de concepto médico.
- La batería de pruebas de IA mide calidad del etiquetado, no concordancia clínica.

### F6. Modelo de datos, API y compatibilidad — L

| Cambio | Detalle |
|---|---|
| Migración `0015_wellness_repositioning.sql` | (a) `symptom_logs`: dejar de escribir `disposition` y `organic_primacy_applied`. Se conservan solo para la exportación LGPD de datos históricos, marcados como `legacy`, y se eliminan tras definir la política de retención. (b) `triage_emergency_events` → `safety_resource_events` con columnas mínimas. (c) `symptom_knowledge`: quitar las columnas clínicas. |
| Rutas de la API [I-01] | `/v1/triage/*` → `/v1/journal/*`; `/v1/triage/emergency-event` → `/v1/journal/safety-event`; `/v1/ai/classify-symptom` → `/v1/ai/tag-entry`. Las rutas viejas quedan como **alias** durante 2 versiones de la app. |
| Rutas de la app [I-02] | `/triage` → `/checkin`; `/triage-outcome` → `/checkin-summary`. Quitar "Sintomas autolimitados" (`app_router.dart:154`). |
| Modelos en la app [I-03, I-04] | Eliminar `CareDisposition`, `aiClinicalConcept`, `urgencyScore` e `isEmergencyCandidate` de `triage_outcome_models.dart` y `symptom_classification.dart`. |
| Versiones viejas de la app | Las versiones publicadas esperan `careDisposition`. **No hay mecanismo de versión mínima** en el código actual, así que hay que crearlo: el backend responde con la versión mínima soportada y la app vieja muestra "actualizar". Hasta que la versión nueva sea obligatoria, la API devuelve `careDisposition: null`, y hay que verificar que la versión actual lo tolere sin errores. |
| Base local (Drift) | Schema v5 si hace falta quitar campos de disposición del outbox. |

**Aceptación:**
- La migración es idempotente y está probada sobre una copia de producción en staging.
- Las versiones viejas de la app siguen funcionando o muestran "actualizar".
- `test:rls` está en verde.

### F7. Documentación interna y agentes — M

Estos documentos también cuentan como evidencia de uso previsto (MDR Art. 2(12), FDA "objective intent").

| Documento | Cambio |
|---|---|
| `CLAUDE.md` [D-01] | Reemplazar "AI-powered preventive triage", "Level 4/5 … emergency red screen" y "19-category clinical taxonomy" por la §1.1. "Clinical Safety" pasa a "Safety: help resources always reachable". |
| `.planning/PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md` [D-02…D-04] | Reescribir los requisitos TRG-02, SOM-02, OUT-01, REC-01, EMRG-01..03 y DISC-01 según F3 y F4. La fase 3 pasa a "Always-on Safety Resources". |
| Agente "Médico Clínico" [D-05] | `.agents/agents/doctor/*` se convierte en un **agente de seguridad de contenido**. Verifica que los recursos de ayuda sean accesibles, que no haya salidas de urgencia ni diagnóstico y que no aparezca vocabulario vetado. Casos nuevos, p. ej.: "texto con dolor de pecho → la app muestra recursos genéricos y no nombra ninguna condición". |
| Métricas de la batería [D-06] | Eliminar "Concordancia Clínica 100%", que es justamente evidencia de desempeño de un SaMD. Nuevas métricas: vocabulario vetado = 0; recursos de ayuda a ≤1 toque desde todas las pantallas. |
| Agente revisor de IA [D-07] | Calibra el etiquetado, no el triaje. |

### F8. Cambios en el roadmap (fases 12 a 15)

| Fase / función | Decisión | Cómo |
|---|---|---|
| 3. Alerta de riesgo | Reformular | Ver F3. |
| 11. Multi-perfil | Mantener | Ya implementado. Revisar COPPA (EE. UU., menores de 13) y la edad de consentimiento GDPR Art. 8 por país. |
| 12. Cartera de vacunas | Mantener | Registro personal. Recordatorios solo del calendario oficial (PNI), mostrado tal cual. |
| 12. Alergias con verificación cruzada | **Quitar el cruce** / mantener el registro | Detectar conflictos alergia-medicamento es una función de dispositivo médico. |
| 13. Condiciones CID | Mantener, reformulado | "Minhas condições (informadas por você)". Nunca sugerir códigos a partir de síntomas. |
| 13. Alarmas de medicamento | Mantener | Recordatorios de lo que el usuario configuró, sin ajuste de dosis. |
| 13. PDF SBAR para el médico | Reformular | "Resumo dos meus registros", sin las secciones Assessment y Recommendation. |
| 14. OCR de exámenes | Reformular o derivar a un socio | Solo transcripción **confirmada por el usuario** y rango impreso por el laboratorio. Sin colores normal/alterado, sin alertas y sin comentarios de IA. Si el negocio necesita interpretación, hacerlo con un socio regulado. |
| 14. Lector de recetas | Reformular (alto riesgo) | Solo prellenar un formulario editable, con confirmación campo por campo. Nunca crear alarmas automáticas. Recomendación: posponerlo hasta tener al consultor. |
| 14. Resumen de prospecto (bula) con IA | **Quitar** o derivar a un socio | Enlazar al Bulário Eletrônico de ANVISA, o licenciar contenido de un proveedor regulado. |
| 15. Voz | Reformular | "Registro por voz". Sin biometría de voz salvo necesidad; si se usa, es dato biométrico. |
| 15. Biometría y suscripciones | Mantener | Sin promesas clínicas en el muro de pago. Recursos de ayuda gratuitos. |

### F9. Privacidad y cumplimiento (obligatorio igual) — M

| Cambio | Detalle |
|---|---|
| IA y residencia de datos | Migrar de la Gemini Developer API (API key) a **Vertex AI** en región Brasil o UE. Si no se migra: declarar la transferencia internacional (LGPD Art. 33, Res. CD/ANPD 19/2024) con cláusulas contractuales. Confirmar un plan **sin entrenamiento con datos del usuario** y firmar un DPA. Hoy contradice la promesa de residencia en São Paulo. |
| RIPD / DPIA | Informe de impacto (LGPD Art. 38; GDPR Art. 35). |
| DPO | Encargado publicado (LGPD Art. 41). Representante en la UE (GDPR Art. 27) si no hay establecimiento allí. |
| Incidentes | Procedimiento de notificación: ANPD en 3 días hábiles; GDPR en 72 h; FTC HBNR en ≤60 días. |
| Publicidad (AdMob) | Solo anuncios contextuales. Ningún dato de salud a la red publicitaria (Apple 5.1.3, FTC HBNR, My Health My Data Act). Sin geolocalización cerca de centros de salud. |
| Menores | COPPA (EE. UU.), GDPR Art. 8 y LGPD Art. 14 para dependientes. |
| Base de datos de producción | Confirmar que el rol de la app **no** tiene `BYPASSRLS` antes de desplegar las migraciones 0013 a 0015. |

### F10. Tiendas y marca

| Cambio | Detalle |
|---|---|
| Ficha de App Store / Google Play | Categoría **Salud y forma física / Health & Fitness**. Descripción basada en la §1.1. Subtítulo "Diário de bem-estar". Evitar "CheckUp" como promesa de chequeo médico [I-06]. |
| Declaraciones | Apple: etiqueta de privacidad. Google: Health apps declaration y Data safety. |
| Revisión de Apple 1.4.1 | Respuesta preparada que explique el uso previsto y la ausencia de diagnóstico. |

---

## 4. Etapas de ejecución

| Etapa | Duración estimada | Frentes | Resultado |
|---|---|---|---|
| 1. Riesgo inmediato | Semana 1 | F0, F1, F2 (onboarding, login, legal), F7 | Desaparece la mayor parte de la evidencia escrita de uso médico. Se cierra el riesgo de atribución falsa. |
| 2. Comportamiento | Semanas 2-3 | F3, F4, F5 | La app deja de **hacer** triaje. La ayuda queda disponible para todos. |
| 3. Datos y API | Semana 4 | F6, resto de F2 | Rutas y modelos sin vocabulario clínico; compatibilidad con versiones viejas. |
| 4. Validación | Semana 5 | Pruebas §5, sesión en vivo, revisión del consultor | Versión candidata y documentación para el consultor. |
| En paralelo | Semanas 1-5 | F9, F10 | Cumplimiento de datos y fichas de tienda. |
| Decisión de negocio | Antes de la fase 14 | F8 | Roadmap ajustado. |

Las estimaciones suponen el equipo actual trabajando con agentes en paralelo, como en la fase 11. La revisión del consultor externo no está incluida en los plazos.

---

## 5. Plan de pruebas

| Prueba | Tipo | Qué verifica |
|---|---|---|
| Vocabulario vetado | Test automático (Dart + Node) | Recorre `.arb`, textos en `lib/` y respuestas de la API buscando los términos de §2. Falla si aparecen fuera de la pantalla de ayuda. |
| Contrato de la API | e2e backend | Ninguna respuesta incluye `careDisposition`, `urgencyScore`, `clinicalConcept`, `isEmergencyCandidate` ni `isCritical`. |
| Esquema de IA | unit backend | El `responseSchema` enviado a Gemini no contiene campos de evaluación. |
| Acceso a la ayuda | widget tests | Botón "Ajuda urgente" en todas las pantallas principales, a 1 toque; pantalla que se puede cerrar; funciona sin red. |
| Aviso contextual | widget tests | Intensidad 5 o texto de alarma muestran **la misma** tarjeta genérica, sin nombre de condición. |
| Registro de seguridad | e2e + RLS | `safety-event` responde 201 con sesión, sin sesión y con token vencido. |
| Migración 0015 | RLS + staging | Idempotente; los datos históricos siguen disponibles en la exportación. |
| Versiones viejas de la app | manual | La versión publicada no falla con `careDisposition: null`, o muestra "actualizar". |
| Sesión en vivo | simulador + backend local con RLS | Recorrido completo de un registro con lectura de pantallas y capturas, como en la fase 11. |
| Batería de agentes | `npm run test:battery` | Nuevas métricas (F7). |

---

## 6. Riesgos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| La propuesta de valor depende de "decirle al usuario qué tan urgente es lo que siente". | Alto | Es una decisión de negocio (§7). Si es así: lanzar el diario ahora y desarrollar el triaje como producto regulado aparte o con un socio. |
| Usuarios actuales acostumbrados a la recomendación. | Medio | Comunicado en la app y bloque estático claro; insights de patrones como reemplazo de valor. |
| Versiones viejas de la app sin mecanismo de versión mínima. | Medio | F6: crear el mecanismo antes de quitar campos de la API. |
| Pérdida de "precisión" percibida al quitar la IA clínica. | Medio | La IA sigue organizando y resumiendo el diario; mejor diseño de insights. |
| Datos ya enviados a Gemini por API key. | Alto (privacidad) | F9: revisar el plan contratado, la retención y el DPA; evaluar si corresponde notificar. |
| Contenido con autores no verificados ya publicado. | Alto (legal) | F0 en la semana 1; revisión legal sobre posibles comunicaciones. |

---

## 7. Decisiones pendientes del cliente

1. **Propuesta de valor:** ¿se acepta que la app no indique urgencia? Si no, hay que definir la estrategia del producto regulado o del socio.
2. **Autores de artículos:** ¿existen contratos con los profesionales citados? Si no, se eliminan (F0).
3. **Proveedor de IA:** ¿se migra a Vertex AI con región Brasil/UE, o se declara la transferencia internacional?
4. **Fase 14:** ¿interpretación de exámenes con un socio regulado, o solo transcripción?
5. **Nombre comercial:** ¿se mantiene "CheckUp" en la ficha de tienda?
6. **Consultor regulatorio:** quién y cuándo, para validar antes del lanzamiento.

---

## Apéndice A. Trazabilidad auditoría → frente

| Frente | IDs de la auditoría |
|---|---|
| F0 | C-19, C-20, C-21 |
| F1 | L-01…L-07, C-05 |
| F2 | C-01…C-41 (excepto C-07…C-10, C-18, C-19, C-20, C-21) |
| F3 | B-03, B-04, B-14, B-15, C-07…C-10, I-05, §4 |
| F4 | B-01, B-02, B-09…B-13, B-18, C-18 |
| F5 | B-05…B-08, B-16, D-07 |
| F6 | I-01…I-04 |
| F7 | D-01…D-07 |
| F8 | §5 de la auditoría |
| F9 | §6 de la auditoría |
| F10 | I-06, §6 Tiendas |

El detalle línea por línea de cada hallazgo, con el texto actual y el propuesto, está en `ANEXO-AUDITORIA-USO-PREVISTO.md` (entregado junto con este plan).
