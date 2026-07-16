import { useState } from "react";
import { PlayCircle, CheckCircle, AlertTriangle, Clock } from "lucide-react";
import { runPIPipeline, runSettlementPipeline, runFullPipeline, loadSampleData } from "../api/client";
import type { BatchPipelineResult, BatchJobResult } from "../types";

export default function BatchPipeline() {
  const [results, setResults] = useState<Array<{ name: string; result: BatchPipelineResult | BatchJobResult; time: string }>>([]);
  const [processing, setProcessing] = useState("");
  const [error, setError] = useState("");

  const run = async (name: string, fn: () => Promise<BatchPipelineResult | BatchJobResult>) => {
    setProcessing(name);
    setError("");
    try {
      const result = await fn();
      setResults((prev) => [{ name, result, time: new Date().toLocaleTimeString() }, ...prev]);
    } catch (e) {
      setError(e instanceof Error ? e.message : `${name} failed`);
    }
    setProcessing("");
  };

  const pipelines = [
    { id: "sample", label: "Load Sample Data", desc: "PILOAD0 - Load 10 sample cards with various statuses", color: "bg-gray-600", fn: () => loadSampleData() as Promise<BatchJobResult> },
    { id: "pi", label: "PI Pipeline", desc: "PILOAD0 + PICRD400 - Card issuance & renewal batch", color: "bg-blue-600", fn: runPIPipeline },
    { id: "settlement", label: "Settlement Pipeline", desc: "STLMT100-400 - Extract, match, calculate, report", color: "bg-purple-600", fn: runSettlementPipeline },
    { id: "full", label: "Full Pipeline", desc: "PI + Settlement - Complete end-to-end batch cycle", color: "bg-red-700", fn: runFullPipeline },
  ];

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Batch Pipeline</h1>
        <p className="text-sm text-gray-500">JCL equivalent - Run batch processing pipelines</p>
      </div>

      {error && <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm flex items-center gap-2"><AlertTriangle size={16} />{error}</div>}

      {/* Pipeline Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        {pipelines.map((p) => (
          <button
            key={p.id}
            onClick={() => run(p.label, p.fn)}
            disabled={!!processing}
            className={`${p.color} text-white rounded-xl p-5 text-left hover:opacity-90 disabled:opacity-50 transition-opacity shadow-sm`}
          >
            <div className="flex items-center justify-between mb-2">
              <PlayCircle size={24} />
              {processing === p.label && <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white" />}
            </div>
            <p className="font-semibold">{p.label}</p>
            <p className="text-sm opacity-80 mt-1">{p.desc}</p>
          </button>
        ))}
      </div>

      {/* Pipeline Info */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-5 mb-6">
        <h3 className="text-sm font-semibold text-gray-700 mb-3">Pipeline Architecture (JCL → FastAPI)</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
          <div className="p-3 bg-blue-50 rounded-lg">
            <p className="font-semibold text-blue-800 mb-2">PI Batch Cycle</p>
            <ol className="space-y-1 text-blue-700">
              <li>1. PILOAD0 → Load/generate sample card data</li>
              <li>2. PICRD100 → Issue cards with Luhn validation</li>
              <li>3. PICRD200 → Activate new cards (NW→AC)</li>
              <li>4. PICRD400 → Renew expiring cards (60-day window)</li>
            </ol>
          </div>
          <div className="p-3 bg-purple-50 rounded-lg">
            <p className="font-semibold text-purple-800 mb-2">Settlement Batch Cycle</p>
            <ol className="space-y-1 text-purple-700">
              <li>1. STLMT100 → Extract & validate transactions</li>
              <li>2. STLMT200 → O(n) sequential merge matching</li>
              <li>3. STLMT300 → Net settlement with 1.75% interchange</li>
              <li>4. STLMT400 → Management report & CSV generation</li>
            </ol>
          </div>
        </div>
      </div>

      {/* Results */}
      {results.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="px-5 py-3 bg-gray-50 border-b text-sm font-semibold text-gray-700">
            Execution History ({results.length})
          </div>
          <div className="divide-y">
            {results.map((r, i) => (
              <div key={i} className="px-5 py-4">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    {(r.result as BatchPipelineResult).status === "COMPLETED" || (r.result as BatchJobResult).status === "COMPLETED" ? (
                      <CheckCircle size={16} className="text-green-600" />
                    ) : (
                      <AlertTriangle size={16} className="text-yellow-600" />
                    )}
                    <span className="font-medium text-sm">{r.name}</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-gray-400">
                    <Clock size={12} />
                    {r.time}
                  </div>
                </div>
                {"jobs" in r.result && (r.result as BatchPipelineResult).jobs ? (
                  <div className="mt-2 space-y-1">
                    {(r.result as BatchPipelineResult).jobs.map((job, j) => (
                      <div key={j} className="flex items-center justify-between text-xs bg-gray-50 rounded p-2">
                        <span className="font-mono">{job.job_name}</span>
                        <div className="flex items-center gap-3">
                          <span className="text-gray-500">Read: {job.records_read} | Written: {job.records_written} | Rejected: {job.records_rejected}</span>
                          <span className={`px-2 py-0.5 rounded-full font-medium ${job.status === "COMPLETED" ? "bg-green-100 text-green-800" : "bg-yellow-100 text-yellow-800"}`}>{job.status}</span>
                        </div>
                      </div>
                    ))}
                    {"total_duration_ms" in r.result && <p className="text-xs text-gray-400 mt-1">Duration: {(r.result as BatchPipelineResult).total_duration_ms}ms</p>}
                  </div>
                ) : (
                  <div className="text-xs text-gray-500">
                    {"message" in r.result && <p>{(r.result as BatchJobResult).message}</p>}
                    {"records_written" in r.result && <p>Records: {(r.result as BatchJobResult).records_read} read, {(r.result as BatchJobResult).records_written} written</p>}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
