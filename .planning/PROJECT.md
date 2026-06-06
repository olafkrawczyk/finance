# Project Context: Financial Planning App

## Overview
A comprehensive financial planning application with both backend and frontend components, focusing on tracking, budgeting, goal planning, and AI-driven insights.

## Tech Stack
- **Backend:** Bun, Hono, Zod
- **Frontend:** React + Tailwind CSS
- **Database:** Postgres (locally hosted)
- **Queue System:** `pgmq` (Postgres extension)
- **AI Integration:** OpenRouter API

## Core Features (MVP)
1. **Tracking:** Bank sync, expense tracking, and income logging.
2. **Budgeting:** Monthly/category-based limits and alerts.
3. **Goal Planning:** Retirement, savings, and large purchase planning.
4. **AI Insights:** AI-driven insights based on spending habits using OpenRouter.

## Authentication
- OAuth/SSO strategy.

## Infrastructure
- Locally hosted Postgres.
- `pgmq` for background job processing and queuing.
