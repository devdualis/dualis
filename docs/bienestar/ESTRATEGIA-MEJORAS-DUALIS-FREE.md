# Dualis Free: análisis de las mejoras propuestas y plan de estrategia

**Versión:** 1.0 | **Fecha:** 26/10/2026
**Fuente analizada:** "2026 Dualis Free melhorias SB. 1" (documento del cliente; en su mayor parte, una conversación con el Modo IA de Google)
**Base técnica:** rama `main` (commit `d0a2bb9`), después del reposicionamiento a bienestar (`06ada1f`) y del plan `docs/bienestar/PLAN-TECNICO-BIENESTAR.md`

> **Aviso.** Este documento no es asesoría legal ni regulatoria. Un consultor regulatorio (ANVISA) y un abogado de protección de datos deben validar la versión final antes del lanzamiento.

---

## 1. Resumen ejecutivo

1. **La mayoría de las ideas de UX son buenas y se adoptan:** pocas opciones por pantalla, emojis y toques en vez de lectura, flujo conversacional Pasado / Presente / Futuro, mapa del cuerpo para tocar la zona, frases de transición variadas, gráficos de 30 días, botón de ayuda fijo, biblioteca de lecturas sin recomendaciones personalizadas.
2. **El núcleo del documento convierte a Dualis en un dispositivo médico, y hay que descartarlo.** Cada respuesta se traduce a un "sintoma estruturado clinicamente" y se asigna a uno de **12 grupos clínicos** (Depresión, TEPT, Pánico, TAG, TOC, Bipolar, Personalidad…) o a una de **18 "esferas" corporales** (Costocondritis, Radiculopatía, Isquemia…). Después, el historial se usa "para que el médico cierre el diagnóstico" o para indicar una vertical de tratamiento (Psiquiatría, TCC…). Eso es, por definición, software que procesa datos de salud para apoyar un diagnóstico.
3. **Esconder la clasificación en el backend no la vuelve legal.** El documento propone "UI amigable + backend que traduce en silencio a grupos clínicos". El regulador mira lo que el software **hace**, no solo lo que muestra. Además, inferir trastornos mentales sin que el usuario lo sepa viola la LGPD (transparencia y finalidad, Art. 6) y es dato sensible inferido (Art. 11). El documento de la IA que "corrige los términos" solo cambió nombres: las etiquetas internas siguen siendo clínicas (`estresse_traumatico`, `anedonia_embotamento`, `desamparo_aprendido`, `ansiedade_cognitiva`).
4. **Regla de oro para todo el producto:** Dualis **guarda y muestra lo que el usuario eligió, con sus propias palabras.** Nunca traduce, agrupa en categorías de salud, interpreta, puntúa ni recomienda en función de las respuestas. Contar y mostrar sí; interpretar no.
5. **Los temores del cliente sobre la pantalla de emergencia son correctos.** El botón universal ya está implementado. Falta quitar los avisos que dependen de lo que escribe el usuario (§10).
6. **Plan:** 5 etapas en unas 6 a 7 semanas (§15). La primera (texto y reglas editoriales) no requiere código y desbloquea todo lo demás.

---

## 2. Bienestar vs. dispositivo médico: la línea que no se cruza

El cliente pidió que la app no sea "de salud", sino de **salud y bienestar**, para no tener que certificarla. Lo que define la categoría es el **uso previsto**, y el regulador lo deduce de tres cosas: lo que el software hace, lo que la empresa dice (interfaz, tienda, marketing) y lo que dicen los documentos internos (incluido este análisis y el documento del cliente).

| Permitido (bienestar) | Prohibido (dispositivo médico) |
|---|---|
| Guardar lo que el usuario eligió: "Fico antecipando problemas", intensidad 3 que **informó**. | Convertir esa elección en "Ansiedade cognitiva / Grupo 09 TAG". |
| Contar: "Você marcou 'Cabeça' em 8 dos últimos 30 dias." | Interpretar: "Seu padrão indica tendência a enxaqueca." |
| Mostrar coincidencias: "Nos dias com 'mente acelerada', você também marcou 'Cabeça' em 5 de 7." | Explicar causas: "Sua dor de cabeça sobe quando sua mente acelera." |
| Biblioteca general, igual para todos, con fuente pública. | "Leia isto" en función de las respuestas (el propio documento lo advierte). |
| Botón de ayuda fijo, igual para todos. | Pantalla de emergencia que aparece según lo que la persona respondió. |
| Exportar "Resumo dos meus registros" con fechas y palabras del usuario. | Exportar "sintomas estruturados" agrupados por categoría diagnóstica "para o médico fechar o diagnóstico". |

**Documentos internos:** el documento del cliente y cualquier especificación con "grupo clínico", "diagnóstico" o "vertical de tratamiento" es evidencia de uso médico. Se recomienda no incorporarlo al repositorio tal cual y archivarlo como material descartado.

**Argumento adicional, no regulatorio:** la correspondencia propuesta es clínicamente incorrecta. Una sola respuesta ("desânimo com o rumo das coisas") no indica espectro bipolar, ni "fico remoendo mágoas" indica trastorno de personalidad. Etiquetar así a una persona, aunque sea en silencio, es un riesgo de daño y de reputación.

---

## 3. Semáforo del documento, punto por punto

