# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A Rails 8 JSON API for a multi-tenant store system. Users own stores; stores have categories; categories hold products. Auth is JWT-based on top of `has_secure_password`. No frontend views are served — this is API-only in practice (controllers render JSON/Jbuilder), though the app was generated as a full Rails app (Propshaft, importmap, Turbo/Stimulus are present but unused by the API).

## Commands

```bash
# Install deps
bundle install

# DB setup (MySQL; reads DB_USERNAME/DB_PASSWORD from .env)
bin/rails db:create db:migrate

# Run the server
bin/rails server

# Run the full test suite (also preps the test DB)
bin/rails db:test:prepare test

# Run a single test file
bin/rails test test/controllers/api/v1/sessions_controller_test.rb

# Run a single test by line number
bin/rails test test/controllers/api/v1/sessions_controller_test.rb:12

# Lint (Omakase RuboCop config)
bin/rubocop
bin/rubocop -A   # auto-correct

# Security scans
bin/brakeman --no-pager
bin/bundler-audit
```

`bundle exec rake` (what CI runs) executes the default Rake task, which runs the test suite.

## CI/CD

`.github/workflows/ruby_ci.yml` runs on push to `main` and on every PR:
- **lint**: `bin/rubocop`
- **test**: `bundle exec rake`

Both must pass. `.github/workflows/ci.yml` is currently fully commented out (dormant scaffold for brakeman/bundler-audit/importmap-audit/system tests) — don't assume it runs.

## Architecture

### Domain model

```
User ──< Store ──< Category ──< Product
```

- `User` — `has_secure_password`; email is normalized (downcased/stripped) before validation; a `jti` (UUID) is set on create and embedded in issued JWTs so tokens can be revoked later via `regenerate_jti!` (not yet wired into any controller — see Auth below).
- `Store belongs_to :user`, `has_many :categories`, `has_many :products, through: :categories`.
- `Category belongs_to :store`, `has_many :products`; name is unique per store.
- `Product belongs_to :category`, `has_one :store, through: :category`; validates price/stock numericality, optional unique SKU.

### Controller layering

- `ApplicationController` is the shared base for the whole app (not just the API). It centralizes `rescue_from ActionController::ParameterMissing`, translating missing-param errors into `400` with a humanized message (e.g. `"Password is required"`). This lives here rather than in the API base controller so every future API version inherits it automatically.
- `Api::V1::BaseController < ApplicationController` disables `wrap_parameters` and skips CSRF verification — the common base for all `api/v1` controllers. Add new versioned controllers under `Api::V1::` inheriting from this.
- Non-versioned `Api::PingsController` / `Api::EchoesController` are simple unauthenticated health/debug endpoints living directly under `Api::` (no base controller of their own).

### Auth (JWT)

- `app/lib/json_web_token.rb` is a pure encode/decode utility (no knowledge of `User`), intentionally placed in `app/lib` rather than `app/services` — it's not a business use case.
- Token payload: `{ user_id, jti, exp }`. `jti` enables revocation (e.g. after password change or logout) by calling `user.regenerate_jti!`, which invalidates all previously issued tokens for that user.
- **Not yet implemented**: a request-authentication middleware/`before_action` (`authenticate_request` / `current_user`) that verifies the JWT and checks `jti` against the DB on protected endpoints. Any new authenticated endpoint will need this — don't assume current_user is available anywhere yet.
- Registration (`POST /api/v1/registration`) does **not** return a token — clients must call `/api/v1/login` separately after registering.

### Status code convention (follow this for all new API endpoints)

| Status | When |
|---|---|
| 400 | Request malformed / required field missing — raised via `params.require(:x)` in controller, caught by the global `rescue_from` in `ApplicationController` |
| 401 | Authentication failure (wrong credentials, invalid/revoked token) |
| 422 | Well-formed request but violates a model validation (uniqueness, length, etc.) |

Controllers call `params.require(:field)` explicitly inside their `*_params` methods for every required field (in addition to `params.permit`) specifically to trigger the 400 path — don't rely on `permit` alone.

Login failures always return the generic `"Invalid email or password"` regardless of whether the email exists, to avoid user enumeration. Never leak `password_digest` or account-existence info in responses.

### Request/response shape

JSON bodies are flat (`{ "email": ..., "password": ... }`), not nested under a resource key (no `user: {...}` wrapper on input) — intentionally diverging from classic Rails form conventions to match common public API style. Responses use Jbuilder views where a reusable rendering of a resource is useful (e.g. `sessions#create`); simple success/error payloads are rendered inline with `render json:`.

See `docs/tasks/auth_api.md` for the full design rationale behind the auth endpoints (status code reasoning, versioning rationale, scope boundaries) if extending auth-related behavior.

### Database

MySQL via `mysql2`. `config/database.yml` splits production into four physical databases (`primary`, `cache`, `queue`, `cable`) for Solid Cache/Queue/Cable, each with its own `migrations_paths` — when adding migrations for those subsystems, put them under the matching `db/*_migrate` directory, not `db/migrate`. Local dev/test credentials come from `.env` (`DB_USERNAME`, `DB_PASSWORD`), loaded via `dotenv-rails`.

Solid Cache/Queue/Cable are present in the Gemfile but not yet activated in `config/environments/production.rb` (cache store and job adapter lines are commented out) — don't assume background jobs or the production cache store are live.

### Deployment

Docker + Kamal (`config/deploy.yml`, secrets in `.kamal/secrets`). `bin/kamal deploy` / `bin/kamal setup`. The `Dockerfile` is a multi-stage build; it runs `assets:precompile` even though this is effectively an API app (Propshaft/importmap scaffolding wasn't stripped out).
