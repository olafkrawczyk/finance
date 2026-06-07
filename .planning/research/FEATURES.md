# Feature Landscape: Multi-Tenant Data Isolation

**Domain:** Financial Planning Application — Single-User to Multi-Tenant Migration
**Researched:** 2026-06-07
**Overall confidence:** HIGH

## Context

The app (v1.0 MVP) is fully built but uses a single-user data model. All users share accounts, categories, and transactions. The `insights` table is the **only** table already scoped by `user_id`. This migration adds per-user data isolation — each user sees only their own data, with no sharing or RBAC.

**Existing auth:** Better Auth (email/password + OAuth) is integrated. `requireAuth` middleware provides `c.get('user')` in route handlers.

---

## Table Stakes

Features that **every** multi-tenant migration must implement. Missing any = data leaks between users = application is broken.

### T-1: user_id Column on All Domain Tables

| Table | Has user_id? | Migration Action |
|-------|-------------|------------------|
| `accounts` | ❌ | ADD COLUMN `user_id TEXT NOT NULL REFERENCES "user"(id)` |
| `categories` | ❌ | ADD COLUMN `user_id TEXT NOT NULL REFERENCES "user"(id)` |
| `transactions` | ❌ | ADD COLUMN `user_id TEXT NOT NULL REFERENCES "user"(id)` |
| `monthly_opening_balances` | ❌ | ADD COLUMN `user_id TEXT NOT NULL REFERENCES "user"(id)` |
| `assets` | ❌ | ADD COLUMN `user_id TEXT NOT NULL REFERENCES "user"(id)` |
| `import_jobs` | ❌ | ADD COLUMN `user_id TEXT NOT NULL REFERENCES "user"(id)` |
| `insights` | ✅ Already has: `user_id TEXT NOT NULL REFERENCES "user"(id)` | None needed |

**Key constraint:** Better Auth `"user"."id"` is `TEXT` (e.g., `"user_abc123"`), not `UUID`. Domain table PKs are `UUID`. The `user_id` FK column **must** be `TEXT` to match the parent type. The `insights` table already demonstrates this pattern correctly.

