import { AlertCircle } from "lucide-react";
import { useEffect, useRef } from "react";
import type { ValidationErrors } from "../types";

export function ErrorSummary({ errors }: { errors: ValidationErrors }) {
  const headingRef = useRef<HTMLHeadingElement>(null);
  const entries = Object.entries(errors);

  useEffect(() => {
    if (entries.length > 0) {
      headingRef.current?.focus();
    }
  }, [entries.length]);

  if (entries.length === 0) return null;

  return (
    <section className="error-summary" role="alert" aria-labelledby="error-title">
      <AlertCircle size={22} aria-hidden="true" />
      <div>
        <h2 id="error-title" ref={headingRef} tabIndex={-1}>
          Review {entries.length} item{entries.length === 1 ? "" : "s"} before
          continuing
        </h2>
        <ul>
          {entries.map(([field, message]) => (
            <li key={field}>
              <a href={`#${field}`}>{message}</a>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
