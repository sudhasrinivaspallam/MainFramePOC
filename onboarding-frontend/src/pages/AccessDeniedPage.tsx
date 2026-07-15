import { LockKeyhole } from "lucide-react";
import { Link, useLocation } from "react-router-dom";

export default function AccessDeniedPage() {
  const location = useLocation();
  const from = (location.state as { from?: string } | null)?.from;

  return (
    <div className="centered-state">
      <span className="state-icon">
        <LockKeyhole size={30} aria-hidden="true" />
      </span>
      <h1>Access restricted</h1>
      <p>
        Your current role does not have permission to access
        {from ? ` ${from}` : " this workspace"}.
      </p>
      <Link className="button button-primary" to="/onboarding">
        Return to dashboard
      </Link>
    </div>
  );
}
