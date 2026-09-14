import { Global, Module, Provider } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool, PoolConfig } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import { DatabaseService, DRIZZLE_DB, DATABASE_POOL } from './database.service';
import * as schema from './schema';

const databasePoolProvider: Provider = {
  provide: DATABASE_POOL,
  inject: [ConfigService],
  useFactory: (configService: ConfigService): Pool => {
    const connectionString =
      configService.get<string>('DATABASE_URL') ||
      'postgresql://postgres:postgres@localhost:5432/dualis_dev';

    const isLocal =
      connectionString.includes('localhost') ||
      connectionString.includes('127.0.0.1');

    const isSupabase = connectionString.includes('supabase.co');

    let ssl: PoolConfig['ssl'] = undefined;

    if (!isLocal) {
      if (isSupabase || configService.get('DATABASE_SSL_REJECT_UNAUTHORIZED') === 'false') {
        ssl = { rejectUnauthorized: false };
      } else if (configService.get('DATABASE_CA_CERT')) {
        ssl = {
          rejectUnauthorized: true,
          ca: configService.get<string>('DATABASE_CA_CERT'),
        };
      }
    }

    const poolConfig: PoolConfig = {
      connectionString,
      ssl,
      max: 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    };

    return new Pool(poolConfig);
  },
};

const drizzleProvider: Provider = {
  provide: DRIZZLE_DB,
  inject: [DATABASE_POOL],
  useFactory: (pool: Pool) => {
    return drizzle(pool, { schema });
  },
};

@Global()
@Module({
  providers: [databasePoolProvider, drizzleProvider, DatabaseService],
  exports: [DRIZZLE_DB, DATABASE_POOL, DatabaseService],
})
export class DatabaseModule {}
