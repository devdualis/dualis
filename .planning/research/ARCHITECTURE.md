# Architecture Research

**Domain:** AI-Driven Preventive Health & Clinical Triage Mobile Platform (Somatic & Psycho-Emotional)  
**Researched:** 2026-09-13  
**Confidence:** HIGH  

---

## Standard Architecture

### System Overview

DualisCheckUp is structured as an offline-capable, client-server preventive health ecosystem. The client is a cross-platform Flutter application utilizing Riverpod for strict state machines and reactive UI updates. The backend is a modular NestJS monolith deployed in Docker containers in the São Paulo region (`sa-east-1` / `southamerica-east1`) for Brazilian LGPD residency compliance. It coordinates PostgreSQL with Row-Level Security (RLS) and temporal indices, Redis 7 for caching and BullMQ background task execution, and an AI classification engine powered by Gemini 1.5 Flash with structured JSON schemas.

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              FLUTTER MOBILE CLIENT (iOS / Android)                     │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────┐  ┌────────────────────────┐  ┌──────────────────────────┐  │
│  │   Dynamic Theme Core   │  │  5-Step Triage Screen  │  │ 2D Body Heat Map Canvas  │  │
│  │ (Indigo ↔ Teal Tween)  │  │  (Riverpod State Mach) │  │ (CustomPainter Vector)   │  │
│  └───────────┬────────────┘  └───────────┬────────────┘  └────────────┬─────────────┘  │
│              │                           │                            │                │
│  ┌───────────┴───────────────────────────┴────────────────────────────┴─────────────┐  │
│  │                     Riverpod Application State Layer                             │  │
│  │    [TriageNotifier]    [EmergencySafetyNotifier]    [SyncOutboxNotifier]         │  │
│  └───────────────────────────────────────┬──────────────────────────────────────────┘  │
│                                          │                                             │
│  ┌───────────────────────────────────────┴──────────────────────────────────────────┐  │
│  │                      Local Persistence & Offline Cache                           │  │
│  │             [Drift / SQLite Store]  ←→  [Secure Storage (Tokens/Keys)]            │  │
│  └───────────────────────────────────────┬──────────────────────────────────────────┘  │
└──────────────────────────────────────────┼─────────────────────────────────────────────┘
                                           │ HTTPS (TLS 1.3 / mTLS / Pinning)
                                           ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              NETWORK & EDGE GATEWAY                                    │
│             Cloudflare WAF / Traefik Reverse Proxy (Rate Limiting, SSL Termination)     │
└──────────────────────────────────────────┬─────────────────────────────────────────────┘
                                           │
                                           ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               NESTJS BACKEND PLATFORM                                  │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│  │                     HTTP Gateway, Guards & Interceptors                          │  │
│  │     [JwtAuthGuard]   [LgpdConsentGuard]   [RlsSessionInterceptor]   [Throttler]  │  │
│  └───────────────────────────────────────┬──────────────────────────────────────────┘  │
│                                          │                                             │
│  ┌───────────────────────────────────────┴──────────────────────────────────────────┐  │
│  │                              Core Domain Modules                                 │  │
│  │  ┌────────────────┐  ┌──────────────────┐  ┌─────────────────┐  ┌─────────────┐  │  │
│  │  │ Triage Module  │  │ Antiburla Engine │  │ AI Classifier   │  │ Lab Exam    │  │  │
│  │  │ (5-Step Tree & │  │ (14-Day Temporal │  │ (Gemini 1.5     │  │ Ingestion   │  │  │
│  │  │ Emergency Halt)│  │ Consistency Scan)│  │ JSON Schemas)   │  │ (Presigned) │  │  │
│  └───────┬────────┘  └────────┬─────────┘  └────────┬────────┘  └──────┬──────┘  │  │
│  └──────────┼────────────────────┼─────────────────────┼──────────────────┼─────────┘  │
│             │                    │                     │                  │            │
│  ┌──────────┴────────────────────┴─────────────────────┴──────────────────┴─────────┐  │
│  │                           Queue & Background Workers                             │  │
│  │                 [BullMQ OCR Worker]  ←→  [BullMQ LLM Worker]                      │  │
│  └───────────────────────────────────────┬──────────────────────────────────────────┘  │
└──────────────────────────────────────────┼─────────────────────────────────────────────┘
                                           │
                ┌──────────────────────────┴──────────────────────────┐
                │                                                     │
                ▼                                                     ▼
