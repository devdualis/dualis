-- backend/src/database/migrations/0018_remove_ai_tagging.sql
-- AI tagging of journal text is removed from the product (strategy §18 decision 1):
-- the app no longer calls it and its endpoints are gone. This drops the shared table
-- that cached tagged phrases from every person, together with its indexes.
-- The `vector` extension stays: library articles still use it.
-- Idempotent: safe to re-run.

DROP INDEX IF EXISTS idx_symptom_knowledge_embedding;
DROP INDEX IF EXISTS idx_symptom_knowledge_system;
DROP TABLE IF EXISTS symptom_knowledge;
