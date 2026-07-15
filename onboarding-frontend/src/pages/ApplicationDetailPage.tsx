import {
  ArrowLeft,
  CheckCircle2,
  Clock3,
  Edit3,
  ExternalLink,
  FileCheck2,
} from "lucide-react";
import { Link, useParams } from "react-router-dom";
import { ApplicationSummary } from "../components/ApplicationSummary";
import { formatDateTime } from "../lib/format";
import { canDecide, canEdit } from "../lib/permissions";
import { useOnboarding } from "../state/useOnboarding";

export default function ApplicationDetailPage() {
  const { id } = useParams();
  const { currentUser, findApplication } = useOnboarding();
  const application = id ? findApplication(id) : undefined;

  if (!application) {
    return (
      <div className="centered-state">
        <FileCheck2 size={34} aria-hidden="true" />
        <h1>Application not found</h1>
        <Link className="button button-primary" to="/onboarding/inquiry">
          Return to inquiry
        </Link>
      </div>
    );
  }

  return (
    <div className="page">
      <div className="wizard-utility">
        <Link to="/onboarding/inquiry" className="back-link">
          <ArrowLeft size={16} aria-hidden="true" />
          Inquiry
        </Link>
        <span className="mono">{application.id}</span>
      </div>

      <div className="page-heading">
        <div>
          <span className="eyebrow">Application detail</span>
          <h1>{application.business.legalName || "Unnamed business"}</h1>
          <p>
            Created {formatDateTime(application.createdAt)} · Last updated{" "}
            {formatDateTime(application.updatedAt)}
          </p>
        </div>
        <div className="heading-actions">
          {canEdit(currentUser, application) && (
            <Link
              className="button button-secondary"
              to={`/onboarding/${application.id}/edit/${application.currentStep}`}
            >
              <Edit3 size={17} aria-hidden="true" />
              Resume draft
            </Link>
          )}
          {canDecide(currentUser, application) && (
            <Link
              className="button button-primary"
              to={`/onboarding/${application.id}/decision`}
            >
              Review decision
              <ExternalLink size={17} aria-hidden="true" />
            </Link>
          )}
        </div>
      </div>

      {application.status === "SUBMITTED" && (
        <div className="success-banner" role="status">
          <Clock3 size={20} aria-hidden="true" />
          <div>
            <strong>Submitted for independent approval</strong>
            <p>
              This version is locked. An authorized approver must complete the
              decision.
            </p>
          </div>
        </div>
      )}

      {application.status === "APPROVED" && (
        <div className="success-banner approved-banner" role="status">
          <CheckCircle2 size={20} aria-hidden="true" />
          <div>
            <strong>Application approved</strong>
            <p>{application.decisionReason || "Approval completed."}</p>
          </div>
        </div>
      )}

      {application.status === "RETURNED" && (
        <div className="return-banner" role="status">
          <Edit3 size={20} aria-hidden="true" />
          <div>
            <strong>Changes requested</strong>
            <p>{application.returnReason}</p>
          </div>
        </div>
      )}

      <ApplicationSummary application={application} />

      <div className="detail-columns">
        <section className="content-card">
          <div className="section-heading compact">
            <div>
              <span className="eyebrow">Client information</span>
              <h2>Contact and ownership</h2>
            </div>
          </div>
          <dl className="review-facts">
            <div>
              <dt>Primary contact</dt>
              <dd>
                {application.contact.firstName} {application.contact.lastName}
              </dd>
            </div>
            <div>
              <dt>Contact email</dt>
              <dd>{application.contact.email || "Not provided"}</dd>
            </div>
            <div>
              <dt>Contact phone</dt>
              <dd>{application.contact.phone || "Not provided"}</dd>
            </div>
            <div>
              <dt>Beneficial owners</dt>
              <dd>{application.owners.length}</dd>
            </div>
          </dl>
          <ul className="owner-summary-list">
            {application.owners.map((owner) => (
              <li key={owner.id}>
                <span>
                  <strong>{owner.name || "Unnamed owner"}</strong>
                  <small>{owner.title || "Title not provided"}</small>
                </span>
                <span>{owner.ownershipPercent}%</span>
                {owner.isController && <em>Controller</em>}
              </li>
            ))}
          </ul>
        </section>

        <section className="content-card">
          <div className="section-heading compact">
            <div>
              <span className="eyebrow">Complete history</span>
              <h2>Audit timeline</h2>
            </div>
          </div>
          <ol className="audit-timeline">
            {[...application.audit].reverse().map((event) => (
              <li key={event.id}>
                <span className="timeline-marker" aria-hidden="true" />
                <div>
                  <strong>{event.action}</strong>
                  <p>{event.detail}</p>
                  <small>
                    {event.actor} · {formatDateTime(event.timestamp)}
                  </small>
                </div>
              </li>
            ))}
          </ol>
        </section>
      </div>
    </div>
  );
}
