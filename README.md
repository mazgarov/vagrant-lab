
# Vagrant Lab

A collection of hands-on labs for learning Linux virtualization, Docker, monitoring, and Kubernetes using Vagrant and libvirt.

The goal of this repository is to build practical infrastructure and DevOps skills through repeatable virtual machine environments.

## Labs

### 1. Single VM

**Directory:** [`single-vm/`](./single-vm/)

Create a single Ubuntu 24.04 virtual machine using Vagrant and libvirt.

Use this lab to learn the basics of Vagrant, including creating, accessing, stopping, and destroying virtual machines.

See the [lab documentation](./single-vm/README.md).

### 2. VM with Docker and Zabbix Agent

**Directory:** [`vm-docker-zabbix/`](./vm-docker-zabbix/)

Create an Ubuntu 24.04 virtual machine with Docker Engine, Docker Compose, and Zabbix Agent 2 installed.

This lab demonstrates automated VM provisioning and basic infrastructure monitoring integration.

See the [lab documentation](./vm-docker-zabbix/README.md).

### 3. Multiple VMs on a LAN

**Directory:** [`multiple-vm-lan/`](./multiple-vm-lan/)

Create a group of five Ubuntu virtual machines with private networking, Docker, and Zabbix Agent 2.

This lab explores multi-VM environments, static IP addressing, and additional network configuration.

See the lab directory for its Vagrantfile and documentation.

### 4. Kubernetes Cluster

**Directory:** [`kubernetes-cluster/`](./kubernetes-cluster/)

Create a five-node Kubernetes lab consisting of one control-plane node and four worker nodes.

The environment uses Ubuntu 24.04, containerd, kubeadm, kubelet, kubectl, and Flannel for pod networking.

The lab includes scripts to initialize the control plane and join worker nodes.

See the [lab documentation](./kubernetes-cluster/README.md).

## Prerequisites

Before using these labs, you will need:

- A Linux host with KVM/libvirt configured, or another environment compatible with the Vagrant provider used by the lab.
- Vagrant with the `vagrant-libvirt` provider.
- Sufficient CPU, memory, and disk space for the selected lab.
- Network access to download the required Vagrant boxes and software packages.

**Important:** Review each lab's README and Vagrantfile before starting it. Some labs require additional network configuration or environment-specific settings.

## General Usage

Run Vagrant commands from the directory of the lab you want to use.

For example:

```bash
cd single-vm
vagrant up
vagrant status
vagrant ssh
```

To stop a VM:

```bash
vagrant halt
```

To destroy the Vagrant-managed VM:

```bash
vagrant destroy
```

> **Warning:** `vagrant destroy` deletes the VM managed by Vagrant. Back up any data you want to keep before running it.

## Configuration and Security

- Review IP addresses, network interfaces, routes, and other environment-specific settings before provisioning.
- Configure the Zabbix server or proxy address where required by the lab.
- Do not commit passwords, private keys, production secrets, or other sensitive configuration.
- Review provisioning scripts before running them, especially when using them in an environment other than the original lab.

## Learning Roadmap

The labs are intended to support a progression from basic virtual machines to more complex infrastructure:

1. Learn Vagrant and virtual machine lifecycle management.
2. Practice automated provisioning, Docker, and monitoring integration.
3. Explore multi-VM networking.
4. Build and operate a Kubernetes cluster.
5. Use the Kubernetes environment to practice deploying applications.

## Status

These labs are intended for learning and experimentation. Configuration and prerequisites may need to be adapted to your own environment.
