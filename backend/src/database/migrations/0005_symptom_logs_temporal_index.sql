-- Migration 0005: Create composite temporal index on symptom_logs for sub-15ms 14-day Antiburla queries

CREATE INDEX IF NOT EXISTS idx_symptom_logs_user_recorded
ON "symptom_logs" ("user_id", "recorded_at" DESC);
