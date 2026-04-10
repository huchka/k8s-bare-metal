# k8s-bare-metal

A Kubernetes cluster built from scratch on local VMs using kubeadm. The goal is to understand every component — not just get a working cluster.

## Cluster

Three arm64 Ubuntu 22.04 VMs on [Multipass](https://multipass.run/) (Apple Silicon).

| Node | Role | IP |
|------|------|----|
| cp1 | control plane | 192.168.2.5 |
| worker1 | worker | 192.168.2.6 |
| worker2 | worker | 192.168.2.7 |

**Stack:** containerd, kubeadm v1.35, Calico CNI (Tigera operator)

## Prerequisites

- macOS with [Multipass](https://multipass.run/) installed
- [Ansible](https://docs.ansible.com/) (`brew install ansible`)
- Multipass SSH key copied to `~/.ssh/multipass_default`:
  ```bash
  sudo cp "/var/root/Library/Application Support/multipassd/ssh-keys/id_rsa" ~/.ssh/multipass_default
  sudo chown $(whoami) ~/.ssh/multipass_default
  chmod 600 ~/.ssh/multipass_default
  ```

## Quick Start

### 1. Launch VMs

```bash
./lab.sh up
```

Creates three VMs with cloud-init (OS prep: kernel modules, sysctl, containerd, kubeadm). If VMs already exist but are stopped, starts them.

### 2. Bootstrap control plane

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/init-control-plane.yaml
```

Runs `kubeadm init` on cp1, sets up kubeconfig, and saves the join command.

### 3. Install Calico CNI

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/install-calico.yaml
```

Installs the Tigera operator and Calico with pod CIDR `192.168.0.0/16`. Waits for calico-node and CoreDNS to be ready.

### 4. Join workers

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/join-workers.yaml
```

Joins worker1 and worker2 to the cluster and verifies all nodes are `Ready`.

### 5. Verify

```bash
multipass exec cp1 -- kubectl get nodes
multipass exec cp1 -- kubectl get pods -A
```

## Lab Management

```bash
./lab.sh up        # Launch or start all VMs
./lab.sh down      # Stop VMs (preserves state)
./lab.sh destroy   # Delete and purge all VMs
./lab.sh status    # Show VM status
```

## Project Structure

```
cloud-init/          OS-level node preparation (cloud-init YAML)
ansible/
  inventory.ini      Ansible inventory (node IPs, SSH config)
  join-command.txt   kubeadm join command (gitignored)
  playbooks/
    init-control-plane.yaml   Phase 3: kubeadm init + kubeconfig + join command
    install-calico.yaml       Phase 4: Calico CNI via Tigera operator
    join-workers.yaml         Phase 5: kubeadm join + cluster health check
plan.md              Full build plan (7 phases)
lab.sh               VM lifecycle management
```

## Build Plan

See [plan.md](plan.md) for the full step-by-step plan. Progress is tracked on the [project board](https://github.com/users/huchka/projects/2).

| Phase | Status |
|-------|--------|
| 1. OS Preparation (cloud-init) | Done |
| 2. Ansible Setup | Done |
| 3. Control Plane Bootstrap | Done |
| 4. CNI Plugin (Calico) | Done |
| 5. Worker Nodes Join | Done |
| 6. Cluster Validation | Next |
| 7. Optional Extras | Planned |

## Blog Series

This project is documented in a blog series:

- [#0: I've Been Using Managed Kubernetes. Now I'm Building It by Hand.](TODO)
- [#1: Every kubeadm Tutorial Lists These 5 Steps. Here's What They Actually Do.](TODO)
- [#2: From Three Disconnected VMs to a Running Control Plane](TODO)
