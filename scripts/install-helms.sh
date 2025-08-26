#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#==========================================
# SETUP NGINX INGRESS CONTROLLER
# =========================================

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --version 4.10.1 \
  --set controller.allowSnippetAnnotations=true
  
#==========================================
# SETUP NEXTCLOUD
# =========================================

$SCRIPT_DIR/../pkl eval $SCRIPT_DIR/../cluster/demo/helms/nextcloud.pkl -o $SCRIPT_DIR/../storage/tmp/pkl-output/demo/helms/nextcloud.yaml -f yaml
helm repo add nextcloud https://nextcloud.github.io/helm/
helm repo update
#helm upgrade --install nextcloud nextcloud/nextcloud \
#  -f $SCRIPT_DIR/../storage/tmp/pkl-output/demo/helms/nextcloud.yaml \
#  --namespace demo \
#  --create-namespace


#==========================================
# SETUP CERT-MANAGER
# =========================================

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.0 \
  --set installCRDs=true