┌──────────────────────────────────────────────┐  ┌──────────────────────────────────────┐
│           DATA PERSISTENCE TIER              │  │          EXTERNAL AI & CLOUD         │
├──────────────────────────────────────────────┤  ├──────────────────────────────────────┤
│  PostgreSQL 16 (São Paulo Region - LGPD)     │  │  Google Gemini 1.5 Flash API        │
│  - Row-Level Security (RLS) enforced per UID │  │  - Sub-2s latency, JSON Schema mode  │
│  - 14-Day Temporal B-Tree & BRIN Indices     │  │  - Somatic & Psychosomatic Matrices  │
│  - JSONB for flexible clinical biomarkers    │  ├──────────────────────────────────────┤
│                                              │  │  OCR Extraction Engine               │
│  Redis 7 Cluster                             │  │  - AWS Textract / Cloud Vision       │
│  - Semantic triage response cache            │  ├──────────────────────────────────────┤
│  - BullMQ job queues & distributed locks     │  │  S3 / GCS Storage Bucket             │
│  - Ephemeral user session state              │  │  - SSE-KMS Encrypted Medical PDFs    │
└──────────────────────────────────────────────┘  └──────────────────────────────────────┘
```

---

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **Flutter Mobile App** | Cross-platform client for iOS and Android; provides 60fps gesture-rich UI, offline-first local cache, dynamic color interpolation, and native hardware integration. | Flutter 3.x with Dart, Riverpod 2.x, Material 3, GoRouter. |
| **Riverpod Triage State Machine** | Enforces the standardized 5-step triage decision tree (Nature → Persistence → Intensity → Triggers → Outcome); manages session lifecycle with automatic cleanup (`autoDispose`). | `AutoDisposeAsyncNotifier<TriageState>` with sealed immutable state unions. |
| **Visual State Switcher** | Seamlessly transitions color palettes between Soft Indigo (`#4F46E5` for Psico-Emocional) and Clinical Teal (`#0D9488` for Física) to reduce cognitive load. | `AnimatedTheme` / `TweenAnimationBuilder<ColorScheme>` driven by `activeVerticalProvider`. |
| **2D Body Heat Map Canvas** | Renders anatomical silhouette across 12 anatomical systems; translates symptom pain/severity scores (1-5) into a chromatic radial gradient (Yellow to Deep Crimson). | Flutter `CustomPainter` with normalized SVG vector coordinate paths and radial shader blurs. |
| **Mobile Offline Sync Engine** | Persists draft triage logs and recent history locally; queues pending check-ins in an outbox and flushes them when connectivity resumes. | Drift (SQLite) or Isar with `connectivity_plus` and transactional outbox table. |
| **NestJS Modular API** | Hosts RESTful endpoints, orchestrates domain logic, handles user authentication, verifies LGPD consent, and manages PostgreSQL transactions. | NestJS 10.x, TypeScript, Fastify/Express engine, Class-Validator, Passport JWT. |
| **RLS Session Interceptor** | Injects the authenticated user ID into the active PostgreSQL session context (`SET LOCAL app.current_user_id = :userId`) before executing queries. | NestJS Interceptor wrapping TypeORM/Prisma/Kysely execution inside a database transaction. |
| **Antiburla Engine** | Analyzes the current triage submission against the patient's rolling 14-day history across 19 categories; detects contradictory claims and initiates empathetic clarification flows. | NestJS `ConsistencyEngineService` querying PostgreSQL temporal index `(user_id, recorded_at DESC)`. |
| **AI Symptom Classifier** | Disambiguates lay descriptions (e.g. "racing heart") into somatic vs psychosomatic clinical matrices using constrained JSON Schema generation within <2s. | Gemini 1.5 Flash via Google Gen AI SDK with fallback circuit breaker. |
| **Decoupled OCR + LLM Pipeline** | Processes uploaded laboratory exam PDFs/images asynchronously without blocking API request threads; extracts structured biomarker key-value pairs. | AWS Textract / Cloud Vision → Redis BullMQ Queue → NestJS Worker → Gemini 1.5 Flash → PostgreSQL. |
| **Emergency Safety Net** | Zero-latency emergency interceptor; triggers immediate red screen modal with one-tap local emergency services (SAMU 192 / 190) when severity 4-5 is detected. | Dual-enforced: Mobile Riverpod immediate guard + Backend `EmergencyException` filter. |

---

## Recommended Project Structure

DualisCheckUp uses a monorepo structure (or structured multi-repo) separating the Flutter client and the NestJS backend, while sharing protocol schemas and API contracts.

