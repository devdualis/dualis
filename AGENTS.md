<!-- GSD:project-start source:PROJECT.md -->

## Project

**DualisCheckUp**

DualisCheckUp is a mobile preventive health platform that centralizes personal health management and medical history directly in the user's hands. It seamlessly integrates physical health tracking (across 12 anatomical systems) and psycho-emotional well-being (across 7 dimensions) into a unified, AI-powered preventive triage experience.

**Core Value:** Unified, safe, and clinically consistent daily health triage bridging somatic/physical symptoms and psycho-emotional states with immediate emergency escalation and 14-day anti-tampering historical verification.

### Constraints

- **Tech Stack**: Flutter + Riverpod (Mobile), NestJS + PostgreSQL (Supabase dev / Google Cloud SQL prod) + Redis (Backend) — Cross-platform efficiency and robust relational data management.
- **Performance**: Sub-2-second latency on AI triage classification.
- **Clinical Safety**: Zero-failure fail-safe trigger for Level 4/5 symptoms into emergency red screen.
- **Regulatory**: Full LGPD compliance for Brazilian users (regional data residency, strict RLS, encryption at rest and in transit).

<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->

## Technology Stack

## Executive Summary

- **Mobile Client:** Flutter 3.29+ / Dart 3.7+ with `flutter_riverpod` (v3.4.3), `go_router` (v18.0.1), `dio` (v5.11.1), `flutter_secure_storage` (v11.1.1), `fl_chart` (v1.2.0), `flutter_svg` (v2.3.0), and `drift` (v2.22.x) for offline SQLite outbox sync.
- **Backend Platform:** NestJS 12 (`@nestjs/core` v12.0.1) running on Node.js 22 LTS with the Fastify HTTP adapter for low routing overhead.
- **Data Tier:** PostgreSQL 16/17 with native Row-Level Security (`app.current_user_id`), `btree_gist` temporal range indexing for 14-day history queries, and Drizzle ORM (v0.45.2) as the primary type-safe SQL layer.
- **Asynchronous Task & Cache Tier:** Redis 7 with BullMQ (v6.3.4) and `@nestjs/bullmq` (v12.0.0) for background lab exam ingestion and response caching.
- **AI & Clinical Engine:** Google Gemini 1.5 Flash via the unified `@google/genai` (v2.22.0) SDK using strict JSON Schema structured outputs.
- **OCR Engine:** Google Cloud Vision API (`@google-cloud/vision` v6.1.0) / AWS Textract (`@aws-sdk/client-textract` v3.750.x) for high-accuracy Brazilian Portuguese medical typography extraction.

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Flutter SDK** | `3.29.x` (Dart `3.7.x`) | Cross-platform client framework (iOS & Android) | Delivers 60–120fps hardware-accelerated rendering on both iOS and Android from a single codebase. Native Canvas support enables high-performance 2D vector body mapping (`CustomPainter`), and Material 3 design tokens enable real-time palette tweening between Soft Indigo and Clinical Teal. |
| **flutter_riverpod** | `3.4.3` | Reactive state management & dependency injection | Unidirectional data flow with compile-time safety and zero `BuildContext` dependency. The `autoDispose` modifier guarantees automatic teardown of sensitive triage session memory when navigating away. Built-in `AsyncValue` eliminates boilerplate for loading/error/data states during AI triage. |
| **NestJS** | `12.0.1` (`@nestjs/core`) | Enterprise backend API platform | Structured, modular architecture (Dependency Injection, Guards, Interceptors, Pipes) enforcing clean separation between Triage, Antiburla, Lab Exams, and Emergency modules. First-class TypeScript support, built-in validation pipelines, and seamless microservice/queue integration. |
| **Node.js** | `22.x LTS` (Jod) | Server runtime environment | Long Term Support (LTS) through 2027. High-performance V8 engine with native fetch, optimized async local storage (crucial for PostgreSQL RLS tenant context propagation), and low memory overhead under containerized workloads. |
| **PostgreSQL** | `16.x` / `17.x` | Primary relational database with RLS & temporal support | Enterprise relational integrity with native Row-Level Security (RLS) to enforce user data isolation at the storage engine level (LGPD requirement). Supports `btree_gist` and temporal range queries (`tstzrange`) for sub-10ms 14-day Antiburla consistency scans. |
| **Drizzle ORM** | `0.45.2` | TypeScript-first SQL query builder & ORM | Operates as a thin type-safe abstraction over `pg`. Unlike heavy ORMs, Drizzle allows frictionless execution of PostgreSQL session variables (`SET LOCAL app.current_user_id = $1`), raw temporal operators, and GiST indexes without pinning pooled connections or incurring interactive transaction penalties. |
| **Redis** | `7.2.x` / Valkey `8.x` | Distributed cache, rate limiter & message broker | In-memory key-value store providing sub-millisecond retrieval for semantic query caching, user check-in rate limiting, and the Redis-backed BullMQ job queue. |
| **BullMQ** | `6.3.4` (`@nestjs/bullmq: 12.0.0`) | Distributed background job queue | Robust job queuing mechanism for decoupled lab exam OCR and LLM biomarker parsing. Provides exponential backoff, job deduplication, rate limiting, and progress tracking without locking HTTP worker threads. |
| **Google Gemini 1.5 Flash** | Model `gemini-1.5-flash` (`@google/genai: 2.22.0`) | Structured AI triage & symptom classification engine | Delivers sub-1200ms inference latency at fraction of the cost of frontier models. Native JSON Schema output enforcement guarantees 100% adherence to the 19-category clinical taxonomy and somatic mapping contracts without syntax errors. |
| **Google Cloud Vision / AWS Textract** | Cloud Vision `6.1.0` / Textract `3.750.x` | Decoupled OCR engine for lab reports | High-fidelity optical character recognition specialized in document layouts and tabular medical data. Isolates OCR from LLM reasoning, slashing token costs by 85% and preventing hallucinated biomarker numbers. |

