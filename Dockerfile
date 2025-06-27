FROM node:20-slim AS builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install --omit=dev

# Install Playwright browsers
RUN npx playwright install --with-deps chromium


FROM debian:bullseye-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    libatk1.0-0 \
    libgtk-3-0 \
    libgbm1 \
    libxkbcommon-x11-0 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/package.json /app/package-lock.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/priv ./priv

CMD ["node", "./priv/server.js"]