**Verde:** se adopta. **Amarillo:** se adopta con cambios. **Rojo:** se descarta.

| # | Propuesta del documento | Veredicto | Motivo / ajuste |
|---|---|---|---|
| 1.1 | Foto de cámara que corta la cabeza | Verde | Bug real: la foto se toma sin recorte y se muestra centrada (`settings_screen.dart:80`). Ver §13. |
| 1.2 | ¿Para qué sirve la parte inferior del registro? (Privacidad, Historial, Hidratación) | Amarillo | El cliente no entiende su función, así que sobra. Simplificar (§13). |
| 2.1 | Priorizar interacción gráfica (emojis, colores, controles rápidos) | Verde | |
| 2.2 | Pocas opciones por pantalla, sin menús profundos | Verde | Máximo 2 a 4 opciones por pantalla. |
| 2.2.1 | Saludo "Olá Seres Baum, bom dia" | Verde | Nombre + saludo según la hora. |
| 2.2.2 | "Como você está emocionalmente?" con emojis (bem / não tão bem) | Verde | |
| — | Ramas Pasado / Presente / Futuro con 2 bifurcaciones y 12 opciones finales | Verde | Buena UX. Las 12 opciones se guardan como **la elección del usuario**, no como grupo (§5). |
| — | 7 frases de transición por pantalla | Amarillo | Idea buena, pero cerca de un tercio de las frases interpretan o alarman. Reglas editoriales y reescritura en §7. |
| — | "Sintoma estruturado clinicamente" + "12 grupos clínicos" | **Rojo** | Ver §2. |
| — | Persistencia ("há quanto tempo") antes de la intensidad | Verde | Orden correcto. |
| — | Escala de intensidad de 5 niveles | Amarillo | Quitar ☠️ y "exige atendimento urgente". Textos en §8. |
| — | Kahneman (Sistema 1 rápido / Sistema 2 reflexivo) | Verde | Como criterio de diseño de UX, no como "método clínico". |
| — | Puntajes por vertical de tratamiento (Psiquiatría, TCC, Psicoanálisis, Estilo de vida) | **Rojo** | Es recomendación de tratamiento. |
| — | Informe mensual "abordagem TCC é a mais recomendada" | **Rojo** | |
| — | "Predomínio de Futuro = tendência à ansiedade" | **Rojo** | Interpretación. Solo se muestra la proporción, sin etiqueta. |
| — | Registro físico tocando el mapa del cuerpo | Verde | Ya existe un mapa anatómico (`anatomical_body_map.dart`); se reutiliza como entrada. |
| — | 18 "esferas" corporales con diagnósticos (Costocondrite, Radiculopatia…) | **Rojo** | Se guarda solo la región y la descripción elegida. |
| — | Informes: varias anomalías en un mismo registro (barriga + cabeza) | Verde | Hoy el registro físico permite una sola categoría. Pasa a ser múltiple. |
| — | Gráficos de la versión Free con 30 días | Verde | Hoy son 14 días (`dashboard_controller.dart:48`) y 7 en hidratación. |
| — | Fondos con fotos de ambientes y personas felices (Free) | Amarillo | Licencias, contraste y peso de la app (§12). En pantallas emocionales, mejor paisajes que caras sonrientes. |
| — | Hidratación tan interactiva como el check-up | Verde | §11. |
| — | Anuncio después de cada registro y después de registrar agua | Amarillo | Sí a anuncios propios; no a interstitials que bloquean justo después de un registro emocional (§14). |
| — | Anuncios de Dualis Premium, ZOC, WGI, UBO | Amarillo | Confirmar qué son. No pueden prometer beneficios de salud. |
| — | No inducir lecturas según las respuestas | Verde | Coincide con la regla R6 del plan vigente. |
| — | Biblioteca organizada por grupos **clínicos**, psicoemocionales y de dolores | Amarillo | Sí a la biblioteca; no a categorías clínicas. Temas de bienestar (§9). |
| — | Mensaje final: "artigos elaborados por profissionais especializados" | Amarillo | Solo si es verificable. Mejor "fontes públicas, como o Ministério da Saúde". |
| — | Pantallas de emergencia condicionadas: evaluar si quitarlas | Verde | Quitar las condicionales; dejar el botón universal (§10). |
| — | Gráficos: Sankey o mapa arriba (macro) + líneas abajo (micro) | Amarillo | Sí, con textos descriptivos. Fuera "período ciclotímico" (§9). |

---

## 4. Estado actual vs. objetivo

