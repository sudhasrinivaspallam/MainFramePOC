/**
 * API Client with localStorage fallback
 * When the backend is unavailable, all data operations fall back to localStorage
 */

import type {
  Card,
  StatusHistory,
  SettlementTransaction,
  SettlementSummary,
  BatchJobResult,
  BatchPipelineResult,
  RenewalResult,
  MatchingResult,
  NetSettlementResult,
  ManagementReport,
  DashboardStats,
} from "../types";

const API_BASE = import.meta.env.VITE_API_URL || "http://localhost:8000";

let useLocalStorage = false;

// ================================================================
// localStorage helpers
// ================================================================
function lsGet<T>(key: string, fallback: T): T {
  try {
    const val = localStorage.getItem(key);
    return val ? JSON.parse(val) : fallback;
  } catch {
    return fallback;
  }
}

function lsSet(key: string, val: unknown): void {
  localStorage.setItem(key, JSON.stringify(val));
}

// Luhn algorithm (mirrors backend)
function calculateLuhnCheckDigit(partial: string): string {
  const digits = partial.split("").map(Number);
  let total = 0;
  for (let i = digits.length - 1; i >= 0; i--) {
    let d = digits[i];
    if ((digits.length - 1 - i) % 2 === 0) {
      d = d * 2;
      if (d > 9) d -= 9;
    }
    total += d;
  }
  return String((10 - (total % 10)) % 10);
}

function generateCardNumber(seq: number): string {
  const bin = "400012";
  const seqStr = String(seq).padStart(9, "0");
  const partial = bin + seqStr;
  return partial + calculateLuhnCheckDigit(partial);
}

function nowTimestamp(): string {
  return new Date().toISOString().replace("T", "-").substring(0, 19);
}

function todayStr(): string {
  return new Date().toISOString().substring(0, 10);
}

// ================================================================
// HTTP helpers
// ================================================================
async function apiFetch<T>(path: string, options?: RequestInit): Promise<T> {
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers: {
        "Content-Type": "application/json",
        ...(options?.headers || {}),
      },
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: res.statusText }));
      throw new Error(err.detail || res.statusText);
    }
    return res.json();
  } catch (e) {
    if (
      e instanceof TypeError &&
      (e.message.includes("fetch") || e.message.includes("network"))
    ) {
      useLocalStorage = true;
      throw e;
    }
    throw e;
  }
}

// ================================================================
// localStorage CRUD implementations
// ================================================================
function lsGetCards(): Card[] {
  return lsGet<Card[]>("cards", []);
}

function lsSaveCards(cards: Card[]): void {
  lsSet("cards", cards);
}

function lsGetHistory(): StatusHistory[] {
  return lsGet<StatusHistory[]>("card_history", []);
}

function lsGetSettlements(): SettlementTransaction[] {
  return lsGet<SettlementTransaction[]>("settlements", []);
}

function lsGetSummaries(): SettlementSummary[] {
  return lsGet<SettlementSummary[]>("settlement_summaries", []);
}

// Sample data for localStorage mode
const SAMPLE_CARDS: Omit<Card, "card_number">[] = [
  { card_type: "DB", account_number: "100000000001", customer_id: "CUST000001", first_name: "JOHN", last_name: "SMITH", addr_line1: "123 MAIN ST", city: "NEW YORK", state: "NY", zip_code: "10001", card_status: "AC", issue_date: todayStr(), expiry_date: "2029-03-05", daily_limit: 2000, available_balance: 15000, activation_date: todayStr() },
  { card_type: "DB", account_number: "100000000002", customer_id: "CUST000002", first_name: "JANE", last_name: "DOE", addr_line1: "456 OAK AVE", city: "LOS ANGELES", state: "CA", zip_code: "90001", card_status: "AC", issue_date: todayStr(), expiry_date: "2029-03-05", daily_limit: 5000, available_balance: 25000, activation_date: todayStr() },
  { card_type: "PP", account_number: "100000000003", customer_id: "CUST000003", first_name: "ROBERT", last_name: "JOHNSON", addr_line1: "789 PINE RD", city: "CHICAGO", state: "IL", zip_code: "60601", card_status: "NW", issue_date: todayStr(), expiry_date: "2029-03-05", daily_limit: 1000, available_balance: 500 },
  { card_type: "DB", account_number: "100000000004", customer_id: "CUST000004", first_name: "MARIA", last_name: "GARCIA", addr_line1: "321 ELM ST", city: "HOUSTON", state: "TX", zip_code: "77001", card_status: "BL", issue_date: todayStr(), expiry_date: "2029-03-05", daily_limit: 3000, available_balance: 18000 },
  { card_type: "DB", account_number: "100000000005", customer_id: "CUST000005", first_name: "WILLIAM", last_name: "BROWN", addr_line1: "654 MAPLE DR", city: "PHOENIX", state: "AZ", zip_code: "85001", card_status: "AC", issue_date: todayStr(), expiry_date: "2029-03-05", daily_limit: 1500, available_balance: 8500, activation_date: todayStr() },
];

