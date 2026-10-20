# Spring Boot REST API - Containerization and Kubernetes Deployment

This document provides comprehensive documentation for the Spring Boot REST API application, including containerization, deployment scripts, and Kubernetes configuration.

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

A minimal Spring Boot HTTP server application designed for containerization and Kubernetes deployment. The application provides REST endpoints for health monitoring and request processing, mirroring the functionality of the Rust REST API.

**Repository Structure:**
```
java_spring_boot/spring_rest/
├── source/                      # Application source code
│   ├── src/
│   │   ├── main/java/com/learniken/springrest/
│   │   │   ├── SpringRestApplication.java  # Main application class
│   │   │   ├── RequestCounter.java           # Request counting utility
│   │   │   └── controller/
│   │   │       └── HealthController.java     # REST controller with endpoints
│   │   └── resources/
│   │       └── application.properties         # Spring configuration
│   ├── pom.xml                 # Maven project configuration
│   ├── Dockerfile             # Docker image build instructions
│   ├── docker-compose.yml     # Docker Compose configuration
│   └── kubernetes.yaml        # Kubernetes deployment manifests
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
    
    └── test/                   # Test and validation scripts
        ├── test_endpoints.sh
        ├── test_endpoints.ps1
        ├── wrk-test.sh
        └── wrk-test.ps1
```

---

## Application Details

### Source Code

The application is located in `/java_spring_boot/spring_rest/source/`:

- **`SpringRestApplication.java`**: Main Spring Boot application class
- **`RequestCounter.java`**: Thread-safe request counter using AtomicLong
- **`HealthController.java`**: REST controller implementing all endpoints
- **`pom.xml`**: Defines project dependencies (Spring Boot Web, Actuator)
- **Port Configuration**: Defaults to port 80 (configurable via `PORT` environment variable)

### Endpoints

| Endpoint | Method | Description | Response Format |
|----------|--------|-------------|----------------|
| `/` | GET | Root endpoint | Plain text greeting |
| `/healthz` | GET | Health check | JSON with status, timestamp, request count, delay |
| `/readyz` | GET | Readiness check | JSON with status |
| `/slow?n=<value>` | GET | Simulates delay | Text with request # and delay info |
| `*` | GET | Unknown routes | HTTP 404 Not Found |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 80 | Internal container port |

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose | Download |
|------|---------|---------|----------|
| Docker | 24.0+ | Container runtime | https://www.docker.com |
| Docker Compose | 2.20+ | Multi-container orchestration | Included with Docker Desktop |
| kubectl | 1.28+ | Kubernetes CLI | https://kubernetes.io/docs/tasks/tools/ |
| Kubernetes | 1.25+ | Container orchestration | Docker Desktop includes local cluster |
| Java JDK | 17+ | For local development (optional) | https://adoptium.net |
| Maven | 3.9+ | For local builds (optional) | https://maven.apache.org |
| curl | Any | HTTP client for testing | Built-in on most systems |

### Docker Desktop Configuration

For local Kubernetes testing, Docker Desktop provides a built-in single-node Kubernetes cluster:

1. Install Docker Desktop
2. Enable Kubernetes in Docker Desktop settings:
   - Open Docker Desktop
   - Go to Settings → Kubernetes
   - Check "Enable Kubernetes"
   - Click "Apply & Restart"

---

## Docker Hub Account

### Account Information

| Detail | Value |
|--------|-------|
| **Username** | magneka |
| **Repository** | learniken-spring-app |
| **Image Tag** | latest |
| **Full Image Name** | `docker.io/magneka/learniken-spring-app:latest` |
| **Access** | Public |

### Authentication

To push new images to Docker Hub:

```bash
# Login to Docker Hub
docker login
# Username: magneka
# Password: [your password]

# Verify authentication
docker pull magneka/learniken-spring-app:latest
```

### Image Information

| Detail | Value |
|--------|-------|
| **Base Image** | eclipse-temurin:17-jre-alpine |
| **Build Image** | maven:3.9.6-eclipse-temurin-17-alpine |
| **Architecture** | Multi-platform (arm64, amd64) |
| **Size** | ~120MB |
| **User** | Runs as non-root user (appuser) |

---

## Local Development

### Using Docker

#### Build the Image

```bash
# Navigate to source directory
cd java_spring_boot/spring_rest/source

# Build the Docker image
docker build -t spring-app -f Dockerfile .

# Or use the official Docker Hub image
docker pull magneka/learniken-spring-app:latest
```

#### Run the Container

