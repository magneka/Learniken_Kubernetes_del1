# Build stage
FROM maven:3.9.6-eclipse-temurin-17 as builder

WORKDIR /usr/src/app

# Copy pom.xml and download dependencies
COPY app/pom.xml ./
RUN mvn dependency:go-offline -B

# Copy source code
COPY app/src/ ./src/

# Build the application
RUN mvn package -DskipTests -B

# Runtime stage - use a minimal base image
FROM eclipse-temurin:17-jre-jammy

RUN apt-get update && apt-get install -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# Copy the compiled JAR from the builder stage
COPY --from=builder /usr/src/app/target/spring-rest-0.1.0.jar ./spring-rest.jar

# Set the entrypoint
ENTRYPOINT ["java", "-jar", "spring-rest.jar"]

# Expose the port the app runs on
EXPOSE 80

# Run as non-root user for security
RUN useradd -m appuser && \
    chown -R appuser:appuser /usr/src/app
USER appuser

# Set environment variables
ENV PORT=80