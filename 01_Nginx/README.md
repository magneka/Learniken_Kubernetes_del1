# Simple Nginx Kubernetes example

One Nginx pod serves [index.html](index.html). No image build or registry account
is needed: Kubernetes downloads the official `nginx:stable-alpine` image.
There are no YAML files: the commented scripts create everything using `kubectl`.

## Requirements

- A running Kubernetes cluster (for example, Docker Desktop Kubernetes or Minikube).
- `kubectl` installed and configured to access it.
- Local port `8080` available.

The scripts use the **current kubectl context** and the **default namespace**.
Check your target cluster with `kubectl config current-context` before starting.
Resources are named `nginx-example`; do not use these names for unrelated workloads.

## Run

From this folder on macOS/Linux (Bash):

```bash
./start.sh
```

On Windows (Command Prompt):

```bat
start.bat
```

Open **http://localhost:8080**. Keep the start terminal open: it runs port
forwarding in the foreground. Ctrl+C stops forwarding only; Nginx keeps running.

To verify the running page from another terminal:

```bash
./verify.sh
```

On Windows:

```bat
verify.bat
```

The verify script uses `curl`, checks for a successful HTTP response, and confirms
that the expected Nginx page text is present. Pass a URL as the first argument if
you use another local port, for example `./verify.sh http://localhost:9090`.
If port `8080` is already occupied, start with another port, for example
`NGINX_PORT=18080 ./start.sh`, then run
`./verify.sh http://localhost:18080`.

## Stop or remove

Run the appropriate command in another terminal:

| Action | Bash | Windows Command Prompt |
| --- | --- | --- |
| Verify the running page | `./verify.sh` | `verify.bat` |
| Stop Nginx, keeping its Kubernetes configuration | `./stop.sh` | `stop.bat` |
| Remove this example's Kubernetes resources | `./remove.sh` | `remove.bat` |

Stopping scales the Deployment to zero pods. Each start recreates the Deployment
and HTML ConfigMap with one pod, briefly interrupting any running example.
An existing port-forward session ends when its pod is stopped or removed;
close that terminal with Ctrl+C if needed.
Removal is safe to repeat and does not delete local files or the namespace.

## How it works

- `kubectl create configmap` packages the HTML file into a ConfigMap.
- `kubectl create deployment` creates the Nginx Deployment.
- `kubectl patch` mounts the ConfigMap in Nginx's web directory using inline JSON.
- The start script waits for the Deployment, then forwards localhost port `8080`
  directly to the pod's port `80`. No Service or Kustomize configuration is needed.

Edit [index.html](index.html), end any existing port-forward session with Ctrl+C,
and run the start script again to deploy the updated page.
The remove scripts also clean up the Service and labeled ConfigMaps from the
earlier YAML-based version, if you previously ran it.