### Supporting Libraries

#### Mobile Client (Flutter / Dart)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **riverpod_annotation** | `4.0.7` | Code-generation annotations for Riverpod | Used with `@riverpod` to generate clean, strongly typed providers and notifiers (`TriageNotifier`, `AuthNotifier`, `HeatMapNotifier`). |
| **go_router** | `18.0.1` | Declarative routing with deep linking & guards | Core navigation framework. Used for route redirection (redirecting unauthenticated users to login or triaging users to emergency red screen) and nested `ShellRoute` tabs. |
| **dio** | `5.11.1` | Advanced HTTP networking client | All REST API communication. Utilized for its interceptors (JWT injection, automatic 401 token refresh), request cancellation (cancelling stale AI triage calls), and upload progress tracking. |
| **flutter_secure_storage** | `11.1.1` | Keychain (iOS) & KeyStore/EncryptedSharedPreferences (Android) | Persisting sensitive authentication tokens (JWT access & refresh tokens) and biometric encryption keys. Never store plaintext credentials in `SharedPreferences`. |
| **fl_chart** | `1.2.0` | High-performance charting engine | Rendering the 7-day emotional trend dashboard across the 7 psycho-emotional dimensions. Supports touch tooltips, line smoothing, and custom grid styling. |
| **flutter_svg** | `2.3.0` | Scalable Vector Graphics rendering engine | Rendering 2D anatomical silhouette body maps. Maps 12 physical systems to vector paths with interactive hit-testing and chromatic color shaders. |
| **drift** | `2.22.x` | Type-safe SQLite persistence & migration engine | Local offline-first database. Stores drafted triage entries, recent offline check-in history, and an outbox queue for synchronization when network connectivity resumes. |
| **sqlite3_flutter_libs** | `0.5.x` | Native SQLite runtime binaries | Bundles updated SQLite C-libraries across iOS, Android, and macOS for Drift. |
| **freezed** | `4.0.1` | Immutable data classes and union types | Modeling 5-step triage decision tree nodes, immutable state objects, and sealed class hierarchy for API request/response contracts. |
| **freezed_annotation** | `4.0.1` | Annotations for Freezed code generation | Used on all domain entity and state classes. |
| **json_serializable** | `6.9.x` | Type-safe JSON serialization/deserialization | Generates `fromJson` and `toJson` methods for all network DTOs and Drift type converters. |
| **url_launcher** | `6.3.2` | Native OS URI scheme launcher | Immediate one-tap dialing for Level 4–5 emergency safety triggers (`tel:192` for Brazilian SAMU, `tel:190` for Police, `tel:188` for CVV mental health). |
| **image_picker** | `1.2.3` | Camera & photo gallery selection | Capturing high-resolution smartphone photos of printed physical laboratory exam results. |
| **file_picker** | `12.3.0` | Native file system document selector | Selecting PDF laboratory reports from device storage or cloud drives. |
| **google_fonts** | `8.2.1` | Runtime & bundled Material 3 typography | Provides modern, accessible clinical typography (e.g., Plus Jakarta Sans or Inter) supporting clear readability in stressful triage scenarios. |
| **intl** | `0.20.2` | Internationalization & date/number formatting | Formatting Brazilian Portuguese currency, dates (`dd/MM/yyyy`), and clinical measurement units. |
| **connectivity_plus** | `6.1.x` | Device network connectivity monitoring | Listening to cellular/Wi-Fi status to trigger outbox sync and toggle offline banners. |

