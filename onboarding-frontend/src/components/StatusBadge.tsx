import type { ApplicationStatus, RiskLevel } from "../types";

const STATUS_LABELS: Record<ApplicationStatus, string> = {
  DRAFT: "Draft",
  RETURNED: "Returned",
  SUBMITTED: "Submitted",
  APPROVED: "Approved",
  REJECTED: "Rejected",
};

export function StatusBadge({ status }: { status: ApplicationStatus }) {
  return (
    <span className={`status-badge status-${status.toLowerCase()}`}>
      <span aria-hidden="true" className="status-dot" />
      {STATUS_LABELS[status]}
    </span>
  );
}

export function RiskBadge({ risk }: { risk: RiskLevel }) {
  return (
    <span className={`risk-badge risk-${risk.toLowerCase()}`}>
      {risk.charAt(0) + risk.slice(1).toLowerCase()} risk
    </span>
  );
}
