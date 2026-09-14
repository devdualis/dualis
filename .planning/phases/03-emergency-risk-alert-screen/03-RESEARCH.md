# Phase 3 Research: Emergency Risk Alert Screen (Screen 8 / RF-006)

**Phase:** 3  
**Padded Phase:** 03  
**Phase Name:** Emergency Risk Alert Screen (Screen 8 / RF-006)  
**Requirements Covered:** EMRG-01, EMRG-02, EMRG-03, I18N-01  
**Target Milestone:** Vertical MVP — Safety Core & Module 2 Foundation  
**Researched:** 2026-09-14  
**Confidence:** HIGH  

---

## Executive Summary

Phase 3 delivers the clinical life-safety backbone of **DualisCheckUp**: **Screen 8 (Emergency Risk Alert Screen - RF-006)**. Prioritizing this phase before Screen 4 (5-Step Triage Wizard) and Screen 3 (Home & Unified Check-In) is a deliberate architectural and clinical safety mandate: an intelligent digital health triage platform must possess an immutable, tested, zero-failure emergency escape and redirection mechanism *before* exposing symptom questioning to users.

This phase guarantees that any high-severity symptom (Level 4 or 5) associated with critical red-flag systems (cardiovascular, respiratory, neurological, acute suicidal or psychotic crises) immediately halts further questionnaire navigation, drops all in-flight triage draft state (`autoDispose`), and locks the user into an unyielding, high-contrast Red Emergency Screen (`#D32F2F`) protected by `PopScope(canPop: false)`.

Key pillars established in this phase:
1. **Deterministic Red-Flag Interceptor Engine (EMRG-01)**: Clinical criteria based on Manchester Triage System (MTS Red/Orange) and Emergency Severity Index (ESI Level 1-2). Executes in <1ms client-side with zero network dependency, utilizing structural thresholds (Level 4/5 on critical organs) and a trilingual regex keyword fast-gate.
2. **Emergency State Machine & Navigation Gating (EMRG-01, EMRG-02)**: Riverpod-driven `EmergencyStateNotifier` and GoRouter route (`/emergency`) guarded with Flutter 3.29 `PopScope(canPop: false)`. Back gestures (Android hardware/system back, iOS swipe-to-pop) are intercepted with a high-urgency medical risk confirmation dialog.
3. **Screen 8 UI Architecture (EMRG-02)**: Full-screen Material 3 Red Emergency View (`#D32F2F`) with WCAG 2.1 AA compliant contrast (>4.8:1 for white-on-crimson, >7:1 for dark-on-pink cards). Built inside a `SingleChildScrollView` to eliminate `RenderFlex` overflow risks on small screens or high-accessibility font scalings. Features dynamic context badges identifying the specific clinical trigger.
4. **1-Tap Telephony Dispatch & External Intents (EMRG-03)**: Integration of `url_launcher: ^6.3.2` for instant 1-tap dialing to Brazilian Emergency Services (SAMU `192`, Bombeiros `193`, CVV `188`, Polícia `190`) and external geo/maps intent (`geo:0,0?q=pronto+socorro`). Includes explicit manifest declarations (`<queries>` in `AndroidManifest.xml` and `LSApplicationQueriesSchemes` in `Info.plist`) plus a dedicated fallback modal for telephony-absent devices (Wi-Fi-only tablets, simulators) with one-tap clipboard copy.
5. **Trilingual Internationalization (I18N-01)**: Complete, localized copy across Brazilian Portuguese (`pt-BR`), Spanish (`es`), and English (`en`) across all titles, trigger badges, physical/emotional action steps, action buttons, exit confirmation dialogs, and dialer fallbacks.
6. **Asynchronous LGPD Audit Telemetry**: A non-blocking, fire-and-forget client report to `POST /v1/triage/emergency-event` logging user ID, category, severity level, source vertical, action taken, and timestamp into an RLS-isolated PostgreSQL audit table.

---

## 1. Deterministic Red-Flag Interceptor Engine (EMRG-01)

### 1.1 Clinical Triage Foundations (MTS & ESI Protocols)

Modern digital health guidelines (Anvisa RDC 657/2022, CFM Res. 2.314/2022, FDA CDSS) require that symptom-checking platforms operate as risk stratification aids rather than autonomous diagnostic engines. When evaluating clinical severity, the application adopts criteria from the two world standards in emergency department triage:

1. **Manchester Triage System (MTS)**:
   - *Red Category (Immediate / 0 minutes)*: Airway compromise, inadequate breathing, exsanguinating hemorrhage, unresponsiveness / convulsion.
   - *Orange Category (Very Urgent / 10 minutes)*: Cardiac chest pain, severe dyspnea, acute neurological deficit (facial droop, hemiparesis, sudden aphasia), sudden onset "thunderclap" headache, stridor, severe suicidal agitation/crisis.
2. **Emergency Severity Index (ESI)**:
   - *ESI Level 1 (Resuscitation)*: Imminent life-threat, acute respiratory arrest, unresponsive patient.
   - *ESI Level 2 (Emergent / High Risk)*: High-risk situation, acute severe chest pain, severe acute pain/distress (rating 7–10/10 or unbearable), suicidal ideation with active intent or plan, altered mental status.

