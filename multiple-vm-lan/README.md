
# Multiple VM LAN Lab — Docker and Zabbix

## Overview

This lab uses Vagrant and the libvirt provider to provision five Ubuntu 24.04 virtual machines. Each VM is configured with Docker Engine, Docker Compose, and Zabbix Agent 2.

The lab includes a private network for communication between the VMs and a temporary LAN networking experiment using macvtap in direct mode.

**Important:** This configuration prepares the operating systems and networking. It does not install or initialize Kubernetes.

## Virtual machines

| VM name | Private cluster IP | LAN IP |
|---|---|---|
| `k8s-master` | `192.168.100.11` | `172.16.3.81` |
| `k8s-worker1` | `192.168.100.12` | `172.16.3.82` |
| `k8s-worker2` | `192.168.100.13` | `172.16.3.83` |
| `k8s-worker3` | `192.168.100.14` | `172.16.3.84` |
| `k8s-worker4` | `192.168.100.15` | `172.16.3.85` |

Each VM is configured with:

- Ubuntu 24.04 LTS using `bento/ubuntu-24.04`
- Pinned box version `202508.03.0`
- 2 virtual CPUs
- 2 GB RAM
- An 80 GB virtual disk

## Prerequisites

- Vagrant
- The Vagrant libvirt provider/plugin
- A working libvirt/KVM environment
- Network access from the guest VMs to the Ubuntu, Docker, and Zabbix repositories
- A Zabbix server or proxy reachable from the VMs, if monitoring is required
- A compatible physical network interface on the libvirt host for the LAN experiment

## Before provisioning

Review these settings carefully before running `vagrant up`.

### 1. Private cluster network

The private network uses `192.168.100.0/24`.

Check that this subnet does not overlap with any existing network on your host or infrastructure.

### 2. LAN addresses and interface

The temporary LAN configuration uses:

- Interface: `ens18`
- Networking mode: bridge mode with direct/macvtap networking
- Netmask: `255.255.255.224` (`/27`)
- LAN addresses: `172.16.3.81` through `172.16.3.85`

Verify that the physical interface exists on the libvirt host and that the addresses are available on the intended LAN.

The current Vagrantfile applies this LAN configuration to every VM because all five entries have a `lan_ip`.

Direct/macvtap networking behaves differently from a conventional Linux bridge. Verify that its connectivity characteristics suit your environment.

### 3. Zabbix server or proxy

The Vagrantfile currently defines:

Replace this address with the reachable Zabbix server or proxy address for your environment.

Each VM uses its own hostname for the Zabbix Agent 2 `Hostname` setting. Configure corresponding hosts in the Zabbix frontend.

### 4. Zabbix PSK encryption

Each VM generates its own PSK inside the guest if `/etc/zabbix/encrypt.psk` does not already exist.

The PSK identity is derived from the VM hostname, for example:

```text
k8s-master-psk
k8s-worker1-psk
```

Configure the corresponding PSK identity and secret in the Zabbix frontend. Keep all PSK secrets private and out of Git.

### 5. Temporary return route

The Vagrantfile creates a systemd service that installs this route:

```text
172.16.4.0/24 via 172.16.3.66 dev eth2
```

This assumes that `eth2` is the correct interface and `172.16.3.66` is the correct gateway for reaching the Windows subnet.

The current provisioner applies this route configuration to every VM. Review it before using the lab on another network.

These route and LAN settings are explicitly marked as temporary experiments in the Vagrantfile and should be removed or adapted when the experiment is finished.

### 6. Disk layout

The provisioning script assumes the following disk layout:

- `/dev/vda3`: LVM physical partition
- `ubuntu-vg`: LVM volume group
- `/dev/ubuntu-vg/ubuntu-lv`: root logical volume

If you change the base box or its disk layout, inspect `lsblk` and the LVM configuration before reusing the expansion commands.

## Provisioning

The Vagrantfile automates these tasks on each VM:

1. Updates the APT package index.
2. Installs disk expansion and repository setup utilities.
3. Expands the root partition, LVM physical volume, root logical volume, and filesystem.
4. Installs Docker Engine and the Compose plugin.
5. Adds the `vagrant` user to the Docker group.
6. Installs Zabbix Agent 2 from the Zabbix 7.0 repository.
7. Generates a unique PSK inside each VM.
8. Configures Zabbix Agent 2 for passive and active checks with PSK encryption.
9. Enables and starts the Zabbix Agent 2 service.
10. Configures the temporary LAN return route.

## Usage

Run these commands from this directory.

### Create and provision all five VMs

```bash
vagrant up
```

### Check VM status

```bash
vagrant status
```

### Connect to a VM

```bash
vagrant ssh k8s-master
```

You can replace `k8s-master` with `k8s-worker1`, `k8s-worker2`, `k8s-worker3`, or `k8s-worker4`.

### Verify Docker

Inside a VM:

```bash
docker --version
docker compose version
sudo systemctl status docker
```

### Verify Zabbix Agent 2

Inside a VM:

```bash
sudo systemctl status zabbix-agent2
sudo zabbix_agent2 -T -c /etc/zabbix/zabbix_agent2.conf
```

### Re-run provisioning

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

## Security notes

- Review all IP addresses, gateways, and interface names before provisioning.
- Do not commit PSK secrets, private keys, passwords, or tokens.
- Docker group membership grants effectively root-level privileges inside each VM.
- The VMs require access to package repositories during provisioning.
- The LAN configuration is environment-specific and should not be copied blindly to another network.
