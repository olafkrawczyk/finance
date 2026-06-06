# Technology Stack

**Project:** Financial Planning Application
**Researched:** 2025-05-22

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Bun | Latest (1.2+) | Runtime & Package Manager | Extremely fast startup, built-in SQL support, and high-performance I/O for workers. |
| Hono | Latest | Web Framework | Lightweight, edge-ready, and has excellent middleware support for OAuth and JWT. |

### Database & Queue
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| PostgreSQL | 16+ | Primary Database | Industry standard for financial data; supports ACID transactions and complex constraints. |
| PGMQ | Latest | Message Queue | Postgres extension that provides SQS-like queuing without needing Redis. Ensures transactional job enqueuing. |

### AI Integration
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| OpenRouter | API | AI Insights & Analysis | Unified access to top-tier models (DeepSeek-R1, Claude 3.5). Excellent for cost-optimization and model fallbacks. |

### Authentication
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Better Auth | Latest | Auth Framework | Provides type-safe hooks for React and Hono; handles OAuth and sessions natively. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `postgres.js` | Latest | DB Driver | The fastest Postgres driver for Bun; handles PGMQ SQL calls efficiently. |
| `zod` | Latest | Validation | Schema validation for financial transactions and AI outputs. |
| `hono/cors` | Latest | Middleware | Required for React frontend communication. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Queue | PGMQ | BullMQ (Redis) | BullMQ requires Redis infra; PGMQ keeps everything in Postgres, simplifying backups and consistency. |
| Auth | Better Auth | Clerk / Auth0 | Better Auth allows you to keep data in your own DB (Postgres), which is better for financial data privacy. |
| AI | OpenRouter | LangChain | OpenRouter is a direct API; LangChain adds abstraction that might be overkill for simple insight generation. |

## Installation

```bash
# Core Dependencies
bun add hono @hono/node-server postgres better-auth zod

# PGMQ and Worker utilities
bun add pgmq-js

# Dev dependencies
bun add -D @types/node
```

## Sources

- [Hono Documentation](https://hono.dev/)
- [PGMQ GitHub](https://github.com/tembo-io/pgmq)
- [Better Auth Documentation](https://better-auth.com/)
- [OpenRouter API Docs](https://openrouter.ai/docs)
