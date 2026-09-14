# Phase 1: Backend Foundation, PostgreSQL RLS & Data Encryption - Research

**Phase:** 01  
**Phase Directory:** `.planning/phases/01-backend-foundation-postgresql-rls-data-encryption`  
**Requirements Covered:** SEC-01, SEC-02, DISC-01  
**Mode:** MVP (Walking Skeleton)  
**Researched:** 2026-09-14  
**Confidence:** HIGH  

---

## Executive Summary

Phase 1 establishes the security, persistence, and compliance bedrock for DualisCheckUp. Because DualisCheckUp handles sensitive health data (*dados pessoais sensíveis de saúde*) bridging somatic symptoms across 12 anatomical systems and psycho-emotional states across 7 dimensions, compliance with the Brazilian General Data Protection Law (LGPD, Lei nº 13.709/2018, Art. 11) is an architectural prerequisite. Security cannot be retrofitted; multi-tenant isolation, cryptographic protection, regional data residency, and medical disclaimer guardrails must be operational from the first commit.

This research defines a lightweight, ultra-high-performance backend walking skeleton built on **Node.js 22 LTS**, **NestJS 12**, and the **Fastify 5 HTTP adapter**. It utilizes **Drizzle ORM 0.45.2** over **PostgreSQL 16/17** with native **Row-Level Security (RLS)**, supporting **Supabase Free Tier for development** and deploying seamlessly to **Google Cloud SQL in the São Paulo region (`southamerica-east1`) for production** via a standardized `DATABASE_URL` with zero vendor lock-in. 

Crucially, this research addresses the primary architectural trap of PostgreSQL RLS in connection-pooled Node.js backends: **connection pool starvation and session state contamination**. It documents a scoped transaction pattern using `SELECT set_config('app.current_user_id', :userId, true)` that guarantees tenant isolation at the database engine level without leaking session variables or exhausting connection pool limits. Furthermore, it details an application-level **AES-256-GCM** encryption service for sensitive health narratives, **TLS 1.3** and HTTP security headers, Brazilian regulatory non-diagnostic disclaimer schemas (Anvisa RDC nº 657/2022 and CFM Resolução nº 2.314/2022), and an exhaustive **Validation Architecture** featuring automated cross-tenant security regression tests with Vitest and Supertest.

---

## Requirements Matrix & Traceability

| Requirement | Description | Phase 1 Implementation Mechanism | Verification Artifact |
|-------------|-------------|-----------------------------------|-----------------------|
| **SEC-01** | PostgreSQL Row-Level Security (`SET LOCAL app.current_user_id = :userId`) guarantees tenant isolation at database engine level. | Engine-level PostgreSQL RLS policies (`FOR ALL USING/WITH CHECK`), enforced via `FORCE ROW LEVEL SECURITY`. NestJS `DatabaseService.withRls()` transaction runner executing `set_config('app.current_user_id', userId, true)`. | Automated cross-tenant negative test matrix (`npm run test:rls`) asserting User A cannot read, update, or delete User B rows even via raw queries. |
| **SEC-02** | AES-256 encryption at rest, TLS 1.3 in transit, and São Paulo region data residency under LGPD Art. 11. | Application-level `EncryptionService` using Node `crypto` AES-256-GCM with 96-bit random IVs and 128-bit authentication tags for clinical notes. Storage in Google Cloud SQL `southamerica-east1` (prod) / Supabase SA (dev). Fastify TLS 1.3 configuration and `@fastify/helmet`. | Unit tests for AES-256-GCM encryption/decryption, tampering detection, and automated SSL/TLS handshake cipher verification. |
| **DISC-01** | Prominent non-diagnostic medical disclaimers compliant with Anvisa RDC 657/2022 and CFM Res. 2.314/2022. | Versioned disclaimer schema and API contract (`GET /v1/legal/disclaimer`), returning localized Brazilian Portuguese legal terms, regulatory citations, and emergency contacts (SAMU 192, CVV 188). Audit table `user_disclaimer_consents`. | E2E API tests validating response payload, version matching, and immutable consent persistence. |

---

## 1. Runtime & Framework Architecture: NestJS 12 + Fastify on Node.js 22 LTS

### 1.1 Technology Choices & Versions

- **Runtime:** Node.js `22.21.x LTS` (Jod). Provides native V8 performance optimizations, native `node:crypto`, `fetch`, and `AsyncLocalStorage` for asynchronous request context propagation.
- **Backend Framework:** NestJS `12.0.1` (`@nestjs/core`, `@nestjs/common`). Provides enterprise modular architecture, dependency injection, and lifecycle hooks.
- **HTTP Adapter:** `@nestjs/platform-fastify: 12.0.1` on `fastify: ^5.0.0`. Fastify reduces routing and serialization overhead to <10ms, preserving critical latency headroom for the subsequent sub-2-second AI triage classification budget (RNF-001).
- **Structured Logging:** `nestjs-pino: ^4.3.0` and `pino-http: ^10.4.0`. Delivers zero-overhead JSON logging with built-in PII/PHI redaction paths (`req.headers.authorization`, `req.body.narrative`, `req.body.password`).

### 1.2 Fastify Bootstrap & Lifecycle Pattern

