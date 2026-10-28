/**
 * Live smoke test for exam/prescription reading (Cloud Vision + Gemini on Vertex AI).
 * Reads credentials from the backend env (GOOGLE_VISION_API_KEY may also come from
 * VISION_ENV_FILE) and prints only results, never credentials.
 * Run: npx tsx scripts/document-reader-smoke.ts <file.(png|jpg|pdf)> [lab|prescription]
 */
import 'dotenv/config';
import { config } from 'dotenv';
import { readFileSync } from 'node:fs';
import { GeminiService } from '../src/common/ai/gemini.service';
import { DocumentReaderService } from '../src/modules/care/document-reader.service';

if (process.env.VISION_ENV_FILE) config({ path: process.env.VISION_ENV_FILE });

async function main() {
  const [file, kind = 'lab'] = process.argv.slice(2);
  if (!file) throw new Error('usage: document-reader-smoke.ts <file> [lab|prescription]');
  const mime = file.endsWith('.pdf') ? 'application/pdf' : file.endsWith('.png') ? 'image/png' : 'image/jpeg';
  const reader = new DocumentReaderService(new GeminiService());
  const bytes = readFileSync(file);

  let t = Date.now();
  const text = await reader.ocr(mime, bytes);
  console.log(`ocr: ${text.length} chars, ${Date.now() - t}ms`);

  t = Date.now();
  const reading = await reader.read(kind as 'lab' | 'prescription', mime, bytes);
  console.log(`read (ocr + gemini): ${Date.now() - t}ms`);
  console.log(JSON.stringify(reading, null, 2));
}

main().catch((err) => {
  console.error('FAILED:', (err as Error).message);
  process.exit(1);
});
