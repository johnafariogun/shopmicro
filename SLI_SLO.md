## Service Level Indicators (SLIs) and Objectives (SLOs)

This document defines the key performance indicators, targets, and automated alerts for the ShopMicro platform to ensure a highly available and responsive e-commerce experience.

### 1. Service Level Indicators (SLIs)

**SLI 1: Request Latency**

* **Definition:** The time it takes to process a successful HTTP request to the `backend` (e.g., `/products`) or the `ml-service` (e.g., `/recommendations`).
* **Measurement:** Percentage of HTTP requests that are completed in less than 200ms.
* **PromQL Template:**
```promql
sum(rate(http_request_duration_seconds_bucket{le="0.2", app=~"shopmicro-backend|shopmicro-ml"}[5m])) 
/ 
sum(rate(http_request_duration_seconds_count{app=~"shopmicro-backend|shopmicro-ml"}[5m]))

```



**SLI 2: Availability (Success Rate)**

* **Definition:** The proportion of successful requests compared to the total number of valid requests.
* **Measurement:** Total number of HTTP 2xx and 3xx responses divided by the total number of HTTP requests.
* **PromQL Template:**
```promql
sum(rate(http_requests_total{status=~"2..|3..", app=~"shopmicro-backend|shopmicro-ml"}[5m])) 
/ 
sum(rate(http_requests_total{app=~"shopmicro-backend|shopmicro-ml"}[5m]))

```



**SLI 3: Error Rate**

* **Definition:** The proportion of internal server errors (5xx) relative to the total number of requests.
* **Measurement:** Total number of HTTP 5xx responses divided by the total number of HTTP requests.
* **PromQL Template:**
```promql
sum(rate(http_requests_total{status=~"5..", app=~"shopmicro-backend|shopmicro-ml"}[5m])) 
/ 
sum(rate(http_requests_total{app=~"shopmicro-backend|shopmicro-ml"}[5m]))

```



### 2. Service Level Objectives (SLOs)

**SLO 1: Availability**

* **Target:** 99.5% of requests over a rolling 30-day window should be successful (non-5xx).
* **Rationale:** As an e-commerce platform, availability is critical for user trust and revenue. A 99.5% target provides an error budget of approximately 3.6 hours of allowed downtime per month. This balances the strict need for reliability with the agility required to perform frequent, zero-downtime rolling Kubernetes deployments.

**SLO 2: Latency**

* **Target:** 90% of requests to the backend and ML service should be completed in less than 200ms.
* **Rationale:** Page load speed directly impacts shopping conversion rates. The 200ms threshold ensures a snappy user experience, while targeting the 90th percentile accounts for occasional cold starts, cache misses to Postgres, or complex ML recommendation computations without failing the overall objective.

---

### 3. Actionable Alerts

To defend our SLOs, the following automated alerts are configured in Prometheus Alertmanager to page the engineering team when the Error Budget is actively at risk.

**Alert 1: High API Error Rate (Fast Burn)**

* **Trigger:** The backend error rate spikes above 5% for a sustained period of 5 minutes.
* **PromQL Template:**
```promql
rate(http_requests_total{app="shopmicro-backend", status=~"5.."}[5m]) 
/ 
rate(http_requests_total{app="shopmicro-backend"}[5m]) > 0.05

```


* **Action Plan:** 1. Query Grafana Loki (`{app="shopmicro-backend"} |= "error"`) for unhandled Node.js exceptions.
2. Check Postgres pod health and connection pool limits.
3. Roll back the most recent deployment if the spike correlates with a CI/CD release.

**Alert 2: Severe Latency Degradation (Slow Burn)**

* **Trigger:** The 90th percentile of request latency remains above the 200ms SLO threshold for 10 consecutive minutes.
* **PromQL Template:**
```promql
histogram_quantile(0.90, sum(rate(http_request_duration_seconds_bucket{app="shopmicro-backend"}[10m])) by (le)) > 0.200

```


* **Action Plan:**
1. Verify Redis cache hit/miss ratio in Grafana. A sudden drop in cache hits indicates Redis eviction or failure, forcing Postgres to handle the load.
2. Check Kubernetes `node_cpu_seconds_total` to determine if backend pods are hitting their CPU limits and requiring a replica scale-up.