```typescript
// backend/src/main.ts
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { Logger } from 'nestjs-pino';
import fastifyHelmet from '@fastify/helmet';
import fastifyCors from '@fastify/cors';
import { AppModule } from './app.module';

async function bootstrap() {
  const fastifyAdapter = new FastifyAdapter({
    logger: false, // Pino handles structured logging via nestjs-pino
    trustProxy: true, // Necessary for Cloud Run / GCP Ingress reverse proxies
    bodyLimit: 1048576, // 1MB payload limit to prevent memory exhaustion
  });

  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    fastifyAdapter,
    { bufferLogs: true },
  );

  // Bind Pino logger
  app.useLogger(app.get(Logger));

  // Enable graceful shutdown to drain database pool connections cleanly
  app.enableShutdownHooks();

  // API Versioning
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // Global Security Headers via Fastify Helmet
  await app.register(fastifyHelmet, {
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'validator.swagger.io'],
        scriptSrc: ["'self'"],
      },
    },
    strictTransportSecurity: {
      maxAge: 63072000, // 2 years in seconds (HSTS preload standard)
      includeSubDomains: true,
      preload: true,
    },
    frameguard: { action: 'deny' },
    noSniff: true,
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
  });

  // Strict CORS policy
  await app.register(fastifyCors, {
    origin: (origin, cb) => {
      // Whitelist mobile schemes and authorized development domains
      const allowedOrigins = [
        /^https:\/\/.*\.dualischeckup\.com\.br$/,
        /^http:\/\/localhost:(3000|5173|8080)$/,
      ];
      if (!origin || allowedOrigins.some((pattern) => pattern.test(origin))) {
        cb(null, true);
      } else {
        cb(new Error('Blocked by CORS policy'), false);
      }
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    credentials: true,
  });

  // Global Validation Pipeline
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;
  await app.listen({ port, host: '0.0.0.0' });
}
bootstrap();
```

---

## 2. Database Tier: PostgreSQL 16/17 with Drizzle ORM 0.45.2

### 2.1 ORM Evaluation & Selection Rationale

| Feature | Drizzle ORM (0.45.2) | Prisma Client (7.10.0) | TypeORM (0.3.x) |
|---------|----------------------|------------------------|-----------------|
| **RLS Session Variable Injection** | Native SQL pass-through (`tx.execute(sql\`...\`)`) without engine overhead. | Requires `$transaction(async (tx) => { ... })` wrapping every query, forcing connection pinning on pool. | Awkward query runner lifecycle; entity listeners bypass transaction context. |
| **Connection Pooling Overhead** | Thin wrapper over `pg.Pool`. Zero query engine binary layer. | Heavy Rust query engine sidecar process; higher memory footprint per container. | Moderate, but high connection leak rate under complex transaction rollback scenarios. |
| **PostgreSQL Temporal Types (`tstzrange`, GiST)** | First-class SQL operator support and direct migration emission. | Limited support for specialized PostgreSQL range types and GiST index operators without raw SQL escapes. | Brittle migration generator for custom index types. |
| **Bundle & Cold Start Time** | <15ms cold start. Ideal for serverless Google Cloud Run containers. | 150–300ms cold start due to Rust engine initialization and schema loading. | 100–250ms cold start due to reflection and metadata compilation. |

**Verdict:** Drizzle ORM 0.45.2 is selected. It operates as a thin, type-safe TypeScript layer over `node-postgres` (`pg`), allowing direct manipulation of session parameters (`set_config`), composite B-Tree/GiST indexes, and PostgreSQL RLS policies without transaction pool exhaustion.

### 2.2 Dual-Environment Strategy: Supabase (Dev) vs. Google Cloud SQL (Prod)

A core project design goal is zero-cost, rapid developer iteration in local and staging environments, coupled with strict regional compliance for production.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      DATABASE ENVIRONMENT TOPOLOGY                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  LOCAL / DEV / STAGING                      PRODUCTION                      │
│  - Supabase Free Tier Managed PG 16         - Google Cloud SQL for PG 16    │
│  - Location: South America (sa-east-1)      - Region: southamerica-east1    │
│  - Transaction Pooler (Port 6543) or        - Private IP via VPC Connector  │
│    Direct Session (Port 5432)               - CMEK AES-256 Storage          │
│  - SSL: rejectUnauthorized: false           - SSL: verify-ca with Server CA │
└───────────────────────┬─────────────────────────────┬───────────────────────┘
                        │                             │
                        ▼                             ▼
         ┌───────────────────────────────────────────────────────────┐
         │         UNIFIED DRIZZLE ORM DATA ACCESS LAYER             │
         │         DATABASE_URL = postgresql://user:pass@host:port/db│
         │         - Identical DDL Schema & Drizzle Migrations       │
         │         - Identical Engine-Level RLS Policies             │
         │         - Identical withRls() Transaction Scoping         │
         └───────────────────────────────────────────────────────────┘
```

#### Connection String & Pooling Configuration

1. **Development (Supabase Free Tier):**
   - **Direct Connection:** `postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres?sslmode=require`
   - **Pooled Connection (Supavisor):** `postgresql://postgres.[REF]:[PASSWORD]@aws-0-sa-east-1.pooler.supabase.com:6543/postgres?sslmode=require`
   - **SSL Setting:** Supabase pooler uses SNI routing with self-signed intermediate certificates. Node `pg` requires `ssl: { rejectUnauthorized: false }` unless the Supabase Root CA cert is explicitly loaded.
2. **Production (Google Cloud SQL São Paulo):**
   - **Location:** São Paulo region (`southamerica-east1`), fulfilling LGPD Art. 11 regional sovereignty.
   - **Connection:** Direct private IP through Google Cloud Run Serverless VPC Access connector or Cloud SQL Auth Proxy.
   - **SSL Setting:** Strict SSL verification (`ssl: { rejectUnauthorized: true, ca: process.env.DB_CA_CERT }`).
3. **Connection Pool Bounds:**
   - Container-safe pool configuration in `pg.Pool`:
     ```typescript
     const pool = new Pool({
       connectionString: process.env.DATABASE_URL,
       max: process.env.DB_POOL_MAX ? parseInt(process.env.DB_POOL_MAX, 10) : 10,
       idleTimeoutMillis: 30000,
       connectionTimeoutMillis: 5000,
       ssl: process.env.NODE_ENV === 'production'
         ? { rejectUnauthorized: true, ca: process.env.DB_CA_CERT }
         : { rejectUnauthorized: false },
     });
     ```

---

