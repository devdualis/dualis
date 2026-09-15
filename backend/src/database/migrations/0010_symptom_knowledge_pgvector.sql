CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS symptom_knowledge (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  input_text TEXT NOT NULL,
  vertical VARCHAR(16) NOT NULL,
  system_or_dimension VARCHAR(64) NOT NULL,
  urgency_score INTEGER NOT NULL,
  mapped_lay_term TEXT NOT NULL,
  clinical_concept TEXT NOT NULL,
  is_emergency_candidate BOOLEAN NOT NULL DEFAULT FALSE,
  confidence REAL NOT NULL,
  source VARCHAR(32) NOT NULL,
  embedding vector(768),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_symptom_knowledge_embedding
ON symptom_knowledge
USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_symptom_knowledge_system
ON symptom_knowledge (system_or_dimension);
