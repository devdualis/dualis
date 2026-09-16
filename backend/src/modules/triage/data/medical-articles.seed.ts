export interface SeedArticleDefinition {
  id: string;
  title: string;
  category: string;
  somaticSystem?: string;
  author: string;
  authorRole: string;
  readTimeMinutes: number;
  summary: string;
  contentMarkdown: string;
  keywords: string[];
  url: string;
}

export const MEDICAL_ARTICLES_SEED: SeedArticleDefinition[] = [
  // ==========================================
  // TABELA 1: VERTICAL SAÚDE PSICO-EMOCIONAL (7 DIMENSÕES)
  // ==========================================

  // 1. Ansiosa / Agitação
  {
    id: 'art-ansiedade-01',
    title: 'Manejo da Ansiedade Aguda e Agitação Psicomotora',
    category: 'ansiosa_agitacao',
    somaticSystem: 'emocional',
    author: 'Dra. Camila Prado',
    authorRole: 'Psiquiatra Clínica (ABP / CRM-SP 165.340)',
    readTimeMinutes: 4,
    summary: 'Exercício guiado de respiração diafragmática 4-7-8 para desaceleração autonômica em estados de agitação, nervosismo e pensamentos acelerados.',
    contentMarkdown: `A ansiedade aguda e a agitação psicomotora ativam intensamente o ramo simpático do sistema nervoso autônomo, acelerando os batimentos e desencadeando pensamentos em turbilhão. A técnica de respiração 4-7-8 atua diretamente no tônus vagal: inspire suavemente pelo nariz contando até 4, retenha o ar nos pulmões por 7 segundos e expire lenta e sonoramente pela boca durante 8 segundos.

Repetir esse ciclo por 4 a 6 vezes reduz comprovadamente a descarga adrenérgica e acalma a mente acelerada. Se o nervosismo persistir, combine a respiração com movimentos de ancoragem nos pés, sentindo o solo firme para diminuir a inquietação motora.`,
    keywords: [
      'ansiedade',
      'agitacao',
      'nervosismo',
      'pensamentos acelerados',
      'crise de ansiedade',
      'inquietacao',
      'respiracao diafragmatica',
      'taquicardia ansiosa',
      'mente acelerada',
    ],
    url: 'https://drauziovarella.uol.com.br/saude-mental/transtornos-de-ansiedade-nao-sao-todos-iguais-entenda-as-caracteristicas-de-cada-tipo/',
  },
  {
    id: 'art-ansiedade-02',
    title: 'Crises de Pânico: Reconhecimento e Protocolo de Grounding 5-4-3-2-1',
    category: 'ansiosa_agitacao',
    somaticSystem: 'emocional',
    author: 'Dr. Henrique Mascarenhas',
    authorRole: 'Psiquiatra e Especialista em Transtornos de Ansiedade (ABP / CRM-SP 177.220)',
    readTimeMinutes: 5,
    summary: 'Como interromper a escalada fisiológica durante crises agudas de pânico, sensação de sufocamento e hiperventilação através de técnicas sensoriais.',
    contentMarkdown: `Uma crise de pânico costuma ter início súbito, com palpitações acentuadas, falta de ar subjetiva, tremores e medo extremo de perder o controle. A técnica de orientação sensorial 5-4-3-2-1 ajuda a retirar o foco do alarme interno:

1. Nomeie 5 coisas que você pode enxergar ao seu redor.
2. Identifique 4 texturas que você pode tocar agora.
3. Foque em 3 sons distintos do ambiente.
4. Perceba 2 aromas diferentes.
5. Sinta 1 sabor presente na sua boca.

Lembre-se de que a crise de pânico é autolimitada e tem pico médio de 10 minutos. Caso ocorra dor torácica irradiada ou síncope verdadeira, procure avaliação médica de emergência para descarte orgânico.`,
    keywords: [
      'crises de panico',
      'panico',
      'crise de panico',
      'medo intenso',
      'hiperventilacao',
      'pensamentos acelerados',
      'grounding',
      'palpitacao ansiosa',
      'tremores emocionais',
      'ansiedade aguda',
    ],
    url: 'https://drauziovarella.uol.com.br/psiquiatria/sindrome-do-panico/',
  },

  // 2. Depressiva / Desânimo
  {
    id: 'art-desanimo-01',
    title: 'Ativação Comportamental: Passos Práticos Contra a Apatia e Desânimo',
    category: 'depressiva_desanimo',
    somaticSystem: 'emocional',
    author: 'Dr. Rafael Nogueira',
    authorRole: 'Psiquiatra e Psicoterapeuta (CRM-SP 148.910)',
    readTimeMinutes: 5,
    summary: 'Estratégias graduais para quebrar o ciclo de desânimo, apatia, falta de energia para nada e resgatar a motivação diária.',
    contentMarkdown: `O desânimo profundo e a apatia criam uma armadilha comportamental: a pessoa não tem energia para nada, isola-se, reduz seus estímulos e a inatividade reforça a química depressógena cerebral. A ativação comportamental propõe a inversão dessa lógica: a ação deve preceder a motivação.

Defina micro-objetivos realizáveis: arrumar a cama, caminhar 5 minutos ao sol ou tomar um banho revigorante. Ao concluir pequenas ações com consistência, os circuitos de recompensa dopaminérgicos começam a se reestruturar. Não espere a vontade chegar: dê o primeiro passo mecânico e observe como seu corpo responde.`,
    keywords: [
      'desanimo',
      'apatia',
      'sem energia para nada',
      'vontade de chorar',
      'falta de energia',
      'desmotivacao',
      'ativacao comportamental',
      'fadiga emocional',
      'abatimento',
    ],
    url: 'https://www.paho.org/pt/topicos/depressao',
  },
  {
    id: 'art-desanimo-02',
    title: 'Tristeza Persistente e Vontade de Chorar: Avaliação Clínica e Cuidados',
    category: 'depressiva_desanimo',
    somaticSystem: 'emocional',
    author: 'Dra. Mônica Furtado',
    authorRole: 'Psiquiatra (FMUSP / CRM-SP 182.440)',
    readTimeMinutes: 5,
    summary: 'Diferenciação entre momentos de tristeza reativa e quadros depressivos persistentes acompanhados de vontade de chorar, choro fácil e anedonia.',
    contentMarkdown: `A tristeza é uma emoção humana básica e adaptativa diante de perdas e frustrações. No entanto, quando a tristeza se torna constante, há choro fácil ou vontade frequente de chorar, desinteresse pelas atividades prazerosas (anedonia) e sensação de vazio há mais de duas semanas, é fundamental buscar avaliação especializada.

Quadros depressivos envolvem desregulação em neurotransmissores como serotonina e noradrenalina. O acolhimento médico precoce, aliado à psicoterapia e eventualmente medicamentos de primeira linha, possui altas taxas de remissão e restabelece a qualidade de vida.`,
    keywords: [
      'tristeza',
      'vontade de chorar',
      'choro facil',
      'depressao',
      'tristeza persistente',
      'anedonia',
      'desanimo profundo',
      'sem energia',
      'isolamento',
    ],
    url: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/d/depressao',
  },

  // 3. Estresse / Burnout
  {
    id: 'art-burnout-01',
    title: 'Esgotamento e Sobrecarga no Trabalho: Prevenção do Burnout',
    category: 'estresse_burnout',
    somaticSystem: 'emocional',
    author: 'Dr. Lucas Rossi',
    authorRole: 'Psicólogo Clínico e do Trabalho (CRP-06/123456)',
    readTimeMinutes: 5,
    summary: 'Reconhecendo os sinais precoces de estar esgotado, sobrecarregado no trabalho, irritável e com sobrecarga profissional crônica.',
    contentMarkdown: `O esgotamento profissional não surge da noite para o dia. Ele se instala silenciosamente quando há excesso contínuo de demandas e pouco tempo para restauração biopsicossocial. Estar sempre esgotado, sentir-se constantemente sobrecarregado no trabalho e apresentar irritabilidade fácil com colegas ou familiares são sintomas característicos da síndrome de burnout.

A primeira linha preventiva envolve estabelecer limites rígidos entre trabalho e vida pessoal: desativar notificações fora do expediente, programar micropausas ativas durante a jornada e renegociar prazos inexequíveis. A saúde física e mental é pré-requisito indispensável para qualquer produtividade sustentável.`,
    keywords: [
      'esgotado',
      'sobrecarregado no trabalho',
      'estresse',
      'burnout',
      'sobrecarga profissional',
      'irritavel',
      'exaustao mental',
      'pressao no trabalho',
    ],
    url: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/s/sindrome-de-burnout',
  },
  {
    id: 'art-burnout-02',
    title: 'Cabeça Cheia e Estresse Contínuo: Modulação do Cortisol e Pausas Restauradoras',
    category: 'estresse_burnout',
    somaticSystem: 'emocional',
    author: 'Dra. Lúcia Cavalcante',
    authorRole: 'Psiquiatra e Especialista em Burnout (CRM-SP 159.080)',
    readTimeMinutes: 4,
    summary: 'Como o excesso de demandas gera sensação de cabeça cheia, estresse diário e irritabilidade, com protocolos de higiene mental e regulação fisiológica.',
    contentMarkdown: `A queixa frequente de "cabeça cheia" reflete sobrecarga cognitiva e hiperativação crônica do eixo hipotálamo-hipófise-adrenal (HPA), mantendo níveis elevados de cortisol circulante. Essa condição prejudica o sono, reduz a flexibilidade mental e torna a pessoa irritável diante de pequenos imprevistos.

Para regular esse estado, recomenda-se a prática de "descarregamento mental": anotar pendências em papel para esvaziar a memória de trabalho, caminhar 15 minutos em ambientes arborizados e praticar pausas de descompressão sem telas. Essas intervenções simples reduzem a pressão intracraniana percebida e protegem a homeostase neuroquímica.`,
    keywords: [
      'estressado',
      'cabeca cheia',
      'irritavel',
      'cortisol',
      'estresse cronico',
      'tensao constante',
      'sobrecarga cognitiva',
      'irritabilidade',
      'pavio curto',
    ],
    url: 'https://drauziovarella.uol.com.br/entrevistas-2/estresse-entrevista/',
  },

  // 4. Somática (Psicossomática)
  {
    id: 'art-somatica-01',
    title: 'Manifestações Psicossomáticas: Nó na Garganta e Aperto no Peito Emocional',
    category: 'somatica',
    somaticSystem: 'emocional',
    author: 'Dra. Juliana Guimarães',
    authorRole: 'Médica de Família e Comunidade (SBMFC / CRM-SP 171.045)',
    readTimeMinutes: 4,
    summary: 'Compreensão da resposta somática do organismo ao estresse, explicando o nó na garganta por nervoso e a sensação de aperto no peito de fundo emocional.',
    contentMarkdown: `O corpo expressa fisicamente as tensões emocionais que a mente não consegue processar. A sensação de nó na garganta por nervoso (globo faríngeo) é consequência do espasmo transitório dos músculos constritores da faringe mediado pelo sistema autônomo. Da mesma forma, o aperto no peito emocional decorre de hipertonia dos músculos intercostais e peitorais durante episódios de angústia.

Embora desconfortáveis, essas sensações não representam lesões estruturais quando causas cardiovasculares e otorrinolaringológicas são afastadas. Exercícios de relaxamento progressivo, liberação miofascial cervical e respiração profunda aliviam o tônus muscular em poucos minutos.`,
    keywords: [
      'no na garganta por nervoso',
      'aperto no peito de fundo emocional',
      'no na garganta',
      'aperto no peito emocional',
      'psicossomatica',
      'somatizacao',
      'globo histerico',
      'tensao emocional',
    ],
    url: 'https://drauziovarella.uol.com.br/psiquiatria/conexao-entre-mente-e-corpo-como-as-emocoes-afetam-a-saude/',
  },
  {
    id: 'art-somatica-02',
    title: 'Gastrite Nervosa e Desconforto Digestivo Relacionado ao Estresse',
    category: 'somatica',
    somaticSystem: 'emocional',
    author: 'Dr. Rodrigo Ponte',
    authorRole: 'Clínico Geral e Psicoterapeuta Somático (CRM-SP 165.790)',
    readTimeMinutes: 4,
    summary: 'Como a hiperatividade autonômica afeta a mucosa gástrica provocando gastrite nervosa, azia e queimação após momentos de tensão ou ansiedade.',
    contentMarkdown: `A chamada "gastrite nervosa" ilustra a conexão direta do eixo cérebro-intestino. Sob estresse agudo ou crônico, a estimulação vagal e adrenérgica altera a motilidade do trato gastrointestinal, eleva a secreção ácida e reduz o muco protetor gástrico, gerando azia, sensação de queimação no estômago e dor epigástrica reflexa.

O tratamento eficaz combina proteção gástrica orientada por médico e regulação comportamental do estresse. Mastigar devagar, evitar refeições volumosas sob tensão e praticar técnicas respiratórias pré-prandiais ajudam a harmonizar o trânsito digestivo.`,
    keywords: [
      'gastrite nervosa',
      'estomago nervoso',
      'azia emocional',
      'dor de estomago nervosa',
      'somatica',
      'queimacao nervosa',
      'dispepsia funcional',
      'dor no estomago por nervoso',
    ],
    url: 'https://drauziovarella.uol.com.br/gastroenterologia/gastrite/',
  },

  // 5. Sono (Insônia/Hipersônia)
  {
    id: 'art-sono-01',
    title: 'Higiene do Sono: O Que Fazer Quando Não Durmo Bem e Tenho Insônia',
    category: 'sono',
    somaticSystem: 'emocional',
    author: 'Dra. Helena Vasconcelos',
    authorRole: 'Especialista em Medicina do Sono (ABMS / CRM-SP 153.220)',
    readTimeMinutes: 4,
    summary: 'Diretrizes práticas para quem não dorme bem, enfrenta insônia de início ou acorda de madrugada com dificuldade para retomar o repouso.',
    contentMarkdown: `Queixas de "não durmo bem" e acordar de madrugada no meio da noite afetam mais de 40% da população adulta. A insônia fragmenta o ciclo circadiano e compromete a consolidação de memórias e a regeneração celular.

A higiene do sono atua na sincronização da melatonina: desligue telas emissoras de luz azul pelo menos 60 minutos antes de se deitar, mantenha o quarto escuro e em temperatura amena e evite bebidas cafeinadas após as 14h. Se acordar de madrugada e não conseguir dormir em 20 minutos, levante-se, realize uma atividade relaxante com luz fraca e só retorne à cama com sono real.`,
    keywords: [
      'nao durmo bem',
      'insonia',
      'acordo de madrugada',
      'acordar de madrugada',
      'dificuldade para dormir',
      'sono fragmentado',
      'higiene do sono',
      'sono ruim',
    ],
    url: 'https://drauziovarella.uol.com.br/neurologia/higiene-do-sono-conheca-11-dicas-para-dormir-melhor/',
  },
  {
    id: 'art-sono-02',
    title: 'Pesadelos Recorrentes e Hipersônia: Causas do Sono Excessivo e Despertares Ansiosos',
    category: 'sono',
    somaticSystem: 'emocional',
    author: 'Dr. Eduardo Faria',
    authorRole: 'Neurologista Especialista em Sono (ABNS / CRM-SP 168.300)',
    readTimeMinutes: 5,
    summary: 'Explicação clínica sobre pesadelos frequentes e hipersônia (dormir demais sem sensação de descanso), abordando a qualidade do sono profundo e ritmo circadiano.',
    contentMarkdown: `Tanto a falta quanto o excesso de sono sinalizam desequilíbrios. Dormir demais (hipersônia) e acordar sem energia costuma indicar fragmentação das fases de sono profundo (N3 e REM), podendo estar associado a quadros respiratórios obstrutivos ou fases depressivas. Por outro lado, pesadelos frequentes decorrem de hipervigilância noturna e processamento emocional traumático residual.

Para amenizar pesadelos e melhorar a eficiência do sono, adote rotinas de descompressão antes de deitar, evitando noticiários sensacionalistas e refeições pesadas. A persistência de sonolência diurna excessiva justifica exame de polissonografia para mapeamento neurofisiológico.`,
    keywords: [
      'pesadelos',
      'durmo demais',
      'hipersonia',
      'sonolencia excessiva',
      'acordo no meio da noite',
      'sono nao reparador',
      'dormir o dia todo',
      'pesadelo',
    ],
    url: 'https://drauziovarella.uol.com.br/doencas-e-sintomas/insonia/',
  },

  // 6. Cognitiva / Foco
  {
    id: 'art-cognitiva-01',
    title: 'Névoa Mental (Brain Fog) e Mente Lerda: Recuperando a Clareza',
    category: 'cognitiva_foco',
    somaticSystem: 'emocional',
    author: 'Dra. Mariana Fagundes',
    authorRole: 'Neuropsicóloga Clínica (CRP-06/98765)',
    readTimeMinutes: 5,
    summary: 'Causas fisiológicas e rotinas para reverter a mente lerda, sensação de névoa mental (brain fog), falta de foco e cansaço cognitivo.',
    contentMarkdown: `A queixa de estar sem foco, com mente lerda e névoa mental (*brain fog*) é cada vez mais comum. Essa sensação de lentidão no processamento mental decorre com frequência de privação de sono reparador, estresse oxidativo, sobrecarga multitarefa ou carências nutricionais (como vitamina B12 e ferro).

Para recuperar a clareza, priorize o monofoco: realize uma atividade por vez, utilize blocos cronometrados de foco (Pomodoro de 25 minutos com 5 de pausa) e faça pequenas caminhadas ao ar livre para estimular a oxigenação cerebral e fatores neurotróficos (BDNF).`,
    keywords: [
      'mente lerda',
      'nevoa mental',
      'brain fog',
      'sem foco',
      'falta de concentracao',
      'lentidao mental',
      'foco',
      'cognitivo',
      'mente pesada',
    ],
    url: 'https://drauziovarella.uol.com.br/neurologia/como-estimular-o-cerebro-no-dia-a-dia/',
  },
  {
    id: 'art-cognitiva-02',
    title: 'Esquecimento no Dia a Dia e Lapsos de Foco: Quando Buscar Apoio',
    category: 'cognitiva_foco',
    somaticSystem: 'emocional',
    author: 'Dr. Fábio Goulart',
    authorRole: 'Neurologista e Neuropsicólogo (HCFMUSP / CRM-SP 174.880)',
    readTimeMinutes: 4,
    summary: 'Distinguindo esquecimento funcional gerado por sobrecarga e estresse de alterações que requerem investigação neuropsicológica detalhada.',
    contentMarkdown: `Sentir-se esquecido no cotidiano — como esquecer onde guardou objetos ou nomes de conhecidos recentes — frequentemente não é perda de memória verdadeira, mas sim falha de atenção primária provocada por ansiedade e distrações eletrônicas contínuas.

Quando a mente está sobrecarregada, a informação sequer chega a ser codificada no hipocampo. Organizar listas diárias, reduzir o consumo de vídeos rápidos e treinar a atenção plena restaura a fixação de memórias. Se os lapsos envolverem desorientação espacial ou tarefas previamente automáticas, uma consulta com neurologista é recomendada.`,
    keywords: [
      'esquecido',
      'lapsos de memoria',
      'esquecimento',
      'sem foco',
      'perda de memoria recente',
      'desatencao',
      'mente dispersa',
      'foco e memoria',
    ],
    url: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/a/alzheimer',
  },

  // 7. Autoestima / Autoimagem
  {
    id: 'art-autoestima-01',
    title: 'Sentimento de Culpa e Sensação de Incapacidade: Como Ressignificar',
    category: 'autoestima',
    somaticSystem: 'emocional',
    author: 'Dr. Bruno Silveira',
    authorRole: 'Psicoterapeuta Cognitivo-Analítico (CRP-06/112340)',
    readTimeMinutes: 5,
    summary: 'Abordagem cognitiva para lidar com o sentimento de culpa excessivo e a sensação contínua de estar se sentindo incapaz perante os desafios.',
    contentMarkdown: `O sentimento de culpa corrosivo e a sensação de estar se sentindo incapaz alimentam um ciclo de desvalorização e evitação. Na terapia cognitiva, compreendemos que a culpa disfuncional geralmente parte de padrões distorcidos de responsabilidade pessoal: assumir o peso de acontecimentos fora do próprio controle.

Exercitar a diferenciação entre responsabilidade real e cobrança imaginária é libertador. Pergunte-se: "Se um amigo querido estivesse passando exatamente por isso, eu o julgaria com essa mesma severidade?". Aplicar a si a mesma gentileza que dedicamos aos outros é o primeiro alicerce da reparação emocional.`,
    keywords: [
      'sentimento de culpa',
      'me sentindo incapaz',
      'sensacao de incapacidade',
      'culpa',
      'autoestima',
      'autoimagem fragilizada',
      'sentimento de insuficiencia',
    ],
    url: 'https://www.paho.org/pt/topicos/saude-mental',
  },
  {
    id: 'art-autoestima-02',
    title: 'Autocrítica Severa: Ferramentas de Autocompaixão e Reestruturação',
    category: 'autoestima',
    somaticSystem: 'emocional',
    author: 'Dra. Isabela Duarte',
    authorRole: 'Psicóloga Especialista em Saúde Mental (CRP-06/87654)',
    readTimeMinutes: 4,
    summary: 'Identificando padrões de autocrítica severa e julgamento interno desmedido, promovendo uma relação mais construtiva com a própria autoimagem.',
    contentMarkdown: `A autocrítica severa funciona como um crítico interno impiedoso que minimiza sucessos e amplifica falhas de forma desproporcional, corroendo a autoimagem. Esse mecanismo frequentemente se origina de crenças nucleares precoces de perfeccionismo e medo da rejeição.

O desenvolvimento da autocompaixão não significa complacência, mas sim suporte compassivo diante das dificuldades. Ao perceber pensamentos autocríticos punitivos, pause e reformule a narrativa interna de maneira objetiva e acolhedora, reconhecendo a imperfeição como parte inerente à condição humana.`,
    keywords: [
      'autocritica severa',
      'autocritica',
      'autoimagem',
      'autoestima baixa',
      'perfeccionismo destrutivo',
      'autocompaixao',
      'culpa e autocobranca',
    ],
    url: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/s/saude-mental',
  },

  // ==========================================
  // TABELA 2: VERTICAL SAÚDE FÍSICA (12 SISTEMAS/ANATOMIAS)
  // ==========================================

  // 1. Cabeça e Pescoço
  {
    id: 'art-cabeca-01',
    title: 'Dor de Cabeça e Enxaqueca: Diferenciação, Sintomas e Primeiros Cuidados',
    category: 'cabeca_pescoco',
    somaticSystem: 'cabeca_pescoco',
    author: 'Dr. Thiago Albuquerque',
    authorRole: 'Neurologista Clínico (UNIFESP / CRM-SP 156.702)',
    readTimeMinutes: 4,
    summary: 'Como identificar cefaleia tensional e crises de enxaqueca pulsátil, com orientações de repouso, hidratação e gatilhos alimentares.',
    contentMarkdown: `As dores na região da cabeça e pescoço têm origens variadas. A cefaleia tensional costuma ser bilateral, com sensação de faixa apertando a cabeça ou peso na nuca, tipicamente associada à postura inadequada e estresse. Já a enxaqueca é comumente unilateral, latejante ou pulsátil, podendo vir acompanhada de aversão à luz (fotofobia), náusea e sensibilidade ao ruído.

No início do quadro, repousar em ambiente escuro e silencioso com hidratação oral auxilia no controle álgico. Sinais de alarme como início súbito e de intensidade máxima imediata ("trovoada"), fraqueza focal ou rigidez de nuca demandam atendimento emergencial imediato.`,
    keywords: [
      'dor de cabeca',
      'enxaqueca',
      'cefaleia',
      'dor latejante na cabeca',
      'enxaqueca com aura',
      'cabeca pesada',
      'dor na nuca',
    ],
    url: 'https://sbcefaleia.com.br/noticias.php?id=350',
  },
  {
    id: 'art-cabeca-02',
    title: 'Sinusite, Dor de Garganta e Dor nos Dentes: Identificando a Origem Facial',
    category: 'cabeca_pescoco',
    somaticSystem: 'cabeca_pescoco',
    author: 'Dr. Adriano Campos',
    authorRole: 'Otorrinolaringologista (ABORL-CCF / CRM-SP 149.330)',
    readTimeMinutes: 4,
    summary: 'Diagnóstico diferencial entre congestão e pressão por sinusite, inflamação com dor de garganta e odontalgias com dor nos dentes.',
    contentMarkdown: `A anatomia orofacial possui rica inervação compartilhada pelo nervo trigêmeo. Uma sinusite nos seios maxilares pode causar sensação de peso facial ao abaixar a cabeça e dor referida nos dentes superiores. Por outro lado, inflamações orofaríngeas manifestam-se com dor de garganta ao engolir, sensação de arranhar e febre moderada.

A lavagem nasal com soro fisiológico a 0,9% em alto volume alivia a pressão sinusal e fluidifica secreções. Manter boa higiene oral e agendar avaliação odontológica é essencial para descartar cáries profundas e periodontite quando a dor dentária for persistente.`,
    keywords: [
      'sinusite',
      'dor de garganta',
      'dor nos dentes',
      'dor de dente',
      'pressao na face',
      'garganta inflamada',
      'dor facial',
      'congestao nasal',
    ],
    url: 'https://drauziovarella.uol.com.br/doencas-e-sintomas/sinusite/',
  },

  // 2. Cardiovascular / Tórax
  {
    id: 'art-cardio-01',
    title: 'Batedeira no Peito e Coração Disparado: Compreendendo as Palpitações',
    category: 'cardiovascular_torax',
    somaticSystem: 'cardiovascular',
    author: 'Dra. Beatriz Silva',
    authorRole: 'Cardiologista (InCor / CRM-SP 142.890)',
    readTimeMinutes: 4,
    summary: 'O que significa sentir o coração disparado, palpitação ou sensação de batedeira no peito, diferenciando causas fisiológicas e quando buscar eletrocardiograma.',
    contentMarkdown: `Sentir o coração disparado ou sensação de batedeira no peito (palpitações) é uma das queixas que mais assustam as pessoas. Na maioria das situações em adultos jovens e sem cardiopatia prévia, trata-se de taquicardia sinusal decorrente de ansiedade, consumo excessivo de café ou energéticos, desidratação ou febre.

No entanto, palpitações que se iniciam de modo abrupto, batimentos descompassados ou episódios acompanhados de tontura e escurecimento visual exigem investigação com eletrocardiograma e Holter 24h para descartar arritmias cardíacas. Diminua estimulantes e monitore o padrão dos episódios.`,
    keywords: [
      'batedeira no peito',
      'coracao disparado',
      'palpitacao',
      'palpitacoes',
      'arritmia',
      'taquicardia',
      'batedeira',
      'coracao acelerado',
    ],
    url: 'https://drauziovarella.uol.com.br/entrevistas-2/arritmia-cardiaca-entrevista/',
  },
  {
    id: 'art-cardio-02',
    title: 'Dor no Peito: Sinais de Alerta Cardiovascular e Quando Acionar Urgência',
    category: 'cardiovascular_torax',
    somaticSystem: 'cardiovascular',
    author: 'Dr. Marcílio Araújo',
    authorRole: 'Cardiologista Intervencionista (SBC / CRM-SP 162.010)',
    readTimeMinutes: 5,
    summary: 'Critérios clínicos para avaliar dor no peito em aperto, queimação ou pontada, destacando os sinais de alerta que exigem atendimento médico imediato.',
    contentMarkdown: `Toda queixa de dor no peito deve ser encarada com máxima cautela e rigor clínico. A dor de origem isquêmica cardíaca costuma ser caracterizada como aperto, opressão ou queimação retroesternal profunda, podendo irradiar para o braço esquerdo, mandíbula ou dorso, associada a sudorese fria e náusea.

Dores em pontada superficial que pioram com a respiração profunda ou com a palpação local frequentemente têm origem muscular ou costocondral. Contudo, em vigência de fatores de risco (hipertensão, tabagismo, idade avançada) ou dúvida clínica, procure imediatamente um pronto-socorro ou acione o SAMU 192.`,
    keywords: [
      'dor no peito',
      'dor toracica',
      'aperto no peito',
      'dor no torax',
      'infarto',
      'angina',
      'urgencia cardiaca',
      'pressao no peito',
    ],
    url: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/i/infarto',
  },

  // 3. Sistema Respiratório
  {
    id: 'art-respiratorio-01',
    title: 'Falta de Ar e Cansaço ao Respirar: Avaliando Sintomas Pulmonares',
    category: 'respiratorio',
    somaticSystem: 'respiratorio',
    author: 'Dra. Clarissa Fontes',
    authorRole: 'Pneumologista (SBPT / CRM-SP 159.400)',
    readTimeMinutes: 4,
    summary: 'Entendendo a sensação de falta de ar e cansaço ao respirar no repouso ou em tarefas cotidianas, com métodos de alívio e checagem de oximetria.',
    contentMarkdown: `A falta de ar (dispneia) e a sensação de cansaço anormal ao respirar podem refletir desde hiperventilação de fundo emocional até patologias do parênquima pulmonar ou vias aéreas, como bronquite, asma e infecções respiratórias.

Em repouso, adote uma postura sentada com o tronco levemente inclinado para a frente (posição de tripé) e pratique a respiração com lábios semicerrados para desacelerar o fluxo aéreo. Se a falta de ar for súbita, vier com lábios arroxeados (cianose) ou saturação de oxigênio abaixo de 93% no oxímetro, trata-se de urgência médica.`,
    keywords: [
      'falta de ar',
      'cansaco ao respirar',
      'dificuldade para respirar',
      'respiracao curta',
      'dispneia',
      'sufocamento',
      'folego curto',
    ],
    url: 'https://sbpt.org.br/portal/publico-geral/doencas/falta-de-ar/',
  },
  {
    id: 'art-respiratorio-02',
    title: 'Chiado no Peito e Tosse Após Esforço: Asma, Bronquite e Cuidados',
    category: 'respiratorio',
    somaticSystem: 'respiratorio',
    author: 'Dr. Márcio Ventura',
    authorRole: 'Pneumologista e Alergologista (SBPT / CRM-SP 155.660)',
    readTimeMinutes: 4,
    summary: 'Orientação sobre chiado no peito (sibilos) e episódios de tosse após esforço físico, identificando broncoespasmo e inflamações das vias aéreas.',
    contentMarkdown: `Ouvir chiado no peito — som agudo e sibilante durante a expiração — acompanhado de tosse após esforço físico ou após exposição a ar frio e poeira é um forte indicativo de hiper-reatividade brônquica e broncoespasmo, como observado na asma brônquica.

Evite fumar ou se expor a fumaça de segunda mão, mantenha o quarto livre de ácaros e consulte um pneumologista para realização de espirometria (prova de função pulmonar). O uso de broncodilatadores inalatórios prescritos proporciona alívio rápido e previne exacerbações graves.`,
    keywords: [
      'chiado no peito',
      'tosse apos esforco',
      'tosse com esforco',
      'chiado',
      'tosse seca',
      'asma',
      'bronquite',
      'broncoespasmo',
      'tosse persistente',
    ],
    url: 'https://sbpt.org.br/portal/publico-geral/doencas/asma/',
  },

  // 4. Gastrointestinal / Abdômen
  {
    id: 'art-gastro-01',
    title: 'Azia, Queimação no Estômago e Refluxo: O Que Fazer',
    category: 'gastrointestinal_abdomen',
    somaticSystem: 'digestivo',
    author: 'Dr. Felipe Queiroz',
    authorRole: 'Gastroenterologista e Endoscopista (FBG / CRM-SP 143.770)',
    readTimeMinutes: 4,
    summary: 'Medidas dietéticas e posturais para alívio de azia persistente, sensação de queimação no estômago e desconforto epigástrico pós-prandial.',
    contentMarkdown: `A queimação no estômago (pirose) e a azia ocorrem pelo refluxo do ácido clorídrico gástrico para o esôfago inferior, irritando a mucosa. Fatores como refeições muito volumosas ou gordurosas, consumo frequente de café, bebidas alcoólicas e deitar-se logo após comer facilitam esse retorno ácido.

Para mitigar os episódios: fracione a alimentação em porções menores ao longo do dia, evite deitar-se nas 2 horas seguintes às principais refeições e eleve a cabeceira da cama em 15 centímetros. Sintomas persistentes por mais de três semanas requerem avaliação médica e endoscopia digestiva alta.`,
    keywords: [
      'azia',
      'queimacao no estomago',
      'queimacao',
      'refluxo',
      'dor no estomago',
      'estomago queimando',
      'azia e refluxo',
      'acidez estomacal',
    ],
    url: 'https://drauziovarella.uol.com.br/gastroenterologia/refluxo-saiba-o-que-e-os-sintomas-e-as-formas-de-tratamento/',
  },
  {
    id: 'art-gastro-02',
    title: 'Enjoo, Diarreia, Dor de Barriga e Cólica: Manejo Gastrointestinal',
    category: 'gastrointestinal_abdomen',
    somaticSystem: 'digestivo',
    author: 'Dra. Fernanda Toledo',
    authorRole: 'Gastroenterologista Clínica (FBG / CRM-SP 139.112)',
    readTimeMinutes: 5,
    summary: 'Guia de hidratação oral e repouso digestivo para episódios de enjoo, diarreia aguda, dor de barriga e cólica abdominal.',
    contentMarkdown: `Quadros agudos com enjoo, diarreia, dor de barriga e cólica abdominal são comumente causados por gastroenterites virais ou alimentares transitórias. O pilar fundamental do tratamento domiciliar é a prevenção de desidratação através da reposição hídrica rigorosa com soro de reidratação oral, água de coco e chás claros.

Alimente-se com dieta branda (arroz branco, batata cozida, maçã sem casca) e evite laticínios e açúcares fermentáveis. Se houver febre alta (>38,5°C), sangue nas fezes ou dor abdominal intensa e contínua que não cede, busque atendimento no pronto atendimento.`,
    keywords: [
      'enjoo',
      'diarreia',
      'dor de barriga',
      'colica',
      'colica intestinal',
      'nausea',
      'vomito',
      'barriga doendo',
      'gastroenterite',
    ],
    url: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/d/dda',
  },

  // 5. Coluna e Dor Dorsal
  {
    id: 'art-coluna-01',
    title: 'Dor nas Costas e Dor na Lombar: Postura, Ergonomia e Alívio',
    category: 'coluna_dor_dorsal',
    somaticSystem: 'musculoesqueletico',
    author: 'Dr. Marcelo Mendes',
    authorRole: 'Ortopedista e Traumatologista Especialista em Coluna (HCFMUSP / CRM-SP 128.450)',
    readTimeMinutes: 5,
    summary: 'Exercícios de descompressão, cuidados ergonômicos e fortalecimento do core para prevenir e amenizar dor nas costas e dores na região lombar.',
    contentMarkdown: `A dor nas costas, especialmente a dor na lombar (lombalgia), é a queixa musculoesquelética mais prevalente do mundo moderno. O sedentarismo associado a longas horas em cadeiras sem apoio lombar e a fraqueza da musculatura estabilizadora abdominal sobrecarregam os discos vertebrais.

Adote pausas a cada 50 minutos para alongamento da cadeia posterior e mobilização do quadril. Exercícios isométricos como a prancha frontal e o "bird-dog" fortalecem o core sem sobrecarregar as facetas articulares. Calor local por 20 minutos ajuda no relaxamento da musculatura paravertebral tensa.`,
    keywords: [
      'dor nas costas',
      'dor na lombar',
      'dor lombar',
      'lombalgia',
      'costas doendo',
      'coluna lombar',
      'dor dorsal',
      'lombar travada',
    ],
    url: 'https://sbot.org.br/dor-lombar-quais-os-motivos/',
  },
  {
    id: 'art-coluna-02',
    title: 'Travei o Pescoço ou as Costas: Conduta Imediata para Coluna Travada',
    category: 'coluna_dor_dorsal',
    somaticSystem: 'musculoesqueletico',
    author: 'Dra. Cristina Barros',
    authorRole: 'Neurocirurgiã e Especialista em Doenças da Coluna (CRM-SP 160.450)',
    readTimeMinutes: 5,
    summary: 'O que fazer nas primeiras horas quando você trava o pescoço ou as costas: repouso relativo, aplicação térmica correta e sinais de alarme neurológico.',
    contentMarkdown: `A expressão "travei o pescoço/costas" reflete uma contratura muscular reflexa intensa e protetora, geralmente desencadeada por movimento brusco, estresse ou início de protrusão discal. O repouso absoluto na cama por dias é contraindicado; o ideal é repouso relativo com movimentação leve e suave conforme tolerado.

Nas primeiras 48 horas, a aplicação de compressas mornas por 20 minutos ajuda a quebrar o espasmo muscular. Não realize manipulações bruscas no pescoço. Se a dor irradiar para as pernas com sensação de choque, perda de força no pé ou alterações no controle de urina/fezes, procure serviço de urgência com brevidade.`,
    keywords: [
      'travei o pescoco/costas',
      'travei as costas',
      'travei o pescoco',
      'coluna travada',
      'torcicolo',
      'travamento muscular',
      'espasmo dorsal',
      'pescoco travado',
    ],
    url: 'https://drauziovarella.uol.com.br/entrevistas-2/hernia-de-disco-entrevista/',
  },

  // 6. Membros Superiores (D/E)
  {
    id: 'art-superiores-01',
    title: 'Dor no Pulso e Tendinite na Mão: Prevenção de LER/DORT',
    category: 'membros_superiores',
    somaticSystem: 'musculoesqueletico',
    author: 'Dr. Rodrigo Sanches',
    authorRole: 'Ortopedista e Cirurgião da Mão (CRM-SP 144.220)',
    readTimeMinutes: 5,
    summary: 'Alongamentos e ajustes ergonômicos para trabalhadores e usuários de computador com tendinite na mão, dor no pulso e punhos inflamados.',
    contentMarkdown: `A dor no pulso e a tendinite na mão e dedos configuram quadros clássicos de Lesões por Esforços Repetitivos (LER/DORT), decorrentes de movimentos repetidos de digitação, manuseio de ferramentas ou smartphone sem descansos periódicos. A inflamação das bainhas tendíneas provoca dor à palpação, perda de força de preensão e inchaço localizado.

Ajuste a altura da cadeira para manter o antebraço a 90 graus com a mesa, com apoio almofadado para os punhos. Faça pausas de 2 minutos a cada hora para alongamento passivo dos tendões flexores e extensores do punho. Uso de gelo local após jornadas intensas auxilia na redução do processo inflamatório agudo.`,
    keywords: [
      'dor no pulso',
      'tendinite na mao',
      'dor na mao',
      'punho doendo',
      'tendinite',
      'LER DORT',
      'tunel do carpo',
      'digitacao',
    ],
    url: 'https://drauziovarella.uol.com.br/podcasts/tendinite/',
  },
  {
    id: 'art-superiores-02',
    title: 'Dor no Ombro e Braço Dormente: Manguito Rotador e Compressão Nervosa',
    category: 'membros_superiores',
    somaticSystem: 'musculoesqueletico',
    author: 'Dr. Leandro Peixoto',
    authorRole: 'Ortopedista Especialista em Ombro e Cotovelo (CRM-SP 152.990)',
    readTimeMinutes: 4,
    summary: 'Identificando tendinite no ombro (manguito rotador), bursite e causas de sensação de braço dormente ou formigamento irradiado.',
    contentMarkdown: `A dor no ombro que piora ao levantar o braço acima da cabeça ou ao dormir sobre o lado afetado costuma decorrer de tendinopatia do manguito rotador ou bursite subacromial. Quando acompanhada de sensação de braço dormente ou peso no membro superior, pode haver radiculopatia cervical (compressão de raiz nervosa no pescoço) ou síndrome do desfiladeiro torácico.

Evite carregar bolsas pesadas em um único ombro e inicie fisioterapia com foco em estabilização escapular. Atenção: se a sensação de braço dormente e fraqueza for de início súbito acompanhada de boca torta ou fala embolada, acione o SAMU 192 imediatamente (possível AVC).`,
    keywords: [
      'dor no ombro',
      'braco dormente',
      'ombro dolorido',
      'dormencia no braco',
      'bursite no ombro',
      'manguito rotador',
      'braco pesado',
    ],
    url: 'https://sbot.org.br/lesao-do-manguito-rotador/',
  },

  // 7. Membros Inferiores (D/E)
  {
    id: 'art-inferiores-01',
    title: 'Torci o Tornozelo e Dor no Joelho: Protocolo RICE e Recuperação Articular',
    category: 'membros_inferiores',
    somaticSystem: 'musculoesqueletico',
    author: 'Dr. Felipe Marcondes',
    authorRole: 'Ortopedista Especialista em Cirurgia do Joelho e Trauma (CRM-SP 138.650)',
    readTimeMinutes: 4,
    summary: 'Passo a passo do protocolo RICE (repouso, gelo, compressão e elevação) para quem torceu o tornozelo ou sente dor no joelho após esforço.',
    contentMarkdown: `Entorses do tornozelo e dor no joelho após pisar em falso ou praticar esportes exigem abordagem rápida para conter o edema e proteger ligamentos. O protocolo RICE consiste em:

1. **Repouso (Rest):** Evite apoiar o peso do corpo sobre a articulação nas primeiras horas.
2. **Gelo (Ice):** Aplique bolsa de gelo protegida por pano por 20 minutos, 3 a 4 vezes ao dia.
3. **Compressão (Compression):** Utilize faixa elástica sem apertar excessivamente a circulação.
4. **Elevação (Elevation):** Mantenha o membro elevado acima do nível do coração quando deitado.

Caso haja incapacidade total de apoiar o pé, deformidade articular visível ou estalo forte no momento do trauma, procure pronto-socorro para realização de radiografia preventiva.`,
    keywords: [
      'torci o tornozelo',
      'dor no joelho',
      'tornozelo torcido',
      'entorse',
      'joelho dolorido',
      'articulacao do joelho',
      'inchaço no tornozelo',
    ],
    url: 'https://sbot.org.br/entorse-de-tornozelo/',
  },
  {
    id: 'art-inferiores-02',
    title: 'Dor no Quadril e Perna Pesada: Avaliação Circulatória e Musculoesquelética',
    category: 'membros_inferiores',
    somaticSystem: 'musculoesqueletico',
    author: 'Dr. Sérgio Muniz',
    authorRole: 'Cirurgião Vascular e Angiologista (SBACV / CRM-SP 141.120)',
    readTimeMinutes: 4,
    summary: 'Como diferenciar problemas de circulação venosa que causam perna pesada de inflamações mecânicas com dor no quadril ou bacia.',
    contentMarkdown: `A sensação incômoda de perna pesada, cansaço no final do dia e inchaço nos tornozelos costuma decorrer de insuficiência venosa crônica periférica, agravada por longos períodos em pé ou sentado. Por outro lado, a dor no quadril ao caminhar ou subir escadas aponta para bursite trocantérica, tendinopatia glútea ou artrose coxofemoral.

Para melhorar o retorno venoso: repouse com as pernas elevadas por 20 minutos à noite, pratique caminhadas regulares e consulte angiologista sobre meias de compressão elástica. Inchaço agudo e dor em apenas uma perna com empastamento da panturrilha exige pronto-socorro urgente para afastar trombose venosa profunda (TVP).`,
    keywords: [
      'perna pesada',
      'dor no quadril',
      'peso nas pernas',
      'circulacao nas pernas',
      'varizes',
      'bursite no quadril',
      'pernas cansadas',
    ],
    url: 'https://drauziovarella.uol.com.br/doencas-e-sintomas/varizes/',
  },

  // 8. Sistema Neurológico
  {
    id: 'art-neuro-01',
    title: 'Tontura e Labirintite: Sintomas, Crises e Orientações de Segurança',
    category: 'neurologico',
    somaticSystem: 'neurologico',
    author: 'Dra. Vanessa Meireles',
    authorRole: 'Neurologista Clínica (CRM-SP 162.190)',
    readTimeMinutes: 5,
    summary: 'Compreendendo as causas mais frequentes de tontura, sensação de rotação (vertigem) e crises de labirintite, com cuidados para evitar quedas.',
    contentMarkdown: `Tontura é um termo genérico que engloba vertigem rotatória (sensação de que o ambiente ou o próprio corpo está girando), sensação de flutuação e desequilíbrio. A labirintite viral e a Vertigem Posicional Paroxística Benigna (VPPB) respondem pela grande maioria dos episódios agudos no sistema vestibular.

Durante uma crise: sente-se imediatamente, fixe o olhar em um ponto fixo, evite virar a cabeça com rapidez e mantenha hidratação constante. Manobras de reposicionamento otolítico (como a de Epley) realizadas por fisioterapeutas ou otorrinos resolvem a VPPB com rapidez. Se a tontura vier acompanhada de fraqueza em um lado do corpo, perda visual ou dificuldade para articular palavras, procure socorro médico imediato.`,
    keywords: [
      'tontura',
      'labirintite',
      'vertigem',
      'sensacao de que tudo gira',
      'desequilibrio',
      'instabilidade',
      'tonturas frequentes',
    ],
    url: 'https://drauziovarella.uol.com.br/doencas-e-sintomas/labirintite/',
  },
  {
    id: 'art-neuro-02',
    title: 'Formigamento e Perda de Sensibilidade: Neuropatias e Sinais de Alerta',
    category: 'neurologico',
    somaticSystem: 'neurologico',
    author: 'Dr. Augusto Vendramin',
    authorRole: 'Neurologista e Neurofisiologista (UNIFESP / CRM-SP 170.660)',
    readTimeMinutes: 5,
    summary: 'Quando o formigamento em extremidades ou perda de sensibilidade tátil decorre de compressão postural benigna vs. quando indica avaliação neurológica.',
    contentMarkdown: `O formigamento (parestesia) transitório e a perda temporária de sensibilidade após cruzar as pernas ou apoiar os cotovelos decorrem de compressão nervosa isquêmica mecânica de rápida reversão ao mudar de postura.

Entretanto, formigamento contínuo em formato de "meias e luvas" em ambas as mãos e pés pode sinalizar neuropatia periférica diabética, carência de vitamina B12 ou problemas tireoidianos. Já o formigamento unilateral com fraqueza motora súbita e desvio de rima labial exige intervenção de emergência hospitalar dentro da janela de AVC.`,
    keywords: [
      'formigamento',
      'perda de sensibilidade',
      'dormencia',
      'formigamento nas maos e pes',
      'perda de tato',
      'neuropatia',
      'choque nos membros',
    ],
    url: 'https://drauziovarella.uol.com.br/neurologia/neuropatia-periferica-doenca-dos-nervos-exige-atencao-e-controle-das-causas/',
  },

  // 9. Geniturinário / Pélvico
  {
    id: 'art-pelvico-01',
    title: 'Dor ao Urinar e Infecção de Urina: Sintomas, Prevenção e Tratamento',
    category: 'geniturinario_pelvico',
    somaticSystem: 'geniturinario',
    author: 'Dr. Gustavo Vianna',
    authorRole: 'Urologista (SBU / CRM-SP 135.780)',
    readTimeMinutes: 4,
    summary: 'Reconhecimento de ardência miccional, dor ao urinar e infecção de urina (cistite), com orientações de hidratação abundante e sinais de infecção renal.',
    contentMarkdown: `A dor ao urinar (disúria), sensação de ardência no canal uretral, vontade frequente de urinar em pequenas quantidades e urina turva são sintomas clássicos de infecção do trato urinário baixo (cistite). Em mulheres, a menor extensão uretral facilita a ascensão de bactérias do trato digestivo (como Escherichia coli).

Beba de 2 a 3 litros de água diariamente e urine sem reter por longos períodos. O uso de antibióticos apropriados requer prescrição médica com base em urocultura. Se surgirem febre alta com calafrios ou dor lombar intensa no flanco (punho-percussão dolorosa), procure pronto-socorro para avaliação de pielonefrite (infecção nos rins).`,
    keywords: [
      'dor ao urinar',
      'infeccao de urina',
      'ardencia ao urinar',
      'cistite',
      'xixi doendo',
      'infecção urinaria',
      'dor na bexiga',
      'urina turva',
    ],
    url: 'https://portaldaurologia.org.br/doencas/infeccao-urinaria/',
  },
  {
    id: 'art-pelvico-02',
    title: 'Cólica Menstrual Forte e Saúde Pélvica: Dismenorreia e Endometriose',
    category: 'geniturinario_pelvico',
    somaticSystem: 'geniturinario',
    author: 'Dra. Aline Monteiro',
    authorRole: 'Ginecologista e Obstetra (FEBRASGO / CRM-SP 158.990)',
    readTimeMinutes: 5,
    summary: 'Diretrizes sobre alívio da cólica menstrual forte, quando desconfiar de endometriose e opções de manejo da dor pélvica cíclica.',
    contentMarkdown: `A cólica menstrual (dismenorreia) decorre da produção uterina de prostaglandinas durante a descamação endometrial, gerando contrações miometriais que reduzem o fluxo sanguíneo local. Embora cólicas leves sejam comuns, uma cólica menstrual muito forte e incapacitante que impede as atividades diárias não deve ser naturalizada.

Quando a dor pélvica é severa, irradia para as costas e coxas ou vem associada a dor na relação sexual (dispareunia) ou dor intestinal durante a menstruação, deve-se investigar endometriose e adenomiose com ultrassonografia especializada e ressonância magnética. Compressas mornas no baixo ventre e acompanhamento ginecológico garantem alívio efetivo.`,
    keywords: [
      'colica menstrual forte',
      'colica menstrual',
      'colica forte',
      'dor pelvica',
      'endometriose',
      'dismenorreia',
      'dor no baixo ventre',
    ],
    url: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/e/endometriose',
  },

  // 10. Sistema Dermatológico
  {
    id: 'art-dermato-01',
    title: 'Coceira na Pele, Manchas Vermelhas e Alergias Cutâneas: O Que Fazer',
    category: 'dermatologico',
    somaticSystem: 'dermatologico',
    author: 'Dra. Patrícia Sampaio',
    authorRole: 'Dermatologista (SBD / CRM-SP 147.330)',
    readTimeMinutes: 4,
    summary: 'Cuidados para acalmar a barreira cutânea em quadros de coceira intensa na pele, placas de alergia e manchas vermelhas pruriginosas.',
    contentMarkdown: `Manchas vermelhas na pele acompanhadas de coceira intensa (prurido) podem decorrer de dermatite de contato, urticária alérgica a alimentos/medicamentos ou ressecamento extremo da barreira lipídica da pele (dermatite atópica ou xerose). Coçar excessivamente lesiona a epiderme e abre portas para infecções bacterianas secundárias.

Evite banhos muito quentes e demorados, use sabonetes neutros e aplique hidratantes emolientes sem fragrância logo após secar o corpo. Alerta máximo: se as manchas na pele vierem acompanhadas de inchaço nos lábios, olhos ou sensação de garganta fechando, busque socorro médico emergencial imediatamente (anafilaxia).`,
    keywords: [
      'coceira na pele',
      'manchas vermelhas',
      'alergia',
      'pele cocando',
      'urticaria',
      'dermatite',
      'placas vermelhas',
      'alergia na pele',
    ],
    url: 'https://www.sbd.org.br/doencas/urticaria/',
  },
  {
    id: 'art-dermato-02',
    title: 'Ferida que Não Fecha e Lesões Cutâneas: Sinais que Exigem Avaliação',
    category: 'dermatologico',
    somaticSystem: 'dermatologico',
    author: 'Dr. Carlos Resende',
    authorRole: 'Dermatologista e Cirurgião Dermatológico (SBD / CRM-SP 163.510)',
    readTimeMinutes: 4,
    summary: 'Critérios de atenção para qualquer ferida que não fecha após semanas, lesões com cicatrização lenta ou alterações pigmentares suspeitas.',
    contentMarkdown: `Toda ferida que não fecha após 3 a 4 semanas, úlceras de cicatrização difícil ou lesões crostosas que sangram facilmente com pequenos toques merecem investigação dermatológica minuciosa. Em idosos ou pessoas expostas ao sol sem proteção, carcinomas basocelulares e espinocelulares podem se iniciar com lesões peroladas ou feridas crônicas.

Além disso, lesões em membros inferiores que não cicatrizam podem sinalizar úlceras venosas ou arteriais ligadas a diabetes e má circulação. Mantenha o local limpo e protegido e agende avaliação com médico dermatologista para biópsia ou conduta adequada, evitando automedicação com pomadas tópicas aleatórias.`,
    keywords: [
      'ferida que nao fecha',
      'ferida que nao cicatriza',
      'ulcera de pele',
      'machucado que nao fecha',
      'lesao na pele',
      'ferida aberta',
      'dermatologia',
    ],
    url: 'https://www.sbd.org.br/doencas/cancer-da-pele/',
  },

  // 11. Sistema Muscular / Geral (Sistêmico)
  {
    id: 'art-muscular-01',
    title: 'Corpo Quebrado e Fadiga Física: Recuperação de Sobrecarga Sistêmica',
    category: 'muscular_geral_sistemico',
    somaticSystem: 'sistemico',
    author: 'Dr. André Cavalcanti',
    authorRole: 'Clínico Geral e Especialista em Medicina Preventiva (SBCM / CRM-SP 134.800)',
    readTimeMinutes: 4,
    summary: 'Estratégias de repouso, hidratação e nutrição celular para estados de corpo quebrado, sensação de exaustão corporal e fadiga física difusa.',
    contentMarkdown: `Acordar com a sensação de "corpo quebrado", dores musculares difusas (mialgias) e fadiga física profunda indica sobrecarga metabólica ou início de quadro infeccioso viral. Quando o organismo combate patógenos ou passa por estresse físico extenuante, citocinas inflamatórias circulantes desencadeiam sensação de fraqueza e necessidade biológica de repouso.

Priorize sono de qualidade ininterrupto, beba líquidos em abundância e garanta aporte de nutrientes e sais minerais. Evite esforços pesados até que a musculatura recupere seu tônus normal. Se a dor e a fadiga persistirem por meses sem causa aparente, investigue alterações reumatológicas e carências vitamínicas.`,
    keywords: [
      'corpo quebrado',
      'fadiga fisica',
      'dor no corpo',
      'cansaco excessivo',
      'corpo dolorido',
      'exaustao corporal',
      'fadiga muscular',
      'sensacao de peso no corpo',
    ],
    url: 'https://drauziovarella.uol.com.br/drauzio/dores-cronicas-artigo/',
  },
  {
    id: 'art-muscular-02',
    title: 'Febre, Calafrios e Dor no Corpo Todo: Triagem de Infecções Virais',
    category: 'muscular_geral_sistemico',
    somaticSystem: 'sistemico',
    author: 'Dra. Simone Lages',
    authorRole: 'Infectologista (SBI / CRM-SP 148.230)',
    readTimeMinutes: 4,
    summary: 'Como monitorar picos de febre, calafrios e dor no corpo todo típicos de viroses, identificando quando o quadro requer pronto-atendimento.',
    contentMarkdown: `O conjunto de febre, calafrios e dor no corpo todo é a resposta imune clássica contra invasores biológicos, comum em viroses sazonais como gripe (influenza), dengue e arboviroses. O calafrio ocorre enquanto o hipotálamo ajusta a temperatura corporal para um nível mais elevado para dificultar a replicação viral.

O monitoramento com termômetro é fundamental: registre as temperaturas e use antitérmicos conforme orientação médica. Beba muita água e soro caseiro. Em áreas endêmicas de dengue, fique atento a sinais de alarme entre o 3º e 5º dia: dor abdominal intensa e contínua, vômitos frequentes e tontura ao se levantar justificam atendimento hospitalar imediato.`,
    keywords: [
      'febre',
      'calafrios',
      'dor no corpo todo',
      'febre e dor no corpo',
      'dor no corpo inteiro',
      'calafrio',
      'sindrome gripal',
      'mal-estar geral',
    ],
    url: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/d/dengue',
  },

  // 12. Endócrino / Metabólico
  {
    id: 'art-endocrino-01',
    title: 'Sede Excessiva e Alterações Metabólicas: Sinais de Alerta Glicêmico',
    category: 'endocrino_metabolico',
    somaticSystem: 'endocrino',
    author: 'Dra. Renata Borges',
    authorRole: 'Endocrinologista e Metabologista (SBEM / CRM-SP 151.040)',
    readTimeMinutes: 5,
    summary: 'Por que a sede excessiva associada a aumento na frequência urinária pode sinalizar distúrbios de glicemia e resistência insulínica.',
    contentMarkdown: `Sentir sede excessiva (polidipsia) constante, acompanhada de boca seca e necessidade de urinar muitas vezes ao dia e à noite (poliúria), é um dos principais sinais de alerta para elevações descontroladas da glicemia, como no diabetes mellitus. Quando a taxa de açúcar no sangue ultrapassa o limiar de filtração renal, a glicose é eliminada na urina carregando grandes volumes de água com ela.

Não ignore a sede persistente. Um simples exame de sangue em jejum (glicemia e hemoglobina glicada) é capaz de diagnosticar precocemente alterações metabólicas. A intervenção em fases iniciais com ajustes nutricionais e atividade física previne complicações cardiovasculares futuras.`,
    keywords: [
      'sede excessiva',
      'muita sede',
      'boca seca constante',
      'urinar muito',
      'diabetes',
      'glicemia alta',
      'desidratacao metabólica',
      'metabolico',
    ],
    url: 'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/d/diabetes',
  },
  {
    id: 'art-endocrino-02',
    title: 'Perdi Muito Peso Sem Motivo e Calores Súbitos: Investigação Hormonal',
    category: 'endocrino_metabolico',
    somaticSystem: 'endocrino',
    author: 'Dr. Paulo Ximenes',
    authorRole: 'Endocrinologista Clínico (SBEM / CRM-SP 167.850)',
    readTimeMinutes: 5,
    summary: 'Explicação médica para perda de peso inexplicada e episódios de calores súbitos (fogachos), abordando função da tireoide e regulação neuroendócrina.',
    contentMarkdown: `Afirmações como "perdi muito peso sem motivo" ou notar que as roupas ficaram folgadas sem mudança na dieta ou nos treinos nunca devem ser ignoradas. Uma perda de mais de 5% do peso corporal em seis meses exige investigação endocrinológica e clínica completa.

Quando a perda de peso vem associada a calores súbitos, sensação de calor excessivo constante, tremores finos nas mãos e taquicardia, pode haver hipertireoidismo (hiperfunção da glândula tireoide). Em mulheres entre 45 e 55 anos, ondas de calor súbitas também caracterizam o climatério/menopausa. Dosagens hormonais de TSH, T4 livre e esteroides sexuais esclarecem o diagnóstico com precisão.`,
    keywords: [
      'perdi muito peso sem motivo',
      'calores subitos',
      'perda de peso involuntaria',
      'emagrecimento rapido',
      'ondas de calor',
      'suor repentino',
      'tireoide',
      'hormonal',
    ],
    url: 'https://www.endocrino.org.br/hipertireoidismo/',
  },

  // ==========================================
  // CUIDADO GERAL / BEM-ESTAR PREVENTIVO
  // ==========================================
  {
    id: 'art-geral-01',
    title: 'Guia de Auto-Cuidado Preventivo e Bem-Estar Diário',
    category: 'geral',
    somaticSystem: 'geral',
    author: 'Dr. André Cavalcanti',
    authorRole: 'Clínico Geral e Medicina Preventiva (SBCM / CRM-SP 134.800)',
    readTimeMinutes: 3,
    summary: 'Práticas fundamentais de hidratação, sono adequado e monitoramento preventivo de sinais e sintomas para saúde integral.',
    contentMarkdown: `A saúde preventiva é construída por pequenos hábitos mantidos com consistência: ingestão diária de água proporcional ao peso corporal (cerca de 35ml por quilo), alimentação diversificada rica em vegetais frescos, sono regular de 7 a 8 horas e pausas de alívio de estresse durante a rotina.

Registrar seus sintomas diariamente e realizar um check-up clínico e laboratorial anual permite identificar pequenas alterações metabólicas ou hormonais antes que elas evoluam para doenças crônicas. O cuidado preventivo é o melhor investimento na sua longevidade ativa.`,
    keywords: [
      'autocuidado',
      'prevencao',
      'check-up',
      'hidratacao',
      'saude integral',
      'bem-estar',
      'estilo de vida',
    ],
    url: 'https://www.paho.org/pt/topicos/curso-vida-saudavel',
  },
];
