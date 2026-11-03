# Informe de desvíos: app actual vs. pedido del cliente "Dualis Free"

**Fecha:** 2026-11-02 · **Base:** código en disco en `main` (incluye cambios sin commit) · **Método:** 4 revisores en paralelo, solo lectura, y verificación manual de los hallazgos principales.

Detalle por área:
- [01 — Cadastro y UX](01-cadastro-ux.md)
- [02 — Flujo emocional](02-flujo-emocional.md)
- [03 — Flujo físico](03-flujo-fisico.md)
- [04 — Datos, reportes y uso previsto](04-datos-reportes-regulatorio.md)
- Pedido transcrito: [ESPEC-CLIENTE.md](ESPEC-CLIENTE.md)

---

## 1. Resumen ejecutivo

1. **La estructura sí está:** 3 verticales temporales, las 12 opciones emocionales con sus emojis, las 18 opciones físicas (más 2 añadidas), un mapa corporal tocable, primero persistencia y luego intensidad, y rotación aleatoria de frases.
2. **Lo conversacional se perdió casi todo.** El cliente pidió 7 frases por posición, 105 frases en total. La app tiene 3 o 4 por posición, ninguna con su texto exacto, y **0 de las 42 frases de bifurcación**. Tampoco existen la frase de cierre ("Obrigado por compartilhar…"), el efecto de escritura ni las preguntas propias de cada pantalla. Es el desvío más visible para el cliente, y en buena parte **no está justificado por escrito**.
3. **"Pocas opciones por pantalla" no se cumple.**
   - Emocional: el cliente pidió 3 botones y luego 2. La app los fusiona en una pantalla de 7 filas.
   - Físico: el cliente describió 4 pantallas y la app tiene 8, con un paso extra ("É dor ou incômodo?") y ramas de 3 botones.
4. **Lo clínico se quitó a propósito**, y está documentado: grupos DSM-5/CID-11, síntoma estructurado, "Esferas", "possível diagnóstico", verticales de tratamiento, semáforo y ☠️. Si se hiciera como pide el cliente, la app pasaría a ser un dispositivo médico (ANVISA RDC 657/2022) y se rompería el uso previsto de bienestar. **Esto no se negocia en código; hay que explicárselo al cliente.**
5. **Queda un riesgo regulatorio real, ajeno al pedido:** los endpoints antiguos de triaje (`/v1/triage/outcome`, `/daily-checkin`) siguen activos en el backend y clasifican por sistema corporal o dimensión emocional.

---

## 2. Desvíos sin justificar (corregir o documentar)

Orden por impacto en lo que el cliente ve.

| # | Desvío | Pidió el cliente | Hay hoy | Evidencia |
|---|---|---|---|---|
| D1 | Frases de bifurcación | 7 por cada uno de los 6 botones de la pantalla 2 (42) | 0 | 02 §Pantalla 2 |
| D2 | Frases por vertical | 7 por vertical, texto del cliente | 3 genéricas, ninguna textual. La estrategia §7 filtraba solo las frases riesgosas, pero también se cayeron frases que §7 no objetó | 02, 04 |
| D3 | Frases por región física | 7 por región (35) | 4 genéricas compartidas entre todas las regiones; ninguna en la pantalla final | 03 |
| D4 | Pantallas 1 y 2 del flujo emocional fusionadas | 3 botones ⏳📍🚀, luego 2 botones | 1 pantalla con 7 filas bajo 3 encabezados de texto, sin emojis temporales. Solo lo explica un comentario "v2.3"; la estrategia §5 aún las describe separadas | 02, 01 |
| D5 | Preguntas del cliente | "O que está ocupando mais espaço na sua mente agora?" + 3 preguntas de bifurcación | "O que pesa mais agora?" (`jv23WhatWeighsQuestion`). La pregunta aprobada en §5 (`jv2TimeQuestion`) existe en l10n pero **no se usa en ningún lado** (verificado) | 02 |
| D6 | Frase de cierre | "Obrigado por compartilhar isso comigo hoje…" | No existe en la app ni en el backend (verificado) | 02, 03 |
| D7 | Emojis en el flujo físico | Emoji en cada botón y cada opción | Ninguno, salvo 🚽 y 🧪 en pelvis: queda inconsistente con el flujo emocional | 03 |
| D8 | Efecto de escritura en las transiciones | Fade-in + escritura suave | Solo fade de 280 ms | 01 |
| D9 | Emojis en "bem / não tão bem" | Emojis | Iconos Material | 01 |
| D10 | Nombres de los niveles de intensidad | Leve / Notável / Desgastante / Severo | Solo números con descripción. §8 solo quita "Paralisante"; quitar los demás no está escrito | 02, 03 |
| D11 | Persistencia e intensidad | 2 pasos (2 pantallas) | 1 pantalla compartida + 3 pasos opcionales (disparadores, qué ayudó, nota) | 02, 03 |
| D12 | Opciones de pelvis que nadie pidió | — | "Dificuldade ou fluxo fraco ao fazer xixi", "Urina escura ou com cheiro forte". No están en ningún documento (verificado) y se parecen a un verificador de síntomas | 03 |
| D13 | Textos físicos acortados | Texto del cliente | Se perdieron "dificuldade de engolir", "palpitação", "refluxo ácido"; solo 2 recortes tienen justificación escrita | 03 |
| D14 | PDF "Resumo dos meus registros" | Exportar para llevar a un profesional | Solo en Premium. La estrategia lo ponía en Free; en Free queda solo el JSON de LGPD | 04 |
| D15 | Coincidencias físico-emocionales | Correlación | Se calculan en backend y app, pero **ninguna pantalla las muestra** | 04 |
| D16 | Reporte de tendencia | 14 días + frase resumen + día de la semana | 7 o 30 días, sin frase, sin conteo por día de la semana (este último es compatible con bienestar) | 04 |
| D17 | Cuadrantes de tendencia (4, incluido el positivo) | Sí | No existen. Lo positivo se registra de otra forma (momentos buenos, qué ayudó), pero ningún documento descarta los cuadrantes | 04 |

