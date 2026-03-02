# Disaster Recovery & Backup Strategy

This guide outlines the data durability, backup, and restoration procedures for all stateful components within the ShopMicro platform.

## 1. PostgreSQL (Primary Datastore)

**State:** Persistent (Source of Truth)
**Strategy:** Daily Automated Snapshots + On-Demand SQL Dumps.

### 💾 Backup Strategy

**A. Manual Backup (pg_dump)**
Perform a manual, point-in-time backup of the `shopmicro` database before major application upgrades:

```bash
# 1. Get the Postgres pod name
POD_NAME=$(kubectl get pods -l app=postgres -n shopmicro -o jsonpath='{.items[0].metadata.name}')

# 2. Execute pg_dump and save the SQL file locally to your machine
kubectl exec $POD_NAME -n shopmicro -- pg_dump -U postgres shopmicro > shopmicro_backup_$(date +%Y%m%d).sql

```

**B. Automated Backups (Infrastructure Level)**
Since the cluster is hosted on AWS EC2, the Postgres `PersistentVolumeClaim` (PVC) is backed by an AWS EBS volume.

* We utilize **AWS Data Lifecycle Manager (DLM)** or **AWS Backup** to take automated daily snapshots of the specific EBS volume tagged with `k8s-app: postgres`.
* Retention policy is set to 30 days.

### 🔄 Restore Procedure

**A. Restore from SQL Dump**
To restore data directly into a running Postgres instance (e.g., recovering from accidental data deletion):

```bash
# 1. Copy the local backup file into the running pod
kubectl cp shopmicro_backup.sql shopmicro/$POD_NAME:/tmp/backup.sql

# 2. Drop existing connections and restore the database
kubectl exec $POD_NAME -n shopmicro -- psql -U postgres -d postgres -c "DROP DATABASE shopmicro WITH (FORCE);"
kubectl exec $POD_NAME -n shopmicro -- psql -U postgres -d postgres -c "CREATE DATABASE shopmicro;"
kubectl exec $POD_NAME -n shopmicro -- psql -U postgres -d shopmicro -f /tmp/backup.sql

```

**B. Restore from AWS EBS Snapshot**
To recover from a complete node or volume failure:

1. Locate the latest EBS snapshot in the AWS Console.
2. Create a new EBS volume from that snapshot in the same Availability Zone as your worker node.
3. Update the `k8s/postgres.yaml` PersistentVolume definition to bind to the new EBS Volume ID.
4. Re-apply the manifest: `kubectl apply -f k8s/postgres.yaml`.

### ✅ Verification

After any restoration, verify data integrity by checking the core tables:

```bash
kubectl exec $POD_NAME -n shopmicro -- psql -U postgres shopmicro -c "SELECT count(*) FROM products;"

```

---

## 2. Redis (Application Cache)

**State:** Ephemeral / Recoverable
**Strategy:** Let it crash (No strict backup required).

Because Redis is strictly used as a read-through cache for the product catalog, **we do not back it up**. If the Redis pod crashes or is deleted, Kubernetes will spin up a fresh pod with an empty cache. The Node.js backend is programmed to gracefully handle cache misses and will automatically repopulate Redis from Postgres upon the next user request.

**Emergency Cache Flush (Manual):**
If stale data is stuck in the cache, you can manually wipe it without restarting the pod:

```bash
REDIS_POD=$(kubectl get pods -l app=redis -n shopmicro -o jsonpath='{.items[0].metadata.name}')
kubectl exec $REDIS_POD -n shopmicro -- redis-cli FLUSHALL

```

---

## 3. Loki & Tempo (Observability Data)

**State:** Ephemeral (Currently using `emptyDir`)
**Strategy:** Infrastructure Redeployment.

Currently, Loki (Logs) and Tempo (Traces) are configured in their Kubernetes manifests to use `emptyDir: {}` for storage. This means their data is tied directly to the lifecycle of the pod. **If the worker node restarts, historical logs and traces are permanently lost.** *For the current scope of ShopMicro, this is acceptable as observability data is used for real-time debugging.* ***
