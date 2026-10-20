# Build stage
FROM rust:1.81.0-slim AS builder

WORKDIR /usr/src/app

# Copy Cargo.toml and Cargo.lock first to leverage Docker cache
COPY Cargo.toml ./
COPY Cargo.lock ./

# Add a placeholder main so cargo can read the manifest before the real source exists
RUN mkdir -p src && echo "fn main() {}" > src/main.rs

# Download dependencies
RUN cargo fetch

# Copy source code, replacing the placeholder
COPY src/ ./src/

# Build the application in release mode
RUN cargo build --release

# Runtime stage - use a minimal base image
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# Copy the compiled binary from the builder stage
COPY --from=builder /usr/src/app/target/release/rust_rest ./

# Set the entrypoint
ENTRYPOINT ["./rust_rest"]

# Expose the port the app runs on
EXPOSE 80

# Run as non-root user for security
RUN useradd -m appuser && \
    chown -R appuser:appuser /usr/src/app
USER appuser

# Set environment variables
ENV PORT=80
ENV RUST_BACKTRACE=1