import { useState } from "react";
import { RefreshCw, CheckCircle } from "lucide-react";
import { renewCards } from "../api/client";
import type { RenewalResult } from "../types";

export default function CardRenewal() {
  const [cutoffDays, setCutoffDays] = useState(60);
  const [result, setResult] = useState<RenewalResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleRenew = async () => {
    setLoading(true);
    setError("");
    try {
      const data = await renewCards(cutoffDays);
      setResult(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Renewal failed");
    }
    setLoading(false);
  };

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Card Renewal</h1>
        <p className="text-sm text-gray-500">PICRD400 - Renew cards expiring within cutoff window</p>
      </div>

      {error && <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>}

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 mb-6 max-w-lg">
        <h3 className="text-sm font-semibold text-gray-700 mb-4">Renewal Parameters</h3>
        <div className="space-y-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Cutoff Window (days)</label>
            <input type="number" min={1} max={365} value={cutoffDays} onChange={(e) => setCutoffDays(parseInt(e.target.value) || 60)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
            <p className="text-xs text-gray-400 mt-1">Cards with Active status expiring within this window will be renewed</p>
          </div>
          <button onClick={handleRenew} disabled={loading} className="w-full flex items-center justify-center gap-2 px-4 py-2.5 bg-red-700 text-white rounded-lg hover:bg-red-800 disabled:opacity-50 text-sm font-medium">
            <RefreshCw size={16} />
            {loading ? "Processing..." : "Run Renewal Batch"}
          </button>
        </div>
        <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
          <p className="text-xs text-blue-800 font-medium mb-1">How Renewal Works (PICRD400):</p>
          <ul className="text-xs text-blue-700 space-y-0.5">
            <li>• Finds all Active cards expiring within {cutoffDays} days</li>
            <li>• Generates new replacement card with 3-year expiry</li>
            <li>• Marks old card as Expired (EX)</li>
            <li>• New card inherits all customer/account data</li>
            <li>• Card sequence starts at 500+ for renewals</li>
          </ul>
        </div>
      </div>

      {result && (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-green-50 rounded-full"><CheckCircle size={24} className="text-green-600" /></div>
            <div>
              <p className="font-semibold text-gray-900">Renewal Complete</p>
              <p className="text-sm text-gray-500">{result.renewed_count} card(s) renewed</p>
            </div>
          </div>
          {result.message && <p className="text-sm text-gray-600 mb-4">{result.message}</p>}
          {result.renewal_pairs && result.renewal_pairs.length > 0 && (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-gray-50 border-b">
                  <tr>
                    <th className="text-left py-2 px-3 font-medium text-gray-500">Old Card</th>
                    <th className="text-left py-2 px-3 font-medium text-gray-500">New Card</th>
                    <th className="text-left py-2 px-3 font-medium text-gray-500">New Expiry</th>
                  </tr>
                </thead>
                <tbody>
                  {result.renewal_pairs.map((pair, i) => (
                    <tr key={i} className="border-b border-gray-50">
                      <td className="py-2 px-3 font-mono text-xs line-through text-gray-400">{pair.old_card_number}</td>
                      <td className="py-2 px-3 font-mono text-xs text-green-700 font-medium">{pair.new_card_number}</td>
                      <td className="py-2 px-3 text-xs">{pair.new_expiry}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
