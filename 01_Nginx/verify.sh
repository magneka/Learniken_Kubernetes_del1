#!/usr/bin/env bash
# Exit immediately if a command fails or an unset variable is used.
set -euo pipefail

# Allow a different URL when the port-forward uses another local port.
URL="${1:-http://localhost:8080}"

# Fetch the page and fail if curl cannot connect or receives a non-2xx response.
PAGE="$(curl --fail --silent --show-error --max-time 10 "$URL")"

# Confirm that the expected page, rather than an unrelated web server, responded.
if ! grep --fixed-strings --quiet "Hello from Nginx on Kubernetes!" <<<"$PAGE"; then
    echo "Verification failed: expected Nginx page content was not found." >&2
    exit 1
fi

echo "Verification passed: $URL returned the expected Nginx page."
