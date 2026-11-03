import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';

/**
 * Phase 11.1 invariant (11.1-02 assumption-delta decision, threat T-11.1-36).
 *
 * Since 0028, a grantee reaches profile data only through the per-category
 * helpers (app_can_read_profile_category / app_can_write_profile_category).
 * A new policy that calls the old all-or-nothing helpers would hand every
 * grantee the whole table again. This test fails when that happens in:
 *  - any CREATE POLICY statement in a migration that sorts strictly after
 *    0028 (0028 itself mentions the old helpers in COMMENT ON FUNCTION), or
 *  - any pgPolicy(...) call in src/database/schema/*.schema.ts.
 */

const MIGRATIONS_DIR = join(__dirname, '../../src/database/migrations');
const SCHEMA_DIR = join(__dirname, '../../src/database/schema');
const BOUNDARY_MIGRATION = '0028_guardianship_consent_gaps.sql';

/** Matches the old helpers only: the category helpers continue with `_category(`. */
const ALL_OR_NOTHING_HELPER = /\bapp_can_(read|write)_profile\(/;

/**
 * Exact policy names allowed to keep an all-or-nothing helper, with the reason.
 * Matched on the policy name only, never by pattern.
 */
const POLICY_ALLOWLIST: Record<string, string> = {
  safety_resource_events_profile_insert:
    "0015 — a help/safety event must never be blocked by a grantee's category scope; safety events are never readable through grants",
};

interface PolicyBlock {
  file: string;
  name: string;
  text: string;
}

function stripSqlLineComments(sql: string): string {
  return sql.replace(/--[^\n]*/g, '');
}

/** Every `CREATE POLICY … ;` statement in a SQL file. */
function extractCreatePolicies(file: string, sql: string): PolicyBlock[] {
  const blocks: PolicyBlock[] = [];
  const re = /CREATE\s+POLICY\s+"?([A-Za-z0-9_]+)"?[\s\S]*?;/gi;
  for (const match of stripSqlLineComments(sql).matchAll(re)) {
    blocks.push({ file, name: match[1], text: match[0] });
  }
  return blocks;
}

/** Every `pgPolicy(…)` call in a schema file, up to its matching close paren. */
function extractPgPolicies(file: string, source: string): PolicyBlock[] {
  const blocks: PolicyBlock[] = [];
  const marker = 'pgPolicy(';
  let from = source.indexOf(marker);
  while (from !== -1) {
    let depth = 0;
    let end = from + marker.length - 1;
    for (; end < source.length; end++) {
      if (source[end] === '(') depth++;
      else if (source[end] === ')' && --depth === 0) break;
    }
    if (depth !== 0) throw new Error(`Unbalanced pgPolicy( call in ${file}`);
    const text = source.slice(from, end + 1);
    const name = /^pgPolicy\(\s*['"`]([^'"`]+)['"`]/.exec(text)?.[1] ?? '<unnamed>';
    blocks.push({ file, name, text });
    from = source.indexOf(marker, end);
  }
  return blocks;
}

/** Migrations whose file name sorts strictly after the 0028 boundary. */
function migrationsAfterBoundary(files: string[]): string[] {
  return files.filter((f) => /^\d{4}_.+\.sql$/.test(f) && f > BOUNDARY_MIGRATION).sort();
}

function offenders(blocks: PolicyBlock[]): string[] {
  return blocks
    .filter((b) => ALL_OR_NOTHING_HELPER.test(b.text) && !Object.hasOwn(POLICY_ALLOWLIST, b.name))
    .map((b) => `${b.file}: policy ${b.name}`);
}

function schemaBlocks(): PolicyBlock[] {
  return readdirSync(SCHEMA_DIR)
    .filter((f) => f.endsWith('.schema.ts'))
    .sort()
    .flatMap((f) => extractPgPolicies(f, readFileSync(join(SCHEMA_DIR, f), 'utf8')));
}

function laterMigrationBlocks(): PolicyBlock[] {
  return migrationsAfterBoundary(readdirSync(MIGRATIONS_DIR)).flatMap((f) =>
    extractCreatePolicies(f, readFileSync(join(MIGRATIONS_DIR, f), 'utf8')),
  );
}

describe('RLS category policy guard (no all-or-nothing helpers after 0028)', () => {
  it('no CREATE POLICY in a migration after 0028 calls app_can_read_profile( or app_can_write_profile(', () => {
    // The boundary must exist, otherwise "after 0028" silently means everything or nothing.
    expect(readdirSync(MIGRATIONS_DIR)).toContain(BOUNDARY_MIGRATION);
    expect(offenders(laterMigrationBlocks())).toEqual([]);
  });

  it('no pgPolicy in a schema file calls the all-or-nothing helpers, except the named allowlist', () => {
    expect(offenders(schemaBlocks())).toEqual([]);
  });

  it('self-check: the schema scan finds the policies (at least 20 pgPolicy blocks)', () => {
    expect(schemaBlocks().length).toBeGreaterThanOrEqual(20);
  });

  it('self-check: the extractors flag the old helpers and pass the category helpers', () => {
    const flagged = extractCreatePolicies(
      'sample.sql',
      'CREATE POLICY x ON t FOR SELECT USING (app_can_read_profile(profile_id));',
    );
    expect(flagged.map((b) => b.name)).toEqual(['x']);
    expect(offenders(flagged)).toEqual(['sample.sql: policy x']);

    const writeFlagged = extractCreatePolicies(
      'sample.sql',
      'create policy y on t for insert with check (app_can_write_profile(profile_id));',
    );
    expect(offenders(writeFlagged)).toEqual(['sample.sql: policy y']);

    const passed = extractCreatePolicies(
      'sample.sql',
      "CREATE POLICY z ON t FOR SELECT USING (app_can_read_profile_category(profile_id, 'habits'));",
    );
    expect(passed).toHaveLength(1);
    expect(offenders(passed)).toEqual([]);

    const schemaSample = extractPgPolicies(
      'sample.schema.ts',
      "pgPolicy('p_old', { for: 'select', using: sql`app_can_read_profile(profile_id)` }),\n" +
        "pgPolicy('p_new', { for: 'select', using: sql`app_can_read_profile_category(profile_id, 'care')` }),",
    );
    expect(schemaSample.map((b) => b.name)).toEqual(['p_old', 'p_new']);
    expect(offenders(schemaSample)).toEqual(['sample.schema.ts: policy p_old']);
  });

  it('self-check: only migrations strictly after 0028 are scanned', () => {
    expect(
      migrationsAfterBoundary([
        '0027_condition_readings.sql',
        BOUNDARY_MIGRATION,
        '0029_next.sql',
        'meta',
        '0030_later.sql',
      ]),
    ).toEqual(['0029_next.sql', '0030_later.sql']);
  });

  it('self-check: every allowlist entry names exactly one scanned policy that still needs it', () => {
    const blocks = [...schemaBlocks(), ...laterMigrationBlocks()];
    for (const name of Object.keys(POLICY_ALLOWLIST)) {
      const matches = blocks.filter((b) => b.name === name);
      expect(matches, `allowlist entry ${name}`).toHaveLength(1);
      expect(ALL_OR_NOTHING_HELPER.test(matches[0].text), `allowlist entry ${name} is stale`).toBe(true);
    }
  });
});
