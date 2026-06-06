---
date: "2026-06-07 00:30"
promoted: false
---

# Feature Exploration: New Dashboard Tiles and Chart Formatting

This document outlines the proposal and design considerations for implementing two new tiles on the dashboard and correcting the number formatting on the charts.

## 1. Total Net Value Tile

### Objective
A dashboard tile showing the combined value of all assets (cash, investments, bonds, silver, etc.) with a separate management page to configure and update these asset values.

### Database Design
We propose a new `assets` table:
```sql
CREATE TABLE IF NOT EXISTS assets (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL UNIQUE,
  value      NUMERIC(19, 4) NOT NULL CHECK (value >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### API Endpoints
- `GET /assets` - Fetch all assets
- `POST /assets` - Create a new asset type
- `PUT /assets/:id` - Update the value or name of an existing asset
- `DELETE /assets/:id` - Remove an asset type

### Frontend UI
- **Dashboard Tile:** A prominent card displaying "Całkowita wartość netto" (Total Net Value) as the sum of all assets, with a button/link to "Zarządzaj aktywami" (Manage Assets).
- **Assets Page (`/assets`):** A dedicated page accessible from the header navigation to add new assets, edit names, update current values, and delete assets.

---

## 2. Current Month Summary Tile

### Objective
A dashboard tile showing three key numbers for the current month:
1. **Expenses (Wydatki)**
2. **Income (Przychody)**
3. **Savings (Zaoszczędzone)**

### Data Fetching
- We can extract the current month's numbers from the existing `/transactions/summary` data by matching the current year and month (e.g. `2026-06` for June 2026).
- If the current calendar month has no transaction data yet, we can fallback to the most recent month available in the dataset, or display zero/empty states.

---

## 3. Chart Number Formatting

### Objective
Align chart tooltips and Y-axis labels with the `pl-PL` formatting used in the table views (space separator for thousands, comma for decimals).

### Implementation
- **Tooltips:** Use the Recharts `<Tooltip formatter={(value) => ...} />` with the `Intl.NumberFormat('pl-PL')` formatter.
- **Y-Axis:** Use `<YAxis tickFormatter={(value) => ...} />` to format ticks cleanly (e.g., using spaces as thousands separators).

---

## 4. Confirmed Design Decisions

Based on the Socratic ideation session, we have aligned on the following implementation details:
1. **Cash Tracking:** Cash will be tracked manually as a customizable asset line item alongside other asset types (like investments, bonds, silver). This keeps the asset model uniform and fully editable.
2. **History tracking:** Only the current snapshot value of each asset will be tracked. We do not need to preserve historical values or draw historical net worth charts.
3. **Current Month Tile Fallback:** If the current calendar month has no transaction data, the tile will fallback to displaying data for the most recent month available in the database (with a label clearly showing which month is displayed).
4. **Y-Axis Formatting:** Chart Y-Axis tick labels will format numbers with spaces for thousands but omit decimal places (e.g., `12 000`) to maintain a clean layout. Tooltips will show full precision (e.g., `12 345,67`).

