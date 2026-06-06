---
title: Build login/signup auth page
date: 2026-06-07
priority: high
---

Tabbed single-page auth with email/password + Google login.

- Single page with two tabs: "Zaloguj" (login) and "Rejestracja" (signup)
- Email + password form in each tab
- "Kontynuuj przez Google" button for OAuth (visible regardless of env config)
- On success, redirect to `/dashboard`
- Use `POST /api/auth/sign-in`, `POST /api/auth/sign-up`, `POST /api/auth/sign-in/social` (Google)
- Should work with credentials: 'include' for cookie-based sessions
