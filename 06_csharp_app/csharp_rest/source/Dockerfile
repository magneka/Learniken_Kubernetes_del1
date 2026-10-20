# Dockerfile for C# .NET Core 11 Minimal API
# Multi-stage build for optimal image size

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:11.0 AS build
WORKDIR /src

# Copy project files and restore dependencies
COPY ["CSharpMinimalApi.csproj", "."]
RUN dotnet restore "CSharpMinimalApi.csproj"

# Copy everything else and build
COPY . .
RUN dotnet publish "CSharpMinimalApi.csproj" -c Release -o /app/publish \
    --no-restore \
    -p:PublishTrimmed=false \
    -p:PublishReadyToRun=true \
    -p:PublishSingleFile=false

# Runtime stage - using Debian-based image for better compatibility
FROM mcr.microsoft.com/dotnet/aspnet:11.0 AS runtime
WORKDIR /app

# Create non-root user for security
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Copy published app from build stage
COPY --from=build --chown=appuser:appgroup /app/publish .

# Set environment variables
ENV ASPNETCORE_URLS=http://+:80
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
ENV PORT=80
ENV APP_NAME="CSharp Minimal API"

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 80

# Set health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/healthz || exit 1

# Entrypoint
ENTRYPOINT ["dotnet", "CSharpMinimalApi.dll"]