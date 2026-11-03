# Especificación del cliente — "Dualis Free" (recibida 2026-11-02)

Transcripción estructurada del pedido del cliente (pt-BR). Se conserva el texto de las opciones y frases tal como lo envió. Cuando el cliente mandó varias versiones, se toma la **última** como vigente y se anotan las diferencias en "Inconsistencias del pedido".

---

## 1. Cadastro (primera pantalla)

1.1 **Foto de cámara**: no se adapta al rostro; recorta el centro de la foto y corta la cabeza.
1.2 El cliente pregunta **cuál es el objetivo** de los tres elementos de la parte inferior de la pantalla:
- Central de privacidade
- Histórico e tendências
- Lembretes de hidratação

## 2. Principios de interacción diaria

2.1 Priorizar interacción gráfica (emojis, dibujos, colores, controles rápidos) en lugar de lectura.
2.2 Pocas opciones por pantalla. Evitar exceso de alternativas y menús profundos.
2.3 Saludo personal: "Olá Seres Baum, bom dia" (nombre del usuario + saludo según la hora).
2.4 Pregunta: "Hoje, como você está se sentindo EMOCIONALMENTE?" con emojis: bem / não tão bem.
2.5 Si la respuesta no es "bem/normal", la persona elige si la preocupación es del **passado, presente o futuro**.
2.6 Tono conversacional (ejemplo del cliente): "Ok, entendi que as coisas não estão tão bem por aí... Me conta: esses sentimentos, preocupações ou desejos estão mais ligados ao..."
2.7 Transiciones animadas (fade-in, efecto de escritura suave en pantalla limpia) entre pantallas.
2.8 Uso diario: rotar frases para evitar fatiga (7 variantes por posición; por día de la semana o al azar).
2.9 Prefiere escalas visuales.

---

## 3. Flujo psicoemocional (3 verticales temporales)

Pantalla 1 (todas): pregunta "O que está ocupando mais espaço na sua mente agora?" con botones:
[ ⏳ O que já passou ] [ 📍 O momento atual ] [ 🚀 O que vem pela frente ]

Después de cada elección, una frase de transición (backend elige 1 de 7). Pantalla 2 = bifurcación de 2 botones, con 7 frases de transición por botón. Pantalla 3 = 2 opciones de "autojulgamento" por rama (12 en total). Luego cierre (persistencia + intensidad).

### 3.1 PASSADO
Pantalla 1 — 7 transiciones:
1. "Olhar para trás às vezes dói ou nos prende... Deixa eu te entender melhor..."
2. "Relembrar faz parte. O que do passado está visitando sua mente hoje?"
3. "Às vezes nossa atenção fica presa lá atrás... O que houve?"
4. "Nossa história nos acompanha, mas hoje parece que ela está pesando um pouco mais..."
5. "Entendi. Parece que alguma coisa que já aconteceu ficou ecoando na sua cabeça..."
6. "Certo. Resgatar memórias exige energia. Vamos olhar mais de perto para esse momento..."
7. "Muitas vezes a nossa mente viaja no tempo para tentar resolver algo que já foi..."

Pantalla 2 — pregunta "Olhar para trás está te trazendo qual sensação?"
- [ 🍂 Uma tristeza ou saudade profunda ] — 7 transiciones:
  1. "Compreendo... Essa falta pesa no peito. É algo mais específico?"
  2. "Sentir essa ausência é doloroso. O que exatamente está fazendo falta hoje?"
  3. "A nostalgia e a melancolia têm um peso próprio. Me conta onde dói mais:"
  4. "Essa sensação de vazio costuma falar sobre o que mudou. É sobre o quê?"
  5. "Acolho o seu desabafo. Vamos tentar clarear um pouco o que é esse sentimento:"
  6. "Às vezes o peito aperta quando lembramos. Qual o formato dessa tristeza hoje?"
  7. "Entendo... É uma sensação de perda ou de caminhos que ficaram para trás?"
