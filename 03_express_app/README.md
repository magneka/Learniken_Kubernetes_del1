# Kubernetes Minimal Node

A minimal Express.js app containerized with Docker and deployed to Kubernetes, with helper scripts (bash + PowerShell) for the full build/push/deploy/teardown lifecycle.

## Project layout

```
Dockerfile              Multi-stage build for the Express app
kubernetes.yaml         Deployment + Service manifest
express_app/            Express.js source (index.js, package.json)
scripts/compose/        Start, stop, restart, and remove Docker Compose resources
start-container.sh/.ps1 Build + run the app as a standalone Docker container
push-container.sh/.ps1  Build + push the image to Docker Hub
deploy-to-k8s.sh/.ps1   Apply the manifest, wait for rollout, smoke-test
remove-from-k8s.sh/.ps1 Tear down the deployment + service
get-metrics.sh/.ps1     Dump deployment/pod/service status, resource usage, logs
```

## Dockerfile explained

```dockerfile
FROM node:18-alpine as builder
ENV NODE_ENV="production"
COPY ./express_app /app
WORKDIR /app
RUN npm install

FROM node:18-alpine
ENV NODE_ENV="production"
COPY --from=builder /app /app
WORKDIR /app
ENV PORT 80
EXPOSE 80

CMD ["npm", "start"]
```

This is a **multi-stage build**: two `FROM` stages share the same base image, but only the final stage ends up in the shipped image.

- **Stage 1 — `builder`**
  - `FROM node:18-alpine as builder` — starts from the small Alpine-based Node 18 image and names this stage `builder` so it can be referenced later.
  - `ENV NODE_ENV="production"` — tells `npm install` to skip `devDependencies` and tells Express/other libraries to run in production mode.
  - `COPY ./express_app /app` — copies the app source (`index.js`, `package.json`) into `/app` inside the image.
  - `WORKDIR /app` — all subsequent commands run from `/app`.
  - `RUN npm install` — installs dependencies based on `package.json`, producing `node_modules`.

- **Stage 2 — final image**
  - `FROM node:18-alpine` — starts a **fresh** image (none of the build layers/cache from stage 1 are carried over).
  - `COPY --from=builder /app /app` — copies only the final `/app` folder (source + installed `node_modules`) from the `builder` stage. This keeps the final image lean since any build-only tooling isn't present (in this simple case there isn't much difference, but the pattern matters as the app grows).
  - `WORKDIR /app` — working directory for the running container.
  - `ENV PORT 80` — sets the port the Express app listens on (read via `process.env.PORT` in [index.js](express_app/index.js)).
  - `EXPOSE 80` — documents that the container listens on port 80 (informational only; it doesn't actually publish the port — that's done with `docker run -p` or the Kubernetes Service).
  - `CMD ["npm", "start"]` — the container's default command, which runs the `start` script from `package.json` (`node index.js`).

### Why multi-stage?

Even though this app has no separate compile step, the multi-stage pattern is still valuable: it keeps a clean separation between "things needed to build" and "things needed to run," and it's trivial to extend later (e.g. adding a TypeScript build step in `builder` without bloating the runtime image).

## kubernetes.yaml explained

The file defines two Kubernetes objects, separated by `---`.

### 1. Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: learniken-express-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: express-app
  template:
    metadata:
      labels:
        app: express-app
    spec:
      containers:
      - name: express-app
        image: <your_dockerhub_name>/learniken-express-app:latest
        ports:
        - containerPort: 80
        env:
        - name: PORT
          value: "80"
```

A `Deployment` manages a set of identical Pod replicas and handles rolling updates, restarts, and self-healing.

- `metadata.name` — the Deployment's own name, `learniken-express-app` (used by `kubectl rollout status deployment/learniken-express-app`, etc.).
- `spec.replicas: 1` — run exactly 1 copy (Pod) of the app. Increase this for horizontal scaling / high availability.
- `spec.selector.matchLabels` — tells the Deployment which Pods it owns, by matching the label `app: express-app`. This **must** match `template.metadata.labels` below.
- `spec.template` — the Pod template used to create each replica:
  - `metadata.labels: app: express-app` — the label applied to every Pod this Deployment creates. The Service (below) uses this same label to find the Pods.
  - `spec.containers[0].name` — container name within the Pod (`express-app`).
  - `image` — the Docker image to pull and run: `<your_dockerhub_name>/learniken-express-app:latest` (built/pushed via [push-container.sh](push-container.sh)/[.ps1](push-container.ps1), or built locally and picked up directly from Docker Desktop's shared image store).
  - `ports.containerPort: 80` — informational declaration of the port the container listens on (mirrors `EXPOSE 80` in the Dockerfile).
  - `env` — sets the `PORT` environment variable inside the container to `80`, read by `index.js` via `process.env.PORT`.

### 2. Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: learniken-express-app-service
spec:
  type: LoadBalancer
  ports:
  - port: 8082
    targetPort: 80
  selector:
    app: express-app
```

