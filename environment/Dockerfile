FROM mcr.microsoft.com/playwright:v1.49.0-jammy

WORKDIR /app

ENV CI=1 \
    DEBIAN_FRONTEND=noninteractive \
    npm_config_audit=false \
    npm_config_fund=false \
    npm_config_update_notifier=false

# Avoid creating reserved harness directories like /tests or /oracle.
RUN mkdir -p /app /logs/verifier

# Seed a minimal static app under /app (agents implement the full UI in /app/index.html).
COPY seed/index.html /app/index.html
