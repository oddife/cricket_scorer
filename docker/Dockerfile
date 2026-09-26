# syntax=docker/dockerfile:1

ARG FLUTTER_VERSION=3.47.4
ARG DRIFT_VERSION=2.35.0

FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS builder

ARG SUPABASE_URL
ARG SUPABASE_PUBLISHABLE_KEY
ARG DRIFT_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
        libglu1-mesa \
    && rm -rf /var/lib/apt/lists/* \
    && flutter config --no-analytics

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Regenerate Drift's generated database bindings from the table definitions.
# This prevents stale/corrupted checked-in generated output from breaking the
# Web compiler, and keeps the Docker build deterministic from source.
RUN dart run build_runner build --delete-conflicting-outputs

# Drift Web requires these runtime assets to be served with the application.
RUN curl -fsSL "https://github.com/simolus3/drift/releases/download/drift-${DRIFT_VERSION}/sqlite3.wasm" -o web/sqlite3.wasm \
    && curl -fsSL "https://github.com/simolus3/drift/releases/download/drift-${DRIFT_VERSION}/drift_worker.js" -o web/drift_worker.js

RUN flutter build web --release \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY}"

FROM nginx:alpine AS runtime

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 3112

CMD ["nginx", "-g", "daemon off;"]