#### Backend (NestJS / TypeScript)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **@nestjs/platform-fastify** | `12.0.1` | High-throughput Fastify HTTP adapter | HTTP routing engine replacing Express. Reduces internal framework latency to <10ms, preserving critical headroom for the sub-2s triage SLA. |
| **@google/genai** | `2.22.0` | Official unified Google Gen AI SDK | Primary AI SDK for invoking Gemini 1.5 Flash with strict `responseSchema` (JSON Schema) structured outputs. |
| **@google-cloud/vision** | `6.1.0` | Google Cloud Vision API Node.js client | High-accuracy OCR pipeline. Extracts raw text, coordinate blocks, and tabular data from uploaded lab photos/PDFs. |
| **@aws-sdk/client-s3** | `3.750.x` | AWS S3 / Cloud Storage SDK | Managing private object storage buckets holding encrypted medical lab files and user avatars. |
| **@aws-sdk/s3-request-presigner** | `3.750.x` | S3 Presigned URL generation | Generating short-lived (15-minute) presigned PUT/GET URLs so mobile clients upload documents directly to S3 without piping large binary files through the NestJS server. |
| **ioredis** | `6.0.0` | Resilient Redis client for Node.js | Direct connection to Redis cluster for caching, rate limiting, and Antiburla temporal locks. |
| **pg** | `8.13.x` | PostgreSQL client driver | Underlying database driver used by Drizzle ORM to manage connection pooling and transaction lifecycle. |
| **zod** | `4.6.4` | TypeScript-first schema validation | Validating runtime environment configuration and defining structured output schemas shared with the Gemini AI engine. |
| **class-validator** | `0.14.x` | Decorator-based DTO validation | Validating incoming HTTP payloads in NestJS controllers via `ValidationPipe`. |
| **class-transformer** | `0.5.x` | Object serialization and transformation | Transforming raw JSON request bodies into strongly typed DTO classes. |
| **argon2** | `0.41.x` | State-of-the-art password hashing | Password hashing winning the Password Hashing Competition (PHC). Resistant to GPU/ASIC brute-force cracking. |
| **@nestjs/jwt** | `12.0.x` | JWT signing and verification | Generating short-lived access tokens (15m) and persistent refresh tokens (7d). |
| **@nestjs/passport** | `12.0.x` | Passport authentication integration | Guarding endpoints via `JwtStrategy` and `LocalStrategy`. |
| **passport-jwt** | `4.0.x` | Passport strategy for authenticating with a JSON Web Token | Extracts Bearer tokens from authorization headers and validates cryptographic signatures. |
| **helmet** | `8.0.x` | HTTP security headers middleware | Securing Express/Fastify headers against XSS, clickjacking, and MIME sniffing attacks. |
| **@nestjs/throttler** | `6.4.x` | Rate limiting guard with Redis storage | Preventing brute-force attacks on auth routes and protecting AI triage endpoints from quota exhaustion. |
| **date-fns** | `4.1.x` | Modular date utility library | Performing temporal math for the 14-day rolling window in the Antiburla consistency algorithm. |
| **nestjs-pino** | `4.3.x` | High-performance structured JSON logging | Logging requests and system events with automatic PII/PHI redaction to comply with LGPD. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| **Flutter Build Runner (`build_runner`)** | Code generator orchestrator | Generates Riverpod providers (`riverpod_generator`), Freezed unions, and JSON serializers. Run with `dart run build_runner watch --delete-conflicting-outputs`. |
| **drizzle-kit** (`0.30.x`) | Migration generator and database visualizer | Generates SQL migrations from TypeScript schema files and provides `drizzle-kit studio` for local database inspection. |
| **Docker & Docker Compose** | Local development environment parity | Spins up local PostgreSQL 16 (with `btree_gist`), Redis 7, and LocalStack (mock S3) in isolated containers. |
| **Vitest** (`3.x`) | Ultra-fast unit & integration test runner | Unit testing NestJS business logic, Antiburla sliding window logic, and clinical rule engines with sub-second feedback loops. |
| **Supertest** (`7.x`) | HTTP integration testing | End-to-end testing of NestJS API endpoints, verifying RLS user isolation and emergency exception filters. |
| **Mocktail** (`1.0.x`) | Dart null-safe mocking library | Mocking Dio network calls, Riverpod providers, and hardware secure storage in Flutter unit tests without code generation. |

