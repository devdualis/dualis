/** Anything with pg's `query` (a Pool or a Client) connected outside the database to drop. */
interface Queryable {
  query(text: string, values?: unknown[]): Promise<{ rows: Array<Record<string, unknown>> }>;
}

/**
 * Drops a throwaway test database once its connections are gone.
 *
 * `pool.end()` resolves as soon as the pool has asked its clients to close, before the
 * server has ended those backends. A `DROP DATABASE ... WITH (FORCE)` that arrives first
 * terminates a closing backend, and pg raises that FATAL (57P01) as an uncaught error:
 * vitest then exits 1 with every test passing. Waiting until pg_stat_activity shows no
 * backend for the database (at most 5 s) removes the race; FORCE stays as the fallback.
 */
export async function dropTestDatabase(root: Queryable, name: string): Promise<void> {
  for (let i = 0; i < 50; i++) {
    const { rows } = await root.query(
      'SELECT count(*)::int AS n FROM pg_stat_activity WHERE datname = $1',
      [name],
    );
    if (Number(rows[0]?.n ?? 0) === 0) break;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  await root.query(`DROP DATABASE IF EXISTS "${name}" WITH (FORCE)`);
}