| Área | Hoy (código en `main`) | Objetivo |
|---|---|---|
| Entrada emocional | Pantalla con 7 categorías (`triage_question_bank.dart`: ansiosa, depressiva, burnout, somática, sono, cognitiva, autoestima). Claves internas con nombres clínicos. | Emoji "bem / não tão bem", luego Pasado / Presente / Futuro, bifurcación de 2 opciones, 1 de 12 opciones finales. |
| Entrada física | Lista de 12 sistemas (cardiovascular, neurológico, endócrino…). Una sola selección. | Toque en el mapa (frente y espalda), 5 regiones, 2 opciones y luego 2 más. Varias zonas por registro. |
| Pasos comunes | Naturaleza → Persistencia → Desencadenante → Intensidad (3 niveles en lo emocional) → Resumen | Persistencia → Intensidad de 5 niveles. El desencadenante pasa a ser opcional o se elimina. |
| Frases | Textos fijos | 3 a 7 variantes aprobadas por pantalla, elegidas al azar en la app. |
| Historial y gráficos | 14 días; línea emocional; mapa de calor; barras de agua de 7 días | 30 días en Free; distribución Pasado/Presente/Futuro + mapa arriba; línea abajo; coincidencias descriptivas. |
| Ayuda urgente | Botón rojo en la barra inferior + overlay en pantallas sin barra (hecho). Avisos condicionados por texto e intensidad (`red_flag_evaluator.dart`). | Solo botón universal + línea fija en la pantalla de intensidad. Decisión pendiente sobre el texto de autolesión (§10). |
| Anuncios | `admob_banner_container.dart`: contenedor sin SDK de anuncios | Tarjeta de anuncio propio (house ad) en la pantalla de resumen, sin SDK ni datos compartidos. |
| Biblioteca | Artículos ligados al resultado (`curated_articles_catalog.dart`) | Biblioteca general por temas, igual para todos, a la que se accede desde un menú y desde el mensaje final. |
| Foto | Sin recorte; se muestra centrada | Recorte circular con zoom y arrastre. |

---

## 5. Nuevo registro emocional (flujo final)

**Pantalla 0:** "Olá, {nome}! Bom dia." → "Como você está se sentindo hoje?" → 😊 Bem · 🙂 Normal · 😕 Não tão bem.
Bem o Normal: registro rápido, resumen y fin.

**Pantalla 1:** "Entendi. Isso que você sente tem mais a ver com…" → ⏳ O que já passou · 📍 O momento atual · 🚀 O que vem pela frente

**Pantalla 2 (bifurcación, 2 opciones) y pantalla 3 (opción final, 2 opciones):**

| Tiempo | Bifurcación | Opción final (texto en la app) | Clave guardada |
|---|---|---|---|
| Passado | 🍂 Tristeza ou saudade | 🛑 Culpa ou arrependimento | `passado.tristeza.culpa` |
| | | ⏳ Falta de alguém ou de como as coisas eram | `passado.tristeza.saudade` |
| | 🔁 Uma memória que incomoda | ⚠️ Uma lembrança ruim que volta | `passado.memoria.lembranca` |
| | | 🔄 Fico remoendo mágoas antigas | `passado.memoria.magoa` |
| Presente | 🔋 Sem energia | 🪫 Corpo pesado, tenso ou dolorido | `presente.energia.corpo` |
| | | 🌫️ No piloto automático, meio desligado | `presente.energia.desligado` |
| | ⚡ Irritado(a) ou sobrecarregado(a) | 💥 Sem paciência, explodindo por pouco | `presente.sobrecarga.paciencia` |
| | | 🌪️ Aperto no peito e momentos de desespero | `presente.sobrecarga.aperto` |
| Futuro | 💬 Mente acelerada | 🧠 Fico antecipando problemas | `futuro.mente.antecipar` |
| | | 🏋️ Cobrança por perfeição ou controle | `futuro.mente.cobranca` |
| | 🚨 Medo de algo dar errado | 👥 Medo de falhar ou ser julgado(a) | `futuro.medo.julgamento` |
| | | 📉 Desânimo com o rumo das coisas | `futuro.medo.desanimo` |

**Pantallas 4 y 5:** persistencia e intensidad (§8). **Pantalla 6:** resumen ("Seu registro de hoje") + gráfico + mensaje de agradecimiento + anuncio (§14).

Reglas del modelo de datos:
- La clave describe **el camino de la elección**, en lenguaje cotidiano. No existe ningún campo `grupo`, `categoria_clinica`, `sintoma_estruturado` ni `vertical_tratamento`, ni en la base de datos ni en el código.
- El texto que se muestra se resuelve en la app a partir de la clave y del `.arb` (pt/en/es).
- Se guarda el ID de la variante de frase que se mostró, solo para análisis de UX.
- Se mantiene el texto libre opcional ("Quer contar mais?") con el etiquetado de IA actual, que solo organiza.

---

## 6. Nuevo registro físico (mapa del cuerpo)

**Pantalla 1:** "Onde você sente desconforto agora?" Silueta con frente y espalda. 5 regiones tocables: Cabeça e pescoço · Peito · Barriga · Costas · Braços, pernas e mãos.

**Pantalla 2 (2 opciones) y pantalla 3 (2 opciones):** se mantienen las descripciones del documento **en las palabras del usuario** y se elimina toda la columna "Sintoma estruturado / Esfera".

| Región | Bifurcación | Opciones finales |
|---|---|---|
| Cabeça e pescoço | Aperto, peso ou pressão | Dor ou pressão nas têmporas ou testa · Latejando, com incômodo à luz ou ao barulho |
| | Olhos, boca ou garganta | Garganta arranhando ou seca · Olhos pesados ou ardendo |
| Peito | Respiração diferente | Respiração curta · Tosse ou peito carregado |
| | Incômodo no peito ou costelas | Coração acelerado ou batedeira · Pontada nas costelas ao respirar fundo |
| Barriga | Queimação ou enjoo | Queimação subindo · Enjoo |
| | Cólica ou estufamento | Gases ou barriga estufada · Cólica ou pontadas |
| Costas | Rigidez ou travamento | Pescoço e ombros duros · Peso na lombar |
| | Dor que fisga ao mexer | Pontada que desce para braço ou perna · Dor ao mexer |
| Braços, pernas e mãos | Cansaço ou dor | Juntas doloridas · Braços ou pernas cansados |
| | Formigamento | Mãos ou pés formigando ou dormentes · Sensação de choque |