## Installation

### Mobile Client (Flutter `pubspec.yaml`)

### Backend Platform (NestJS `package.json`)

# Core NestJS & Fastify Platform

# Database Layer (Drizzle ORM + PostgreSQL Driver)

# Redis & Background Queue (BullMQ)

# AI & Document Processing

# Security, Auth & Utilities

# Development & Testing Dependencies

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| **Drizzle ORM (0.45.2)** | **Prisma Client (7.10.0)** | Use Prisma if the team prioritizes automated schema-first migrations and Prisma Studio visual tools over advanced PostgreSQL features. **Trade-off:** Prisma requires interactive transactions (`$transaction`) to execute `SET LOCAL app.current_user_id = $1` for Row-Level Security, which holds dedicated pooled connections and increases connection contention under high check-in load. Drizzle executes RLS session context natively without transaction penalties. |
| **Drizzle ORM (0.45.2)** | **TypeORM (0.3.x)** | Avoid for greenfield. Only use if migrating an existing legacy codebase already bound to TypeORM entities. TypeORM has significant maintenance lag, brittle migration generation, and poor TypeScript type inference compared to modern alternatives. |
| **Google Gemini 1.5 Flash** | **OpenAI GPT-4o-mini** | Use GPT-4o-mini if company infrastructure is already committed to Microsoft Azure OpenAI Service. Both models support strict JSON Schema structured outputs with sub-2s latency. Gemini 1.5 Flash is recommended due to superior multilingual medical terminology handling (Brazilian Portuguese), lower input token pricing, and native multimodal document capabilities for secondary verification. |
| **Decoupled OCR (Cloud Vision / Textract) + LLM** | **Direct Multimodal LLM (End-to-End)** | Use Direct Multimodal LLM only for quick prototyping or single-page unstructured receipts. For medical lab exams (5+ page PDFs with dense numerical tables, reference intervals, and tiny fonts), direct multimodal input causes hallucinated decimal values, costs 6x–10x more in multimodal image tokens, and exhibits 15–30s latencies that break mobile UX. |
| **Fastify (`@nestjs/platform-fastify`)** | **Express (`@nestjs/platform-express`)** | Use Express if the team relies on niche third-party Express middlewares that have no Fastify equivalent. Fastify handles 2x–3x more requests per second with 40% lower P99 response times, preserving critical headroom for the sub-2s AI triage SLA. |
| **Drift (SQLite)** | **Hive CE / Isar / SharedPreferences** | Use SharedPreferences only for simple non-sensitive UI settings (e.g., theme toggle). Use Drift for clinical data because healthcare records require relational integrity, ACID transactions, atomic updates, and indexing. Key-value stores like Hive lack relational constraints and cannot query past triage logs efficiently offline. |
| **Riverpod (3.4.3)** | **flutter_bloc (9.x)** | Use BLoC if the mobile team has deep existing enterprise BLoC conventions. Riverpod 3 is recommended for DualisCheckUp because its code generation (`@riverpod`) drastically reduces boilerplate, provider scoping is trivial, and `autoDispose` naturally solves the cleanup of sensitive health triage sessions when screens unmount. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Direct End-to-End Multimodal LLM for Lab Exams** | Feeding raw multi-page lab PDFs directly into a vision LLM costs $0.05–$0.15 per exam in token fees, frequently hallucinates vital decimal places in lab numbers (e.g., reads `0.8` as `8.0` or swaps reference intervals), and takes 15–30 seconds to complete. | **Decoupled OCR + LLM Pipeline:** Extract high-resolution text and tables via Google Cloud Vision / Textract, then pass clean structured text to Gemini 1.5 Flash for biomarker JSON extraction. |
| **Unconstrained LLM Prompts for Triage** | Prompting an LLM with free-form text ("Decide if this is an emergency and return your advice") yields unpredictable JSON, markdown formatting tags, and probabilistic variations that bypass clinical safety rules. | **Strict JSON Schema (`responseSchema`) with Deterministic Safety Gates:** Enforce valid schemas at the API level and intercept emergency keywords with hardcoded deterministic rules before prompting the LLM. |
| **TypeORM in 2026** | Suffers from architectural stagnation, slow ESM adoption, complex entity decoration bugs, and difficult integration with PostgreSQL Row-Level Security session context. | **Drizzle ORM (0.45.x):** Zero-overhead SQL-like TypeScript syntax with native RLS parameter injection. |
| **Prisma Interactive Transactions for Every Read** | In Prisma, enforcing RLS requires wrapping every query in `prisma.$transaction(async (tx) => { await tx.$executeRaw\`SET LOCAL...\`; return tx.triage.findMany(); })`. Under high concurrent load, this exhausts connection pools because each interactive transaction holds an open connection. | **Drizzle ORM with Client Session Middleware:** Sets connection session variables cleanly or utilizes Supabase/PostgREST-style query wrappers. |
| **GetX for State Management** | Global service locator anti-pattern with mutable global state, lack of compile-time dependency safety, and unpredictable memory leaks when disposing triage sessions. | **flutter_riverpod (3.4.3):** Immutable state, compile-time safety, declarative UI binding, and automatic lifecycle management via `autoDispose`. |
| **SharedPreferences for Medical Logs / Tokens** | Stores unencrypted XML/plist files on disk; easily inspected on rooted/jailbroken devices, violating Brazilian LGPD compliance standards for sensitive health data. | **flutter_secure_storage (11.1.1):** Hardware-backed Keychain (iOS) and KeyStore/EncryptedSharedPreferences (Android). |
| **Client-Side Direct Supabase/Firebase Access for Triage** | Calling database tables directly from the mobile client bypasses the centralized deterministic clinical safety net and prevents the backend Antiburla temporal scanning engine from validating claims before persistence. | **NestJS Mediated Backend:** All triage submissions flow through authenticated NestJS endpoints guarded by deterministic emergency rules and LGPD audit logs. |