```
dualis/
├── .planning/                  # Project roadmap, research, and phase state
├── docker/                     # Container definitions & compose manifests
│   ├── docker-compose.yml      # Local dev stack (NestJS, Postgres, Redis, LocalStack)
│   ├── Dockerfile.backend      # Multi-stage production NestJS Dockerfile
│   └── postgres-init/          # DB initialization scripts (RLS setup, extensions)
├── backend/                    # NestJS Modular Backend
│   ├── src/
│   │   ├── common/             # Cross-cutting guards, decorators, filters
│   │   │   ├── decorators/     # CurrentUser, Roles, Public
│   │   │   ├── filters/        # GlobalHttpExceptionFilter, EmergencyExceptionFilter
│   │   │   ├── guards/         # JwtAuthGuard, LgpdConsentGuard, ThrottlerBehindProxyGuard
│   │   │   ├── interceptors/   # PostgresRlsInterceptor, LoggingInterceptor
│   │   │   └── pipes/          # ZodValidationPipe / ClassValidationPipe
│   │   ├── config/             # Environment validation, database, Redis, S3 configs
│   │   ├── database/           # Migrations, seeds, RLS policies, custom SQL functions
│   │   │   ├── migrations/     # TypeORM / Kysely migration files
│   │   │   └── rls-policies/   # Pure SQL definitions for PostgreSQL RLS
│   │   ├── modules/            # Feature-driven domain modules
│   │   │   ├── auth/           # Identity, OTP, LGPD consent registry
│   │   │   ├── triage/         # 5-Step Triage engine, emergency evaluation
│   │   │   │   ├── controllers/
│   │   │   │   ├── dto/        # Inbound/outbound schema contracts
│   │   │   │   ├── entities/   # TriageSession, TriageStepLog
│   │   │   │   └── services/   # TriageOrchestratorService
│   │   │   ├── consistency/    # 14-Day Temporal Antiburla Engine
│   │   │   │   ├── algorithms/ # Inconsistency detection heuristics
│   │   │   │   └── services/   # ConsistencyEngineService
│   │   │   ├── ai-classifier/  # Gemini 1.5 Flash client & prompt templates
│   │   │   │   ├── schemas/    # Strict JSON schemas for 19 categories
│   │   │   │   └── services/   # GeminiClassifierService, SomaticDisambiguator
│   │   │   ├── lab-exam/       # Decoupled OCR & LLM processing
│   │   │   │   ├── queues/     # BullMQ producers & consumers
│   │   │   │   ├── ocr/        # Textract / Cloud Vision adapter
│   │   │   │   └── services/   # LabExamService, BiomarkerExtractor
│   │   │   ├── dashboard/      # Heat map data aggregation, 7-day emotional trends
│   │   │   └── audit/          # LGPD immutable access and modification log
│   │   ├── app.module.ts       # Root module assembling domain features
│   │   └── main.ts             # Bootstrap with Fastify/Express, helmet, CORS
│   ├── test/                   # E2E test suites (Supertest, testcontainers)
│   ├── package.json
│   └── tsconfig.json
├── mobile/                     # Flutter Cross-Platform Client
│   ├── android/                # Android native wrapper & permissions
│   ├── ios/                    # iOS native wrapper & entitlements
│   ├── assets/                 # SVGs, anatomical silhouette vectors, fonts
│   │   ├── vectors/body/       # 12 anatomical region vector path definitions
│   │   └── icons/
│   ├── lib/
│   │   ├── core/               # App-wide constants, network client, theme definitions
│   │   │   ├── constants/      # AppColors (Indigo, Teal, Crimson), API endpoints
│   │   │   ├── network/        # Dio client, AuthInterceptor, RetryInterceptor
│   │   │   ├── security/       # BiometricAuth, FlutterSecureStorage adapter
│   │   │   └── theme/          # DynamicThemeNotifier, AppThemeData (M3)
│   │   ├── features/           # Feature-first modular organization
│   │   │   ├── auth/           # Login, onboarding, LGPD consent dialogs
│   │   │   ├── triage/         # Core 5-step triage feature
│   │   │   │   ├── data/       # TriageRepository, TriageRemoteDataSource, OutboxDao
│   │   │   │   ├── domain/     # TriageSession, TriageStep, SymptomSeverity
│   │   │   │   └── presentation/
│   │   │   │       ├── controllers/ # TriageStateMachine (Riverpod Notifier)
│   │   │   │       ├── screens/     # UnifiedEntryScreen, StepWizardScreen
│   │   │   │       └── widgets/     # StepCards, NaturePicker, IntensitySlider
│   │   │   ├── emergency/      # Red-Screen Emergency Halt Modal
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── controllers/ # EmergencySafetyNotifier
│   │   │   │   │   └── widgets/     # OneTapCallButton, GuidanceCard
│   │   │   ├── heat_map/       # 2D Anatomical Body Heat Map
│   │   │   │   ├── presentation/
│   │   │   │   │   ├── canvas/      # AnatomicalCanvasPainter (CustomPainter)
│   │   │   │   │   └── widgets/     # InteractiveBodyView, ChromaticLegend
│   │   │   ├── emotional_graph/# 7-Day emotional multi-axis trend visualizer
│   │   │   ├── lab_exams/      # Document scanner, PDF upload, biomarker viewer
│   │   │   └── history/        # 14-Day longitudinal check-in list
│   │   ├── shared/             # Shared reusable presentation components
│   │   │   └── widgets/        # DualisAppBar, ErrorStateView, ShimmerSkeleton
│   │   └── main.dart           # App entry point with ProviderScope
│   ├── pubspec.yaml
│   └── test/                   # Widget tests, unit tests, state machine mocks
└── README.md
```

### Structure Rationale

- **Flutter Feature-First (`mobile/lib/features/`)**: Isolates presentation, domain logic, and data access by business capability rather than technical artifact. This prevents coupling between the complex 5-step triage state machine and secondary features like document scanning or profile management.
- **Backend Modular Monolith (`backend/src/modules/`)**: High developer velocity during greenfield development with zero microservice deployment overhead, yet strictly isolated via NestJS module boundaries. Modules communicate via clear internal service APIs or BullMQ event queues, making future extraction into microservices trivial if needed.
- **Dedicated Security & RLS Layer (`backend/src/database/rls-policies/`)**: Keeping Row-Level Security policies in audited SQL migration files guarantees that security rules remain part of the database schema and cannot be accidentally bypassed by backend application code changes.
- **Dedicated Canvas Painter Package (`mobile/lib/features/heat_map/presentation/canvas/`)**: Keeps the mathematically intensive rendering logic (Bézier curves, normalized coordinate transformations, radial shaders) segregated from UI layout logic.

---

## Architectural Patterns

### Pattern 1: Riverpod 5-Step Triage State Machine with Emergency Short-Circuit

**What:** A linear-branching finite state machine implemented via Riverpod `AutoDisposeAsyncNotifier` that strictly enforces step progression:  
`Nature (1) → Persistence (2) → Intensity (3) → Triggers (4) → Outcome (5)`.  
If at any step an emergency red flag is triggered (e.g. intensity 4-5 combined with acute chest pain, dyspnea, or suicidal ideation), the state machine immediately transitions to `EmergencyHaltState`, blocking standard progression and rendering the full-screen modal.

**When to use:** In medical triage and symptom evaluation where skipping steps or leaving an invalid clinical state produces dangerous or inconsistent outcomes.

**Trade-offs:**  
- *Pros:* Complete compile-time type safety; impossible to submit an incomplete triage; automatic garbage collection of memory when user exits (`autoDispose`).
- *Cons:* Rigid progression requires explicit back-navigation stack handling and state caching if the user wants to revise step 2 while on step 4.

