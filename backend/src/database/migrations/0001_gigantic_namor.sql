CREATE INDEX "idx_symptom_logs_user_recorded" ON "symptom_logs" USING btree ("user_id","recorded_at" DESC NULLS LAST);--> statement-breakpoint
CREATE UNIQUE INDEX "idx_symptom_logs_user_client_session" ON "symptom_logs" USING btree ("user_id","client_session_id");--> statement-breakpoint
CREATE INDEX "idx_triage_emergency_events_user_id" ON "triage_emergency_events" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_triage_emergency_events_reported_at" ON "triage_emergency_events" USING btree ("reported_at");--> statement-breakpoint
ALTER TABLE "users" FORCE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "symptom_logs" FORCE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "user_disclaimer_consents" FORCE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "triage_emergency_events" FORCE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "email_verifications" FORCE ROW LEVEL SECURITY;--> statement-breakpoint
GRANT USAGE ON SCHEMA public TO authenticated;--> statement-breakpoint
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;