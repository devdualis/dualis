import { Client } from 'pg';
import * as dotenv from 'dotenv';
import * as path from 'path';
import OpenAI from 'openai';
import { MEDICAL_ARTICLES_SEED } from '../src/modules/triage/data/medical-articles.seed';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const EMBEDDING_MODEL = 'text-embedding-3-small';
const EMBEDDING_DIMENSIONS = 768;

const apiKey = process.env.OPENAI_KEY;

const client = apiKey && apiKey !== 'mock-openai-key' ? new OpenAI({ apiKey }) : null;

function generateDeterministicEmbedding(text: string): number[] {
  const vector = new Array(768).fill(0);
  const normalized = text.toLowerCase().trim();
  for (let i = 0; i < normalized.length; i++) {
    const code = normalized.charCodeAt(i);
    const idx = (code * 31 + i * 17) % 768;
    vector[idx] += 0.5;
  }
  const words = normalized.split(/[\s,.;:!?/\\-]+/).filter((w) => w.length > 1);
  for (let w = 0; w < words.length; w++) {
    const word = words[w];
    let hash = 0;
    for (let c = 0; c < word.length; c++) {
      hash = (hash << 5) - hash + word.charCodeAt(c);
      hash |= 0;
    }
    const idx = Math.abs(hash) % 768;
    vector[idx] += 3.0;
  }
  let sumSquares = 0;
  for (let i = 0; i < 768; i++) {
    sumSquares += vector[i] * vector[i];
  }
  const magnitude = Math.sqrt(sumSquares) || 1;
  return vector.map((val) => Number((val / magnitude).toFixed(6)));
}

async function getEmbedding(text: string): Promise<number[]> {
  if (client) {
    try {
      const response = await client.embeddings.create({
        model: EMBEDDING_MODEL,
        input: text,
        dimensions: EMBEDDING_DIMENSIONS,
      });
      const values = response.data?.[0]?.embedding;
      if (Array.isArray(values) && values.length === EMBEDDING_DIMENSIONS) {
        return values;
      }
    } catch (e) {
      // Fall through to deterministic embedding
    }
  }
  console.warn('Falling back to deterministic clinical embedding for:', text.slice(0, 40));
  return generateDeterministicEmbedding(text);
}

async function runSeed() {
  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    console.error('DATABASE_URL is not defined in environment.');
    process.exit(1);
  }

  const pgClient = new Client({
    connectionString: dbUrl,
    ssl: { rejectUnauthorized: false },
  });

  console.log('Connecting to database...');
  await pgClient.connect();
  console.log('Connected to PostgreSQL successfully.');

  // Ensure pgvector extension and table structure
  await pgClient.query('CREATE EXTENSION IF NOT EXISTS vector;');

  const total = MEDICAL_ARTICLES_SEED.length;
  console.log(`Starting embedding and upsert of ${total} medical articles...`);

  let successCount = 0;
  const startTime = Date.now();

  for (let i = 0; i < total; i++) {
    const article = MEDICAL_ARTICLES_SEED[i];
    const textToEmbed = `${article.title} ${article.category} ${article.keywords.join(' ')} ${article.summary}`;

    process.stdout.write(`[${i + 1}/${total}] Embedding '${article.id}' (${article.category})... `);

    const embedding = await getEmbedding(textToEmbed);
    const vectorString = `[${embedding.join(',')}]`;

    await pgClient.query(
      `
      INSERT INTO medical_articles (
        id, title, category, somatic_system, author, author_role,
        read_time_minutes, summary, content_markdown, keywords, url, embedding
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12::vector
      )
      ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        category = EXCLUDED.category,
        somatic_system = EXCLUDED.somatic_system,
        author = EXCLUDED.author,
        author_role = EXCLUDED.author_role,
        read_time_minutes = EXCLUDED.read_time_minutes,
        summary = EXCLUDED.summary,
        content_markdown = EXCLUDED.content_markdown,
        keywords = EXCLUDED.keywords,
        url = EXCLUDED.url,
        embedding = EXCLUDED.embedding,
        created_at = NOW();
      `,
      [
        article.id,
        article.title,
        article.category,
        article.somaticSystem || null,
        article.author,
        article.authorRole,
        article.readTimeMinutes,
        article.summary,
        article.contentMarkdown,
        article.keywords,
        article.url,
        vectorString,
      ],
    );

    successCount++;
    console.log(`Done (${embedding.length} dims)`);

    // Subtle rate-limiting delay between Gemini API calls to prevent 429 RPM limit
    if (client && i < total - 1) {
      await new Promise((resolve) => setTimeout(resolve, 150));
    }
  }

  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`\nSuccessfully embedded and upserted ${successCount}/${total} articles in ${elapsed}s.`);

  // Validation
  const countRes = await pgClient.query(`
    SELECT count(*) as total, count(embedding) as with_embedding
    FROM medical_articles;
  `);
  console.log('Database verification:', countRes.rows[0]);

  // Semantic test
  console.log('\n--- Running Semantic Verification Queries ---');
  const testQueries = [
    'travei o pescoço e a lombar não consigo me mexer',
    'acordo de madrugada com pesadelo e insônia',
    'dor ao urinar e ardência forte na bexiga',
    'sede excessiva e perdi muito peso sem motivo',
    'ferida que não fecha na perna há semanas',
  ];

  for (const q of testQueries) {
    const qEmbedding = await getEmbedding(q);
    const qVector = `[${qEmbedding.join(',')}]`;

    const matchRes = await pgClient.query(
      `
      SELECT id, title, category, 1 - (embedding <=> $1::vector) as similarity
      FROM medical_articles
      ORDER BY embedding <=> $1::vector ASC
      LIMIT 2;
    `,
      [qVector],
    );

    console.log(`\nQuery: "${q}"`);
    for (const r of matchRes.rows) {
      console.log(`  -> [${r.category}] ${r.title} (similarity: ${(Number(r.similarity) * 100).toFixed(1)}%)`);
    }
  }

  await pgClient.end();
  console.log('\nSeeding complete and DB connection closed.');
}

runSeed().catch((err) => {
  console.error('Fatal seed error:', err);
  process.exit(1);
});
