#!/usr/bin/env bash

set -euo pipefail

OUTPUT_DIR="evidence-$(date +%Y%m%d-%H%M%S)"

usage() {
  echo "Usage: $0 collect | archive | clean"
  exit 1
}

collect() {
  echo "Collecting Kubernetes evidence..."
  mkdir -p "$OUTPUT_DIR"

  echo "Saving cluster info..."
  kubectl cluster-info > "$OUTPUT_DIR/cluster-info.txt"

  echo "Saving nodes..."
  kubectl get nodes -o wide > "$OUTPUT_DIR/nodes.txt"

  echo "Saving node details..."
  kubectl describe nodes > "$OUTPUT_DIR/node-describe.txt"

  echo "Saving pods..."
  kubectl get pods -A -o wide > "$OUTPUT_DIR/pods.txt"

  echo "Saving deployments..."
  kubectl get deployments -A > "$OUTPUT_DIR/deployments.txt"

  echo "Saving services..."
  kubectl get svc -A > "$OUTPUT_DIR/services.txt"

  echo "Saving events..."
  kubectl get events -A --sort-by=.metadata.creationTimestamp > "$OUTPUT_DIR/events.txt"

  echo "Saving kube-system pods..."
  kubectl get pods -n kube-system -o wide > "$OUTPUT_DIR/kube-system.txt"

  echo "Saving version info..."
  kubectl version > "$OUTPUT_DIR/version.txt"

  echo "Evidence collected in: $OUTPUT_DIR"
}

archive() {
  echo "Archiving evidence..."
  tar -czf "$OUTPUT_DIR.tar.gz" "$OUTPUT_DIR"
  echo "Archive created: $OUTPUT_DIR.tar.gz"
}

clean() {
  rm -rf evidence-* || true
  echo "Old evidence removed"
}

case "${1:-}" in
  collect)
    collect
    ;;
  archive)
    archive
    ;;
  clean)
    clean
    ;;
  *)
    usage
    ;;
esac