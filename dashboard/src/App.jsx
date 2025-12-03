import React, { useState, useEffect } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';

function App() {
  const [metrics, setMetrics] = useState({
    totalTransactions: 0,
    fraudDetected: 0,
    avgLatency: 0,
    accuracy: 0
  });

  const [recentTransactions, setRecentTransactions] = useState([]);

  useEffect(() => {
    // Fetch metrics from API
    fetchMetrics();
    const interval = setInterval(fetchMetrics, 5000);
    return () => clearInterval(interval);
  }, []);

  const fetchMetrics = async () => {
    // TODO: Connect to API Gateway endpoint
    // const response = await fetch('YOUR_API_ENDPOINT/metrics');
    // const data = await response.json();
    // setMetrics(data);
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial' }}>
      <h1>Fraud Detection Dashboard</h1>
      
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '20px', marginBottom: '30px' }}>
        <MetricCard title="Total Transactions" value={metrics.totalTransactions} />
        <MetricCard title="Fraud Detected" value={metrics.fraudDetected} color="red" />
        <MetricCard title="Avg Latency" value={`${metrics.avgLatency}ms`} />
        <MetricCard title="Accuracy" value={`${metrics.accuracy}%`} color="green" />
      </div>

      <h2>Recent Transactions</h2>
      <TransactionTable transactions={recentTransactions} />

      <h2>Risk Score Distribution</h2>
      <LineChart width={800} height={300} data={recentTransactions}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="timestamp" />
        <YAxis />
        <Tooltip />
        <Legend />
        <Line type="monotone" dataKey="risk_score" stroke="#8884d8" />
      </LineChart>
    </div>
  );
}

function MetricCard({ title, value, color = 'blue' }) {
  return (
    <div style={{ 
      padding: '20px', 
      border: '1px solid #ddd', 
      borderRadius: '8px',
      backgroundColor: '#f9f9f9'
    }}>
      <h3 style={{ margin: '0 0 10px 0', fontSize: '14px', color: '#666' }}>{title}</h3>
      <p style={{ margin: 0, fontSize: '32px', fontWeight: 'bold', color }}>{value}</p>
    </div>
  );
}

function TransactionTable({ transactions }) {
  return (
    <table style={{ width: '100%', borderCollapse: 'collapse', marginBottom: '30px' }}>
      <thead>
        <tr style={{ backgroundColor: '#f0f0f0' }}>
          <th style={{ padding: '10px', textAlign: 'left' }}>Transaction ID</th>
          <th style={{ padding: '10px', textAlign: 'left' }}>Amount</th>
          <th style={{ padding: '10px', textAlign: 'left' }}>Merchant</th>
          <th style={{ padding: '10px', textAlign: 'left' }}>Risk Score</th>
          <th style={{ padding: '10px', textAlign: 'left' }}>Status</th>
        </tr>
      </thead>
      <tbody>
        {transactions.map((txn, idx) => (
          <tr key={idx} style={{ borderBottom: '1px solid #ddd' }}>
            <td style={{ padding: '10px' }}>{txn.transaction_id}</td>
            <td style={{ padding: '10px' }}>${txn.amount}</td>
            <td style={{ padding: '10px' }}>{txn.merchant}</td>
            <td style={{ padding: '10px' }}>{txn.risk_score}</td>
            <td style={{ padding: '10px' }}>
              <span style={{ 
                padding: '4px 8px', 
                borderRadius: '4px',
                backgroundColor: txn.risk_score > 0.8 ? '#ffebee' : '#e8f5e9',
                color: txn.risk_score > 0.8 ? '#c62828' : '#2e7d32'
              }}>
                {txn.risk_score > 0.8 ? 'HIGH RISK' : 'NORMAL'}
              </span>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

export default App;