A `Service` provides a stable network endpoint in front of a set of Pods (Pods come and go, but the Service's address stays constant).

- `metadata.name` — `learniken-express-app-service`, referenced by `kubectl get svc` and `kubectl port-forward svc/...`.
- `spec.type: LoadBalancer` — requests an externally reachable IP/port. On Docker Desktop's local cluster this resolves to `localhost`/the Docker Desktop VM IP; on a cloud provider (AKS, EKS, GKE) this provisions a real cloud load balancer.
- `spec.selector: app: express-app` — routes traffic to any Pod carrying the label `app: express-app` (i.e., the Pods created by the Deployment above).
- `spec.ports`:
  - `port: 8082` — the **external/service-facing** port. Clients (or `kubectl port-forward`) connect to this port.
  - `targetPort: 80` — the **container port** traffic is forwarded to, matching `containerPort` in the Deployment and `EXPOSE 80`/`PORT=80` in the Dockerfile.

This split lets the externally exposed port (`8082`) differ from the port the app actually listens on internally (`80`) — useful for avoiding clashes with privileged ports or other services, without having to change the application code.

### How the two tie together

```
Client → Service (port 8082) → selector app=express-app → Pod(s) (containerPort 80) → Express app (PORT=80)
```

`kubectl apply -f kubernetes.yaml` creates/updates both objects in one step (see [deploy-to-k8s.sh](deploy-to-k8s.sh)/[.ps1](deploy-to-k8s.ps1)); `kubectl delete -f kubernetes.yaml` removes both (see [remove-from-k8s.sh](remove-from-k8s.sh)/[.ps1](remove-from-k8s.ps1)).

## Commands

Every script has a bash (`.sh`) and PowerShell (`.ps1`) version with identical behavior. Run them from the repo root.

### Build & run locally (no Kubernetes)

Builds the Docker image and runs it as a single standalone container (no cluster involved) — useful for quick local testing.

```bash
./start-container.sh
```
```powershell
.\start-container.ps1
```
Runs:
```bash
docker build -t express-app .
docker run -d -p 8082:80 --name express-app-container express-app
```
App becomes available at `http://localhost:8082`.

### Build & push to Docker Hub

Builds the image tagged as `<your_dockerhub_name>/learniken-express-app:latest`, logs in to Docker Hub (prompts if not already authenticated), and pushes it. Only needed if you want the image available in a registry (e.g. for a remote cluster) — Docker Desktop's local Kubernetes can use the locally built image directly without this step.

```bash
./push-container.sh
```
```powershell
.\push-container.ps1
```
Runs:
```bash
docker build -t <your_dockerhub_name>/learniken-express-app:latest .
docker login
docker push <your_dockerhub_name>/learniken-express-app:latest
```

### Deploy to Kubernetes

Applies [kubernetes.yaml](kubernetes.yaml) (creates/updates the Deployment + Service), waits for the rollout to finish, lists pods/service info, then port-forwards and curls the service once as a smoke test.

```bash
./deploy-to-k8s.sh
```
```powershell
.\deploy-to-k8s.ps1
```
Runs (summarized):
```bash
kubectl apply -f kubernetes.yaml
kubectl rollout status deployment/learniken-express-app
kubectl get pods
kubectl get svc learniken-express-app-service
kubectl port-forward svc/learniken-express-app-service 8082:8082   # temporary, for the smoke test
curl http://localhost:8082
```
Prerequisite: the image referenced in `kubernetes.yaml` must already exist — either built locally with `docker build -t <your_dockerhub_name>/learniken-express-app:latest .` (Docker Desktop's cluster shares the local image cache) or pushed via `push-container`.

Replace `<your_dockerhub_name>` in [kubernetes.yaml](kubernetes.yaml), [push-container.sh](push-container.sh), and [push-container.ps1](push-container.ps1) with your actual Docker Hub username before running these commands.

### Remove from Kubernetes

Deletes the Deployment and Service created from [kubernetes.yaml](kubernetes.yaml). Safe to re-run — uses `--ignore-not-found` so it won't error if already removed.

```bash
./remove-from-k8s.sh
```
```powershell
.\remove-from-k8s.ps1
```
Runs:
```bash
kubectl delete -f kubernetes.yaml --ignore-not-found
kubectl get deployment,svc,pods -l app=express-app   # shows what (if anything) remains
```

### Get metrics / status

Dumps as much live information about the deployment as possible in one shot: deployment status, replica set, pods, service, CPU/memory usage (requires `metrics-server`), full pod `describe` output (requests/limits, restarts, events), recent events, and recent logs.

```bash
./get-metrics.sh
```
```powershell
.\get-metrics.ps1
```
Runs (summarized):
```bash
kubectl get deployment learniken-express-app -o wide
kubectl get rs -l app=express-app -o wide
kubectl get pods -l app=express-app -o wide
kubectl get svc learniken-express-app-service -o wide
kubectl top pods -l app=express-app
kubectl top nodes
kubectl describe pods -l app=express-app
kubectl get events --field-selector involvedObject.kind=Pod --sort-by='.lastTimestamp'
kubectl logs -l app=express-app --tail=50 --all-containers
```
Note: `kubectl top` requires `metrics-server` installed in the cluster. On Docker Desktop's local cluster, install it with:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```
(the `--kubelet-insecure-tls` patch is needed because Docker Desktop's kubelet uses a self-signed certificate).

### Typical end-to-end flow

```bash
./deploy-to-k8s.sh      # build happens separately — see prerequisite note above
./get-metrics.sh         # check replicas, resource usage, logs
./remove-from-k8s.sh     # tear down when done
```
