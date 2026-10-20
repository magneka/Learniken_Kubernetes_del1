#!/usr/bin/env bash
# Exit immediately if a command fails or an unset variable is used.
set -euo pipefail

# Watch this namespace; pass a different namespace as the first argument.
NAMESPACE="${1:-default}"

# Pass "watch" as the second argument to refresh every 5 seconds until Ctrl+C.
MODE="${2:-once}"

# Print the restart table and the probe events that explain it.
show_restarts() {
    echo "Cluster context: $(kubectl config current-context)"
    echo "Namespace:       ${NAMESPACE}"
    echo "Checked at:      $(date +%H:%M:%S)"
    echo

    # RESTARTS counts how many times the container was restarted.
    # The LAST-* columns describe the most recent restart, and stay empty
    # until a restart has actually happened.
    kubectl -n "${NAMESPACE}" get pods -o custom-columns=\
'NAME:.metadata.name,'\
'READY:.status.containerStatuses[*].ready,'\
'RESTARTS:.status.containerStatuses[*].restartCount,'\
'LAST-REASON:.status.containerStatuses[*].lastState.terminated.reason,'\
'LAST-EXIT:.status.containerStatuses[*].lastState.terminated.exitCode,'\
'LAST-RESTART:.status.containerStatuses[*].lastState.terminated.finishedAt,'\
'POD-AGE:.metadata.creationTimestamp'

    echo
    echo "Recent liveness and restart events:"

    # Field selectors cannot match message text, so filter the output instead.
    # grep must not end the script when it finds nothing, hence the "|| true".
    EVENTS="$(kubectl -n "${NAMESPACE}" get events \
        --field-selector involvedObject.kind=Pod \
        --sort-by=.lastTimestamp 2>/dev/null \
        | grep -iE 'liveness|readiness|restart|BackOff' | tail -10 || true)"

    if [ -z "${EVENTS}" ]; then
        echo "  (none yet - no probe failures or restarts recorded)"
    else
        echo "${EVENTS}" | sed 's/^/  /'
    fi

    echo
    echo "Exit code 137 means Kubernetes killed the container after the"
    echo "liveness probe failed. LAST-RESTART is when the old container died."
}

if [ "${MODE}" = "watch" ]; then
    # Repeat until the user presses Ctrl+C.
    # Clearing fails when there is no terminal, so never abort on it.
    while true; do
        clear 2>/dev/null || true
        show_restarts
        sleep 5
    done
else
    show_restarts
fi
