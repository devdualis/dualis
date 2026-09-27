CREATE TABLE IF NOT EXISTS water_intake_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_ml integer NOT NULL,
  source text NOT NULL DEFAULT 'manual',
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_water_intake_logs_user_recorded ON water_intake_logs(user_id, recorded_at DESC);

ALTER TABLE water_intake_logs ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'water_intake_logs' AND policyname = 'water_intake_logs_patient_isolation'
  ) THEN
    CREATE POLICY water_intake_logs_patient_isolation ON water_intake_logs
      FOR ALL
      USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid)
      WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);
  END IF;
END
$$;
