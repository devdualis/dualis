-- Migration 0004: Add disposition, organic_primacy_applied, and step_answers to symptom_logs

ALTER TABLE "symptom_logs" ADD COLUMN IF NOT EXISTS "disposition" text;
ALTER TABLE "symptom_logs" ADD COLUMN IF NOT EXISTS "organic_primacy_applied" boolean DEFAULT false NOT NULL;
ALTER TABLE "symptom_logs" ADD COLUMN IF NOT EXISTS "step_answers" text;
