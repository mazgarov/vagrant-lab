#!/usr/bin/env bash
# Set up the Kubernetes control plane on k8s-master.
# Run as the regular "vagrant" user, not as root:
#   bash scripts/setup-master-k8s.sh
#
# Assumptions:
# - Kubernetes packages and containerd are already provisioned by Vagrant.
# - The master's private interface is eth1 with address 192.168.100.11.
# - Kubernetes packages are from the v1.36 repository.
# - Pod CIDR is 10.244.0.0/16, used by the Flannel manifest.

set -Eeuo pipefail

MASTER_IP="192.168.100.11"
POD_CIDR="10.244.0.0/16"
CRI_SOCKET="unix:///run/containerd/containerd.sock"
FLANNEL_MANIFEST="https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"

log() {
  printf '\n[%s] %s\n' "$(date '+%F %T')" "$*"
}

die() {
  printf '\nERROR: %s\n' "$*" >&2
  exit 1
}

[[ "${EUID}" -ne 0 ]] || die "Run this script as the regular vagrant user, without sudo."

command -v kubeadm >/dev/null 2>&1 || die "kubeadm is not installed. Fix Vagrant provisioning first."
command -v kubectl >/dev/null 2>&1 || die "kubectl is not installed. Fix Vagrant provisioning first."
command -v containerd >/dev/null 2>&1 || die "containerd is not installed."
ip -4 -o addr show dev eth1 | grep -Fq "${MASTER_IP}/24" \
  || die "Expected ${MASTER_IP}/24 on eth1, but it was not found."

log "Configure kubelet to register the master on the private network"
echo "KUBELET_EXTRA_ARGS=--node-ip=${MASTER_IP}" | sudo tee /etc/default/kubelet >/dev/null
sudo systemctl enable containerd
sudo systemctl restart containerd
sudo systemctl enable kubelet

if [[ ! -s /etc/kubernetes/admin.conf ]]; then
  log "Initialize Kubernetes control plane"
  sudo kubeadm init \
    --apiserver-advertise-address="${MASTER_IP}" \
    --pod-network-cidr="${POD_CIDR}" \
    --cri-socket="${CRI_SOCKET}"
else
  log "Existing Kubernetes admin.conf found; skipping kubeadm init"
fi

log "Configure kubectl for the current user"
mkdir -p "${HOME}/.kube"
sudo cp /etc/kubernetes/admin.conf "${HOME}/.kube/config"
sudo chown "$(id -u):$(id -g)" "${HOME}/.kube/config"
chmod 600 "${HOME}/.kube/config"
export KUBECONFIG="${HOME}/.kube/config"

log "Install Flannel"
kubectl apply -f "${FLANNEL_MANIFEST}"

log "Ensure Flannel uses eth1 (the private node network)"
FLANNEL_ARGS="$(kubectl -n kube-flannel get daemonset kube-flannel-ds \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="kube-flannel")].args[*]}')"
if [[ " ${FLANNEL_ARGS} " != *" --iface=eth1 "* ]]; then
  kubectl -n kube-flannel patch daemonset kube-flannel-ds \
    --type='json' \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--iface=eth1"}]'
else
  log "Flannel already has --iface=eth1; no patch needed"
fi

log "Wait for Flannel rollout"
kubectl -n kube-flannel rollout status daemonset/kube-flannel-ds --timeout=180s

log "Current node and system pod status"
kubectl get nodes -o wide
kubectl get pods -A

log "Master setup script completed"
printf '\nTo create a fresh worker join command, run on this master:\n'
printf '  sudo kubeadm token create --print-join-command\n'