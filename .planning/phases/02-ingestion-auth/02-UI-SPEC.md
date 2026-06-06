# Phase 2: Ingestion & Auth — UI Design Contract

**Phase:** 2 — Ingestion & Auth
**Created:** 2026-06-06
**Scope:** File upload UI for bank CSV import

---

## Screens

### 1. Import Upload Screen

**Route:** `/import`
**Purpose:** Allow users to upload bank CSV files and initiate import processing.

#### Layout

```
┌─────────────────────────────────────────────────────┐
│  Import Transactions                                │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Account: [Dropdown ▼]                              │
│                                                      │
│  Bank Format: [ING ▼] [IPKO ▼]                     │
│                                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │                                             │    │
│  │     📁 Drop CSV file here or click to      │    │
│  │        browse                               │    │
│  │                                             │    │
│  └─────────────────────────────────────────────┘    │
│                                                      │
│  [Upload and Start Import]                           │
│                                                      │
│  ─────────────────────────────────────────────────   │
│  Recent Imports                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │ Job ID    │ Status    │ Date      │ Count    │  │
│  │ 12345     │ Complete  │ 2026-06-06 │ 42      │  │
│  └────────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

#### Components

**Account Selector**
- Dropdown populated from `/accounts` API
- Default: first account if only one exists
- Label: "Select Account"

**Bank Format Selector**
- Two options: ING, IPKO
- Default: ING
- Auto-detect based on filename extension/content if possible

**File Drop Zone**
- Visual: Dashed border, centered icon + text
- Accepts: `.csv` files only
- Max size: 10MB
- Shows filename after selection
- Error state: red border if invalid file type

**Upload Button**
- Primary action (blue fill)
- Disabled until file selected and account chosen
- Shows spinner while uploading
- On success: redirects to Import Status page

**Recent Imports Table**
- Columns: Job ID, Status (badge), Date, Transaction Count
- Status badges: Pending (yellow), Processing (blue), Complete (green), Error (red)
- Paginated: 5 items per page

---

### 2. Import Status Screen

**Route:** `/import/:jobId`
**Purpose:** Show real-time progress of an import job.

#### Layout

```
┌─────────────────────────────────────────────────────┐
│  Import Status                                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Job ID: {job_id}                                   │
│  Status: [Processing ▶]                             │
│                                                     │
│  Progress: ████████░░░░ 45%                         │
│  Processed: 45 / 100 transactions                  │
│                                                     │
│  ─────────────────────────────────────────────────   │
│  Errors (3)                                         │
│  ┌────────────────────────────────────────────────┐  │
│  │ Row 50: Invalid date format "2026-13-01"     │  │
│  │ Row 87: Amount parsing failed for "1.234,56"   │  │
│  └────────────────────────────────────────────────┘  │
│                                                     │
│  [← Back to Imports]                                │
│                                                     │
└─────────────────────────────────────────────────────┘
```

#### Components

**Progress Bar**
- Visual: Horizontal bar with percentage text
- Updates every 2 seconds via polling `GET /import/:jobId`
- Color: blue (processing), green (complete), red (error)

**Error List**
- Collapsible section (default: expanded if errors > 0)
- Shows: row number, error message
- Max height: 200px with scroll

**Polling Behavior**
- Interval: 2 seconds while status is "processing"
- Stop polling when status is "complete" or "error"
- Timeout: 5 minutes max polling

---

## Design System

### Colors
- Primary: `#3b82f6` (blue-500)
- Success: `#22c55e` (green-500)
- Warning: `#eab308` (yellow-500)
- Error: `#ef4444` (red-500)
- Background: `#f9fafb` (gray-50)
- Card: `#ffffff` (white)
- Border: `#e5e7eb` (gray-200)

### Typography
- Headings: `text-xl font-semibold text-gray-900`
- Body: `text-sm text-gray-600`
- Labels: `text-sm font-medium text-gray-700`
- Mono (job IDs): `font-mono text-xs`

### Spacing
- Page padding: `p-6`
- Card padding: `p-4`
- Gap between sections: `gap-6`
- Form element gap: `gap-4`

### Interactive States
- Hover: `hover:bg-gray-50`
- Focus: `focus:ring-2 focus:ring-blue-500 focus:border-blue-500`
- Disabled: `opacity-50 cursor-not-allowed`
- Loading: `opacity-75` with spinner icon

---

## Responsive Behavior

**Mobile (< 640px)**
- Full-width cards, stacked layout
- Drop zone: full width, reduced height
- Recent imports table: horizontal scroll

**Tablet (640px - 1024px)**
- Cards: 2-column grid for related fields
- Drop zone: centered, max-width 400px

**Desktop (> 1024px)**
- Max-width container: 1024px centered
- Side-by-side: upload form + recent imports

---

## Accessibility

- File input: `aria-label="Upload CSV file"`
- Status badges: `role="status"` with `aria-live="polite"`
- Progress bar: `role="progressbar"` with `aria-valuenow`, `aria-valuemin`, `aria-valuemax`
- Error list: `role="alert"` with `aria-live="assertive"`
- All form elements: associated `<label>` elements
- Color alone never conveys status — icons + text always paired

---

## API Integration

| Endpoint | Method | Purpose | Body / Response |
|----------|--------|---------|-----------------|
| `/accounts` | GET | Populate account dropdown | `{ data: [{ id, name }] }` |
| `/import` | POST | Start import | `FormData: file, account_id, bank_format` → `{ data: { job_id } }` |
| `/import/:jobId` | GET | Poll status | `{ data: { status, processed, total, errors: [{ row, message }] } }` |

---

## Error Handling

| Scenario | UI Behavior |
|----------|-------------|
| Invalid file type | Drop zone border turns red, message: "Please upload a CSV file" |
| File too large | Message: "File must be under 10MB" |
| Upload network error | Retry button appears, error toast |
| Import processing error | Error list shows row-level errors, status badge = "Error" |
| Job not found | 404 page with "Import job not found" |
| Auth required | Redirect to `/auth/signin` |

---

*UI-SPEC generated: 2026-06-06*
