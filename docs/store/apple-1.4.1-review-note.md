# Apple App Review Guideline 1.4.1 — Intended Use & Safety Note

**App Name:** Dualis  
**Bundle ID:** `com.dualis.checkup` (or `dualis_mobile`)  
**Target Category:** Health & Fitness  
**Submission Note / Reviewer Response Regarding Guideline 1.4.1 (Physical Harm / Medical Claims)**

---

### Dear App Review Team,

We are submitting this note to clarify the intended use, functional boundaries, and safety architecture of **Dualis** with respect to **App Review Guideline 1.4.1 (Medical and Health Apps)** and related guidelines (5.1.1 and 5.1.3).

---

### 1. Statement of Intended Use (Non-Medical / General Wellness)

**Dualis is a general health & wellness journaling and self-awareness application.**  
The canonical intended-use statement, prominently displayed in the app's onboarding, terms of service, and store description, is as follows:

> *"DualisCheckUp is a wellness and self-awareness app. It helps you keep a daily journal of how you feel physically and emotionally, track habits such as hydration and sleep, view your own entries over time, and access general educational content about healthy habits. DualisCheckUp is not a medical device: it does not assess, classify or interpret symptoms, does not indicate urgency levels, does not diagnose, does not recommend treatment and does not replace a healthcare professional. In an emergency, call your local emergency number. If you are in emotional distress, contact your local crisis line."*

The application is **intended as a wellness app; regulatory confirmation is pending**. It is **not** Software as a Medical Device (SaMD) and does not fall under regulated medical device classifications in Brazil (ANVISA RDC 657/2022 exclusions for general wellness), the European Union (EU MDR 2017/745 / MDCG 2019-11), or the United States (FDA General Wellness: Policy for Low Risk Devices).

---

### 2. Functional Boundaries — What the App Does and Does NOT Do

| Capability | App Implementation | Medical Claim / SaMD? |
|---|---|---|
| **Symptom Interpretation & Triage** | **NONE.** The app does not interpret symptoms, calculate urgency scores, or assign clinical dispositions (e.g., "urgent care" vs. "self care"). | **NO** — Strictly excluded. |
| **Medical Diagnosis** | **NONE.** The app never suggests, predicts, or infers diseases, conditions, or medical diagnoses based on user inputs. | **NO** — Strictly excluded. |
| **Intensity Tracking** | Purely **self-reported** by the user on a subjective 1–5 scale. Clearly labeled in UI as *"Intensidade que você informou"* (Self-reported intensity). | **NO** — Personal record only. |
| **AI Tagging (Gemini)** | Used solely as a neutral semantic organizer to index user journal entries into general body areas (e.g., "head", "chest", "legs") or emotional states. The AI prompt explicitly forbids diagnosis, severity grading, or clinical advice. | **NO** — Organizational tool. |
| **Educational Content** | General, non-personalized articles on lifestyle, hydration, sleep hygiene, and stress relief. All articles cite authentic, verifiable public health organizations (e.g., *Ministério da Saúde*), with clear disclaimers that they are not personal medical advice. | **NO** — General wellness education. |

---

### 3. Universal & Always-On Safety Resources (No Algorithmic Gating)

Unlike clinical triage tools that only surface emergency resources if an algorithm flags severe danger, Dualis implements an **always-on, universal safety resource architecture**:

1. **Global "Ajuda urgente" Button:** Available in 1 tap from the navigation bar on every authenticated screen as well as the sign-in screen, regardless of user input.
2. **Static Emergency Resources Screen:** Displays verified public emergency contact numbers customized by device region (e.g., Brazil: SAMU 192, CVV 188, Bombeiros 193, Polícia 190; US: 911/988; EU: 112).
3. **Static List of Warning Signs:** Contains verbatim, publicly established emergency warning signs cited directly from official public health agencies (*Ministério da Saúde* / SAMU).
4. **Non-Blocking Safety Prompts:** If a user logs a high discomfort rating (5/5) or enters alarming text, the application displays a static, non-judgmental prompt (*"Se isso for uma emergência, não use o app: ligue 192 agora."*) with direct access to local emergency services. The screen is dismissable and does not attempt clinical diagnosis.

---

### 4. Privacy & Guideline 5.1.3 Compliance

- **No Third-Party Health Data Tracking:** The app does not use health or wellness data for advertising, profiling, or cross-app tracking.
- **Contextual Local Ads:** Native banner ads utilize only coarse age range and approximate location for local merchant discovery (e.g., pharmacies, grocery stores); personal wellness entries are never shared with ad networks.
- **Field-Level Encryption & RLS:** All personal wellness records are protected with AES-256 encryption at rest and TLS 1.3 in transit, backed by PostgreSQL Row-Level Security.

---

### 5. Summary

Dualis does not generate inaccurate or misleading medical data because it does **not** provide clinical assessments, triage levels, or medical advice. It functions exclusively as a personal health and wellness log, keeping the user in full control of their self-reported information.

Please feel free to contact our engineering and compliance team should you require any additional demonstrations, test credentials, or clarifications during review.
