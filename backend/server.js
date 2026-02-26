const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");
const redis = require("redis");
const promClient = require("prom-client");
const register = new promClient.Registry();
register.setDefaultLabels({ app: "shopmicro-backend" });

const app = express();
app.use(express.json());
// Allow cross-origin requests from the frontend dev server
app.use(cors());

// Health check with startup probe readiness
app.get("/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    await cache.ping();
    res.json({ status: "ok", service: "backend", timestamp: Date.now() });
  } catch (err) {
    res.status(503).json({ status: "unhealthy", error: err.message });
  }
});

// Prometheus metrics endpoint
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

// Request counter
const httpRequestDuration = new promClient.Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status"],
  registers: [register],
});

app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer({ method: req.method, route: req.route?.path || req.path });
  res.on("finish", () => end({ status: res.statusCode }));
  next();
});

const pool = new Pool({
  host: process.env.DB_HOST || "postgres",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
  database: process.env.DB_NAME || "shopmicro",
  port: Number(process.env.DB_PORT || 5432),
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

const cache = redis.createClient({
  url: process.env.REDIS_URL || "redis://redis:6379",
});
cache.on("error", (err) => console.error("Redis Client Error", err));

// Cache hit/miss metrics
const cacheCounter = new promClient.Counter({
  name: "cache_operations_total",
  help: "Cache operations",
  labelNames: ["type"],
  registers: [register],
});

app.get("/products", async (req, res) => {
  const cacheKey = "products:all";
  try {
    const cached = await cache.get(cacheKey);
    if (cached) {
      cacheCounter.inc({ type: "hit" });
      return res.json(JSON.parse(cached));
    }
    
    cacheCounter.inc({ type: "miss" });
    const result = await pool.query("SELECT id, name, price FROM products ORDER BY id");
    await cache.setEx(cacheKey, 30, JSON.stringify(result.rows));
    res.json(result.rows);
  } catch (err) {
    console.error("Products error:", err);
    res.status(500).json({ error: "backend_error", detail: err.message });
  }
});

const PORT = process.env.PORT || 8080;

async function start() {
  try {
    await cache.connect();
    console.log("Redis connected");
  } catch (err) {
    console.error("Failed to connect to Redis:", err);
    process.exit(1);
  }

  app.listen(PORT, () => {
    console.log(`Backend listening on port ${PORT}`);
  });
}

start();
