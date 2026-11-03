# 03 — Flujo físico (ESPEC-CLIENTE §4) vs. app

Revisión de solo lectura, 2026-11-02. Se revisó el código en disco, no los docs.

Rutas abreviadas:
- **ARB** = `mobile/lib/l10n/app_pt.arb`
- **KEYS** = `mobile/lib/features/journal/domain/journal_keys.dart`
- **MAP** = `mobile/lib/features/journal/presentation/widgets/body_region_map.dart`
- **FLOW** = `mobile/lib/features/journal/presentation/screens/journal_flow_screen.dart`
- **CTRL** = `mobile/lib/features/journal/presentation/controllers/journal_flow_controller.dart`
- **LBL** = `mobile/lib/features/journal/presentation/journal_labels.dart`
- **EMO** = `mobile/lib/features/journal/presentation/journal_item_text.dart`
- **INT** = `mobile/lib/features/journal/presentation/widgets/intensity_scale.dart`
- **BK** = `backend/src/modules/journal/constants/journal-keys.constant.ts`
- **EST** = `docs/bienestar/ESTRATEGIA-MEJORAS-DUALIS-FREE.md`
- **CON** = `docs/bienestar/CONTRATO-JOURNAL-V2.md`

## 1. Tabla de requisitos

| Requisito | Estado | Evidencia | Detalle |
|---|---|---|---|
| P1: el mapa anatómico es gráfico y se puede tocar | CUMPLE | MAP:16-107, FLOW:818 | `CustomPaint` con zonas tocables (`GestureDetector` + `Semantics`) y vista frente/espalda (FLOW:793). Las formas son rectángulos y un óvalo, no una silueta anatómica. Admite selección múltiple (EST §18.2). |
| P1: pregunta "Em qual parte do seu corpo você está sentindo esse desconforto agora?" | PARCIAL | ARB:1252 | La app dice "Onde você sente dor ou incômodo?" y la pista "Toque direto no desenho." (ARB:2828). EST §6 propone "Onde você sente desconforto agora?". El texto de la app no coincide con ninguno de los dos y ningún doc explica el cambio. |
| P1: 5 macrorregiones | PARCIAL / DESVÍO INTENCIONAL (documentado) | MAP:33-35, KEYS:88-131 | Hay 6 zonas en el mapa: frente `cabeca, peito, barriga, pelve, membros`; espalda `cabeca, costas, membros`. A eso se suman 3 áreas de "No corpo todo" (`pele, musculos, hormonios`, FLOW:858-876). EST §6 fija las 5 regiones; CON v2.1 (l.46-55) agrega las áreas de cuerpo entero y CON v2.3 (l.244-262) agrega la pelve. Motivo de producto, no regulatorio. |
| P1: nombres de las regiones | PARCIAL / DESVÍO INTENCIONAL (documentado) | ARB:1282-1286, 2815 | "Cabeça ou Pescoço" pasa a "Cabeça e pescoço"; "Tórax ou Peito" a "Peito"; "Abdômen ou Ventre" a "Barriga" (solo la parte alta) + "Pelve e baixo ventre"; "Coluna ou Costas" a "Costas" (solo en la vista de espalda: hace falta un toque más); "Membros (Braços, Pernas ou Mãos)" a "Braços, pernas e mãos". Nombres según EST §6. |
| P2: 7 frases de transición por región (35 en total, distintas por región) | DESVÍO INTENCIONAL (documentado en parte) | ARB:1430-1433, LBL:519-530, CTRL:524-562 | Hay **4 frases genéricas** en un único pool `region`, iguales para todas las regiones. EST §7 recomienda "3 a 4 variantes por pantalla (no 7)" y reglas editoriales. Que las frases sean comunes a todas las regiones no está escrito; se deduce. Solo 2 de las 4 vienen de propuestas de EST §7 ("Vamos anotar o que você sente aqui." para Cabeça 1 y "Registrar ajuda você a acompanhar seu dia a dia." para Membros 7). No se usa ninguna frase del cliente al pie de la letra. |
| P2: frases elegidas al azar o por día | CUMPLE (al azar, en el dispositivo) | CTRL:13-14, 524-541 | Se eligen al azar en el dispositivo, no en el backend (EST §7 regla 7). El ID mostrado se guarda en `transitionVariantIds` (backend `dto/journal.dto.ts:371-373`). |
| P2: transiciones animadas | CUMPLE | FLOW:154-170 | `AnimatedSwitcher` con fundido y deslizamiento de 280 ms. No hay efecto de escritura. |
| P2: 2 botones de bifurcación por región | PARCIAL / DESVÍO INTENCIONAL (documentado) | KEYS:88-131, 137-164 | Cabeça frente: 3 (`pressao`, `sentidos`, `rosto`). Cabeça espalda: 2 (`pressao`, `nuca`). Barriga: 3 (`intestino` extra). Pelve: 3. Peito, Costas y Membros: 2. Extras en CON v2.1 y v2.2 §3. EST §3 permite "2 a 4 opciones por pantalla". |
| P2: texto de los botones de bifurcación | PARCIAL / DESVÍO INTENCIONAL (documentado) | ARB:1317-1326 | Todos se acortaron, por ejemplo "Uma alteração no ritmo ou na forma de respirar" pasa a "Respiração diferente", y "Um incômodo físico na altura do coração ou costelas" a "Incômodo no peito ou costelas" (se quita "coração"). El texto coincide con la tabla de EST §6. |
| P2: emoji en los botones de bifurcación (🧠👄🫁🫀🤢⚡🪵⚡🏋️🧊) | **FALTA / DESVÍO SIN JUSTIFICAR** | FLOW:545, EMO:7-96 | `journalEmojis` no tiene ninguna clave `<region>.<branch>`, así que las filas salen sin emoji. El flujo emocional sí los tiene (EMO:14-19). EST §3 2.1 marca "interacción gráfica" en verde. Ningún doc dice que se quitan. |
| P2: paso extra "É dor ou incômodo?" antes de la bifurcación | Extra (documentado) | FLOW:505-541, ARB:1293-1295 | Es obligatorio, con ⚡ Dor / 〰️ Incômodo, en la misma pantalla que la bifurcación ("Onde exatamente?", ARB:2996). Viene de CON v2.1 l.57. El cliente no lo pidió. |
| P3: 18 opciones finales con el texto exacto | PARCIAL / DESVÍO INTENCIONAL (documentado en la tabla, sin motivo para la mayoría) | ARB:1327-1346 | Las 18 existen como clave (ver §2). Todas se acortaron. Solo 2 cambios tienen motivo escrito ("Respiração curta" y "Enjoo", EST §6). En los demás se quitan matices clínicos ("refluxo ácido", "palpitação", "dificuldade de engolir", "visão cansada", "persistente", "irradia", "gelados") sin explicación. |
| P3: emoji en cada opción final (🤕🤯👄👁️🫁🗣️🫀🩻🤮🤢💨⚡🪵🪓⚡🦵🦿🧊) | **FALTA / DESVÍO SIN JUSTIFICAR** | FLOW:608, EMO:7-96 | Ninguna de las 18 tiene emoji. Las únicas opciones físicas con emoji son `pelve.urina.dificuldade` 🚽 y `pelve.urina.cor_odor` 🧪 (EMO:90-91), lo que deja la pantalla incoherente. |
| P3: Coluna/fisga y Membros/dormência con 1 sola opción | DESVÍO INTENCIONAL (documentado) | KEYS:110-117 | La app completa la segunda opción: "Dor ao mexer" (`costas.fisgada.ao_mexer`) y "Sensação de choque" (`membros.formigamento.choque`), tomada del texto del botón del cliente. Ver EST §6. |
| P3: síntoma estructurado + "Esfera 01–18" | DESVÍO INTENCIONAL (documentado) | BK:28-71, KEYS:88-131 | Solo se guarda `optionKey` + lado + sensación. No existe ninguna esfera. Decisión en EST §3 (rojo), §18 decisión 1, CON "Hard rules". `grep esfera/sphere` sin resultados en `backend/src` y `mobile/lib`. |
| P3: selección múltiple + "✏️ Escrever o meu" | Extra (documentado) | FLOW:604-685 | Selección múltiple (EST §18.2) y texto propio con sugerencia de IA (EST §18.3, CLAUDE.md). |
| P4 paso 1: pregunta de persistencia | PARCIAL / DESVÍO INTENCIONAL (documentado) | ARB:1347, FLOW:1007 | "Há quanto tempo você percebe isso?" en lugar de "E há quanto tempo você nota esse desconforto físico se repetindo?". Es la misma pregunta para el flujo emocional y el físico (EST §8). |
| P4 paso 1: 3 opciones con ⏱️⏳🔄 | PARCIAL | ARB:1348-1350, FLOW:914-940 | Textos: "Começou hoje", "Alguns dias ou semanas" (sin "Há"), "Meses ou anos" (sin "Há muitos"); ver EST §8. Los emojis solo aparecen con un único malestar; en la vista compacta de varios malestares no hay emoji (FLOW:943-990). |
| P4: persistencia y luego intensidad, en pasos separados | PARCIAL / DESVÍO INTENCIONAL (documentado) | FLOW:879-1015 | El orden es el correcto (persistencia, luego intensidad), pero las dos están **en una sola pantalla**, por malestar (EST §18.2). Falta la transición final "Obrigado por compartilhar…"; se usa el pool `intensity` (ARB:1434-1436). |
| P4 paso 2: pregunta "…o quanto isso está limitando as suas ações cotidianas?" | PARCIAL / DESVÍO INTENCIONAL (documentado) | ARB:1352-1353 | "Agora, quanto isso pesa no seu dia?" es la misma pregunta que en el flujo emocional (EST §8). |
| P4 paso 2: escala 1–5 con nombre de nivel (Leve, Notável, Limitante, Severo, Incapacitante) | DESVÍO INTENCIONAL (documentado en parte) | ARB:1354, INT:51 | Muestra "{n} de 5" sin nombre de nivel. EST §8 quita "Incapacitante" y "Paralisante" de forma explícita; quitar Leve, Notável, Limitante y Severo no está escrito (se deduce). |
| P4 paso 2: descripciones por nivel | DESVÍO INTENCIONAL (documentado) | ARB:1367-1371, INT:17-28 | Coinciden con la columna física de EST §8. El nivel 5 tiene el mismo texto que el emocional ("Está me travando quase por completo hoje."). Se quitan "tomar um remédio" y "exige suporte imediato". |
| P4 paso 2: semáforo 🟢🟡🟠🔴☠️ | DESVÍO INTENCIONAL (documentado) | INT:11-12 | Un solo tono de azul (claro a intenso). EST §8: "no un semáforo"; EST §7 regla 3 quita ☠️. |
| P4: línea fija de emergencia (no la pidió el cliente) | Extra (documentado) | INT:254-258, ARB:1372 | "Se for uma emergência, use o botão Ajuda ou ligue 192." (EST §8). |
| Pantallas extra después del cierre | Extra (documentado) | FLOW:248-262 | El camino físico tiene 8 pantallas (ánimo, mapa, sensación+bifurcación, opciones, persistencia+intensidad, factores, "Como foi lidar / O que ajudou", nota), frente a las 4 del cliente. Ver EST §18.1 y CON v2.2 §5. |
| Opciones filtradas por sexo | Extra (documentado en parte) | KEYS:162 | "Cólica menstrual" no se muestra a hombres. Las claves están en CON v2.2 y v2.3; el filtro por sexo no figura en CON. |

