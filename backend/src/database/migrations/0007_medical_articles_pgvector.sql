CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS medical_articles (
  id VARCHAR(64) PRIMARY KEY,
  title TEXT NOT NULL,
  category VARCHAR(64) NOT NULL,
  somatic_system VARCHAR(64),
  author TEXT NOT NULL,
  author_role TEXT NOT NULL,
  read_time_minutes INTEGER NOT NULL DEFAULT 4,
  summary TEXT NOT NULL,
  content_markdown TEXT NOT NULL,
  keywords TEXT[] NOT NULL,
  url TEXT NOT NULL,
  embedding vector(768),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_medical_articles_embedding 
ON medical_articles 
USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_medical_articles_category 
ON medical_articles (category);
