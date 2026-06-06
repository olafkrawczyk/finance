---
title: Add logout button
date: 2026-06-07
priority: medium
---

Add a logout button in the header/nav area.

- `POST /api/auth/sign-out` with credentials: 'include'
- Clear session state and redirect to `/login`
- Position in header next to existing nav items (or right-aligned)
- Maybe show user email/name next to the button
