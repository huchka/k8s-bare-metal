#!/bin/bash
set -e

CLOUD_INIT="cloud-init/common.yaml"

UBUNTU_VERSION="22.04"
CPUS=2
MEMORY=2G
DISK=20G

echo "Checking if VMs already exist..."
for vm in cp1 worker1 worker2; do
  if multipass info "$vm" >/dev/null 2>&1; then
    echo "Error: VM '$vm' already exists. Aborting."
    exit 1
  fi
done

echo "Launching control plane..."
multipass launch $UBUNTU_VERSION --name cp1 --cpus $CPUS --memory $MEMORY --disk $DISK \
  --cloud-init "$CLOUD_INIT"

echo "Launching worker nodes..."
multipass launch $UBUNTU_VERSION --name worker1 --cpus $CPUS --memory $MEMORY --disk $DISK \
  --cloud-init "$CLOUD_INIT"

multipass launch $UBUNTU_VERSION --name worker2 --cpus $CPUS --memory $MEMORY --disk $DISK \
  --cloud-init "$CLOUD_INIT"

echo "All VMs launched."
multipass list
