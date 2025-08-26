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
   ssh "$VM_TARGET" "mkdir -p ${REMOTE_PATH}"

   # 2. Remote cleanup (excluding certain persistent folders/files)
   ssh "$VM_TARGET" bash <<EOF
cd "${REMOTE_PATH}" || exit 1

find . \\( \
   -path '.' \
   -o -path '..' \
   -o -path './Settings.pkl' \
   \
   -o -path './storage/nextcloud' \
   -o -path './storage/nextcloud/*' \
   -o -path './storage/mariadb' \
   -o -path './storage/mariadb/*' \
   -o -path './storage/data' \
   -o -path './storage/data/*' \
   \
   -o -path './storage/demo/nginx/public' \
   -o -path './storage/demo/nginx/public/*' \
   -o -path './storage/demo/nginx/logs' \
   -o -path './storage/demo/nginx/logs/*' \
   -o -path './storage/demo/backend' \
   -o -path './storage/demo/backend/*' \
   -o -path './storage/demo/mongo' \
   -o -path './storage/demo/mongo/*' \
   \
   -o -path './storage/pro/nginx/public' \
   -o -path './storage/pro/nginx/public/*' \
   -o -path './storage/pro/nginx/logs' \
\\) -prune -o -exec rm -rf {} +
EOF

   # 3. Generate file list (excluding Settings.pkl)
   git ls-files | grep -v '^Settings.pkl$' > /tmp/deploy_filelist.txt
   find releases -type f >> /tmp/deploy_filelist.txt

   # 4. Create zip
   zip -@ deploy.zip < /tmp/deploy_filelist.txt

   # ✅ 5. Upload and unzip deploy.zip on the remote host
   scp deploy.zip "$VM_TARGET:${REMOTE_PATH}/deploy.zip"
   rm deploy.zip
   ssh "$VM_TARGET" bash <<EOF
cd "${REMOTE_PATH}" || exit 1
unzip -o deploy.zip
rm deploy.zip
EOF

   ssh "$VM_TARGET" "mkdir -p ${REMOTE_PATH}/releases"
   scp -r releases/* "$VM_TARGET:${REMOTE_PATH}/releases/"

   ssh "$VM_TARGET" "cd ${REMOTE_PATH} && touch releases && rm -f releases/.images_pulled && sudo -S make"

   echo "✅ Deployment complete."
done