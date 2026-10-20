#!/usr/bin/env bash
# Exit immediately if a command fails or an unset variable is used.
set -euo pipefail

# Clean this namespace; pass a different namespace as the first argument.
NAMESPACE="${1:-default}"

# Show the target so you never delete pods in the wrong cluster by accident.
echo "Cluster context: $(kubectl config current-context)"
echo "Namespace:       ${NAMESPACE}"
echo

# List the pods that are about to be removed.
kubectl -n "${NAMESPACE}" get pods

# Ask before deleting, because this cannot be undone. FORCE=1 skips the question.
if [ "${FORCE:-0}" != "1" ]; then
    read -r -p "Permanently delete these pods? Type yes to continue: " ANSWER
    if [ "${ANSWER}" != "yes" ]; then
        echo "Cancelled. Nothing was deleted."
        exit 1
    fi
fi

# Delete the controllers first; otherwise they immediately recreate their pods.
kubectl -n "${NAMESPACE}" delete deployments,statefulsets,daemonsets,replicasets,jobs,cronjobs --all --ignore-not-found

# Delete any remaining pods that were created without a controller.
kubectl -n "${NAMESPACE}" delete pods --all --ignore-not-found

echo "All pods removed from namespace ${NAMESPACE}. Nothing will restart."
