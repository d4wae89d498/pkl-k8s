#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/settings.sh

echo ======================================================
echo "Deleting cluster ${CLUSTER_NAME}..."
$SCRIPT_DIR/engines/${CLUSTER_ENGINE}/delete-cluster.sh
echo "Cluster deleted."
echo ======================================================