- [ 🔁 Uma angústia ou memória que incomoda ] — 7 transiciones:
  1. "Sei como é... Pensamentos antigos martelando. O que exatamente está voltando?"
  2. "Memórias desconfortáveis podem ser muito invasivas. O que está insistindo em aparecer?"
  3. "Lidar com o que incomoda exige coragem. O que está tirando sua paz agora?"
  4. "Parece que um fantasma do passado resolveu dar as caras hoje. O que ele traz?"
  5. "Ficar preso a uma cena antiga desgasta muito a mente. É sobre qual tipo de conflito?"
  6. "Essa angústia geralmente sinaliza algo que não foi bem digerido por aí. O que houve?"
  7. "Compreendo o incômodo. Vamos dar um nome para esse pensamento que está te travando:"

Pantalla 3:
- Desde tristeza/saudade:
  - [ 🛑 Um sentimento de culpa ou arrependimento ] → tag `auto_recriminacao` → síntoma "Humor deprimido com autoincriminação / Culpa excessiva" → Grupo 01 Transtornos Depressivos/Afetivos
  - [ ⏳ A falta de alguém ou do jeito que as coisas eram ] → `melancolia_passado` → "Anseio persistente por perda" → Grupo 02 Luto Prolongado e Adaptação
- Desde angústia/memória:
  - [ ⚠️ Uma lembrança ruim que insiste em voltar ] → `estresse_traumatico` → "Intrusão cognitiva involuntária" → Grupo 03 Trauma e Estresse (TEPT)
  - [ 🔄 Fico remoendo mágoas ou rejeições antigas ] → `afeto_retido` → "Ruminação interpessoal rígida" → Grupo 04 Traços de Personalidade

### 3.2 PRESENTE
Pantalla 1 — 7 transiciones:
1. "O agora tem exigido muito de você, não é? Vamos olhar para isso juntos..."
2. "Viver o presente às vezes é desafiador. Onde está o seu foco hoje?"
3. "Muita coisa acontecendo ao mesmo tempo... Como você se sente com o hoje?"
4. "Estar no aqui e agora está parecendo uma tarefa pesada neste momento..."
5. "Certo. Vamos aterrar os pensamentos e entender o que está acontecendo nas suas últimas horas..."
6. "O dia a dia consome nossa energia. Me conta o que está drenando você agora..."
7. "Entendido. Quando o presente nos puxa com força, vale a pena investigar o motivo..."

Pantalla 2 — pregunta "Como seu corpo e sua mente estão reagindo ao agora?"
- [ 🔋 Me sinto esgotado e sem energia ] — 7 transiciones:
  1. "Seu corpo está pedindo arrego... Me conta como é esse cansaço:"
  2. "A exaustão física e mental desliga nossos motores. O que você sente mais forte?"
  3. "Estar sem bateria é um sinal de alerta sério. Como esse esgotamento se traduz?"
  4. "Parece que você está operando na reserva da reserva hoje. Onde pesa mais?"
  5. "Respire fundo. Não precisa carregar o mundo nas costas. O que essa fadiga te causa?"
  6. "Esse cansaço extremo nubla a nossa percepção. De que forma ele está se manifestando?"
  7. "Entendo perfeitamente o esgotamento. Me ajuda a categorizar o que sumiu por aí:"
- [ ⚡ Me sinto irritado ou sobrecarregado ] — 7 transiciones:
  1. "Os nervos estão à flor da pele por aí... O que parece estar transbordando?"
  2. "A sensação de sobrecarga nos deixa com pavio curto. O que está gerando essa pressão?"
  3. "Muita pressão externa acaba gerando faíscas internas. O que está te irritando?"
  4. "Parece que o ambiente ao seu redor engoliu a sua paciência hoje. O que está acontecendo?"
  5. "Lidar com o excesso de estímulos causa essa reatividade. Onde está o gatilho principal?"
  6. "Estar sobrecarregado faz a mente querer explodir para se defender. O que está demais?"
  7. "Compreendo o nível de estresse. Vamos tentar isolar o foco dessa angústia imediata:"