DualisCheckUp adopts a standardized 1–5 Intensity Scale across its 12 anatomical systems and 7 psycho-emotional dimensions:
- **Level 1**: Leve / Quase imperceptível (Mild)
- **Level 2**: Leve a moderado (Mild-to-moderate)
- **Level 3**: Moderado (Moderate)
- **Level 4**: Forte / Intenso (Severe / MTS Orange / ESI 2)
- **Level 5**: Insuportável / Crítico (Critical / MTS Red / ESI 1)

### 1.2 Exhaustive Red-Flag Taxonomy

The deterministic engine monitors complaints across two major verticals:

#### A. Physical Vertical (12 Anatomical Systems)

| Anatomical System (`anatomicalSystem`) | Critical Red-Flag Clinical Presentation | Triggered Severity | Category Code | Recommended Primary Service |
|---|---|---|---|---|
| **Cardiovascular / Tórax** (`cardiovascular_chest`) | Crushing retrosternal/substernal chest pain/pressure; pain radiating to left arm, neck, jaw, or shoulder blades; tightness with cold sweats (diaphoresis); severe acute palpitations with presyncope. | Level 4 or 5 | `chestPain` | SAMU (`192`) |
| **Respiratório** (`respiratory`) | Acute severe dyspnea; choking; inability to speak full sentences without gasping; stridor (high-pitched inspiratory sound); cyanosis of lips/fingertips; acute severe asthma flare. | Level 4 or 5 | `respiratoryDistress` | SAMU (`192`) |
| **Neurológico** (`neurological`) | Cincinnati Stroke Scale signs: sudden facial droop (boca torta), unilateral arm/leg weakness (hemiparesia), acute speech slurring or aphasia (fala arrastada); sudden syncope (desmaio / perda de consciência); sudden focal numbness. | Level 4 or 5 | `neurologicalStroke` | SAMU (`192`) |
| **Neurológico / Cabeça** (`neurological` / `head_neck`) | Thunderclap headache ("pior dor de cabeça da vida" reaching maximum intensity within seconds, indicating possible subarachnoid hemorrhage / aneurysm rupture). | Level 4 or 5 | `thunderclapHeadache` | SAMU (`192`) |
| **Cabeça e Pescoço** (`head_neck`) | Acute airway compromise; angioedema (swelling of tongue, lips, uvula); severe anaphylaxis throat constriction. | Level 4 or 5 | `anaphylaxisAirway` | SAMU (`192`) |
| **Geral / Sistêmico** (`systemic_general`) | Massive uncontrolled hemorrhage; clinical shock symptoms (profound dizziness, cold/clammy skin, grey pallor, confusion); acute anaphylactic collapse. | Level 4 or 5 | `massiveHemorrhage` | SAMU (`192`) / Bombeiros (`193`) |
| **Gastrointestinal / Abdômen** (`gastrointestinal_abdomen`) | Acute surgical abdomen; unbearable peritoneal rigidity/guarding; massive hematemesis (vomiting blood) or melena with dizziness. | Level 5 | `generalCriticalIntensity` | SAMU (`192`) |
| **Qualquer Sistema Físico** (Outros sistemas) | Intensidade Nível 5 ("Insuportável / Incapacitante") relatada pelo paciente. | Level 5 | `generalCriticalIntensity` | SAMU (`192`) |

#### B. Psycho-Emotional Vertical (7 Dimensions)

| Dimension (`emotionalDimension`) | Critical Red-Flag Clinical Presentation | Triggered Severity | Category Code | Recommended Primary Service |
|---|---|---|---|---|
| **Depressiva / Desânimo** (`depressive_hopelessness`) | Acute suicidal ideation; explicit intent to self-harm; desire to end one's life; feeling that "death is the only way out"; crisis despair. | Level 4 or 5 (or keyword) | `suicidalCrisis` | CVV (`188`) & SAMU (`192`) |
| **Ansiosa / Agitação** (`anxious_agitation`) | Severe acute panic collapse; extreme hyperventilation tetany with intense feeling of asphyxiation and impending doom; severe acute dissociative state. | Level 4 or 5 | `anxiousPanicCollapse` | CVV (`188`) & SAMU (`192`) |
| **Estresse / Burnout** (`stress_burnout`) | Acute psychotic agitation; violent delirium; acute loss of contact with reality; threat to self or others. | Level 4 or 5 | `severePsychosisDelirium` | SAMU (`192`) / CVV (`188`) |

### 1.3 Deterministic Rule Engine Design

The engine executes in **under 1 millisecond** client-side, completely offline, with **zero LLM dependency** and **zero network overhead**.

```
                           [User Input Flow]
                                  │
         ┌────────────────────────┴────────────────────────┐
         ▼                                                 ▼
[Step 1: Lay Text Input]                       [Step 3: Intensity Selection]
         │                                                 │
         ▼                                                 ▼
[Keyword/Regex Fast-Gate]                       [Structural Rule Gate]
 - Suicidal intent patterns?                     - Intensity >= 4 on Critical Organs?
 - Stroke/Cincinnati patterns?                   - Intensity == 5 on Any Organ?
 - Crushing chest pain patterns?                 - Intensity >= 4 on Emotional Crisis?
 - Airway/Asphyxia patterns?                               │
         │                                                 │
         └────────────────────────┬────────────────────────┘
                                  │
                        Matches Emergency?
                                  │
                 ┌────────────────┴────────────────┐
                 ▼ YES                             ▼ NO
        [HALT QUESTIONING]                 [CONTINUE TRIAGE]
        [Purge Triage Draft]               [Proceed to next step]
        [Route to /emergency]
```

