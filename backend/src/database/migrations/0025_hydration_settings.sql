-- backend/src/database/migrations/0025_hydration_settings.sql
-- Water goal and reminder choices move to the server (quick task 261031-t2b), so they
-- follow the person across logout, reinstall and new devices instead of living only in
-- the phone's secure storage. Account-level: one JSON document per user, covered by the
-- existing users_patient_isolation RLS policy (a user reads and writes only their row).
-- Idempotent: safe to re-run.

ALTER TABLE users ADD COLUMN IF NOT EXISTS hydration_settings jsonb;
