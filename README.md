# Store

A Rails 8 JSON API for a simple multi-tenant store system: users can own stores, stores have categories, and categories hold products. Includes JWT-based authentication and a CI/CD pipeline (RuboCop + tests) via GitHub Actions.

## Tech stack

- **Ruby** 3.3.5 / **Rails** 8.1
- **MySQL** (via `mysql2`)
- **Puma** + **Thruster**, assets via **Propshaft**
- **Solid Queue** / **Solid Cache** / **Solid Cable** (DB-backed, no Redis required)
- **JWT** (`jwt` gem) + `has_secure_password` (bcrypt) for auth
- **Kamal** for Docker-based deployment
- Linting: `rubocop-rails-omakase` · Security: `brakeman`, `bundler-audit`

## Domain model

```
User ──< Store ──< Category ──< Product
```

- A `User` authenticates with email/password and can own multiple `Store`s.
- A `Store` has many `Category`s (unique name per store).
- A `Category` has many `Product`s (name, price, stock quantity, optional unique SKU).

## Getting started

### Prerequisites

- Ruby 3.3.5 (see `.ruby-version`)
- MySQL 5.7.8+ running locally
- Bundler (`gem install bundler`)

### Setup

```bash
bundle install

# Configure DB credentials (used by config/database.yml)
cp .env.example .env    # or create .env with DB_USERNAME / DB_PASSWORD
# DB_USERNAME=root
# DB_PASSWORD=yourpassword

bin/rails db:create db:migrate
```

### Run the app

```bash
bin/rails server
```

The app boots on `http://localhost:3000`. Health check: `GET /up`.

### Run tests

```bash
bin/rails db:test:prepare test
```

### Lint & security scans

```bash
bin/rubocop          # style
bin/brakeman          # static security analysis
bin/bundler-audit     # known CVEs in gems
```

## API

All JSON endpoints are namespaced under `/api`. Authenticated endpoints use `/api/v1`.

| Method | Path | Description |
|---|---|---|
| GET | `/up` | Rails health check |
| GET | `/api/ping` | Liveness check |
| GET | `/api/echo?message=...` | Echoes back a message |
| POST | `/api/v1/registration` | Register a new user |
| POST | `/api/v1/login` | Log in, returns a JWT |

### POST /api/v1/registration

```json
// Request
{ "email": "a@b.com", "password": "12345678", "name": "Viet" }

// 201 Created
{ "user": { "id": 1, "email": "a@b.com", "name": "Viet" } }

// 400 Bad Request — missing required field
{ "errors": ["Password is required"] }

// 422 Unprocessable Entity — business rule violation
{ "errors": ["Email has already been taken"] }
```

### POST /api/v1/login

```json
// Request
{ "email": "a@b.com", "password": "12345678" }

// 200 OK
{ "user": { "id": 1, "email": "a@b.com", "name": "Viet" }, "token": "eyJ..." }

// 401 Unauthorized — wrong credentials
{ "errors": ["Invalid email or password"] }
```

Status code convention: **400** for missing/malformed request fields, **401** for authentication failures, **422** for valid-but-invalid-by-business-rule input. See [docs/tasks/auth_api.md](docs/tasks/auth_api.md) for the full design rationale.

## Deployment

Deployed as a Docker container via [Kamal](https://kamal-deploy.org). Configuration lives in `config/deploy.yml` and secrets in `.kamal/secrets`.

```bash
bin/kamal setup   # first-time deploy
bin/kamal deploy  # subsequent deploys
```

Build/run manually:

```bash
docker build -t store .
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<config/master.key> --name store store
```

## CI/CD

GitHub Actions (`.github/workflows/ruby_ci.yml`) runs on every push to `main` and every pull request:

- **lint** — `bin/rubocop`
- **test** — `bundle exec rake` (runs the test suite)

Dependabot (`.github/dependabot.yml`) keeps dependencies up to date.