## 2. Árbol del cliente vs. árbol de la app (pt-BR)

Las bifurcaciones y opciones de la app no tienen emoji en ningún caso, salvo donde se indica.

| Región cliente | Bifurcación cliente | Opción cliente (18) | Región / bifurcación app | Opción app (ARB) | Diferencia |
|---|---|---|---|---|---|
| Cabeça ou Pescoço | 🧠 Uma sensação de aperto, peso ou pressão | 🤕 Uma dor ou pressão nas têmporas ou testa | Cabeça e pescoço / Aperto, peso ou pressão | Dor ou pressão nas têmporas ou testa (1327) | Quita "Uma" y el emoji |
| | | 🤯 Uma pulsação forte que incomoda a luz ou ruídos | | Latejando, com incômodo à luz ou ao barulho (1328) | Reescrita |
| | 👄 Algo incomodando nos sentidos, boca ou garganta | 👄 Garganta arranhando, seca ou dificuldade de engolir | Olhos, boca ou garganta (solo frente) | Garganta arranhando ou seca (1329) | Quita "dificuldade de engolir" |
| | | 👁️ Olhos pesados, ardendo ou visão cansada | | Olhos pesados ou ardendo (1330) | Quita "visão cansada" |
| Tórax ou Peito | 🫁 Uma alteração no ritmo ou na forma de respirar | 🫁 Respiração curta, falta de ar ou sufocamento | Peito / Respiração diferente | Respiração curta (1331) | Recorte con motivo escrito (EST §6) |
| | | 🗣️ Uma tosse persistente ou peito carregado | | Tosse ou peito carregado (1332) | Quita "persistente" |
| | 🫀 Um incômodo físico na altura do coração ou costelas | 🫀 Coração acelerado, batedeira ou palpitação | Incômodo no peito ou costelas | Coração acelerado ou batedeira (1333) | Quita "palpitação" |
| | | 🩻 Uma pontada ou dor nas costelas ao respirar fundo | | Pontada nas costelas ao respirar fundo (1334) | Quita "ou dor" |
| Abdômen ou Ventre | 🤢 Uma queimação, azia ou estômago embrulhado | 🤮 Queimação subindo para a garganta ou refluxo ácido | Barriga / Queimação ou enjoo | Queimação subindo (1335) | Quita "para a garganta ou refluxo ácido" |
| | | 🤢 Enjoo forte, náusea ou estômago completamente travado | | Enjoo (1336) | Recorte con motivo escrito (EST §6) |
| | ⚡ Uma cólica, pontada ou sensação de estufamento | 💨 Gases abundantes, estufamento ou abdômen esticado | Cólica ou estufamento | Gases ou barriga estufada (1337) | Reescrita |
| | | ⚡ Cólicas intestinais fortes ou pontadas pontuais | | Cólica ou pontadas (1338) | Quita "intestinais fortes" |
| Coluna ou Costas | 🪵 Uma rigidez, peso ou sensação de travamento muscular | 🪵 Pescoço e ombros duros, tensionados ou travados | Costas (solo espalda) / Rigidez ou travamento | Pescoço e ombros duros (1339) | Acortada |
| | | 🪓 Peso na lombar ou dor cansada ao ficar em pé | | Peso na lombar (1340) | Acortada |
| | ⚡ Uma dor pontual que fisga ou queima ao mover | ⚡ Uma pontada aguda na coluna que irradia para a perna/braço | Dor que fisga ao mexer | Pontada que desce para braço ou perna (1341) | Reescrita |
| | | (no hay) | | **Dor ao mexer** (1342) | Extra: completa la bifurcación |
| Membros | 🏋️ Uma fadiga, fraqueza ou dor muscular generalizada | 🦵 Juntas ou articulações doloridas e estalando | Braços, pernas e mãos / Cansaço ou dor | Juntas doloridas (1343) | Quita "e estalando" |
| | | 🦿 Pernas ou braços cansados, pesados e doloridos | | Braços ou pernas cansados (1344) | Acortada |
| | 🧊 Uma dormência, formigamento ou sensação de choque | 🧊 Mãos ou pés dormentes, gelados ou formigando | Formigamento | Mãos ou pés formigando ou dormentes (1345) | Quita "gelados" |
| | | (no hay) | | **Sensação de choque** (1346) | Extra: completa la bifurcación |

