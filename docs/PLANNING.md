# Planning — Trello-Lite

This document captures the **design-first** phase of the capstone: user stories,
the data model / schema design, and the key API design decisions. The machine
-readable contract is [`swagger/v1/openapi.yaml`](../swagger/v1/openapi.yaml),
which was authored before the controllers were implemented.

---

## 1. Product summary

A multi-user Kanban board service. Users create **boards**, invite collaborators
with **roles**, organise work into ordered **lists** of **cards**, and annotate
cards with comments, labels, assignees and file attachments. External systems
integrate through a documented REST API and outbound webhooks.

## 2. Personas

- **Owner** — creates a board, manages members and integrations, can delete it.
- **Admin** — full control of a board's content and configuration (labels, webhooks, members).
- **Member** — creates and edits lists, cards and comments.
- **Viewer** — read-only access to a board.
- **Integrator** — a machine client consuming the API / receiving webhooks.

## 3. User stories

### Authentication & accounts
- As a user, I can **register** with name/email/password and immediately receive a token pair.
- As a user, I can **log in** to obtain an access token and a refresh token.
- As a user, I can **refresh** my access token without re-entering credentials, and the old refresh token is invalidated (rotation).
- As a user, I can **log out**, revoking a refresh token.

### Boards & membership
- As a user, I can **create a board** and automatically become its admin/owner.
- As a user, I only **see boards** I own, am a member of, or that are public.
- As an admin, I can **add/remove members by email** and **set their role**.
- As an owner, I can **delete** a board; the owner's own membership cannot be changed or removed.

### Lists & cards
- As a member, I can **create, rename, reorder and delete lists** on a board.
- As a member, I can **create cards** with a title, description and due date.
- As a member, I can **move a card** within a list or to another list at a chosen position.
- As a member, I can **assign labels and members** to a card and **archive** it.
- As a viewer, I can **read** lists and cards but not modify them.

### Collaboration
- As a member, I can **comment** on cards; I can edit/delete my own comments, and admins can delete any.
- As a member, I can **upload file attachments** to a card and delete them.
- As a member, I can view a board's **activity feed**.

### Integration & operability
- As an admin, I can **register webhooks** filtered by event type and receive **HMAC-signed** deliveries.
- As an integrator, I get **paginated**, **rate-limited** responses with consistent error shapes.
- As an operator, I can rely on a **`/up` health check** and **Sentry** error reporting.

## 4. Data model

### Entities & relationships

```
User 1───* Board (as owner)
User *───* Board           via BoardMembership (role: admin|member|viewer)
Board 1───* List           (ordered by position)
Board 1───* Label
Board 1───* Webhook 1───* WebhookDelivery
Board 1───* Activity        (append-only feed; polymorphic subject)
List 1───* Card            (ordered by position)
Card *───* User            via CardAssignment   (assignees)
Card *───* Label           via CardLabel
Card 1───* Comment
Card 1───* ActiveStorage attachments
User 1───* RefreshToken
```

### Tables (primary columns)

| Table | Key columns | Notes |
|-------|-------------|-------|
| `users` | `email` (citext, unique), `name`, `password_digest`, `role` | `has_secure_password`; email normalised + case-insensitive unique. |
| `boards` | `name`, `description`, `owner_id`, `visibility` (private/public) | Owner auto-added as admin member on create. |
| `board_memberships` | `board_id`, `user_id`, `role` | Unique `[board_id, user_id]`. |
| `lists` | `board_id`, `name`, `position` | Index `[board_id, position]`. |
| `cards` | `list_id`, `creator_id`, `title`, `description`, `position`, `due_on`, `archived` | Index `[list_id, position]`. |
| `card_assignments` | `card_id`, `user_id` | Unique `[card_id, user_id]`. |
| `labels` / `card_labels` | `board_id`, `name`, `color` / `card_id`, `label_id` | Label unique per board; join unique. |
| `comments` | `card_id`, `user_id`, `body` | |
| `activities` | `board_id`, `user_id?`, `action`, `subject_type/id`, `metadata` (jsonb) | Append-only; `created_at` only. |
| `webhooks` | `board_id`, `url`, `secret`, `event_types` (jsonb), `active` | Secret auto-generated; events validated against allow-list. |
| `webhook_deliveries` | `webhook_id`, `event`, `payload` (jsonb), `status`, `response_code`, `attempts`, `delivered_at` | Delivery audit log. |
| `refresh_tokens` | `user_id`, `token_digest` (unique), `expires_at`, `revoked_at` | Opaque tokens stored as SHA-256 digests. |

### Design decisions
- **Integer enums** for `role` / `visibility` / delivery `status` — compact, indexable; surfaced as strings in the API.
- **`citext`** for email gives case-insensitive uniqueness at the database level.
- **Dense integer positions** for lists/cards, recomputed by `Cards::Mover` and the `Positionable` concern, keep ordering simple and gap-free.
- **Foreign keys + `dependent: :destroy`** enforce referential integrity and clean cascades.
- **`jsonb`** for webhook `event_types`, delivery `payload` and activity `metadata` keeps flexible structures queryable.
- **Polymorphic `subject`** on activities lets one feed reference any record type.

## 5. API design notes

- **Versioned** under `/api/v1`; nesting is shallow (e.g. cards are created under a list but addressed at `/cards/:id`).
- **Auth**: stateless JWT access tokens + DB-backed rotating refresh tokens.
- **AuthZ**: Pundit policies resolve the owning board for any record and apply the caller's role.
- **Serialization**: Alba resources; single resources returned bare, collections as arrays with pagination metadata in headers.
- **Errors**: uniform `{ "error": { "code", "message", "details" } }` envelope across 401/403/404/422/429.
- **Idempotent-friendly**: validation errors return field-level `details`.

See [`DEPLOYMENT.md`](DEPLOYMENT.md) for the operational/ship phase.
