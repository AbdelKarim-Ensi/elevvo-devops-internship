# Task 5: Multi-Stage Containerization & Internal Networking

A todo-list app (Node.js + Express) backed by PostgreSQL, containerized with a
hardened multi-stage Dockerfile and orchestrated with Docker Compose on a
private network.

## Architecture

~~~
host :3000 --> [ app (node, non-root) ] --backend (internal)--> [ postgres-db ]
                     frontend network                              no published port
~~~

- `frontend`: normal bridge, publishes the app on port 3000.
- `backend`: bridge with `internal: true`. It has no outside access, and only
  `app` and `postgres-db` are attached.
- `postgres-db` has no `ports:` entry, so it is unreachable from the host.

## Key decisions

| Topic | Choice |
|---|---|
| Multi-stage | `build` stage prepares the app and dependencies; `runtime` stage copies only the result |
| Base image | `node:22-alpine` |
| Privileges | `USER node` (uid 1000), never root |
| Attack surface | `npm`, `yarn` and `corepack` removed from the runtime image |
| OS patches | `apk upgrade` in the runtime stage |
| Secrets | `.env` generated locally, git-ignored |
| Readiness | DB healthcheck (`pg_isready`), app waits via `depends_on: service_healthy` |
| Bonus | Trivy scan blocks the run on HIGH/CRITICAL CVEs |

## Run

~~~bash
cd app && npm install --omit=dev && cd ..
cat > .env <<EOT
POSTGRES_USER=todo_user
POSTGRES_PASSWORD=$(openssl rand -hex 16)
POSTGRES_DB=tododb
EOT
docker build -t todo-app:latest . && ./scan.sh && docker compose up -d
~~~

Open http://localhost:3000.

## Verification

~~~bash
./demo.sh
~~~

Observed results:

| Check | Result |
|---|---|
| `whoami` / `id` in the app container | `node` / `uid=1000(node)` |
| Image content size | 62.2 MB |
| `docker network inspect ..._backend` | `internal=true` |
| `nc -zv localhost 5432` | Connection refused (closed on host) |
| App to DB over private DNS | `postgres-db:5432 reachable` |
| `which npm` in runtime | absent |
| Trivy on final image | 0 HIGH / 0 CRITICAL |

## Security scan story

The first scan found 7 HIGH in Alpine packages (openssl, musl, zlib) and 22
HIGH/CRITICAL in npm's own internal dependencies. Fixes:

1. `apk upgrade` patches the OS packages.
2. Removing npm/yarn/corepack from the runtime image eliminates the rest. The
   app runs with `node server.js` and does not need them.

## Troubleshooting note

On Docker Desktop (VM-based), the default bridge could not reach the npm
registry and builds hung. Switching to the native Docker Engine
(`docker context use default`) and installing dependencies on the host before
the `COPY` solved it.

## Files

- `Dockerfile`: multi-stage, non-root, hardened runtime
- `docker-compose.yml`: app + `postgres-db`, private network
- `scan.sh`: Trivy gate (HIGH/CRITICAL fails the run)
- `demo.sh`: replays all verification steps
- `app/`: todo-list source