**Extras de la app que el cliente no pidió** (todos en BK:28-71 y KEYS:88-131):
- Cabeça / Rosto (solo frente): Tontura · Nariz entupido ou escorrendo · Incômodo no ouvido · Mandíbula ou dentes travados (ARB:2665-2669; CON v2.2 §3).
- Cabeça / Nuca (solo espalda): Nuca dura ou pesada · Pontada na parte de trás (ARB:1296, 1303-1304; CON v2.1).
- Barriga / Cólica: + Cólica menstrual, solo mujeres (ARB:2670; CON v2.2 §3).
- Barriga / Intestino: Intestino preso · Intestino solto (ARB:2671-2673; CON v2.2 §3).
- **Pelve e baixo ventre** (región nueva, solo frente):
  - Ao fazer xixi: Arde ou dói · Vontade toda hora · **Dificuldade ou fluxo fraco** 🚽 · **Urina escura ou com cheiro forte** 🧪.
  - Baixo ventre: Cólica · Peso ou pressão · Cólica menstrual.
  - Região íntima: Coceira ou ardência · Sensibilidade ou inchaço.
  - Textos en ARB:2815-2827. Documentado en CON v2.3 l.244-262, **salvo `urina.dificuldade` y `urina.cor_odor`, que no figuran en CON ni en EST** (solo en el código, commit ceef4b5). "Cor/odor da urina" se acerca a un signo clínico.