Pantalla 3:
- Desde esgotado:
  - [ 🪫 Meu corpo está pesado, tenso ou com dores ] → `sobrecarga_somatica` → Grupo 05 Sintomas Somáticos / Burnout
  - [ 🌫️ Me sinto no piloto automático ou meio desligado ] → `anedonia_embotamento` → Grupo 06 Dissociativos
- Desde irritado/sobrecarregado:
  - [ 💥 Estou sem paciência e explodindo por pouco ] → `baixo_limiar_frustracao` → Grupo 07 Controle de Impulsos
  - [ 🌪️ Sinto um sufoco no peito e crises de desespero ] → `reatividade_ambiental` → Grupo 08 Pânico e Agorafobia

### 3.3 FUTURO
Pantalla 1 — 7 transiciones:
1. "O amanhã pode parecer um grande ponto de interrogação... Me conta uma coisa..."
2. "Olhar para frente acelera o passo... Como está sua mente em relação ao amanhã?"
3. "O futuro reserva muitas expectativas. O que ele está te trazendo agora?"
4. "Projetar cenários que ainda não existem consome um esforço enorme do seu cérebro..."
5. "Entendi. O amanhã está roubando a atenção do seu momento atual..."
6. "Planejar é bom, mas tentar controlar o amanhã gera muita tensão. Vamos entender isso..."
7. "Certo. Quando os olhos focam muito na linha do horizonte, o peito costuma responder..."

Pantalla 2 — pregunta "O que você sente quando projeta o amanhã?"
- [ 💬 Uma mente acelerada que não para ] — 7 transiciones:
  1. "Essa engrenagem na sua cabeça rodando sem parar... O foco está em:"
  2. "Pensamentos em cascata causam um ruído interno gigante. Qual o assunto principal deles?"
  3. "Acelerar o pensamento é como correr em uma esteira sem fim. Para onde você está correndo?"
  4. "Essa pressa interna geralmente tenta prever problemas. O que sua mente está arquitetando?"
  5. "Entendo o turbilhão. Quando o rádio interno não desliga, o que ele fica repetindo?"
  6. "Uma mente que não descansa acaba gerando uma cobrança pesada. De onde vem esse ruído?"
  7. "Sei bem como é esse loop mental. Vamos categorizar o foco desse fluxo de pensamentos:"
- [ 🚨 Um medo do que pode dar errado ] — 7 transiciones:
  1. "O medo tenta nos paralisar para nos proteger. O que mais assusta você?"
  2. "A insegurança em relação ao amanhã gera cenários difíceis. Qual o seu maior receio?"
  3. "O medo do amanhã costuma sussurrar previsões ruins no nosso ouvido. O que ele está dizendo?"
  4. "Antecipar o pior é uma defesa exaustiva da mente. Diante do que você se sente desprotegido?"
  5. "Compreendo essa sensação de ameaça no horizonte. O que exatamente disparou o alerta?"
  6. "O medo do fracasso ou da incerteza pesa muito hoje. O que você está tentando evitar?"
  7. "Respeito o seu temor. Vamos tentar dar uma forma lógica para essa preocupação com o futuro:"

Pantalla 3:
- Desde mente acelerada:
  - [ 🧠 Fico antecipando problemas e cenários ruins ] → `ansiedade_cognitiva` → Grupo 09 TAG
  - [ 🏋️ Uma cobrança esmagadora por perfeição ou controle ] → `perfeccionismo_ansioso` → Grupo 10 TOC
- Desde medo:
  - [ 👥 Medo de falhar, ser julgado ou passar vergonha ] → `antecipacao_ameaca` → Grupo 11 Ansiedade Social
  - [ 📉 Desânimo com o rumo das coisas e falta de perspectiva ] → `desamparo_aprendido` → Grupo 12 Humor / Espectro Bipolar

