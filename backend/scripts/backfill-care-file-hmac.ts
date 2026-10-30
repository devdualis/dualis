/**
 * Fills care_documents.file_hmac (migration 0022) for documents stored before it, so an
 * old file uploaded again is recognised too. Decrypts one file at a time with
 * ENCRYPTION_MASTER_KEY and writes only the fingerprint. When a profile already holds
 * the same file twice, the newer copy keeps NULL (nothing is deleted) and is counted.
 * Run with the table-owner role (RLS would hide other people's rows):
 *   DATABASE_URL=<owner url> npx tsx scripts/backfill-care-file-hmac.ts [--dry-run]
 */
import 'dotenv/config';
import { Pool } from 'pg';
import { ConfigService } from '@nestjs/config';
import { EncryptionService } from '../src/common/encryption/encryption.service';

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, max: 1 });
  const encryption = new EncryptionService(new ConfigService({ ENCRYPTION_MASTER_KEY: process.env.ENCRYPTION_MASTER_KEY }));
  const { rows: ids } = await pool.query<{ id: string }>(
    `SELECT id FROM care_documents WHERE file_hmac IS NULL ORDER BY created_at`,
  );
  let filled = 0;
  let repeated = 0;
  let failed = 0;
  // Fingerprints given in this run, so a dry run counts repeats the same way.
  const seen = new Set<string>();
  for (const { id } of ids) {
    try {
      const { rows } = await pool.query<{ profile_id: string; file: Buffer }>(
        `SELECT profile_id, file FROM care_documents WHERE id = $1`,
        [id],
      );
      const fileHmac = encryption.fingerprint(encryption.decryptBuffer(rows[0].file));
      const { rowCount: taken } = await pool.query(
        `SELECT 1 FROM care_documents WHERE profile_id = $1 AND file_hmac = $2`,
        [rows[0].profile_id, fileHmac],
      );
      const key = `${rows[0].profile_id}:${fileHmac}`;
      if (taken || seen.has(key)) {
        repeated++;
        continue;
      }
      seen.add(key);
      if (!dryRun) await pool.query(`UPDATE care_documents SET file_hmac = $2 WHERE id = $1`, [id, fileHmac]);
      filled++;
    } catch (err) {
      failed++;
      console.warn(`document ${id}: ${(err as Error).message}`);
    }
  }
  console.log(`${dryRun ? '[dry run] ' : ''}documents: ${ids.length}, filled: ${filled}, same file already in profile: ${repeated}, failed: ${failed}`);
  await pool.end();
}

main().catch((err) => {
  console.error('FAILED:', (err as Error).message);
  process.exit(1);
});
