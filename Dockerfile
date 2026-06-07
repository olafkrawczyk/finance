# Stage 1: Build frontend
FROM node:22-bookworm AS builder
WORKDIR /app

# Copy root dependency manifests (frontend uses root-level deps via vite.config.ts root: 'frontend')
COPY package.json bun.lock ./
RUN npm install --ignore-scripts

# Copy build config and frontend source
COPY vite.config.ts tsconfig.json postcss.config.js ./
COPY frontend/ frontend/

# Build frontend (outputs to frontend/dist/)
RUN npm run build:web

# Stage 2: Bun runtime
FROM oven/bun:1
WORKDIR /app

# Copy dependency manifests and install (layer caching)
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile --production

# Copy app source code
COPY tsconfig.json ./
COPY index.ts ./
COPY src/ src/

# Copy built frontend from builder stage
COPY --from=builder /app/frontend/dist ./frontend/dist

# Copy entrypoint orchestration script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENV NODE_ENV=production

# Healthcheck via /health endpoint (D-04)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD bun -e "fetch('http://localhost:${PORT:-3000}/health').then(r => { if (!r.ok) throw new Error(); process.exit(0); }).catch(() => process.exit(1))" || exit 1

EXPOSE 3000
ENTRYPOINT ["/app/entrypoint.sh"]