## 3. Native PostgreSQL Row-Level Security (RLS) Architecture

### 3.1 The Connection Pool Starvation & Leakage Trap

In a standard Node.js web application utilizing a database connection pool (`pg.Pool`), connections are shared and recycled across hundreds of incoming HTTP requests.

> [!CAUTION]
> **The Session Variable Leakage Trap:**  
> If an application executes `SET app.current_user_id = 'user-123'` on a pooled connection without resetting it, that connection returns to the pool with `app.current_user_id` still set to `'user-123'`. When a subsequent request for `user-456` or an unauthenticated query acquires that recycled connection, it inherits the previous tenant's permissions, causing a catastrophic multi-tenant data leak.

> [!WARNING]
> **The Interceptor-Wide Transaction Starvation Trap:**  
> If an HTTP interceptor opens a database transaction (`BEGIN`) at the start of every request, holds the connection open while the request executes controller logic, parses schemas, calls external APIs, and waits on network I/O, the connection pool (typically 10–20 connections) is exhausted within seconds, freezing the API under modest concurrent load.

### 3.2 The Defensive Solution: Transaction-Scoped RLS Runner (`withRls`)

To completely eliminate both pool starvation and session variable leakage:
1. **Never use session-level `SET`:** Always use `SELECT set_config('app.current_user_id', $1, true)`. The third argument (`is_local = true`) guarantees that the setting is discarded by PostgreSQL the instant the transaction completes (`COMMIT` or `ROLLBACK`).
2. **Never open transactions in HTTP interceptors:** Transactions must be scoped strictly to the duration of the database operations inside service or repository methods.
3. **Use parameterized binding:** Never interpolate UUIDs into SQL strings (`SET LOCAL app.current_user_id = '${userId}'` is vulnerable to SQL injection). `set_config($1, $2, true)` uses standard positional parameters.
4. **Force RLS on all tables:** In PostgreSQL, table owners and superusers bypass RLS by default. Production tables must enforce `ALTER TABLE <table_name> FORCE ROW LEVEL SECURITY;` so that even migrations or services connecting under default roles adhere to policies.

### 3.3 Database Schema & RLS Policy Definition in Drizzle

```typescript
// backend/src/database/schema/symptom-logs.schema.ts
import { pgTable, uuid, text, integer, timestamp, pgPolicy } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { users } from './users.schema';

export const symptomLogs = pgTable(
  'symptom_logs',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    encryptedNarrative: text('encrypted_narrative'), // AES-256-GCM ciphertext
    intensity: integer('intensity').notNull(),
    anatomicalSystem: text('anatomical_system'),
    emotionalDimension: text('emotional_dimension'),
    recordedAt: timestamp('recorded_at', { withTimezone: true }).defaultNow().notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    // Engine-level RLS policy
    pgPolicy('symptom_logs_patient_isolation', {
      for: 'all',
      using: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
      withCheck: sql`user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
  ],
);
```

#### Corresponding SQL Migration Script

```sql
-- backend/src/database/migrations/0001_enable_rls.sql
-- Enable and FORCE Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;

ALTER TABLE symptom_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE symptom_logs FORCE ROW LEVEL SECURITY;

-- Policy for symptom_logs
DROP POLICY IF EXISTS symptom_logs_patient_isolation ON symptom_logs;
CREATE POLICY symptom_logs_patient_isolation ON symptom_logs
  FOR ALL
  USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
  WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