**Example:**
```dart
// mobile/lib/features/triage/presentation/controllers/triage_state_machine.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'triage_state_machine.freezed.dart';

@freezed
class TriageState with _$TriageState {
  const factory TriageState.initial() = _Initial;
  const factory TriageState.stepNature({required HealthVertical vertical, String? rawDescription}) = _StepNature;
  const factory TriageState.stepPersistence({required TriageDraft draft}) = _StepPersistence;
  const factory TriageState.stepIntensity({required TriageDraft draft}) = _StepIntensity;
  const factory TriageState.stepTriggers({required TriageDraft draft}) = _StepTriggers;
  const factory TriageState.stepOutcome({required TriageResult result}) = _StepOutcome;
  const factory TriageState.clarificationRequired({required AntiburlaConflict conflict}) = _ClarificationRequired;
  const factory TriageState.emergencyHalt({required EmergencyReason reason}) = _EmergencyHalt;
}

class TriageStateMachine extends AutoDisposeAsyncNotifier<TriageState> {
  @override
  Future<TriageState> build() async => const TriageState.initial();

  void recordNature(HealthVertical vertical, String description) {
    // Dynamic theme updates trigger reactively via activeVerticalProvider
    ref.read(activeVerticalProvider.notifier).state = vertical;
    state = AsyncData(TriageState.stepPersistence(
      draft: TriageDraft(vertical: vertical, rawDescription: description),
    ));
  }

  void recordIntensity(int score) {
    state.whenData((current) {
      if (current is _StepIntensity) {
        final updatedDraft = current.draft.copyWith(intensityScore: score);
        
        // Zero-failure emergency interceptor: Level 4/5 trigger check
        if (score >= 4 && updatedDraft.hasCriticalRedFlags()) {
          state = AsyncData(TriageState.emergencyHalt(
            reason: EmergencyReason.criticalSeverityFlagged(score, updatedDraft.primarySymptom),
          ));
          return;
        }

        state = AsyncData(TriageState.stepTriggers(draft: updatedDraft));
      }
    });
  }
}
```

---

### Pattern 2: Multi-Tenant Row-Level Security (RLS) with Session Context Injection

**What:** PostgreSQL Row-Level Security ensures that database queries executed by the application pool can only read or write rows belonging to the currently authenticated patient (`user_id`). The NestJS backend intercepts every request, opens a transaction, and executes `SET LOCAL app.current_user_id = :userId` before performing any ORM or SQL query.

**When to use:** Mandatory under Brazilian LGPD (Art. 11 - Sensitive Health Data) and medical data regulations to guarantee data isolation even in the event of an application logic defect or SQL injection.

**Trade-offs:**  
- *Pros:* Defense-in-depth security at the database engine level; zero chance of data leaking between patients; satisfies strict LGPD audit requirements.
- *Cons:* Cannot use un-parameterized raw connections from a shared pool without setting session context; requires transactional wrapping or database proxies that maintain connection pinning per transaction.

**Example:**
```sql
-- database/rls-policies/001_symptom_logs_rls.sql
ALTER TABLE symptom_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE symptom_logs FORCE ROW LEVEL SECURITY;

CREATE POLICY patient_isolation_policy ON symptom_logs
    FOR ALL
    USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
    WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);
```

```typescript
// backend/src/common/interceptors/postgres-rls.interceptor.ts
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { DataSource } from 'typeorm';

@Injectable()
export class PostgresRlsInterceptor implements NestInterceptor {
  constructor(private readonly dataSource: DataSource) {}

  async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
    const request = context.switchToHttp().getRequest();
    const userId = request.user?.sub;

    if (!userId) {
      return next.handle();
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Injects tenant context strictly scoped to this local transaction
      await queryRunner.query(`SET LOCAL app.current_user_id = $1`, [userId]);
      request.queryRunner = queryRunner;
      
      const result = await next.handle().toPromise();
      await queryRunner.commitTransaction();
      return result;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }
}
```

---

### Pattern 3: Decoupled Asynchronous Lab Exam OCR + LLM Pipeline

**What:** Processing medical exam reports (PDFs, multi-page lab prints) requires extracting raw text/tables via an OCR engine (AWS Textract or Google Cloud Vision) followed by structured biomarker extraction using an LLM (Gemini 1.5 Flash). This pipeline is fully decoupled from the client request loop via Redis BullMQ queues.

**When to use:** Handling large files (>5MB) and slow third-party processing without exceeding HTTP gateway timeouts (typically 15–30 seconds) or consuming high-cost multimodal vision tokens unnecessarily.

**Trade-offs:**  
- *Pros:* High reliability, automatic retry with exponential backoff, cost optimization (plain text LLM tokens are 10x cheaper than high-res multimodal vision tokens), excellent user experience with real-time status polling or push notifications.
- *Cons:* Requires background queue infrastructure (Redis + BullMQ) and asynchronous client UI states (Processing / Completed / Failed).

**Example:**
```typescript
// backend/src/modules/lab-exam/queues/lab-exam-processing.consumer.ts
import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { OcrService } from '../ocr/ocr.service';
import { GeminiBiomarkerExtractor } from '../services/gemini-biomarker-extractor.service';
import { LabExamRepository } from '../repositories/lab-exam.repository';

@Processor('lab-exam-queue')
export class LabExamProcessingConsumer extends WorkerHost {
  constructor(
    private readonly ocrService: OcrService,
    private readonly llmExtractor: GeminiBiomarkerExtractor,
    private readonly labRepo: LabExamRepository,
  ) {
    super();
  }

  async process(job: Job<{ examId: string; storageKey: string; userId: string }>): Promise<void> {
    const { examId, storageKey, userId } = job.data;

    // Step 1: Optical Character Recognition (Extract tabular & plain text)
    const ocrResult = await this.ocrService.extractTextFromStorage(storageKey);

    // Step 2: Constrained LLM Extraction (Token-efficient text input)
    const biomarkers = await this.llmExtractor.extractBiomarkers({
      rawText: ocrResult.rawText,
      tables: ocrResult.tables,
    });

    // Step 3: Persist structured key-value clinical records
    await this.labRepo.saveParsedBiomarkers(examId, userId, biomarkers);
  }
}
```