#### Rule 1: Structural Categorical Gate
Evaluated when intensity is selected (Step 3) or when a high-risk category is chosen:
- **Condition 1**: `intensity >= 4` AND `anatomicalSystem` $\in$ `{ cardiovascular_chest, respiratory, neurological, head_neck }`.
- **Condition 2**: `intensity == 5` on ANY anatomical system.
- **Condition 3**: `intensity >= 4` AND `emotionalDimension` $\in$ `{ depressive_hopelessness, anxious_agitation, stress_burnout }` with crisis flags.

#### Rule 2: Semantic Keyword/Regex Fast-Gate (Trilingual)
Evaluated immediately upon raw text entry in Step 1 (e.g. conversational search or lay description) across Brazilian Portuguese, Spanish, and English. If a high-lethality phrase is detected, the engine halts triage **immediately without requiring the user to answer questions 2, 3, 4, or 5**.

```dart
// Core regex definitions
final suicideRegex = RegExp(
  r'(quero|vou)\s+(me\s+)?(matar|morrer)|'
  r'(tirar|acabar\s+com)\s+(a\s+)?(minha\s+)?vida|'
  r'suic[ií]d|'
  r'(quiero|voy\s+a)\s+(morir|suicidar)|'
  r'quitarme\s+la\s+vida|'
  r'(want\s+to|going\s+to)\s+(die|kill\s+myself)|'
  r'end\s+my\s+life',
  caseSensitive: false,
);

final strokeRegex = RegExp(
  r'boca\s+torta|rosto\s+torto|paralisia\s+facial|'
  r'perda\s+de\s+for[çc]a\s+no\s+bra[çc]o|'
  r'fala\s+arrastada|n[ãa]o\s+consigo\s+falar|'
  r'cara\s+torcida|dificultad\s+para\s+hablar|'
  r'facial\s+droop|slurred\s+speech|arm\s+weakness|hemipares',
  caseSensitive: false,
);

final chestPainRegex = RegExp(
  r'(dor|aperto|press[ãa]o)\s+no\s+peito\s+(irradiando|forte|insuport[aá]vel)|'
  r'peito\s+queimando.*(bra[çc]o|mand[ií]bula)|'
  r'dolor\s+en\s+el\s+pecho\s+irradiando|'
  r'crushing\s+chest\s+pain',
  caseSensitive: false,
);

final airwayRegex = RegExp(
  r'n[ãa]o\s+consigo\s+respirar|falta\s+de\s+ar\s+sufocante|garganta\s+fechando|'
  r'no\s+puedo\s+respirar|garganta\s+cerrada|asfixia|'
  r'can(\x27|not|\s+not)\s+breathe|throat\s+closing|suffocating|stridor',
  caseSensitive: false,
);

final thunderclapRegex = RegExp(
  r'pior\s+dor\s+de\s+cabe[çc]a\s+da\s+(minha\s+)?vida|'
  r'dor\s+s[uú]bita\s+explosiva\s+na\s+cabe[çc]a|'
  r'peor\s+dolor\s+de\s+cabeza\s+de\s+mi\s+vida|'
  r'worst\s+headache\s+of\s+my\s+life|thunderclap\s+headache',
  caseSensitive: false,
);
```

---

## 2. Emergency State Machine & Navigation Gating (EMRG-01, EMRG-02)

### 2.1 State Architecture (Riverpod)

The emergency state is modeled with explicit immutability in `mobile/lib/features/emergency/`:

```
mobile/lib/features/emergency/
├── domain/
│   ├── emergency_context.dart       # Trigger category, severity, source vertical, timestamp
│   └── emergency_trigger_type.dart  # Enum of categories (chestPain, stroke, suicide, etc.)
├── presentation/
│   ├── controllers/
│   │   └── emergency_controller.dart # Notifier managing emergency state & telemetry
│   ├── screens/
│   │   └── emergency_screen.dart     # Screen 8: Full-screen red modal with PopScope
│   └── widgets/
│       ├── emergency_action_button.dart   # 1-tap dialer button (SAMU, CVV, Bombeiros)
│       ├── emergency_instructions_card.dart # Tailored clinical advice card
│       ├── emergency_badge.dart           # High-visibility trigger category pill
│       └── telephony_fallback_dialog.dart # Modal for tablets / no-dialer devices
└── services/
    ├── telephony_service.dart        # url_launcher wrapper with fallback checks
    └── emergency_audit_service.dart  # Asynchronous backend telemetry reporter
```

#### State Definitions

