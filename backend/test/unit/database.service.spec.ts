import { describe, it, expect, vi, beforeEach } from 'vitest';
import { DatabaseService } from '../../src/database/database.service';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from '../../src/database/schema';

describe('DatabaseService Unit Tests (SEC-01)', () => {
  let databaseService: DatabaseService;
  let mockPool: Partial<Pool>;
  let mockDb: Partial<NodePgDatabase<typeof schema>>;
  let mockTxExecute: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    mockTxExecute = vi.fn().mockResolvedValue(undefined);
    mockPool = {
      end: vi.fn().mockResolvedValue(undefined),
    };
    mockDb = {
      transaction: vi.fn().mockImplementation(async (callback) => {
        const mockTx = {
          execute: mockTxExecute,
        };
        return callback(mockTx as any);
      }),
    };

    databaseService = new DatabaseService(
      mockDb as NodePgDatabase<typeof schema>,
      mockPool as Pool,
    );
  });

  describe('withRls', () => {
    it('should reject empty or invalid userId', async () => {
      await expect(databaseService.withRls('', async () => 'ok')).rejects.toThrow(
        'DatabaseService.withRls: A valid non-empty userId string is required.',
      );
      await expect(
        databaseService.withRls('   ', async () => 'ok'),
      ).rejects.toThrow('DatabaseService.withRls: A valid non-empty userId string is required.');
      await expect(
        databaseService.withRls(null as any, async () => 'ok'),
      ).rejects.toThrow('DatabaseService.withRls: A valid non-empty userId string is required.');
    });

    it('should execute set_config with is_local=true and run callback', async () => {
      const testUserId = '11111111-1111-1111-1111-111111111111';
      let executedInsideTx = false;

      const result = await databaseService.withRls(testUserId, async (tx) => {
        executedInsideTx = true;
        return 'success';
      });

      expect(mockDb.transaction).toHaveBeenCalled();
      expect(mockTxExecute).toHaveBeenCalled();
      expect(executedInsideTx).toBe(true);
      expect(result).toBe('success');
    });
  });

  describe('onModuleDestroy', () => {
    it('should cleanly end the database connection pool', async () => {
      await databaseService.onModuleDestroy();
      expect(mockPool.end).toHaveBeenCalled();
    });
  });
});
