import { Component, type ErrorInfo, type ReactNode } from "react";
import { AlertTriangle, RefreshCcw } from "lucide-react";

interface State {
  hasError: boolean;
  reference: string;
}

export class ErrorBoundary extends Component<
  { children: ReactNode },
  State
> {
  state: State = {
    hasError: false,
    reference: "",
  };

  static getDerivedStateFromError(): State {
    return {
      hasError: true,
      reference: `BBO-${Date.now().toString().slice(-8)}`,
    };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error("Onboarding portal error", error, info);
  }

  render() {
    if (this.state.hasError) {
      return (
        <main className="fatal-error">
          <span className="state-icon">
            <AlertTriangle size={30} aria-hidden="true" />
          </span>
          <h1>We could not load this page</h1>
          <p>
            Your saved applications are still available. Refresh the portal
            and try again.
          </p>
          <p className="correlation-id">
            Support reference: {this.state.reference}
          </p>
          <button
            className="button button-primary"
            type="button"
            onClick={() => window.location.reload()}
          >
            <RefreshCcw size={17} aria-hidden="true" />
            Reload portal
          </button>
        </main>
      );
    }

    return this.props.children;
  }
}
