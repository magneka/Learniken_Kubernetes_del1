# Build stage - use official Go image
FROM golang:1.21-alpine AS builder

WORKDIR /usr/src/app

# Copy go.mod and go.sum first to leverage Docker cache
COPY src/go.mod ./
COPY src/go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY src/main.go ./

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o go-rest-app main.go

# Runtime stage - use a minimal base image
FROM alpine:3.18

RUN apk add --no-cache ca-certificates curl && \
    rm -rf /var/cache/apk/*

WORKDIR /usr/src/app

# Copy the compiled binary from the builder stage
COPY --from=builder /usr/src/app/go-rest-app ./

# Set the entrypoint
ENTRYPOINT ["./go-rest-app"]

# Expose the port the app runs on
EXPOSE 80

# Run as non-root user for security
RUN adduser -D appuser && \
    chown -R appuser:appuser /usr/src/app
USER appuser

# Set environment variables
ENV PORT=80