---

### Pattern 4: 14-Day Temporal Consistency Engine ("Antiburla") with Disambiguation Loop

**What:** When a patient logs symptoms during triage, the NestJS `ConsistencyEngineService` executes a targeted query against the last 14 days of historical logs across the 19 clinical categories. If the engine detects a clinical contradiction (e.g. reporting "acute chest pain starting today" when a log from 3 days ago reported "constant chest pain for 2 weeks", or logging "no physical activity" right after high-intensity exertion), it pauses completion and returns an empathetic clarification prompt.

**When to use:** Ensuring data integrity for medical history and preventing false reassurance or erroneous risk escalation.

**Trade-offs:**  
- *Pros:* Improves longitudinal clinical accuracy; prevents user confusion; produces reliable medical summaries.
- *Cons:* Slightly higher classification latency (~300ms added DB check); requires careful prompt tuning to avoid sounding accusatory or paternalistic to the user.

---

## Data Flow

### Request Flow

```
[Flutter Mobile App]
    │  1. User selects "Feeling unwell" (Unified Entry)
    ▼
[Riverpod TriageStateMachine]
    │  2. Checks local offline cache (Drift) for active draft
    ▼
[Dio Network Client]
    │  3. HTTPS POST /v1/triage/classify (JSON payload + Bearer JWT)
    ▼
[Reverse Proxy / WAF]
    │  4. Rate limiting check (Redis), SSL termination
    ▼
[NestJS API Gateway]
    │  5. JwtAuthGuard verifies claims & active LGPD consent
    │  6. PostgresRlsInterceptor sets app.current_user_id
    ▼
[TriageOrchestratorService]
    ├──────────────────────────────────────────────────┐
    │ 7. Parallel Temporal Scan                        │ 8. Real-Time Classification
    ▼                                                  ▼
[PostgreSQL (14-Day Temporal Index)]            [Gemini 1.5 Flash API]
    │ Query: user_id + recorded_at >= NOW()-14d         │ Schema: JSON Schema (19 categories)
    │ Latency: ~15ms (B-Tree indexed)                  │ Latency: ~850ms (sub-2s SLA)
    ▼                                                  ▼
[ConsistencyEngineService] ◄───────────────────────────┘
    │  9. Merge: Classify symptom + Validate against 14-day history
    ├─ If Severity 4-5: Flag EmergencyHalt
    ├─ If Inconsistent: Flag ClarificationRequired
    └─ If Consistent: Return Next Step Guidance
    ▼
[NestJS Response] (HTTP 200 / 201)
    │  10. Return classified structured JSON
    ▼
[Flutter Mobile App]
    │  11. If Emergency → Render Full-Screen Red Modal + Phone Dialer
    │  12. If Physical  → Animate theme to Clinical Teal (#0D9488)
    │  13. If Emotional → Animate theme to Soft Indigo (#4F46E5)
```

---

### State Management

The Flutter mobile application maintains state using Riverpod 2.x code generation and immutable state models.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          RIVERPOD STATE HIERARCHY                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │               activeVerticalProvider (StateProvider)                │   │
│   │               [Physical | Psycho-Emotional | Hybrid]                │   │
│   └──────────────────────────────────┬──────────────────────────────────┘   │
│                                      │ (Drives color interpolation)         │
│                                      ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │              dynamicThemeProvider (NotifierProvider)                │   │
│   │        Interpolates ColorScheme between Soft Indigo & Clinical Teal  │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │         triageStateMachineProvider (AutoDisposeAsyncNotifier)       │   │
│   │                                                                     │   │
│   │   [Step 1: Nature]  ──► [Step 2: Persistence] ──► [Step 3: Intensity]│  │
│   │           │                                             │           │   │
│   │           ▼                                             ▼           │   │
│   │   [Disambiguation]                             [Emergency Check]   │   │
│   │           │                                             │           │   │
│   │           ▼                                             ▼           │   │
│   │   [Step 4: Triggers] ────────────────────────► [Step 5: Outcome]    │   │
│   │                                                         │           │   │
│   │   [EmergencyHaltState] ◄────────────────────────────────┤ (Red Flag)│   │
│   └──────────────────────────────────┬──────────────────────────────────┘   │
│                                      │                                      │
│                                      ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │               heatMapSyncProvider (AsyncNotifier)                   │   │
│   │      Transforms 12 anatomical logs into normalized 2D coordinates   │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Key Data Flows

#### 1. Unified Daily Entry to 5-Step Triage Execution
1. The user taps "How are you feeling today?" on the home screen.
2. The user inputs a free-form lay string (e.g. "Sentindo meu coração acelerado e aperto no peito").
3. Mobile triggers `AiClassifierModule`. The backend calls Gemini 1.5 Flash using strict JSON schema:
   - Identifies whether the symptom is somatic (Cardiovascular/Respiratory), psycho-emotional (Anxiety/Panic), or a psychosomatic crossover.
   - Assigns initial categorization across the 19 standard categories.
4. Response arrives in <1.2s. The app evaluates the category:
   - If physical, `activeVerticalProvider` sets `HealthVertical.physical`, triggering a 300ms curve animation to Clinical Teal (`#0D9488`).
   - If emotional, sets `HealthVertical.emotional`, animating to Soft Indigo (`#4F46E5`).
5. The 5-step wizard displays Step 2 (Persistence: acute, subacute, chronic).
6. Step 3 records Intensity (Visual Analog Scale 1-5).
7. Step 4 records Triggers (environmental, physical, psychological).
8. Step 5 produces the Outcome: preventive guidance, educational articles, or medical follow-up recommendation.

