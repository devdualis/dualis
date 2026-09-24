# Manual de Uso da Marca Dualis — Diretrizes de Engenharia e Design (v1.0)

Este documento consolida as diretrizes do **Manual de Uso da Marca Dualis (Versão 1.0 — Setembro de 2026)** para a equipe de desenvolvimento e design do aplicativo móvel **DualisCheckUp**.

---

## 1. Objetivo e Composição da Marca

A marca **Dualis** é composta por três elementos fundamentais em composição única:
1. **Símbolo**: Forma contínua e entrelaçada, inspirada no conceito de infinito, construída com gradiente nos tons de azul (`#0B83C9`), ciano (`#26B7D7`) e verde (`#66BE71`).
2. **Logotipo**: Nome “Dualis” em azul-marinho institucional (`#0E3E6C`).
3. **Tagline**: *"continuous check up"*, em azul-claro (`#2B9ED0`) com espaçamento expandido entre letras.

A assinatura visual comunica continuidade, conexão, acompanhamento e evolução preventiva na saúde do usuário.

---

## 2. Versões Autorizadas

### 2.1 Versão Horizontal (Principal)
- **Estrutura**: Símbolo à esquerda, logotipo "Dualis" à direita e tagline *"continuous check up"* abaixo do nome.
- **Uso Recomendado**: Cabeçalhos de tela (`AppBar`), barras de navegação superior, relatórios e telas em formato widescreen.
- **Implementação**:
  ```dart
  DualisLogo(
    variant: DualisLogoVariant.horizontal,
    width: 160, // Mínimo digital: 150 px
  )
  ```

### 2.2 Versão Vertical (Secundária)
- **Estrutura**: Símbolo centralizado no topo, logotipo "Dualis" centralizado abaixo, e tagline centralizada na base.
- **Uso Recomendado**: Telas de abertura/login, splash screens, banners verticais, totens ou quando a leitura horizontal estiver comprometida.
- **Implementação**:
  ```dart
  DualisLogo(
    variant: DualisLogoVariant.vertical,
    width: 160, // Mínimo digital: 120 px
    isHighVisibility: true,
  )
  ```

### 2.3 Símbolo Isolado
- **Estrutura**: Apenas a forma contínua do infinito.
- **Uso Recomendado**: Ícone de aplicativo (`app_icon.png`), avatares, favicon web e espaços ultra-reduzidos.
- **Implementação**:
  ```dart
  DualisLogo(
    variant: DualisLogoVariant.symbolOnly,
    width: 40,
  )
  // ou diretamente
  DualisEmblem(size: 40)
  ```

---

## 3. Área de Proteção

- **Regra Geral**: Deve ser preservada uma área livre ao redor do logotipo. Nenhum texto, botão, ícone, borda, linha ou foto deve invadir esse espaço.
- **Distância Mínima**: Equivalente à altura da letra minúscula **“a”** da palavra "Dualis" (aproximadamente 6% a 8% da largura renderizada).
- **Aplicações de Alta Visibilidade (Hero/Splash/Login)**: Recomenda-se aplicar pelo menos **duas vezes essa medida (\(2X\))**.
- **Propriedade no Flutter**:
  ```dart
  DualisLogo(
    withProtectionArea: true,
    isHighVisibility: true, // Aplica margem 2X
  )
  ```

---

## 4. Tamanhos Mínimos

Para garantir a legibilidade da tagline, devem ser respeitados os seguintes limites:

| Aplicação | Largura Mínima Recomendada | Comportamento Abaixo do Mínimo |
|---|---|---|
| **Uso digital horizontal** | **150 px** | Oculta a tagline e usa versão sem tagline (`dualis_logo_horizontal_notag.png`) |
| **Uso digital vertical** | **120 px** | Oculta a tagline e usa versão sem tagline (`dualis_logo_vertical_notag.png`) |
| **Uso impresso horizontal** | 35 mm | Requer versão institucional sem tagline |
| **Uso impresso vertical** | 28 mm | Requer versão institucional sem tagline |

> **Nota Técnica**: No componente `DualisLogo`, essa degradação para a versão sem tagline ocorre automaticamente caso `width < 150` (horizontal) ou `width < 120` (vertical), sem nunca esticar ou recortar a marca.

---

## 5. Cores Oficiais da Marca

