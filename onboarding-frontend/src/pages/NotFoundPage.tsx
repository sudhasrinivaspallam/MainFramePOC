import { FileQuestion } from "lucide-react";
import { Link } from "react-router-dom";

export default function NotFoundPage() {
  return (
    <div className="centered-state">
      <span className="state-icon">
        <FileQuestion size={30} aria-hidden="true" />
      </span>
      <h1>Page not found</h1>
      <p>The requested onboarding page does not exist or may have moved.</p>
      <Link className="button button-primary" to="/onboarding">
        Return to dashboard
      </Link>
    </div>
  );
}
