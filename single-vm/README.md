# Single VM Lab

## Overview

This lab uses Vagrant and the libvirt provider to create a single Ubuntu 24.04 virtual machine. It provides a starting point for Linux administration and future Docker practice.

## Configuration

| Setting | Value |
|---|---|
| Base box | `bento/ubuntu-24.04` |
| Hostname | `docker-vm` |
| Memory | 2 GB |
| Virtual CPUs | 2 |
| Virtualization provider | libvirt |

## Prerequisites

- Vagrant
- The Vagrant libvirt provider/plugin
- A working libvirt/KVM environment
- Network access to download the base box, if it is not already available locally

## Usage

Run these commands from this directory.

### Create and start the VM

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

### Stop the VM

```bash
vagrant halt
```

### Delete the VM

```bash
vagrant destroy
```

**Warning:** Destroying the VM removes the virtual machine and its virtual disk. Back up anything you want to keep before confirming the operation.

## Notes

This configuration creates the VM but does not automatically install Docker or other software. Additional provisioning can be added as the lab evolves.








# Single VM Lab

## Overview

This lab uses Vagrant and the libvirt provider to create a single Ubuntu 24.04 virtual machine. It provides a starting point for Linux administration and future Docker practice.

## Configuration

| Setting | Value |
|---|---|
| Base box | `bento/ubuntu-24.04` |
| Hostname | `docker-vm` |
| Memory | 2 GB |
| Virtual CPUs | 2 |
| Virtualization provider | libvirt |

## Prerequisites

- Vagrant
- The Vagrant libvirt provider/plugin
- A working libvirt/KVM environment
- Network access to download the base box, if it is not already available locally

## Usage

Run these commands from this directory.

### Create and start the VM

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

### Stop the VM

```bash
vagrant halt
```

### Delete the VM

```bash
vagrant destroy
```

**Warning:** Destroying the VM removes the virtual machine and its virtual disk. Back up anything you want to keep before confirming the operation.

## Notes

This configuration creates the VM but does not automatically install Docker or other software. Additional provisioning can be added as the lab evolves.
