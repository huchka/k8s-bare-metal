# k8s-bare-metal

## Purpose

Self-study project to build a Kubernetes cluster from scratch on local VMs. The goal is to understand every component and step involved in setting up K8s — not just get a working cluster.

## Learning Approach

- **User drives the implementation.** Don't execute provisioning or K8s commands — provide them and explain what they do.
- **Explain after every change.** When modifying config files, cloud-init, or Ansible playbooks, explain what each section does and why it's needed.
- **No shortcuts.** Don't skip steps or bundle multiple concepts. One step at a time.
- **Ask before choosing.** When there are multiple valid approaches (e.g., CNI plugin, networking mode), present options with tradeoffs.

## Infrastructure

- **Host:** macOS M2 (Apple Silicon)
- **VM tool:** Multipass (ARM64 Ubuntu 22.04 VMs)
- **Automation:** cloud-init for OS-level prep, Ansible for K8s provisioning
- **Container runtime:** containerd
- **K8s version:** v1.30

## Cluster Topology

| Node    | Role          | CPUs | Memory | Disk |
|---------|---------------|------|--------|------|
| cp1     | control plane | 2    | 2GB    | 20GB |
| worker1 | worker        | 2    | 2GB    | 20GB |
| worker2 | worker        | 2    | 2GB    | 20GB |

## Project Structure

- `cloud-init/` — cloud-init YAML configs for VM bootstrap
- `ansible/` — Ansible playbooks and inventory for K8s setup
- `up.sh` — Launch all VMs
- `plan.md` — Step-by-step build plan