## Stack Patterns by Variant

### Deployment & Infrastructure Variant

- **Hosting:** Google Cloud Run (Fully managed serverless containers for NestJS API).
- **Database:** Google Cloud SQL for PostgreSQL (São Paulo region `southamerica-east1`).
- **Cache & Queue:** Google Cloud Memorystore for Redis.
- **Storage:** Google Cloud Storage (GCS) with CMEK (Customer-Managed Encryption Keys).
- **OCR:** Google Cloud Vision API native VPC integration.
- **AI:** Google Vertex AI Gemini 1.5 Flash endpoint (`southamerica-east1` / `us-east4`).
- **Rationale:** Minimizes network hops and egress costs between NestJS, Cloud Vision, and Gemini. Ensures full compliance with Brazilian data residency laws.
- **Hosting:** AWS ECS Fargate or AWS App Runner in São Paulo (`sa-east-1`).
- **Database:** Amazon RDS for PostgreSQL (Multi-AZ, `sa-east-1`).
- **Cache & Queue:** Amazon ElastiCache for Redis (Valkey).
- **Storage:** Amazon S3 with SSE-KMS in São Paulo.
- **OCR:** AWS Textract with `TABLES` and `FORMS` feature extraction.
- **AI:** Amazon Bedrock (or direct Gemini 1.5 Flash API via Google Cloud interconnect).
- **Rationale:** Ideal if the engineering organization is standardized on AWS IAM, CloudWatch, and KMS encryption infrastructure.

### Network Resilience Variant

