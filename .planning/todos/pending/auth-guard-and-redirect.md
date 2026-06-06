---
title: Wire auth guard into App.tsx
date: 2026-06-07
priority: high
---

Check session on mount via `GET /api/auth/get-session`. If no session, redirect to `/login`.

- Add session state (user | null, loading) at App level
- Show loading spinner while session is being checked
- If no session, render only the login page (don't show main nav/content)
- If session exists, render current routing logic
- Handle 401 responses gracefully across all API calls
