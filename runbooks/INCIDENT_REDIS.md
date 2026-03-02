### Incident Runbook: Redis Cache Failure (Latency Degradation)

**Severity:** P2 (High)
**Symptom:** Users report the product catalog is extremely slow to load. The `BackendLatencyDegradation` Prometheus alert fires because the 90th percentile response time has exceeded the 200ms SLO.

#### 🚩 Detection

* **Alert:** Prometheus fires `BackendLatencyDegradation` to the Alertmanager channel.
* **Metric Verification:** Grafana's PromQL `cache_operations_total` panel shows a sudden 100% drop in cache "hits" and a massive spike in cache "misses".
* **Manual Check:**
```bash
kubectl get pods -l app=redis -n shopmicro

```



#### 🛠️ Triage & Resolution

**Step 1: Check Pod Status and Memory Limits**
If the Redis pod is completely missing, stuck in `CrashLoopBackOff`, or shows `OOMKilled` (Out of Memory):

```bash
kubectl describe pod -l app=redis -n shopmicro

```

* **Error: `OOMKilled`:** Redis ran out of allocated RAM and the Kubernetes Linux kernel terminated it. We need to bump the memory limit in `redis.yaml`.
* **Error: `Evicted`:** The worker node ran out of disk space or memory, forcing the pod off the node.

**Step 2: Inspect Redis Logs**
If the pod says `Running` but isn't accepting connections, check the internal logs for connection exhaustion or corrupted memory states:

```bash
kubectl logs -l app=redis -n shopmicro --tail=50

```

**Step 3: Test Network Connectivity from Backend**
Verify the Node.js backend can successfully resolve the Redis service DNS:

```bash
BACKEND_POD=$(kubectl get pods -l app=backend -n shopmicro -o jsonpath='{.items[0].metadata.name}')
kubectl exec $BACKEND_POD -n shopmicro -- ping redis

```

**Step 4: Emergency Recovery**
If Redis is deadlocked or corrupted, the fastest way to restore the 200ms SLO is to nuke the pod and let Kubernetes spin up a fresh, empty cache:

```bash
# 1. Force restart the Redis pod
kubectl delete pod -l app=redis -n shopmicro

# 2. (Optional) Temporarily scale up the backend to handle the Postgres CPU load while the cache warms up
kubectl scale deployment backend --replicas=4 -n shopmicro

```

#### 📈 Post-Mortem

* **Root Cause Analysis:** Determine why Redis failed (e.g., insufficient memory limits, a traffic spike, or a network partition).
* **Action Items:** * Update `resources.limits.memory` in `k8s/redis.yaml` if it was an OOMKill.
* Implement Redis persistence (AOF/RDB) if we need to prevent a completely cold cache upon restart.
* Verify that the Prometheus Alertmanager successfully routed the alert to the on-call engineer.