#### 2. Emergency Level 4–5 Immediate Interruption
1. In Step 3 (Intensity), the user selects level 4 or 5 and flags acute pain or danger symptoms (e.g. radiating chest pain, severe breathlessness, sudden speech impairment, severe depressive despair).
2. The `TriageStateMachine` evaluates the safety invariant:  
   `score >= 4 && hasCriticalRedFlag == true`.
3. The state machine transitions to `TriageState.emergencyHalt()` immediately without contacting the backend.
4. Concurrently, a background telemetry payload is dispatched to the backend (`POST /v1/triage/emergency-alert`) to log the event in compliance with health audit rules.
5. The UI pushes a non-dismissible, full-screen Red Modal (`#DC2626`) showing:
   - Specific clinical hazard identified in plain language.
   - Large one-tap button initiating a native phone call to Brazilian Emergency Services (SAMU `192` or Police/Fire `190/193`).
   - Geolocation coordinates display to assist the user when speaking with the emergency dispatcher.

#### 3. 14-Day Temporal Antiburla Inconsistency Detection
1. User completes step 3 reporting "severe lower back pain that started today and is completely new".
2. `ConsistencyEngineService` queries PostgreSQL:
   ```sql
   SELECT symptom_type, intensity, persistence_days, recorded_at
   FROM symptom_logs
   WHERE user_id = $1 
     AND anatomical_system = 'musculoskeletal'
     AND recorded_at >= NOW() - INTERVAL '14 days'
   ORDER BY recorded_at DESC;
   ```
3. The query returns a log from 5 days prior where the user logged "lumbar strain after heavy gym workout, ongoing for 3 weeks".
4. The backend returns a response with status `INCONSISTENCY_DETECTED` and an empathetic clarification payload.
5. The Flutter app presents an inline clarification modal: *"Notamos que você registrou um desconforto lombar contínuo há 5 dias. Esta dor de hoje é uma piora daquele quadro ou trata-se de um evento completamente diferente?"*
6. User clarifies in one tap; the system merges the temporal record without rejecting or penalizing the user.

#### 4. Asynchronous Lab Exam Processing Pipeline
1. User captures a 3-page blood test PDF via the Flutter mobile document scanner.
2. Flutter requests a presigned upload URL from `POST /v1/lab-exams/presigned-url`.
3. Backend generates an Amazon S3 / Google Cloud Storage presigned PUT URL with a 15-minute TTL, enforcing server-side encryption (`SSE-KMS`).
4. Flutter uploads the binary directly to the object store, bypassing the NestJS API bandwidth.
5. Upon successful upload, Flutter notifies `POST /v1/lab-exams/{id}/process`.
6. NestJS enqueues a job into Redis BullMQ queue `lab-exam-queue`.
7. A BullMQ worker retrieves the file, submits it to AWS Textract for OCR table extraction, and receives raw text and cell matrices.
8. The worker sends the parsed text to Gemini 1.5 Flash with a schema specifying `biomarker_name`, `measured_value`, `unit`, `reference_range_low`, `reference_range_high`, and `clinical_status` (`normal | elevated | low | critical`).
9. Extracted biomarkers are written to PostgreSQL table `clinical_biomarkers` under the patient's RLS context.
10. A push notification (Firebase Cloud Messaging) alerts the patient: *"Seu hemograma foi processado com sucesso e está disponível no seu histórico."*

#### 5. Offline-First Symptom Sync Flow
1. User opens the app while in an area without mobile connectivity (e.g. rural road, hospital basement).
2. The user initiates and completes a daily check-in.
3. `TriageRepository` checks network connectivity via `connectivity_plus`.
4. If offline, the serialized triage session is stored in local Drift SQLite table `sync_outbox` with status `PENDING` and a generated UUID v4.
5. The user is provided immediate feedback: *"Registro salvo no dispositivo. Será sincronizado assim que a conexão for restaurada."*
6. A background listener (`ConnectivityNotifier`) detects network restoration (`WiFi` / `Cellular`).
7. The `SyncOutboxWorker` reads pending rows in FIFO order and posts them to `POST /v1/triage/batch-sync`.
8. The backend idempotently validates the records using the client-generated UUIDs, executes 14-day temporal consistency, commits them to PostgreSQL, and returns 200 OK.
9. Drift marks the local records as `SYNCED`.

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| **0 – 1k Users** | Single NestJS container on Google Cloud Run or AWS ECS Fargate; managed PostgreSQL (`db.t4g.medium`) and managed Redis instance. SQLite (Drift) on client. Synchronous Gemini API calls with 2s timeout. Direct S3 presigned uploads. |
| **1k – 100k Users** | Horizontal auto-scaling of NestJS API instances (min 2, max 10); PostgreSQL read replica for analytical dashboard queries; Redis cluster for BullMQ queues and semantic response caching; Cloudflare CDN edge caching for static assets and preventive articles. |
| **100k+ Users** | Dedicated worker node pools for BullMQ OCR/LLM pipelines to prevent background jobs from starving the user-facing API; PostgreSQL table partitioning by month (`PARTITION BY RANGE (recorded_at)`); multi-region read replicas with primary database strictly retained in São Paulo for LGPD compliance. |

### Scaling Priorities & Bottlenecks

1. **First Bottleneck: LLM Rate Limits & Classification Latency**
   - *Problem:* As daily check-in volume peaks between 7:00 AM and 9:00 AM, concurrent external API requests to Gemini 1.5 Flash can hit quota limits or introduce latency spikes (>2.5s), violating RNF-001.
   - *Fix:* Implement Redis-backed semantic caching for normalized common symptom queries (e.g. "dor de cabeça leve", "azia após o almoço"). Hash canonical symptom representations so identical inputs return cached classifications in <25ms, reducing upstream LLM calls by up to 60%.

