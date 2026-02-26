import { useEffect, useState, useCallback } from "react";

const API_BASE = import.meta.env.VITE_API_BASE ?? "http://localhost:8080";
const ML_BASE  = import.meta.env.VITE_ML_BASE  ?? "http://localhost:5000";

export default function App() {
  const [products, setProducts] = useState([]);
  const [recs, setRecs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const [productsRes, recsRes] = await Promise.all([
        fetch(`${API_BASE}/products`),
        fetch(`${ML_BASE}/recommendations/42`)
      ]);

      if (!productsRes.ok || !recsRes.ok) {
        throw new Error('Failed to fetch data');
      }

      const productsData = await productsRes.json();
      const recsData = await recsRes.json();
      
      setProducts(productsData);
      setRecs(recsData.recommendations || []);
    } catch (err) {
      setError(err.message);
      console.error('Fetch error:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  if (loading) return <div className="loading">Loading ShopMicro...</div>;
  if (error) return <div className="error">Error: {error}</div>;

  return (
    <div className="app">
      <header className="header">
        <h1>🛒 ShopMicro</h1>
        <p>E-commerce Demo Platform</p>
      </header>
      
      <main className="main">
        <section className="products">
          <h2>Products</h2>
          <div className="product-grid">
            {products.map((p) => (
              <div key={p.id} className="product-card">
                <h3>{p.name}</h3>
                <div className="price">${p.price}</div>
              </div>
            ))}
          </div>
        </section>

        <section className="recommendations">
          <h2>Recommended for User 42</h2>
          <div className="recs-list">
            {recs.map((r, i) => (
              <span key={i} className="rec-item">{r}</span>
            ))}
          </div>
        </section>
      </main>

      <footer className="footer">
        <small>Backend: {API_BASE} | ML: {ML_BASE}</small>
      </footer>
    </div>
  );
}
