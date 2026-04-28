# Plans

Versioned implementation plans for non-trivial k8s-bare-metal changes.

## When to use

Drop into Plan Mode (Shift+Tab) and save the resulting plan to this directory before executing, when the task is one of:

- New cloud-init step or significant change to existing one
- New Ansible role or playbook restructure
- VM topology change (adding nodes, changing roles, sizing)
- Bringing up a new K8s component (CNI, storage, ingress, observability)
- Anything that requires re-running `up.sh` from scratch on the user's side

Skip Plan Mode for: typo fixes, comment edits, single-line config tweaks.

## Naming

```
.plans/YYYYMMDD-<kebab-slug>.md
```

Examples:
- `.plans/20260428-cilium-cni-install.md`
- `.plans/20260505-add-metallb-loadbalancer.md`

## Plan structure

Each file should contain:

1. **Goal** — one sentence: what success looks like
2. **Context** — current cluster state, related steps in `plan.md`
3. **Approach** — the chosen path with rejected alternatives noted (especially CNI/storage/ingress choices — these have heavy tradeoffs)
4. **Steps** — ordered, verifiable; user runs each step and confirms before next
5. **Risks / rollback** — what could go wrong, how to undo

## Lifecycle

- Plans are committed alongside the code/playbook change they drove
- Plans are not edited after merge — they capture decisions in time
- Stale plans stay as historical record

## Why

This is a learning project — the *reasoning* behind each step is the point, not just the working result. Saved plans preserve that reasoning across sessions and form the basis for future blog posts.