2. **Second Bottleneck: 14-Day Temporal Scans on PostgreSQL**
   - *Problem:* At 50,000 active users logging daily symptoms across 19 categories, `symptom_logs` accumulates ~1 million rows monthly. Unoptimized temporal range queries degrade performance.
   - *Fix:* Composite B-Tree indexing on `(user_id, recorded_at DESC)` ensures every 14-day scan performs an index seek scanning at most 14–30 rows per user. For historical partitions older than 90 days, convert to BRIN (Block Range Indexing) to reduce index storage by 85%.

3. **Third Bottleneck: Synchronous Document Parsing in Node.js Event Loop**
   - *Problem:* Parsing heavy multi-page PDF lab reports inside the API process blocks the single-threaded Node.js event loop, degrading HTTP throughput for triage requests.
   - *Fix:* Complete decoupling via BullMQ. The API only signs S3 URLs and enqueues job IDs. Independent containerized workers process OCR and LLM calls in isolated event loops.

---

## Anti-Patterns

### Anti-Pattern 1: Synchronous Heavy OCR & Multimodal LLM Calls in the HTTP Request Thread

**What people do:** When a patient uploads a lab exam photo or PDF, the API controller keeps the HTTP connection open, sends the image directly to a multimodal LLM (e.g. GPT-4o or Gemini multimodal), and waits 15–45 seconds before returning a response.  
**Why it's wrong:** HTTP gateways (AWS ALB, Cloudflare, Fastly) drop connections after 15–30 seconds. Multimodal vision tokens are 10–20x more expensive than raw text tokens. Furthermore, connection timeouts cause client retries, duplicating expensive LLM calls.  
**Do this instead:** Use presigned S3 uploads and decoupled background workers (BullMQ). First run low-cost OCR (Textract/Cloud Vision), then feed the extracted plain text into Gemini 1.5 Flash. Return a 202 Accepted immediately with a job tracking ID.

### Anti-Pattern 2: Client-Only Emergency Safety Gatekeeping

**What people do:** Relying exclusively on mobile Flutter logic to detect Level 4/5 emergencies and display the emergency screen, while backend endpoints blindly accept and persist the data without validation.  
**Why it's wrong:** A compromised client, an outdated app version, or an API call intercepted via proxy can bypass client-side checks, leaving a critically ill patient without immediate intervention or clinical escalation records.  
**Do this instead:** Implement dual-enforced safety gates. The Flutter client enforces an immediate, zero-latency UI short-circuit to protect the user immediately, while the backend `TriageModule` independently verifies severity on every payload. If the backend detects severity 4–5, it responds with an `EmergencyExceptionPayload` and flags the record for emergency audit.

### Anti-Pattern 3: Treating Physical and Psycho-Emotional Symptoms as Disconnected Silos

**What people do:** Building two completely separate triage flows with different database tables, schemas, and classification engines for physical symptoms versus psychological symptoms.  
**Why it's wrong:** Clinically dangerous. Psychosomatic symptoms (e.g. panic attacks mimicking myocardial infarction; chronic gastrointestinal distress masking generalized anxiety) are missed if the systems cannot cross-reference somatic complaints against emotional states.  
**Do this instead:** Implement a unified 5-step decision tree across all 19 categories (12 anatomical + 7 emotional), using dynamic theming (Indigo vs Teal) for visual clarity while storing data in a unified relational schema that enables cross-dimensional correlation.

### Anti-Pattern 4: Direct Unrestricted Database Queries Bypassing PostgreSQL RLS Context

**What people do:** Using an ORM (Prisma or standard TypeORM) with a shared database connection pool without initializing the session variable `app.current_user_id` before queries, relying solely on `WHERE user_id = :id` clauses in application code.  
**Why it's wrong:** A single missing `where` clause in an API handler or an ORM join leak can expose sensitive medical records of one patient to another, creating a catastrophic LGPD violation (Art. 52 penalties up to R$ 50 million).  
**Do this instead:** Enforce PostgreSQL Row-Level Security at the database engine level with `FORCE ROW LEVEL SECURITY`. Combine with a NestJS interceptor that injects `SET LOCAL app.current_user_id = :userId` inside every transactional query.

---

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **Google Gemini 1.5 Flash** | HTTPS REST via `@google/genai` SDK using `responseSchema` (JSON mode). | Enforce strict schemas for 19 categories and sub-2s timeout. Fallback to GPT-4o-mini if error rate exceeds 3% over 60s. |
| **AWS Textract / Cloud Vision** | Asynchronous batch document analysis via AWS SDK / GCP SDK in BullMQ workers. | Used exclusively in background workers. Extracts key-value tables from Brazilian laboratory report layouts (DASA, Fleury, Hermes Pardini). |
| **AWS S3 / Google Cloud Storage** | Pre-signed PUT/GET URLs with 15-minute expiration; server-side encryption with KMS customer-managed keys (`SSE-KMS`). | Storage bucket located in São Paulo (`sa-east-1` / `southamerica-east1`) to satisfy Brazilian data sovereignty. |
| **Firebase Cloud Messaging (FCM)** | Server-side push notifications dispatched when asynchronous OCR/LLM biomarker extraction finishes or check-in reminders trigger. | APNs for iOS, FCM for Android. Zero sensitive clinical data in push payload (only generic alert text). |
| **Brazilian Emergency Services (SAMU / Disque Saúde)** | Native mobile URL launcher (`tel:192`, `tel:190`, `tel:136`). | Client-side native telephony intent triggered from the full-screen Emergency Red Screen modal. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| **Flutter UI ↔ Riverpod State Layer** | Reactive streams (`ref.watch`, `ref.listen`). | State changes trigger smooth theme color tweening (300ms) and canvas repainting. |
| **Flutter Client ↔ NestJS Backend** | HTTPS REST with JSON payloads, Bearer JWT in `Authorization` header. | Client uses Dio with token refresh interceptor and offline sync queue. |
| **NestJS API ↔ PostgreSQL Database** | TypeORM / Kysely connection pool wrapped in transactional `PostgresRlsInterceptor`. | Enforces `SET LOCAL app.current_user_id` before any query execution. |
| **NestJS API ↔ Redis 7** | `ioredis` client for caching; BullMQ for message queuing. | Redis is used for semantic AI query caching, rate limiting, and background jobs. |
| **NestJS TriageModule ↔ Antiburla Engine** | In-process asynchronous dependency injection. | Runs temporal query over last 14 days of `symptom_logs` within the same DB transaction. |
| **LabExamModule ↔ Background Worker** | BullMQ Redis queue (`lab-exam-queue`). | Decouples heavy OCR/LLM jobs from API gateway instances. |

