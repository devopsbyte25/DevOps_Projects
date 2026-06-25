# flask-docker-webapp

A minimal DevOps webapp project:

- A small **Python/Flask** web app with several real HTTP methods implemented
  (`GET`, `POST`, `DELETE`).
- A **multi-stage Dockerfile** that builds a small, non-root, production image.
- A **docker-compose.yml** for local development.
- A **GitHub Actions** pipeline that lints, tests, builds a multi-arch image,
  and pushes it to **GitHub Container Registry (GHCR)** — with an optional
  Docker Hub push — on every push to `main` and on version tags.

```
04-dockerize_webapp/
├── app/
│   ├── __init__.py
│   └── main.py              # Flask app + routes
├── tests/
│   └── test_app.py          # pytest unit tests
├── Dockerfile               # multi-stage, non-root, healthcheck
├── docker-compose.yml
├── requirements.txt
├── requirements-dev.txt
├── wsgi.py                   # gunicorn entrypoint
├── Makefile
├── .dockerignore
├── .gitignore
└── README.md
```

## 1. The application

Implemented endpoints:

| Method | Path                | Description                       |
| ------ | ------------------- | --------------------------------- |
| GET    | `/health`           | Liveness/readiness probe          |
| GET    | `/version`          | Returns `APP_VERSION` env var     |
| GET    | `/api/greet/<name>` | Returns a greeting                |
| GET    | `/api/time`         | Current server UTC time           |
| POST   | `/api/echo`         | Echoes back the request body      |
| GET    | `/api/items`        | List in-memory items              |
| POST   | `/api/items`        | Create an item: `{"name": "..."}` |
| DELETE | `/api/items/<id>`   | Delete an item by id              |

## 2. Run it locally (no Docker)

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
make run            # starts on http://localhost:8080
```

Run the tests:

```bash
make test
make lint
```

## 3. Build and run with Docker

```bash
docker build -t flask-docker-webapp:local .
docker run --rm -p 8080:8080 flask-docker-webapp:local
curl http://localhost:8080/health
```

Or with Compose:

```bash
docker compose up --build
```

The Dockerfile:

- Uses a **builder stage** to install Python dependencies, and a separate
  slim **runtime stage** so build tools never ship in the final image.
- Runs as a **non-root user** (`app`).
- Declares a `HEALTHCHECK` so orchestrators (Docker, Swarm, Kubernetes
  readiness probes via exec, etc.) can detect liveness.
- Serves the app with `gunicorn` rather than the Flask dev server.

## 4. Push the image to a registry manually (optional)

```bash
docker tag flask-docker-webapp:local ghcr.io/<github-username>/flask-docker-webapp:manual
echo $GITHUB_TOKEN | docker login ghcr.io -u <github-username> --password-stdin
docker push ghcr.io/<github-username>/flask-docker-webapp:manual
```

(Mentioned below ci/cd pipeline steps)

## 5. The CI/CD pipeline (`''/.github/workflows/ci-04-dockerize_webapp.yml`)

The workflow has three jobs:

1. **`test`** — runs on every push and pull request. Installs dependencies,
   runs `flake8`, then `pytest` with coverage. Nothing else runs if this fails.
2. **`build-and-push`** — runs only on `push` events (not PRs), after `test`
   passes. It:
   - Sets up Docker Buildx + QEMU for **multi-architecture builds**
     (`linux/amd64` and `linux/arm64`).
   - Logs into **GHCR** using the automatically-provided `GITHUB_TOKEN`
     (no secrets to configure).
   - Optionally also logs into **Docker Hub** if you've added
     `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` repo secrets.
   - Uses `docker/metadata-action` to compute tags automatically:
     - `latest` on the default branch
     - semantic version tags (`v1.2.3` → `1.2.3` and `1.2`) when you push a
       Git tag like `v1.2.3`
     - the short commit SHA, for traceability
   - Builds and pushes with `docker/build-push-action`, using GitHub Actions
     cache (`type=gha`) to speed up subsequent builds.
3. **`deploy`** — a placeholder job that only fires on version tags
   (`refs/tags/v*`). Replace its single `echo` step with whatever your real
   deployment mechanism is (SSH + `docker compose pull && up -d`, a
   Kubernetes `kubectl rollout restart`, an ECS service update, Argo CD sync,
   etc.).

### One-time setup steps on GitHub

1. **Push this repo to GitHub.**
2. **Allow the workflow to publish packages:**
   _Settings → Actions → General → Workflow permissions_ → select
   **"Read and write permissions"** (needed so `GITHUB_TOKEN` can push to
   GHCR). This is the only mandatory setup step — no registry secrets are
   required for GHCR.
3. _(Optional)_ To also push to Docker Hub, add two repository secrets under
   _Settings → Secrets and variables → Actions_:
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_TOKEN` (a Docker Hub access token, not your password)
4. _(Optional)_ By default the published GHCR package is private. To make it
   public: go to the package page on your GitHub profile/org → **Package
   settings** → **Change visibility**.

### Triggering the pipeline

- Push to `main` → runs tests, then builds & pushes an image tagged `latest`
  and `sha-<commit>`.
- Push a tag, e.g.:
  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```
  → runs tests, builds & pushes an image tagged `1.0.0` and `1.0`, then runs
  the `deploy` job.
- Open a pull request → only the `test` job runs (no image is built/pushed),
  so PRs can't accidentally publish images.

### Pulling the published image

```bash
docker pull ghcr.io/<github-username>/flask-docker-webapp:latest
docker run --rm -p 8080:8080 ghcr.io/<github-username>/flask-docker-webapp:latest
```