- No corpo todo: Pele (2×2), Músculos (2×2), Hormônios e metabolismo (2×2) (ARB:1290-1316; CON v2.1 l.46-51).
- Sensación Dor/Incômodo, factores, "Como foi lidar", "O que ajudou" y nota libre.

Conteo de la app: 20 opciones en las 10 bifurcaciones del cliente (18 + 2 de relleno). Con los extras, el árbol de mapa + cuerpo entero llega a 59 opciones finales.

## 3. Las 5 brechas más importantes

1. **Sin emojis en bifurcaciones ni opciones físicas** (FLOW:545, 608; EMO:7-96). El cliente los pidió en las 28 líneas y el flujo emocional sí los tiene. Ningún doc lo justifica. Solo 2 opciones de pelve tienen icono, lo que deja la pantalla incoherente.
2. **Frases de transición**: hay 4 genéricas para todas las regiones en lugar de 7 por región. Ninguna es del cliente, y la pantalla de opciones finales no tiene frase. EST §7 justifica reducir la cantidad y reescribir, pero no que las frases sean iguales para todas las regiones.
3. **Árbol más grande que lo pedido**: 6 zonas en el mapa + 3 de cuerpo entero, bifurcaciones de 3 en Cabeça (frente), Barriga y Pelve, y un paso obligatorio Dor/Incômodo. Contradice "pocas opciones por pantalla" (ESPEC §2.2), aunque está documentado en CON v2.1-v2.3. Dos opciones de pelve (`dificuldade`, `cor_odor`) no tienen respaldo en ningún doc.
4. **Cierre distinto**: persistencia e intensidad en una sola pantalla, preguntas genéricas compartidas con el flujo emocional, sin nombres de nivel, sin semáforo y sin la frase "Obrigado por compartilhar…". Casi todo está documentado (EST §8, §18.2); quitar los nombres Leve, Notável, Limitante y Severo no lo está.
5. **Textos de las 18 opciones recortados** sin motivo escrito, salvo 2 ("Respiração curta", "Enjoo"). Además, la pregunta del mapa ("Onde você sente dor ou incômodo?") no coincide ni con el cliente ni con EST §6. Conviene que el cliente valide los recortes.

DONE
