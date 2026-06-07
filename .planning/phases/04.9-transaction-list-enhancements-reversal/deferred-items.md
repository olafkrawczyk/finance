# Deferred Items — Plan 04.9-02

## Pre-existing Test Failures (not caused by Plan 04.9-02)

The following 5 test failures in `tests/ui-components.test.ts` are pre-existing issues from Plan 04.9-04 (Polish localization). They are NOT caused by changes in Plan 04.9-02 and are logged here for tracking.

| Test Name | Issue | Expected | Actual |
|-----------|-------|----------|--------|
| renders ImportUpload component without crashing | Polish localization mismatch | "Import Transactions" | "Importuj transakcje" |
| renders ImportStatus component without crashing | Polish localization mismatch | "Loading job status..." | "Ładowanie statusu zadania..." |
| renders InsightsTabs without crashing | Polish localization mismatch | "All" | "Wszystkie" |
| renders InsightCard dismissed state | Polish localization mismatch | "Dismissed" | "Odrzucono" |
| renders MonthlyPage component in loading state | Polish localization mismatch | "Loading month view..." | "Ładowanie szczegółów miesiąca..." |

These tests will need updating to match the new Polish text that was introduced in Plan 04.9-04. They should be fixed as part of a separate plan that reconciles the test expectations with the current UI strings.
