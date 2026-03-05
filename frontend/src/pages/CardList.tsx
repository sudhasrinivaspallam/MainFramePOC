import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Search, CreditCard, RefreshCw } from "lucide-react";
import { fetchCards, searchCards } from "../api/client";
import type { Card } from "../types";
import { STATUS_LABELS, STATUS_COLORS } from "../types";

export default function CardList() {
  const [cards, setCards] = useState<Card[]>([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [error, setError] = useState("");

  const load = async () => {
    setLoading(true);
    try {
      const data = statusFilter
        ? await fetchCards(statusFilter)
        : await fetchCards();
      setCards(data);
      setError("");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load cards");
    }
    setLoading(false);
  };

  const handleSearch = async () => {
    if (!query.trim()) {
      load();
      return;
    }
    setLoading(true);
    try {
      const data = await searchCards(query);
      setCards(data);
      setError("");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Search failed");
    }
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, [statusFilter]);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Card Inquiry</h1>
          <p className="text-sm text-gray-500">
            PIONL100 - Search and view card details
          </p>
        </div>
        <button
          onClick={load}
          className="flex items-center gap-2 px-3 py-2 text-sm bg-white border border-gray-200 rounded-lg hover:bg-gray-50"
        >
          <RefreshCw size={14} />
          Refresh
        </button>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
          {error}
        </div>
      )}

      {/* Search & Filter */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-4 mb-6">
        <div className="flex flex-col md:flex-row gap-3">
          <div className="flex-1 relative">
            <Search
              size={16}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"
            />
            <input
              type="text"
              placeholder="Search by card number, customer ID, or name..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSearch()}
              className="w-full pl-9 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500"
          >
            <option value="">All Statuses</option>
            <option value="NW">New</option>
            <option value="AC">Active</option>
            <option value="BL">Blocked</option>
            <option value="EX">Expired</option>
            <option value="CL">Closed</option>
          </select>
          <button
            onClick={handleSearch}
            className="px-4 py-2 bg-red-700 text-white rounded-lg hover:bg-red-800 text-sm font-medium"
          >
            Search
          </button>
        </div>
      </div>

      {/* Results */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-red-700" />
          </div>
        ) : cards.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-32 text-gray-400">
            <CreditCard size={32} className="mb-2" />
            <p className="text-sm">No cards found</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">
                    Card Number
                  </th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">
                    Type
                  </th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">
                    Customer
                  </th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">
                    Status
                  </th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">
                    Issue Date
                  </th>
                  <th className="text-left py-3 px-4 font-medium text-gray-500">
                    Expiry Date
                  </th>
                  <th className="text-right py-3 px-4 font-medium text-gray-500">
                    Balance
                  </th>
                  <th className="text-right py-3 px-4 font-medium text-gray-500">
                    Daily Limit
                  </th>
                </tr>
              </thead>
              <tbody>
                {cards.map((card) => (
                  <tr
                    key={card.card_number}
                    className="border-b border-gray-50 hover:bg-gray-50 transition-colors"
                  >
                    <td className="py-3 px-4 font-mono text-xs">
                      <Link
                        to={`/cards/${card.card_number}`}
                        className="text-red-700 hover:underline font-medium"
                      >
                        {card.card_number.replace(/(.{4})/g, "$1 ").trim()}
                      </Link>
                    </td>
                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-700">
                        {card.card_type === "DB" ? "Debit" : "Prepaid"}
                      </span>
                    </td>
                    <td className="py-3 px-4">
                      <div className="font-medium text-gray-900">
                        {card.first_name} {card.last_name}
                      </div>
                      <div className="text-xs text-gray-400">
                        {card.customer_id}
                      </div>
                    </td>
                    <td className="py-3 px-4">
                      <span
                        className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                          STATUS_COLORS[card.card_status] || "bg-gray-100 text-gray-800"
                        }`}
                      >
                        {STATUS_LABELS[card.card_status] || card.card_status}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-xs text-gray-600">
                      {card.issue_date}
                    </td>
                    <td className="py-3 px-4 text-xs text-gray-600">
                      {card.expiry_date}
                    </td>
                    <td className="py-3 px-4 text-right font-mono text-xs">
                      ${card.available_balance.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                    </td>
                    <td className="py-3 px-4 text-right font-mono text-xs">
                      ${card.daily_limit.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <div className="px-4 py-3 bg-gray-50 border-t border-gray-100 text-xs text-gray-500">
          {cards.length} card(s) found
        </div>
      </div>
    </div>
  );
}