```dart
enum EmergencyTriggerCategory {
  chestPain,
  respiratoryDistress,
  neurologicalStroke,
  thunderclapHeadache,
  anaphylaxisAirway,
  massiveHemorrhage,
  suicidalCrisis,
  anxiousPanicCollapse,
  severePsychosisDelirium,
  generalCriticalIntensity,
}

enum EmergencyServiceType {
  samu192,
  cvv188,
  bombeiros193,
  policia190,
  mapsEmergencyRoom,
}

class EmergencyContext {
  final EmergencyTriggerCategory category;
  final int severityLevel; // 4 or 5
  final bool isEmotional;
  final DateTime detectedAt;
  final String? rawTriggerPhrase;

  const EmergencyContext({
    required this.category,
    required this.severityLevel,
    required this.isEmotional,
    required this.detectedAt,
    this.rawTriggerPhrase,
  });

  EmergencyServiceType get primaryService =>
      isEmotional ? EmergencyServiceType.cvv188 : EmergencyServiceType.samu192;
}
```

### 2.2 GoRouter Integration & Route Protection

In `mobile/lib/core/router/route_paths.dart`:
```dart
class RoutePaths {
  static const String onboarding = '/onboarding';
  static const String register = '/register';
  static const String login = '/login';
  static const String home = '/home';
  static const String emergency = '/emergency'; // Screen 8 (RF-006)
}
```

In `mobile/lib/core/router/app_router.dart`:
```dart
GoRoute(
  path: RoutePaths.emergency,
  name: 'emergency',
  builder: (context, state) {
    final emergencyContext = state.extra as EmergencyContext? ??
        EmergencyContext(
          category: EmergencyTriggerCategory.generalCriticalIntensity,
          severityLevel: 5,
          isEmotional: false,
          detectedAt: DateTime.now(),
        );
    return EmergencyScreen(emergencyContext: emergencyContext);
  },
),
```

### 2.3 `PopScope(canPop: false)` Back-Gesture Locking Mechanism

To prevent users from inadvertently dismissing the emergency screen via Android hardware back buttons, edge swipe navigation gestures, or iOS interactive pop gestures, the `EmergencyScreen` wraps its view in a strict `PopScope`:

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    
    // User attempted to pop or swipe back.
    // Intercept and prompt with mandatory clinical warning dialog.
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const EmergencyExitConfirmationDialog(),
    );

    if (shouldExit == true && context.mounted) {
      // Discard in-flight triage session state
      ref.read(emergencyControllerProvider.notifier).recordExitConfirmed();
      // Safely navigate back to home screen
      context.go(RoutePaths.home);
    }
  },
  child: Scaffold(...),
)
```

#### Exit Confirmation Dialog Invariants
1. **Barrier Dismissible = false**: The user cannot tap outside the dialog to dismiss it.
2. **Safe Default**: The primary button is `[Permanecer na Emergência]` (`isDefaultAction: true`).
3. **Destructive Acknowledgment**: The secondary button is `[Entendi os Riscos / Sair]`, styled with muted/destructive styling to discourage accidental exit.
4. **State Teardown**: Exiting completely clears the active triage state machine so no stale emergency or survey answers persist in memory.

---

## 3. Screen 8 UI Architecture (EMRG-02)

### 3.1 Material 3 Emergency Palette & Accessibility

- **Base Emergency Crimson**: `AppColors.emergencyCrimson` (`Color(0xFFD32F2F)`).
- **Background Accent**: Deep Emergency Maroon (`Color(0xFFB71C1C)`).
- **Surface Contrast Card**: Light Red Surface (`Color(0xFFFFEBEE)`).
- **Text On Red**: High-contrast Pure White (`#FFFFFF`). Contrast ratio: **4.8:1** (meets WCAG 2.1 AA requirement of 4.5:1).
- **Text On Surface Card**: Deep Crimson Charcoal (`Color(0xFF5A0C0C)`). Contrast ratio: **> 7.5:1** (meets WCAG AAA standards).

### 3.2 View Layout Architecture

