---
phase: "1"
slug: "backend-foundation-postgresql-rls-data-encryption"
status: verified
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-13"
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest 3.x + Supertest 7.x |
| **Config file** | `backend/vitest.config.ts`, `backend/vitest.config.e2e.ts` |
| **Quick run command** | `npm run test` (in backend directory) |
| **Full suite command** | `npm run verify:phase1` |
| **Estimated runtime** | ~8–12 seconds |

---

## Sampling Rate

- **After every task commit:** Run `npm run test`
- **After every plan wave:** Run `npm run verify:phase1`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | SEC-01 | T-01-01 | NestJS Fastify bootstrap and Drizzle schema initialize cleanly | unit | `npm run test` | ✅ | ✅ green |
| 01-01-02 | 01 | 1 | SEC-01 | T-01-02 | `DatabaseService.withRls` sets and resets `app.current_user_id` without pool contamination | integration | `npm run test:rls` | ✅ | ✅ green |
| 01-02-01 | 02 | 2 | SEC-02 | T-01-03 | AES-256-GCM encrypts/decrypts with unique 96-bit IVs and detects tampering | unit | `npm run test -- test/unit/encryption.service.spec.ts` | ✅ | ✅ green |
| 01-02-02 | 02 | 2 | DISC-01 | T-01-04 | GET /v1/legal/disclaimer returns Anvisa/CFM compliant disclaimer contract with security headers | e2e | `npm run test:e2e` | ✅ | ✅ green |
| 01-02-03 | 02 | 2 | SEC-01 | T-01-05 | User A cannot query, update, or delete User B records across 7 negative regression scenarios | security | `npm run test:rls` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `backend/test/unit/encryption.service.spec.ts` — AES-256-GCM unit test stubs
- [x] `backend/test/security/cross-tenant-rls.spec.ts` — 7 cross-tenant RLS regression test scenarios
- [x] `backend/test/e2e/legal-disclaimer.e2e-spec.ts` — Supertest E2E specs for disclaimer endpoint and Helmet headers
- [x] `backend/vitest.config.ts` & `backend/vitest.config.e2e.ts` — test configuration files
- [x] Dependencies install: `vitest`, `@vitest/coverage-v8`, `supertest`, `@types/supertest`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| TLS 1.3 Negotiation | SEC-02 | Requires remote TLS handshake inspector or OpenSSL CLI on live port | Run `openssl s_client -connect localhost:3000 -tls1_3` and verify cipher suite is TLS_AES_256_GCM_SHA384 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending 2026-09-13
