import { ArrowRight, FileSearch, RotateCcw, Search } from "lucide-react";
import { useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { RiskBadge, StatusBadge } from "../components/StatusBadge";
import { formatDate } from "../lib/format";
import { useOnboarding } from "../state/useOnboarding";

export default function InquiryPage() {
  const { applications } = useOnboarding();
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState("ALL");
  const [risk, setRisk] = useState("ALL");
  const [owner, setOwner] = useState("ALL");

  const owners = Array.from(
    new Set(applications.map((application) => application.ownerName)),
  ).sort();

  const results = useMemo(
    () =>
      applications.filter((application) => {
        const text =
          `${application.id} ${application.business.legalName} ${application.business.dbaName} ${application.business.taxId} ${application.ownerName}`.toLowerCase();
        return (
          text.includes(query.toLowerCase()) &&
          (status === "ALL" || application.status === status) &&
          (risk === "ALL" || application.riskLevel === risk) &&
          (owner === "ALL" || application.ownerName === owner)
        );
      }),
    [applications, owner, query, risk, status],
  );

  const reset = () => {
    setQuery("");
    setStatus("ALL");
    setRisk("ALL");
    setOwner("ALL");
  };

  return (
    <div className="page">
      <div className="page-heading">
        <div>
          <span className="eyebrow">Application inquiry</span>
          <h1>Find onboarding applications</h1>
          <p>
            Search current and historical applications with permission-aware
            access to client data.
          </p>
        </div>
      </div>

      <section className="content-card">
        <div className="inquiry-filters" role="search">
          <label className="search-box wide-search">
            <span className="sr-only">Search applications</span>
            <Search size={18} aria-hidden="true" />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Application ID, legal name, DBA, tax ID, or owner"
            />
          </label>
          <label className="filter-select">
            <span>Status</span>
            <select
              value={status}
              onChange={(event) => setStatus(event.target.value)}
            >
              <option value="ALL">All statuses</option>
              <option value="DRAFT">Draft</option>
              <option value="RETURNED">Returned</option>
              <option value="SUBMITTED">Submitted</option>
              <option value="APPROVED">Approved</option>
              <option value="REJECTED">Rejected</option>
            </select>
          </label>
          <label className="filter-select">
            <span>Risk</span>
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
          <label className="filter-select">
            <span>Owner</span>
            <select
              value={owner}
              onChange={(event) => setOwner(event.target.value)}
            >
              <option value="ALL">All owners</option>
              {owners.map((name) => (
                <option key={name}>{name}</option>
              ))}
            </select>
          </label>
          <button className="button button-tertiary" type="button" onClick={reset}>
            <RotateCcw size={16} aria-hidden="true" />
            Reset
          </button>
        </div>

        <div className="result-count" aria-live="polite">
          {results.length} application{results.length === 1 ? "" : "s"} found
        </div>

        {results.length === 0 ? (
          <div className="empty-state">
            <FileSearch size={34} aria-hidden="true" />
            <h2>No matching applications</h2>
            <p>Try a broader search or reset one or more filters.</p>
            <button
              className="button button-secondary"
              type="button"
              onClick={reset}
            >
              Reset filters
            </button>
          </div>
        ) : (
          <div className="table-wrap">
            <table>
              <caption className="sr-only">Application inquiry results</caption>
              <thead>
                <tr>
                  <th scope="col">Business</th>
                  <th scope="col">Application ID</th>
                  <th scope="col">Status</th>
                  <th scope="col">Risk</th>
                  <th scope="col">Owner</th>
                  <th scope="col">Updated</th>
                  <th scope="col">
                    <span className="sr-only">Action</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {results.map((application) => (
                  <tr key={application.id}>
                    <td>
                      <strong>
                        {application.business.legalName || "Unnamed business"}
                      </strong>
                      <span className="cell-subtext">
                        {application.business.dbaName || "No DBA"}
                      </span>
                    </td>
                    <td className="mono">{application.id}</td>
                    <td>
                      <StatusBadge status={application.status} />
                    </td>
                    <td>
                      <RiskBadge risk={application.riskLevel} />
                    </td>
                    <td>{application.ownerName}</td>
                    <td>{formatDate(application.updatedAt)}</td>
                    <td>
                      <Link
                        className="table-action"
                        aria-label={`View ${application.id}`}
                        to={`/onboarding/${application.id}`}
                      >
                        View
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
    </div>
  );
}