Ajustes respecto al documento:
- "Falta de ar ou sufocamento" pasa a "Respiração curta"; "estômago completamente travado", a "Enjoo". Las palabras extremas en un botón invitan a que la app "reaccione", y la app no reacciona.
- Después de la intensidad: **"Quer marcar outra parte do corpo?"** Sí vuelve al mapa; No va al resumen. Así se cubre el pedido de varias anomalías (barriga + cabeza) sin pantallas cargadas.
- Clave guardada: `cabeca.pressao.temporas` + lado (frente/costas) + persistencia + intensidad. Nada de "sistema".

---

## 7. Frases de transición: reglas editoriales

Las frases rotativas son una buena idea para que el registro diario no se vuelva repetitivo. El riesgo es que cada frase es un mensaje de la app sobre la salud del usuario. Reglas:

1. **Acoger y preguntar; nunca explicar la causa.** Prohibido: "geralmente sinaliza", "costuma indicar", "seu corpo está pedindo", "o peito costuma responder".
2. **Nada de alarma:** ni "sinal de alerta", "sério", "perigo" o "urgente".
3. **Nada de metáforas de violencia o muerte:** "explodir", "fantasma", ☠️.
4. **La app no hace terapia:** nada de "vamos investigar", "vamos dar uma forma lógica", "ressignificar".
5. **Nada de pseudociencia:** "consome um esforço enorme do seu cérebro", "ritmos vitais".
6. Máximo 90 caracteres. Se leen en 2 segundos (Sistema 1).
7. Variantes **incluidas en la app** (funcionan sin red) y elegidas al azar en el dispositivo. El documento propone que las elija el backend; no hace falta, y añade latencia. Si se quiere editarlas sin publicar una versión nueva, usar un catálogo remoto opcional con las incluidas como respaldo.
8. Toda frase nueva pasa por la prueba automática de vocabulario vetado y por una revisión humana.

Frases del documento que **no se pueden usar tal cual**:

| Pantalla | Frase | Problema | Propuesta |
|---|---|---|---|
| Passado, entrada 1 | "…Deixa eu te entender melhor…" | La app "evalúa" | "…Vamos registrar isso com calma." |
| Passado, entrada 7 | "…tentar resolver algo que já foi…" | Interpreta | "A mente às vezes volta no tempo. Vamos anotar isso." |
| Tristeza 4 | "Essa sensação de vazio costuma falar sobre o que mudou" | Interpreta | "Obrigado por contar. Tem a ver com o quê?" |
| Memória 4 | "Parece que um fantasma do passado…" | Metáfora | Eliminar |
| Memória 6 | "Essa angústia geralmente sinaliza algo que não foi bem digerido" | Interpretación psicodinámica | Eliminar |
| Presente, entrada 7 | "…vale a pena investigar o motivo" | Terapia | "Vamos anotar o que está pesando hoje." |
| Esgotado 1 | "Seu corpo está pedindo arrego" | Atribuye causa | "Entendi, o cansaço apareceu. Como ele está?" |
| Esgotado 3 | "Estar sem bateria é um sinal de alerta sério" | **Alarma** | Eliminar |
| Esgotado 6 | "Esse cansaço extremo nubla a nossa percepção" | Afirmación médica | Eliminar |
| Irritado 6 | "…faz a mente querer explodir para se defender" | Interpretación y violencia | Eliminar |
| Futuro, entrada 4 | "…consome um esforço enorme do seu cérebro" | Pseudociencia | Eliminar |
| Futuro, entrada 7 | "…o peito costuma responder" | Relación somática causal | Eliminar |
| Mente acelerada 4 y 6 | "geralmente tenta prever problemas", "acaba gerando uma cobrança pesada" | Interpreta | Eliminar |
| Medo 1, 4 y 7 | "O medo tenta nos paralisar para nos proteger", "defesa exaustiva", "forma lógica" | Psicoeducación o terapia | Eliminar o reescribir |
| Cabeça 2 | "O peso na mente às vezes se reflete física e diretamente aqui" | Relación psicosomática | Eliminar |
| Cabeça 1 | "Essa é uma região sensível às tensões do dia" | Causa | "Vamos anotar o que você sente aqui." |
| Peito 4 y 5 | "ritmos vitais", "Aterrar a atenção na respiração e no coração" | Pseudoclínico | Eliminar |
| Membros 7 | "…ajuda a entender seus picos de atividade física" | Promete análisis | "Registrar ajuda você a acompanhar seu dia a dia." |

Recomendación: lanzar con **3 a 4 variantes aprobadas por pantalla** (no 7) y sumar más después. Escribir 7 por pantalla son unas 200 frases en 3 idiomas, y la calidad importa más que la cantidad.

---

## 8. Persistencia e intensidad (comunes a los dos registros)

**Persistencia:** "Há quanto tempo você percebe isso?" → ⏱️ Começou hoje · ⏳ Alguns dias ou semanas · 🔄 Meses ou anos.
Claves: `hoje`, `dias_semanas`, `meses_anos`. Fuera las etiquetas internas "agudo" y "crônico".

