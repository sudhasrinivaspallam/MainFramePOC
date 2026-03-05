import { useState } from "react";
import { CheckCircle, Search } from "lucide-react";
import { fetchCards, activateCard } from "../api/client";
import type { Card } from "../types";

export default function CardActivation() {
  const [cards, setCards] = useState<Card[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [activating, setActivating] = useState<string | null>(null);
  const [pinOffset, setPinOffset] = useState("");
  const [customerId, setCustomerId] = useState("");

  const loadNewCards = async () => {
    setLoading(true);
    try {
      const data = await fetchCards("NW");
      setCards(data);
      setError("");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load cards");
    }
    setLoading(false);
  };

  const handleActivate = async (card: Card) => {
    if (!customerId.trim()) {
      setError("Customer ID is required for activation");
      return;
    }
    setActivating(card.card_number);
    setError("");
    setSuccess("");
    try {
      await activateCard(card.card_number, {
        customer_id: customerId || card.customer_id,
        pin_offset: pinOffset || "1234",
        activation_channel: "OL",
      });
      setSuccess(`Card ${card.card_number} activated successfully`);
      await loadNewCards();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Activation failed");
    }
    setActivating(null);
  };

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Card Activation</h1>
        <p className="text-sm text-gray-500">PICRD200 - Activate new cards (NW → AC)</p>
      </div>

      {error && <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>}
      {success && <div className="mb-4 p-3 bg-green-50 border border-green-200 rounded-lg text-green-700 text-sm flex items-center gap-2"><CheckCircle size={16} />{success}</div>}

      {/* Activation Form */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 mb-6 max-w-lg">
        <h3 className="text-sm font-semibold text-gray-700 mb-4">Activation Parameters</h3>
        <div className="space-y-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Customer ID *</label>
            <input type="text" maxLength={10} value={customerId} onChange={(e) => setCustomerId(e.target.value)} placeholder="Enter customer ID to verify" className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">PIN Offset</label>
            <input type="text" maxLength={4} value={pinOffset} onChange={(e) => setPinOffset(e.target.value)} placeholder="4-digit PIN offset" className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          </div>
          <button onClick={loadNewCards} disabled={loading} className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-red-700 text-white rounded-lg hover:bg-red-800 disabled:opacity-50 text-sm font-medium">
            <Search size={16} />
            {loading ? "Loading..." : "Find Cards Pending Activation"}
          </button>
        </div>
      </div>

      {/* Cards List */}
      {cards.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="px-5 py-3 bg-gray-50 border-b text-sm font-semibold text-gray-700">
            Cards Pending Activation ({cards.length})
          </div>
          <div className="divide-y">
            {cards.map((card) => (
              <div key={card.card_number} className="px-5 py-4 flex items-center justify-between hover:bg-gray-50">
                <div>
                  <p className="font-mono text-sm font-medium">{card.card_number.replace(/(.{4})/g, "$1 ").trim()}</p>
                  <p className="text-xs text-gray-500">{card.first_name} {card.last_name} | {card.customer_id} | {card.card_type === "DB" ? "Debit" : "Prepaid"}</p>
                </div>
                <button
                  onClick={() => handleActivate(card)}
                  disabled={activating === card.card_number}
                  className="px-4 py-1.5 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 text-sm font-medium"
                >
                  {activating === card.card_number ? "Activating..." : "Activate"}
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {cards.length === 0 && !loading && (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-8 text-center text-gray-400">
          <CheckCircle size={32} className="mx-auto mb-2" />
          <p className="text-sm">Click "Find Cards" to load cards pending activation</p>
        </div>
      )}
    </div>
  );
}
