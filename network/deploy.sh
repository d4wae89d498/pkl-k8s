#!/bin/bash

# === Get script location ===
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# === GET $NODES ===
source $SCRIPT_DIR/nodes.sh

# === CONFIGURATION ===
IPSETS_DIR="$SCRIPT_DIR/ipsets"     # ipsets folder relative to script
RULES_TEMPLATE="$SCRIPT_DIR/node.fw" # main firewall template
CLUSTER_TEMPLATE="$SCRIPT_DIR/cluster.fw"

# === FUNCTIONS ===
function deploy_ipsets {
    local SSH_TARGET=$1
    echo "[+] Deploying IP sets to $SSH_TARGET..."

    # Loop through all .fw files in ipsets/
    for ipset_file in $(ls ${IPSETS_DIR}/*.fw 2>/dev/null | grep -v '^$'); do
        scp "$ipset_file" "${SSH_TARGET}:/etc/pve/firewall/$(basename $ipset_file)"
        echo " ✔ Copied $(basename $ipset_file)"
    done

    echo "[+] IP sets deployed."
}

function deploy_vm_rules {
    local SSH_TARGET=$1
    local VMID=$2
    local TMP_DIR=$(mktemp -d)

    echo "[+] Deploying rules for VM$VMID on $SSH_TARGET..."

    scp "${CLUSTER_TEMPLATE}" "${SSH_TARGET}:/etc/pve/firewall/cluster.fw"
    scp "${RULES_TEMPLATE}" "${SSH_TARGET}:/etc/pve/firewall/${VMID}.fw"
    echo " ✔ Copied VM$VMID rules"

    rm -rf "$TMP_DIR"
    echo "[+] Done deploying VM$VMID rules."
}

function reload_firewall {
    local SSH_TARGET=$1
    echo "[+] Restarting PVE firewall on $SSH_TARGET..."
    ssh "$SSH_TARGET" "pve-firewall compile 2>&1 >/dev/null && pve-firewall restart"
    echo " ✔ Firewall restarted."
}

# === MAIN ===
echo "[*] Starting deployment..."

for NODE in "${PVE_NODES[@]}"; do
    SSH_TARGET=$(echo "$NODE" | cut -d ':' -f1 | tr -d ' ')
    VMIP=$(echo "$NODE" | cut -d ':' -f2 | tr -d ' ')
    VMID=$(echo "$NODE" | cut -d ':' -f3 | tr -d ' ' )

    echo "Processing PVE $SSH_TARGET VM #$VMID IP $VMIP"
    deploy_ipsets "$SSH_TARGET"
    deploy_vm_rules "$SSH_TARGET" "$VMID"
    reload_firewall "$SSH_TARGET"
done

echo "[*] Deployment complete."