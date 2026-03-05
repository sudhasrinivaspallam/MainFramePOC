import { useEffect, useState } from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Layout from "./components/Layout";
import Dashboard from "./pages/Dashboard";
import CardList from "./pages/CardList";
import CardDetail from "./pages/CardDetail";
import CardIssuance from "./pages/CardIssuance";
import CardActivation from "./pages/CardActivation";
import CardStatus from "./pages/CardStatus";
import CardRenewal from "./pages/CardRenewal";
import Settlement from "./pages/Settlement";
import SettlementReports from "./pages/SettlementReports";
import BatchPipeline from "./pages/BatchPipeline";
import { checkConnection, setOfflineMode } from "./api/client";

export default function App() {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    checkConnection().then((connected) => {
      if (!connected) {
        setOfflineMode(true);
      }
      setReady(true);
    });
  }, []);

  if (!ready) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-red-700 mx-auto mb-4" />
          <p className="text-sm text-gray-500">Connecting to server...</p>
        </div>
      </div>
    );
  }

  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/cards" element={<CardList />} />
          <Route path="/cards/issue" element={<CardIssuance />} />
          <Route path="/cards/activate" element={<CardActivation />} />
          <Route path="/cards/status" element={<CardStatus />} />
          <Route path="/cards/renew" element={<CardRenewal />} />
          <Route path="/cards/:cardNumber" element={<CardDetail />} />
          <Route path="/settlement" element={<Settlement />} />
          <Route path="/settlement/reports" element={<SettlementReports />} />
          <Route path="/batch" element={<BatchPipeline />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  );
}
