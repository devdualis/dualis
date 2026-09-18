ALTER TABLE medical_articles 
ADD COLUMN IF NOT EXISTS language VARCHAR(10) NOT NULL DEFAULT 'pt';

CREATE INDEX IF NOT EXISTS idx_medical_articles_language 
ON medical_articles (language);

CREATE INDEX IF NOT EXISTS idx_medical_articles_category_lang 
ON medical_articles (category, language);
