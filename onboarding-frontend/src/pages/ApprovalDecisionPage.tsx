import {
  AlertTriangle,
  ArrowLeft,
  CheckCircle2,
  RotateCcw,
  ShieldCheck,
  XCircle,
} from "lucide-react";
import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { ApplicationSummary } from "../components/ApplicationSummary";
import { formatDateTime } from "../lib/format";
import { canDecide } from "../lib/permissions";
import { useOnboarding } from "../state/useOnboarding";
import type { ApplicationStatus } from "../types";

type Decision = Extract<
  ApplicationStatus,
  "APPROVED" | "RETURNED" | "REJECTED"
>;

export default function ApprovalDecisionPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const {
    currentUser,
    findApplication,
    decideApplication,
  } = useOnboarding();
  const application = id ? findApplication(id) : undefined;
  const [decision, setDecision] = useState<Decision | null>(null);
  const [reason, setReason] = useState("");
  const [error, setError] = useState("");

  if (!application) {
    return (
      <div className="centered-state">
        <AlertTriangle size={34} aria-hidden="true" />
        <h1>Application not found</h1>
        <Link className="button button-primary" to="/onboarding/approvals">
          Return to approval queue
        </Link>
      </div>
    );
  }

  if (!canDecide(currentUser, application)) {
    return (
      <div className="centered-state">
        <ShieldCheck size={34} aria-hidden="true" />
        <h1>Decision unavailable</h1>
        <p>
          This application is not awaiting a decision, or your current role
          cannot decide it.
        </p>
        <Link
          className="button button-primary"
          to={`/onboarding/${application.id}`}
        >
          View application
        </Link>
      </div>
    );
  }

  const chooseDecision = (nextDecision: Decision) => {
    setDecision(nextDecision);
    setReason("");
    setError("");
  };

  const confirmDecision = () => {
    if (!decision) return;
    if (decision !== "APPROVED" && !reason.trim()) {
      setError("A reason is required when returning or rejecting an application.");
      return;
    }
    decideApplication(application.id, decision, reason.trim());
    navigate(`/onboarding/${application.id}`);
  };

  return (
    <div className="page">
      <div className="wizard-utility">
        <Link to="/onboarding/approvals" className="back-link">
          <ArrowLeft size={16} aria-hidden="true" />
          Approval queue
        </Link>
        <span className="mono">{application.id}</span>
      </div>

      <div className="page-heading approval-heading">
        <div>
          <span className="eyebrow">Independent approval review</span>
          <h1>Review {application.business.legalName}</h1>
          <p>
            Submitted {formatDateTime(application.submittedAt)} by{" "}
            {application.ownerName}
          </p>
        </div>
      </div>

      <div className="decision-layout">
        <div>
          <ApplicationSummary application={application} />

          <section className="content-card">
            <div className="section-heading compact">
              <div>
                <span className="eyebrow">Compliance review</span>
                <h2>Risk screening responses</h2>
              </div>
            </div>
            <dl className="review-facts">
              <div>
                <dt>Source of funds</dt>
                <dd>{application.compliance.sourceOfFunds}</dd>
              </div>
              <div>
                <dt>Tax classification</dt>
                <dd>{application.compliance.taxClassification}</dd>
              </div>
              <div>
                <dt>PEP exposure</dt>
                <dd>{application.compliance.pepExposure}</dd>
              </div>
              <div>
                <dt>Foreign operations</dt>
                <dd>{application.compliance.foreignOperations}</dd>
              </div>
              <div>
                <dt>High-risk activity</dt>
                <dd>{application.compliance.highRiskActivity}</dd>
              </div>
              <div>
                <dt>Analyst notes</dt>
                <dd>{application.compliance.notes || "No additional notes"}</dd>
              </div>
            </dl>
          </section>

          <section className="content-card">
            <div className="section-heading compact">
              <div>
                <span className="eyebrow">Evidence</span>
                <h2>Document checklist</h2>
              </div>
            </div>
            <ul className="evidence-list">
              {Object.entries(application.documents).map(([name, verified]) => (
                <li key={name}>
                  {verified ? (
                    <CheckCircle2 size={18} aria-hidden="true" />
                  ) : (
                    <AlertTriangle size={18} aria-hidden="true" />
                  )}
                  <span>{documentLabel(name)}</span>
                  <strong>{verified ? "Verified" : "Missing"}</strong>
                </li>
              ))}
            </ul>
          </section>
        </div>

        <aside className="decision-panel">
          <span className="eyebrow">Decision</span>
          <h2>Complete approval review</h2>
          <p>
            Your decision and comments will be written to the permanent audit
            history.
          </p>

          <div className="decision-options">
            <button
              type="button"
              className={`decision-option approve ${
                decision === "APPROVED" ? "selected" : ""
              }`}
              onClick={() => chooseDecision("APPROVED")}
            >
              <CheckCircle2 size={20} aria-hidden="true" />
              <span>
                <strong>Approve</strong>
                <small>Accept the application as submitted</small>
              </span>
            </button>
            <button
              type="button"
              className={`decision-option return ${
                decision === "RETURNED" ? "selected" : ""
              }`}
              onClick={() => chooseDecision("RETURNED")}
            >
              <RotateCcw size={20} aria-hidden="true" />
              <span>
                <strong>Return for changes</strong>
                <small>Send actionable items back to the maker</small>
              </span>
            </button>
            <button
              type="button"
              className={`decision-option reject ${
                decision === "REJECTED" ? "selected" : ""
              }`}
              onClick={() => chooseDecision("REJECTED")}
            >
              <XCircle size={20} aria-hidden="true" />
              <span>
                <strong>Reject</strong>
                <small>Decline this onboarding request</small>
              </span>
            </button>
          </div>

          {decision && (
            <div className="decision-confirm">
              <label htmlFor="decision-reason">
                {decision === "APPROVED"
                  ? "Approval note (optional)"
                  : "Decision reason"}
              </label>
              <textarea
                id="decision-reason"
                rows={4}
                value={reason}
                aria-invalid={Boolean(error)}
                onChange={(event) => {
                  setReason(event.target.value);
                  setError("");
                }}
                placeholder={
                  decision === "RETURNED"
                    ? "Describe the changes and affected sections."
                    : "Record the rationale for this decision."
                }
              />
              {error && (
                <span className="field-error" role="alert">
                  {error}
                </span>
              )}
              <button
                type="button"
                className="button button-primary decision-submit"
                onClick={confirmDecision}
              >
                Confirm{" "}
                {decision === "APPROVED"
                  ? "approval"
                  : decision === "RETURNED"
                    ? "return"
                    : "rejection"}
              </button>
            </div>
          )}

          <div className="control-note">
            <ShieldCheck size={17} aria-hidden="true" />
            Maker-checker separation is active. You did not create this
            application.
          </div>
        </aside>
      </div>
    </div>
  );
}

function documentLabel(name: string): string {
  const labels: Record<string, string> = {
    formationDocument: "Formation document",
    taxDocument: "Tax documentation",
    ownerIdentification: "Beneficial-owner identification",
    bankingResolution: "Banking resolution",
  };
  return labels[name] ?? name;
}