**Intensidad informada por el usuario (1 a 5):** "Agora, quanto isso pesa no seu dia?"

| Nivel | Emocional | Físico |
|---|---|---|
| 1 | Passa rápido, sigo meu dia normalmente. | Sinto, mas não atrapalha nada. |
| 2 | Percebo, mas consigo manter o foco. | Incomoda, mas mantenho minhas atividades. |
| 3 | Está tirando minha energia ou foco. | Diminuiu meu ritmo ou me fez pausar. |
| 4 | Está mudando minha rotina (sono, tarefas, convívio). | Não consigo fazer direito o que preciso. |
| 5 | Está me travando quase por completo hoje. | Está me travando quase por completo hoje. |

- Se eliminan ☠️, "Paralisante", "Incapacitante" y "exige atendimento urgente". El usuario se califica a sí mismo; la app no le dice qué hacer.
- Color: una escala de un solo tono (claro a intenso), no un semáforo verde/rojo, que sugiere "riesgo".
- **Línea fija, igual para todos y siempre visible** bajo la escala: "Se for uma emergência, use o botão Ajuda ou ligue 192." No depende de lo que se elija.
- En el resumen y en el historial: "Intensidade que você informou: 3/5".

---

## 9. Informes, gráficos y biblioteca

### 9.1 Gráficos (Free: 30 días)
- **Arriba (resumen del mes):** barra de distribución Passado / Presente / Futuro + mapa del cuerpo con las zonas marcadas. El Sankey (tiempo → tema → intensidad) es más vistoso, pero `fl_chart` no lo trae y hay que dibujarlo a mano (unos 3 días). Se propone para la etapa 4, si hay tiempo.
- **Abajo (detalle):** línea de intensidad diaria con las dos series (emocional y física) y la de agua.
- **Ventana:** pasar de 14 a 30 días en el dashboard y de 7 a 30 en hidratación. Es solo la ventana de visualización: los datos se conservan según la política de retención. La versión Premium puede ofrecer 6 a 12 meses.

### 9.2 Textos permitidos en los informes

| Sí | No |
|---|---|
| "Em outubro, 'O que vem pela frente' apareceu em 12 dos seus 20 registros." | "Seu problema este mês foi o Futuro." |
| "A parte do corpo que você mais marcou foi Cabeça (8 dias)." | "Tendência a enxaqueca." |
| "Nos 7 dias em que você marcou 'Mente acelerada', também marcou 'Cabeça' em 5." | "Sua dor de cabeça subiu exatamente quando sua mente acelerou." |
| "Ciclo menstrual" (solo si el usuario lo registra él mismo, en una función futura y opcional) | "Período ciclotímico" (ciclotimia es un diagnóstico) |

### 9.3 Biblioteca de lecturas
- Organizada por **temas de bienestar**, no por grupos clínicos: Emoções e humor · Estresse e descanso · Sono · Corpo e movimento · Alimentação e digestão · Hidratação · Relações e convívio · Primeiros cuidados e quando procurar ajuda.
- Igual para todos. Nunca se ordena ni se destaca según las respuestas. El mensaje final enlaza a la biblioteca en general, no a un artículo.
- Cada artículo muestra su fuente real (Ministério da Saúde, BVS, OMS…), sin autores no verificados (plan vigente, F0).
- **Mensaje final:** "Obrigado por registrar seu dia! 🌿 Na Biblioteca você encontra textos de fontes públicas, como o Ministério da Saúde, sobre hábitos saudáveis."

### 9.4 Exportación para el profesional
"Resumo dos meus registros" (PDF): fechas, elecciones con las palabras del usuario, intensidad informada y zonas marcadas. Sin agrupar en categorías de salud ni conclusiones. El usuario decide si lo comparte.

---

## 10. Ayuda urgente: qué queda y qué se quita

El temor del cliente está bien fundado. Si la app **decide** cuándo mostrar la emergencia, asume implícitamente la tarea de detectarla. Cuando falla (porque el usuario no lo escribió o lo escribió de otra forma), queda expuesta a una acusación de omisión. Y, por definición, eso es triaje.

| Elemento | Decisión |
|---|---|
| Botón rojo "Ajuda" en la barra inferior + overlay en las pantallas sin barra + acceso desde el login | **Se mantiene** (ya implementado). Igual para todos, gratuito y funciona sin red. |
| Pantalla de recursos: lista estática de señales de alarma con fuente oficial y botones 192/193/188/190 | **Se mantiene.** |
| Línea fija en la pantalla de intensidad | **Se agrega** (§8). |
| Avisos que aparecen si el texto menciona "dor no peito", "não consigo respirar"… (`warningSignPatterns`) | **Se quita.** Es detección de síntomas y crea expectativa de vigilancia. |
| Aviso si el texto menciona autolesión o suicidio (`selfHarmPattern`) | **Se quita** (decisión del cliente, 27/10/2026). La app no reacciona a ningún texto. Riesgo aceptado y documentado en §18. El CVV 188 sigue visible en la pantalla de recursos y en la línea fija de intensidad. |
| Términos de uso | Agregar: "O Dualis não monitora seus registros em tempo real e não aciona serviços de emergência. Em emergência, ligue 192." |