---

## 3. Desvíos intencionales (comunicar al cliente)

Ya decididos y documentados. No se implementan como los pidió el cliente.

| Pedido | Decisión | Documento | Alternativa en la app |
|---|---|---|---|
| Tag clínica, síntoma estructurado, Grupo 01–12 DSM-5/CID-11 | Eliminado | Estrategia §2, §18 decisión 1 | Se guarda solo la opción elegida por la persona (`optionKey`) |
| "Esferas" 01–18 del flujo físico | Eliminado | §18 decisión 1 | Zona + opción, sin clasificar por sistema |
| "Possível diagnóstico" (≥4 días/semana, ≥10/mes) | Eliminado | §2, §18 | Historial y conteos que la persona ve de sí misma |
| Verticales de tratamiento (psiquiatría, TCC, psicoanálisis…) | Eliminado | §2, §18 | Recursos de ayuda estáticos, iguales para todos |
| Semáforo 🟢🟡🟠🔴 y ☠️ "Paralisante/Incapacitante" | Eliminado | §8 | Escala 1–5 con descripción neutra |
| Frases con lenguaje clínico o de alarma ("sinal de alerta sério", "pedindo arrego"…) | Reescritas o quitadas | §7 | 3–4 frases neutras por posición |
| Extra: mapa con más zonas y más opciones, multiselección | Añadido | Contrato journal v2.1–v2.3, §18.2–18.3 | — |
| Recorte de foto manual (sin detección de rostro) | Decidido | §13 | Pantalla de recorte circular con zoom y arrastre |
| Saludo solo con el primer nombre | Decidido | Estrategia | "Olá Seres, bom dia" |

**Por qué no se puede hacer lo clínico:** almacenar "silenciosamente" un grupo diagnóstico por persona, disparar "possível diagnóstico" y derivar a psiquiatría es procesar datos de un paciente individual con finalidad diagnóstica. Eso es SaMD según la ANVISA RDC 657/2022 (MDR Regla 11 en la UE: clase IIa o superior). Además contradice la declaración de uso previsto que ya está en los Términos, en las fichas de las tiendas y en `CLAUDE.md`. Que la capa sea invisible para el usuario no cambia nada: el regulador mira lo que el software hace con los datos. Ver [INTENDED-USE-AUDIT.md](../../../.planning/INTENDED-USE-AUDIT.md).

---

## 4. Lo que la app añadió sin que el cliente lo pidiera

- Flujo físico: región Pelve; ramas Rosto, Nuca e Intestino; cólica menstrual (oculta para hombres); 3 áreas de "cuerpo entero"; paso "É dor ou incômodo?"; 2 opciones extra para las ramas que en el pedido tenían 1 sola ("Dor ao mexer", "Sensação de choque").
- Cierre: 3 pasos opcionales (disparadores, qué ayudó, nota libre) y una línea fija del 192 bajo la escala.
- En conjunto, esto va contra el pedido de "pocas opciones por pantalla, sin menús profundos".