### 3.4 Cierre (orden vigente)
Transición final: "Obrigado por compartilhar isso comigo hoje. Só para eu entender a intensidade disso na sua rotina..."

Paso 1 — Persistencia: "E há quanto tempo você nota esse padrão se repetindo?"
- [ ⏱️ Começou hoje ] [ ⏳ Há alguns dias ou semanas ] [ 🔄 Há muitos meses ou anos ]

Paso 2 — Intensidad: "E olhando para o agora, o quanto isso está pesando na sua rotina?"
- 🟢 1 Leve: É só um pensamento passageiro. Sigo o dia normalmente.
- 🟡 2 Notável: Exige um pouco de atenção, mas consigo manter meu foco.
- 🟠 3 Desgastante: Está diminuindo meu rendimento, foco ou energia.
- 🔴 4 Severo: Está alterando meu comportamento (sono, isolamento, tarefas).
- ☠️ 5 Paralisante: Está me bloqueando completamente nas últimas horas.

(Variante anterior del cliente: también pidió "Por quanto tempo esse sentimento ficou presente hoje?" — Momento isolado / Metade do dia / O dia todo.)

### 3.5 Datos y reportes que pide el cliente
- Guardar por registro: eje temporal, frase de transición usada, bifurcación, tag, síntoma estructurado, grupo clínico (id + nombre), persistencia, intensidad 1–5.
- Capa UI en lenguaje cotidiano; capa backend traduce "silenciosamente" a síntoma estructurado y grupo clínico DSM-5/CID-11.
- Reglas de acumulación: un registro = 1 punto de "estado"; "posible diagnóstico" si la misma tag aparece ≥4 días/semana o ≥10 días/mes con intensidad >3.
- Reporte a los 14–15 días: "Notamos que nos últimos 14 dias você passou 65% do seu tempo focado no Futuro, acumulando tensões de Ansiedade Generalizada… mais forte nas terças e quintas." Versión suavizada: "60% dos seus picos de estresse estiveram concentrados na Categoria 09".
- Score que direcciona a "Verticais de Tratamento": Encaminhamento Psiquiátrico / TCC / Psicanálise / Estilo de Vida.
- Exportación de datos para llevar a un profesional.
- Cuadrantes de tendencia: Internalizante Afetiva, Internalizante Ansiosa, Externalizante/Impulsiva, Bem-estar/Protetiva (mapear también lo positivo).
- Correlación físico–emocional ("Categoria 09 seguida de palpitações intensidade 3").

---

## 4. Flujo físico (mismo nivel de detalle)

Pantalla 1 — mapa anatómico: "Em qual parte do seu corpo você está sentindo esse desconforto agora?"
[ Cabeça ou Pescoço ] [ Tórax ou Peito ] [ Abdômen ou Ventre ] [ Coluna ou Costas ] [ Membros (Braços, Pernas ou Mãos) ]

Pantalla 2 — 7 transiciones por región + 2 botones:

**Cabeça ou Pescoço** — transiciones:
1. "Essa é uma região sensível às tensões do dia... Como você descreve o que sente?"
2. "O peso na mente às vezes se reflete física e diretamente aqui. O que está acontecendo?"
3. "Certo. Vamos registrar esse ponto de tensão. Como ele se manifesta agora?"
4. "Entendi. Desconfortos nessa área mudam totalmente o nosso dia. Qual a sensação principal?"
5. "Concentrar o foco no topo do corpo ajuda a isolar a queixa. O que está incomodando?"
6. "Acolho o seu relato. Vamos mapear o tipo de sinal que a sua cabeça está enviando:"
7. "Perceber o desconforto facial ou cervical é o primeiro passo. Me conta mais:"
Botones: [ 🧠 Uma sensação de aperto, peso ou pressão ] [ 👄 Algo incomodando nos sentidos, boca ou garganta ]