// ================================================================
// Public API functions
// ================================================================

export function isOfflineMode(): boolean {
  return useLocalStorage;
}

export function setOfflineMode(offline: boolean): void {
  useLocalStorage = offline;
}

// --- Cards ---

export async function fetchCards(status?: string): Promise<Card[]> {
  if (useLocalStorage) {
    let cards = lsGetCards();
    if (status) cards = cards.filter((c) => c.card_status === status);
    return cards;
  }
  const params = status ? `?status=${status}` : "";
  return apiFetch<Card[]>(`/api/cards${params}`);
}

export async function fetchCard(cardNumber: string): Promise<Card> {
  if (useLocalStorage) {
    const card = lsGetCards().find((c) => c.card_number === cardNumber);
    if (!card) throw new Error(`Card ${cardNumber} not found`);
    return card;
  }
  return apiFetch<Card>(`/api/cards/${cardNumber}`);
}

export async function searchCards(query: string): Promise<Card[]> {
  if (useLocalStorage) {
    const q = query.toLowerCase();
    return lsGetCards().filter(
      (c) =>
        c.card_number.includes(q) ||
        c.customer_id.toLowerCase().includes(q) ||
        c.first_name.toLowerCase().includes(q) ||
        c.last_name.toLowerCase().includes(q)
    );
  }
  return apiFetch<Card[]>(`/api/cards/search?q=${encodeURIComponent(query)}`);
}

export async function issueCard(data: Record<string, unknown>): Promise<Card> {
  if (useLocalStorage) {
    const cards = lsGetCards();
    const seq = cards.length + 100;
    const cardNumber = generateCardNumber(seq);
    const card: Card = {
      card_number: cardNumber,
      card_type: (data.card_type as string) || "DB",
      account_number: (data.account_number as string) || "",
      customer_id: (data.customer_id as string) || "",
      first_name: (data.first_name as string) || "",
      last_name: (data.last_name as string) || "",
      addr_line1: data.addr_line1 as string,
      city: data.city as string,
      state: data.state as string,
      zip_code: data.zip_code as string,
      card_status: "NW",
      issue_date: todayStr(),
      expiry_date: new Date(Date.now() + 3 * 365 * 86400000).toISOString().substring(0, 10),
      daily_limit: (data.daily_limit as number) || 1000,
      available_balance: (data.available_balance as number) || 0,
      created_timestamp: nowTimestamp(),
      updated_timestamp: nowTimestamp(),
    };
    cards.push(card);
    lsSaveCards(cards);
    return card;
  }
  return apiFetch<Card>("/api/cards", {
    method: "POST",
    body: JSON.stringify(data),
  });
}

export async function activateCard(
  cardNumber: string,
  data: Record<string, unknown>
): Promise<Card> {
  if (useLocalStorage) {
    const cards = lsGetCards();
    const idx = cards.findIndex((c) => c.card_number === cardNumber);
    if (idx === -1) throw new Error("Card not found");
    if (cards[idx].card_status !== "NW")
      throw new Error("Card must be in NW status to activate");
    cards[idx].card_status = "AC";
    cards[idx].activation_date = todayStr();
    cards[idx].updated_timestamp = nowTimestamp();
    lsSaveCards(cards);
    return cards[idx];
  }
  return apiFetch<Card>(`/api/cards/${cardNumber}/activate`, {
    method: "PUT",
    body: JSON.stringify({ card_number: cardNumber, ...data }),
  });
}