---

## 5. Cadastro (sección 1 del pedido)

- **Foto que corta la cabeza:** la causa era el avatar circular con recorte centrado sobre una selfie vertical. Ya existe una pantalla de recorte manual (`photo_crop_screen.dart`, commit `b9c94a7`). Pendiente:
  1. Las fotos guardadas antes del cambio siguen cortadas.
  2. Una foto vertical sin zoom queda con franjas transparentes.
  3. Sin detección de rostro, el encuadre inicial puede no centrar la cara.
- **"¿Para qué sirven los 3 elementos de abajo?"** La pantalla que el cliente llama "cadastro" es **Configurações**, no el registro. Los 3 accesos funcionan (privacidad, historial, panel de agua), pero están bajo "Privacidade e Dados" con subtítulos técnicos, así que no se entiende para qué son. El historial casi no tiene otra entrada en la app. Es un problema de copy y de ubicación, no de funcionalidad.

---

## 6. Riesgo regulatorio residual (no lo pidió el cliente, pero salió en la revisión)

- **Eliminación completada (2026-11-02):** Se eliminaron definitivamente del backend los endpoints `POST /v1/journal/outcome`, `POST /v1/journal/daily-checkin` y sus alias `/v1/triage/*` en `triage.controller.ts`, junto con sus DTOs (`triage-outcome.dto.ts`, `daily-checkin.dto.ts`), el servicio `TriageOutcomeService` y los servicios/seeds de artículos recomendados (`articles-catalog.service.ts`, `article-embedding.service.ts`, `articles-vector.service.ts`, seeds). Ahora responden 404. Se conservaron `GET history`, `DELETE history/:id` y `POST recurrence-check|antiburla-check` con sus servicios bajo ambos prefijos (`/v1/journal/` y `/v1/triage/`).
- En la app móvil, se eliminaron los llamadores (`api_endpoints.dart`, el feature `triage_outcome`, `TriggerCheckInController`, `DualAxisTriggerCard`, `TodayTriageResultTab`, `AxisIntensityResolver` y `triage_vertical.dart`). El `SyncOutboxWorker` descarta de forma permanente e inocua cualquier ítem pendiente en cola de los endpoints antiguos sin errores ni reintentos, manteniendo la sincronización normal de entradas de diario v2.
- Ayuda a ≤1 toque: **se cumple** en todas las pantallas del diario.

---

## 7. Inconsistencias del propio pedido

Hay que aclararlas con el cliente antes de tocar el texto:
- La numeración de los grupos cambia entre versiones (Dissociativos 06/08, TOC 10/11).
- `reatividade_ambiental` se usa para dos cosas distintas.
- La pantalla 2 del flujo físico promete 20 caminos y la pantalla 3 trae 18.
- El orden del cierre cambia entre versiones.
- Pide "history storage sin diagnóstico" y a la vez "alerta clínico / possível diagnóstico".

---

## 8. Recomendación

**Hacer ya** (compatible con bienestar, bajo riesgo, es lo que el cliente más va a notar):
1. Restaurar el flujo emocional en 3 pantallas, con los botones ⏳📍🚀 y la pregunta del cliente (D4, D5).
2. Ampliar los bancos de frases a 7 por posición, usando los textos del cliente que pasan el filtro de §7. Incluir las de bifurcación y las de región física (D1–D3).
3. Añadir la frase de cierre, el efecto de escritura y emojis en el flujo físico y en "bem / não tão bem" (D6–D9).
4. Separar persistencia e intensidad en 2 pasos y recuperar los nombres de nivel no alarmistas, como Leve y Notável (D10, D11).
5. Quitar o documentar las 2 opciones urinarias (D12).

**Decidir con el cliente:**
- Recortar las zonas y opciones extra del flujo físico para cumplir "pocas opciones" (sección 4).
- El PDF de resumen: ¿Free o Premium? (D14)
- Mostrar las coincidencias físico-emocionales y el conteo por día de la semana, redactados en lenguaje descriptivo y sin interpretar (D15, D16).

**Comunicar por escrito al cliente:** la sección 3, con la razón regulatoria, más el descarte de los cuadrantes (D17), o bien implementarlos como "cómo te sentiste", sin etiquetas clínicas.

**Técnico:** endpoints antiguos de triaje eliminados (sección 6, 2026-11-02).