**Tórax ou Peito** — transiciones:
1. "A região do peito responde muito rápido ao nosso ritmo de vida. O que você nota?"
2. "Certo. Sentir o tórax reagir merece atenção e registro cuidadoso. Como está essa sensação?"
3. "Vamos olhar para o centro do seu peito agora. O que parece fora do lugar?"
4. "Compreendo. É uma área que abriga nossos ritmos vitais. Qual o sinal principal de hoje?"
5. "Aterrar a atenção na respiração e no coração ajuda a descrever o peso. O que houve?"
6. "Entendido. O corpo fala através desses sinais torácicos. Me ajuda a entender:"
7. "Registrar o desconforto no peito é fundamental para o seu histórico. O que está presente?"
Botones: [ 🫁 Uma alteração no ritmo ou na forma de respirar ] [ 🫀 Um incômodo físico na altura do coração ou costelas ]

**Abdômen ou Ventre** — transiciones:
1. "O nosso centro digestivo é extremamente reativo às nossas rotinas. O que há por aí?"
2. "Certo. O abdômen costuma acumular muitas das nossas tensões diárias. Como ele está?"
3. "Vamos registrar o que o seu ventre está sinalizando nas últimas horas. O que você sente?"
4. "Entendi. Desconfortos nessa área alteram nossa energia vital. Qual o foco do incômodo?"
5. "Olhar para a região estomacal ou intestinal exige uma percepção clara. Me conta:"
6. "Acolho o seu check-up. O que o seu sistema digestivo ou abdominal está relatando agora?"
7. "Registrar essa queixa na linha do tempo ajuda a monitorar seus hábitos. Qual a sensação?"
Botones: [ 🤢 Uma queimação, azia ou estômago embrulhado ] [ ⚡ Uma cólica, pontada ou sensação de estufamento ]

**Coluna ou Costas** — transiciones:
1. "A nossa sustentação carregar o peso do dia a dia às vezes cobra um preço. Onde dói?"
2. "Certo. A coluna reflete muito a nossa postura física e emocional. O que você nota?"
3. "Vamos registrar esse ponto nas suas costas para acompanhar o histórico. Como está a dor?"
4. "Entendi. Um incômodo nas costas limita nossa liberdade de movimento. Qual a sensação?"
5. "Focar na linha da coluna ajuda a identificar o travamento. Me conta mais sobre isso:"
6. "Acolho o seu registro. A sua musculatura dorsal está sinalizando o que neste momento?"
7. "Mapear as dores nas costas ajuda a avaliar seus períodos de esforço. Como se manifesta?"
Botones: [ 🪵 Uma rigidez, peso ou sensação de travamento muscular ] [ ⚡ Uma dor pontual que fisga ou queima ao mover ]

**Membros** — transiciones:
1. "Nossos braços e pernas executam nossas ações. Onde está o limite hoje?"
2. "Certo. O cansaço ou a tensão nas extremidades afeta nossa mobilidade. O que houve?"
3. "Vamos catalogar essa sensação nos membros para o seu banco de dados. Como ela é?"
4. "Entendi. Mãos, braços ou pernas doloridas mudam nosso rendimento. Qual o sinal?"
5. "Focar na musculatura ou articulação das articulações ajuda a clarear a queixa. O que sente?"
6. "Acolho seu check-up físico. Como os seus membros estão respondendo ao agora?"
7. "Registrar a fadiga periférica ajuda a entender seus picos de atividade física. Me conta:"
Botones: [ 🏋️ Uma fadiga, fraqueza ou dor muscular generalizada ] [ 🧊 Uma dormência, formigamento ou sensação de choque ]

