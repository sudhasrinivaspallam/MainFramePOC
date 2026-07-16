import type { ReactNode } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { useOnboarding } from "../state/useOnboarding";
import type { UserRole } from "../types";

export function PermissionGuard({
  roles,
  children,
}: {
  roles: UserRole[];
  children: ReactNode;
}) {
  const { currentUser } = useOnboarding();
  const location = useLocation();

  if (!roles.includes(currentUser.role)) {
    return (
      <Navigate
        to="/access-denied"
        replace
        state={{ from: location.pathname }}
      />
    );
  }

  return children;
}
