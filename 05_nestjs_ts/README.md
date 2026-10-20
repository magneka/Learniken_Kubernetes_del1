# NestJS TypeScript Kubernetes app

This directory contains a small NestJS application written in TypeScript. It is
the NestJS counterpart to [`03_express_app`](../03_express_app) and intentionally
keeps the same process-local slow-request behavior. The application is
containerized with Docker and deployed with Kubernetes.

## Application behavior

The application listens on port `80` in the container. The local Docker
configuration publishes that port as `8084`.

| Endpoint | Behavior |
| --- | --- |
| `GET /` | Returns a greeting. |
| `GET /slow?n=100` | Increments the process-local request counter and delays the response by `requestCount * n` milliseconds. |
| `GET /healthz` | Delays by `requestCount * 100` milliseconds, then returns the current counter and delay. |
| `GET /readyz` | Returns immediately with `{ "status": "UP" }`. |
| `GET /metrics` | Exposes the per-Pod `requests_per_second` Prometheus gauge used by the HPA. |

The counter is held in application memory. Each Pod has its own counter, so
scaling from one to five replicas creates five independent counters rather than
one shared counter. Restarting a Pod resets its counter.

## Project structure

```text
05_nestjs_ts/
├── Dockerfile
├── docker-compose.yml
├── kubernetes.yaml
├── restapi/
│   ├── package.json
│   ├── package-lock.json
│   ├── tsconfig.json
│   ├── source/main.ts
│   ├── source/app.module.ts
│   └── source/app.controller.ts
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
curl http://localhost:8084/
curl http://localhost:8084/readyz
curl "http://localhost:8084/slow?n=100"
curl http://localhost:8084/healthz
```

The helper script is equivalent for a standalone Docker container:

```bash
./scripts/docker/start-container.sh
```

The Dockerfile uses two stages. The builder installs development dependencies
and compiles the TypeScript sources into `dist/main.js`. The final image copies the
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
application:

1. **ServiceAccount** `learniken-nestjs-scaler` — identity available for
   scaling Jobs.
2. **Deployment** `learniken-nestjs-ts-app` — runs the NestJS Pods and starts with
   `replicas: 1`.
3. **Service** `learniken-nestjs-ts-app-service` — exposes port `8084` and routes
   to Pods labeled `app: nestjs-ts-app`.
4. **HorizontalPodAutoscaler** `learniken-nestjs-ts-app-hpa` — scales the
   Deployment between 1 and 10 replicas based on a `requests_per_second`
   custom metric.

The readiness probe calls `/readyz` and controls whether a Pod receives
traffic. The liveness probe calls `/healthz`. Because `/healthz` deliberately
gets slower as the counter grows, it also demonstrates how an expensive
liveness endpoint can affect Kubernetes health checks.

### Horizontal Pod Autoscaler

```yaml
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Pods
    pods:
      metric:
        name: requests_per_second
      target:
        type: AverageValue
        averageValue: 100
```

The HPA targets an **average of 100 requests per second per Pod**. With
`type: Pods` and `type: AverageValue`, Kubernetes divides the summed metric
across the Pods and calculates the desired replica count as:

```text
desired replicas = ceil(total requests per second / 100)
```

That gives the intended behavior for sustained load:

| Total traffic | Desired Pods |
| ---: | ---: |
| 300 RPS | 3 |
| 1,000 RPS | 10 |

The application records requests in each Pod and exposes a rolling 60-second
average at `/metrics`. The Service has Prometheus scrape annotations, so a
Prometheus installation can collect the per-Pod gauge. The Prometheus Adapter
must then publish `requests_per_second` through `custom.metrics.k8s.io` for the
HPA to consume it.