Pantalla 3 — opción final → síntoma estructurado → "Esfera":
- Cabeça / aperto: [ 🤕 Uma dor ou pressão nas têmporas ou testa ] → Cefaleia tensional → Esfera 01 Neurológico; [ 🤯 Uma pulsação forte que incomoda a luz ou ruídos ] → Crise enxaquecosa → Esfera 02 Vascular Craniano
- Cabeça / sentidos: [ 👄 Garganta arranhando, seca ou dificuldade de engolir ] → Esfera 03 Otorrino/Imunológico; [ 👁️ Olhos pesados, ardendo ou visão cansada ] → Esfera 04 Oftalmológico
- Tórax / respiração: [ 🫁 Respiração curta, falta de ar ou sufocamento ] → Esfera 05 Respiratório/Autonômico; [ 🗣️ Uma tosse persistente ou peito carregado ] → Esfera 06 Respiratório Baixo
- Tórax / coração-costelas: [ 🫀 Coração acelerado, batedeira ou palpitação ] → Esfera 07 Cardiovascular; [ 🩻 Uma pontada ou dor nas costelas ao respirar fundo ] → Esfera 08 Osteomuscular Torácico
- Abdômen / queimação: [ 🤮 Queimação subindo para a garganta ou refluxo ácido ] → Esfera 09 Digestório Alto; [ 🤢 Enjoo forte, náusea ou estômago completamente travado ] → Esfera 10 Motilidade
- Abdômen / cólica: [ 💨 Gases abundantes, estufamento ou abdômen esticado ] → Esfera 11 Digestório Baixo; [ ⚡ Cólicas intestinais fortes ou pontadas pontuais ] → Esfera 12 Cólon Irritável
- Coluna / rigidez: [ 🪵 Pescoço e ombros duros, tensionados ou travados ] → Esfera 13 Axial Superior; [ 🪓 Peso na lombar ou dor cansada ao ficar em pé ] → Esfera 14 Axial Inferior
- Coluna / fisga: [ ⚡ Uma pontada aguda na coluna que irradia para a perna/braço ] → Esfera 15 Neurovertebral (solo 1 opción en el pedido)
- Membros / fadiga: [ 🦵 Juntas ou articulações doloridas e estalando ] → Esfera 16 Articular; [ 🦿 Pernas ou braços cansados, pesados e doloridos ] → Esfera 17 Muscular
- Membros / dormência: [ 🧊 Mãos ou pés dormentes, gelados ou formigando ] → Esfera 18 Nervoso Periférico (solo 1 opción en el pedido)

Pantalla 4 — cierre:
Paso 1: "E há quanto tempo você nota esse desconforto físico se repetindo?" — [ ⏱️ Começou hoje ] [ ⏳ Há alguns dias ou semanas ] [ 🔄 Há muitos meses ou anos ]
Paso 2: "Olhando para o agora, o quanto isso está limitando as suas ações cotidianas?"
- 🟢 1 Leve: Sinto o desconforto, mas ele não atrapalha nenhum movimento ou tarefa.
- 🟡 2 Notável: Incomoda ao me mexer ou trabalhar, mas mantenho minhas atividades normais.
- 🟠 3 Limitante: Diminuiu minha mobilidade, foco ou me fez pausar/tomar um remédio de rotina.
- 🔴 4 Severo: Está alterando meu comportamento (não consigo trabalhar, dormir ou me mover direito).
- ☠️ 5 Incapacitante: Travou meu corpo completamente no momento ou exige suporte imediato.

---

## 5. Inconsistencias del pedido (detectadas al transcribir)

- Numeración de grupos emocionales cambia entre versiones (en una versión Dissociativos = 08 y Pânico = 07; TOC = 11 y Social = 10). Vigente: la de §3.
- Tag `reatividade_ambiental` se usa para "É muita coisa ao mesmo tempo" en una versión y para "sufoco no peito/crises de desespero" (pánico) en otra.
- Flujo físico: la Pantalla 2 promete "caminhos 1–20", pero la Pantalla 3 trae 18 esferas; "Coluna / fisga" y "Membros / dormência" tienen 1 opción cada uno en vez de 2.
- Orden del cierre: una versión pide intensidad primero y luego duración; la versión "Na Ordem Correta" pide persistencia primero y luego intensidad (vigente).
- El pedido mezcla "History Storage sin diagnóstico" con "gatilho de alerta clínico / possível diagnóstico" y "Encaminhamento Psiquiátrico".
