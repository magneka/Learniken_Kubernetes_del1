#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:8081}"
PAGE="$(curl --fail --silent --show-error --max-time 10 "$URL")"

if ! grep --fixed-strings --quiet "Hello from Nginx on Kubernetes!" <<<"$PAGE"; then
    echo "Verification failed: expected Nginx page content was not found." >&2
    exit 1
fi

echo "Verification passed: $URL returned the expected Nginx page."