- **Local Cache:** Drift (SQLite) stores active triage drafts and the patient's last 14 days of historical logs locally.
- **Outbox Pattern:** Submitting a triage session while offline persists the record in an internal `triage_outbox` table with status `PENDING_SYNC`.
- **Background Sync:** `connectivity_plus` detects internet restoration and triggers Riverpod's `SyncOutboxNotifier` to upload pending records in chronological order.
- **Offline Clinical Gate:** If the user logs Level 4–5 red-flag symptoms while offline, the app **does not wait for backend sync**. It immediately triggers the hardcoded local emergency modal and prompts the user to dial `192` (SAMU) natively.

## Version Compatibility Matrix

| Package / Tool | Version | Compatible Ecosystem | Critical Notes |
|----------------|---------|----------------------|----------------|
| **Flutter SDK** | `3.29.x` | Dart `>=3.7.0 <4.0.0` | Requires Xcode 16+ on macOS and Android SDK 35 (compileSdk 35). Full Material 3 support. |
| **flutter_riverpod** | `3.4.3` | `riverpod_annotation: 4.0.7`, `riverpod_generator: 2.6.x` | Riverpod 3 unified syntax. Uses `Ref` and `@riverpod` annotations. Deprecates old StateNotifier syntax in favor of `AsyncNotifier`. |
| **go_router** | `18.0.1` | Flutter `>=3.27.0` | Uses modern `ShellRoute` and `StatefulShellRoute` for dual-vertical bottom navigation. Fully compatible with Riverpod `refreshListenable`. |
| **fl_chart** | `1.2.0` | Flutter `>=3.24.0` | Major release with improved render performance and canvas clip-path optimizations for smooth 60fps graph animations. |
| **Node.js** | `22.x LTS` | NestJS `12.x`, `@google/genai: 2.22.x` | Requires `node:crypto` and native `fetch`. Do not use Node 18 (End of Life). |
| **@nestjs/core** | `12.0.1` | TypeScript `^5.7.0`, Fastify `^5.0.0` | Fastify 5 adapter requires `@nestjs/platform-fastify: 12.0.1`. |
| **drizzle-orm** | `0.45.2` | `drizzle-kit: 0.30.5`, `pg: ^8.13.0` | Full support for PostgreSQL 16/17 range types (`tstzrange`) and GiST index definitions. |
| **bullmq** | `6.3.4` | `@nestjs/bullmq: 12.0.0`, `ioredis: ^6.0.0` | BullMQ 6 requires Redis 6.2+ (Redis 7 recommended). Uses Redis Streams and atomic Lua scripts. |
| **@google/genai** | `2.22.0` | Node `>=20.0.0` | The official unified Google Gen AI SDK replacing legacy `@google/generative-ai`. Supports Gemini 1.5 Flash and Gemini 2.0. |
| **@google-cloud/vision**| `6.1.0` | Node `>=22.0.0` | Strict Node 22 engine requirement. Provides optimized gRPC bindings for document OCR. |

## Quality Gate & Verification Evidence

## Sources

- [pub.dev Official Package Registry](https://pub.dev) — Verified live versions for `flutter_riverpod`, `go_router`, `dio`, `fl_chart`, `flutter_secure_storage`, `freezed`, `drift`, `flutter_svg`, `url_launcher`, `file_picker`, `image_picker`.
- [npm Official Package Registry via jsDelivr CDN](https://cdn.jsdelivr.net) — Verified live releases for `@nestjs/core`, `@nestjs/bullmq`, `bullmq`, `ioredis`, `drizzle-orm`, `@prisma/client`, `@google/genai`, `@google-cloud/vision`, `zod`.
- [Google Gen AI SDK Documentation](https://ai.google.dev/gemini-api/docs/sdks) — Verified migration to unified `@google/genai` SDK and structured JSON Schema capabilities for Gemini 1.5 Flash.
- [PostgreSQL Documentation on Row-Level Security & GiST](https://www.postgresql.org/docs/current/ddl-rowsecurity.html) — Verified `current_setting('app.current_user_id', true)` and `btree_gist` index behaviors for temporal anti-tampering scans.
- [Drizzle ORM Documentation](https://orm.drizzle.team) — Verified PostgreSQL RLS session integration, range types, and GiST index support.
- [Brazilian General Data Protection Law (LGPD - Lei 13.709/2018)](https://www.gov.br/anpd/pt-br) — Verified sensitive health data residency, encryption, and patient isolation standards.

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