```bash
# Run with default configuration (port 80 internally)
docker run -d -p 8087:80 --name spring-app-container spring-app

# Or using the Docker Hub image
docker run -d -p 8087:80 --name spring-app-container magneka/learniken-spring-app:latest

# With custom environment variables
docker run -d -p 8087:80 \
  --name spring-app-container \
  -e PORT=80 \
  magneka/learniken-spring-app:latest
```

#### Using Scripts

Navigate to the Docker scripts directory:

```bash
cd java_spring_boot/spring_rest/scripts/docker

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
docker logs spring-app-container

# Execute command in container
docker exec -it spring-app-container /bin/sh

# Stop container
docker stop spring-app-container

# Remove container
docker rm spring-app-container

# Remove image
docker rmi magneka/learniken-spring-app:latest
```

---

### Using Docker Compose

#### Configuration

The `docker-compose.yml` file defines:

```yaml
services:
  spring_rest:
    build: .
    container_name: spring-rest-api
    ports:
      - "8087:80"
    environment:
      - PORT=80
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    restart: unless-stopped
```

#### Commands

```bash
# Navigate to source directory
cd java_spring_boot/spring_rest/source

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
cd java_spring_boot/spring_rest/scripts/compose

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

1. **Docker Hub Image**: Ensure `magneka/learniken-spring-app:latest` is available
2. **Kubernetes Cluster**: Docker Desktop Kubernetes or any K8s cluster
3. **kubectl**: Configured to access your cluster

### Deployment Configuration

The `kubernetes.yaml` file defines a Deployment and Service:

```yaml
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: learniken-spring-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: spring-app
  template:
    metadata:
      labels:
        app: spring-app
    spec:
      containers:
      - name: spring-app
        image: magneka/learniken-spring-app:latest
        ports:
        - containerPort: 80
        env:
        - name: PORT
          value: "80"
        # Enter stuff here

# Service with LoadBalancer
apiVersion: v1
kind: Service
metadata:
  name: learniken-spring-app-service
spec:
  type: LoadBalancer
  ports:
  - port: 8087
    targetPort: 80
  selector:
    app: spring-app
```

### Exercise: Configure Health Probes

The `kubernetes.yaml` file in `source/` has no health probes. Replace the `# Enter stuff here` line with:

- a `readinessProbe` that calls `/readyz` on port 80
- a `livenessProbe` that calls `/healthz` on port 80

Choose your own delays, periods, timeouts and failure thresholds. Then deploy, send slow requests with `/slow?n=<value>`, and watch for restarts with `kubectl get pods -w` or the `watch-pod-restarts` script in the repository root.

### Using kubectl Directly

```bash
# Navigate to source directory
cd java_spring_boot/spring_rest/source

# Deploy to Kubernetes
kubectl apply -f kubernetes.yaml

# Check deployment status
kubectl get deployments

# Check pods
kubectl get pods -l app=spring-app

# Check service
kubectl get svc learniken-spring-app-service

# View logs
kubectl logs -l app=spring-app -f

# Delete deployment
kubectl delete -f kubernetes.yaml

# Port forwarding for local access
kubectl port-forward svc/learniken-spring-app-service 8087:8087
```

### Using Scripts

Navigate to the Kubernetes scripts directory:

```bash
cd java_spring_boot/spring_rest/scripts/k8s

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

The `start-container.sh` script automatically sets up port forwarding from localhost:8087 to the service. This allows you to access the application at `http://localhost:8087` even when running in Kubernetes.

---

## Scripts Reference

### Docker Scripts

**Location:** `java_spring_boot/spring_rest/scripts/docker/`

| Script | Description | Usage |
|--------|-------------|-------|
| `start-container.sh` | Build Docker image and run container on port 8087 | `./start-container.sh` |
| `stop-container.sh` | Stop and remove running container | `./stop-container.sh` |
| `remove-container.sh` | Force remove container (running or stopped) | `./remove-container.sh` |
| `restart-container.sh` | Stop, remove, rebuild, and restart | `./restart-container.sh` |

**PowerShell Versions:** Same functionality with `.ps1` extensions

### Docker Compose Scripts

**Location:** `java_spring_boot/spring_rest/scripts/compose/`

| Script | Description | Usage |
|--------|-------------|-------|
| `start-container.sh` | Start containers using docker compose | `./start-container.sh` |
| `stop-container.sh` | Stop containers | `./stop-container.sh` |
| `remove-container.sh` | Stop and remove containers, networks, volumes, images | `./remove-container.sh` |
| `restart-container.sh` | Rebuild and restart containers | `./restart-container.sh` |

**PowerShell Versions:** Same functionality with `.ps1` extensions

### Kubernetes Scripts

**Location:** `java_spring_boot/spring_rest/scripts/k8s/`

