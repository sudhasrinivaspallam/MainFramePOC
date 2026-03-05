export interface Card {
  card_number: string;
  card_type: string;
  account_number: string;
  customer_id: string;
  first_name: string;
  last_name: string;
  addr_line1?: string;
  addr_line2?: string;
  city?: string;
  state?: string;
  zip_code?: string;
  card_status: string;
  issue_date: string;
  expiry_date: string;
  activation_date?: string;
  last_used_date?: string;
  daily_limit: number;
  available_balance: number;
  pin_offset?: string;
  cvv_value?: string;
  branch_code?: string;
  created_timestamp?: string;
  updated_timestamp?: string;
}

export interface StatusHistory {
  history_id: number;
  card_number: string;
  previous_status: string;
  new_status: string;
  reason_code?: string;
  requestor_id?: string;
  status_date: string;
  created_timestamp?: string;
}

export interface SettlementTransaction {
  settle_id: string;
  txn_id: string;
  card_number: string;
  account_number?: string;
  txn_type?: string;
  txn_amount: number;
  txn_date?: string;
  merchant_id?: string;
  merchant_name?: string;
  acquirer_id?: string;
  issuer_id?: string;
  network_id?: string;
  interchange_fee: number;
  settle_status: string;
  settle_date?: string;
  batch_seq_num?: number;
  created_timestamp?: string;
}

export interface SettlementSummary {
  id?: number;
  settle_date: string;
  network_id: string;
  total_txn_count: number;
  total_txn_amount: number;
  matched_count: number;
  matched_amount: number;
  unmatched_count: number;
  unmatched_amount: number;
  disputed_count: number;
  disputed_amount: number;
  total_fees: number;
  net_settle_amount: number;
  recon_status: string;
  created_timestamp?: string;
}

export interface BatchJobResult {
  job_name: string;
  status: string;
  records_read: number;
  records_written: number;
  records_rejected: number;
  details?: Record<string, unknown>;
  message: string;
}

export interface BatchPipelineResult {
  pipeline_name: string;
  status: string;
  jobs: BatchJobResult[];
  total_duration_ms: number;
}

export interface RenewalResult {
  renewed_count: number;
  renewal_pairs: Array<{
    old_card_number: string;
    new_card_number: string;
    old_expiry: string;
    new_expiry: string;
    customer_name: string;
  }>;
  message: string;
}

export interface MatchingResult {
  matched_count: number;
  matched_amount: number;
  unmatched_settlement_count: number;
  unmatched_acquirer_count: number;
  amount_mismatch_count: number;
  details: Array<Record<string, unknown>>;
}

export interface NetSettlementResult {
  summaries: SettlementSummary[];
  grand_total_txn_count: number;
  grand_total_txn_amount: number;
  grand_total_matched_count: number;
  grand_total_fees: number;
  grand_total_net_amount: number;
}

export interface ManagementReport {
  report_date: string;
  network_details: Array<Record<string, unknown>>;
  grand_totals: Record<string, unknown>;
  csv_data: string;
}

export interface DashboardStats {
  total_cards: number;
  active_cards: number;
  new_cards: number;
  blocked_cards: number;
  expired_cards: number;
  closed_cards: number;
  total_transactions: number;
  total_settlement_txns: number;
  total_settlement_amount: number;
  recent_cards: Card[];
  recent_settlements: SettlementSummary[];
}

export const STATUS_LABELS: Record<string, string> = {
  NW: "New",
  AC: "Active",
  IN: "Inactive",
  BL: "Blocked",
  EX: "Expired",
  CL: "Closed",
  HL: "Hotlisted",
};

export const STATUS_COLORS: Record<string, string> = {
  NW: "bg-blue-100 text-blue-800",
  AC: "bg-green-100 text-green-800",
  IN: "bg-gray-100 text-gray-800",
  BL: "bg-red-100 text-red-800",
  EX: "bg-orange-100 text-orange-800",
  CL: "bg-gray-200 text-gray-600",
  HL: "bg-purple-100 text-purple-800",
};

export const SETTLE_STATUS_LABELS: Record<string, string> = {
  PE: "Pending",
  MT: "Matched",
  UM: "Unmatched",
  ST: "Settled",
  DI: "Disputed",
};

export const SETTLE_STATUS_COLORS: Record<string, string> = {
  PE: "bg-yellow-100 text-yellow-800",
  MT: "bg-green-100 text-green-800",
  UM: "bg-red-100 text-red-800",
  ST: "bg-blue-100 text-blue-800",
  DI: "bg-orange-100 text-orange-800",
};

export const RECON_STATUS_LABELS: Record<string, string> = {
  BL: "Balanced",
  OB: "Out of Balance",
  PE: "Pending",
};
