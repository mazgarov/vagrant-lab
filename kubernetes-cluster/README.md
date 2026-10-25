
# Kubernetes Cluster Lab

## Overview

This lab uses Vagrant and the libvirt provider to provision a five-node Kubernetes learning environment on Ubuntu 24.04.

The cluster consists of one control-plane node and four worker nodes. Vagrant automates operating-system preparation and installation of Docker, Zabbix Agent 2, containerd, and the Kubernetes command-line components.

Cluster initialization and worker joining are performed by separate scripts so these steps can be studied and executed independently.

## Architecture

| Node | Role | Private IP |
|---|---|---|
| `k8s-master` | Control plane | `192.168.100.11` |
| `k8s-worker1` | Worker | `192.168.100.12` |
| `k8s-worker2` | Worker | `192.168.100.13` |
| `k8s-worker3` | Worker | `192.168.100.14` |
| `k8s-worker4` | Worker | `192.168.100.15` |

Each VM is configured with:

- Ubuntu 24.04 LTS
- 2 virtual CPUs
- 2 GB RAM
- An 80 GB virtual disk
- Docker Engine and Docker Compose plugin
- Zabbix Agent 2
- containerd
- Kubernetes v1.36 packages

The Vagrant/libvirt management network is separate from the private cluster network used for node-to-node communication.

## Repository contents

| File | Purpose |
|---|---|
| `Vagrantfile` | Defines the five VMs and provisions their operating systems and Kubernetes prerequisites |
| `scripts/setup-master-k8s.sh` | Initializes the Kubernetes control plane and installs Flannel |
| `scripts/join-workers-k8s.sh` | Generates a fresh join command, joins worker nodes, and checks node readiness |

## Prerequisites

- Vagrant
- The Vagrant libvirt provider/plugin
- A working libvirt/KVM environment
- Network access from the VMs to the Ubuntu, Docker, Zabbix, and Kubernetes package repositories
- Sufficient host resources to run five VMs simultaneously
- A reachable Zabbix server or proxy if monitoring is required

## Before provisioning

### 1. Review the network configuration

The private cluster network uses `192.168.100.0/24`.

Check that this subnet does not overlap with any existing network on your host or infrastructure.

The control-plane setup script expects `eth1` to have the address `192.168.100.11/24`. The worker join commands use the API server address `192.168.100.11:6443`.

The Vagrantfile also retains commented-out LAN experiment settings. They are disabled by default.

### 2. Configure the Zabbix server or proxy

The Vagrantfile defines a `ZABBIX_SERVER` value. Review it and configure the address of the Zabbix server or proxy reachable from the VMs.

Each agent uses the VM hostname as its Zabbix `Hostname` and uses a per-VM PSK identity derived from that hostname.

Configure the corresponding hosts and PSK encryption settings in the Zabbix frontend.

Never commit PSK secrets, private keys, passwords, or tokens to GitHub.

### 3. Understand the container runtime

The Vagrantfile installs Docker Engine and configures containerd for Kubernetes.

Kubernetes uses containerd through its CRI interface. The provisioning script checks that the containerd CRI runtime plugin is healthy.

### 4. Understand the Kubernetes network

The master setup script initializes the cluster with the pod CIDR `10.244.0.0/16` and installs Flannel.

Flannel is configured to use `eth1`, the private cluster interface.

## Setup procedure

Run the following commands from this directory.

### Step 1 — Provision the five VMs

```bash
vagrant up
```

Check the VM states:

```bash
vagrant status
```

### Step 2 — Verify the installed components

Check the Kubernetes package versions on the master:

```bash
vagrant ssh k8s-master
```

Inside the VM:

```bash
kubeadm version
kubectl version --client
kubelet --version
containerd --version
```

Exit the VM when finished:

```bash
exit
```

### Step 3 — Initialize the control plane

Run the setup script as the regular `vagrant` user inside the master VM:

```bash
vagrant ssh k8s-master
bash /vagrant/scripts/setup-master-k8s.sh
```

The script initializes the control plane, configures `kubectl` for the current user, installs Flannel, and waits for the Flannel DaemonSet rollout.

Verify the master:

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

### Step 4 — Join the worker nodes

From the host, run:

```bash
bash ./scripts/join-workers-k8s.sh
```

The script obtains a fresh join command from the master, joins workers that have not already been configured, waits for all nodes to become Ready, and prints the final node status.

### Step 5 — Verify the cluster

Connect to the master:

```bash
vagrant ssh k8s-master
```

Check the nodes:

```bash
kubectl get nodes -o wide
```

Check the system pods:

```bash
kubectl get pods -A -o wide
```

All five nodes should report `Ready`. Flannel should be running on every node, and the CoreDNS pods should reach `Running`.

## Useful commands

### Check VM status

```bash
vagrant status
```

### Re-run Vagrant provisioning

```bash
vagrant provision
```

### Stop the VMs

```bash
vagrant halt
```

### Destroy the VMs

```bash
vagrant destroy
```

**Warning:** Destroying the VMs removes their virtual disks and the data stored on them. Back up anything you want to keep before confirming the operation.

## Notes

- The Vagrantfile installs Kubernetes packages and prepares the operating systems. It does not automatically initialize the control plane or join workers.
- The control-plane setup and worker-join steps are intentionally separate.
- The Kubernetes repository is configured for the v1.36 package stream.
- The setup scripts assume the private interface is `eth1` and the private cluster addresses match the values documented above.
- The worker-join script skips a worker if `/etc/kubernetes/kubelet.conf` already exists. If a previous join attempt failed, inspect that worker before retrying.
- The lab is intended for learning and experimentation, not as a production-ready cluster configuration.