---

## 11. Hidratación más interactiva

- Mismo lenguaje visual que el registro: una sola acción por pantalla.
- Vaso o botella que se llena con animación. Botones rápidos 🥛 200 ml · 🍶 500 ml · ✏️ Outro. Anillo de meta diaria y racha de días.
- Meta definida por el usuario. Si se muestra una referencia general, debe llevar su fuente. Nada de "você precisa de 35 ml/kg".
- Anuncio después de registrar agua: como máximo una vez al día (§14).
- Gráfico de 30 días (hoy, 7).

---

## 12. Fondos con fotos (Free)

- Sí, con condiciones: licencia comercial con *model release* (stock pago, o Unsplash/Pexels con control de licencia), WebP comprimido (menos de 150 KB cada uno) y una capa oscura o clara para cumplir el contraste WCAG AA.
- En las pantallas emocionales, **paisajes y ambientes** antes que personas sonriendo. Para alguien que acaba de marcar "desânimo", una foto de gente feliz puede sentirse como un juicio.
- Un set pequeño (8 a 12) incluido en la app y rotativo. Premium puede ofrecer fondos lisos o personalizables.

---

## 13. Registro y primera pantalla

- **Foto que corta la cabeza:** agregar un paso de recorte circular con zoom y arrastre antes de guardar. Opción A (sin dependencia nueva): `InteractiveViewer` + recorte propio. Opción B: paquete `image_cropper` (dependencia nueva, requiere aprobación). La detección automática de rostro (ML Kit) es más pesada y no hace falta. Recomendación: A.
- **"¿Qué es la parte inferior?":** si el cliente no entiende para qué sirven "Central de privacidade / Histórico e tendências / Lembretes de hidratação", el usuario tampoco. Propuesta: el registro solo pide los datos mínimos; los recordatorios de agua se ofrecen después del primer registro, con una pregunta ("Quer lembretes para beber água?"). La privacidad queda en Ajustes, con un enlace en el consentimiento.
- **Saludo:** "Olá, {primeiro nome}! Bom dia / Boa tarde / Boa noite."

---

## 14. Publicidad

| Regla | Detalle |
|---|---|
| Formato | **Tarjeta nativa en la pantalla de resumen**, que no bloquea. No interstitial a pantalla completa. Un anuncio que tapa la pantalla justo después de que alguien marcó "momentos de desespero 5" es mala experiencia y mala imagen, y la tarjeta lo evita sin lógica condicional. |
| Momento | Una vez después del registro del día (emocional + físico juntos) y como máximo una vez al día después de registrar agua. Nunca en la pantalla de ayuda ni durante el flujo. |
| Contenido | Primero, anuncios propios (Dualis Premium, ZOC, WGI, UBO): imagen + logo + enlace, incluidos en la app o servidos por el backend. **Sin SDK de terceros, así que no se comparte ningún dato.** |
| Igual para todos | El anuncio **no** depende de las respuestas (Apple 5.1.3 y LGPD Art. 11: los datos de salud no se usan para publicidad). Nunca "recomendado para você". |
| Anunciantes | Confirmar qué son ZOC, WGI y UBO. Si venden suplementos o servicios de salud, el anuncio no puede hacer promesas de salud ni aparecer como consejo del Dualis. Etiqueta "Anúncio" visible. |
| Red externa (futuro) | AdMob solo con anuncios no personalizados y sin datos de salud. Declararlo en Data Safety y en la etiqueta de privacidad de Apple. |

---

## 15. Plan de ejecución

| Etapa | Duración | Contenido | Entregable |
|---|---|---|---|
| **0. Decisiones y textos** | Semana 1 | Respuestas del cliente (§16). Textos finales pt/en/es: 12 + 20 opciones, 3 a 4 frases por pantalla, escalas, mensajes, biblioteca. Revisión editorial con las reglas del §7. | Catálogo de textos aprobado. Sin código. |
| **1. Arreglos rápidos** | Semana 1, en paralelo | Recorte de foto. Saludo con nombre. Ventanas de 30 días (dashboard e hidratación). Quitar `warningSignPatterns`. Línea fija de emergencia. Cláusula en los Términos. | Versión que se puede publicar enseguida. |
| **2. Nuevo registro emocional** | Semanas 2-3 | Árbol Pasado/Presente/Futuro en la app. Nuevo modelo de datos (claves de elección + persistencia + intensidad 1-5). Migración de la base de datos y de Drift; los registros antiguos se muestran como "registro anterior". Endpoint `/v1/journal`. Frases rotativas. Pruebas de vocabulario y de contrato (ningún campo clínico). | Flujo emocional nuevo de punta a punta. |
| **3. Nuevo registro físico** | Semanas 3-4 | Mapa del cuerpo tocable (frente y espalda), reutilizando `anatomical_body_map.dart`. Varias zonas por registro. Mismas pantallas de persistencia e intensidad. | Flujo físico nuevo. |
| **4. Resumen, gráficos, biblioteca, anuncios** | Semanas 5-6 | Pantalla de resumen con mensaje + tarjeta de anuncio. Distribución por tiempo + mapa + líneas de 30 días. Coincidencias descriptivas. Biblioteca por temas. Hidratación interactiva. Fondos. Sankey si hay tiempo. | Experiencia completa de la versión Free. |
| **5. Validación** | Semana 7 | `npm run test:battery` (vocabulario vetado = 0, ayuda a ≤1 toque). Sesión en vivo en el simulador con capturas. Revisión del consultor regulatorio. Fichas de tienda (Health & Fitness). | Versión candidata. |

