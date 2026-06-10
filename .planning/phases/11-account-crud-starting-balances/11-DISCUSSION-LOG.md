# Phase 11: Account CRUD & Starting Balances - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-10
**Phase:** 11-account-crud-starting-balances
**Areas discussed:** Account page format, Starting balance + chart model, Seed accounts on signup, Assets in balance chart

---

## Account Page Format

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone /accounts page | Dedicated page at /accounts route, like AssetsPage. Full CRUD table, create form, inline edit, delete with confirmation. Consistent with existing pattern. | ✓ |
| Settings section | Accounts as a section within a settings page. Less discoverable but centralized. | |
| Modal/overlay on dashboard | Account management as a modal triggered from dashboard. Quick access but limited space. | |

**User's choice:** Standalone /accounts page (Recommended)
**Notes:** Follows existing AssetsPage CRUD pattern.

| Option | Description | Selected |
|--------|-------------|----------|
| Name + type + currency + starting balance + date | Full set: name, type, currency (default PLN), starting_balance (default 0), starting_balance_date | ✓ |
| Name + type + starting balance only | Skip currency, skip date (use current month). Simpler form. | |
| Just name, starting balance in separate section | Account creation asks only name+type. Starting balance set separately. | |

**User's choice:** Name + type + currency + starting balance + date
**Notes:** Type and currency set at creation only, not editable after.

| Option | Description | Selected |
|--------|-------------|----------|
| Typed confirmation | User types "DELETE myaccount" to confirm. Prevents accidental deletion. | ✓ |
| Standard confirmation dialog | Simple "Are you sure?" dialog. Faster but easier to misclick. | |

**User's choice:** Typed confirmation (Recommended)
**Notes:** Matches financial data sensitivity — typed confirmation prevents accidental loss.

---

## Starting Balance + Chart Model

| Option | Description | Selected |
|--------|-------------|----------|
| Per-account sum with fallback | Sum accounts' starting_balance where date <= month. Fall back to monthly_opening_balances if no starting_balances set. | ✓ |
| Full replacement, migrate data | Per-account starting_balance completely replaces monthly_opening_balances. Migrate existing data. | |
| Dual system — both coexist | Both per-account starting_balance and monthly_opening_balances usable. | |

**User's choice:** Per-account sum with fallback (Recommended)
**Notes:** Clean backward compatibility for legacy users.

| Option | Description | Selected |
|--------|-------------|----------|
| Sum where date <= month | Sum all starting_balances where date <= current month. No-date accounts use earliest transaction month. | ✓ |
| Exact month match only | Only accounts with starting_balance_date exactly at chart's first month. | |

**User's choice:** Sum where date <= month (Recommended)
**Notes:** Simple and predictable behavior.

| Option | Description | Selected |
|--------|-------------|----------|
| Deprecate — leave in place | monthly_opening_balances data preserved, no new UI. Read-only fallback. | ✓ |
| Migrate existing data, then drop | Copy existing data to accounts, then drop table. | |

**User's choice:** Deprecate — leave in place (Recommended)
**Notes:** No migration needed for legacy data.

---

## Seed Accounts on Signup

| Option | Description | Selected |
|--------|-------------|----------|
| Keep defaults | 2 default accounts (ING Business, IPKO Personal) as now. Users can rename/delete. | ✓ |
| Single generic default | Create only 1 generic default account. | |
| No defaults | User creates all accounts from scratch. | |

**User's choice:** Keep defaults (Recommended)
**Notes:** Zero behavior change for signup flow.

| Option | Description | Selected |
|--------|-------------|----------|
| No, user sets balance later | Defaults get starting_balance=0, starting_balance_date=NULL. User configures manually. | ✓ |
| Yes, prompt for balance on first login | Signup hook prompts for starting balance during onboarding. | |
| Set date=signup_date, balance=0 | Token starting_balance=0 with date=signup_date. Baseline starts from join date. | |

**User's choice:** No, user sets balance later (Recommended)
**Notes:** Clean separation — signup creates accounts, user configures balances.

---

## Assets in Balance Chart

| Option | Description | Selected |
|--------|-------------|----------|
| Separate snapshots table | New table asset_value_snapshots(asset_id, value, date, notes). One asset can have many snapshots. | ✓ |
| Append-only assets table | No updated_at, each row is a named snapshot. Same name repeated = history. | |

**User's choice:** Separate snapshots table (Recommended)
**Notes:** Clean relational model with FK to assets.

| Option | Description | Selected |
|--------|-------------|----------|
| Change triggers snapshot silently | Edit value -> old value auto-archived to snapshots, new value becomes current. Transparent. | ✓ |
| Dedicated snapshot management | User explicitly adds snapshots with date+value. More manual. | |
| Monthly auto-snapshot | System auto-captures at end of each month. Combined with manual entries. | |

**User's choice:** Change triggers snapshot silently
**Notes:** Zero-friction UX. User edits asset value as normal, history is captured automatically.

| Option | Description | Selected |
|--------|-------------|----------|
| Forward-fill last known value | Last snapshot value carries forward to future months until newer snapshot. Standard financial pattern. | ✓ |
| Show only months with snapshots | Gaps in chart line. Honest but less useful. | |
| Use current value for all months | Most recent value applied to all months. Simplest but inaccurate historically. | |

**User's choice:** Forward-fill last known value
**Notes:** Standard time-series pattern for financial data.

**Scope decision for this area:** Folded into Phase 11 (not deferred to separate phase). User explicitly chose to include asset value history snapshots + combined net worth chart line in this phase.

---

*Phase: 11-Account CRUD & Starting Balances*
*Log created: 2026-06-10*
