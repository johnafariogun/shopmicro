#!/usr/bin/env bash
# setup-nodes.sh
# ──────────────────────────────────────────────────────────────────────────────
# Run this ONCE against your k3s cluster before deploying any manifests.
# It labels and taints the 3 worker nodes to match the scheduling strategy
# defined in the k8s/ manifests.
#
# Node layout:
#   worker-1  →  role=data      (postgres + redis)   tainted: data-only=true:NoSchedule
#   worker-2  →  role=app       (backend + ml-service)
#   worker-3  →  role=frontend  (frontend + ingress)
#
# Usage:
#   1. Edit NODE_DATA / NODE_APP / NODE_FRONTEND below to match your actual
#      node names (run: kubectl get nodes  to find them).
#   2. chmod +x setup-nodes.sh && ./setup-nodes.sh
#
# To undo everything this script does:
#   kubectl label node $NODE_DATA role-
#   kubectl taint node $NODE_DATA data-only-
#   kubectl label node $NODE_APP role-
#   kubectl label node $NODE_FRONTEND role-
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── EDIT THESE to match your node names ──────────────────────────────────────
NODE_DATA="${NODE_DATA:-worker-1}"
NODE_APP="${NODE_APP:-worker-2}"
NODE_FRONTEND="${NODE_FRONTEND:-worker-3}"
# ─────────────────────────────────────────────────────────────────────────────

echo "==> Verifying cluster connectivity..."
kubectl cluster-info --request-timeout=5s

echo ""
echo "==> Nodes found:"
kubectl get nodes -o wide
echo ""

# ── Data node ─────────────────────────────────────────────────────────────────
echo "==> Labelling $NODE_DATA as role=data..."
kubectl label node "$NODE_DATA" role=data --overwrite

echo "==> Tainting $NODE_DATA with data-only=true:NoSchedule..."
# The taint prevents any pod from landing here unless it explicitly tolerates it.
# postgres and redis both carry the matching toleration.
kubectl taint node "$NODE_DATA" data-only=true:NoSchedule --overwrite

# ── App node ──────────────────────────────────────────────────────────────────
echo "==> Labelling $NODE_APP as role=app..."
kubectl label node "$NODE_APP" role=app --overwrite

# ── Frontend node ─────────────────────────────────────────────────────────────
echo "==> Labelling $NODE_FRONTEND as role=frontend..."
kubectl label node "$NODE_FRONTEND" role=frontend --overwrite

# ── Verify ────────────────────────────────────────────────────────────────────
echo ""
echo "==> Node labels and taints applied. Current state:"
kubectl get nodes -o custom-columns=\
"NAME:.metadata.name,\
ROLE:.metadata.labels.role,\
TAINTS:.spec.taints[*].key"

echo ""
echo "==> Done. You can now apply the k8s manifests:"
echo "    kubectl apply -f k8s/namespace.yaml"
echo "    kubectl create secret generic shopmicro-secrets \\"
echo "      --namespace=shopmicro \\"
echo "      --from-literal=POSTGRES_DB=shopmicro \\"
echo "      --from-literal=POSTGRES_USER=postgres \\"
echo "      --from-literal=POSTGRES_PASSWORD=<your-password>"
echo "    kubectl apply -k k8s/"
