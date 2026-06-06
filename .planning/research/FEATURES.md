# Feature Landscape

**Domain:** Financial Planning Application
**Researched:** 2025-05-22

## Table Stakes

Features users expect in any financial app. Missing these = high friction.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Transaction Ledger | Users need to see where money goes. | Low | Must support categories and manual entry. |
| Bank/CSV Import | Manual entry is tedious. | Medium | Use PGMQ for async parsing of large files. |
| Budgeting Rules | 50/30/20 or custom limits. | Low | Visual progress bars (Actual vs Budget). |
| Net Worth Tracking | High-level financial health. | Low | Sum of all accounts minus liabilities. |
| Goal Setting | Saving for specific targets. | Medium | Requires logic for "funding" a goal from savings. |

## Differentiators

Features that set this app apart from basic spreadsheets.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| AI Insight Generation | Automated analysis of spending habits via OpenRouter. | Medium | "You spent 20% more on dining this month." |
| Future Forecasting | Predicting net worth based on current save rate. | High | Needs compound interest logic and AI reasoning. |
| Double-Entry Audit | Professional-grade data integrity. | High | Rare in consumer apps; allows for error detection. |
| Local-First Postgres | Users own their data. | Medium | Allows for privacy-conscious financial management. |

## Anti-Features

Features to explicitly NOT build to maintain focus.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Direct Brokerage Trading | High regulatory and API complexity. | Manual investment entry or balance tracking only. |
| Crypto Wallet Management | High security risk and volatility. | Track as a generic asset type. |
| Social Networking | Privacy is paramount in finance. | Exportable PDF reports for sharing with partners. |

## Feature Dependencies

```
Database Schema (Ledger) → Transaction Ledger → Budgeting Rules
Bank/CSV Import → Transaction Ledger
Transaction Ledger → AI Insight Generation
Transaction Ledger → Net Worth Tracking
```

## MVP Recommendation

Prioritize:
1. **Immutable Ledger**: The core data structure.
2. **Bank/CSV Import**: PGMQ-based background jobs for data entry.
3. **50/30/20 Budgeting**: Simple, actionable rules for users.
4. **AI Summary**: One differentiator to prove value (OpenRouter).

Defer: Future forecasting and multi-currency support.

## Sources

- [YNAB Features](https://www.ynab.com/features)
- [Personal Capital / Empower Reviews](https://www.empower.com/personal-investors)
- [Financial Planning Best Practices (Search Results)](SUMMARY.md)
