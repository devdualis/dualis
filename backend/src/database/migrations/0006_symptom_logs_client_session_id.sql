-- Migration 0006: Add client_session_id to symptom_logs for outbox idempotency

ALTER TABLE "symptom_logs" ADD COLUMN IF NOT EXISTS "client_session_id" text;

CREATE UNIQUE INDEX IF NOT EXISTS "idx_symptom_logs_user_client_session" 
ON "symptom_logs" ("user_id", "client_session_id") 
WHERE "client_session_id" IS NOT NULL;
