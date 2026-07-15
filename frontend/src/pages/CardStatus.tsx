import { useState } from "react";
import { Shield, Search, AlertTriangle } from "lucide-react";
import { fetchCard, updateCardStatus } from "../api/client";
import type { Card } from "../types";
import { STATUS_LABELS, STATUS_COLORS } from "../types";

const ACTIONS = [
  { code: "BL", label: "Block Card", desc: "Block an active card (AC → BL)", color: "bg-red-600" },
  { code: "UB", label: "Unblock Card", desc: "Unblock a blocked card (BL → AC)", color: "bg-green-600" },
  { code: "CL", label: "Close Card", desc: "Close card permanently (AC/BL/NW → CL)", color: "bg-gray-600" },
  { code: "HL", label: "Hotlist Card", desc: "Hotlist an active card (AC → BL)", color: "bg-orange-600" },
];

export default function CardStatus() {
  const [cardNumber, setCardNumber] = useState("");
  const [card, setCard] = useState<Card | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [reasonCode, setReasonCode] = useState("CUST");
  const [requestorId, setRequestorId] = useState("SYSTEM");
  const [processing, setProcessing] = useState(false);

  const handleSearch = async () => {
    if (!cardNumber.trim()) return;
    setLoading(true);
    setError("");
    setSuccess("");
    try {
      const c = await fetchCard(cardNumber.replace(/\s/g, ""));
      setCard(c);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Card not found");
      setCard(null);
    }
    setLoading(false);
  };

  const handleAction = async (actionCode: string) => {
    if (!card) return;
    setProcessing(true);
    setError("");
    setSuccess("");
    try {
      const updated = await updateCardStatus(card.card_number, {
        action_code: actionCode,
        reason_code: reasonCode,
        requestor_id: requestorId,
      });
      setCard(updated);
      setSuccess(`Card status updated to ${STATUS_LABELS[updated.card_status] || updated.card_status}`);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Status update failed");
    }
    setProcessing(false);
  };

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Card Status Update</h1>
        <p className="text-sm text-gray-500">PICRD300 - Block, Unblock, Close, or Hotlist cards</p>
      </div>

      {error && <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm flex items-center gap-2"><AlertTriangle size={16} />{error}</div>}
      {success && <div className="mb-4 p-3 bg-green-50 border border-green-200 rounded-lg text-green-700 text-sm">{success}</div>}

      {/* Search */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 mb-6 max-w-lg">
        <h3 className="text-sm font-semibold text-gray-700 mb-3">Find Card</h3>
        <div className="flex gap-2">
          <input type="text" placeholder="Enter card number" value={cardNumber} onChange={(e) => setCardNumber(e.target.value)} onKeyDown={(e) => e.key === "Enter" && handleSearch()} className="flex-1 px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500" />
          <button onClick={handleSearch} disabled={loading} className="px-4 py-2 bg-red-700 text-white rounded-lg hover:bg-red-800 disabled:opacity-50 text-sm font-medium">
            <Search size={16} />
          </button>
        </div>
      </div>

      {card && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Card Info */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
            <h3 className="text-sm font-semibold text-gray-700 mb-4 flex items-center gap-2">
              <Shield size={16} /> Card Information
            </h3>
            <dl className="space-y-2 text-sm">
              <div className="flex justify-between"><dt className="text-gray-500">Card Number</dt><dd className="font-mono">{card.card_number}</dd></div>
              <div className="flex justify-between"><dt className="text-gray-500">Customer</dt><dd>{card.first_name} {card.last_name}</dd></div>
              <div className="flex justify-between"><dt className="text-gray-500">Current Status</dt><dd><span className={`px-2 py-0.5 rounded-full text-xs font-medium ${STATUS_COLORS[card.card_status] || "bg-gray-100"}`}>{STATUS_LABELS[card.card_status] || card.card_status}</span></dd></div>
              <div className="flex justify-between"><dt className="text-gray-500">Expiry</dt><dd>{card.expiry_date}</dd></div>
            </dl>
            <div className="mt-4 pt-4 border-t space-y-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Reason Code</label>
                <select value={reasonCode} onChange={(e) => setReasonCode(e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm">
                  <option value="CUST">Customer Request</option>
                  <option value="FRAUD">Fraud Detected</option>
                  <option value="LOST">Card Lost</option>
                  <option value="STOLEN">Card Stolen</option>
                  <option value="ADMIN">Administrative</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Requestor ID</label>
                <input type="text" value={requestorId} onChange={(e) => setRequestorId(e.target.value)} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm" />
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
            <h3 className="text-sm font-semibold text-gray-700 mb-4">Available Actions</h3>
            <div className="space-y-3">
              {ACTIONS.map((action) => (
                <button key={action.code} onClick={() => handleAction(action.code)} disabled={processing} className={`w-full flex items-center justify-between p-3 rounded-lg text-white ${action.color} hover:opacity-90 disabled:opacity-50 transition-opacity`}>
                  <div className="text-left">
                    <p className="font-medium text-sm">{action.label}</p>
                    <p className="text-xs opacity-80">{action.desc}</p>
                  </div>
                  <Shield size={16} />
                </button>
              ))}
            </div>
            <div className="mt-4 p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
              <p className="text-xs text-yellow-800 font-medium mb-1">Valid Transitions (PICRD300):</p>
              <ul className="text-xs text-yellow-700 space-y-0.5">
                <li>• Active (AC) → Blocked/Hotlisted (BL), Closed</li>
                <li>• Blocked (BL) → Active (Unblock), Closed</li>
                <li>• New (NW) → Closed</li>
              </ul>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
