#!/bin/bash

set -euo pipefail

set_settings() {
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SETTINGS=$(cd $SCRIPT_DIR/../ && ./pkl eval Settings.pkl -f json)
    CLUSTER_ENGINE=$(echo "$SETTINGS" | jq -r '.cluster.engine');
    CLUSTER_NAME=$(echo "$SETTINGS" | jq -r '.cluster.name');
}

set_settings