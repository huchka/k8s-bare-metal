# k8s-bare-metal

A Kubernetes cluster built from scratch on local VMs using kubeadm. The goal is to understand every component — not just get a working cluster.

## Cluster

Topology is defined in `cluster.yaml`:

```yaml
cluster:
  ubuntu_version: "22.04"
  control_plane:
    count: 1
    cpus: 2
    memory: 2G
    disk: 20G
  workers:
    count: 2
    cpus: 2
    memory: 2G
    disk: 20G
```

Change the counts to adjust topology. Node names are generated automatically (`cp1..cpN`, `worker1..workerM`).

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

## Build from Scratch

### 1. Launch VMs

```bash
./lab.sh up
```

Creates VMs based on `cluster.yaml` with cloud-init (kernel modules, sysctl, containerd, kubeadm). Auto-generates `ansible/inventory.ini` from Multipass IPs.

### 2. Bootstrap control plane

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/init-control-plane.yaml
```

Runs `kubeadm init` on cp1 with Calico pod CIDR (`192.168.0.0/16`), sets up kubeconfig, and saves the join command.

### 3. Install Calico CNI

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/install-calico.yaml
```

Installs the Tigera operator and Calico. Waits for calico-node and CoreDNS to be ready. Control plane node goes `Ready`.

### 4. Join workers

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/join-workers.yaml
```

Joins all worker nodes to the cluster and verifies every node is `Ready`.

### 5. Verify

```bash
multipass exec cp1 -- kubectl get nodes
multipass exec cp1 -- kubectl get pods -A
```

## Tear Down

```bash
./lab.sh destroy
```

Deletes and purges all VMs. To rebuild from scratch, run the full build sequence again.

## Lab Management

```bash
./lab.sh up          # Launch or start all VMs + generate inventory
./lab.sh down        # Stop VMs (preserves state)
./lab.sh destroy     # Delete and purge all VMs
./lab.sh status      # Show VM status
./lab.sh inventory   # Regenerate ansible/inventory.ini from running VMs
```

## Full Lifecycle (copy-paste)

Build a cluster from nothing:

```bash
./lab.sh up
ansible-playbook -i ansible/inventory.ini ansible/playbooks/init-control-plane.yaml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/install-calico.yaml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/join-workers.yaml
multipass exec cp1 -- kubectl get nodes
```

Tear down and rebuild:

```bash
./lab.sh destroy
./lab.sh up
ansible-playbook -i ansible/inventory.ini ansible/playbooks/init-control-plane.yaml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/install-calico.yaml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/join-workers.yaml
multipass exec cp1 -- kubectl get nodes
```

## Project Structure

```
cluster.yaml         Cluster topology config (node counts, resources)
cloud-init/          OS-level node preparation (cloud-init YAML)
ansible/
  inventory.ini      Auto-generated Ansible inventory (gitignored after dynamic switch)
  join-command.txt   kubeadm join command (gitignored)
  playbooks/
    init-control-plane.yaml   kubeadm init + kubeconfig + join command
    install-calico.yaml       Calico CNI via Tigera operator
    join-workers.yaml         kubeadm join + cluster health check
plan.md              Full build plan
lab.sh               VM lifecycle + inventory generation
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
| 6. Cluster Validation | Done |

## Blog Series

This project is documented in a blog series:

- [#0: I've Been Using Managed Kubernetes. Now I'm Building It by Hand.](TODO)
- [#1: Every kubeadm Tutorial Lists These 5 Steps. Here's What They Actually Do.](TODO)
- [#2: From Three Disconnected VMs to a Running Control Plane](TODO)