| Script | Description | Usage |
|--------|-------------|-------|
| `build-container.sh` | Build Docker image, login, push to Docker Hub | `./build-container.sh` |
| `start-container.sh` | Apply Kubernetes manifests, wait for rollout, port-forward | `./start-container.sh` |
| `stop-container.sh` | Scale deployment to 0 replicas | `./stop-container.sh` |
| `remove-container.sh` | Delete all Kubernetes resources | `./remove-container.sh` |
| `restart-container.sh` | Remove, rebuild, push, deploy | `./restart-container.sh` |

**PowerShell Versions:** Same functionality with `.ps1` extensions

**Note:** Kubernetes scripts use `magneka/learniken-spring-app:latest` image from Docker Hub.

---

## Testing

### Test Scripts

**Location:** `java_spring_boot/spring_rest/scripts/test/`

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

# Or with PowerShell
./wrk-test.ps1
```

### Manual Testing

```bash
# Test health endpoint
curl http://localhost:8087/healthz

# Test root endpoint
curl http://localhost:8087/

# Test readiness endpoint
curl http://localhost:8087/readyz

# Test slow endpoint
curl http://localhost:8087/slow?n=10
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Client                                │
└─────────────────────────────────────────────────────────────┘
                      │ HTTP Request
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer                            │
│              (Kubernetes Service - port 8087)                │
└─────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                      Deployment                               │
│              (1 replica, labels: app=spring-app)                │
└─────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                      Container                               │
│              (port 80, image: magneka/learniken-spring-app)     │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                Spring Boot Application                   ││
│  │  ┌───────────┐  ┌───────────┐  ┌───────────────────────┐ ││
│  │  │ /         │  │ /healthz   │  │ /readyz                 │ ││
│  │  └───────────┘  └───────────┘  └───────────────────────┘ ││
│  │  ┌───────────────────────┐  ┌───────────────────────┐ ││
│  │  │ /slow?n=<value>        │  │ 404 for unknown routes  │ ││
│  │  └───────────────────────┘  └───────────────────────┘ ││
│  └─────────────────────────────────────────────────────────┘│
│  Health Checks: Exercise - add readiness & liveness probes     │
└─────────────────────────────────────────────────────────────┘
```

### Port Mapping

| Layer | Port | Protocol |
|-------|------|----------|
| Kubernetes Service | 8087 | TCP |
| Container | 80 | TCP |
| Application | 80 | TCP (configurable via PORT env var) |

---

## Troubleshooting

### Common Issues

#### Image Pull Errors

**Problem:** `ImagePullBackOff` or `ErrImagePull` in Kubernetes

**Solution:**
```bash
# Ensure image exists on Docker Hub
docker pull magneka/learniken-spring-app:latest

# Verify Docker Hub authentication
docker login

# Check image name in kubernetes.yaml matches Docker Hub
```

#### Container Won't Start

**Problem:** Container crashes immediately

**Debug:**
```bash
# View container logs
docker logs spring-app-container

# Or in Kubernetes
kubectl logs -l app=spring-app

# Check build logs
kubectl describe pod <pod-name>
```

#### Port Already in Use

**Problem:** Port 8087 already in use

**Solution:**
```bash
# Find process using port 8087
lsof -i :8087

# Kill the process
kill <PID>

# Or use a different port
docker run -d -p 8087:80 --name spring-app-container magneka/learniken-spring-app:latest
```

#### Docker Compose Health Check Fails

**Problem:** Health check fails during startup

**Solution:**
```yaml
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

### Useful Commands

```bash
# Docker
## List all containers (including stopped)
docker ps -a

## List all images
docker images

## Remove all unused containers, networks, images
docker system prune

# Docker Compose
## List all services
docker compose ls

## View service logs
docker compose logs <service-name>

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
```

---

## Quick Start Guide

### 1. Run Locally with Docker Compose

```bash
cd java_spring_boot/spring_rest/source
docker compose up -d
# Access at http://localhost:8087
```

### 2. Run on Kubernetes

```bash
# Build and push image
cd java_spring_boot/spring_rest/scripts/k8s
./build-container.sh

# Deploy to Kubernetes
./start-container.sh
# Access at http://localhost:8087
```

### 3. Test the Application

```bash
cd java_spring_boot/spring_rest/scripts/test
./test_endpoints.sh
```

### 4. Clean Up

```bash
# Docker Compose
cd java_spring_boot/spring_rest/source
docker compose down

# Kubernetes
cd java_spring_boot/spring_rest/scripts/k8s
./remove-container.sh
```

---

*Last updated: 2026-10-04*
*Maintainer: magneka (magne@alvheim.com)*
*Docker Hub: https://hub.docker.com/r/magneka/learniken-spring-app*
