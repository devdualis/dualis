-- backend/src/database/migrations/0001_enable_rls.sql
-- Enable and FORCE Row Level Security on health data tables (LGPD Art. 11 compliance)

-- 1. Users Table RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_patient_isolation ON users;
CREATE POLICY users_patient_isolation ON users
  FOR ALL
  USING (id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
  WITH CHECK (id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

-- 2. Symptom Logs Table RLS
ALTER TABLE symptom_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE symptom_logs FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS symptom_logs_patient_isolation ON symptom_logs;
CREATE POLICY symptom_logs_patient_isolation ON symptom_logs
  FOR ALL
  USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
  WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);

-- 3. User Disclaimer Consents Table RLS
ALTER TABLE user_disclaimer_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_disclaimer_consents FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_disclaimer_consents_patient_isolation ON user_disclaimer_consents;
CREATE POLICY user_disclaimer_consents_patient_isolation ON user_disclaimer_consents
  FOR ALL
  USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
  WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);
