import {
  ArrowRight,
  CheckCircle2,
  Clock3,
  FilePenLine,
  Plus,
  RotateCcw,
} from "lucide-react";
import { Link } from "react-router-dom";
import { formatDate } from "../lib/format";
import { canCreate, canEdit } from "../lib/permissions";
import { useOnboarding } from "../state/useOnboarding";
import type { ApplicationStatus } from "../types";
import { RiskBadge, StatusBadge } from "../components/StatusBadge";

const statusCounts: {
  status: ApplicationStatus;
  label: string;
  icon: typeof Clock3;
}[] = [
  { status: "DRAFT", label: "Drafts in progress", icon: FilePenLine },
  { status: "RETURNED", label: "Returned for changes", icon: RotateCcw },
  { status: "SUBMITTED", label: "Awaiting decision", icon: Clock3 },
  { status: "APPROVED", label: "Approved", icon: CheckCircle2 },
];

export default function DashboardPage() {
  const { applications, currentUser } = useOnboarding();
  const actionable = applications.filter(
    (application) =>
      canEdit(currentUser, application) ||
      (currentUser.role === "APPROVER" && application.status === "SUBMITTED"),
  );

  return (
    <div className="page">
      <div className="page-heading">
        <div>
          <span className="eyebrow">Client onboarding workspace</span>
          <h1>Good afternoon, {currentUser.name.split(" ")[0]}</h1>
          <p>
            Track applications, resolve outstanding items, and keep client
            onboarding moving.
          </p>
        </div>
        {canCreate(currentUser.role) && (
          <Link className="button button-primary" to="/onboarding/new">
            <Plus size={18} aria-hidden="true" />
            Start application
          </Link>
        )}
      </div>

      <section className="metric-grid" aria-label="Application status summary">
        {statusCounts.map(({ status, label, icon: Icon }) => (
          <article className="metric-card" key={status}>
            <span className={`metric-icon metric-${status.toLowerCase()}`}>
              <Icon size={20} aria-hidden="true" />
            </span>
            <div>
              <strong>
                {
                  applications.filter(
                    (application) => application.status === status,
                  ).length
                }
              </strong>
              <span>{label}</span>
            </div>
          </article>
        ))}
      </section>

      <section className="content-card">
        <div className="section-heading">
          <div>
            <span className="eyebrow">Priority work</span>
            <h2>Applications requiring attention</h2>
          </div>
          <Link className="text-link" to="/onboarding/inquiry">
            View all applications
            <ArrowRight size={16} aria-hidden="true" />
          </Link>
        </div>

        {actionable.length === 0 ? (
          <div className="empty-state">
            <CheckCircle2 size={34} aria-hidden="true" />
            <h3>You are all caught up</h3>
            <p>No applications currently require action for this role.</p>
          </div>
        ) : (
          <div className="table-wrap">
            <table>
              <caption className="sr-only">
                Applications requiring attention
              </caption>
              <thead>
                <tr>
                  <th scope="col">Business</th>
                  <th scope="col">Application</th>
                  <th scope="col">Status</th>
                  <th scope="col">Risk</th>
                  <th scope="col">Updated</th>
                  <th scope="col">
                    <span className="sr-only">Action</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {actionable.slice(0, 6).map((application) => (
                  <tr key={application.id}>
                    <td>
                      <strong>
                        {application.business.legalName || "Unnamed business"}
                      </strong>
                      <span className="cell-subtext">
                        {application.business.dbaName || application.ownerName}
                      </span>
                    </td>
                    <td className="mono">{application.id}</td>
                    <td>
                      <StatusBadge status={application.status} />
                    </td>
                    <td>
                      <RiskBadge risk={application.riskLevel} />
                    </td>
                    <td>{formatDate(application.updatedAt)}</td>
                    <td>
                      <Link
                        className="table-action"
                        aria-label={`Open ${application.id}`}
                        to={
                          currentUser.role === "APPROVER"
                            ? `/onboarding/${application.id}/decision`
                            : `/onboarding/${application.id}/edit/${application.currentStep}`
                        }
                      >
                        Open
                        <ArrowRight size={15} aria-hidden="true" />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <div className="dashboard-lower-grid">
        <section className="content-card">
          <div className="section-heading compact">
            <div>
              <span className="eyebrow">Process health</span>
              <h2>Onboarding service levels</h2>
            </div>
          </div>
          <div className="sla-list">
            <div>
              <span>Average draft completion</span>
              <strong>2.4 days</strong>
            </div>
            <div>
              <span>Approval turnaround</span>
              <strong>6.8 hours</strong>
            </div>
            <div>
              <span>Completed within SLA</span>
              <strong>94%</strong>
            </div>
          </div>
        </section>
        <section className="content-card next-steps-card">
          <span className="eyebrow">Modernized workflow</span>
          <h2>From terminal screens to guided onboarding</h2>
          <p>
            Draft persistence, contextual validation, role-based decisions,
            inquiry, and audit history replace conversational CICS state.
          </p>
          <Link className="text-link" to="/onboarding/inquiry">
            Explore the inquiry workspace
            <ArrowRight size={16} aria-hidden="true" />
          </Link>
        </section>
      </div>
    </div>
  );
}
