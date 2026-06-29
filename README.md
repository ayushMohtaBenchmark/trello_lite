# Trello-Lite API

A multi-user project board (Trello-lite) built as a Rails 8.1 **API-only**
application. It is fully containerised, documented with a design-first OpenAPI
spec, and ships an authenticated, paginated, rate-limited JSON API with outbound
webhooks and background job processing.

> Capstone deliverable: a fully containerised, deployed app with a documented,
> authenticated, rate-limited API.

---

## Table of contents

- [Feature overview](#feature-overview)
- [Tech stack](#tech-stack)
- [Quick start (Docker)](#quick-start-docker)
- [API at a glance](#api-at-a-glance)
- [Authentication flow](#authentication-flow)
- [Webhooks](#webhooks)
- [Testing & quality gates](#testing--quality-gates)
- [Production deployment](#production-deployment)
- [Project structure](#project-structure)
- [Documentation](#documentation)

---

## Feature overview

| Area        | What's included |
|-------------|-----------------|
| **Auth**    | JWT access tokens (30 min) + rotating, revocable refresh tokens (SHA-256 hashed at rest). Register / login / refresh / logout / me. |
| **Domain**  | Users, boards, board memberships (admin/member/viewer), lists, cards, comments, labels, assignees, file attachments, activity feed. |
| **API**     | Versioned REST (`/api/v1`), Alba serializers, Pagy pagination (header metadata + `Link`), consistent JSON error envelope. |
| **AuthZ**   | Pundit policies driven by per-board roles; board owner is always admin. |
| **Uploads** | Active Storage attachments on cards (local disk in dev, S3-compatible in prod). |
| **Limits**  | Rack::Attack throttling (per-token / per-IP) with `RateLimit-*` + `Retry-After` headers. |
| **Webhooks**| Per-board, event-filtered, HMAC-SHA256 signed, delivered via Solid Queue with retries + delivery audit log. |
| **Docs**    | Hand-written OpenAPI 3.0 spec served through Swagger UI at `/api-docs`. |
| **Quality** | RSpec (79 examples), 93% line coverage (SimpleCov, 90% gate), Bullet N+1 guard, Brakeman clean. |
| **Ops**     | Multi-stage production Docker image, Solid Queue worker, Sentry error tracking, health check at `/up`. |

## Tech stack

- **Ruby** 3.3.6, **Rails** 8.1 (API mode)
- **PostgreSQL** 16
- **Solid Queue** (jobs) + **Solid Cache** (cache / rate-limit store) — no Redis required
- **JWT** + **bcrypt**, **Pundit**, **Alba**, **Pagy**, **Rack::Attack**, **rack-cors**
- **rswag** (Swagger UI), **Sentry**
- **RSpec**, **FactoryBot**, **Faker**, **shoulda-matchers**, **SimpleCov**, **WebMock**, **Bullet**, **Brakeman**

## Quick start (Docker)

No local Ruby/Postgres needed — everything runs in containers.

```bash
# 1. Build and start Postgres + the API (creates, migrates and seeds the DB)
docker compose up --build

# 2. The API is now live:
#    API base   → http://localhost:3000/api/v1
#    Swagger UI → http://localhost:3000/api-docs
#    Health     → http://localhost:3000/up
```

Seed credentials (`db/seeds.rb`): `demo@trello-lite.test` / `password123`.

Common tasks:

```bash
docker compose run --rm web bin/rails console          # Rails console
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec   # run the suite
docker compose run --rm web bundle exec brakeman        # security scan
```

## API at a glance

All endpoints are under `/api/v1` and require `Authorization: Bearer <access_token>`
(except register / login / refresh). Full reference: **Swagger UI** at `/api-docs`
or [`swagger/v1/openapi.yaml`](swagger/v1/openapi.yaml).

```
POST   /auth/register | /auth/login | /auth/refresh
DELETE /auth/logout            GET /auth/me

GET/POST            /boards                 GET/PATCH/DELETE /boards/:id
GET/POST/PATCH/DEL  /boards/:id/memberships
GET/POST/PATCH/DEL  /boards/:id/labels
GET/POST            /boards/:id/webhooks    GET/PATCH/DELETE /webhooks/:id
GET                 /boards/:id/activities

GET/POST  /boards/:id/lists   GET/PATCH/DELETE /lists/:id
GET/POST  /lists/:id/cards    GET/PATCH/DELETE /cards/:id   PATCH /cards/:id/move
GET/POST  /cards/:id/comments GET/POST /cards/:id/attachments
PATCH/DEL /comments/:id       DELETE /attachments/:id
```

Pagination: `?page=` & `?per_page=` (max 100). Responses carry `X-Total-Count`,
`X-Page`, `X-Per-Page`, `X-Total-Pages` and a RFC-5988 `Link` header.

### Example

```bash
TOKEN=$(curl -s -X POST localhost:3000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"user":{"email":"demo@trello-lite.test","password":"password123"}}' \
  | jq -r .access_token)

curl localhost:3000/api/v1/boards -H "Authorization: Bearer $TOKEN"
```

## Authentication flow

1. `POST /auth/register` or `/auth/login` → `{ access_token, refresh_token, expires_in }`.
2. Send `Authorization: Bearer <access_token>` on every request.
3. When the access token expires, `POST /auth/refresh` with the refresh token.
   The old refresh token is **revoked and rotated** (one-time use).
4. `DELETE /auth/logout` revokes a refresh token.

Refresh tokens are stored only as SHA-256 digests, so a database leak cannot
reveal usable tokens.

## Webhooks

Board admins register webhooks subscribed to specific events (`card.created`,
`card.moved`, `comment.created`, …). On each event the API enqueues a Solid
Queue job that POSTs a JSON payload signed with `X-TrelloLite-Signature:
sha256=<hmac>` (HMAC-SHA256 of the raw body using the webhook secret, returned
once at creation). Failures retry with exponential backoff and every attempt is
recorded in `webhook_deliveries`.

Verify a payload on the receiving end:

```ruby
expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, request.raw_post)
ActiveSupport::SecurityUtils.secure_compare(expected, request.headers["X-TrelloLite-Signature"])
```

## Testing & quality gates

```bash
docker compose run --rm -e RAILS_ENV=test -e COVERAGE=true web bundle exec rspec
docker compose run --rm web bundle exec brakeman      # 0 warnings
docker compose run --rm web bundle exec bundler-audit check --update
```

- **RSpec** — model, request, service and policy specs (79 examples).
- **SimpleCov** — 93% line coverage; the suite fails under 90% when `COVERAGE=true`.
- **Bullet** — request specs raise on N+1 queries.
- **Brakeman** — static security analysis, clean.

## Production deployment

The production image (`Dockerfile`) is a slim, multi-stage, non-root build
running Puma behind Thruster. A reference production stack (API + Solid Queue
worker + Postgres) lives in `docker-compose.prod.yml`. See
[`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for the full guide, environment
variables, Sentry setup and scaling notes.

```bash
export RAILS_MASTER_KEY=$(cat config/master.key)
export SECRET_KEY_BASE=$(openssl rand -hex 64)
docker compose -f docker-compose.prod.yml up --build
# API on http://localhost:8080  (set WEB_PORT to change)
```

## Project structure

```
app/
  controllers/api/v1/   # versioned REST controllers + concerns (auth, errors, pagination)
  models/               # domain models + Positionable concern
  serializers/          # Alba resources
  services/             # Auth::TokenIssuer, Webhooks::Dispatcher/Sender, Cards::Mover, ActivityLogger
  policies/             # Pundit policies (role-based)
  jobs/                 # WebhookDeliveryJob
  lib/                  # JsonWebToken
config/                 # env config, initializers (rack_attack, sentry, alba, pagy, bullet, rswag)
db/migrate/             # schema migrations (+ Solid Queue/Cache tables)
swagger/v1/openapi.yaml # design-first OpenAPI 3.0 contract
spec/                   # RSpec suite
docs/                   # planning + deployment docs
Dockerfile              # production image
Dockerfile.dev          # development / test image
docker-compose*.yml     # dev and production-like stacks
```

## Documentation

- [`docs/PLANNING.md`](docs/PLANNING.md) — user stories, schema design & data model, API design notes.
- [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) — containerisation & production deployment guide.
- [`swagger/v1/openapi.yaml`](swagger/v1/openapi.yaml) — the API contract (also at `/api-docs`).