| Elemento | Nome de Referência | HEX | Constante em `AppColors` |
|---|---|---|---|
| **Nome "Dualis"** | Azul-marinho | `#0E3E6C` | `AppColors.dualisNavy` |
| **Símbolo — azul** | Azul | `#0B83C9` | `AppColors.dualisSymbolBlue` |
| **Símbolo — ciano** | Ciano | `#26B7D7` | `AppColors.dualisSymbolCyan` |
| **Símbolo — verde** | Verde | `#66BE71` | `AppColors.dualisSymbolGreen` |
| **Tagline** | Azul-claro | `#2B9ED0` | `AppColors.dualisTagline` |

### Fundos Recomendados:
- **Branco**: `#FFFFFF` (Versão institucional preferencial colorida).
- **Cinza muito claro**: `#F8FAFC` (`AppColors.brandBgLightGray`).
- **Azul muito claro**: `#F0F7FB` (`AppColors.brandBgLightBlue`), preservando contraste.
- **Fundo azul-marinho escuro**: `#0E3E6C`, exclusivamente com versão branca/reversa aprovada.

---

## 6. Versões Monocromáticas e Reversas

A ordem de preferência de reprodução é:
1. **Versão colorida sobre fundo claro / branco**: Padrão institucional.
2. **Versão monocromática azul-marinho (`#0E3E6C`)**: Para impressões monocromáticas e peças de apoio claras (`DualisLogoColorScheme.monochromeNavy`).
3. **Versão branca reversa (`#FFFFFF`)**: Para modo escuro (`ThemeData.dark()`) ou fundos azul-marinho escuros (`DualisLogoColorScheme.whiteReversed`).

---

## 7. Tipografia de Apoio

A família tipográfica oficial adotada para o ecossistema é **Inter**:
- **Títulos e Destaques**: *Inter SemiBold* (peso `600`), cor institucional `AppColors.dualisNavy`.
- **Subtítulos**: *Inter Medium* (peso `500`).
- **Texto Corrido**: *Inter Regular* (peso `400`).
- **Texto Técnico**: *Inter Regular*.

O nome "Dualis" no logotipo **nunca** deve ser redigitado ou substituído por fonte aproximada; deve sempre ser utilizado o ativo gráfico oficial.

---

## 8. Usos Incorretos (O que NUNCA fazer)

- ❌ **Nunca** alterar as cores do símbolo, do logotipo ou da tagline.
- ❌ **Nunca** esticar, comprimir, inclinar, girar ou distorcer a proporção da marca.
- ❌ **Nunca** separar o símbolo do nome em telas comuns institucionais.
- ❌ **Nunca** apagar, traduzir, reescrever ou reposicionar manualmente a tagline.
- ❌ **Nunca** aplicar sombras, contornos, brilhos, relevos, reflexos ou gradientes artificiais.
- ❌ **Nunca** usar o logotipo sobre fundos poluídos ou sem contraste mínimo de acessibilidade.

---

## 9. Canais Digitais e Acessibilidade

- O logotipo exibido no `AppBar` do aplicativo possui largura de **160 px** (respeitando o mínimo de 150 px).
- O toque no logotipo do cabeçalho direciona o usuário para a tela inicial / aba Home.
- Todos os logos contam com a etiqueta de acessibilidade para leitores de tela:
  `Semantics(label: "Dualis — continuous check up")`.

---

## 10. Governança da Biblioteca de Ativos

Os arquivos oficiais mestres estão organizados em `mobile/lib/assets/`:
- `lib/assets/brand/dualis_logo_horizontal.png`: Logotipo horizontal colorido com tagline.
- `lib/assets/brand/dualis_logo_vertical.png`: Logotipo vertical colorido com tagline.
- `lib/assets/brand/dualis_logo_horizontal_notag.png`: Logotipo horizontal sem tagline.
- `lib/assets/brand/dualis_logo_vertical_notag.png`: Logotipo vertical sem tagline.
- `lib/assets/brand/dualis_logo_symbol.png`: Símbolo contínuo isolado em alta resolução.
- `lib/assets/brand/dualis_logo_monochrome_navy.png`: Versão monocromática azul-marinho.
- `lib/assets/brand/dualis_logo_reverse_white.png`: Versão reversa branca horizontal.
- `lib/assets/brand/dualis_logo_vertical_reverse_white.png`: Versão reversa branca vertical.
- `lib/assets/icon/app_icon.png`: Ícone de aplicativo 1024x1024 com símbolo infinito.
- `lib/assets/icon/app_icon_foreground.png`: Foreground transparente adaptativo 1024x1024.
