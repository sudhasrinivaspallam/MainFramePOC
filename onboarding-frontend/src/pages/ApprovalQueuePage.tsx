import { ArrowRight, ClipboardCheck, Search } from "lucide-react";
import { useState } from "react";
import { Link } from "react-router-dom";
import { RiskBadge, StatusBadge } from "../components/StatusBadge";
import { formatDate } from "../lib/format";
import { useOnboarding } from "../state/useOnboarding";

export default function ApprovalQueuePage() {
  const { applications } = useOnboarding();
  const [query, setQuery] = useState("");
  const [risk, setRisk] = useState("ALL");
  const submitted = applications
    .filter((application) => application.status === "SUBMITTED")
    .filter(
      (application) =>
        (risk === "ALL" || application.riskLevel === risk) &&
        `${application.business.legalName} ${application.id}`
          .toLowerCase()
          .includes(query.toLowerCase()),
    );

  return (
    <div className="page">
      <div className="page-heading">
        <div>
          <span className="eyebrow">Maker-checker control</span>
          <h1>Approval queue</h1>
          <p>
            Review submitted applications, compliance findings, documents, and
            audit evidence before deciding.
          </p>
        </div>
      </div>

      <section className="content-card">
        <div className="filter-bar" role="search">
          <label className="search-box">
            <span className="sr-only">Search approval queue</span>
            <Search size={18} aria-hidden="true" />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search business or application ID"
            />
          </label>
          <label className="filter-select">
            <span>Risk level</span>
            <select
              value={risk}
              onChange={(event) => setRisk(event.target.value)}
            >
              <option value="ALL">All risks</option>
              <option value="LOW">Low</option>
              <option value="MEDIUM">Medium</option>
              <option value="HIGH">High</option>
            </select>
          </label>
        </div>

        {submitted.length === 0 ? (
          <div className="empty-state">
            <ClipboardCheck size={34} aria-hidden="true" />
            <h2>No applications match</h2>
            <p>Adjust your filters or return when new work is submitted.</p>
          </div>
        ) : (
          <div className="approval-list">
            {submitted.map((application) => (
              <article className="approval-card" key={application.id}>
                <div className="approval-card-main">
                  <div>
                    <span className="mono">{application.id}</span>
                    <h2>{application.business.legalName}</h2>
                    <p>
                      Submitted by {application.ownerName} on{" "}
                      {formatDate(application.submittedAt)}
                    </p>
                  </div>
                  <div className="approval-badges">
                    <StatusBadge status={application.status} />
                    <RiskBadge risk={application.riskLevel} />
                  </div>
                </div>
                <dl className="approval-facts">
                  <div>
                    <dt>Products</dt>
                    <dd>{application.products.products.join(", ")}</dd>
                  </div>
                  <div>
                    <dt>Foreign activity</dt>
                    <dd>{application.compliance.foreignOperations}</dd>
                  </div>
                  <div>
                    <dt>Documents</dt>
                    <dd>
                      {Object.values(application.documents).filter(Boolean)
                        .length}
                      /4 verified
                    </dd>
                  </div>
                </dl>
                <Link
                  className="button button-primary"
                  to={`/onboarding/${application.id}/decision`}
                >
                  Review application
                  <ArrowRight size={17} aria-hidden="true" />
                </Link>
              </article>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
