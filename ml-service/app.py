from flask import Flask, jsonify, request
import requests as http
import random
from flask_cors import CORS
import os
from dotenv import load_dotenv
load_dotenv()


app = Flask(__name__)
# Allow cross-origin requests from the frontend dev server
CORS(app)
backend_api = os.getenv("BACKEND_API", "http://backend:8080")

def products_url_from_backend(base: str) -> str:
    base = base.strip()
    if not base.startswith(("http://", "https://")):
        raise ValueError(f"BACKEND_API must start with http:// or https://, got: {base!r}")
    return f"{base.rstrip('/')}/products"

@app.get("/health")
def health():
    return jsonify({"status": "ok", "service": "ml-service"})

@app.get("/recommendations/<int:user_id>")
def recommendations(user_id: int):
    url = products_url_from_backend(backend_api)
    try:
        products = http.get(url, timeout=5)
        print(f"Fetched products from backend {url}: {products.status_code}")
        products.raise_for_status()
        catalog = [product.get("name") for product in products.json()]
        picks = random.sample(catalog, min(3, len(catalog)))
        return jsonify({"user_id": user_id, "recommendations": picks})
    except Exception as e:
        print("Error fetching products in ml-service:", e)
        return jsonify({"error": "failed_to_fetch_backend", "detail": str(e)}), 502

@app.get("/metrics")
def metrics():
    # Minimal placeholder so scraping does not fail in starter mode
    return "shopmicro_ml_requests_total 1\n", 200, {"Content-Type": "text/plain; version=0.0.4"}

@app.get("/recommendations_gen")
def recommendations_gen():
    url = products_url_from_backend(backend_api)
    try:
        products = http.get(url, timeout=5)
        print(f"Fetched products from backend {url}: {products.status_code}")
        products.raise_for_status()
        catalog = [product.get("name") for product in products.json()]
        picks = random.sample(catalog, min(3, len(catalog)))
        return jsonify({"recommendations": picks, "source_count": len(catalog)})
    except Exception as e:
        print("Error fetching products in ml-service:", e)
        return jsonify({"error": "failed_to_fetch_backend", "detail": str(e)}), 502

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)