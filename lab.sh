#!/bin/bash
set -e

CLOUD_INIT="cloud-init/common.yaml"
UBUNTU_VERSION="22.04"
CPUS=2
MEMORY=2G
DISK=20G
NODES=(cp1 worker1 worker2)

usage() {
  echo "Usage: $0 {up|down|destroy|status}"
  echo ""
  echo "  up       Launch or start all VMs"
  echo "  down     Stop all VMs (preserves state)"
  echo "  destroy  Delete and purge all VMs"
  echo "  status   Show VM status"
  exit 1
}

cmd_up() {
  for vm in "${NODES[@]}"; do
    state=$(multipass info "$vm" --format csv 2>/dev/null | tail -1 | cut -d, -f2 || echo "")
    if [ "$state" = "Running" ]; then
      echo "  $vm already running"
    elif [ -n "$state" ]; then
      echo "  Starting $vm..."
      multipass start "$vm"
    else
      echo "  Launching $vm..."
      multipass launch $UBUNTU_VERSION --name "$vm" --cpus $CPUS --memory $MEMORY --disk $DISK \
        --cloud-init "$CLOUD_INIT"
    fi
  done

  echo ""
  multipass list
}

cmd_down() {
  echo "Stopping VMs..."
  for vm in "${NODES[@]}"; do
    multipass stop "$vm" 2>/dev/null && echo "  Stopped $vm" || echo "  $vm not running"
  done
}

cmd_destroy() {
  echo "Destroying VMs..."
  for vm in "${NODES[@]}"; do
    multipass delete "$vm" 2>/dev/null && echo "  Deleted $vm" || echo "  $vm not found"
  done
  multipass purge
  echo "All VMs purged."
}

cmd_status() {
  multipass list
}

case "${1:-}" in
  up)      cmd_up ;;
  down)    cmd_down ;;
  destroy) cmd_destroy ;;
  status)  cmd_status ;;
  *)       usage ;;
esac
