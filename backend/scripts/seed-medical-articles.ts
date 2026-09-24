import { Client } from 'pg';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { GeminiService } from '../src/common/ai/gemini.service';
import { MEDICAL_ARTICLES_SEED } from '../src/modules/triage/data/medical-articles.seed';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const gemini = new GeminiService();

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
  const values = await gemini.embed(text);
  if (values) return values;
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
        id, language, title, category, somatic_system, author, author_role,
        read_time_minutes, summary, content_markdown, keywords, url, embedding
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13::vector
      )
      ON CONFLICT (id) DO UPDATE SET
        language = EXCLUDED.language,
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
        article.language || 'pt',
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
    if (gemini.isAvailable && i < total - 1) {
      await new Promise((resolve) => setTimeout(resolve, 150));
    }
  }

  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`\nSuccessfully embedded and upserted ${successCount}/${total} articles in ${elapsed}s.`);

  // Validation
  const countRes = await pgClient.query(`
    SELECT language, count(*) as total, count(embedding) as with_embedding
    FROM medical_articles
    GROUP BY language
    ORDER BY language;
  `);
  console.log('Database verification by language:');
  console.table(countRes.rows);

  // Semantic test across PT, ES, EN
  console.log('\n--- Running Multilingual Semantic Verification Queries ---');
  const testQueries = [
    { text: 'travei o pescoço e a lombar não consigo me mexer', lang: 'pt' },
    { text: 'se me trabó el cuello y la espalda baja no me puedo mover', lang: 'es' },
    { text: 'locked neck and lower back pain cannot move', lang: 'en' },
    { text: 'ataque de panico palpitaciones y miedo a perder el control', lang: 'es' },
    { text: 'severe chest pressure and heart palpitations', lang: 'en' },
  ];

  for (const { text: q, lang } of testQueries) {
    const qEmbedding = await getEmbedding(q);
    const qVector = `[${qEmbedding.join(',')}]`;

    const matchRes = await pgClient.query(
      `
      SELECT id, language, title, category, 1 - (embedding <=> $1::vector) as similarity
      FROM medical_articles
      WHERE language = $2
      ORDER BY embedding <=> $1::vector ASC
      LIMIT 2;
    `,
      [qVector, lang],
    );

    console.log(`\nQuery (${lang}): "${q}"`);
    for (const r of matchRes.rows) {
      console.log(`  -> [${r.language}] [${r.category}] ${r.title} (similarity: ${(Number(r.similarity) * 100).toFixed(1)}%)`);
    }
  }

  await pgClient.end();
  console.log('\nSeeding complete and DB connection closed.');
}

runSeed().catch((err) => {
  console.error('Fatal seed error:', err);
  process.exit(1);
});
