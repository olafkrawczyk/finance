# Phase 11: Account CRUD & Starting Balances - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can create, rename, and delete accounts from the UI, set per-account starting balances (with date), and see accurate balance-over-time charts that use per-account starting balances as the baseline. Additionally, asset value history snapshots are stored append-only, and a combined net worth chart line shows bank balance + asset values for each month.

</domain>

<spec_lock>
## Requirements (locked via SPEC.md)

**6 requirements are locked.** See `11-SPEC.md` for full requirements, boundaries, and acceptance criteria.

Downstream agents MUST read `11-SPEC.md` before planning or implementing. Requirements are not duplicated here.

**In scope (from SPEC.md):**
- Backend account CRUD use-cases (create, read, update, delete) + routes
- Frontend account management page (list, create form, rename, delete with confirmation)
- Migration: add `starting_balance` and `starting_balance_date` to accounts table
- Migration: add `UNIQUE(user_id, name)` to accounts table
- Starting balance input in account create form
- Starting balance edit in account detail view
- `getMonthlySummary` updated to use per-account aggregated starting balances
- Delete guard (409 on accounts with transactions)
- Zod validation schemas for account CRUD

**Out of scope (from SPEC.md):**
- Modifying `monthly_opening_balances` table schema (adding account_id) — replaced by per-account starting balance approach instead
- Transfers between accounts — separate feature for future phase
- Account reconciliation / balance verification — future enhancement
- Account archiving (soft-delete) — future enhancement
- Historical starting balance editing for past dates — only set at creation time
- Multiple currencies / exchange rate handling — no currency conversion in scope

**Assets integration (expanded from SPEC — now in scope per discussion):**
- New `asset_value_snapshots` table for append-only value history
- Combined net worth chart line (bank balance + asset values)
- Auto-archive on asset value change

</spec_lock>

<decisions>
## Implementation Decisions

### Account Page Format
- **D-01:** Standalone `/accounts` page (like `AssetsPage`) — not a settings section or modal. Follows the existing CRUD page pattern from AssetsPage.tsx.
- **D-02:** Create/edit form includes: name (required), type (personal/business), currency (default PLN, set at creation only), starting_balance (default 0), starting_balance_date (date picker). Type and currency are set at creation and not editable after.
- **D-03:** Delete requires typed confirmation — user types `DELETE <account_name>` to confirm. Not a simple "Are you sure?" dialog. Prevents accidental deletion.

### Starting Balance + Chart Model
- **D-04:** `getMonthlySummary` sums all accounts' `starting_balance` where `starting_balance_date <= month_start` as the initial baseline. If no accounts have `starting_balance` set (e.g., legacy users with `starting_balance=0`), fall back to `monthly_opening_balances` for backward compatibility.
- **D-05:** Date logic: sum of all starting_balances where `starting_balance_date <= current_month`. For accounts with `starting_balance_date=NULL` and `starting_balance > 0`, treat the starting_balance as effective from the earliest transaction month.
- **D-06:** `monthly_opening_balances` table is deprecated — left in place with data preserved, no new UI for it. Serves as read-only fallback for legacy users who set balances before this phase. No migration to copy its data.

### Seed Accounts on Signup
- **D-07:** Keep existing behavior: signup hook in `src/auth.ts` creates 2 default accounts (ING Business, IPKO Personal). Users can rename/delete them later.
- **D-08:** Default accounts get `starting_balance=0` and `starting_balance_date=NULL`. User sets starting balance manually via the account edit view.

