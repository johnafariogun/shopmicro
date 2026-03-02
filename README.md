(empty)
**ShopMicro**

Small e‑commerce microservices sample used for the Capstone project. Contains a React frontend, a Node.js/Express backend, and a Python Flask ML-service. The repository includes Docker and Kubernetes manifests and CI/CD workflows.

**Architecture**
- **Frontend**: React + Vite — code in [frontend](frontend)
- **Backend**: Node.js + Express + PostgreSQL + Redis — code in [backend](backend)
- **ML-Service**: Python Flask recommending service — code in [ml-service](ml-service)
- **Infra**: Docker Compose for local development and Kubernetes manifests for cluster deployment in `k8s/`.

**Key Files**
- **Backend entry**: [backend/server.js](backend/server.js)
- **Frontend entry**: [frontend/src/App.jsx](frontend/src/App.jsx)
- **ML-Service entry**: [ml-service/app.py](ml-service/app.py)
- **Docker Compose**: [docker-compose.yml](docker-compose.yml)
- **Kubernetes manifests**: k8s/ (namespace, deployments, services)
- **CI**: [.github/workflows/ci.yaml](.github/workflows/ci.yaml)
- **CD**: [.github/workflows/cd.yaml](.github/workflows/cd.yaml)

**Observability (current status)**
- **Backend**: ✅ Instrumented with OpenTelemetry (OTLP) and Prometheus metrics. Good tracing and metrics; needs structured JSON logging. See [backend/server.js](backend/server.js).
- **ML-Service**: ✅ Instrumented with OpenTelemetry and Prometheus. Good tracing and metrics; needs structured logging and resilience improvements. See [ml-service/app.py](ml-service/app.py).
- **Frontend**: ❌ No observability. Add OpenTelemetry Web SDK and error tracking (Sentry) to capture RUM and propagate trace context.

**Local development**
- Start dependent services (Postgres, Redis): `docker compose up -d postgres redis` or use the top-level `docker-compose.yml`.
- Start backend: `cd backend && npm install && npm start`
- Start ml-service: `cd ml-service && pip install -r requirements.txt && python app.py`
- Start frontend (dev): `cd frontend && npm install && npm run dev`

**Testing**
- Backend unit tests (if present): `cd backend && npm test`
- ML-Service tests: `cd ml-service && pytest`
- Frontend tests: `cd frontend && npm test`

**CI / CD**
- CI runs lint, tests, and build jobs: [.github/workflows/ci.yaml](.github/workflows/ci.yaml).
- CD deploys to a self‑managed Kubernetes cluster using a kubeconfig secret: [.github/workflows/cd.yaml](.github/workflows/cd.yaml).
- To enable CD, add `KUBECONFIG` (base64) and other secrets to GitHub repository secrets.