```
┌────────────────────────────────────────────────────────┐
│ SafeArea (Full Bleed Background: #D32F2F)              │
│ ┌────────────────────────────────────────────────────┐ │
│ │ SingleChildScrollView (BouncingScrollPhysics)      │ │
│ │                                                    │ │
│ │   [ Pulsing White Emergency Icon Badge ]           │ │
│ │                                                    │ │
│ │   "ALERTA DE RISCO IMEDIATO"                       │ │
│ │   "Sintomas de gravidade identificados."           │ │
│ │                                                    │ │
│ │   [ 🚨 Badge: Dor Torácica Crítica (Nível 5) ]     │ │
│ │                                                    │ │
│ │   ┌──────────────────────────────────────────────┐ │ │
│ │   │ Instructions Card (Surface: #FFEBEE)         │ │ │
│ │   │ 1. Interrompa qualquer esforço imediatamente │ │ │
│ │   │ 2. Não dirija até o hospital por conta...    │ │ │
│ │   │ 3. Afrouxe roupas apertadas e mantenha...    │ │ │
│ │   └──────────────────────────────────────────────┘ │ │
│ │                                                    │ │
│ │   [ 📞 LIGAR SAMU (192) ]   (Height: 58, White/Red) │ │
│ │                                                    │ │
│ │   [ 🚒 LIGAR BOMBEIROS (193) ] (Muted Button)      │ │
│ │                                                    │ │
│ │   [ 🏥 BUSCAR PRONTO-SOCORRO MAIS PRÓXIMO ]        │ │
│ │                                                    │ │
│ │   "Ao ligar, informe seu endereço com calma."      │ │
│ │                                                    │ │
│ │   [ Voltar ao Início (Não recomendado) ]           │ │
│ │                                                    │ │
│ └────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

### 3.3 Dynamic Clinical Content Switching (Physical vs. Emotional)

Screen 8 dynamically renders different instructions, badges, and primary buttons based on `emergencyContext.isEmotional`:

#### When `isEmotional == false` (Physical Triggers):
- **Badge**: "🚨 Dor Torácica Crítica" / "🚨 Dificuldade Respiratória Aguda" / "🚨 Suspeita de AVC"
- **Instructions Card**:
  1. *Repouso Imediato*: Interrompa qualquer esforço físico e permaneça em repouso sentado ou com a cabeça elevada.
  2. *Não Dirija*: Não tente dirigir até o hospital. Acione o SAMU pelo 192 ou solicite ajuda imediata a quem estiver com você.
  3. *Conforto*: Afrouxe roupas apertadas e tente manter a respiração estável enquanto o atendimento chega.
- **Primary Dial Button**: `[📞 Ligar SAMU (192)]`
- **Secondary Dial Button**: `[🚒 Ligar Bombeiros (193)]`
- **Location Intent Button**: `[🏥 Buscar Pronto-Socorro Mais Próximo]`

#### When `isEmotional == true` (Psycho-Emotional Triggers):
- **Badge**: "🚨 Apoio Emocional Imediato / Risco à Vida"
- **Instructions Card**:
  1. *Você Não Está Sozinho(a)*: Existem profissionais prontos para acolher você com respeito, total sigilo e sem julgamentos agora mesmo.
  2. *Apoio 24 Horas Gratuito*: Ligue para o CVV no número 188. O atendimento funciona em todo o território nacional.
  3. *Segurança Imediata*: Se você sentir que não consegue garantir sua própria segurança neste momento, acione o SAMU (192) ou procure a UPA/Pronto-Socorro mais próximo acompanhado(a).
- **Primary Dial Button**: `[💚 Ligar CVV - Apoio Emocional (188)]`
- **Secondary Dial Button**: `[📞 Ligar SAMU (192)]`
- **Location Intent Button**: `[🏥 Buscar UPA / Pronto-Socorro Mais Próximo]`

---

## 4. 1-Tap Telephony Dispatch & External Intent Handling (EMRG-03)

### 4.1 `url_launcher` Implementation Details

Dependency added to `mobile/pubspec.yaml`:
```yaml
dependencies:
  url_launcher: ^6.3.2
```

In `mobile/lib/features/emergency/services/telephony_service.dart`:
```dart
import 'package:url_launcher/url_launcher.dart';

class TelephonyService {
  Future<bool> canMakeCalls() async {
    final testUri = Uri(scheme: 'tel', path: '192');
    return canLaunchUrl(testUri);
  }

  Future<bool> callSamu() => _call('192');
  Future<bool> callBombeiros() => _call('193');
  Future<bool> callCvv() => _call('188');
  Future<bool> callPolicia() => _call('190');

