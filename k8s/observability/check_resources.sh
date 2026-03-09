#!/bin/bash

for node in $(kubectl get nodes -o name); do
  echo "===== $node ====="
  # 1. Added -it, --image, and --profile
  kubectl debug $node -it -q --image=busybox --profile=sysadmin -- chroot /host df -h | grep -E '^Filesystem|/$'
  
  # 2. Clean up the temporary debug pod that Kubernetes creates
  pod_name=$(kubectl get pods -A -l "kubectl.kubernetes.io/default-node-selector" -o name | grep node-debugger | head -n 1)
  kubectl delete $pod_name --ignore-not-found -q
  echo
done