---

## Suggested Build Order (Component Dependencies)

This build order directly guides the roadmap phase structure by establishing technical dependencies from the database core to the presentation layer.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       SUGGESTED IMPLEMENTATION PHASES                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: Core Foundation, Persistence & Security Baseline                   │
│ - Dockerized PostgreSQL 16 & Redis 7 development environment               │
│ - LGPD-compliant database schema with Row-Level Security (RLS) policies     │
│ - NestJS baseline with JwtAuthGuard, LgpdConsentGuard & RLS Interceptor     │
│ - Flutter project setup, Material 3 baseline, and Dio network client        │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: Triage Engine & Emergency Safety Net                               │
│ - Gemini 1.5 Flash AI Classifier with strict JSON schemas (19 categories)   │
│ - NestJS TriageModule implementing 5-step decision tree logic               │
│ - Zero-failure Level 4-5 Emergency Safety Net (Mobile red modal + API)     │
│ - Riverpod TriageStateMachine on Flutter client                             │
│ - Dynamic Theme Switcher (Soft Indigo #4F46E5 ↔ Clinical Teal #0D9488)      │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: Longitudinal Consistency Engine ("Antiburla") & Offline Sync       │
│ - PostgreSQL 14-day temporal composite B-Tree indices                       │
│ - Antiburla comparison heuristics in NestJS ConsistencyEngineService        │
│ - Empathetic clarification dialogs on Flutter client                        │
│ - Offline storage (Drift/SQLite) and Transactional Outbox Sync Worker       │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: Visualizations & Somatic Mapping                                   │
│ - Flutter 2D Anatomical Body Heat Map CustomPainter canvas                  │
│ - Normalized vector coordinate hit-testing across 12 anatomical systems     │
│ - Linear 7-day emotional trend graph across 7 psychological dimensions      │
│ - Somatic/Psychosomatic cross-mapping clinical visualization                │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: Decoupled Lab Exam Processing Pipeline                             │
│ - S3 / GCS presigned upload handler with SSE-KMS encryption                 │
│ - Redis BullMQ worker setup for asynchronous processing                     │
│ - OCR engine integration (AWS Textract / Cloud Vision)                      │
│ - Gemini 1.5 Flash token-efficient biomarker key-value extraction          │
│ - Firebase Cloud Messaging (FCM) notifications for completed lab exams      │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 6: Production Hardening, Compliance Audit & Latency Optimization      │
│ - Sub-2-second AI triage latency verification under load                    │
│ - Redis semantic cache tuning for common symptoms                           │
│ - LGPD Art. 11 & Art. 52 compliance audit trail verification                │
│ - Zero-failure emergency modal testing and E2E simulation                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Build Order Dependency Justification

1. **Phase 1 must precede Phase 2:** The AI Triage Engine cannot securely store symptom records without the PostgreSQL Row-Level Security policies and the tenant context interceptor configured in Phase 1.
2. **Phase 2 must precede Phase 3:** The 14-day Antiburla consistency engine requires that the core 5-step triage logging structure is already producing validated, structured symptom entries.
3. **Phase 3 must precede Phase 4:** The 2D Body Heat Map and 7-day emotional graphs rely on aggregated longitudinal historical data and offline sync mechanisms established in Phase 3.
4. **Phase 5 can run in parallel or after Phase 3/4:** The decoupled lab exam pipeline is an asynchronous subsystem that feeds into the existing patient medical profile once the primary triage and storage layers are stable.
5. **Phase 6 concludes the sequence:** Latency benchmarking, cache warm-up, and LGPD regulatory audits require all application components to be operational under realistic load.

---

## Sources

- [PostgreSQL Row-Level Security Official Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [Google Gemini API Structured Outputs with JSON Schema](https://ai.google.dev/gemini-api/docs/structured-outputs)
- [Flutter Riverpod 2.x Architecture Best Practices](https://riverpod.dev/docs/concepts/reading)
- [Brazilian General Data Protection Law (LGPD - Lei 13.709/2018, Art. 11 - Dados Sensíveis de Saúde)](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)
- [NestJS Architecture & Execution Context](https://docs.nestjs.com/fundamentals/execution-context)
- [BullMQ Redis Message Queueing & Job Processing Guide](https://docs.bullmq.io/)
- [Manchester Triage System (MTS) Emergency Protocols](https://www.triagenet.net/)

---
*Architecture research for: DualisCheckUp (Mobile Health Triage & Medical Tracking Platform)*  
*Researched: 2026-09-13*
