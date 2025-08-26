#!/bin/bash
set -euo pipefail
###################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/../../settings.sh
PROJECT_ROOT=$(realpath $SCRIPT_DIR/../../../)
###################
PORTS=$(echo "$SETTINGS" | jq -r '
  .ingress.ports | to_entries[] | 
  "--port \(.value):\(.value)"' | tr '\n' ' ')

cd $PROJECT_ROOT

###################
cmd="k3d cluster create $CLUSTER_NAME \
    --servers 1 \
    --agents 0 \
    --volume $PROJECT_ROOT/storage:/storage \
    $PORTS \
    --network k3d-demo \
    --k3s-arg --disable=traefik@server:*
    " 
echo $cmd
$cmd