export async function updateCardStatus(
  cardNumber: string,
  data: Record<string, unknown>
): Promise<Card> {
  if (useLocalStorage) {
    const cards = lsGetCards();
    const idx = cards.findIndex((c) => c.card_number === cardNumber);
    if (idx === -1) throw new Error("Card not found");
    const actionMap: Record<string, string> = { BL: "BL", UB: "AC", CL: "CL", HL: "HL" };
    const newStatus = actionMap[data.action_code as string];
    if (!newStatus) throw new Error("Invalid action code");
    cards[idx].card_status = newStatus;
    cards[idx].updated_timestamp = nowTimestamp();
    lsSaveCards(cards);
    return cards[idx];
  }
  return apiFetch<Card>(`/api/cards/${cardNumber}/status`, {
    method: "PUT",
    body: JSON.stringify({ card_number: cardNumber, ...data }),
  });
}

export async function updateCard(
  cardNumber: string,
  data: Record<string, unknown>
): Promise<Card> {
  if (useLocalStorage) {
    const cards = lsGetCards();
    const idx = cards.findIndex((c) => c.card_number === cardNumber);
    if (idx === -1) throw new Error("Card not found");
    Object.assign(cards[idx], data, { updated_timestamp: nowTimestamp() });
    lsSaveCards(cards);
    return cards[idx];
  }
  return apiFetch<Card>(`/api/cards/${cardNumber}`, {
    method: "PUT",
    body: JSON.stringify(data),
  });
}

export async function fetchCardHistory(
  cardNumber: string
): Promise<StatusHistory[]> {
  if (useLocalStorage) {
    return lsGetHistory().filter((h) => h.card_number === cardNumber);
  }
  return apiFetch<StatusHistory[]>(`/api/cards/${cardNumber}/history`);
}

export async function renewCards(
  cutoffDays: number = 60
): Promise<RenewalResult> {
  if (useLocalStorage) {
    return { renewed_count: 0, renewal_pairs: [], message: "No cards to renew in offline mode" };
  }
  return apiFetch<RenewalResult>(
    `/api/cards/renew?cutoff_days=${cutoffDays}`,
    { method: "POST" }
  );
}

export async function loadSampleData(): Promise<BatchJobResult> {
  if (useLocalStorage) {
    const existing = lsGetCards();
    if (existing.length > 0) {
      return { job_name: "PILOAD0", status: "SKIPPED", records_read: 0, records_written: 0, records_rejected: 0, message: "Data already loaded" };
    }
    const cards: Card[] = SAMPLE_CARDS.map((c, i) => ({
      ...c,
      card_number: generateCardNumber(100 + i),
      created_timestamp: nowTimestamp(),
      updated_timestamp: nowTimestamp(),
    }));
    lsSaveCards(cards);
    return { job_name: "PILOAD0", status: "COMPLETED", records_read: cards.length, records_written: cards.length, records_rejected: 0, message: `Loaded ${cards.length} sample cards` };
  }
  return apiFetch<BatchJobResult>("/api/cards/load-sample-data", {
    method: "POST",
  });
}

// --- Settlement ---

export async function fetchSettlementTransactions(
  status?: string,
  network?: string
): Promise<SettlementTransaction[]> {
  if (useLocalStorage) {
    let txns = lsGetSettlements();
    if (status) txns = txns.filter((t) => t.settle_status === status);
    if (network) txns = txns.filter((t) => t.network_id === network);
    return txns;
  }
  const params = new URLSearchParams();
  if (status) params.set("status", status);
  if (network) params.set("network", network);
  return apiFetch<SettlementTransaction[]>(
    `/api/settlement/transactions?${params}`
  );
}

export async function fetchSettlementSummaries(
  settleDate?: string
): Promise<SettlementSummary[]> {
  if (useLocalStorage) {
    let sums = lsGetSummaries();
    if (settleDate) sums = sums.filter((s) => s.settle_date === settleDate);
    return sums;
  }
  const params = settleDate ? `?settle_date=${settleDate}` : "";
  return apiFetch<SettlementSummary[]>(`/api/settlement/summaries${params}`);
}

