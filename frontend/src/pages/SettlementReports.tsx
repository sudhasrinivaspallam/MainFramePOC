import { useState } from "react";
import { FileText, Download } from "lucide-react";
import { fetchManagementReport, getCSVDownloadUrl } from "../api/client";
import type { ManagementReport } from "../types";

export default function SettlementReports() {
  const [report, setReport] = useState<ManagementReport | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleGenerate = async () => {
    setLoading(true);
    setError("");
    try {
      const data = await fetchManagementReport();
      setReport(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to generate report");
    }
    setLoading(false);
  };

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Settlement Reports</h1>
        <p className="text-sm text-gray-500">STLMT400 - Management report & CSV export</p>
      </div>

      {error && <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>}

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 mb-6 max-w-lg">
        <div className="flex gap-3">
          <button onClick={handleGenerate} disabled={loading} className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-red-700 text-white rounded-lg hover:bg-red-800 disabled:opacity-50 text-sm font-medium">
            <FileText size={16} />
            {loading ? "Generating..." : "Generate Report"}
          </button>
          <a href={getCSVDownloadUrl()} target="_blank" rel="noreferrer" className="flex items-center gap-2 px-4 py-2.5 border border-gray-200 rounded-lg hover:bg-gray-50 text-sm font-medium text-gray-700">
            <Download size={16} />
            CSV
          </a>
        </div>
      </div>

      {report && (
        <div className="space-y-6">
          {/* Report Header */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-semibold text-gray-700">Management Report</h3>
              <span className="text-xs text-gray-400">Report Date: {report.report_date}</span>
            </div>

            {/* Network Details */}
            {report.network_details && report.network_details.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50 border-b">
                    <tr>
                      <th className="text-left py-2 px-3 font-medium text-gray-500">Network</th>
                      <th className="text-right py-2 px-3 font-medium text-gray-500">Total Txns</th>
                      <th className="text-right py-2 px-3 font-medium text-gray-500">Total Amount</th>
                      <th className="text-right py-2 px-3 font-medium text-gray-500">Matched</th>
                      <th className="text-right py-2 px-3 font-medium text-gray-500">Unmatched</th>
                      <th className="text-right py-2 px-3 font-medium text-gray-500">Disputed</th>
                      <th className="text-right py-2 px-3 font-medium text-gray-500">Fees</th>
                      <th className="text-right py-2 px-3 font-medium text-gray-500">Net Amount</th>
                    </tr>
                  </thead>
                  <tbody>
                    {report.network_details.map((nd: Record<string, unknown>, i: number) => (
                      <tr key={i} className="border-b border-gray-50">
                        <td className="py-2 px-3 font-medium">{String(nd.network_id || nd.network || "")}</td>
                        <td className="py-2 px-3 text-right">{Number(nd.total_txn_count || nd.txn_count || 0)}</td>
                        <td className="py-2 px-3 text-right font-mono">${Number(nd.total_txn_amount || nd.txn_amount || 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                        <td className="py-2 px-3 text-right">{Number(nd.matched_count || 0)}</td>
                        <td className="py-2 px-3 text-right">{Number(nd.unmatched_count || 0)}</td>
                        <td className="py-2 px-3 text-right">{Number(nd.disputed_count || 0)}</td>
                        <td className="py-2 px-3 text-right font-mono">${Number(nd.interchange_fees || nd.fees || 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                        <td className="py-2 px-3 text-right font-mono font-medium">${Number(nd.net_amount || 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <p className="text-sm text-gray-400 text-center py-4">No network data available. Run the settlement pipeline first.</p>
            )}
          </div>

          {/* Grand Totals */}
          {report.grand_totals && Object.keys(report.grand_totals).length > 0 && (
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
              <h3 className="text-sm font-semibold text-gray-700 mb-3">Grand Totals</h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {Object.entries(report.grand_totals).map(([key, value]) => (
                  <div key={key} className="text-center p-3 bg-gray-50 rounded-lg">
                    <p className="text-lg font-bold text-gray-900">
                      {typeof value === "number" ? (key.includes("amount") || key.includes("fee") || key.includes("net") ? `$${value.toLocaleString(undefined, { minimumFractionDigits: 2 })}` : value.toLocaleString()) : String(value)}
                    </p>
                    <p className="text-xs text-gray-500 mt-1">{key.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* CSV Preview */}
          {report.csv_data && (
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5">
              <h3 className="text-sm font-semibold text-gray-700 mb-3">CSV Preview</h3>
              <pre className="bg-gray-50 rounded-lg p-3 text-xs font-mono overflow-x-auto max-h-48 whitespace-pre">
                {report.csv_data}
              </pre>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
