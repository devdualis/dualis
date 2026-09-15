import { pgTable, uuid, varchar, date, timestamp, pgPolicy, text, boolean } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const users = pgTable(
  'users',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    name: varchar('name', { length: 255 }).notNull(),
    email: varchar('email', { length: 255 }).notNull().unique(),
    passwordHash: varchar('password_hash', { length: 255 }).notNull(),
    gender: varchar('gender', { length: 50 }).notNull(),
    dateOfBirth: date('date_of_birth'),
    picture: text('picture'),
    isEmailVerified: boolean('is_email_verified').default(false).notNull(),
    emailVerifiedAt: timestamp('email_verified_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    pgPolicy('users_patient_isolation', {
      for: 'all',
      using: sql`id = NULLIF(current_setting('app.current_user_id', true), '')::uuid OR current_setting('app.is_auth_service', true) = 'true'`,
      withCheck: sql`id = NULLIF(current_setting('app.current_user_id', true), '')::uuid`,
    }),
  ],
);

