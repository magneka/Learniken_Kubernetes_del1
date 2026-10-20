#!/usr/bin/env bash
# Exit immediately if a command fails or an unset variable is used.
set -euo pipefail

# List this namespace; pass a different namespace as the first argument.
# Pass "all" to list pods in every namespace.
NAMESPACE="${1:-default}"

# Show the target so you always know which cluster you are looking at.
echo "Cluster context: $(kubectl config current-context)"

# Choose between a single namespace and the whole cluster.
if [ "${NAMESPACE}" = "all" ] || [ "${NAMESPACE}" = "-A" ]; then
    echo "Namespace:       all namespaces"
    SCOPE=(--all-namespaces)
else
    echo "Namespace:       ${NAMESPACE}"
    SCOPE=(-n "${NAMESPACE}")
fi
echo

# The AGE column shows how long each pod has been running.
# Oldest pods are listed last because they sort by creation time.
kubectl get pods "${SCOPE[@]}" -o wide --sort-by=.metadata.creationTimestamp

echo
echo "AGE shows how long the pod has existed. RESTARTS above 0 means the"
echo "container was restarted, so it may be running for less time than AGE."
