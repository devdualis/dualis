import { Injectable, Inject, OnModuleDestroy } from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { sql } from 'drizzle-orm';
import * as schema from './schema';

export const DRIZZLE_DB = Symbol('DRIZZLE_DB');
export const DATABASE_POOL = Symbol('DATABASE_POOL');

export type DrizzleTransaction = Parameters<
  Parameters<NodePgDatabase<typeof schema>['transaction']>[0]
>[0];

@Injectable()
export class DatabaseService implements OnModuleDestroy {
  constructor(
    @Inject(DRIZZLE_DB) public readonly db: NodePgDatabase<typeof schema>,
    @Inject(DATABASE_POOL) public readonly pool: Pool,
  ) {}

  /**
   * Executes a callback within a dedicated PostgreSQL transaction where
   * app.current_user_id is strictly set for the transaction lifetime.
   * is_local = true guarantees the setting automatically resets at COMMIT or ROLLBACK.
   */
  async withRls<T>(
    userId: string,
    callback: (tx: DrizzleTransaction) => Promise<T>,
  ): Promise<T> {
    if (!userId || typeof userId !== 'string' || userId.trim().length === 0) {
      throw new Error('DatabaseService.withRls: A valid non-empty userId string is required.');
    }

    return this.db.transaction(async (tx) => {
      // is_local = true ensures setting automatically resets on COMMIT/ROLLBACK
      await tx.execute(
        sql`SELECT set_config('app.current_user_id', ${userId}, true)`,
      );
      return callback(tx);
    });
  }

  async onModuleDestroy(): Promise<void> {
    await this.pool.end();
  }
}
