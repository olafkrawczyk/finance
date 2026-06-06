# Phase 3: Views & Categorization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-06
**Phase:** 03-views-categorization
**Areas discussed:** Charting library, Navigation & routing, Categorization UX, Manual entry pattern

---

## Charting Library

| Option | Description | Selected |
|--------|-------------|----------|
| Recharts | React-native charting, declarative API, most popular React chart lib | ✓ |
| Nivo | Built on D3, beautiful SVG charts, steeper learning curve | |
| Chart.js (react-chartjs-2) | Canvas-based, performant, less React-idiomatic | |

**User's choice:** Recharts (Recommended)

---

## Chart — Prediction Line

| Option | Description | Selected |
|--------|-------------|----------|
| Simple linear projection | 3-month projection from last data points | |
| Linear regression over all data | Fit trend line across all historical data | ✓ |
| Skip for now | Add prediction later | |

**User's choice:** Linear regression over all data

---

## Chart — Interactivity

| Option | Description | Selected |
|--------|-------------|----------|
| Tooltips on hover | Show values on hover (Recharts default) | |
| Tooltips + click to Monthly view | Hover tooltips + clicking a data point navigates to /month/YYYY-MM | ✓ |

**User's choice:** Tooltips + click to Monthly view

---

## Chart — Color Scheme

| Option | Description | Selected |
|--------|-------------|----------|
| App theme colors | Blue/indigo theme: expenses red, income green, balance blue | |
| Recharts defaults | Standard Recharts palette | ✓ |

**User's choice:** Recharts defaults

---

## Navigation & Routing — Navigation Pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Header nav bar | Extend existing App.tsx header with nav links | ✓ |
| Sidebar navigation | Fixed sidebar with icons + labels | |
| Tab bar | In-page tabs, less URL-addressable | |

**User's choice:** Header nav bar (Recommended)

---

## Navigation & Routing — Zbiorczy/Monthly Relationship

| Option | Description | Selected |
|--------|-------------|----------|
| Separate routes with URL param | /zbiorczy and /month/2024-01 | ✓ |
| Expandable inline panel | Monthly as expandable panel within Zbiorczy page | |

**User's choice:** Separate routes with URL param

---

## Navigation & Routing — Landing Page

| Option | Description | Selected |
|--------|-------------|----------|
| Zbiorczy as home | Summary table is the primary working view | |
| Dashboard as home | Visual charts overview as landing page | ✓ |

**User's choice:** Dashboard as home

---

## Categorization UX — Selection Pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Bulk-select + assign | Checkboxes + single dropdown to apply to all selected | ✓ |
| Inline per-row dropdown | Each row has its own category dropdown | |
| Both | Bulk tool available, plus inline per-row dropdown | |

**User's choice:** Bulk-select + assign (Recommended)

---

## Categorization UX — Flow Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Post-import flow | Categorize button on import success screen for that batch | ✓ |
| Global uncategorized page | Page showing ALL uncategorized from any import | |

**User's choice:** Post-import flow (Recommended)

---

## Manual Entry — Form Presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Modal from header button | + button in header, modal from any page | |
| Dedicated page /add | Separate route with its own page | ✓ |

**User's choice:** Dedicated page /add

---

## Manual Entry — Form Fields

| Option | Description | Selected |
|--------|-------------|----------|
| Full form: all 6 fields | Category, Amount, Description, Date, Type, Account | |
| Minimal: 3 fields | Category, Amount, Type | |

**User's choice:** As full form but no account field — Category, Amount, Description, Date (default today), Type

---

## Responsiveness

**User's choice:** "Responsiveness is a must, this has to look good on iPhone"

**Notes:** Mobile-first design constraint applied to all views. Tailwind responsive utilities. Tables may need horizontal scroll on mobile. Charts should stack vertically. Header nav may need to adapt for narrow screens.

---

## the agent's Discretion

- Linear regression implementation (client-side or backend endpoint)
- Bulk category update API design (individual PATCH vs batch endpoint)
- Responsive breakpoint strategy for tables, charts, navigation
- Chart dimensions, aspect ratios, mobile layout
- Integration of Categorize button with ImportStatus component
- Default account for manual entry transactions
