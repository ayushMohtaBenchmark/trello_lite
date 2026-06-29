# Deployment — Trello-Lite

How to containerise, configure and run Trello-Lite in production. The app is
PostgreSQL-backed and uses **Solid Queue** (jobs) and **Solid Cache** (cache /
rate-limit store) in a single database — **no Redis required**.

---

## 1. Images

| File | Purpose |
|------|---------|
| `Dockerfile` | Production image — multi-stage, slim, **non-root**, Bootsnap-precompiled, Puma behind **Thruster**, listens on port 80. |
| `Dockerfile.dev` | Development/test image — full toolchain and all gem groups, bind-mounted source. |

Build the production image:

```bash
docker build -t trello-lite:latest .
```

`bin/docker-entrypoint` runs `bin/rails db:prepare` (create + migrate, idempotent)
before booting the server, so a fresh database is provisioned automatically.

## 2. Configuration (environment variables)

| Variable | Required | Description |
|----------|----------|-------------|
| `RAILS_ENV` | yes | `production` |
| `SECRET_KEY_BASE` | yes* | Rails secret; or provide `RAILS_MASTER_KEY` and use encrypted credentials. |
| `RAILS_MASTER_KEY` | yes* | Decrypts `config/credentials.yml.enc`. |
| `POSTGRES_HOST` / `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | yes | Database connection. |
| `RAILS_MAX_THREADS` | recommended | Puma threads / DB pool size. Must exceed the Solid Queue worker thread count (default config needs ≥ 7; use `10`). |
| `JWT_SECRET_KEY` | optional | Overrides the JWT signing key (defaults to `secret_key_base`). |
| `CORS_ORIGINS` | optional | Comma-separated allowed origins (default `*`). |
| `RATE_LIMIT_RPM` / `AUTH_RATE_LIMIT_RPM` | optional | Throttle limits (default 300 / 10 per minute). |
| `ACTIVE_STORAGE_SERVICE` | optional | `local` (default) or `amazon` for S3. |
| `SENTRY_DSN` | optional | Enables Sentry error tracking when set. |
| `SENTRY_TRACES_SAMPLE_RATE` | optional | Performance trace sampling (default `0.1`). |
| `GIT_SHA` | optional | Tags the Sentry release. |

\* Provide **either** `SECRET_KEY_BASE` **or** `RAILS_MASTER_KEY` (with credentials).

A template is in [`.env.example`](../.env.example).

## 3. Reference production stack

`docker-compose.prod.yml` runs the full topology: API (`web`), background
worker (`worker`, Solid Queue supervisor), and Postgres (`db`).

```bash
export RAILS_MASTER_KEY=$(cat config/master.key)
export SECRET_KEY_BASE=$(openssl rand -hex 64)
export POSTGRES_PASSWORD=$(openssl rand -hex 16)

docker compose -f docker-compose.prod.yml up --build
#   API        → http://localhost:8080      (override with WEB_PORT)
#   Health     → http://localhost:8080/up
#   Swagger UI → http://localhost:8080/api-docs
```

Components:
- **web** — Puma/Thruster, runs `db:prepare` on boot, serves the API and Swagger UI.
- **worker** — `rake solid_queue:start` (supervisor + dispatcher + worker) delivers webhooks with retries.
- **db** — PostgreSQL 16 with a healthcheck gating dependants.

## 4. Database

Single PostgreSQL database holds application tables **plus** the Solid Queue and
Solid Cache tables (`db/migrate/20260101000150_create_solid_tables.rb`).
`bin/rails db:prepare` creates and migrates everything; on a brand-new database
it also runs `db/seeds.rb`.

To scale, run multiple `web` replicas behind a load balancer and one or more
`worker` replicas. Because cache and rate-limit counters live in Solid Cache
(shared DB), throttling is consistent across all web replicas.

## 5. Observability

- **Health check**: `GET /up` returns 200 when the app boots cleanly — wire it to your load balancer / uptime monitor.
- **Error tracking**: set `SENTRY_DSN`. Routine 4xx (not-found, validation, authorization) are excluded from Sentry noise; PII sending is disabled.
- **Logs**: structured request-tagged logs to STDOUT (`config.log_tags = [:request_id]`).

## 6. Security posture

- Runs as a **non-root** user in the container.
- `force_ssl` + HSTS enabled in production (`assume_ssl` for proxy termination).
- Refresh tokens stored as **SHA-256 digests**; access tokens are short-lived JWTs.
- **Rack::Attack** throttles general and auth traffic; **rack-cors** restricts origins.
- **Brakeman** runs clean; **bundler-audit** checks dependencies for CVEs.

## 7. Deploying to a host / PaaS

The image is a standard Rails 8 container and deploys anywhere that runs OCI
images (Fly.io, Render, ECS, Kubernetes, a plain VM, or **Kamal**). Checklist:

1. Provision PostgreSQL; set the `POSTGRES_*` / `DATABASE_URL` variables.
2. Set `SECRET_KEY_BASE` (or `RAILS_MASTER_KEY`) and `RAILS_MAX_THREADS=10`.
3. Run one `web` service (port 80) and at least one `worker` (`rake solid_queue:start`).
4. Point a TLS-terminating proxy / load balancer at `web`, health-checking `/up`.
5. (Optional) Set `SENTRY_DSN`, `CORS_ORIGINS`, and S3 (`ACTIVE_STORAGE_SERVICE=amazon`) credentials.

## 8. CI suggestion

```bash
docker compose -f docker-compose.yml build web
docker compose run --rm -e RAILS_ENV=test -e COVERAGE=true web bundle exec rspec
docker compose run --rm web bundle exec brakeman -q
docker compose run --rm web bundle exec bundler-audit check --update
```
