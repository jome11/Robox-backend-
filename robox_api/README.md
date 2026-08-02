# robox_api (Turso + Render edition)

This backend now talks to a **Turso** database over plain HTTPS
(`lib/db.dart`), instead of the local `sqlite3` file the project
started with. There's no native database driver involved anywhere,
which is what makes it deployable to Render without headaches.

## One-time local setup

```bash
dart pub get

export TURSO_DATABASE_URL="libsql://your-db-yourorg.turso.io"
export TURSO_AUTH_TOKEN="your-turso-token"
export JWT_SECRET="pick-a-long-random-string"

dart run bin/init_db.dart      # creates all tables in Turso
dart run bin/seed_admins.dart  # creates the two default admin accounts
dart run bin/seed_stock.dart   # optional: seeds starter stock items
```

## Run locally

```bash
dart_frog dev
```

## Deploy to Render

1. Push this project to GitHub (repo root = this folder).
2. Render Dashboard > New > Web Service > connect the repo.
3. Environment = **Docker** (the root `Dockerfile` here handles the
   build — Render will detect it automatically).
4. Add environment variables on the service: `TURSO_DATABASE_URL`,
   `TURSO_AUTH_TOKEN`, `JWT_SECRET`.
5. Deploy. Render assigns the port via `$PORT`, which `dart_frog`
   already reads (see the generated `build/bin/server.dart`).
6. Once it's live, run `bin/init_db.dart` and `bin/seed_admins.dart`
   **once** from your machine (pointed at the same Turso database) if
   you haven't already — Render's filesystem is ephemeral, so you
   can't run one-off scripts on the server itself.

## What changed from the original sqlite3 version

- `lib/db.dart` — full rewrite. `getDb()` now returns a `TursoClient`
  with `query()`/`execute()` methods that talk to Turso's
  `/v2/pipeline` HTTP API. `initDb()` creates all tables (call it via
  `bin/init_db.dart`).
- Every route file that used `db.select(...)` / `db.execute(...)`
  synchronously now uses `await db.query(...)` / `await db.execute(...)`.
  Row access (`row['column_name']`) is unchanged.
- `pubspec.yaml` — dropped `sqlite3`, added `http`.
- JWT secret is now read from `JWT_SECRET` (env var) instead of being
  hardcoded, in every `_middleware.dart` and in `login.dart`.
- Added a root-level `Dockerfile` (Render builds from the repo root).
- Added `bin/init_db.dart` — a one-off schema setup script.
