import { sql } from 'drizzle-orm';
import { boolean, pgPolicy, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';
import { users } from './users.schema';

// Only the backend may write verified access. Never expose this table for
// client updates through PostgREST, including updates by the owning user.
export const subscriptions = pgTable('subscriptions', {
  userId: uuid('user_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  entitlementId: text('entitlement_id').notNull(),
  isPremium: boolean('is_premium').notNull().default(false),
  expiresAt: timestamp('expires_at', { withTimezone: true }),
  managementUrl: text('management_url'),
  environment: text('environment'),
  verifiedAt: timestamp('verified_at', { withTimezone: true }).notNull(),
}, (table) => [pgPolicy('subscriptions_backend_owner', {
  for: 'all',
  using: sql`current_user NOT IN ('anon', 'authenticated') AND ${table.userId} = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
  withCheck: sql`current_user NOT IN ('anon', 'authenticated') AND ${table.userId} = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
})]);