On a Docker Desktop cluster, Prometheus and the Prometheus Adapter must be
installed manually before metric-driven scaling can work. See
[Required cluster components](#required-cluster-components) below.

Because the HPA owns the replica count, the Deployment's `replicas: 1` only
applies before the HPA takes over. Within one reconcile cycle, the HPA raises
the Deployment to `minReplicas: 1`:

```text
SuccessfulRescale  New size: 1; reason: Current number of replicas below Spec.MinReplicas
```

#### Required cluster components

`requests_per_second` is a **custom metric**, not a built-in resource metric
such as CPU. The cluster must therefore serve the `custom.metrics.k8s.io` API,
which normally means Prometheus plus the Prometheus Adapter, and the
application must expose the metric for Prometheus to scrape.

A default Docker Desktop cluster has neither metrics-server nor a custom
metrics adapter. The HPA is still created and still enforces `minReplicas`,
but it cannot compute a metric-driven replica count and reports:

```text
TARGETS: <unknown>/100

ScalingActive  False  FailedGetPodsMetric
  unable to get metric requests_per_second: unable to fetch metrics from
  custom metrics API: no custom metrics API (custom.metrics.k8s.io) registered
```

Verify the API is available before relying on metric-driven scaling:

```bash
kubectl get apiservices | grep custom.metrics
kubectl get hpa learniken-nestjs-ts-app-hpa
```

To scale on CPU instead, which only needs metrics-server, replace the metric
block with:

```yaml
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```


## Scheduled scaling mechanism

Scaling is defined in Kubernetes YAML rather than in the application code or
in an external shell process. Each CronJob creates a short-lived Pod at its
scheduled time. That Pod runs the Kubernetes CLI with a command equivalent to:

```bash
kubectl scale deployment/learniken-nestjs-ts-app --replicas=<target>
```

The three schedules are:

| CronJob | Local time | Cron expression | Target replicas |
| --- | ---: | --- | ---: |
| `learniken-nestjs-scale-up-one` | 07:00 | `0 7 * * *` | 1 |
| `learniken-nestjs-scale-up-five` | 09:00 | `0 9 * * *` | 5 |
| `learniken-nestjs-scale-down-zero` | 17:00 | `0 17 * * *` | 0 |

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
`magneka/learniken-nestjs-ts-app:latest`, and the Deployment sets
`imagePullPolicy: IfNotPresent` so a locally available image is used without
contacting a registry.

### Step 1 — Build the image

```bash
docker build -t magneka/learniken-nestjs-ts-app:latest -f Dockerfile .
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
docker save magneka/learniken-nestjs-ts-app:latest -o /tmp/nestjs-ts-app.tar
```

Then run a temporary privileged helper Pod that can reach the node:

```bash
kubectl run image-loader --image=alpine:3.20 --restart=Never \
  --overrides='{"spec":{"hostPID":true,"containers":[{"name":"loader","image":"alpine:3.20","command":["sleep","3600"],"securityContext":{"privileged":true},"volumeMounts":[{"name":"host-tmp","mountPath":"/host-tmp"}]}],"volumes":[{"name":"host-tmp","hostPath":{"path":"/tmp","type":"Directory"}}]}}'

kubectl wait --for=condition=Ready pod/image-loader --timeout=180s
kubectl cp /tmp/nestjs-ts-app.tar default/image-loader:/host-tmp/nestjs-ts-app.tar
kubectl exec image-loader -- nsenter -t 1 -m -u -i -n -p -- \
  ctr -n k8s.io images import /tmp/nestjs-ts-app.tar
kubectl delete pod image-loader
```

Verify the image is registered in the cluster:

```bash
kubectl exec image-loader -- nsenter -t 1 -m -u -i -n -p -- \
  ctr -n k8s.io images ls | grep nestjs
```

If you instead push the image to a registry the cluster can reach, this step
is unnecessary:

```bash
./scripts/k9s/push-container.sh
```

### Step 3 — Apply the manifest

```bash
kubectl apply -f kubernetes.yaml
kubectl rollout status deployment/learniken-nestjs-ts-app
```

If the Deployment already existed while the image was missing, trigger a new
rollout so the Pods retry with the now-available image:

```bash
kubectl rollout restart deployment/learniken-nestjs-ts-app
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
kubectl port-forward svc/learniken-nestjs-ts-app-service 18084:8084
curl http://localhost:18084/
curl "http://localhost:18084/slow?n=100"
```

Port `8084` on the host may already be used by another container or service.
If `kubectl port-forward` reports `address already in use`, choose a different
local port as shown above.

## Inspecting and testing scaling

Inspect the Deployment, CronJobs, Pods, and Service:

```bash
kubectl get deployment learniken-nestjs-ts-app
kubectl get cronjobs
kubectl get jobs
kubectl get pods -l app=nestjs-ts-app
kubectl get service learniken-nestjs-ts-app-service
```

View the most recent scaling Jobs and their logs:

```bash
kubectl get jobs --sort-by=.metadata.creationTimestamp
kubectl logs job/<job-name>
```

To test the scaling command without waiting for the clock, create a one-off
Job from one of the CronJobs:

```bash
kubectl create job --from=cronjob/learniken-nestjs-scale-up-five manual-scale-up-five
kubectl wait --for=condition=complete job/manual-scale-up-five --timeout=120s
kubectl get deployment learniken-nestjs-ts-app
```

This is a test of the same container command and RBAC path used by the
scheduled Job. Remove the temporary Job after testing:

```bash
kubectl delete job manual-scale-up-five
```

To run a load test against a port-forwarded Service:

```bash
kubectl port-forward service/learniken-nestjs-ts-app-service 8084:8084
./scripts/test/wrk-test.sh
```

`wrk` is duration-based and has **no request-count flag**; `-n` is not valid
and fails with `wrk: invalid option -- n`. The scripts therefore use
`-d20s`. To send a fixed number of requests instead, use the Lua script,
which stops the thread after 1000 responses:

```bash
wrk -t1 -c1 -d30s -s ./scripts/test/wrk-1000-requests.lua http://localhost:8084
```

Note that `wrk` still runs until `-d` expires even after the thread stops, so
the reported `Requests/sec` is averaged over the whole duration rather than
over the time the 1000 requests actually took.

Load sent through `kubectl port-forward` is also not a valid autoscaling
test: the forward pins traffic to a single Pod rather than spreading it
across the Service endpoints.

## Removing the resources

Delete the Deployment, Service, RBAC resources, and CronJobs together with:

```bash
./scripts/k9s/remove-from-k8s.sh
```

Or run the Kubernetes command directly:

```bash
kubectl delete -f kubernetes.yaml
```
