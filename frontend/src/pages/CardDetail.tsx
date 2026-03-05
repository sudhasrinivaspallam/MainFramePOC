import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { ArrowLeft, Clock, CreditCard } from "lucide-react";
import { fetchCard, fetchCardHistory } from "../api/client";
import type { Card, StatusHistory } from "../types";
import { STATUS_LABELS, STATUS_COLORS } from "../types";

export default function CardDetail() {
  const { cardNumber } = useParams<{ cardNumber: string }>();
  const [card, setCard] = useState<Card | null>(null);
  const [history, setHistory] = useState<StatusHistory[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!cardNumber) return;
    const load = async () => {
      setLoading(true);
      try {
        const [c, h] = await Promise.all([
          fetchCard(cardNumber),
          fetchCardHistory(cardNumber),
        ]);
        setCard(c);
        setHistory(h);
      } catch (e) {
        setError(e instanceof Error ? e.message : "Failed to load card");
      }
      setLoading(false);
    };
    load();
  }, [cardNumber]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-red-700" />
      </div>
    );
  }

  if (error || !card) {
    return (
      <div className="p-6">
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {error || "Card not found"}
        </div>
        <Link to="/cards" className="mt-4 inline-flex items-center gap-2 text-sm text-red-700 hover:underline">
          <ArrowLeft size={14} /> Back to Cards
        </Link>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center gap-3 mb-6">
        <Link to="/cards" className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
          <ArrowLeft size={18} className="text-gray-600" />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Card Details</h1>
          <p className="text-sm text-gray-500">PIONL100 - Card Inquiry</p>
        </div>
      </div>

      {/* Card Visual */}
      <div className="bg-gradient-to-br from-red-800 via-red-700 to-red-900 rounded-2xl p-6 text-white mb-6 max-w-md shadow-lg">
        <div className="flex items-center justify-between mb-8">
          <div className="w-10 h-7 bg-yellow-400 rounded-sm" />
          <span className="text-xs opacity-80">{card.card_type === "DB" ? "DEBIT" : "PREPAID"}</span>
        </div>
        <p className="font-mono text-xl tracking-widest mb-4">
          {card.card_number.replace(/(.{4})/g, "$1 ").trim()}
        </p>
        <div className="flex justify-between text-sm">
          <div>
            <p className="text-xs opacity-60">CARDHOLDER</p>
            <p className="font-medium">{card.first_name} {card.last_name}</p>
          </div>
          <div className="text-right">
            <p className="text-xs opacity-60">EXPIRES</p>
            <p className="font-medium">{card.expiry_date}</p>
          </div>
        </div>
      </div>

      {/* Details Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <h3 className="text-sm font-semibold text-gray-700 mb-4 flex items-center gap-2">
            <CreditCard size={16} /> Card Information
          </h3>
          <dl className="space-y-3">
            {[
              ["Card Number", card.card_number],
              ["Card Type", card.card_type === "DB" ? "Debit" : "Prepaid"],
              ["Account Number", card.account_number],
              ["Customer ID", card.customer_id],
              ["Status", null],
              ["Issue Date", card.issue_date],
              ["Expiry Date", card.expiry_date],
              ["Activation Date", card.activation_date || "N/A"],
              ["Branch Code", card.branch_code || "N/A"],
            ].map(([label, value]) => (
              <div key={label as string} className="flex justify-between py-1 border-b border-gray-50">
                <dt className="text-sm text-gray-500">{label}</dt>
                <dd className="text-sm font-medium text-gray-900">
                  {label === "Status" ? (
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${STATUS_COLORS[card.card_status] || "bg-gray-100"}`}>
                      {STATUS_LABELS[card.card_status] || card.card_status}
                    </span>
                  ) : (
                    value
                  )}
                </dd>
              </div>
            ))}
          </dl>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <h3 className="text-sm font-semibold text-gray-700 mb-4">Customer & Financial</h3>
          <dl className="space-y-3">
            {[
              ["Name", `${card.first_name} ${card.last_name}`],
              ["Address", card.addr_line1 || "N/A"],
              ["City, State", `${card.city || ""}, ${card.state || ""} ${card.zip_code || ""}`],
              ["Daily Limit", `$${card.daily_limit.toLocaleString(undefined, { minimumFractionDigits: 2 })}`],
              ["Available Balance", `$${card.available_balance.toLocaleString(undefined, { minimumFractionDigits: 2 })}`],
              ["PIN Offset", card.pin_offset || "N/A"],
              ["CVV", card.cvv_value ? "***" : "N/A"],
              ["Last Used", card.last_used_date || "N/A"],
              ["Created", card.created_timestamp || "N/A"],
            ].map(([label, value]) => (
              <div key={label as string} className="flex justify-between py-1 border-b border-gray-50">
                <dt className="text-sm text-gray-500">{label}</dt>
                <dd className="text-sm font-medium text-gray-900">{value}</dd>
              </div>
            ))}
          </dl>
        </div>
      </div>

      {/* Status History */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
        <h3 className="text-sm font-semibold text-gray-700 mb-4 flex items-center gap-2">
          <Clock size={16} /> Status History
        </h3>
        {history.length === 0 ? (
          <p className="text-sm text-gray-400">No history available</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="text-left py-2 px-3 font-medium text-gray-500">Date</th>
                  <th className="text-left py-2 px-3 font-medium text-gray-500">Previous</th>
                  <th className="text-left py-2 px-3 font-medium text-gray-500">New</th>
                  <th className="text-left py-2 px-3 font-medium text-gray-500">Reason</th>
                  <th className="text-left py-2 px-3 font-medium text-gray-500">Requestor</th>
                </tr>
              </thead>
              <tbody>
                {history.map((h) => (
                  <tr key={h.history_id} className="border-b border-gray-50">
                    <td className="py-2 px-3 text-xs">{h.status_date}</td>
                    <td className="py-2 px-3">
                      <span className={`px-2 py-0.5 rounded-full text-xs ${STATUS_COLORS[h.previous_status] || "bg-gray-100"}`}>
                        {STATUS_LABELS[h.previous_status] || h.previous_status || "—"}
                      </span>
                    </td>
                    <td className="py-2 px-3">
                      <span className={`px-2 py-0.5 rounded-full text-xs ${STATUS_COLORS[h.new_status] || "bg-gray-100"}`}>
                        {STATUS_LABELS[h.new_status] || h.new_status}
                      </span>
                    </td>
                    <td className="py-2 px-3 text-xs">{h.reason_code || "—"}</td>
                    <td className="py-2 px-3 text-xs">{h.requestor_id || "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