export async function generateAndExtractSample(): Promise<BatchJobResult> {
  if (useLocalStorage) {
    return { job_name: "GENDATA+STLMT100", status: "COMPLETED", records_read: 0, records_written: 0, records_rejected: 0, message: "Sample data generated in offline mode" };
  }
  return apiFetch<BatchJobResult>("/api/settlement/generate-sample-data", {
    method: "POST",
  });
}

export async function runMatching(): Promise<MatchingResult> {
  if (useLocalStorage) {
    return { matched_count: 0, matched_amount: 0, unmatched_settlement_count: 0, unmatched_acquirer_count: 0, amount_mismatch_count: 0, details: [] };
  }
  return apiFetch<MatchingResult>("/api/settlement/run-matching", {
    method: "POST",
  });
}

export async function calculateNetSettlement(): Promise<NetSettlementResult> {
  if (useLocalStorage) {
    return { summaries: [], grand_total_txn_count: 0, grand_total_txn_amount: 0, grand_total_matched_count: 0, grand_total_fees: 0, grand_total_net_amount: 0 };
  }
  return apiFetch<NetSettlementResult>("/api/settlement/calculate", {
    method: "POST",
  });
}

export async function fetchManagementReport(): Promise<ManagementReport> {
  if (useLocalStorage) {
    return { report_date: todayStr(), network_details: [], grand_totals: {}, csv_data: "" };
  }
  return apiFetch<ManagementReport>("/api/settlement/report");
}

export function getCSVDownloadUrl(settleDate?: string): string {
  const params = settleDate ? `?settle_date=${settleDate}` : "";
  return `${API_BASE}/api/settlement/report/csv${params}`;
}

// --- Batch Pipeline ---

export async function runPIPipeline(): Promise<BatchPipelineResult> {
  if (useLocalStorage) {
    await loadSampleData();
    return { pipeline_name: "PI_BATCH_CYCLE", status: "COMPLETED", jobs: [], total_duration_ms: 0 };
  }
  return apiFetch<BatchPipelineResult>("/api/batch/run-pi-pipeline", {
    method: "POST",
  });
}

export async function runSettlementPipeline(): Promise<BatchPipelineResult> {
  if (useLocalStorage) {
    return { pipeline_name: "SETTLEMENT_BATCH_CYCLE", status: "COMPLETED", jobs: [], total_duration_ms: 0 };
  }
  return apiFetch<BatchPipelineResult>("/api/batch/run-settlement-pipeline", {
    method: "POST",
  });
}

export async function runFullPipeline(): Promise<BatchPipelineResult> {
  if (useLocalStorage) {
    await loadSampleData();
    return { pipeline_name: "FULL_BATCH_PIPELINE", status: "COMPLETED", jobs: [], total_duration_ms: 0 };
  }
  return apiFetch<BatchPipelineResult>("/api/batch/run-full-pipeline", {
    method: "POST",
  });
}

export async function fetchDashboardStats(): Promise<DashboardStats> {
  if (useLocalStorage) {
    const cards = lsGetCards();
    return {
      total_cards: cards.length,
      active_cards: cards.filter((c) => c.card_status === "AC").length,
      new_cards: cards.filter((c) => c.card_status === "NW").length,
      blocked_cards: cards.filter((c) => c.card_status === "BL").length,
      expired_cards: cards.filter((c) => c.card_status === "EX").length,
      closed_cards: cards.filter((c) => c.card_status === "CL").length,
      total_transactions: 0,
      total_settlement_txns: lsGetSettlements().length,
      total_settlement_amount: lsGetSettlements().reduce((s, t) => s + t.txn_amount, 0),
      recent_cards: cards.slice(0, 5),
      recent_settlements: lsGetSummaries().slice(0, 5),
    };
  }
  return apiFetch<DashboardStats>("/api/batch/dashboard");
}

// Check connectivity on load
export async function checkConnection(): Promise<boolean> {
  try {
    await fetch(`${API_BASE}/health`, { signal: AbortSignal.timeout(3000) });
    useLocalStorage = false;
    return true;
  } catch {
    useLocalStorage = true;
    return false;
  }
}
