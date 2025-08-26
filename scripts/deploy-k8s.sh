#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/../network/nodes.sh

REMOTE_PATH="demo-infra"
for NODE in "${PVE_NODES[@]}"; do

    # 0. Get target
    VM_TARGET=$(echo "$NODE" | cut -d ':' -f2 | tr -d ' ')
    echo "Deploying on $VM_TARGET"

    # 1. Ensure remote path exists
    ssh "$VM_TARGET" "mkdir -p ${REMOTE_PATH} && \
        rm -rf ${REMOTE_PATH}/cluster"

    # 2. Copy local cluster directory to remote host
    scp -r "$SCRIPT_DIR/../cluster" "$VM_TARGET:${REMOTE_PATH}/cluster"

    # 3. Run!!
    ssh "$VM_TARGET" "cd ${REMOTE_PATH} && sudo -S make apply"

done