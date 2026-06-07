---
spike: 003
name: frontend-edit-delete-ui
type: standard
validates: "Given a transaction in the monthly view, when user clicks edit/delete, then the UI allows inline editing of all fields or removal"
verdict: VALIDATED
related: [002]
tags: [frontend, ui, edit, delete]
---

# Spike 003: Frontend Edit/Delete UI

## What This Validates

Users can edit all transaction fields (date, type, amount, description, category) and delete transactions directly from the monthly transaction table.

## How to Run

Open the prototype HTML in a browser:
```
open .planning/spikes/003-frontend-edit-delete-ui/prototype.html
```

## Investigation Trail

- Edit button (pencil icon) appears on hover in each table row → opens modal with prefilled form → all fields editable → Save updates the row
- Delete button (trash icon) appears on hover → confirmation dialog → removes row
- Hover-revealed actions follow the existing pattern (currently no row actions exist, but hover-reveal is consistent with modern table UX)
- Edit form uses the same fields as the CreateTransaction form
- Delete has a confirmation step to prevent accidental removal

## Results

**Verdict: VALIDATED ✓**

The prototype demonstrates the full UX flow. Implementation in the real app requires:
- Wire the edit modal to PUT /transactions/:id (from Spike 002)
- Wire the delete confirmation to DELETE /transactions/:id (from Spike 002)
- Add GET /transactions/:id for prefill
- Category dropdown should fetch real categories from the API
- Show toast/notification on success
- Refetch transaction list after edit/delete
