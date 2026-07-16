import { ArrowRight, Check, FileText, ShieldCheck } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useOnboarding } from "../state/useOnboarding";

export default function StartApplicationPage() {
  const { createApplication } = useOnboarding();
  const navigate = useNavigate();

  const start = () => {
    const application = createApplication();
    navigate(`/onboarding/${application.id}/edit/business`);
  };

  return (
    <div className="page narrow-page">
      <div className="page-heading">
        <div>
          <span className="eyebrow">New client relationship</span>
          <h1>Start a business banking application</h1>
          <p>
            Create a secure draft and complete the guided onboarding workflow.
          </p>
        </div>
      </div>

      <div className="start-layout">
        <section className="content-card start-card">
          <div className="start-icon">
            <FileText size={28} aria-hidden="true" />
          </div>
          <h2>Before you begin</h2>
          <p>Have the following information available:</p>
          <ul className="check-list">
            <li>
              <Check size={17} aria-hidden="true" />
              Legal entity and tax information
            </li>
            <li>
              <Check size={17} aria-hidden="true" />
              Primary contact and beneficial ownership details
            </li>
            <li>
              <Check size={17} aria-hidden="true" />
              Expected account activity and requested products
            </li>
            <li>
              <Check size={17} aria-hidden="true" />
              Formation, tax, identity, and authorization documents
            </li>
          </ul>
          <div className="start-actions">
            <button
              className="button button-primary"
              type="button"
              onClick={start}
            >
              Create secure draft
              <ArrowRight size={18} aria-hidden="true" />
            </button>
            <button
              className="button button-secondary"
              type="button"
              onClick={() => navigate("/onboarding")}
            >
              Cancel
            </button>
          </div>
        </section>

        <aside className="security-note">
          <ShieldCheck size={22} aria-hidden="true" />
          <div>
            <h2>Your work is protected</h2>
            <p>
              The application is saved as a versioned draft. Only authorized
              team members can view or update client information.
            </p>
          </div>
        </aside>
      </div>
    </div>
  );
}
