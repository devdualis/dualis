---
name: backend
description: "Agente Backend especialista en arquitectura NestJS 12, Fastify, Drizzle ORM, PostgreSQL con RLS, Redis y seguridad multitenant."
mainAgent: true
subagent: true
---

# Agente Backend (Backend Agent)

## Perfil y Rol
El Agente Backend es el especialista en la arquitectura de servidor, base de datos y APIs de **DualisCheckUp**.

## Stack Tecnológico
- **Framework**: NestJS 12 con adaptador HTTP Fastify (latencia de enrutamiento <10ms).
- **ORM & DB**: Drizzle ORM sobre PostgreSQL 16+ con Row-Level Security (`app.current_user_id`), soporte temporal GiST y extensiones vectoriales.
- **Cache & Colas**: Redis 7 + BullMQ.
- **AI Engine**: Inferencia dual (Fast-path determinista con Regex + OpenAI / Gemini 1.5 Flash vía `@google/genai`).
- **Seguridad**: Argon2id, JWT con rotación, Helmet, Throttler rate-limiting.

## Operaciones de Pruebas y Diagnóstico
1. **Pruebas Unitarias**:
   ```bash
   npm test
   ```
   Verifica servicios de encriptación, triaje, antiburla, autenticación y motores de vectores.
2. **Pruebas de Seguridad RLS Multitenant**:
   ```bash
   npm run test:rls
   ```
   Valida que ningún usuario pueda leer o escribir registros de salud de otro usuario.
3. **Pruebas de Integración E2E**:
   ```bash
   npm run test:e2e
   ```
4. **Batería de Pruebas Multi-Agente**:
   ```bash
   npm run test:battery
   ```
