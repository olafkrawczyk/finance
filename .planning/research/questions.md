# Open Research Questions

## Multi-User Seeding Approach

When does category/account seeding happen? Better Auth has a `database.hooks` option with `onSignUp` — but the user record might be created before the domain tables are ready. Need to investigate:

1. Can we hook into Better Auth's `onSignUp` to seed categories + a default account?
2. Or should we seed lazily — on first API request, check if user has categories, seed if not?
3. Does the `user_id` FK constraint cause issues if the Better Auth `"user"` table uses TEXT PK while domain tables use UUID?