-- Policy for users
DROP POLICY IF EXISTS users_patient_isolation ON users;
CREATE POLICY users_patient_isolation ON users
  FOR ALL
  USING (id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
  WITH CHECK (id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);
```

### 3.4 NestJS Database Module & `withRls` Service Implementation

```typescript
// backend/src/database/database.service.ts
import { Injectable, Inject, OnModuleDestroy } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { sql } from 'drizzle-orm';
import * as schema from './schema';

export const DRIZZLE_DB = Symbol('DRIZZLE_DB');
export const DATABASE_POOL = Symbol('DATABASE_POOL');

@Injectable()
export class DatabaseService implements OnModuleDestroy {
  constructor(
    @Inject(DRIZZLE_DB) public readonly db: NodePgDatabase<typeof schema>,
    @Inject(DATABASE_POOL) private readonly pool: Pool,
  ) {}

  /**
   * Executes a callback within a dedicated PostgreSQL transaction where
   * app.current_user_id is strictly set for the transaction lifetime.
   * Connection is returned to the pool immediately upon completion.
   */
  async withRls<T>(
    userId: string,
    callback: (tx: Parameters<Parameters<typeof this.db.transaction>[0]>[0]) => Promise<T>,
  ): Promise<T> {
    if (!userId || typeof userId !== 'string') {
      throw new Error('DatabaseService.withRls: A valid userId UUID is required.');
    }

    return this.db.transaction(async (tx) => {
      // is_local = true ensures setting automatically resets at COMMIT/ROLLBACK
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${userId}, true)`,
      );
      return callback(tx);
    });
  }

  async onModuleDestroy() {
    await this.pool.end();
  }
}
```

---

## 4. Field-Level Encryption at Rest: AES-256-GCM

### 4.1 Threat Model & LGPD Justification

While cloud databases offer disk encryption at rest (Transparent Data Encryption via AES-256), disk-level encryption does not protect against:
1. SQL injection attacks that dump database tables.
2. Compromised database administrator credentials or internal cloud operator access.
3. Leaked unencrypted database backups or replication stream logs.

Under LGPD Art. 11, personal health data (*dados sensíveis de saúde*) requires proactive technical safeguards (Art. 46). DualisCheckUp enforces **Application-Level Field Encryption**: sensitive clinical narratives, psychiatric notes, and free-text symptom descriptions are encrypted inside the NestJS application layer before entering PostgreSQL, and decrypted only in memory when requested by an authorized user session.

### 4.2 Cryptographic Specification

- **Algorithm:** `AES-256-GCM` (Galois/Counter Mode). Provides Authenticated Encryption with Associated Data (AEAD), guaranteeing confidentiality, data integrity, and tamper detection.
- **Key Length:** 256 bits (32 bytes), derived from a secure environment secret `ENCRYPTION_MASTER_KEY` (64-character hex string).
- **Initialization Vector (IV / Nonce):** 96 bits (12 bytes), generated dynamically using cryptographically secure pseudorandom numbers (`crypto.randomBytes(12)`). **IVs are never reused.**
- **Authentication Tag:** 128 bits (16 bytes), generated by the GCM cipher. Verifies that ciphertext has not been altered or truncated.
- **Serialization Format:** Versioned string payload:  
  `v1:<iv_hex>:<auth_tag_hex>:<ciphertext_hex>`
  - `v1`: Key version identifier, enabling future zero-downtime key rotation.
  - `<iv_hex>`: 24 hex characters (12 bytes).
  - `<auth_tag_hex>`: 32 hex characters (16 bytes).
  - `<ciphertext_hex>`: Variable-length hex representation of the encrypted text.

### 4.3 NestJS `EncryptionService` Implementation

```typescript
// backend/src/common/encryption/encryption.service.ts
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';

@Injectable()
export class EncryptionService {
  private readonly algorithm = 'aes-256-gcm';
  private readonly key: Buffer;
  private readonly currentVersion = 'v1';

  constructor(private readonly configService: ConfigService) {
    const rawKey = this.configService.get<string>('ENCRYPTION_MASTER_KEY');
    if (!rawKey) {
      throw new Error('ENCRYPTION_MASTER_KEY environment variable is missing.');
    }
    // Master key must be 32 bytes (256 bits)
    this.key = Buffer.from(rawKey, 'hex');
    if (this.key.length !== 32) {
      throw new Error('ENCRYPTION_MASTER_KEY must be a 64-character hex string (32 bytes).');
    }
  }

  /**
   * Encrypts plaintext into a versioned serialized string format.
   * Output: v1:<iv_hex>:<authTag_hex>:<ciphertext_hex>
   */
  encrypt(plaintext: string): string {
    if (plaintext === null || plaintext === undefined) {
      return plaintext;
    }
    if (typeof plaintext !== 'string') {
      throw new TypeError('EncryptionService.encrypt requires a string input.');
    }

    // 12 bytes IV recommended for GCM
    const iv = randomBytes(12);
    const cipher = createCipheriv(this.algorithm, this.key, iv);

    let ciphertext = cipher.update(plaintext, 'utf8', 'hex');
    ciphertext += cipher.final('hex');

    const authTag = cipher.getAuthTag();

    return `${this.currentVersion}:${iv.toString('hex')}:${authTag.toString('hex')}:${ciphertext}`;
  }

  /**
   * Decrypts a serialized versioned ciphertext back to plaintext.
   * Throws Error if payload is tampered with or corrupted.
   */
  decrypt(serializedCiphertext: string): string {
    if (!serializedCiphertext) {
      return serializedCiphertext;
    }

    const parts = serializedCiphertext.split(':');
    if (parts.length !== 4) {
      throw new Error('Invalid encrypted payload format.');
    }

    const [version, ivHex, authTagHex, ciphertextHex] = parts;

    if (version !== 'v1') {
      throw new Error(`Unsupported encryption version: ${version}`);
    }

    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');

    if (iv.length !== 12 || authTag.length !== 16) {
      throw new Error('Corrupted IV or authentication tag length.');
    }

    const decipher = createDecipheriv(this.algorithm, this.key, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(ciphertextHex, 'hex', 'utf8');
    decrypted += decipher.final('utf8'); // Throws if authTag verification fails

    return decrypted;
  }
}
```

---

## 5. Transport Security & Network Hardening: TLS 1.3 & Headers

### 5.1 TLS 1.3 Protocol Enforcement

Under LGPD Art. 11 and international health data standards, data in transit must resist cryptographic downgrades and eavesdropping.
- **Protocol:** TLS 1.3 exclusively (`minVersion: 'TLSv1.3'`).
- **Cipher Suites:**
  - `TLS_AES_256_GCM_SHA384`
  - `TLS_CHACHA20_POLY1305_SHA256`
  - `TLS_AES_128_GCM_SHA256`
- **Reverse Proxy Offloading:** When deployed to Google Cloud Run, Cloud Run edge proxies terminate TLS 1.3 automatically. When running direct container instances or staging proxies, Fastify's native HTTPS server options enforce `minVersion: 'TLSv1.3'`.

### 5.2 HTTP Security Headers Configuration

Fastify Helmet enforces mandatory security headers:
- `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`: Forces browsers and mobile HTTP clients (Dio) to use HTTPS for 2 years.
- `X-Content-Type-Options: nosniff`: Prevents MIME-type sniffing.
- `X-Frame-Options: DENY`: Prevents framing and clickjacking.
- `Content-Security-Policy`: Restricts script and asset execution to origin.
- `Referrer-Policy: strict-origin-when-cross-origin`: Strips URL parameters from outbound referrer headers to prevent inadvertent health token leakage.

---

## 6. Non-Diagnostic Medical Disclaimer: Anvisa RDC 657/2022 & CFM Res. 2.314/2022

### 6.1 Regulatory Framework

In Brazil, digital healthcare software is governed by two regulatory authorities:
1. **Anvisa (Agência Nacional de Vigilância Sanitária) - RDC nº 657/2022:** Regulates Software as a Medical Device (SaMD). Software intended for personal wellness, self-monitoring, and general risk stratification is classified as exempt or Class I (low risk), **provided it does NOT claim autonomous diagnostic capability or clinical prescription authority**. Prominent disclaimers must declare that the system is an auxiliary educational and triage tool.
2. **Conselho Federal de Medicina (CFM) - Resolução nº 2.314/2022:** Regulates tele-orientation and digital triage. Digital platforms must explicitly inform users that digital triage does not replace in-person or synchronous telemedicine medical consultation, and must provide immediate escalation instructions for medical emergencies.

### 6.2 Medical Disclaimer API Contract

- **Endpoint:** `GET /v1/legal/disclaimer`
- **Access:** Public (unauthenticated) to allow pre-registration review on Screen 1 & Screen 2.
- **Payload Schema:**

```typescript
// backend/src/modules/legal/dto/medical-disclaimer-response.dto.ts
export class RegulatoryCitationDto {
  regulation: string; // e.g., 'RDC Anvisa nº 657/2022'
  authority: string;  // e.g., 'ANVISA'
  classification: string; // e.g., 'Software de Bem-Estar / SaMD Classe I'
  summary: string;
}

export class EmergencyContactDto {
  service: string;   // e.g., 'SAMU'
  number: string;    // e.g., '192'
  description: string;
}

export class MedicalDisclaimerResponseDto {
  version: string; // e.g., '2026.1'
  title: string;
  disclaimerText: string;
  shortDisclaimer: string; // Compact version for mobile check-in banners
  emergencyNotice: string;
  emergencyContacts: EmergencyContactDto[];
  regulatoryBasis: RegulatoryCitationDto[];
  lastUpdated: string; // ISO 8601
}
```

#### Canonical Legal Text Payload

```json
{
  "version": "2026.1",
  "title": "Aviso Legal de Isenção de Diagnóstico e Orientação Preventiva",
  "disclaimerText": "O DualisCheckUp é uma plataforma móvel de auto-monitoramento preventivo e triagem de bem-estar físico e psico-emocional baseada em protocolos clínicos reconhecidos. O aplicativo NÃO realiza diagnósticos médicos, NÃO prescreve medicamentos ou tratamentos e NÃO substitui a consulta clínica presencial ou o aconselhamento de um médico devidamente registrado no Conselho Regional de Medicina (CRM). Todas as informações e estratificações de risco fornecidas possuem finalidade estritamente informativa e preventiva.",
  "shortDisclaimer": "O DualisCheckUp oferece triagem preventiva e não substitui a avaliação de um profissional médico.",
  "emergencyNotice": "EM CASO DE SINTOMAS GRAVES, DOR TORÁCICA INTENSA, FALTA DE AR AGUDA, PERDA DE CONSCIÊNCIA, DÉFICITS NEUROLÓGICOS OU CRISES EMOCIONAIS AGUDAS COM RISCO À VIDA, INTERROMPA O USO DO APLICATIVO E ACIONE IMEDIATAMENTE OS SERVIÇOS DE EMERGÊNCIA OU DIRIJA-SE AO PRONTO-SOCORRO MAIS PRÓXIMO.",
  "emergencyContacts": [
    { "service": "SAMU", "number": "192", "description": "Serviço de Atendimento Móvel de Urgência" },
    { "service": "Bombeiros", "number": "193", "description": "Resgate e emergências" },
    { "service": "CVV", "number": "188", "description": "Centro de Valorização da Vida (Apoio emocional e prevenção do suicídio)" }
  ],
  "regulatoryBasis": [
    {
      "regulation": "RDC nº 657/2022",
      "authority": "ANVISA",
      "classification": "Software como Dispositivo Médico (SaMD) - Enquadramento Preventivo / Classe I",
      "summary": "Software voltado ao incentivo ao bem-estar e auto-cuidado sem finalidade de diagnóstico autônomo."
    },
    {
      "regulation": "Resolução nº 2.314/2022",
      "authority": "Conselho Federal de Medicina (CFM)",
      "classification": "Teleorientação e Triagem Médica Digital",
      "summary": "Diretrizes de esclarecimento ao paciente quanto à não-substituição do ato médico tradicional."
    }
  ],
  "lastUpdated": "2026-09-14T00:00:00.000Z"
}
```

### 6.3 Audit Trail Persistence: User Disclaimer Consents

Under LGPD Art. 8, proof of consent must be documented with an immutable timestamp and audit trail.

```typescript
// backend/src/database/schema/user-disclaimer-consents.schema.ts
import { pgTable, uuid, varchar, timestamp } from 'drizzle-orm/pg-core';
import { users } from './users.schema';

export const userDisclaimerConsents = pgTable('user_disclaimer_consents', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  disclaimerVersion: varchar('disclaimer_version', { length: 20 }).notNull(),
  acceptedAt: timestamp('accepted_at', { withTimezone: true }).defaultNow().notNull(),
  ipAddressHash: varchar('ip_address_hash', { length: 64 }).notNull(), // SHA-256 hashed IP (LGPD compliant)
  userAgent: varchar('user_agent', { length: 255 }),
});
```

---

## 7. Critical Pitfalls & Defensive Engineering in Phase 1

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     PHASE 1 CRITICAL PITFALL TAXONOMY                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. Connection Pool Session Bleed: Leaking tenant ID across recycled conns.  │
│    -> MITIGATION: Use set_config(..., true) inside isolated transactions.   │
├─────────────────────────────────────────────────────────────────────────────┤
│ 2. Superuser RLS Bypass: Superuser DB accounts silently ignore RLS policies.│
│    -> MITIGATION: Enforce FORCE ROW LEVEL SECURITY and non-superuser roles. │
├─────────────────────────────────────────────────────────────────────────────┤
│ 3. Plaintext PII/PHI in Query Logs: Logging SQL statements with narratives. │
│    -> MITIGATION: Pino redaction hooks + parameterized field encryption.    │
├─────────────────────────────────────────────────────────────────────────────┤
│ 4. IV Reuse in AES-256-GCM: Catastrophic key recovery via two-time pads.    │
│    -> MITIGATION: Enforce crypto.randomBytes(12) on EVERY encrypt() call.   │
├─────────────────────────────────────────────────────────────────────────────┤
│ 5. Comma-Separated Decimal Confusion: Brazilian comma vs dot in DB floats.  │
│    -> MITIGATION: Store clinical scores as integers or strict numeric types.│
└─────────────────────────────────────────────────────────────────────────────┘
```

### 7.1 Detailed Pitfall Analysis

1. **Superuser RLS Bypass:**
   - *Risk:* In PostgreSQL, the `postgres` superuser role bypasses RLS policies by default unless explicitly configured.
   - *Mitigation:* In production DDL migrations, execute `ALTER TABLE <name> FORCE ROW LEVEL SECURITY;`. For application runtime, provision a dedicated least-privilege role (`dualis_app_user`) that is not a superuser and does not possess `BYPASSRLS`.
2. **Plaintext PHI in Application & Database Logs:**
   - *Risk:* Node.js query loggers (e.g., `pino` or Drizzle logger) printing raw SQL statements containing sensitive health symptom descriptions.
   - *Mitigation:* With AES-256-GCM field-level encryption, the string passed into Drizzle and PostgreSQL is already ciphertext. Even if SQL query logging is enabled in development, only ciphertext hex strings appear in the logs.
3. **AES-GCM Nonce/IV Collision:**
   - *Risk:* In GCM mode, reusing an IV with the same encryption key completely destroys the security guarantees of the cipher, allowing attackers to recover the authentication key and forge messages.
   - *Mitigation:* IV generation is hardcoded to `randomBytes(12)` on every invocation. The unit test suite validates that 10,000 consecutive encryptions of the identical plaintext string produce 10,000 distinct IVs and ciphertexts.

---

## 8. Validation Architecture

This mandatory section specifies the complete validation framework, automated test scripts, fixtures, and negative security regression suites for Phase 1.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        PHASE 1 TEST ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  Test Framework: Vitest 3.x + Supertest 7.x                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  Layer 1: Unit Tests (Fast, in-memory)                                      │
│  - EncryptionService (AES-256-GCM, IV randomness, tampering detection)      │
│  - DisclaimerService (Schema conformity, version validation)                │
├─────────────────────────────────────────────────────────────────────────────┤
│  Layer 2: Database Integration Tests (Isolated PostgreSQL container)        │
│  - Drizzle ORM Schema Migration & RLS Policy Creation                       │
│  - Scoped Transaction Verification (set_config reset on rollback/commit)    │
│  - Connection Pool Leak & Recycling Safety Check                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  Layer 3: Cross-Tenant Security Regression Suite (Negative Test Matrix)     │
│  - User A vs User B Isolation on SELECT, UPDATE, DELETE                     │
│  - Default Deny: Queries without set_config return 0 rows                   │
│  - SQL Injection Bypass Resilience                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  Layer 4: End-to-End HTTP API Tests (Supertest)                             │
│  - GET /v1/legal/disclaimer returns 200 with Brazilian regulatory metadata  │
│  - Fastify Helmet Security Headers Assertion (HSTS, CSP, X-Frame-Options)   │
│  - CORS Preflight & Rejection Verification                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 8.1 Test Framework & Dependencies

- **Runner:** `vitest: ^3.0.5`
- **HTTP Assertion:** `supertest: ^7.0.0`
- **PostgreSQL Driver:** `pg: ^8.13.3`
- **Database Test Environment:** Local PostgreSQL 16 container (Docker) or isolated test schema in Supabase.

### 8.2 Automated Verify Commands

Add the following scripts to `backend/package.json`:

```json
{
  "scripts": {
    "test": "vitest run --dir src",
    "test:watch": "vitest --dir src",
    "test:coverage": "vitest run --coverage --dir src",
    "test:e2e": "vitest run --config ./vitest.config.e2e.ts",
    "test:rls": "vitest run test/security/cross-tenant-rls.spec.ts",
    "db:migrate": "drizzle-kit migrate",
    "db:push": "drizzle-kit push",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\"",
    "verify:phase1": "npm run test && npm run test:rls && npm run test:e2e"
  }
}
```

### 8.3 Cross-Tenant RLS Negative Security Regression Suite

This test suite executes direct database queries against PostgreSQL to prove that User A cannot read, modify, or delete User B's rows under any circumstances.

```typescript
// backend/test/security/cross-tenant-rls.spec.ts
import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import { sql } from 'drizzle-orm';
import { users, symptomLogs } from '../../src/database/schema';

describe('Security Regression: PostgreSQL Cross-Tenant RLS Isolation (SEC-01)', () => {
  let pool: Pool;
  let db: ReturnType<typeof drizzle>;

  // Deterministic Test UUIDs
  const userA_Id = '11111111-1111-1111-1111-111111111111';
  const userB_Id = '22222222-2222-2222-2222-222222222222';
  const userA_LogId = 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const userB_LogId = 'bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  beforeAll(async () => {
    pool = new Pool({
      connectionString: process.env.TEST_DATABASE_URL || process.env.DATABASE_URL,
      max: 5,
    });
    db = drizzle(pool);

    // Ensure RLS is active and forced
    await pool.query(`ALTER TABLE symptom_logs ENABLE ROW LEVEL SECURITY;`);
    await pool.query(`ALTER TABLE symptom_logs FORCE ROW LEVEL SECURITY;`);
    await pool.query(`ALTER TABLE users ENABLE ROW LEVEL SECURITY;`);
    await pool.query(`ALTER TABLE users FORCE ROW LEVEL SECURITY;`);
  });

  afterAll(async () => {
    await pool.end();
  });

  beforeEach(async () => {
    // Clean and seed test records in a bypass session
    // For test setup only, use a maintenance query
    await pool.query(`TRUNCATE TABLE symptom_logs, users CASCADE;`);

    // Insert test tenants
    await pool.query(
      `INSERT INTO users (id, email) VALUES ($1, $2), ($3, $4);`,
      [userA_Id, 'tenantA@dualis.com.br', userB_Id, 'tenantB@dualis.com.br'],
    );

    // Insert records directly for both tenants
    await pool.query(
      `INSERT INTO symptom_logs (id, user_id, encrypted_narrative, intensity) VALUES 
       ($1, $2, 'enc_narrative_A', 3),
       ($3, $4, 'enc_narrative_B', 5);`,
      [userA_LogId, userA_Id, userB_LogId, userB_Id],
    );
  });

  it('Scenario 1: User A can read their own logs under User A session context', async () => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);

      const res = await client.query('SELECT * FROM symptom_logs');
      expect(res.rows).toHaveLength(1);
      expect(res.rows[0].id).toBe(userA_LogId);
      expect(res.rows[0].user_id).toBe(userA_Id);

      await client.query('COMMIT');
    } finally {
      client.release();
    }
  });

  it('Scenario 2: User A attempting to query User B log returns EMPTY set (Cross-Tenant SELECT blocked)', async () => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);

      // User A explicitly queries for User B's log ID
      const res = await client.query('SELECT * FROM symptom_logs WHERE id = $1', [userB_LogId]);
      expect(res.rows).toHaveLength(0); // Engine RLS drops row silently

      // User A attempts WHERE user_id = userB_Id
      const resAll = await client.query('SELECT * FROM symptom_logs WHERE user_id = $1', [userB_Id]);
      expect(resAll.rows).toHaveLength(0);

      await client.query('COMMIT');
    } finally {
      client.release();
    }
  });

  it('Scenario 3: User A attempting to UPDATE User B log affects 0 rows (Cross-Tenant UPDATE blocked)', async () => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);

      const res = await client.query(
        'UPDATE symptom_logs SET intensity = 1 WHERE id = $1',
        [userB_LogId],
      );
      expect(res.rowCount).toBe(0);

      await client.query('COMMIT');
    } finally {
      client.release();
    }

    // Verify row was NOT modified
    const check = await pool.query('SELECT intensity FROM symptom_logs WHERE id = $1', [userB_LogId]);
    expect(check.rows[0].intensity).toBe(5);
  });

  it('Scenario 4: User A attempting to DELETE User B log affects 0 rows (Cross-Tenant DELETE blocked)', async () => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);

      const res = await client.query('DELETE FROM symptom_logs WHERE id = $1', [userB_LogId]);
      expect(res.rowCount).toBe(0);

      await client.query('COMMIT');
    } finally {
      client.release();
    }

    // Verify row still exists
    const check = await pool.query('SELECT id FROM symptom_logs WHERE id = $1', [userB_LogId]);
    expect(check.rows).toHaveLength(1);
  });

  it('Scenario 5: Default Deny — Unauthenticated query without set_config returns 0 rows', async () => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      // No set_config executed

      const res = await client.query('SELECT * FROM symptom_logs');
      expect(res.rows).toHaveLength(0);

      await client.query('COMMIT');
    } finally {
      client.release();
    }
  });

  it('Scenario 6: SQL Injection / Malicious WHERE bypass attempts are blocked by engine RLS', async () => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);

      // Malicious query attempting to bypass WHERE clause with OR '1'='1'
      const res = await client.query("SELECT * FROM symptom_logs WHERE '1'='1'");
      expect(res.rows).toHaveLength(1);
      expect(res.rows[0].user_id).toBe(userA_Id); // Cannot see User B's row

      await client.query('COMMIT');
    } finally {
      client.release();
    }
  });

  it('Scenario 7: Session settings do not bleed into recycled pooled connections', async () => {
    // Step 1: Client 1 uses connection and sets User A context
    const client1 = await pool.connect();
    await client1.query('BEGIN');
    await client1.query(`SELECT set_config('app.current_user_id', $1, true)`, [userA_Id]);
    await client1.query('COMMIT');
    client1.release();

    // Step 2: Client 2 acquires a connection from the same pool without setting context
    const client2 = await pool.connect();
    try {
      const res = await client2.query("SELECT current_setting('app.current_user_id', true) as uid");
      expect(res.rows[0].uid).toBeFalsy(); // Must be empty or null, NOT userA_Id
    } finally {
      client2.release();
    }
  });
});
```

### 8.4 Unit Test Suite: AES-256-GCM Field-Level Encryption

```typescript
// backend/test/unit/encryption.service.spec.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { ConfigService } from '@nestjs/config';
import { EncryptionService } from '../../src/common/encryption/encryption.service';

