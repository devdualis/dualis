/**
 * Live smoke test for Gemini on Vertex AI. Reads VERTEX_* from the backend env file
 * and prints only results, never credentials. Run: npx tsx scripts/vertex-smoke.ts
 */
import 'dotenv/config';
import { GeminiService } from '../src/common/ai/gemini.service';
import { JournalSuggestService } from '../src/modules/journal/journal-suggest.service';

async function main() {
  const present = (k: string) => (process.env[k] ? 'set' : 'missing');
  console.log('env:', ['VERTEX_PROJECT', 'VERTEX_LOCATION', 'VERTEX_CLIENT_EMAIL', 'VERTEX_PRIVATE_KEY']
    .map((k) => `${k}=${present(k)}`).join(' '));
  console.log('location:', process.env.VERTEX_LOCATION || 'southamerica-east1 (default)');

  const gemini = new GeminiService();
  if (!gemini.isAvailable) throw new Error('Vertex client not configured');

  let t = Date.now();
  const json = await gemini.generateJson<{ ok: boolean }>({
    prompt: 'Return ok=true.',
    schema: { type: 'object', properties: { ok: { type: 'boolean' } }, required: ['ok'] },
  });
  console.log('generateJson:', JSON.stringify(json), `${Date.now() - t}ms`);

  t = Date.now();
  const vector = await gemini.embed('beber água ao longo do dia');
  console.log('embed:', vector ? `${vector.length} dims` : 'null (failed, see warning above)', `${Date.now() - t}ms`);

  const suggest = new JournalSuggestService(gemini);
  for (const [text, kind] of [
    ['minha cabeça está pesada', 'physical'],
    ['fico pensando no que pode dar errado amanhã', 'emotional'],
    ['comprei um carro novo', 'emotional'],
  ] as const) {
    t = Date.now();
    console.log(`suggest(${kind}, "${text}"):`, JSON.stringify(await suggest.suggest(text, kind)), `${Date.now() - t}ms`);
  }
}

main().catch((err) => {
  console.error('FAILED:', (err as Error).message);
  process.exit(1);
});
