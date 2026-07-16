import { createContext } from "react";
import type {
  ApplicationStatus,
  BusinessApplication,
  UserProfile,
} from "../types";

export interface OnboardingContextValue {
  currentUser: UserProfile;
  users: UserProfile[];
  applications: BusinessApplication[];
  setCurrentUser: (userId: string) => void;
  createApplication: () => BusinessApplication;
  saveApplication: (
    application: BusinessApplication,
    auditDetail?: string,
  ) => BusinessApplication;
  decideApplication: (
    id: string,
    status: Extract<ApplicationStatus, "APPROVED" | "RETURNED" | "REJECTED">,
    reason: string,
  ) => void;
  findApplication: (id: string) => BusinessApplication | undefined;
  resetDemoData: () => void;
}

export const OnboardingContext =
  createContext<OnboardingContextValue | null>(null);