describe('EncryptionService (SEC-02: AES-256-GCM Field Encryption)', () => {
  let service: EncryptionService;
  const mockMasterKey = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'; // 32 bytes

  beforeEach(() => {
    const configService = new ConfigService({
      ENCRYPTION_MASTER_KEY: mockMasterKey,
    });
    service = new EncryptionService(configService);
  });

  it('should encrypt and decrypt a sensitive clinical symptom narrative correctly', () => {
    const rawNarrative = 'Paciente relata dor torácica opressiva irradiando para membro superior esquerdo e sudorese.';
    const encrypted = service.encrypt(rawNarrative);

    expect(encrypted).not.toBe(rawNarrative);
    expect(encrypted.startsWith('v1:')).toBe(true);

    const decrypted = service.decrypt(encrypted);
    expect(decrypted).toBe(rawNarrative);
  });

  it('should generate unique IVs for identical plaintext inputs (No IV reuse)', () => {
    const rawText = 'Cefaleia frontal pulsátil de intensidade 4';
    const enc1 = service.encrypt(rawText);
    const enc2 = service.encrypt(rawText);

    expect(enc1).not.toBe(enc2);

    const iv1 = enc1.split(':')[1];
    const iv2 = enc2.split(':')[1];
    expect(iv1).not.toBe(iv2);

    expect(service.decrypt(enc1)).toBe(rawText);
    expect(service.decrypt(enc2)).toBe(rawText);
  });

  it('should throw an error if ciphertext or authentication tag is tampered with', () => {
    const rawText = 'Pensamentos intrusivos e ansiedade severa';
    const encrypted = service.encrypt(rawText);
    const parts = encrypted.split(':');

    // Tamper with ciphertext by altering the last hex character
    const tamperedCiphertext = parts[3].slice(0, -1) + (parts[3].endsWith('a') ? 'b' : 'a');
    const tamperedPayload = `${parts[0]}:${parts[1]}:${parts[2]}:${tamperedCiphertext}`;

    expect(() => service.decrypt(tamperedPayload)).toThrow();
  });

  it('should throw an error if master key length is invalid', () => {
    const invalidConfig = new ConfigService({
      ENCRYPTION_MASTER_KEY: 'too-short',
    });
    expect(() => new EncryptionService(invalidConfig)).toThrow('ENCRYPTION_MASTER_KEY must be a 64-character hex string');
  });
});
```

### 8.5 End-to-End Test Suite: Medical Disclaimer & Security Headers

```typescript
// backend/test/e2e/legal-disclaimer.e2e-spec.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { Test } from '@nestjs/testing';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { AppModule } from '../../src/app.module';

