# Koa TypeScript Kubernetes app

This directory contains a small Koa application written in TypeScript. It is
the Koa counterpart to [`03_express_app`](../03_express_app) and intentionally
keeps the same process-local slow-request behavior. The application is
containerized with Docker and deployed with Kubernetes.

## Application behavior

The application listens on port `80` in the container. The local Docker
configuration publishes that port as `8083`.

| Endpoint | Behavior |
| --- | --- |
| `GET /` | Returns a greeting. |
| `GET /slow?n=100` | Increments the process-local request counter and delays the response by `requestCount * n` milliseconds. |
| `GET /healthz` | Delays by `requestCount * 100` milliseconds, then returns the current counter and delay. |
| `GET /readyz` | Returns immediately with `{ "status": "UP" }`. |

The counter is held in application memory. Each Pod has its own counter, so
scaling from one to five replicas creates five independent counters rather than
one shared counter. Restarting a Pod resets its counter.

## Project structure

```text
04_koa_ts/
├── Dockerfile
├── docker-compose.yml
├── kubernetes.yaml
├── restapi/
│   ├── package.json
│   ├── package-lock.json
│   ├── tsconfig.json
│   └── source/index.ts
└── scripts/
    ├── compose/      # Start, stop, restart, and remove Compose resources
    ├── docker/       # Build, start, stop, and restart locally
    ├── k9s/          # Build/push and deploy/remove Kubernetes resources
    └── test/         # wrk load test and Kubernetes metrics helpers
```

## Build and run locally

### Using Docker Compose

From this directory, run:

```bash
docker compose up --build
```

Then test the application:

```bash
curl http://localhost:8083/
curl http://localhost:8083/readyz
curl "http://localhost:8083/slow?n=100"
curl http://localhost:8083/healthz
```

The helper script is equivalent for a standalone Docker container:

```bash
./scripts/docker/start-container.sh
```

The Dockerfile uses two stages. The builder installs development dependencies
and compiles `source/index.ts` into `dist/index.js`. The final image copies the
compiled output and production dependencies only.

### Building TypeScript without Docker

```bash
cd restapi
npm install
npm run build
npm start
```

## Kubernetes resources

[`kubernetes.yaml`](./kubernetes.yaml) contains every resource needed for the
application and its scheduled scaling:

1. **ServiceAccount** `learniken-koa-scaler` — identity used by the scaling
   Jobs.
2. **Role** and **RoleBinding** — allow that identity to read and update only
   the `deployments/scale` subresource in the `default` namespace.
3. **Deployment** `learniken-koa-ts-app` — runs the Koa Pods and starts with
   `replicas: 1`.
4. **Service** `learniken-koa-ts-app-service` — exposes port `8083` and routes
   to Pods labeled `app: koa-ts-app`.
5. **Three CronJobs** — run `kubectl scale` at the scheduled times.

The readiness probe calls `/readyz` and controls whether a Pod receives
traffic. The liveness probe calls `/healthz`. Because `/healthz` deliberately
gets slower as the counter grows, it also demonstrates how an expensive
liveness endpoint can affect Kubernetes health checks.

## Scheduled scaling mechanism

Scaling is defined in Kubernetes YAML rather than in the application code or
in an external shell process. Each CronJob creates a short-lived Pod at its
scheduled time. That Pod runs the Kubernetes CLI with a command equivalent to:

```bash
kubectl scale deployment/learniken-koa-ts-app --replicas=<target>
```

The three schedules are:

| CronJob | Local time | Cron expression | Target replicas |
| --- | ---: | --- | ---: |
| `learniken-koa-scale-up-one` | 07:00 | `0 7 * * *` | 1 |
| `learniken-koa-scale-up-five` | 09:00 | `0 9 * * *` | 5 |
| `learniken-koa-scale-down-zero` | 17:00 | `0 17 * * *` | 0 |

All three CronJobs specify:

```yaml
timeZone: "Europe/Oslo"
concurrencyPolicy: Forbid
```

Therefore, the times follow Norwegian local time, including daylight-saving
time changes, and Kubernetes does not start a second run if the previous run
has not finished. The `timeZone` field requires a Kubernetes version that
supports time-zone-aware CronJobs. On older clusters, validate the cluster
version before applying this manifest.

### What happens during the day

1. **Before 07:00** — after the previous 17:00 run, the Deployment has zero
   Pods. The Service still exists, but it has no ready endpoints.
2. **At 07:00** — the first CronJob changes the Deployment to one replica.
   Kubernetes creates a Pod, waits for it to pass readiness, and then the
   Service can route traffic to it.
3. **At 09:00** — the second CronJob changes the Deployment to five replicas.
   Kubernetes creates four additional Pods. Requests may reach any replica,
   and each replica has its own slow-request counter.
4. **At 17:00** — the final CronJob changes the Deployment to zero replicas.
   Kubernetes terminates the Pods and the Service has no ready endpoints until
   the next 07:00 run.

The Deployment's `replicas: 1` value is the initial state when the manifest is
first applied. The CronJobs subsequently change the live Deployment scale; the
scheduled values are not stored by the Deployment itself.

### Why RBAC is included

Pods do not automatically have permission to modify Deployments. The manifest
grants the CronJob ServiceAccount the minimum required permissions:

