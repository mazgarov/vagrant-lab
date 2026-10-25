#!/usr/bin/env bash
set -Eeuo pipefail

# Join the worker VMs to the Kubernetes cluster.
# Run this script from the directory containing the Vagrantfile.

MASTER="k8s-master"

WORKERS=(
    "k8s-worker1"
    "k8s-worker2"
    "k8s-worker3"
    "k8s-worker4"
)

log() {
    printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

# Make sure this script is run from the Vagrant project directory.
if [[ ! -f "Vagrantfile" ]]; then
    echo "ERROR: Vagrantfile not found."
    echo "Run this script from ~/vagrant-lab/ubuntu-docker."
    exit 1
fi

# Verify that the master VM is running.
if ! vagrant status "$MASTER" --machine-readable |
    grep -q ',state,running$'; then
    echo "ERROR: $MASTER is not running."
    exit 1
fi

# Verify that all worker VMs are running before changing the cluster.
for worker in "${WORKERS[@]}"; do
    if ! vagrant status "$worker" --machine-readable |
        grep -q ',state,running$'; then
        echo "ERROR: $worker is not running."
        exit 1
    fi
done

# Generate a fresh join command on the master.
log "Generate a fresh Kubernetes join command"

JOIN_COMMAND="$(
    vagrant ssh "$MASTER" -c \
        'sudo kubeadm token create --print-join-command'
)"

JOIN_COMMAND="$(printf '%s\n' "$JOIN_COMMAND" | tail -n 1)"

if [[ "$JOIN_COMMAND" != kubeadm\ join\ * ]]; then
    echo "ERROR: Could not obtain a valid kubeadm join command."
    echo "Check the master and its kubeadm configuration."
    exit 1
fi

# Join each worker unless it has already been configured as a cluster node.
for worker in "${WORKERS[@]}"; do
    log "Check $worker"

    if vagrant ssh "$worker" -c \
        'sudo test -f /etc/kubernetes/kubelet.conf' \
        >/dev/null 2>&1; then
        log "$worker already has kubelet.conf; skipping join"
        continue
    fi

    log "Joining $worker to the Kubernetes cluster"

    # Split the generated command into its expected components.
    # Normalize whitespace before parsing the join command.
    JOIN_COMMAND="$(printf '%s' "$JOIN_COMMAND" | xargs)"

    read -r JOIN_WORD JOIN_SUBCOMMAND API_ENDPOINT TOKEN_FLAG TOKEN HASH_FLAG CA_HASH \
        <<< "$JOIN_COMMAND"

    if [[ "$JOIN_WORD" != "kubeadm" ||
          "$JOIN_SUBCOMMAND" != "join" ||
          "$TOKEN_FLAG" != "--token" ||
          "$HASH_FLAG" != "--discovery-token-ca-cert-hash" ||
          -z "$API_ENDPOINT" || -z "$TOKEN" || -z "$CA_HASH" ]]; then
        echo "ERROR: The generated kubeadm join command has an unexpected format."
        exit 1
    fi
    
    # Validate the SHA-256 hash format before joining.
    if [[ ! "$CA_HASH" =~ ^sha256:[[:xdigit:]]{64}$ ]]; then
        echo "ERROR: Invalid CA certificate hash: [$CA_HASH]"
        exit 1
    fi

    # Pass a single, correctly quoted command to the remote worker.
    REMOTE_JOIN_COMMAND="sudo kubeadm join '$API_ENDPOINT' --token '$TOKEN' --discovery-token-ca-cert-hash '$CA_HASH'"
    
    if ! vagrant ssh "$worker" -c "$REMOTE_JOIN_COMMAND"; then
        echo "ERROR: Failed to join $worker."
        echo "Inspect the worker before retrying."
        exit 1
    fi

    log "$worker joined successfully"
done

# Wait for all five nodes to report Ready.
log "Wait for all Kubernetes nodes to become Ready"

if ! vagrant ssh "$MASTER" -c \
    'kubectl wait --for=condition=Ready nodes --all --timeout=180s'; then
    echo "ERROR: Not all nodes became Ready within 180 seconds."
    vagrant ssh "$MASTER" -c 'kubectl get nodes -o wide'
    exit 1
fi

# Display the final cluster state.
log "Final Kubernetes node status"
vagrant ssh "$MASTER" -c 'kubectl get nodes -o wide'

log "Worker join process completed"