# Walking Skeleton — DualisCheckUp

**Phase:** 1
**Generated:** 2026-09-14

## Capability Proven End-to-End

A client can fetch the Brazilian regulatory medical disclaimer and emergency contacts via a hardened, TLS 1.3 / Helmet-secured NestJS Fastify HTTP endpoint while the backend executes multi-tenant clinical data transactions isolated by PostgreSQL Row-Level Security and protected by AES-256-GCM field-level encryption.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Backend Framework | NestJS 12 (`@nestjs/core`, `@nestjs/common`) | Enterprise modular architecture, dependency injection, and clean lifecycle hooks for database pool management. |
| HTTP Adapter | Fastify 5 (`@nestjs/platform-fastify`) | Minimal routing and serialization latency (<10ms), reserving critical latency headroom for the sub-2-second AI triage classification budget (RNF-001). |
| Data Layer | PostgreSQL 16/17 + Drizzle ORM 0.45.2 (`drizzle-orm`, `node-postgres`) | Thin type-safe SQL layer over `pg.Pool` with zero query engine binary overhead (<15ms cold start), native support for `set_config` transaction-scoped RLS injection, and cross-compatibility with Supabase and Google Cloud SQL. |
| Tenant Isolation | Engine-Level PostgreSQL RLS (`FORCE ROW LEVEL SECURITY`) | Native PostgreSQL database-engine row security enforced via `DatabaseService.withRls()` transaction runner (`SELECT set_config('app.current_user_id', :userId, true)`), eliminating connection-pool session bleeding and application-layer tenant leakage. |
| Data at Rest Encryption | AES-256-GCM (AEAD) with dynamic 96-bit IVs and 128-bit auth tags | Cryptographic field-level protection for sensitive health narratives under LGPD Art. 11, preventing unauthorized reading even in cases of raw DB dumps or log leaks. |
| Data Residency & Cloud Target | Supabase (`sa-east-1`) for Dev / Google Cloud SQL (`southamerica-east1`, São Paulo) for Prod | Zero-cost rapid developer iteration locally and in staging, with strict São Paulo geographic data residency for production LGPD Art. 11 compliance. |
| Transport Security | TLS 1.3 + Fastify Helmet (HSTS, CSP, X-Frame-Options: DENY) | Prevents cryptographic downgrade attacks, enforces strict HTTPS transport for 2 years, and guards mobile/web clients against clickjacking and MIME sniffing. |
| Test Runner | Vitest 3.x + Supertest 7.x | High-speed ESM-native test runner for in-memory unit tests, database RLS integration suites, and HTTP E2E checks. |

## Stack Touched in Phase 1

- [ ] Project scaffold (NestJS 12, Fastify 5, TypeScript 5.7, Drizzle ORM, Vitest, ESLint)
- [ ] Routing — `GET /v1/legal/disclaimer` (Anvisa RDC 657/2022 & CFM Resolução 2.314/2022 disclaimer and emergency escalation contacts localized for `pt-BR`, `es`, and `en`)
- [ ] Database — PostgreSQL Drizzle schema migration (`users`, `symptom_logs`, `user_disclaimer_consents`), RLS policies with `FORCE ROW LEVEL SECURITY`, and transaction-scoped `withRls` read/write execution
- [ ] Security & Hardening — AES-256-GCM field encryption service (`EncryptionService`), Fastify Helmet security headers, TLS 1.3 protocol enforcement
- [ ] Verification Suite — Automated cross-tenant negative security matrix (`npm run test:rls`), encryption unit specs (`npm run test`), and disclaimer E2E specs (`npm run test:e2e`)

## Out of Scope (Deferred to Later Slices)

- Flutter mobile client scaffold & Riverpod state management (Phase 2)
- Biometric authentication & FaceID auto-lock (Phase 2)
- Emergency Risk Alert screen UI with PopScope dismissal lock (Phase 3)
- 5-step dynamic triage wizard and 19-category taxonomy (Phase 4)
- Gemini 1.5 Flash sub-2-second AI natural language classification (Phase 5)
- AdMob native ad container (Phase 5)
- 14-day Antiburla temporal consistency bottom sheet (Phase 7)
- Offline SQLite Drift caching and transactional outbox synchronization (Phase 8)
- 2D Anatomical Body Map & Emotional Trend Graph (Phase 9)
- LGPD self-service data export and cascade account deletion (Phase 10)

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this skeleton without altering its architectural decisions:

- Phase 2: Onboarding & Identity (Screens 1 & 2) with Native Biometrics (`local_auth`) and Simplified Registration (RF-007)
- Phase 3: Emergency Risk Alert Screen (Screen 8 / RF-006) with zero-failure deterministic red-flag escalation
- Phase 4: Dynamic 5-Step Triage Wizard (Screen 4 / RF-002) with Teal ↔ Indigo dynamic theming
- Phase 5: Home & Unified Trigger Check-in (Screen 3 / RF-001) with sub-2s Gemini classification & AdMob container
- Phase 6: Triage Outcome, Somatic Mapping & Article Recommendations (Screen 6 / RF-004, RF-005)
- Phase 7: Antiburla Historical Verification Sheet (Screen 5 / RF-003, UC-01)
- Phase 8: Offline Caching & Outbox Synchronization (Drift SQLite)
- Phase 9: Historical Dashboard & 2D Body Heat Map (Screen 7 / RF-008)
- Phase 10: LGPD Data Sovereignty, Account Deletion & Production Verification (LGPD Art. 18)
