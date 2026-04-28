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
- **K8s version:** v1.35

## Cluster Topology

| Node    | Role          | CPUs | Memory | Disk |
|---------|---------------|------|--------|------|
| cp1     | control plane | 2    | 2GB    | 20GB |
| worker1 | worker        | 2    | 2GB    | 20GB |
| worker2 | worker        | 2    | 2GB    | 20GB |

## Development Process

This project follows a structured SDLC. See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow, labels, board columns, and branch naming conventions.

### Process Rules for Claude
- Follow the workflow defined in CONTRIBUTING.md.
- NEVER create an issue without acceptance criteria.
- ALWAYS apply appropriate `type:`, `priority:`, and `size:` labels when creating issues.
- ALWAYS link PRs to issues with `Closes #N`.
- When starting a new feature: check if a design exists (wiki page or inline in issue). Only create a wiki page for `size:L` or issues with meaningful architectural tradeoffs. For `size:S` or obvious approaches, inline in the issue body is sufficient.
- When creating issues from a design: label them `phase:ready` only after design is reviewed.
- New issues start as `phase:design` unless the task is straightforward (bug fix, small chore).
- When starting work on an issue: move it to "In Progress" on the project board.
- When opening a PR: move the issue to "In Review".
- When merged and verified: move the issue to "Done".

## Plan Mode for non-trivial changes

Drop into Plan Mode (Shift+Tab) and save the plan to `.plans/YYYYMMDD-<slug>.md` before executing for:
- New cloud-init steps or significant changes to existing ones
- New Ansible roles or playbook restructures
- VM topology changes (adding nodes, role changes, sizing)
- Bringing up new K8s components (CNI, storage, ingress, observability)
- Anything requiring a from-scratch `up.sh` re-run on the user's side

Skip for: typo fixes, comment edits, single-line config tweaks. See `.plans/README.md` for naming and structure.

## Project Structure

- `cloud-init/` — cloud-init YAML configs for VM bootstrap
- `ansible/` — Ansible playbooks and inventory for K8s setup
- `up.sh` — Launch all VMs
- `plan.md` — Step-by-step build plan
- `.plans/` — Versioned implementation plans for non-trivial changes
