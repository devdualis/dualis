import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { habitsDatabase } from '../support/habits-database';

// Live tests are opt-in and the fixture rejects remote URLs before opening any connection.
describe.skipIf(!process.env.TEST_DATABASE_URL)('Daily habits: real runtime-role RLS and lifecycle', () => {
  let f: Awaited<ReturnType<typeof habitsDatabase>>;
  const today = new Date().toISOString().slice(0, 10);
  beforeAll(async () => { f = await habitsDatabase(); });
  afterAll(async () => { if (f) await f.close(); });

  it('runtime grants work with ENABLE + FORCE RLS and no bypass privileges', async () => {
    const role = await f.appPool.query('SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user');
    expect(role.rows[0]).toEqual({ rolsuper: false, rolbypassrls: false });
    const table = await f.admin.query("SELECT relrowsecurity, relforcerowsecurity FROM pg_class WHERE oid = 'daily_habits'::regclass");
    expect(table.rows[0]).toEqual({ relrowsecurity: true, relforcerowsecurity: true });
    await expect(f.habits.putDay(f.owner, f.primary, today, { sleepQuality: 'bem' })).resolves.toMatchObject({ sleepQuality: 'bem' });
    expect((await f.appPool.query('SELECT * FROM daily_habits')).rows).toEqual([]);
  });
  it('one row per profile/day, full replacement, and no cross-profile reads', async () => {
    await f.habits.putDay(f.owner, f.primary, today, { moved: true, movementMinutes: '15_30', period: true });
    const saved = await f.habits.putDay(f.owner, f.primary, today, { sleepHours: '7_8' });
    expect(saved).toEqual({ day: today, sleepHours: '7_8', sleepQuality: null, moved: null, movementMinutes: null, period: null, updatedAt: expect.any(String) });
    expect((await f.admin.query('SELECT id FROM daily_habits WHERE profile_id = $1', [f.primary])).rowCount).toBe(1);
    expect((await f.habits.listDays(f.owner, f.dependent)).days).toEqual([]);
    expect((await f.habits.listDays(f.stranger, f.primary)).days).toEqual([]);
    await expect(f.habits.putDay(f.stranger, f.primary, today, {})).rejects.toThrow(/row-level security/);
    await expect(f.habits.deleteDay(f.owner, f.dependent, today)).rejects.toMatchObject({ status: 404 });
  });
  it('CO_MANAGE writes with caller as author; VIEW_ONLY only reads', async () => {
    await f.habits.putDay(f.manager, f.dependent, today, { moved: true, movementMinutes: 'ate_15' });
    const stored = await f.admin.query('SELECT user_id FROM daily_habits WHERE profile_id = $1', [f.dependent]);
    expect(stored.rows[0].user_id).toBe(f.manager);
    expect((await f.habits.listDays(f.viewer, f.dependent)).days).toHaveLength(1);
    await expect(f.habits.putDay(f.viewer, f.dependent, today, {})).rejects.toThrow(/row-level security/);
    await expect(f.habits.deleteDay(f.viewer, f.dependent, today)).rejects.toMatchObject({ status: 404 });
    const changed = await f.asUser(f.viewer, (c) => c.query("UPDATE daily_habits SET period = true WHERE profile_id = $1", [f.dependent]));
    expect(changed.rowCount).toBe(0);
    await expect(f.asUser(f.owner, (c) => c.query('INSERT INTO daily_habits (user_id, profile_id, day) VALUES ($1, $2, current_date - 1)', [f.manager, f.primary]))).rejects.toThrow(/row-level security/);
    await f.habits.putDay(f.owner, f.dependent, today, { period: false });
    expect((await f.admin.query('SELECT user_id FROM daily_habits WHERE profile_id = $1', [f.dependent])).rows[0].user_id).toBe(f.manager);
  });
  it('SQL constraints reject invalid choices and minutes without moved=true', async () => {
    for (const [column, value] of [['sleep_quality', 'otimo'], ['sleep_hours', '8'], ['movement_minutes', '90']]) {
      await expect(f.asUser(f.owner, (c) => c.query(`UPDATE daily_habits SET ${column} = $1 WHERE profile_id = $2`, [value, f.primary]))).rejects.toThrow(/daily_habits_.*check/);
    }
    await expect(f.asUser(f.owner, (c) => c.query("UPDATE daily_habits SET moved = NULL, movement_minutes = 'ate_15' WHERE profile_id = $1", [f.primary]))).rejects.toThrow(/daily_habits_movement_check/);
    await expect(f.asUser(f.owner, (c) => c.query("UPDATE daily_habits SET moved = false, movement_minutes = 'ate_15' WHERE profile_id = $1", [f.primary]))).rejects.toThrow(/daily_habits_movement_check/);
  });
  it('deleting an author retains shared-profile data; deleting the owner cascades all owned habits', async () => {
    await f.asUser(f.manager, (c) => c.query('DELETE FROM users WHERE id = $1', [f.manager]));
    expect((await f.admin.query('SELECT user_id FROM daily_habits WHERE profile_id = $1', [f.dependent])).rows).toEqual([{ user_id: null }]);
    await f.asUser(f.owner, (c) => c.query('DELETE FROM users WHERE id = $1', [f.owner]));
    expect((await f.admin.query('SELECT * FROM daily_habits WHERE profile_id = ANY($1::uuid[])', [[f.primary, f.dependent]])).rows).toEqual([]);
  });
});
