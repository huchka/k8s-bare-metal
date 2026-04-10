#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/cluster.yaml"

# Parse cluster.yaml using awk (no Python/yq dependency)
read_config() {
  awk '
    /ubuntu_version:/  { gsub(/"/, "", $2); print "UBUNTU_VERSION=" $2 }
    /cloud_init:/      { gsub(/"/, "", $2); print "CLOUD_INIT=" $2 }
    /control_plane:/   { section = "cp" }
    /workers:/         { section = "wk" }
    /count:/           { if (section == "cp") print "CP_COUNT=" $2;
                         if (section == "wk") print "WK_COUNT=" $2 }
    /cpus:/            { if (section == "cp") print "CP_CPUS=" $2;
                         if (section == "wk") print "WK_CPUS=" $2 }
    /memory:/          { if (section == "cp") print "CP_MEMORY=" $2;
                         if (section == "wk") print "WK_MEMORY=" $2 }
    /disk:/            { if (section == "cp") print "CP_DISK=" $2;
                         if (section == "wk") print "WK_DISK=" $2 }
  ' "$CONFIG"
}

eval "$(read_config)"

# Build node lists from config
CP_NODES=()
for i in $(seq 1 "$CP_COUNT"); do
  CP_NODES+=("cp$i")
done

WORKER_NODES=()
for i in $(seq 1 "$WK_COUNT"); do
  WORKER_NODES+=("worker$i")
done

ALL_NODES=("${CP_NODES[@]}" "${WORKER_NODES[@]}")

usage() {
  echo "Usage: $0 {up|down|destroy|status|inventory}"
  echo ""
  echo "  up        Launch or start all VMs"
  echo "  down      Stop all VMs (preserves state)"
  echo "  destroy   Delete and purge all VMs"
  echo "  status    Show VM status"
  echo "  inventory Generate ansible/inventory.ini from running VMs"
  exit 1
}

cmd_up() {
  for vm in "${CP_NODES[@]}"; do
    launch_or_start "$vm" "$CP_CPUS" "$CP_MEMORY" "$CP_DISK"
  done

  for vm in "${WORKER_NODES[@]}"; do
    launch_or_start "$vm" "$WK_CPUS" "$WK_MEMORY" "$WK_DISK"
  done

  echo ""
  multipass list

  echo ""
  echo "Generating inventory..."
  cmd_inventory
}

launch_or_start() {
  local vm=$1 cpus=$2 memory=$3 disk=$4
  state=$(multipass info "$vm" --format csv 2>/dev/null | tail -1 | cut -d, -f2 || echo "")
  if [ "$state" = "Running" ]; then
    echo "  $vm already running"
  elif [ -n "$state" ]; then
    echo "  Starting $vm..."
    multipass start "$vm"
  else
    echo "  Launching $vm..."
    multipass launch "$UBUNTU_VERSION" --name "$vm" --cpus "$cpus" --memory "$memory" --disk "$disk" \
      --cloud-init "$SCRIPT_DIR/$CLOUD_INIT"
  fi
}

get_vm_ip() {
  multipass info "$1" --format csv 2>/dev/null | tail -1 | cut -d, -f3
}

cmd_inventory() {
  local inv="$SCRIPT_DIR/ansible/inventory.ini"
  mkdir -p "$SCRIPT_DIR/ansible"

  {
    echo "[control_plane]"
    for vm in "${CP_NODES[@]}"; do
      ip=$(get_vm_ip "$vm")
      if [ -z "$ip" ]; then
        echo "Error: Could not get IP for $vm. Is it running?" >&2
        exit 1
      fi
      echo "$vm ansible_host=$ip"
    done

    echo ""
    echo "[workers]"
    for vm in "${WORKER_NODES[@]}"; do
      ip=$(get_vm_ip "$vm")
      if [ -z "$ip" ]; then
        echo "Error: Could not get IP for $vm. Is it running?" >&2
        exit 1
      fi
      echo "$vm ansible_host=$ip"
    done

    echo ""
    echo "[k8s:children]"
    echo "control_plane"
    echo "workers"

    echo ""
    echo "[k8s:vars]"
    echo "ansible_user=ubuntu"
    echo "ansible_ssh_private_key_file=~/.ssh/multipass_default"
    echo "ansible_python_interpreter=/usr/bin/python3.10"
  } > "$inv"

  echo "  Written to $inv"
}

cmd_down() {
  echo "Stopping VMs..."
  for vm in "${ALL_NODES[@]}"; do
    multipass stop "$vm" 2>/dev/null && echo "  Stopped $vm" || echo "  $vm not running"
  done
}

cmd_destroy() {
  echo "Destroying VMs..."
  for vm in "${ALL_NODES[@]}"; do
    multipass delete "$vm" 2>/dev/null && echo "  Deleted $vm" || echo "  $vm not found"
  done
  multipass purge
  echo "All VMs purged."
}

cmd_status() {
  multipass list
}

case "${1:-}" in
  up)        cmd_up ;;
  down)      cmd_down ;;
  destroy)   cmd_destroy ;;
  status)    cmd_status ;;
  inventory) cmd_inventory ;;
  *)         usage ;;
esac
