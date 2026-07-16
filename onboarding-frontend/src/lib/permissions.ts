import type {
  BusinessApplication,
  UserProfile,
  UserRole,
} from "../types";

export const ROLE_LABELS: Record<UserRole, string> = {
  RELATIONSHIP_MANAGER: "Relationship Manager",
  OPERATIONS_ANALYST: "Operations Analyst",
  APPROVER: "Approver",
  AUDITOR: "Auditor / Read only",
};

export function canCreate(role: UserRole): boolean {
  return role === "RELATIONSHIP_MANAGER" || role === "OPERATIONS_ANALYST";
}

export function canEdit(
  user: UserProfile,
  application: BusinessApplication,
): boolean {
  if (
    user.role !== "RELATIONSHIP_MANAGER" &&
    user.role !== "OPERATIONS_ANALYST"
  ) {
    return false;
  }
  if (application.status !== "DRAFT" && application.status !== "RETURNED") {
    return false;
  }
  return (
    user.role === "OPERATIONS_ANALYST" || application.ownerId === user.id
  );
}

export function canDecide(
  user: UserProfile,
  application: BusinessApplication,
): boolean {
  return (
    user.role === "APPROVER" &&
    application.status === "SUBMITTED" &&
    application.ownerId !== user.id
  );
}

export function canViewSensitive(role: UserRole): boolean {
  return role === "OPERATIONS_ANALYST" || role === "APPROVER";
}
