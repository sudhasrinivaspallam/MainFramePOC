import { formatCurrency, formatDate, maskTaxId } from "../lib/format";
import { canViewSensitive } from "../lib/permissions";
import { useOnboarding } from "../state/useOnboarding";
import type { BusinessApplication } from "../types";
import { RiskBadge, StatusBadge } from "./StatusBadge";

export function ApplicationSummary({
  application,
}: {
  application: BusinessApplication;
}) {
  const { currentUser } = useOnboarding();
  const business = application.business;

  return (
    <div className="summary-grid">
      <section className="summary-card">
        <div className="summary-card-heading">
          <div>
            <span className="eyebrow">Application</span>
            <h2>{business.legalName || "Unnamed business"}</h2>
          </div>
          <StatusBadge status={application.status} />
        </div>
        <dl className="detail-list">
          <div>
            <dt>Application ID</dt>
            <dd>{application.id}</dd>
          </div>
          <div>
            <dt>DBA</dt>
            <dd>{business.dbaName || "Not provided"}</dd>
          </div>
          <div>
            <dt>Entity type</dt>
            <dd>{business.entityType || "Not provided"}</dd>
          </div>
          <div>
            <dt>Tax ID</dt>
            <dd>
              {canViewSensitive(currentUser.role)
                ? business.taxId || "Not provided"
                : maskTaxId(business.taxId)}
            </dd>
          </div>
          <div>
            <dt>Owner</dt>
            <dd>{application.ownerName}</dd>
          </div>
          <div>
            <dt>Last updated</dt>
            <dd>{formatDate(application.updatedAt)}</dd>
          </div>
        </dl>
      </section>

      <section className="summary-card">
        <div className="summary-card-heading">
          <div>
            <span className="eyebrow">Risk and products</span>
            <h2>Onboarding profile</h2>
          </div>
          <RiskBadge risk={application.riskLevel} />
        </div>
        <dl className="detail-list">
          <div>
            <dt>Products</dt>
            <dd>
              {application.products.products.join(", ") || "Not selected"}
            </dd>
          </div>
          <div>
            <dt>Expected balance</dt>
            <dd>{formatCurrency(application.products.expectedBalance)}</dd>
          </div>
          <div>
            <dt>Monthly transactions</dt>
            <dd>
              {application.products.monthlyTransactions.toLocaleString()}
            </dd>
          </div>
          <div>
            <dt>Foreign operations</dt>
            <dd>{application.compliance.foreignOperations || "Not answered"}</dd>
          </div>
          <div>
            <dt>Documents</dt>
            <dd>
              {Object.values(application.documents).filter(Boolean).length} of 4
              complete
            </dd>
          </div>
          <div>
            <dt>Application version</dt>
            <dd>v{application.version}</dd>
          </div>
        </dl>
      </section>
    </div>
  );
}