**Why `user_id` on transactions and not rely on account_id → user_id join:**
- Direct `user_id` on transactions avoids a join on every transaction query
- Prevents cross-account attacks (create a transaction in another user's account by guessing an account UUID)
- Simpler RLS policies and query filters
- Standard practice for row-level isolation

**Complexity:** MEDIUM (schema migration + data backfill + NOT NULL enforcement)

### T-2: Query Scoping — Every SQL Query Filters by user_id

Every `SELECT`, `INSERT`, `UPDATE`, `DELETE` on scoped tables must include `user_id = ${userId}`.

**Current pattern (breaks multi-tenant):**
```typescript
// reference.ts
const rows = await sql`SELECT * FROM accounts ORDER BY name`;
```

**Required pattern:**
```typescript
const userId = c.get('user').id;
const rows = await sql`SELECT * FROM accounts WHERE user_id = ${userId} ORDER BY name`;
```

**Locations to audit and modify:**

| File | Table(s) Queried | Scope Change |
|------|------------------|-------------|
| `reference.ts` | accounts, categories | Add WHERE user_id |
| `ledger.ts` | transactions | Add WHERE user_id on list, get, update, delete |
| `use-cases/ledger.ts` | transactions, monthly_opening_balances | Add user_id param to every query |
| `use-cases/assets.ts` | assets | Add WHERE user_id on all ops |
| `import.ts` | import_jobs | Add WHERE user_id on status check |
| `use-cases/import.ts` | import_jobs | Inject user_id in INSERT + SELECT |

**Key insight:** The `insights` routes already follow the correct pattern — they extract `user.id` from `c.get('user')` and pass it to use-cases. This is the model to replicate.

**Complexity:** MEDIUM (mechanical change across ~15-20 query locations, but each change is straightforward)

### T-3: INSERTs Include user_id

Every `INSERT` statement on scoped tables must include `user_id`:

```typescript
// Before
INSERT INTO accounts (name, type, currency) VALUES (...)

// After
INSERT INTO accounts (name, type, currency, user_id) VALUES (${name}, ${type}, ${currency}, ${userId})
```

**Affected operations:** createAccount, createCategory, createTransaction, createAsset, createOpeningBalance, enqueueImportJob

**Complexity:** LOW (mechanical, just adding one column to INSERTs)

### T-4: Foreign Key Constraints Are user_id-Aware

Existing UNIQUE constraints may break with user_id:

| Table | Constraint | Problem |
|-------|-----------|---------|
| `categories.name` | `UNIQUE` | Users can't have same-named categories. Should become `UNIQUE(user_id, name)` |
| `assets.name` | `UNIQUE` | Same issue. Should become `UNIQUE(user_id, name)` |
| `transactions.import_hash` | `UNIQUE` | Import hashes must be unique per user. Should become `UNIQUE(user_id, import_hash)` |
| `monthly_opening_balances` | `UNIQUE(year, month)` | Should become `UNIQUE(user_id, year, month)` |

**Migration order:**
1. DROP existing UNIQUE constraints
2. ADD COLUMN user_id (nullable initially for backfill)
3. Backfill user_id for existing rows (see T-6)
4. ADD new composite UNIQUE constraints including user_id
5. ALTER COLUMN user_id SET NOT NULL

**Complexity:** MEDIUM (constraint changes require careful ordering)

### T-5: INSERT/UPDATE Authorization Checks

Even with `user_id` on tables, every mutation should verify the user owns referenced resources:

```typescript
// When creating a transaction for account_id X, verify account belongs to user
const [account] = await sql`
  SELECT 1 FROM accounts WHERE id = ${input.account_id} AND user_id = ${userId}
`;
if (!account) throw new Error('Account not found');
```

This prevents:
- Creating transactions in another user's account
- Assigning another user's categories to your transactions
- Cross-user data injection via ID guessing

**Complexity:** LOW (defense-in-depth, ~1 extra query per mutation)

### T-6: Existing Data Gets Assigned to the "Original" User

The app currently has data in the database (accounts, categories, transactions, etc.). This data must belong to **some** user after migration.

**Approach:**
1. Identify the "owner" user — the existing user(s) who created this data. If there's only one user (MVP stage), this is easy.
2. Migration SQL backfills `user_id` for all existing rows.
3. If multiple users exist and data is commingled (e.g., User A added some categories, User B added others, everyone sees everything), there's no clean automated split. Options:
   - **Option A (Preferable):** Assign all existing data to the first registered admin user. Other users start fresh.
   - **Option B:** Run a manual reconciliation — create duplicate categories/accounts per user.
   - **Option C (If data is truly shared):** Designate an "owner" and have other users re-create their data.

**Recommendation for this app:** Since v1.0 was single-user, there's effectively one user (the developer). Assign all existing data to that user. This is the simplest and correct approach.

**Migration SQL pattern:**
```sql
UPDATE accounts SET user_id = '${existing_user_id}' WHERE user_id IS NULL;
UPDATE categories SET user_id = '${existing_user_id}' WHERE user_id IS NULL;
UPDATE transactions SET user_id = '${existing_user_id}' WHERE user_id IS NULL;
-- etc for all scoped tables
```

**Complexity:** LOW (simple UPDATE queries, but requires knowing which user(s) own the data)

---

## Differentiators

Features beyond basic isolation that provide real value.

### D-1: Row-Level Security (RLS) as Defense-in-Depth

**What:** Enable Postgres RLS on all scoped tables with a policy like:
```sql
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_isolation ON accounts
  USING (user_id = current_setting('app.current_user_id')::TEXT);
```

**Why this matters:**
- Catches any query that forgot the `WHERE user_id = ?` clause (acts as a safety net)
- Prevents data leaks even if a new developer adds a query without scoping
- Provides security even if the application layer has a bug

**Implementation challenge:** Postgres RLS relies on `current_user` or `current_setting`. The app uses raw `sql` template tag queries (not an ORM), so you'd need to set `SET LOCAL app.current_user_id = 'user_xxx'` at the start of each request via Hono middleware.

**Worth it for this app?** YES — financial data is sensitive, and RLS is a cheap safety net. However, it adds complexity to the connection pool setup (must set session variables per request). **Recommended as a stretch goal** after the application-layer scoping is solid.

**Complexity:** HIGH (requires connection pooling changes, session variable management, testing)

### D-2: Seed Data on Signup — Default Categories and Account

**What:** When a new user registers, automatically create sensible defaults so they don't start with a blank slate.

**Seed categories (common Polish personal finance categories):**

| Name | Type | is_fixed_cost |
|------|------|--------------|
| Wynagrodzenie | income | false |
| Sprzedaż | income | false |
| Inny przychód | income | false |
| Mieszkanie (czynsz) | expense | true |
| Media (prąd/gaz) | expense | true |
| Jedzenie | expense | false |
| Transport | expense | false |
| Zdrowie | expense | false |
| Rozrywka | expense | false |
| Ubrania | expense | false |
| Oszczędności | expense | false |
| Inny wydatek | expense | false |

**Seed account:**
| Name | Type | Currency |
|------|------|----------|
| Konto główne | personal | PLN |

**Implementation:**
```typescript
// Using Better Auth's databaseHooks (the cleanest approach)
export const auth = betterAuth({
  databaseHooks: {
    user: {
      create: {
        after: async (user) => {
          // These run in a background context — need direct DB access
          await seedDefaultData(user.id);
        },
      },
    },
  },
});
```

**Alternative:** Seed lazily — check on first API request if user has categories, create if empty. This is more resilient (handles failed signup hooks gracefully) but slightly more complex.

**Recommended approach:** **Lazy seeding** — it's more robust. The signup flow can fail for many reasons (network, DB timeout), and lazy seeding ensures defaults are always created eventually.

```typescript
// In reference routes or a middleware
async function ensureUserSeeded(userId: string) {
  const [hasCategories] = await sql`
    SELECT EXISTS(SELECT 1 FROM categories WHERE user_id = ${userId}) AS has
  `;
  if (!hasCategories.has) {
    await seedDefaultCategories(userId);
    await seedDefaultAccount(userId);
  }
}
```

**Complexity:** LOW (well-understood pattern, Better Auth hooks are well-documented)

### D-3: Migration Without Downtime

**What:** Add columns as nullable, backfill, add NOT NULL, deploy — all while the app is running.

**Migration strategy:**
1. **Phase A (no downtime):** Add `user_id` columns as NULLABLE. Add composite indexes on `(user_id, ...)` for common query patterns. Backfill existing data.
2. **Phase B (brief deployment window):** Add NOT NULL constraint. Deploy code that always provides user_id.
3. Between Phase A and B, the app runs with a mix — old code may insert rows without user_id, new code always provides it.

**For a self-hosted app with controlled deployments** (which this is), a brief maintenance window is simpler and acceptable. The phased approach is only needed for SaaS with uptime SLAs.

**Complexity:** LOW for self-hosted (just schedule 15-30 min of downtime); MEDIUM for zero-downtime

### D-4: Data Export / Deletion Per User

**What:** When a user deletes their account, all their data is cleaned up via `ON DELETE CASCADE` on `user_id` foreign keys.

**Status:** The FK to `"user"(id)` already has `ON DELETE CASCADE` on `insights`. Adding `user_id` FKs to other tables with `ON DELETE CASCADE` means Better Auth user deletion automatically cascades. However, **verify carefully** — accidental user deletion would nuke all financial data. Consider `ON DELETE SET NULL` or a soft-delete approach for safety.

**Complexity:** MEDIUM (depends on whether you want hard cascade or soft-delete business logic)

---

## Anti-Features

Things that seem good for multi-tenancy but create problems in this context.

### A-1: Organization / Team Accounts (Better Auth Organization Plugin)

**Why tempting:** Better Auth has a built-in `organization` plugin for multi-tenant teams, shared accounts, and memberships.

**Why avoid:** The project explicitly scopes this milestone to "Basic multi-tenant data isolation — no sharing, no RBAC." The Organization plugin adds:
- Invitation flows
- Role management (owner/admin/member)
- Organization-scoped data model
- Invitation acceptance/rejection

None of these are needed. The Organization plugin solves *collaborative* multi-tenancy (teams sharing data), not *isolated* multi-tenancy (each user has their own data). Using it would add unnecessary complexity.

**Instead:** Simple `user_id` column per table. No organization abstraction.

### A-2: Full Row-Level Security as the Primary Isolation Mechanism

**Why tempting:** RLS is Postgres-native and "automatic" — enable it and forget it.

**Why avoid:**
- RLS only works if the connection has the right session variables set
- The app uses raw SQL via a `sql` template tag — not all queries go through the same connection setup
- RLS errors surface as generic Postgres errors, hard to debug
- RLS bypass is silent for table owners (developers can accidentally bypass in admin queries)

**Instead:** Use **application-layer scoping** (explicit `WHERE user_id = ?`) as the primary mechanism, and consider RLS as a defense-in-depth layer only after application scoping is solid.

### A-3: User-Specific Database Schemas / Separate Databases

**Why tempting:** "What if each user gets their own Postgres schema or even a separate database?" Complete isolation, no leak risk.

**Why avoid:**
- Massive operational complexity — connection pooling, migrations across N schemas
- Can't query across users for analytics
- Migration overhead: every schema change must be applied N times
- Not justified for personal finance data (not PCI/HIPAA level)

**Instead:** Shared tables with `user_id` column. This handles financial data isolation perfectly.

### A-4: Soft Deletes via "Isolation" (user_id as Deleted Flag)

**Why tempting:** Some ORMs encourage "soft delete" as a pattern where `user_id = NULL` means "deleted."

**Why avoid:** This confuses two concerns — ownership and deletion. A row with no owner is an orphan, not a ghost. Use explicit `deleted_at TIMESTAMPTZ` for soft deletes if needed.

**Instead:** Keep `user_id NOT NULL` always. If you need soft delete, add a separate `deleted_at` column.

### A-5: Sharing Features (Read-Only Links, View-Only Access)

**Why tempting:** "What if User A wants to share their budget with User B?"

**Why avoid:** This introduces RBAC, sharing grants, access control lists — a massive scope expansion. The milestone is specifically "no sharing." Sharing can be a future milestone with its own design phase.

**Instead:** Defer to post-v1.1. The data model with `user_id` scoping can be extended later with sharing tables if needed (e.g., `shared_access` table mapping `viewer_user_id → owner_user_id`).

---

## Feature Dependencies

```
Auth (Better Auth, already built)
  └─> user_id column migration (add columns, backfill, enforce NOT NULL)
        ├─> Query scoping (every SQL query adds WHERE user_id = ?)
        │     └─> Seed data on signup (default categories + account for new users)
        ├─> UNIQUE constraint updates (DROP old, ADD composite)
        └─> Existing user data assignment (backfill "original" user's ID)
              └─> Potential rollout to existing users
```

## MVP Recommendation (for this milestone)

**Must ship:**
1. **user_id columns** on all domain tables (migration + FK constraints)
2. **Query scoping** — every SQL query references user_id
3. **INSERT user_id** — every insert includes user_id
4. **UNIQUE constraint migration** — composite UNIQUE(user_id, ...)
5. **Existing data backfill** — assign all existing rows to the original user
6. **Seed data on signup** — lazy seeding of default categories + default account

**Defer to stretch:**
- RLS (defense-in-depth, adds connection management complexity)
- Data export per user (not urgent for v1.1)
- Soft-delete support (not needed yet)

**Not building (explicit):**
- Organization/team accounts
- Sharing/permissions/RBAC
- User-specific schemas or databases

## Implementation Order Recommendation

1. **Migration setup** (column additions, FK constraints, index creation — all nullable initially)
2. **Backfill existing data** (assign current rows to "original" user)
3. **Enforce NOT NULL** (alter columns after backfill)
4. **Update UNIQUE constraints** (drop old, add composite)
5. **Code changes — use-cases** (add userId param to every function)
6. **Code changes — route handlers** (extract user.id, pass to use-cases)
7. **Seed data on signup** (lazy seeding in reference routes)
8. **Defense-in-depth checks** (verify ownership on mutations)

## Sources

- [Better Auth Database Hooks Documentation](https://www.better-auth.com/docs/concepts/database) — verified HIGH confidence: `databaseHooks.user.create.after` is the correct hook for post-signup seeding
- [Better Auth Hooks Documentation](https://www.better-auth.com/docs/concepts/hooks) — verified HIGH confidence: `hooks.after` for sign-up endpoint also works for seeding
- [PostgreSQL Row-Level Security Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html) — verified HIGH confidence: RLS patterns for multi-tenant isolation
- Existing codebase analysis (`insights.ts` pattern for user scoping, `reference.ts` for unscoped queries) — verified HIGH confidence
- Domain experience with multi-tenant migrations — MEDIUM confidence (applied patterns from YNAB, Actual Budget, Firefly III architecture)
