# Kubernetes minimal examples

Small container and Kubernetes examples, progressing from a single Nginx Pod
to REST APIs implemented with several different languages and frameworks. Each
example has its own README with complete build, run, test, and cleanup
instructions.

## Examples

| Example | Description | Local port | Documentation |
| --- | --- | ---: | --- |
| `01_Nginx` | Nginx served by a Deployment created with `kubectl` commands (no YAML manifest). | 8080 | [README](01_Nginx/README.md) |
| `02_Nginx_yaml` | Nginx served by a Deployment and ConfigMap defined with a YAML manifest. | 8081 | [README](02_Nginx_yaml/README.md) |
| `03_express_app` | Node.js Express REST app built with Docker and deployed with Kubernetes. | 8082 | [README](03_express_app/README.md) |
| `04_koa_ts` | Koa REST app written in TypeScript, with Docker and Kubernetes deployment. | 8083 | [README](04_koa_ts/README.md) |
| `05_nestjs_ts` | NestJS REST app written in TypeScript, with Docker and Kubernetes deployment. | 8084 | [README](05_nestjs_ts/README.md) |
| `06_csharp_app/csharp_rest` | .NET minimal REST API packaged as a container and deployed to Kubernetes. | 8085 | [README](06_csharp_app/csharp_rest/README.md) |
| `07_go/go_rest` | Go REST API packaged as a container and deployed to Kubernetes. | 8086 | [README](07_go/go_rest/README.md) |
| `08_java_spring_boot/spring_rest` | Spring Boot REST API packaged as a container and deployed to Kubernetes. | 8087 | [README](08_java_spring_boot/spring_rest/README.md) |
| `09_rust_app/08_rust_rest` | Rust REST API packaged as a container and deployed to Kubernetes. | 8088 | [README](09_rust_app/08_rust_rest/README.md) |

The application examples generally provide the same basic REST endpoints,
including `/`, `/healthz`, `/readyz`, and `/slow`. Check the example README for
the exact port, commands, endpoints, and Kubernetes resources.

## Common prerequisites

Install the tools required by the example you want to run:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with Docker
  Compose and, if desired, its built-in Kubernetes cluster.
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/) configured for a running
  Kubernetes cluster.
- `curl` for the smoke-test commands.
- The language toolchain only when running an application without Docker:
  Node.js/npm, the .NET SDK, Go, Java/Maven, or Rust/Cargo.

Run commands from the example directory unless its README says otherwise.
The shell scripts target macOS/Linux; PowerShell or `.bat` variants are
provided where applicable.

## Docker Hub username

The container push/build scripts use `magneka` as the example Docker Hub
username. Before pushing an image, replace `magneka` with your own Docker Hub
username in the relevant push/build script and in the matching Kubernetes
manifest. Otherwise the script will try to push to repositories owned by
`magneka`, or Kubernetes will try to pull the wrong image.

Find all remaining references from the repository root:

```bash
grep -RIn --exclude-dir=.git "magneka" .
```

After changing the image names, authenticate with Docker Hub and run the
example's push script:

```bash
docker login
./scripts/k9s/push-container.sh
```

On Windows, update the `.ps1` script and run its corresponding PowerShell
command. The required Docker Hub repositories must already exist, or your
account must be allowed to create them.

## Installing `wrk` and Windows alternatives

`wrk` is a command-line HTTP benchmarking tool used by the Koa and NestJS
examples. There is no dependable, maintained `winwrk` download that should be
recommended here. On Windows, use [`hey`](https://github.com/rakyll/hey) as the
closest simple replacement, or use [k6](https://grafana.com/docs/k6/latest/)
when you need scripted scenarios.

### macOS

With [Homebrew](https://brew.sh/):

```bash
brew install wrk
wrk --version
```

### Linux

On Debian or Ubuntu, install the packaged version:

```bash
sudo apt update
sudo apt install wrk
wrk --version
```

For the latest upstream source and build instructions, see the
[official wrk repository](https://github.com/wg/wrk).

### Windows: `hey` (recommended)

`hey` provides Windows binaries on its
[releases page](https://github.com/rakyll/hey/releases). Download the Windows
archive, extract `hey.exe`, and put it in a directory on `PATH`. You can also
install it from source if Go is installed:

```powershell
go install github.com/rakyll/hey@latest
hey.exe -help
```

The common `wrk` options map to `hey` like this:

| `wrk` | `hey` |
| --- | --- |
| `-c 5` | `-c 5` |
| `-d 20s` | `-z 20s` |
| `-t 5` | no direct equivalent; `hey` uses available CPU cores |

For example, replace:

```text
wrk -t5 -c5 -d20s http://localhost:8084
```

with:

```powershell
hey.exe -c 5 -z 20s http://localhost:8084
```

`hey` uses `-n` for a fixed request count, which is useful when the test should
stop after an exact number of requests.

### Windows: k6

Install the official Windows package with `winget`:

```powershell
winget install k6 --source winget
k6 version
```

Alternatively, download the
[official k6 Windows installer](https://dl.k6.io/msi/k6-latest-amd64.msi).
Unlike `wrk` and `hey`, k6 runs a JavaScript test script, so it is better suited
to multi-step or authenticated scenarios than to a direct command replacement.

### Running a load test

Start the application first, then run the test script from that example. For
example:

```bash
cd 05_nestjs_ts
./scripts/test/wrk-test.sh
```

On Windows, use the corresponding `.ps1` script from PowerShell. `wrk` is
duration-based; the scripts use `-d` to control how long the benchmark runs.

## Repository helper scripts

The top-level scripts operate on the shared Kubernetes context:

- `list-all-pods.sh` / `list-all-pods.bat` list Pods.
- `remove-all-pods.sh` / `remove-all-pods.bat` remove all Pods in the
  `default` namespace.
- `watch-pod-restarts.sh` / `watch-pod-restarts.bat` monitor Pod restarts.

Inspect a local example README before running cleanup commands, and confirm the
active context with `kubectl config current-context`.
