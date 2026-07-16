import { useEffect, useState } from "react";
import { ArrowRightLeft, RefreshCw, PlayCircle, Calculator } from "lucide-react";
import {
  fetchSettlementTransactions,
  generateAndExtractSample,
  runMatching,
  calculateNetSettlement,
} from "../api/client";
import type { SettlementTransaction, MatchingResult, NetSettlementResult } from "../types";
import { SETTLE_STATUS_LABELS, SETTLE_STATUS_COLORS } from "../types";

export default function Settlement() {
  const [txns, setTxns] = useState<SettlementTransaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [networkFilter, setNetworkFilter] = useState("");
  const [matchResult, setMatchResult] = useState<MatchingResult | null>(null);
  const [netResult, setNetResult] = useState<NetSettlementResult | null>(null);
  const [processing, setProcessing] = useState("");

  const load = async () => {
    setLoading(true);
    try {
      const data = await fetchSettlementTransactions(
        statusFilter || undefined,
        networkFilter || undefined
      );
      setTxns(data);
      setError("");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load transactions");
    }
    setLoading(false);
  };

  useEffect(() => { load(); }, [statusFilter, networkFilter]);

  const handleGenerateData = async () => {
    setProcessing("generate");
    setError("");
    try {
      const r = await generateAndExtractSample();
      setSuccess(`Generated & extracted: ${r.records_written} transactions`);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to generate data");
    }
    setProcessing("");
  };

  const handleMatch = async () => {
    setProcessing("match");
    setError("");
    try {
      const r = await runMatching();
      setMatchResult(r);
      setSuccess(`Matching complete: ${r.matched_count} matched, ${r.unmatched_settlement_count} unmatched, ${r.amount_mismatch_count} disputed`);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Matching failed");
    }
    setProcessing("");
  };

  const handleCalculate = async () => {
    setProcessing("calculate");
    setError("");
    try {
      const r = await calculateNetSettlement();
      setNetResult(r);
      setSuccess(`Net settlement calculated: $${r.grand_total_net_amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}`);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Calculation failed");
    }
    setProcessing("");
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Settlement</h1>
          <p className="text-sm text-gray-500">STLMT100-400 - Transaction extract, matching, & net settlement</p>
        </div>
        <button onClick={load} className="flex items-center gap-2 px-3 py-2 text-sm bg-white border border-gray-200 rounded-lg hover:bg-gray-50">
          <RefreshCw size={14} /> Refresh
        </button>
      </div>

      {error && <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>}
      {success && <div className="mb-4 p-3 bg-green-50 border border-green-200 rounded-lg text-green-700 text-sm">{success}</div>}

      {/* Pipeline Actions */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 mb-6">
        <h3 className="text-sm font-semibold text-gray-700 mb-3">Settlement Pipeline</h3>
        <div className="flex flex-wrap gap-3">
          <button onClick={handleGenerateData} disabled={!!processing} className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 text-sm font-medium">
            <PlayCircle size={16} />
            {processing === "generate" ? "Generating..." : "1. Generate & Extract (STLMT100)"}
          </button>
          <button onClick={handleMatch} disabled={!!processing} className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:opacity-50 text-sm font-medium">
            <ArrowRightLeft size={16} />
            {processing === "match" ? "Matching..." : "2. Run Matching (STLMT200)"}
          </button>
          <button onClick={handleCalculate} disabled={!!processing} className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 text-sm font-medium">
            <Calculator size={16} />
            {processing === "calculate" ? "Calculating..." : "3. Calculate Net (STLMT300)"}
          </button>
        </div>
      </div>

      {/* Matching Results */}
      {matchResult && (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 mb-6">
          <h3 className="text-sm font-semibold text-gray-700 mb-3">Matching Results (STLMT200)</h3>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            <div className="text-center p-3 bg-green-50 rounded-lg">
              <p className="text-xl font-bold text-green-700">{matchResult.matched_count}</p>
              <p className="text-xs text-green-600">Matched</p>
            </div>
            <div className="text-center p-3 bg-green-50 rounded-lg">
              <p className="text-xl font-bold text-green-700">${matchResult.matched_amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}</p>
              <p className="text-xs text-green-600">Matched Amount</p>
            </div>
            <div className="text-center p-3 bg-yellow-50 rounded-lg">
              <p className="text-xl font-bold text-yellow-700">{matchResult.unmatched_settlement_count}</p>
              <p className="text-xs text-yellow-600">Unmatched (Settle)</p>
            </div>
            <div className="text-center p-3 bg-orange-50 rounded-lg">
              <p className="text-xl font-bold text-orange-700">{matchResult.unmatched_acquirer_count}</p>
              <p className="text-xs text-orange-600">Unmatched (Acquirer)</p>
            </div>
            <div className="text-center p-3 bg-red-50 rounded-lg">
              <p className="text-xl font-bold text-red-700">{matchResult.amount_mismatch_count}</p>
              <p className="text-xs text-red-600">Disputed</p>
            </div>
          </div>
        </div>
      )}

      {/* Net Settlement Results */}
      {netResult && netResult.summaries.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 mb-6">
          <h3 className="text-sm font-semibold text-gray-700 mb-3">Net Settlement (STLMT300)</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="text-left py-2 px-3 font-medium text-gray-500">Network</th>
                  <th className="text-right py-2 px-3 font-medium text-gray-500">Txn Count</th>
                  <th className="text-right py-2 px-3 font-medium text-gray-500">Txn Amount</th>
                  <th className="text-right py-2 px-3 font-medium text-gray-500">Matched</th>
                  <th className="text-right py-2 px-3 font-medium text-gray-500">Fees (1.75%)</th>
                  <th className="text-right py-2 px-3 font-medium text-gray-500">Net Amount</th>
                  <th className="text-left py-2 px-3 font-medium text-gray-500">Status</th>
                </tr>
              </thead>
              <tbody>
                {netResult.summaries.map((s) => (
                  <tr key={s.network_id} className="border-b border-gray-50">
                    <td className="py-2 px-3 font-medium">{s.network_id}</td>
                    <td className="py-2 px-3 text-right">{s.total_txn_count}</td>
                    <td className="py-2 px-3 text-right font-mono">${s.total_txn_amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                    <td className="py-2 px-3 text-right">{s.matched_count}</td>
                    <td className="py-2 px-3 text-right font-mono">${s.total_fees.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                    <td className="py-2 px-3 text-right font-mono font-medium">${s.net_settle_amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                    <td className="py-2 px-3"><span className={`px-2 py-0.5 rounded-full text-xs ${s.recon_status === "BL" ? "bg-green-100 text-green-800" : "bg-yellow-100 text-yellow-800"}`}>{s.recon_status === "BL" ? "Balanced" : "Out of Balance"}</span></td>
                  </tr>
                ))}
              </tbody>
              <tfoot className="bg-gray-50 font-semibold">
                <tr>
                  <td className="py-2 px-3">TOTAL</td>
                  <td className="py-2 px-3 text-right">{netResult.grand_total_txn_count}</td>
                  <td className="py-2 px-3 text-right font-mono">${netResult.grand_total_txn_amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                  <td className="py-2 px-3 text-right">{netResult.grand_total_matched_count}</td>
                  <td className="py-2 px-3 text-right font-mono">${netResult.grand_total_fees.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                  <td className="py-2 px-3 text-right font-mono">${netResult.grand_total_net_amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                  <td className="py-2 px-3"></td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-4 mb-6">
        <div className="flex flex-wrap gap-3">
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="px-3 py-2 border border-gray-200 rounded-lg text-sm">
            <option value="">All Statuses</option>
            <option value="PE">Pending</option>
            <option value="MT">Matched</option>
            <option value="UM">Unmatched</option>
            <option value="DI">Disputed</option>
          </select>
          <select value={networkFilter} onChange={(e) => setNetworkFilter(e.target.value)} className="px-3 py-2 border border-gray-200 rounded-lg text-sm">
            <option value="">All Networks</option>
            <option value="VISA">VISA</option>
            <option value="MC">Mastercard</option>
            <option value="STAR">STAR</option>
          </select>
        </div>
      </div>

      {/* Transactions Table */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-red-700" />
          </div>
        ) : txns.length === 0 ? (
          <div className="p-8 text-center text-gray-400 text-sm">
            <ArrowRightLeft size={32} className="mx-auto mb-2" />
            No settlement transactions found. Click "Generate & Extract" to create sample data.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="text-left py-3 px-3 font-medium text-gray-500">Settle ID</th>
                  <th className="text-left py-3 px-3 font-medium text-gray-500">Txn ID</th>
                  <th className="text-left py-3 px-3 font-medium text-gray-500">Card</th>
                  <th className="text-left py-3 px-3 font-medium text-gray-500">Merchant</th>
                  <th className="text-left py-3 px-3 font-medium text-gray-500">Network</th>
                  <th className="text-right py-3 px-3 font-medium text-gray-500">Amount</th>
                  <th className="text-left py-3 px-3 font-medium text-gray-500">Status</th>
                  <th className="text-left py-3 px-3 font-medium text-gray-500">Txn Date</th>
                </tr>
              </thead>
              <tbody>
                {txns.map((txn) => (
                  <tr key={txn.settle_id} className="border-b border-gray-50 hover:bg-gray-50">
                    <td className="py-2 px-3 font-mono text-xs">{txn.settle_id}</td>
                    <td className="py-2 px-3 font-mono text-xs">{txn.txn_id}</td>
                    <td className="py-2 px-3 font-mono text-xs">{txn.card_number}</td>
                    <td className="py-2 px-3 text-xs">{txn.merchant_name}</td>
                    <td className="py-2 px-3 text-xs"><span className="px-2 py-0.5 rounded bg-gray-100 text-gray-700 font-medium">{txn.network_id}</span></td>
                    <td className="py-2 px-3 text-right font-mono text-xs">${txn.txn_amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                    <td className="py-2 px-3"><span className={`px-2 py-0.5 rounded-full text-xs font-medium ${SETTLE_STATUS_COLORS[txn.settle_status] || "bg-gray-100"}`}>{SETTLE_STATUS_LABELS[txn.settle_status] || txn.settle_status}</span></td>
                    <td className="py-2 px-3 text-xs">{txn.txn_date}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <div className="px-4 py-3 bg-gray-50 border-t text-xs text-gray-500">
          {txns.length} transaction(s)
        </div>
      </div>
    </div>
  );
}