  Future<bool> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  Future<bool> openNearestEmergencyRoom() async {
    final geoUri = Uri.parse('geo:0,0?q=pronto+socorro');
    final webUri = Uri.parse('https://www.google.com/maps/search/pronto+socorro');

    if (await canLaunchUrl(geoUri)) {
      return launchUrl(geoUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUri)) {
      return launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
```

### 4.2 Handling Telephony Absence (Tablets, Simulators & Wi-Fi Devices)

On devices lacking cellular telephony capabilities (e.g. Wi-Fi-only iPads, Android tablets without telephony hardware, or desktop/emulators):
- `canLaunchUrl(Uri.parse('tel:192'))` returns `false`.
- The app intercepts this condition and opens the **Telephony Fallback Dialog**:
  - Displays the emergency number in large, prominent 36pt bold monospace typography.
  - Informs the user: *"Este aparelho não suporta chamadas diretas. Disque manualmente para o número abaixo a partir de outro telefone:"*
  - Includes a `[Copiar Número]` button triggering `Clipboard.setData(ClipboardData(text: '192'))` with instant confirmation.

### 4.3 Native Platform Manifest Declarations

#### Android (`mobile/android/app/src/main/AndroidManifest.xml`)
On Android 11+ (API level 30+), apps must declare target package queries in `<queries>`:
```xml
<queries>
    <!-- Telephony dialer intent -->
    <intent>
        <action android:name="android.intent.action.DIAL" />
        <data android:scheme="tel" />
    </intent>
    <!-- Native maps geo query -->
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="geo" />
    </intent>
    <!-- Web browser fallback -->
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="https" />
    </intent>
    <!-- Existing text processing -->
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
</queries>
```

#### iOS (`mobile/ios/Runner/Info.plist`)
Apple requires declaring external URI schemes under `LSApplicationQueriesSchemes`:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>tel</string>
    <string>geo</string>
    <string>maps</string>
    <string>https</string>
    <string>http</string>
</array>
```

---

## 5. Trilingual Localization (I18N-01)

All strings for Screen 8 are declared across `app_pt.arb`, `app_es.arb`, and `app_en.arb`:

### Summary of New Localization Keys

| Key | Brazilian Portuguese (`app_pt.arb`) | Spanish (`app_es.arb`) | English (`app_en.arb`) |
|---|---|---|---|
| `emergencyTitle` | Alerta de Risco Imediato | Alerta de Riesgo Inmediato | Immediate Risk Alert |
| `emergencySubtitle` | Sintomas de gravidade identificados. Procure atendimento médico urgente. | Síntomas graves identificados. Busque atención médica urgente. | Severe symptoms identified. Seek immediate emergency medical care. |
| `emergencyBadgeChestPain` | Dor Torácica Crítica | Dolor Torácico Crítico | Critical Chest Pain |
| `emergencyBadgeRespiratory` | Dificuldade Respiratória Aguda | Dificultad Respiratoria Aguda | Acute Respiratory Distress |
| `emergencyBadgeStroke` | Suspeita de Déficit Neurológico (AVC) | Sospecha de Déficit Neurológico (ACV) | Suspected Neurological Deficit (Stroke) |
| `emergencyBadgeHeadache` | Cefaleia Súbita e Explosiva | Cefalea Súbita y Explosiva | Sudden Severe Headache |
| `emergencyBadgeEmotional` | Apoio Emocional Imediato / Risco à Vida | Apoyo Emocional Inmediato / Riesgo Vital | Immediate Crisis Support / Life Safety |
| `emergencyBadgeGeneral` | Sintoma Crítico (Nível 4–5) | Síntoma Crítico (Nivel 4–5) | Critical Symptom (Level 4–5) |
| `emergencyInstructionPhysical1` | Interrompa qualquer esforço físico e permaneça em repouso. | Interrumpa cualquier esfuerzo físico y permanezca en reposo. | Stop any physical activity and rest immediately. |
| `emergencyInstructionPhysical2` | Não dirija até o hospital. Acione o 192 ou peça ajuda a terceiros. | No conduzca al hospital. Llame al 192 o pida ayuda a un acompañante. | Do not drive to the hospital. Call emergency services or ask someone for help. |
| `emergencyInstructionPhysical3` | Afrouxe roupas apertadas e tente manter a calma enquanto o socorro chega. | Afloje la ropa ajustada e intente mantener la calma mientras espera la ayuda. | Loosen tight clothing and try to stay calm while waiting for assistance. |
| `emergencyInstructionEmotional1` | Você não está sozinho(a). Ajuda qualificada e sigilosa está disponível agora. | No estás solo/a. Hay ayuda especializada y confidencial disponible ahora mismo. | You are not alone. Qualified, confidential help is available right now. |
| `emergencyInstructionEmotional2` | O CVV oferece apoio emocional gratuito 24 horas por dia pelo telefone 188. | El CVV ofrece apoyo emocional gratuito las 24 horas a través del teléfono 188. | Free, confidential 24/7 crisis support is available. In Brazil, dial 188 (CVV). |
| `emergencyInstructionEmotional3` | Se sentir que está em perigo imediato, acione o 192 ou procure a emergência. | Si siente que está en peligro inmediato, llame al 192 o acuda a una sala de emergencias. | If you feel in immediate danger, call emergency services (192) or go to the ER. |
| `emergencyCallSamu` | Ligar SAMU (192) | Llamar SAMU (192) | Call SAMU (192) |
| `emergencyCallBombeiros` | Ligar Bombeiros (193) | Llamar Bomberos (193) | Call Fire / Rescue (193) |
| `emergencyCallCvv` | Ligar CVV - Apoio Emocional (188) | Llamar CVV - Apoyo Emocional (188) | Call Crisis Line (188) |
| `emergencyCallPolicia` | Ligar Polícia (190) | Llamar Polícia (190) | Call Police (190) |
| `emergencyFindHospital` | Buscar Pronto-Socorro Mais Próximo | Buscar Sala de Urgencias Cercana | Find Nearest Emergency Room |
| `emergencyDispatcherHint` | Ao ligar, informe seu endereço com clareza e mantenha a calma. | Al llamar, informe su dirección con claridad y mantenga la calma. | When calling, state your address clearly and stay calm. |
| `emergencyExitButton` | Voltar ao Início (Não recomendado) | Volver al Inicio (No recomendado) | Return to Home (Not recommended) |
| `emergencyExitConfirmTitle` | Atenção Médica Urgente | Atención Médica Urgente | Urgent Medical Attention |
| `emergencyExitConfirmBody` | Seus sintomas indicam uma situação de risco à vida. Recomendamos fortemente que você contate um serviço médico antes de sair. Deseja realmente voltar ao início? | Sus síntomas indican una situación de riesgo vital. Le recomendamos encarecidamente que contacte con un servicio médico antes de salir. ¿Desea realmente volver al inicio? | Your symptoms indicate a life-threatening risk. We strongly advise contacting emergency services before leaving. Are you sure you want to exit? |
| `emergencyExitConfirmStay` | Permanecer na Emergência | Permanecer en Emergencia | Stay on Emergency Screen |
| `emergencyExitConfirmLeave` | Entendi os Riscos / Sair | Entendido / Salir | I Understand Risks / Exit |
| `emergencyFallbackTitle` | Dispositivo sem Discador | Dispositivo sin Marcador | Calling Not Supported |
| `emergencyFallbackBody` | Este aparelho não suporta chamadas diretas. Disque manualmente para o número abaixo em outro telefone: | Este dispositivo no soporta llamadas directas. Marque manualmente el siguiente número en otro teléfono: | Direct calling is not supported on this device. Please dial the following number from another phone: |
| `emergencyCopyNumber` | Copiar Número | Copiar Número | Copy Number |
| `emergencyCopiedToast` | Número copiado para a área de transferência. | Número copiado al portapapeles. | Number copied to clipboard. |

---

## 6. Backend Audit Integration (LGPD Compliance)

### 6.1 Asynchronous Emergency Event Reporting

Under Brazilian LGPD (Art. 11), emergency escalation events must be logged for clinical auditability. However, **life-safety client operations must never be delayed by backend network latency or downtime**.

- The client fires the report via `unawaited(ref.read(emergencyAuditServiceProvider).reportEmergencyEvent(...))`.
- If the phone is offline or in flight mode, the failure is caught gracefully without interrupting the user.

### 6.2 Endpoint Contract & Schema

- **Route**: `POST /v1/triage/emergency-event`
- **Authorization**: Optional/Bearer JWT (records `userId` if user is authenticated; allows anonymous UUID if triggered during initial unauthenticated onboarding/check-in).
- **Rate Limit**: Permissive (e.g. 30 requests/minute per IP) so emergency reporting is never blocked by throttling.

#### Request DTO (`create-emergency-event.dto.ts`):
```typescript
export class CreateEmergencyEventDto {
  @IsEnum(EmergencyTriggerCategory)
  triggerCategory: string;

  @IsInt()
  @Min(4)
  @Max(5)
  severityLevel: number;

  @IsEnum(['PHYSICAL', 'EMOTIONAL'])
  sourceVertical: 'PHYSICAL' | 'EMOTIONAL';

  @IsISO8601()
  clientTimestamp: string;

  @IsOptional()
  @IsString()
  actionTaken?: 'DIALED_192' | 'DIALED_188' | 'DIALED_193' | 'OPENED_MAPS' | 'DISMISSED_CONFIRMED';
}
```

#### Drizzle ORM Schema (`backend/src/database/schema/triage-emergency-events.schema.ts`):
```typescript
import { pgTable, uuid, text, integer, timestamp, pgPolicy } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';

export const triageEmergencyEvents = pgTable(
  'triage_emergency_events',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }),
    triggerCategory: text('trigger_category').notNull(),
    severityLevel: integer('severity_level').notNull(),
    sourceVertical: text('source_vertical').notNull(),
    actionTaken: text('action_taken'),
    reportedAt: timestamp('reported_at', { withTimezone: true }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    pgPolicy('triage_emergency_events_isolation', {
      for: 'all',
      using: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
      withCheck: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
  ],
);
```

---

## 7. Common Pitfalls & Prevention Strategies (Phase 3 Specific)

| Pitfall | Root Cause | Impact | Prevention Strategy |
|---|---|---|---|
| **Android Back Button Dismissal** | Using standard `AppBar` or unhandled back navigation gestures. | Panicked patient accidentally leaves emergency screen and resumes triage, delaying critical care. | Wrap root view in `PopScope(canPop: false)`. Intercept back gestures via `onPopInvokedWithResult` and display non-dismissible risk confirmation modal. |
| **`canLaunchUrl` Crash on Tablets** | Assuming every mobile device is a phone capable of placing cellular calls. | App crashes or hangs on iPads or Android Wi-Fi tablets when user taps "Ligar 192". | Check `canLaunchUrl` beforehand; if false, display `TelephonyFallbackDialog` showing the number in 36pt font with 1-tap clipboard copy. |
| **Missing Android 11+ Package Visibility** | Omitting `<queries>` intent declarations in `AndroidManifest.xml`. | `canLaunchUrl('tel:192')` returns `false` on all modern Android devices even with a valid phone SIM. | Declare `android.intent.action.DIAL` with `tel` scheme and `VIEW` with `geo` in `AndroidManifest.xml`. |
| **Missing iOS `LSApplicationQueriesSchemes`** | Omitting schemes in `Info.plist`. | iOS blocks scheme queries, preventing dialer launch. | Declare `tel`, `geo`, `maps` under `LSApplicationQueriesSchemes` in `Info.plist`. |
| **UI Overflow on Small Screens (`RenderFlex`)** | Fixed vertical `Column` layout without scrolling. | Bottom buttons cut off or yellow/black striped overflow error on iPhone SE or high display zoom. | Use `SingleChildScrollView` with `SafeArea` ensuring full vertical scrolling on any viewport. |
| **Network Lag on Emergency Redirection** | Blocking navigation while sending audit telemetry to backend. | 2–5 second freeze during acute life-threatening emergency. | Make backend event reporting completely asynchronous and non-blocking (`unawaited`). |
| **Stale Session State Bleed** | Failing to reset active triage state when emergency is triggered. | If user exits emergency days later, previous acute crisis answers remain active in form. | Purge in-memory draft session upon emergency trigger and upon exit confirmation. |

---

## 8. Validation Architecture

### 8.1 Automated Flutter Mobile Test Suite

#### Execution Commands
```bash
# Run all Phase 3 unit and widget tests
flutter test test/features/emergency/
```

#### Test Structure
```
mobile/test/features/emergency/
├── red_flag_evaluator_test.dart      # Unit tests for deterministic rule engine
├── emergency_screen_test.dart        # Widget tests for Screen 8 rendering & PopScope
└── telephony_service_test.dart       # Mock tests for dialer intents & fallback dialogs
```

#### Key Test Scenarios & Fixtures

1. **`red_flag_evaluator_test.dart` (Unit Tests)**:
   - *Physical Chest Pain*: Intensity 5 on `cardiovascular_chest` returns `EmergencyTriggerCategory.chestPain`.
   - *Physical Dyspnea*: Intensity 4 on `respiratory` returns `EmergencyTriggerCategory.respiratoryDistress`.
   - *Stroke Cincinnati*: Raw text containing "boca torta e braço fraco" immediately halts triage without intensity.
   - *Thunderclap Headache*: Text containing "pior dor de cabeça da vida" triggers `EmergencyTriggerCategory.thunderclapHeadache`.
   - *Suicidal Crisis*: Text containing "quero me matar" or "end my life" immediately triggers `EmergencyTriggerCategory.suicidalCrisis`.
   - *Negative Controls*: Intensity 2 on `knee` (membros inferiores) or mild tension headache returns `null` (no emergency halt).

2. **`emergency_screen_test.dart` (Widget Tests)**:
   - *Visual Invariants*: Verifies `#D32F2F` background, stark title "Alerta de Risco Imediato", and context badge.
   - *Physical Variant*: Asserts presence of `Ligar SAMU (192)` and physical instruction cards.
   - *Emotional Variant*: Asserts presence of `Ligar CVV - Apoio Emocional (188)` and emotional instruction cards.
   - *`PopScope` Gesture Lock*: Dispatches system back pop; asserts screen does NOT pop and `EmergencyExitConfirmationDialog` is displayed.
   - *Confirmation Stay*: Tapping "Permanecer na Emergência" dismisses dialog; emergency screen remains visible.
   - *Confirmation Leave*: Tapping "Entendi os Riscos / Sair" pops dialog and navigates to `/home`.
   - *Trilingual Switching*: Tests rendering under `Locale('pt')`, `Locale('es')`, and `Locale('en')`.

3. **`telephony_service_test.dart` (Platform Mock Tests with Mocktail)**:
   - Mock `UrlLauncherPlatform` instance.
   - *Happy Path Dialing*: Tapping "Ligar SAMU (192)" verifies `launchUrl(Uri.parse('tel:192'))` is invoked with `LaunchMode.externalApplication`.
   - *Tablet Fallback*: When `canLaunchUrl` returns `false`, verifies that the fallback dialog appears displaying "192" and clipboard copy button.

### 8.2 Automated Backend Test Suite (NestJS)

#### Execution Commands
```bash
# In backend/ directory:
npm run test:unit -- src/modules/triage/emergency-event.service.spec.ts
npm run test:e2e -- test/emergency-event.e2e-spec.ts
```

#### Key Test Scenarios
1. **`emergency-event.service.spec.ts`**:
   - Successfully records emergency event with valid UUID, severity level 5, and category enum.
   - Rejects invalid severity level (<4) with validation error.
2. **`emergency-event.e2e-spec.ts`**:
   - `POST /v1/triage/emergency-event` with Bearer token returns 201 Created and persists row in `triage_emergency_events`.
   - Verifies tenant isolation: user A cannot query user B's emergency events under RLS.

---

## 9. Recommended Plan Breakdown for Phase 3

Phase 3 is structured into **2 sequential implementation plans**:

- **Plan 03-01: Deterministic Red-Flag Evaluation Engine & Emergency State Machine**:
  - Add `url_launcher: ^6.3.2` to `mobile/pubspec.yaml`.
  - Update `mobile/android/app/src/main/AndroidManifest.xml` (`<queries>` for `tel`, `geo`, `https`).
  - Update `mobile/ios/Runner/Info.plist` (`LSApplicationQueriesSchemes` for `tel`, `geo`, `maps`).
  - Implement domain models (`EmergencyTriggerCategory`, `EmergencyContext`, `EmergencyState`).
  - Implement `RedFlagEvaluator` with MTS/ESI clinical criteria and trilingual regex keyword scanner.
  - Implement Riverpod `emergencyControllerProvider` and `TelephonyService`.
  - Add route `/emergency` to `app_router.dart`.
  - Deliver automated unit test suite (`red_flag_evaluator_test.dart`, `telephony_service_test.dart`).

- **Plan 03-02: Screen 8 Emergency Modal, PopScope Lock, Trilingual Copy & Backend Audit**:
  - Add complete trilingual keys to `app_pt.arb`, `app_es.arb`, and `app_en.arb`.
  - Implement `EmergencyScreen` (`#D32F2F`), `PopScope(canPop: false)`, and `EmergencyExitConfirmationDialog`.
  - Implement action buttons (SAMU 192, CVV 188, Bombeiros 193, Maps Emergency Room) and `TelephonyFallbackDialog`.
  - Create NestJS `triage_emergency_events` Drizzle schema, `TriageAuditModule`, and `POST /v1/triage/emergency-event`.
  - Deliver comprehensive widget tests (`emergency_screen_test.dart`) and backend e2e tests (`emergency-event.e2e-spec.ts`).