### Asset Value Snapshots (folded into scope per discussion)
- **D-09:** New table `asset_value_snapshots(asset_id, value, date, notes)` — append-only history per asset. Linked to `assets(id)` with FK. Each snapshot tracks the asset's value at a specific point in time. No deletion of historic snapshots.
- **D-10:** Change triggers snapshot silently: when the user edits an asset's value in the Assets page, the old value is automatically archived as a snapshot, and the new value replaces the `assets.value` field. The user does not manually manage snapshots — the system does it transparently.
- **D-11:** Combined net worth chart line in `getMonthlySummary`: for each month, compute `bank_balance` (from per-account starting_balance + transaction running balance) + `total_assets_value` (forward-filled from the last asset snapshot on or before that month's end). Display as a separate line on the balance chart.
- **D-12:** Forward-fill for missing snapshots: if no snapshot exists for a given month, carry forward the most recent snapshot value. Standard time-series pattern for financial data.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Spec (locked requirements)
- `.planning/phases/11-account-crud-starting-balances/11-SPEC.md` — Locked requirements, boundaries, and acceptance criteria for Phase 11

### Prior Phase Context
- `.planning/phases/10-frontend-cache-isolation/10-CONTEXT.md` — React Query patterns (per-user key scoping, CacheManager, mutation invalidation)
- `.planning/phases/07-backend-scoping/07-CONTEXT.md` — Route handler userId extraction, use-case params object pattern, scoping

### Backend Source Files
- `src/core/reference/use-cases.ts` — Existing `listAccounts()` — account CRUD use-cases go here
- `src/interface-adapters/api/reference.ts` — Existing `GET /accounts` route — new CRUD routes go here
- `src/core/ledger/use-cases.ts` — `getMonthlySummary()` — update balance computation + add combined net worth line
- `src/core/assets/use-cases.ts` — Existing asset CRUD — add snapshot creation logic
- `src/interface-adapters/api/assets.ts` — Existing asset routes — add snapshot endpoints or modify update
- `src/application/schemas/assets.ts` — Zod validation schemas for assets
- `src/auth.ts` — Signup hook creating default accounts (ING Business, IPKO Personal)

### Frontend Source Files
- `frontend/src/pages/AssetsPage.tsx` — CRUD page pattern to follow for AccountPage
- `frontend/src/api.ts` — API fetch functions — add account CRUD + asset snapshot functions
- `frontend/src/lib/query/hooks.ts` — React Query hooks — add account mutation hooks
- `frontend/src/lib/query/queryKeys.ts` — Query key factory — add account keys
- `frontend/src/lib/query/client.ts` — QueryClient setup with defaults
- `frontend/src/App.tsx` — Route definitions — add `/accounts` route
- `frontend/src/components/` — Existing UI components to reuse

### Database / Migrations
- `src/infrastructure/db/migrations/` — Migration files directory (new migrations: 012 for starting_balance columns, 013 for UNIQUE(user_id, name), 014 for asset_value_snapshots table)
- `src/infrastructure/db/schema.sql` — Current schema reference

### Spike Findings
- `.opencode/skills/spike-findings-finance/references/import-dedup.md` — Import dedup pattern, UNIQUE constraint patterns
- `.opencode/skills/spike-findings-finance/references/transaction-crud.md` — CRUD patterns from prior spikes

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `frontend/src/pages/AssetsPage.tsx` — Full CRUD page pattern: table list, add form (right panel), inline edit, delete with confirmation. Direct template for AccountPage.
- `frontend/src/lib/query/hooks.ts` — `useAssets()`, `useCreateAsset()`, `useUpdateAsset()`, `useDeleteAsset()` — mutation/query hook pattern to follow for accounts
- `frontend/src/lib/query/queryKeys.ts` — Per-user key factory pattern: `['user', userId, 'accounts']`, `['user', userId, 'assetValueSnapshots']`
- `src/core/reference/use-cases.ts` — `listAccounts()` — same file for new CRUD use-cases
- `src/core/assets/use-cases.ts` — `listAssets`, `createAsset`, `updateAsset`, `deleteAsset` — full CRUD pattern to mirror for accounts
- `src/interface-adapters/api/reference.ts` — Existing `GET /accounts` route — same file for CRUD routes
- `frontend/src/components/MonthSidebar.tsx` — Currently displays opening balance; will reference per-account starting balances

### Established Patterns
- **Backend:** Hono router, Zod validation schemas, use-cases with params object, userId from session
- **Frontend:** React Query with per-user key scoping (`['user', userId, ...]`), broad mutation invalidation (`queryClient.invalidateQueries({ queryKey: ['user', userId] })`)
- **CRUD page:** AssetsPage.tsx pattern — list table + side panel create form + inline row edit + confirm delete
- **Migration:** node-pg-migrate, sequential numbered files (008–011 exist), `up()`/`down()` functions
- **Loading states:** Skeleton components on `isPending`, background refetch on `isFetching`

### Integration Points
- `src/core/reference/use-cases.ts` — Add `createAccount`, `updateAccount`, `deleteAccount`
- `src/interface-adapters/api/reference.ts` — Add `POST /accounts`, `PUT /accounts/:id`, `DELETE /accounts/:id`
- `src/core/ledger/use-cases.ts` — Modify `getMonthlySummary()`: replace global `monthly_opening_balances` with per-account aggregated starting balances; add combined net worth line with asset snapshots forward-fill
- `src/core/assets/use-cases.ts` — Modify `updateAsset()` to create a snapshot before overwriting value; add `listAssetSnapshots(assetId)` read
- `src/interface-adapters/api/assets.ts` — Add `GET /assets/:id/snapshots` endpoint
- `frontend/src/api.ts` — Add `createAccount()`, `updateAccount()`, `deleteAccount()`, `getAccountSnapshots()`
- `frontend/src/lib/query/queryKeys.ts` — Add account and asset snapshot key factories
- `frontend/src/lib/query/hooks.ts` — Add `useAccounts()`, `useCreateAccount()`, `useUpdateAccount()`, `useDeleteAccount()`, `useAssetSnapshots()`
- `frontend/src/App.tsx` — Add route for `/accounts` -> AccountPage
- `frontend/src/pages/` — Create `AccountPage.tsx` (following AssetsPage.tsx pattern)
- `frontend/src/pages/AssetsPage.tsx` — Modify to auto-create snapshot on value change
- `frontend/src/charts/` — Add combined net worth line to `BalanceChart.tsx` or `ComboChart.tsx`
- `src/infrastructure/db/migrations/` — Add migration 012 (starting_balance + starting_balance_date), 013 (UNIQUE user_id, name), 014 (asset_value_snapshots table)
- `src/infrastructure/db/schema.sql` — Update after all migrations defined

### Creative Options
- BalanceChart could show 2 lines: bank balance (existing) and total net worth (new) — toggleable overlay or stacked

</code_context>

<specifics>
## Specific Ideas

- **Asset snapshots as append-only history:** Every value change to an asset auto-creates a snapshot. Modeled as separate `asset_value_snapshots` table with FK to assets. Forward-filled for months without explicit snapshots.
- **Combined net worth line:** Chart shows "Stan konta" (bank balance) as existing line, plus "Wartość netto" (bank + assets) as a separate line. User can toggle visibility.

</specifics>

<deferred>
## Deferred Ideas

None — all discussed areas are folded into this phase.

</deferred>

---

*Phase: 11-Account CRUD & Starting Balances*
*Context gathered: 2026-06-10*
