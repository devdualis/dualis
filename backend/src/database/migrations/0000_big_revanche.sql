CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(255) NOT NULL,
	"email" varchar(255) NOT NULL,
	"password_hash" varchar(255) NOT NULL,
	"gender" varchar(50) NOT NULL,
	"date_of_birth" date,
	"picture" text,
	"is_email_verified" boolean DEFAULT false NOT NULL,
	"email_verified_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "symptom_logs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"encrypted_narrative" text,
	"intensity" integer NOT NULL,
	"anatomical_system" text,
	"emotional_dimension" text,
	"disposition" text,
	"organic_primacy_applied" boolean DEFAULT false NOT NULL,
	"step_answers" text,
	"client_session_id" text,
	"recorded_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "symptom_logs" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "user_disclaimer_consents" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"disclaimer_version" varchar(20) NOT NULL,
	"accepted_at" timestamp with time zone DEFAULT now() NOT NULL,
	"ip_address_hash" varchar(64) NOT NULL,
	"user_agent" varchar(255)
);
--> statement-breakpoint
ALTER TABLE "user_disclaimer_consents" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "triage_emergency_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid,
	"trigger_category" text NOT NULL,
	"severity_level" integer NOT NULL,
	"source_vertical" text NOT NULL,
	"action_taken" text,
	"reported_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "triage_emergency_events" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "medical_articles" (
	"id" varchar(64) PRIMARY KEY NOT NULL,
	"language" varchar(10) DEFAULT 'pt' NOT NULL,
	"title" text NOT NULL,
	"category" varchar(64) NOT NULL,
	"somatic_system" varchar(64),
	"author" text NOT NULL,
	"author_role" text NOT NULL,
	"read_time_minutes" integer DEFAULT 4 NOT NULL,
	"summary" text NOT NULL,
	"content_markdown" text NOT NULL,
	"keywords" text[] NOT NULL,
	"url" text NOT NULL,
	"embedding" vector(768),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "email_verifications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"email" varchar(255) NOT NULL,
	"code_hash" varchar(255) NOT NULL,
	"attempts" integer DEFAULT 0 NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "email_verifications" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "symptom_knowledge" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"input_text" text NOT NULL,
	"vertical" varchar(16) NOT NULL,
	"system_or_dimension" varchar(64) NOT NULL,
	"urgency_score" integer NOT NULL,
	"mapped_lay_term" text NOT NULL,
	"clinical_concept" text NOT NULL,
	"is_emergency_candidate" boolean DEFAULT false NOT NULL,
	"confidence" real NOT NULL,
	"source" varchar(32) NOT NULL,
	"embedding" vector(768),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "symptom_logs" ADD CONSTRAINT "symptom_logs_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_disclaimer_consents" ADD CONSTRAINT "user_disclaimer_consents_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "triage_emergency_events" ADD CONSTRAINT "triage_emergency_events_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "email_verifications" ADD CONSTRAINT "email_verifications_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "idx_medical_articles_category" ON "medical_articles" USING btree ("category");--> statement-breakpoint
CREATE INDEX "idx_medical_articles_language" ON "medical_articles" USING btree ("language");--> statement-breakpoint
CREATE INDEX "idx_medical_articles_category_lang" ON "medical_articles" USING btree ("category","language");--> statement-breakpoint
CREATE INDEX "idx_medical_articles_embedding" ON "medical_articles" USING hnsw ("embedding" vector_cosine_ops);--> statement-breakpoint
CREATE INDEX "idx_symptom_knowledge_system" ON "symptom_knowledge" USING btree ("system_or_dimension");--> statement-breakpoint
CREATE INDEX "idx_symptom_knowledge_embedding" ON "symptom_knowledge" USING hnsw ("embedding" vector_cosine_ops);--> statement-breakpoint
CREATE POLICY "users_patient_isolation" ON "users" AS PERMISSIVE FOR ALL TO public USING (id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR current_setting('app.is_auth_service', true) = 'true') WITH CHECK (id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);--> statement-breakpoint
CREATE POLICY "symptom_logs_patient_isolation" ON "symptom_logs" AS PERMISSIVE FOR ALL TO public USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid) WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);--> statement-breakpoint
CREATE POLICY "user_disclaimer_consents_patient_isolation" ON "user_disclaimer_consents" AS PERMISSIVE FOR ALL TO public USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid) WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid);--> statement-breakpoint
CREATE POLICY "triage_emergency_events_isolation" ON "triage_emergency_events" AS PERMISSIVE FOR ALL TO public USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid) WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR user_id IS NULL);--> statement-breakpoint
CREATE POLICY "email_verifications_isolation" ON "email_verifications" AS PERMISSIVE FOR ALL TO public USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR current_setting('app.is_auth_service', true) = 'true') WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR current_setting('app.is_auth_service', true) = 'true');