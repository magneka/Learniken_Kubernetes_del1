# Simple Nginx Kubernetes YAML example

This is the YAML-based version of [01_Nginx](../01_Nginx). One Nginx pod serves
[index.html](index.html). A single manifest, [nginx.yaml](nginx.yaml), defines
the Deployment, and the start script turns `index.html` into a ConfigMap that is
mounted as Nginx's web directory. No image build or registry account is needed.

## Requirements

- A running Kubernetes cluster, such as Docker Desktop Kubernetes or Minikube.
- `kubectl` installed and configured to access it.
- Local port `8081` available.

The scripts use the current `kubectl` context and the `default` namespace.

## Run

From this folder on macOS/Linux:

```bash
./start.sh
```

On Windows:

```bat
start.bat
```

Open **http://localhost:8081**. Keep the start terminal open because it runs
port forwarding in the foreground. Use `verify.sh` or `verify.bat` from another
terminal to check the page.

Set `NGINX_PORT` to use another local port, for example
`NGINX_PORT=18081 ./start.sh`.

## Stop or remove

| Action | Bash | Windows |
| --- | --- | --- |
| Verify the page | `./verify.sh` | `verify.bat` |
| Stop Nginx | `./stop.sh` | `stop.bat` |
| Remove the resources | `./remove.sh` | `remove.bat` |

Stopping scales the Deployment to zero. Removing deletes the Deployment defined
in [nginx.yaml](nginx.yaml) and the generated `nginx-example-yaml-html` ConfigMap.

Edit [index.html](index.html) and run the start script again to deploy the
updated page.
