
# VM — Docker and Zabbix Agent

## Overview

This lab uses Vagrant and the libvirt provider to provision an Ubuntu 24.04 virtual machine with Docker Engine, Docker Compose, and Zabbix Agent 2.

The configuration also expands the root filesystem to use the available space on an 80 GB virtual disk.

## Configuration

| Setting | Value |
|---|---|
| Operating system | Ubuntu 24.04 LTS |
| Vagrant box | `bento/ubuntu-24.04` |
| Box version | `202508.03.0` |
| VM hostname | `docker-vm` |
| Memory | 2 GB |
| Virtual CPUs | 2 |
| Virtual disk | 80 GB |
| Provider | libvirt |
| Container runtime | Docker Engine with containerd |
| Compose | Docker Compose plugin |
| Monitoring agent | Zabbix Agent 2 |
| Zabbix repository | Zabbix 7.0 |

## Prerequisites

- Vagrant
- The Vagrant libvirt provider/plugin
- A working libvirt/KVM environment
- Network access from the guest to the Ubuntu, Docker, and Zabbix package repositories
- A reachable Zabbix server or proxy if monitoring is required

## Before provisioning

Review the following settings and requirements before running `vagrant up`.

### 1. Zabbix server or proxy address

The Vagrantfile currently defines:

Replace this value with the address of the Zabbix server or proxy reachable from the VM.

The address is used for both `Server` and `ServerActive` in the Zabbix Agent 2 configuration.

### 2. Zabbix host name

The agent hostname is configured as:

```text
docker-vm
```

Create or configure the corresponding host in the Zabbix frontend using the same host name. If you change the hostname in the Vagrantfile, update the Zabbix host configuration accordingly.

### 3. PSK encryption

The provisioning script generates a PSK inside the VM if `/etc/zabbix/encrypt.psk` does not already exist.

The configured PSK identity is:

```text
docker-vm-psk
```

For Zabbix communication to work with PSK encryption, the host's encryption settings in the Zabbix frontend must match the agent's PSK identity and secret.

Keep the PSK secret private. Do not commit the generated key or other credentials to GitHub.

### 4. Network connectivity

Ensure that the VM can reach the configured Zabbix server or proxy on the required Zabbix agent ports. Also ensure that the guest can access the package repositories during provisioning.

This Vagrantfile does not explicitly configure a custom network interface or static IP address.

### 5. VM resources and disk layout

The VM is configured with 2 GB of RAM, 2 virtual CPUs, and an 80 GB virtual disk.

The provisioning script assumes that the base Ubuntu image uses `/dev/vda3` as the LVM physical volume and `/dev/ubuntu-vg/ubuntu-lv` as the root logical volume. Verify these assumptions if you change the base box.

## Provisioning

The Vagrantfile automates these tasks:

1. Updates Ubuntu packages.
2. Installs disk expansion and repository setup tools.
3. Expands the partition, LVM physical volume, root logical volume, and filesystem.
4. Adds the official Docker APT repository.
5. Installs Docker Engine, the Docker CLI, containerd, Buildx, and the Compose plugin.
6. Enables Docker and adds the `vagrant` user to the Docker group.
7. Installs Zabbix Agent 2 from the Zabbix 7.0 repository.
8. Generates and configures the local PSK.
9. Configures the Zabbix server, active checks, hostname, and PSK encryption.
10. Validates the Zabbix Agent configuration and starts the service.

## Usage

Run these commands from this directory.

### Create and provision the VM

```bash
vagrant up
```

### Connect to the VM

```bash
vagrant ssh
```

### Check VM status

```bash
vagrant status
```

### Verify Docker

Inside the VM:

```bash
docker --version
docker compose version
sudo systemctl status docker
```

The `vagrant` user may need a new login session before its Docker group membership takes effect.

### Verify Zabbix Agent 2

Inside the VM:

```bash
sudo systemctl status zabbix-agent2
sudo zabbix_agent2 -T -c /etc/zabbix/zabbix_agent2.conf
```

### Re-run provisioning

```bash
vagrant provision
```

### Stop the VM

```bash
vagrant halt
```

### Destroy the VM

```bash
vagrant destroy
```

**Warning:** Destroying the VM removes its virtual disk and the data stored on it. Back up anything you want to keep before confirming the operation.

## Security notes

- Review the Zabbix server address before provisioning.
- Never commit PSK secrets, private keys, passwords, or tokens.
- Membership in the Docker group grants effectively root-level privileges inside the VM.
- The VM requires network access to the package repositories during provisioning.