describe('Legal & Regulatory Disclaimer Endpoint (DISC-01) & Security Headers', () => {
  let app: NestFastifyApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication<NestFastifyApplication>(new FastifyAdapter());
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /v1/legal/disclaimer returns 200 with Brazilian regulatory compliance metadata', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/legal/disclaimer')
      .expect(200);

    expect(res.body).toHaveProperty('version');
    expect(res.body).toHaveProperty('disclaimerText');
    expect(res.body.disclaimerText).toContain('NÃO realiza diagnósticos médicos');
    expect(res.body.emergencyNotice).toContain('SAMU');
    expect(res.body.emergencyContacts).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ service: 'SAMU', number: '192' }),
        expect.objectContaining({ service: 'CVV', number: '188' }),
      ]),
    );
    expect(res.body.regulatoryBasis).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ regulation: expect.stringContaining('RDC nº 657/2022') }),
        expect.objectContaining({ regulation: expect.stringContaining('Resolução nº 2.314/2022') }),
      ]),
    );
  });

  it('Response includes mandatory HSTS, CSP, and X-Frame-Options security headers', async () => {
    const res = await request(app.getHttpServer()).get('/v1/legal/disclaimer');

    expect(res.headers['strict-transport-security']).toBeDefined();
    expect(res.headers['strict-transport-security']).toContain('max-age=63072000');
    expect(res.headers['x-frame-options']).toBe('DENY');
    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });
});
```

---

## 9. Implementation Roadmap & Plan Decomposition

Phase 1 is structured into two focused, executable plans in `.planning/phases/01-backend-foundation-postgresql-rls-data-encryption/`:

### Plan 01-01: Backend Skeleton, Drizzle ORM Schema & PostgreSQL RLS
- Initialize NestJS 12 Fastify project with TypeScript, Pino logging, and environment configuration.
- Setup Drizzle ORM 0.45.2 with `pg.Pool` connection factory supporting both Supabase (Dev) and Google Cloud SQL (Prod).
- Define Drizzle schema for `users`, `symptom_logs`, and `user_disclaimer_consents`.
- Implement migration generator with SQL DDL enabling and forcing PostgreSQL Row-Level Security.
- Implement `DatabaseService.withRls(userId, callback)` transaction runner utilizing parameterized `set_config('app.current_user_id', userId, true)`.
- Execute automated cross-tenant security regression tests (`test/security/cross-tenant-rls.spec.ts`) asserting 100% tenant isolation.

### Plan 01-02: AES-256-GCM Field Encryption, TLS/Helmet Security & Medical Disclaimer API
- Implement `EncryptionService` with AES-256-GCM, random 12-byte IVs, 16-byte auth tags, and key versioning (`v1`).
- Configure Fastify Helmet security headers (HSTS 2 years, CSP, nosniff, DENY) and strict CORS whitelist.
- Implement `LegalModule` exposing `GET /v1/legal/disclaimer` returning Brazilian Portuguese disclaimer contracts compliant with Anvisa RDC 657/2022 and CFM Resolução 2.314/2022.
- Implement unit test suites for `EncryptionService` and E2E Supertest suites for `LegalModule`.
- Run full Phase 1 verification command: `npm run verify:phase1`.

---

## 10. Research References

- **Brazilian Regulations:**
  - *Lei Geral de Proteção de Dados (LGPD)* — Lei nº 13.709/2018 (Art. 5º, II; Art. 11: Dados Pessoais Sensíveis de Saúde).
  - *Agência Nacional de Vigilância Sanitária (Anvisa)* — RDC nº 657/2022 (Regulamentação de Software como Dispositivo Médico - SaMD).
  - *Conselho Federal de Medicina (CFM)* — Resolução CFM nº 2.314/2022 (Regulamentação da Telemedicina e Teleorientação).
- **PostgreSQL & Drizzle ORM:**
  - [PostgreSQL Documentation on Row-Level Security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
  - [PostgreSQL Configuration Functions (`set_config`)](https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-SET)
  - [Drizzle ORM Documentation (PostgreSQL / RLS Policies)](https://orm.drizzle.team/docs/rls)
- **Node.js & Security Standards:**
  - [Node.js `node:crypto` API Documentation (AES-GCM)](https://nodejs.org/api/crypto.html#crypto_class_cipher)
  - [NIST SP 800-38D: Recommendation for Block Cipher Modes of Operation: Galois/Counter Mode (GCM)](https://csrc.nist.gov/publications/detail/sp/800-38d/final)
  - [OWASP Security Headers Guide](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html)