```yaml
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get"]
- apiGroups: ["apps"]
  resources: ["deployments/scale"]
  verbs: ["get", "patch", "update"]
```

Both rules are required. `kubectl scale` first reads the Deployment object
itself to resolve it, and then writes the new replica count through the
`scale` subresource. Granting only `deployments/scale` makes the Job fail with
`error: no objects passed to scale`, because the lookup step is denied before
any scaling is attempted. The permissions are limited to the `default`
namespace and do not allow creating or deleting Deployments.

The CronJob Pods use `registry.k8s.io/kubectl:v1.31.0`, which provides the
`kubectl` command inside the cluster. The command uses the Pod's in-cluster
Kubernetes credentials and does not require a kubeconfig file or a secret
embedded in the repository.

## Deploying to Kubernetes

The image referenced by the Deployment is
`magneka/learniken-koa-ts-app:latest`, and the Deployment sets
`imagePullPolicy: IfNotPresent` so a locally available image is used without
contacting a registry.

### Step 1 — Build the image

```bash
docker build -t magneka/learniken-koa-ts-app:latest -f Dockerfile .
```

### Step 2 — Make the image available to the cluster

Recent Docker Desktop versions run Kubernetes as a `kind`-style cluster whose
containerd image store is **separate from the Docker image store**. A locally
built image is therefore not visible to the cluster, and the Pod fails with
`ImagePullBackOff` and `pull access denied`.

Check which situation applies:

```bash
kubectl get nodes
```

If the node is named `desktop-control-plane`, the image must be imported into
the node. Export it and load it into the node's containerd:

```bash
docker save magneka/learniken-koa-ts-app:latest -o /tmp/koa-ts-app.tar
```

Then run a temporary privileged helper Pod that can reach the node:

```bash
kubectl run image-loader --image=alpine:3.20 --restart=Never \
  --overrides='{"spec":{"hostPID":true,"containers":[{"name":"loader","image":"alpine:3.20","command":["sleep","3600"],"securityContext":{"privileged":true},"volumeMounts":[{"name":"host-tmp","mountPath":"/host-tmp"}]}],"volumes":[{"name":"host-tmp","hostPath":{"path":"/tmp","type":"Directory"}}]}}'

kubectl wait --for=condition=Ready pod/image-loader --timeout=180s
kubectl cp /tmp/koa-ts-app.tar default/image-loader:/host-tmp/koa-ts-app.tar
kubectl exec image-loader -- nsenter -t 1 -m -u -i -n -p -- \
  ctr -n k8s.io images import /tmp/koa-ts-app.tar
kubectl delete pod image-loader
```

Verify the image is registered in the cluster:

```bash
kubectl exec image-loader -- nsenter -t 1 -m -u -i -n -p -- \
  ctr -n k8s.io images ls | grep koa
```

If you instead push the image to a registry the cluster can reach, this step
is unnecessary:

```bash
./scripts/k9s/push-container.sh
```

### Step 3 — Apply the manifest

```bash
kubectl apply -f kubernetes.yaml
kubectl rollout status deployment/learniken-koa-ts-app
```

If the Deployment already existed while the image was missing, trigger a new
rollout so the Pods retry with the now-available image:

```bash
kubectl rollout restart deployment/learniken-koa-ts-app
```

The deployment helper performs the apply, waits for the rollout, displays
resource information, and starts a temporary port-forward:

```bash
./scripts/k9s/deploy-to-k8s.sh
```

The PowerShell equivalents are available beside the Bash scripts for Windows
hosts.

### Step 4 — Reach the application

```bash
kubectl port-forward svc/learniken-koa-ts-app-service 18083:8083
curl http://localhost:18083/
curl "http://localhost:18083/slow?n=100"
```

Port `8083` on the host may already be used by another container or service.
If `kubectl port-forward` reports `address already in use`, choose a different
local port as shown above.

## Inspecting and testing scaling

Inspect the Deployment, CronJobs, Pods, and Service:

```bash
kubectl get deployment learniken-koa-ts-app
kubectl get cronjobs
kubectl get jobs
kubectl get pods -l app=koa-ts-app
kubectl get service learniken-koa-ts-app-service
```

View the most recent scaling Jobs and their logs:

```bash
kubectl get jobs --sort-by=.metadata.creationTimestamp
kubectl logs job/<job-name>
```

To test the scaling command without waiting for the clock, create a one-off
Job from one of the CronJobs:

```bash
kubectl create job --from=cronjob/learniken-koa-scale-up-five manual-scale-up-five
kubectl wait --for=condition=complete job/manual-scale-up-five --timeout=120s
kubectl get deployment learniken-koa-ts-app
```

This is a test of the same container command and RBAC path used by the
scheduled Job. Remove the temporary Job after testing:

```bash
kubectl delete job manual-scale-up-five
```

To run a load test against a port-forwarded Service:

```bash
kubectl port-forward service/learniken-koa-ts-app-service 8083:8083
./scripts/test/wrk-test.sh
```

## Removing the resources

Delete the Deployment, Service, RBAC resources, and CronJobs together with:

```bash
./scripts/k9s/remove-from-k8s.sh
```

Or run the Kubernetes command directly:

```bash
kubectl delete -f kubernetes.yaml
```
