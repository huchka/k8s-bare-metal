#!/bin/bash
set -e

CLOUD_INIT="cloud-init/common.yaml"

UBUNTU_VERSION="22.04"
CPUS=2
MEMORY=2G
DISK=20G

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