Las estimaciones suponen el equipo actual trabajando con agentes en paralelo y no incluyen la revisión del consultor externo. Cada etapa entra como fase del roadmap (`/gsd-plan-phase`), con pruebas y su propio cierre.

### Pruebas automáticas nuevas
- **Vocabulario vetado** (ampliar la existente): además de la lista vigente, transtorno, TAG, TOC, TEPT, bipolar, ciclotim*, borderline, grupo clínico, sintoma estruturado, esfera, vertical de tratamento, anedonia, radiculopatia, costocondrite, isquemia, ☠️.
- **Contrato de datos:** el esquema de `/v1/journal` y la migración no contienen columnas ni campos de grupo, categoría clínica o sistema anatómico.
- **Independencia de los anuncios:** el widget del anuncio no recibe ningún dato del registro.
- **Ayuda:** sigue a 1 toque desde todas las pantallas nuevas.

---

## 16. Decisiones pendientes del cliente

1. ~~Grupos clínicos~~: resuelto, se eliminan (§18).
2. ~~Aviso de autolesión~~: resuelto, se quita (§18).
3. ~~Anunciantes~~: resuelto, son ejemplos internos (§18). Falta confirmar si se acepta la tarjeta nativa en lugar del interstitial.
4. **Fotos de fondo:** ¿presupuesto para stock con licencia, o banco gratuito con control de licencia?
5. ~~Desencadenante~~: resuelto, se integra (§18.1).
6. **Nombre "CheckUp" y términos "avaliação" / "auto check-up":** el documento los usa mucho. Recomendación: "registro" en toda la interfaz. El nombre comercial sigue pendiente (plan vigente, decisión 5).

---

## 17. Riesgos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| El cliente insiste en la clasificación clínica "solo interna" | Alto (regulatorio y LGPD) | §2: lo que cuenta es lo que el software hace. Documentar la decisión por escrito. |
| Frases rotativas que se van llenando de interpretación con el tiempo | Medio | Prueba de vocabulario + revisión humana obligatoria en cada cambio de texto. |
| Usuarios con historial en el formato viejo | Medio | Los registros antiguos se conservan y se muestran como "registro anterior" en el historial y en la exportación. |
| Versiones viejas de la app frente al nuevo endpoint | Medio | Mantener `/v1/triage` como alias durante 2 versiones y crear el mecanismo de versión mínima (plan vigente, F6). |
| Anuncios de terceros con promesas de salud | Medio | Revisar cada pieza antes de publicarla. Etiqueta "Anúncio". |
| Peso de la app por las fotos | Bajo | WebP, set pequeño, descarga diferida. |

---

## 18. Decisiones del cliente (27/10/2026) y cambios al plan

| # | Decisión | Efecto en el plan |
|---|---|---|
| 1 | Se eliminan los 12 grupos clínicos y las 18 esferas, **también en el backend**. | No existe ningún campo, tabla, constante ni documento interno con grupo, categoría clínica, sistema anatómico ni vertical de tratamiento. La prueba de contrato lo verifica. |
| 2 | **No** se mantiene el aviso de autolesión por texto. | Se elimina `RedFlagEvaluator` completo (`selfHarmPattern` y `warningSignPatterns`), además de `SafetyNoticeKind` y del banner inline. La ayuda queda solo como botón universal, pantalla de recursos y línea fija en la intensidad. El campo `mentionsSelfHarm` del esquema de IA se quita, o deja de usarse en la app. **Riesgo aceptado:** si alguien escribe sobre suicidio, la app no responde de forma específica. Mitigación: CVV 188 siempre a 1 toque y una cláusula en los Términos ("o Dualis não lê seus registros em tempo real"). Conviene dejar constancia escrita de esta decisión. |
| 3 | ZOC, WGI y UBO son productos internos ficticios para ejemplificar publicidad. | Se usan como anuncios propios de demostración (imagen + logo), sin SDK. Antes del lanzamiento se reemplazan por anunciantes reales o por Dualis Premium. |
| 4 | El paso "desencadenante" se integra al nuevo proceso. | Ver §18.1. |
| 5 | Se puede registrar más de un malestar en el mismo registro. | Ver §18.2. |
| 6 | El usuario puede escribir su propio malestar o una condición ya diagnosticada (por ejemplo, depresión) y seguirla en el tiempo. | Ver §18.3 y §18.4. |

### 18.1 Desencadenante integrado

Va después de la intensidad, es **opcional** y admite varias opciones. Es una sola pantalla por registro, no una por malestar.

- Pregunta: "Tem algo que pode ter contribuído hoje?" (atribución del propio usuario, no de la app).
- Chips con selección múltiple: 💼 Trabalho ou estudos · 👨‍👩‍👧 Família ou relações · 😴 Noite mal dormida · 🍽️ Alimentação · 🏃 Esforço físico · 🤕 Queda ou mau jeito · 💊 Medicamento novo · 🌦️ Clima ou ambiente · 🤷 Não sei · ✏️ Outro.
- Los chips físicos (esfuerzo, caída, alimentación, medicamento, clima) solo aparecen si hay un malestar físico en el registro. Reutiliza las claves actuales de `triage_question_bank.dart`.
- Botón "Pular" siempre visible.
- En los informes, solo se cuenta: "Você marcou 'Noite mal dormida' em 6 dos 9 dias com 'Cabeça'". Sin relación causal.

