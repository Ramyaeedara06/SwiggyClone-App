# Swiggy-Clone (Sample) - CI/CD Ready
This is a sample Swiggy-Clone Node.js backend repo prepared for Jenkins CI/CD, Docker, and Kubernetes deployment.
Files included:
- `Jenkinsfile` - Declarative pipeline (build, test, docker build/push, deploy)
- `Dockerfile` - Multi-stage production image
- `k8s/` - Kubernetes manifests (namespace, deployment, service, ingress)
- `src/` - Minimal Express app with health endpoint and sample routes
- `tests/` - Jest sample test
- `.dockerignore`, `package.json`, `scripts/migrate.sh`

Edit registry, credentials IDs, and any environment-specific values in `Jenkinsfile` before using.
