import {
  useState,
  type ReactNode,
} from "react";
import {
  createEmptyApplication,
  seedApplications,
  USERS,
} from "../lib/applicationData";
import type {
  ApplicationStatus,
  BusinessApplication,
  UserProfile,
} from "../types";
import { OnboardingContext } from "./context";

const STORAGE_KEY = "business-banking-onboarding-applications";
const USER_KEY = "business-banking-onboarding-user";

function loadApplications(): BusinessApplication[] {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    return saved ? (JSON.parse(saved) as BusinessApplication[]) : seedApplications();
  } catch {
    return seedApplications();
  }
}

function loadUser(): UserProfile {
  const userId = localStorage.getItem(USER_KEY);
  return USERS.find((user) => user.id === userId) ?? USERS[0];
}

export function OnboardingProvider({ children }: { children: ReactNode }) {
  const [currentUser, updateCurrentUser] = useState<UserProfile>(loadUser);
  const [applications, setApplications] =
    useState<BusinessApplication[]>(loadApplications);

  const persistApplications = (next: BusinessApplication[]) => {
    setApplications(next);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  };

  const setCurrentUser = (userId: string) => {
    const user = USERS.find((candidate) => candidate.id === userId);
    if (!user) return;
    updateCurrentUser(user);
    localStorage.setItem(USER_KEY, user.id);
  };

  const createApplication = () => {
    const application = createEmptyApplication(currentUser);
    persistApplications([application, ...applications]);
    return application;
  };

  const saveApplication = (
    application: BusinessApplication,
    auditDetail?: string,
  ) => {
    const timestamp = new Date().toISOString();
    const updated: BusinessApplication = {
      ...application,
      version: application.version + 1,
      updatedAt: timestamp,
      audit: auditDetail
        ? [
            ...application.audit,
            {
              id: crypto.randomUUID(),
              timestamp,
              actor: currentUser.name,
              action: auditDetail,
              detail: `Application version ${application.version + 1}.`,
            },
          ]
        : application.audit,
    };
    persistApplications(
      applications.map((item) => (item.id === updated.id ? updated : item)),
    );
    return updated;
  };

  const decideApplication = (
    id: string,
    status: Extract<
      ApplicationStatus,
      "APPROVED" | "RETURNED" | "REJECTED"
    >,
    reason: string,
  ) => {
    const timestamp = new Date().toISOString();
    const action =
      status === "APPROVED"
        ? "Application approved"
        : status === "RETURNED"
          ? "Returned for changes"
          : "Application rejected";
    persistApplications(
      applications.map((application) =>
        application.id === id
          ? {
              ...application,
              status,
              version: application.version + 1,
              updatedAt: timestamp,
              decisionAt: timestamp,
              decisionReason: status !== "RETURNED" ? reason : undefined,
              returnReason: status === "RETURNED" ? reason : undefined,
              audit: [
                ...application.audit,
                {
                  id: crypto.randomUUID(),
                  timestamp,
                  actor: currentUser.name,
                  action,
                  detail: reason || "No additional comments.",
                },
              ],
            }
          : application,
      ),
    );
  };

  const findApplication = (id: string) =>
    applications.find((application) => application.id === id);

  const resetDemoData = () => {
    const seeded = seedApplications();
    persistApplications(seeded);
  };

  const value = {
    currentUser,
    users: USERS,
    applications,
    setCurrentUser,
    createApplication,
    saveApplication,
    decideApplication,
    findApplication,
    resetDemoData,
  };

  return (
    <OnboardingContext.Provider value={value}>
      {children}
    </OnboardingContext.Provider>
  );
}
