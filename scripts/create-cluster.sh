#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/settings.sh

echo ======================================================
echo "Installing cluster ${CLUSTER_NAME}..."
$SCRIPT_DIR/engines/${CLUSTER_ENGINE}/create-cluster.sh
echo "Cluster created."
echo "Waiting for cluster to be ready..."
until kubectl get nodes >/dev/null 2>&1; do
    sleep 2
done
echo "Cluster is ready."
echo ======================================================
