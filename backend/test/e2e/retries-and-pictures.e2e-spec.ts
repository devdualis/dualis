import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { randomUUID } from 'node:crypto';
import { Test } from '@nestjs/testing';
import { ConflictException } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { JwtService } from '@nestjs/jwt';
import { DATABASE_POOL, DRIZZLE_DB } from '../../src/database/database.service';
import { AuthService } from '../../src/modules/auth/auth.service';
import { HydrationService } from '../../src/modules/hydration/hydration.service';
import { StorageService } from '../../src/common/storage/storage.service';
import { habitsDatabase } from '../support/habits-database';

/** Uploads get their own name, like the real storage; deletions are recorded. */
class RecordingStorage {
  uploads = 0;
  readonly removed: string[] = [];
  async processAvatarImage(userId: string, picture: string): Promise<string> {
    if (!picture.startsWith('data:image')) return picture;
    const name = ++this.uploads;
    // A slow upload, so overlapping saves really overlap.
    await new Promise((resolve) => setTimeout(resolve, 20));
    return `https://ref.supabase.co/storage/v1/object/public/avatars/${userId}/${name}.png`;
  }
  async removeAvatar(_userId: string, url: string | null | undefined): Promise<void> {
    if (url) this.removed.push(url);
  }
  async removeLeftoverAvatars(): Promise<void> {}
  async removeAvatars(): Promise<void> {}
}

const PNG = `data:image/png;base64,${Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0]).toString('base64')}`;

describe.skipIf(!process.env.TEST_DATABASE_URL)('Retries and picture changes on a real local database', () => {
  let f: Awaited<ReturnType<typeof habitsDatabase>>;
  let hydration: HydrationService;
  let auth: AuthService;
  const storage = new RecordingStorage();

  beforeAll(async () => {
    f = await habitsDatabase();
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(DATABASE_POOL).useValue(f.appPool)
      .compile();
    hydration = module.get(HydrationService);
    // Built by hand: vitest emits no decorator metadata, so Nest would leave the optional
    // storage out. The database is the real one, under the non-superuser app role.
    auth = new AuthService(
      module.get(DRIZZLE_DB),
      module.get(JwtService),
      {} as any,
      {} as any,
      storage as unknown as StorageService,
    );
  });
  afterAll(async () => { if (f) await f.close(); });

  it('a water log sent again with its client id is saved once', async () => {
    const clientId = randomUUID();
    const first = await hydration.logWater(f.owner, f.primary, { amountMl: 300, clientId });
    const retry = await hydration.logWater(f.owner, f.primary, { amountMl: 300, clientId });

    expect(first.id).toBe(clientId);
    expect(retry).toEqual(first);
    const rows = await f.admin.query('SELECT amount_ml FROM water_intake_logs WHERE profile_id = $1', [f.primary]);
    expect(rows.rows).toEqual([{ amount_ml: 300 }]);
    expect((await hydration.getTodayLogs(f.owner, f.primary)).todayTotalMl).toBe(300);
  });

  it('a client id already used by another profile is refused, never shown', async () => {
    const clientId = randomUUID();
    await hydration.logWater(f.owner, f.primary, { amountMl: 250, clientId });

    await expect(
      hydration.logWater(f.stranger, f.foreign, { amountMl: 999, clientId }),
    ).rejects.toBeInstanceOf(ConflictException);
    const foreign = await f.admin.query('SELECT 1 FROM water_intake_logs WHERE profile_id = $1', [f.foreign]);
    expect(foreign.rowCount).toBe(0);
  });

  it('older app versions without a client id still add each log', async () => {
    await hydration.logWater(f.owner, f.dependent, { amountMl: 200 });
    await hydration.logWater(f.owner, f.dependent, { amountMl: 200 });
    const rows = await f.admin.query('SELECT 1 FROM water_intake_logs WHERE profile_id = $1', [f.dependent]);
    expect(rows.rowCount).toBe(2);
  });

  it('overlapping picture saves never delete the picture in use', async () => {
    const initial = `https://ref.supabase.co/storage/v1/object/public/avatars/${f.owner}/0.png`;
    await f.admin.query('UPDATE users SET picture = $1 WHERE id = $2', [initial, f.owner]);

    await Promise.all([
      auth.updateProfile(f.owner, { picture: PNG }),
      auth.updateProfile(f.owner, { picture: PNG }),
    ]);

    const current = (await f.admin.query('SELECT picture FROM users WHERE id = $1', [f.owner])).rows[0].picture;
    expect(current).toMatch(/\/[12]\.png$/);
    expect(storage.removed).not.toContain(current);
    // Each save deleted exactly the picture it replaced: the first upload and the old one.
    expect([...storage.removed].sort()).toEqual(
      [initial, current.endsWith('1.png') ? current.replace('1.png', '2.png') : current.replace('2.png', '1.png')].sort(),
    );
  });
});
