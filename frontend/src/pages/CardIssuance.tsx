import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { CreditCard, CheckCircle } from "lucide-react";
import { issueCard } from "../api/client";
import type { Card } from "../types";

export default function CardIssuance() {
  const navigate = useNavigate();
  const [form, setForm] = useState({
    card_type: "DB", account_number: "", customer_id: "",
    first_name: "", last_name: "", addr_line1: "", addr_line2: "",
    city: "", state: "", zip_code: "", daily_limit: "1000.00",
    available_balance: "0.00", branch_code: "",
  });
  const [result, setResult] = useState<Card | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const card = await issueCard({
        ...form,
        daily_limit: parseFloat(form.daily_limit),
        available_balance: parseFloat(form.available_balance),
      });
      setResult(card);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to issue card");
    }
    setLoading(false);
  };

  const update = (field: string, value: string) =>
    setForm((prev) => ({ ...prev, [field]: value }));

  if (result) {
    return (
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-6">Card Issued Successfully</h1>
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 max-w-lg">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-green-50 rounded-full"><CheckCircle size={24} className="text-green-600" /></div>
            <div>
              <p className="font-semibold text-gray-900">New Card Created</p>
              <p className="text-sm text-gray-500">Status: New (NW)</p>
            </div>
          </div>
          <div className="bg-gray-50 rounded-lg p-4 mb-4 font-mono text-center text-xl tracking-widest">
            {result.card_number.replace(/(.{4})/g, "$1 ").trim()}
          </div>
          <dl className="space-y-2 text-sm">
            <div className="flex justify-between"><dt className="text-gray-500">Customer</dt><dd className="font-medium">{result.first_name} {result.last_name}</dd></div>
            <div className="flex justify-between"><dt className="text-gray-500">Type</dt><dd>{result.card_type === "DB" ? "Debit" : "Prepaid"}</dd></div>
            <div className="flex justify-between"><dt className="text-gray-500">Expiry</dt><dd>{result.expiry_date}</dd></div>
            <div className="flex justify-between"><dt className="text-gray-500">Daily Limit</dt><dd>${result.daily_limit.toFixed(2)}</dd></div>
          </dl>
          <div className="flex gap-3 mt-6">
            <button onClick={() => navigate(`/cards/${result.card_number}`)} className="flex-1 px-4 py-2 bg-red-700 text-white rounded-lg hover:bg-red-800 text-sm font-medium">View Card</button>
            <button onClick={() => { setResult(null); setForm({ ...form, account_number: "", customer_id: "", first_name: "", last_name: "" }); }} className="flex-1 px-4 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 text-sm">Issue Another</button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Card Issuance</h1>
        <p className="text-sm text-gray-500">PICRD100 - Issue new debit/prepaid cards with Luhn validation</p>
      </div>
      {error && <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>}
      <form onSubmit={handleSubmit} className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 max-w-2xl">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Card Type *</label>
            <select value={form.card_type} onChange={(e) => update("card_type", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500">
              <option value="DB">Debit</option>
              <option value="PP">Prepaid</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Account Number *</label>
            <input type="text" required maxLength={12} value={form.account_number} onChange={(e) => update("account_number", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Customer ID *</label>
            <input type="text" required maxLength={10} value={form.customer_id} onChange={(e) => update("customer_id", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">First Name *</label>
            <input type="text" required maxLength={25} value={form.first_name} onChange={(e) => update("first_name", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Last Name *</label>
            <input type="text" required maxLength={25} value={form.last_name} onChange={(e) => update("last_name", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Address Line 1</label>
            <input type="text" maxLength={40} value={form.addr_line1} onChange={(e) => update("addr_line1", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">City</label>
            <input type="text" maxLength={25} value={form.city} onChange={(e) => update("city", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">State</label>
              <input type="text" maxLength={2} value={form.state} onChange={(e) => update("state", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">ZIP</label>
              <input type="text" maxLength={10} value={form.zip_code} onChange={(e) => update("zip_code", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Daily Limit ($)</label>
            <input type="number" step="0.01" min="0" value={form.daily_limit} onChange={(e) => update("daily_limit", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Initial Balance ($)</label>
            <input type="number" step="0.01" min="0" value={form.available_balance} onChange={(e) => update("available_balance", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Branch Code</label>
            <input type="text" maxLength={6} value={form.branch_code} onChange={(e) => update("branch_code", e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          </div>
        </div>
        <button type="submit" disabled={loading} className="mt-6 w-full flex items-center justify-center gap-2 px-4 py-2.5 bg-red-700 text-white rounded-lg hover:bg-red-800 disabled:opacity-50 text-sm font-medium">
          <CreditCard size={16} />
          {loading ? "Issuing..." : "Issue Card"}
        </button>
      </form>
    </div>
  );
}
