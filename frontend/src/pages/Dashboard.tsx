import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  CreditCard,
  ArrowRightLeft,
  AlertTriangle,
  CheckCircle,
  TrendingUp,
  PlayCircle,
} from "lucide-react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from "recharts";
import { fetchDashboardStats, loadSampleData } from "../api/client";
import type { DashboardStats } from "../types";
import { STATUS_LABELS } from "../types";

const PIE_COLORS = ["#16a34a", "#3b82f6", "#ef4444", "#f97316", "#6b7280", "#8b5cf6"];

export default function Dashboard() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = async () => {
    setLoading(true);
    try {
      const data = await fetchDashboardStats();
      setStats(data);
      setError("");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load dashboard");
    }
    setLoading(false);
  };

  const handleLoadSample = async () => {
    try {
      await loadSampleData();
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load sample data");
    }
  };

  useEffect(() => {
    load();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-red-700" />
      </div>
    );
  }

  const cardStatusData = stats
    ? [
        { name: "Active", value: stats.active_cards, color: "#16a34a" },
        { name: "New", value: stats.new_cards, color: "#3b82f6" },
        { name: "Blocked", value: stats.blocked_cards, color: "#ef4444" },
        { name: "Expired", value: stats.expired_cards, color: "#f97316" },
        { name: "Closed", value: stats.closed_cards, color: "#6b7280" },
      ].filter((d) => d.value > 0)
    : [];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-sm text-gray-500">
            Plastic Issuance & Settlement System Overview
          </p>
        </div>
        {stats && stats.total_cards === 0 && (
          <button
            onClick={handleLoadSample}
            className="flex items-center gap-2 px-4 py-2 bg-red-700 text-white rounded-lg hover:bg-red-800 transition-colors text-sm font-medium"
          >
            <PlayCircle size={16} />
            Load Sample Data
          </button>
        )}
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle size={16} />
          {error}
        </div>
      )}

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">Total Cards</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {stats?.total_cards || 0}
              </p>
            </div>
            <div className="p-3 bg-blue-50 rounded-lg">
              <CreditCard size={24} className="text-blue-600" />
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">Active Cards</p>
              <p className="text-2xl font-bold text-green-600 mt-1">
                {stats?.active_cards || 0}
              </p>
            </div>
            <div className="p-3 bg-green-50 rounded-lg">
              <CheckCircle size={24} className="text-green-600" />
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">
                Settlement Txns
              </p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {stats?.total_settlement_txns || 0}
              </p>
            </div>
            <div className="p-3 bg-purple-50 rounded-lg">
              <ArrowRightLeft size={24} className="text-purple-600" />
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">
                Settlement Amount
              </p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                ${(stats?.total_settlement_amount || 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}
              </p>
            </div>
            <div className="p-3 bg-yellow-50 rounded-lg">
              <TrendingUp size={24} className="text-yellow-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* Card Status Distribution */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <h3 className="text-sm font-semibold text-gray-700 mb-4">
            Card Status Distribution
          </h3>
          {cardStatusData.length > 0 ? (
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={cardStatusData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={90}
                    dataKey="value"
                    label={({ name, value }) => `${name}: ${value}`}
                  >
                    {cardStatusData.map((_, index) => (
                      <Cell
                        key={index}
                        fill={PIE_COLORS[index % PIE_COLORS.length]}
                      />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <div className="h-64 flex items-center justify-center text-gray-400 text-sm">
              No card data available
            </div>
          )}
        </div>

        {/* Card Counts Bar Chart */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
          <h3 className="text-sm font-semibold text-gray-700 mb-4">
            Cards by Status
          </h3>
          {stats && stats.total_cards > 0 ? (
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={cardStatusData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="value" fill="#b91c1c" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <div className="h-64 flex items-center justify-center text-gray-400 text-sm">
              No card data available
            </div>
          )}
        </div>
      </div>

      {/* Recent Cards */}
      {stats && stats.recent_cards.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-semibold text-gray-700">
              Recent Cards
            </h3>
            <Link
              to="/cards"
              className="text-xs text-red-700 hover:text-red-800 font-medium"
            >
              View All
            </Link>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100">
                  <th className="text-left py-2 px-3 font-medium text-gray-500">
                    Card Number
                  </th>
                  <th className="text-left py-2 px-3 font-medium text-gray-500">
                    Customer
                  </th>
                  <th className="text-left py-2 px-3 font-medium text-gray-500">
                    Status
                  </th>
                  <th className="text-right py-2 px-3 font-medium text-gray-500">
                    Balance
                  </th>
                </tr>
              </thead>
              <tbody>
                {stats.recent_cards.map((card) => (
                  <tr
                    key={card.card_number}
                    className="border-b border-gray-50 hover:bg-gray-50"
                  >
                    <td className="py-2 px-3 font-mono text-xs">
                      <Link
                        to={`/cards/${card.card_number}`}
                        className="text-red-700 hover:underline"
                      >
                        {card.card_number}
                      </Link>
                    </td>
                    <td className="py-2 px-3">
                      {card.first_name} {card.last_name}
                    </td>
                    <td className="py-2 px-3">
                      <span
                        className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                          card.card_status === "AC"
                            ? "bg-green-100 text-green-800"
                            : card.card_status === "NW"
                            ? "bg-blue-100 text-blue-800"
                            : card.card_status === "BL"
                            ? "bg-red-100 text-red-800"
                            : "bg-gray-100 text-gray-800"
                        }`}
                      >
                        {STATUS_LABELS[card.card_status] || card.card_status}
                      </span>
                    </td>
                    <td className="py-2 px-3 text-right font-mono text-xs">
                      ${card.available_balance.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Quick Actions */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
        <h3 className="text-sm font-semibold text-gray-700 mb-4">
          Quick Actions
        </h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <Link
            to="/cards/issue"
            className="flex flex-col items-center gap-2 p-4 rounded-lg border border-gray-200 hover:border-red-300 hover:bg-red-50 transition-colors"
          >
            <CreditCard size={24} className="text-red-700" />
            <span className="text-xs font-medium text-gray-700">
              Issue Card
            </span>
          </Link>
          <Link
            to="/cards/activate"
            className="flex flex-col items-center gap-2 p-4 rounded-lg border border-gray-200 hover:border-red-300 hover:bg-red-50 transition-colors"
          >
            <CheckCircle size={24} className="text-red-700" />
            <span className="text-xs font-medium text-gray-700">
              Activate Card
            </span>
          </Link>
          <Link
            to="/settlement"
            className="flex flex-col items-center gap-2 p-4 rounded-lg border border-gray-200 hover:border-red-300 hover:bg-red-50 transition-colors"
          >
            <ArrowRightLeft size={24} className="text-red-700" />
            <span className="text-xs font-medium text-gray-700">
              Settlement
            </span>
          </Link>
          <Link
            to="/batch"
            className="flex flex-col items-center gap-2 p-4 rounded-lg border border-gray-200 hover:border-red-300 hover:bg-red-50 transition-colors"
          >
            <PlayCircle size={24} className="text-red-700" />
            <span className="text-xs font-medium text-gray-700">
              Run Pipeline
            </span>
          </Link>
        </div>
      </div>
    </div>
  );
}