### 18.2 Varios malestares en un registro

- **Físico:** en el mapa se pueden tocar varias zonas (cada una queda resaltada) y en la pantalla final se pueden marcar varias opciones. Botón "Continuar".
- **Emocional:** en la pantalla final se pueden marcar varias opciones. Al terminar, la app pregunta "Quer registrar mais alguma coisa?", que vuelve a Pasado/Presente/Futuro.
- **Persistencia e intensidad, por malestar**, en una sola pantalla compacta: una fila por malestar ("Cabeça · pressão nas têmporas") con 3 chips de persistencia y 5 puntos de intensidad. Con un solo malestar, la pantalla es la misma de §8.
- **Modelo de datos:** `journal_entries` (el registro del día: estado general, desencadenantes, texto libre) → N `journal_items` (clave de la elección o texto propio, lado del cuerpo, persistencia, intensidad).
- **Gráficos:** una línea por malestar (máximo 5 visibles; el resto, en "ver mais") y el mapa con todas las zonas.

### 18.3 Malestar propio ("✏️ Outro")

- Botón "✏️ Escrever o meu" en la pantalla final emocional y en cada región del mapa.
- Hasta 40 caracteres. Luego, las mismas pantallas de persistencia e intensidad.
- Se guarda **tal cual lo escribió el usuario**. La IA de etiquetado puede sugerir la zona del cuerpo o el estado de ánimo para ordenar los gráficos, pero nunca reescribe el texto ni lo convierte en un término médico.
- Lo escrito queda disponible como atajo en los próximos registros ("Seus itens").

### 18.4 "Minhas condições": seguimiento de una condición ya diagnosticada

Flujo:
- En Perfil, la sección **"Minhas condições (informadas por você)"** tiene un botón "+ Adicionar" y un campo de texto libre ("Depressão", "Enxaqueca", "Diabetes"…).
- Cada condición aparece como una tarjeta más en el registro diario: "Como você está com **Depressão** hoje?", con la misma escala de intensidad de 1 a 5, persistencia (opcional) y nota libre.
- Tiene su propia línea en los gráficos y en el resumen exportable, siempre con el nombre que el usuario escribió.

**¿Convierte esto a Dualis en una app de salud regulada?** No, si se cumplen estas condiciones. Registrar lo que uno mismo declara y verlo a lo largo del tiempo es un diario personal. Lo que define a un dispositivo médico es que el software **haga algo clínico** con ese dato: detectar, interpretar, alertar, ajustar o recomendar. Por ejemplo, la guía de bienestar general de la FDA incluye explícitamente las apps que ayudan a convivir con una condición crónica mediante hábitos y registro, siempre que no la diagnostiquen ni la traten. En Brasil, que el consultor lo confirme frente a la RDC 657/2022.

| Permitido | Prohibido (lo vuelve dispositivo médico) |
|---|---|
| Texto libre escrito por el usuario. | Lista o autocompletado de enfermedades o códigos CID que la app "conoce" y procesa. Si algún día se ofrece una lista, que sea solo para escribir más rápido, sin ninguna lógica asociada. |
| La misma escala 1-5 para cualquier condición. | Escalas o cuestionarios validados por condición (PHQ-9 para depresión, etc.) con puntaje o interpretación. |
| Gráfico: "Depressão: média 3,2 em outubro (você informou)". | "Sua depressão piorou", alertas por tendencia, umbrales, "procure seu psiquiatra". |
| La misma biblioteca general para todos. | Contenido, consejos o anuncios distintos según la condición escrita. |
| Recordatorio diario genérico de registro. | Recordatorios o ajustes de medicación calculados por la app. |
| Exportar para mostrar al médico, si el usuario quiere. | Enviar automáticamente a un profesional o a un tercero. |
| Ficha de tienda: "Registre como você se sente, inclusive com condições que você já acompanha." | Marketing del tipo "Controle sua depressão" o "Acompanhamento de doenças". |

Requisitos aunque no sea dispositivo médico:
- Es **dato de salud sensible** según la LGPD (y, en el caso de la salud mental, especialmente sensible). Ya lo cubre el consentimiento Art. 11 I. Agregar en la Política de Privacidad: "condições que você informar".
- El texto de las condiciones **no** se envía a la IA. No hace falta: el usuario ya lo nombró. Así se reduce la transferencia internacional de datos (plan vigente, F9).
- Nunca se usa para anuncios (ni siquiera los internos).
- Se puede borrar en cualquier momento y entra en la exportación LGPD.

### 18.5 Ajustes al calendario

- Etapa 1: se suma la eliminación completa de `RedFlagEvaluator` (+0,5 día).
- Etapa 2: modelo `journal_entries` / `journal_items`, desencadenantes, selección múltiple y "Outro" (+3 a 4 días).
- Etapa 3: "Minhas condições" (perfil + tarjeta diaria + línea en gráficos), +3 días.
- Nuevo total estimado: **8 semanas**.
