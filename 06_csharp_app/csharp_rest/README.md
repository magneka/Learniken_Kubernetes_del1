# C# .NET Core 11 Minimal API - Containerization and Kubernetes Deployment

This document provides comprehensive documentation for the C# .NET Core 11 Minimal API application, including containerization, deployment scripts, and Kubernetes configuration.

## Table of Contents

- [Overview](#overview)
- [Application Details](#application-details)
- [Prerequisites](#prerequisites)
- [Docker Hub Account](#docker-hub-account)
- [Local Development](#local-development)
  - [Using Docker](#using-docker)
  - [Using Docker Compose](#using-docker-compose)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Scripts Reference](#scripts-reference)
  - [Docker Scripts](#docker-scripts)
  - [Docker Compose Scripts](#docker-compose-scripts)
  - [Kubernetes Scripts](#kubernetes-scripts)
- [Testing](#testing)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)

---

## Overview

A minimal C# .NET Core 11 HTTP API application designed for containerization and Kubernetes deployment. The application provides REST endpoints for health monitoring and request processing, following the same pattern as the Rust, Go, and other implementations in this repository.

**Repository Structure:**
```
csharp_app/csharp_rest/
├── source/                      # Application source code
│   ├── Program.cs             # Main application code
│   ├── CSharpMinimalApi.csproj # .NET project configuration
│   ├── CSharpMinimalApi.sln    # Visual Studio solution file
│   ├── Dockerfile             # Docker image build instructions
│   ├── docker-compose.yml     # Docker Compose configuration
│   ├── kubernetes.yaml        # Kubernetes deployment manifests
│   ├── .dockerignore          # Files to exclude from Docker build
│   └── .env                  # Environment variables
│
└── scripts/                    # Deployment automation scripts
    ├── docker/                 # Docker deployment scripts
    │   ├── start-container.sh
    │   ├── stop-container.sh
    │   ├── remove-container.sh
    │   ├── restart-container.sh
    │   └── *.ps1 (PowerShell versions)
    │
    ├── compose/                # Docker Compose scripts
    │   ├── start-container.sh
    │   ├── stop-container.sh
    │   ├── remove-container.sh
    │   └── restart-container.sh
    │   └── *.ps1 (PowerShell versions)
    │
    ├── k8s/                   # Kubernetes deployment scripts
    │   ├── build-container.sh
    │   ├── start-container.sh
    │   ├── stop-container.sh
    │   ├── remove-container.sh
    │   └── restart-container.sh
    │   └── *.ps1 (PowerShell versions)
    │
    └── test/                   # Test and validation scripts
        ├── test_endpoints.sh
        ├── test_endpoints.ps1
        ├── wrk-test.sh
        └── wrk-test.ps1
```

---

## Application Details

### Source Code

The application is located in `/csharp_app/csharp_rest/source/`:

- **`Program.cs`**: Implements a minimal ASP.NET Core Web API with endpoints
- **`CSharpMinimalApi.csproj`**: Defines .NET 11 project configuration with optimization settings
- **`CSharpMinimalApi.sln`**: Visual Studio solution file
- **Port Configuration**: Defaults to port 80 (configurable via `PORT` environment variable)

### Endpoints

| Endpoint | Method | Description | Response Format |
|----------|--------|-------------|----------------|
| `/` | GET | Root endpoint | Plain text greeting |
| `/healthz` | GET | Health check | JSON with status, timestamp, request count, uptime, app name, version, framework |
| `/readyz` | GET | Readiness check | JSON with status, timestamp, request count |
| `/slow?n=<value>` | GET | Simulates delay (n * 100ms) | Text with request # and delay info |
| `*` | GET | Unknown routes | HTTP 404 Not Found with JSON error |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 80 | Internal container port |
| `APP_NAME` | CSharp Minimal API | Application name for responses |
| `ASPNETCORE_ENVIRONMENT` | Production | ASP.NET Core environment |
| `ASPNETCORE_URLS` | http://+:80 | Listening URLs for Kestrel |
| `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT` | false | Globalization behavior |

### Project Configuration

The .NET Core 11 project is configured for optimal deployment:
- **Target Framework**: net11.0
- **Trimmed Publishing**: Enabled for smaller deployment size
- **ReadyToRun**: Enabled for faster startup
- **Single File**: Disabled for better compatibility
- **Docker OS**: Linux

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose | Download |
|------|---------|---------|----------|
| .NET SDK | 11.0.200+ | .NET development | https://dotnet.microsoft.com |
| Docker | 24.0+ | Container runtime | https://www.docker.com |
| Docker Compose | 2.20+ | Multi-container orchestration | Included with Docker Desktop |
| kubectl | 1.28+ | Kubernetes CLI | https://kubernetes.io/docs/tasks/tools/ |
| Kubernetes | 1.25+ | Container orchestration | Docker Desktop includes local cluster |
| curl | Any | HTTP client for testing | Built-in on most systems |

### Docker Desktop Configuration

For local Kubernetes testing, Docker Desktop provides a built-in single-node Kubernetes cluster:

1. Install Docker Desktop
2. Enable Kubernetes in Docker Desktop settings:
   - Open Docker Desktop
   - Go to Settings -> Kubernetes
   - Check "Enable Kubernetes"
   - Click "Apply & Restart"

### .NET Core 11 Installation

To build the application locally (optional, not needed for Docker builds):

```bash
# Install .NET 11 SDK
# macOS: brew install --cask dotnet-sdk
# Windows: Download from https://dotnet.microsoft.com/download
# Ubuntu: wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && sudo dpkg -i packages-microsoft-prod.deb && sudo apt-get update && sudo apt-get install -y dotnet-sdk-11.0

# Verify installation
dotnet --version
```

---

## Docker Hub Account

### Account Information

| Detail | Value |
|--------|-------|
| **Username** | magneka |
| **Repository** | learniken-csharp-app |
| **Image Tag** | latest |
| **Full Image Name** | `docker.io/magneka/learniken-csharp-app:latest` |
| **Access** | Public |

### Authentication

To push new images to Docker Hub:

```bash
# Login to Docker Hub
docker login
# Username: magneka
# Password: [your password]

# Verify authentication
docker pull magneka/learniken-csharp-app:latest
```

### Image Information

| Detail | Value |
|--------|-------|
| **Base Image** | mcr.microsoft.com/dotnet/aspnet:11.0.202-alpine3.19 |
| **Build Image** | mcr.microsoft.com/dotnet/sdk:11.0.202-alpine3.19 |
| **Architecture** | Multi-platform (arm64, amd64) |
| **Size** | ~120MB |
| **User** | Runs as non-root user (appuser) |

---

## Local Development

### Using Docker

#### Build the Image

```bash
# Navigate to source directory
cd csharp_app/csharp_rest/source

# Build the Docker image
docker build -t csharp-app -f Dockerfile .

# Or use the official Docker Hub image
docker pull magneka/learniken-csharp-app:latest
```

#### Run the Container

```bash
# Run with default configuration (port 80 internally, mapped to 8085 externally)
docker run -d -p 8085:80 --name csharp-rest-container magneka/learniken-csharp-app:latest

# With custom environment variables
docker run -d -p 8085:80 \
  --name csharp-rest-container \
  -e PORT=80 \
  -e APP_NAME="CSharp Minimal API" \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e ASPNETCORE_URLS=http://+:80 \
  -e DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
  magneka/learniken-csharp-app:latest
```

#### Using Scripts

Navigate to the Docker scripts directory:

```bash
cd csharp_app/csharp_rest/scripts/docker

# Start the container
./start-container.sh

# Stop the container
./stop-container.sh

# Remove the container
./remove-container.sh

# Restart the container (stop + rebuild + start)
./restart-container.sh
```

#### Manual Commands

```bash
# View running containers
docker ps

# View logs
docker logs csharp-rest-container

# Execute command in container
docker exec -it csharp-rest-container /bin/sh

# Stop container
docker stop csharp-rest-container

# Remove container
docker rm csharp-rest-container

# Remove image
docker rmi magneka/learniken-csharp-app:latest
```

---

### Using Docker Compose

#### Configuration

The `docker-compose.yml` file defines:

```yaml
services:
  csharp_rest:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: csharp-rest-api
    ports:
      - "8085:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ASPNETCORE_URLS=http://+:80
      - PORT=80
      - APP_NAME=CSharp Minimal API
      - DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    restart: unless-stopped
    networks:
      - csharp-network
```

#### Commands

```bash
# Navigate to source directory
cd csharp_app/csharp_rest/source

# Start services
docker compose up -d

# View service status
docker compose ps

# View logs
docker compose logs -f

# Stop services
docker compose down

# Stop and remove volumes
docker compose down -v
```

#### Using Scripts

Navigate to the Docker Compose scripts directory:

```bash
cd csharp_app/csharp_rest/scripts/compose

# Start containers
./start-container.sh

# Stop containers
./stop-container.sh

# Remove containers, networks, volumes, and images
./remove-container.sh

# Restart containers with fresh build
./restart-container.sh
```

---

## Kubernetes Deployment

### Prerequisites

1. **Docker Hub Image**: Ensure `magneka/learniken-csharp-app:latest` is available
2. **Kubernetes Cluster**: Docker Desktop Kubernetes or any K8s cluster
3. **kubectl**: Configured to access your cluster

### Deployment Configuration

The `kubernetes.yaml` file defines:

```yaml
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: learniken-csharp-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: csharp-app
  template:
    metadata:
      labels:
        app: csharp-app
    spec:
      containers:
      - name: csharp-app
        image: magneka/learniken-csharp-app:latest
        ports:
        - containerPort: 80
        env:
        - name: PORT
          value: "80"
        - name: APP_NAME
          value: "CSharp Minimal API"
        # Enter stuff here

# Service
apiVersion: v1
kind: Service
metadata:
  name: learniken-csharp-app-service
spec:
  type: LoadBalancer
  ports:
  - port: 8085
    targetPort: 80
  selector:
    app: csharp-app
```

### Exercise: Configure Health Probes

The `kubernetes.yaml` file in `source/` has no health probes. Replace the `# Enter stuff here` line with:

- a `readinessProbe` that calls `/readyz` on port 80
- a `livenessProbe` that calls `/healthz` on port 80

Choose your own delays, periods, timeouts and failure thresholds. Then deploy, send slow requests with `/slow?n=<value>`, and watch for restarts with `kubectl get pods -w` or the `watch-pod-restarts` script in the repository root.

### Using kubectl Directly

```bash
# Navigate to source directory
cd csharp_app/csharp_rest/source

# Deploy to Kubernetes
kubectl apply -f kubernetes.yaml

# Check deployment status
kubectl get deployments

# Check pods
kubectl get pods -l app=csharp-app

# Check service
kubectl get svc learniken-csharp-app-service

# View logs
kubectl logs -l app=csharp-app -f

# Delete deployment
kubectl delete -f kubernetes.yaml

# Port forwarding for local access
kubectl port-forward svc/learniken-csharp-app-service 8085:8085
```

### Using Scripts

Navigate to the Kubernetes scripts directory:

```bash
cd csharp_app/csharp_rest/scripts/k8s

# Build Docker image and push to Docker Hub
./build-container.sh

# Deploy to Kubernetes with port forwarding
./start-container.sh

# Scale deployment to 0 replicas (stop)
./stop-container.sh

# Delete all Kubernetes resources
./remove-container.sh

# Full rebuild and redeploy cycle
./restart-container.sh
```

#### Port Forwarding

The `start-container.sh` script automatically sets up port forwarding from localhost:8085 to the service. This allows you to access the application at `http://localhost:8085` even when running in Kubernetes.

---

## Scripts Reference

### Docker Scripts

**Location:** `csharp_app/csharp_rest/scripts/docker/`

| Script | Description | Usage |
|--------|-------------|-------|
| `start-container.sh` | Build and run container on port 8085 | `./start-container.sh` |
| `stop-container.sh` | Stop and remove running container | `./stop-container.sh` |
| `remove-container.sh` | Force remove container (running or stopped) | `./remove-container.sh` |
| `restart-container.sh` | Stop, remove, rebuild, and restart | `./restart-container.sh` |
| PowerShell versions | Same functionality with `.ps1` extensions | `./start-container.ps1` |

### Docker Compose Scripts

**Location:** `csharp_app/csharp_rest/scripts/compose/`

| Script | Description | Usage |
|--------|-------------|-------|
| `start-container.sh` | Start containers using docker compose | `./start-container.sh` |
| `stop-container.sh` | Stop containers | `./stop-container.sh` |
| `remove-container.sh` | Stop and remove containers, networks, volumes, images | `./remove-container.sh` |
| `restart-container.sh` | Rebuild and restart containers | `./restart-container.sh` |
| PowerShell versions | Same functionality with `.ps1` extensions | `./start-container.ps1` |

### Kubernetes Scripts

**Location:** `csharp_app/csharp_rest/scripts/k8s/`

| Script | Description | Usage |
|--------|-------------|-------|
| `build-container.sh` | Build Docker image, login, push to Docker Hub | `./build-container.sh` |
| `start-container.sh` | Apply Kubernetes manifests, wait for rollout, port-forward | `./start-container.sh` |
| `stop-container.sh` | Scale deployment to 0 replicas | `./stop-container.sh` |
| `remove-container.sh` | Delete all Kubernetes resources | `./remove-container.sh` |
| `restart-container.sh` | Remove, rebuild, push, deploy | `./restart-container.sh` |
| PowerShell versions | Same functionality with `.ps1` extensions | `./start-container.ps1` |

**Note:** Kubernetes scripts use `magneka/learniken-csharp-app:latest` image from Docker Hub.

---

## Testing

### Test Scripts

**Location:** `csharp_app/csharp_rest/scripts/test/`

#### Endpoint Testing

```bash
# Run comprehensive endpoint tests
./test_endpoints.sh

# Or with PowerShell
./test_endpoints.ps1
```

**Test Coverage:**
- Root endpoint (`/`)
- Healthz endpoint with all fields
- Readyz endpoint
- Slow endpoint (default and custom parameters)
- 404 handling for unknown endpoints
- Request counter increment

#### Load Testing

```bash
# Run load test with wrk (if installed)
./wrk-test.sh

# With custom parameters (duration, concurrency, threads)
./wrk-test.sh 60s 20 4

# Or with PowerShell
./wrk-test.ps1
```

### Manual Testing

```bash
# Test health endpoint
curl http://localhost:8085/healthz

# Test root endpoint
curl http://localhost:8085/

# Test readiness endpoint
curl http://localhost:8085/readyz

# Test slow endpoint
curl http://localhost:8085/slow?n=10

# Test unknown endpoint (404)
curl http://localhost:8085/unknown
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Client                                │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTP Request
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer                            │
│              (Kubernetes Service - port 8085)                │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                      Deployment                               │
│              (1 replica, labels: app=csharp-app)                │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                      Container                               │
│              (port 80, image: magneka/learniken-csharp-app)    │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                 ASP.NET Core Application                   ││
│  │  ┌───────────┐  ┌───────────┐  ┌───────────────────────┐ ││
│  │  │ /         │  │ /healthz   │  │ /readyz                 │ ││
│  │  └───────────┘  └───────────┘  └───────────────────────┘ ││
│  │  ┌───────────────────────┐  ┌───────────────────────┐ ││
│  │  │ /slow?n=<value>        │  │ 404 for unknown routes  │ ││
│  │  └───────────────────────┘  └───────────────────────┘ ││
│  └─────────────────────────────────────────────────────────┘│
│  Health Checks: Exercise - add readiness & liveness probes     │
│  Security: Non-root user, dropped capabilities, read-only FS   │
└─────────────────────────────────────────────────────────────┘
```

### Port Mapping

| Layer | Port | Protocol |
|-------|------|----------|
| Kubernetes Service | 8085 | TCP |
| Container | 80 | TCP |
| Application (Kestrel) | 80 | TCP (configurable via PORT env var) |

---

## Troubleshooting

### Common Issues

#### Image Pull Errors

**Problem:** `ImagePullBackOff` or `ErrImagePull` in Kubernetes

**Solution:**
```bash
# Ensure image exists on Docker Hub
docker pull magneka/learniken-csharp-app:latest

# Verify Docker Hub authentication
docker login

# Check image name in kubernetes.yaml matches Docker Hub
```

#### Container Won't Start

**Problem:** Container crashes immediately

**Debug:**
```bash
# View container logs
docker logs csharp-rest-container

# Or in Kubernetes
kubectl logs -l app=csharp-app

# Check build logs
kubectl describe pod <pod-name>
```

#### Port Already in Use

**Problem:** Port 8085 already in use

**Solution:**
```bash
# Find process using port 8085
lsof -i :8085

# Kill the process
kill <PID>

# Or use a different port
docker run -d -p 8085:80 --name csharp-rest-container magneka/learniken-csharp-app:latest
```

#### Docker Compose Health Check Fails

**Problem:** Health check fails during startup

**Solution:**
```bash
# Temporarily disable health check in docker-compose.yml
# Or increase start_period:
healthcheck:
  start_period: 30s
```

#### Kubernetes Resource Already Exists

**Problem:** `already exists` error when applying manifests

**Solution:**
```bash
# Delete existing resources first
kubectl delete -f kubernetes.yaml

# Then reapply
kubectl apply -f kubernetes.yaml
```

#### .NET Runtime Issues

**Problem:** Application fails to start in container

**Debug:**
```bash
# Check if .NET runtime is properly installed
docker exec -it csharp-rest-container dotnet --version

# Check published files
docker exec -it csharp-rest-container ls -la /app

# Check environment variables
docker exec -it csharp-rest-container printenv
```

### Useful Commands

```bash
# Docker
## List all containers (including stopped)
docker ps -a

## List all images
docker images

## Remove all unused containers, networks, images
docker system prune

## Inspect container
docker inspect csharp-rest-container

# Docker Compose
## List all services
docker compose ls

## View service logs
docker compose logs csharp_rest

## Build and start
docker compose up -d --build

# Kubernetes
## List all resources
kubectl get all

## List all pods
kubectl get pods -A

## Describe a pod
kubectl describe pod <pod-name>

## View pod logs
kubectl logs <pod-name>

## Delete all resources
kubectl delete all --all

## View resource usage
kubectl top pods

## Check events
kubectl get events --sort-by='.metadata.creationTimestamp'
```

---

## Quick Start Guide

### 1. Run Locally with Docker Compose

```bash
cd csharp_app/csharp_rest/source
docker compose up -d
# Access at http://localhost:8085
```

### 2. Run on Kubernetes

```bash
# Build and push image
cd csharp_app/csharp_rest/scripts/k8s
./build-container.sh

# Deploy to Kubernetes
./start-container.sh
# Access at http://localhost:8085
```

### 3. Test the Application

```bash
cd csharp_app/csharp_rest/scripts/test
./test_endpoints.sh
```

### 4. Clean Up

```bash
# Docker Compose
cd csharp_app/csharp_rest/source
docker compose down

# Docker
cd csharp_app/csharp_rest/scripts/docker
./remove-container.sh

# Kubernetes
cd csharp_app/csharp_rest/scripts/k8s
./remove-container.sh
```

---

## Testing Sequence

To test the application in the requested sequence:

### 1. Docker Testing

```bash
cd csharp_app/csharp_rest/scripts/docker

# Start Docker container
./start-container.sh

# Wait a few seconds for startup
sleep 5

# Test endpoints
cd ../test
./test_endpoints.sh

# Stop Docker container
cd ../docker
./stop-container.sh
```

### 2. Docker Compose Testing

```bash
cd csharp_app/csharp_rest/scripts/compose

# Start Docker Compose
./start-container.sh

# Wait a few seconds for startup
sleep 10

# Test endpoints
cd ../test
./test_endpoints.sh

# Stop Docker Compose
cd ../compose
./stop-container.sh
```

### 3. Kubernetes Testing

```bash
cd csharp_app/csharp_rest/scripts/k8s

# Build and push Docker image
./build-container.sh

# Deploy to Kubernetes
./start-container.sh

# Wait for deployment to be ready
sleep 15

# Test endpoints (from another terminal)
cd ../test
./test_endpoints.sh

# Stop Kubernetes deployment
cd ../k8s
./stop-container.sh

# Clean up
./remove-container.sh
```

---

## Best Practices

1. **Security**: Always run containers as non-root users
2. **Resource Limits**: Set appropriate CPU and memory limits in Kubernetes
3. **Health Checks**: Use readiness and liveness probes
4. **Logging**: Monitor container logs for issues
5. **Updates**: Regularly update base images for security patches
6. **Secrets**: Use Kubernetes secrets for sensitive data (not in this example)
7. **Configuration**: Use ConfigMaps for environment-specific settings

---

*Last updated: 2026-10-04*
*Maintainer: magneka (magne@alvheim.com)*
*Docker Hub: https://hub.docker.com/r/magneka/learniken-csharp-app*
*Source: /csharp_app/csharp_rest*