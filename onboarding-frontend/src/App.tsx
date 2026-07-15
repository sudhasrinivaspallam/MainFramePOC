import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AppShell } from "./components/AppShell";
import { ErrorBoundary } from "./components/ErrorBoundary";
import { PermissionGuard } from "./components/PermissionGuard";
import AccessDeniedPage from "./pages/AccessDeniedPage";
import ApplicationDetailPage from "./pages/ApplicationDetailPage";
import ApprovalDecisionPage from "./pages/ApprovalDecisionPage";
import ApprovalQueuePage from "./pages/ApprovalQueuePage";
import DashboardPage from "./pages/DashboardPage";
import InquiryPage from "./pages/InquiryPage";
import NotFoundPage from "./pages/NotFoundPage";
import OnboardingWizardPage from "./pages/OnboardingWizardPage";
import StartApplicationPage from "./pages/StartApplicationPage";
import { OnboardingProvider } from "./state/OnboardingContext";

export default function App() {
  return (
    <ErrorBoundary>
      <OnboardingProvider>
        <BrowserRouter>
          <AppShell>
            <Routes>
              <Route path="/" element={<Navigate to="/onboarding" replace />} />
              <Route path="/onboarding" element={<DashboardPage />} />
              <Route
                path="/onboarding/new"
                element={
                  <PermissionGuard
                    roles={["RELATIONSHIP_MANAGER", "OPERATIONS_ANALYST"]}
                  >
                    <StartApplicationPage />
                  </PermissionGuard>
                }
              />
              <Route
                path="/onboarding/:id/edit/:step"
                element={
                  <PermissionGuard
                    roles={["RELATIONSHIP_MANAGER", "OPERATIONS_ANALYST"]}
                  >
                    <OnboardingWizardPage />
                  </PermissionGuard>
                }
              />
              <Route
                path="/onboarding/approvals"
                element={
                  <PermissionGuard roles={["APPROVER"]}>
                    <ApprovalQueuePage />
                  </PermissionGuard>
                }
              />
              <Route
                path="/onboarding/:id/decision"
                element={
                  <PermissionGuard roles={["APPROVER"]}>
                    <ApprovalDecisionPage />
                  </PermissionGuard>
                }
              />
              <Route path="/onboarding/inquiry" element={<InquiryPage />} />
              <Route
                path="/onboarding/:id"
                element={<ApplicationDetailPage />}
              />
              <Route path="/access-denied" element={<AccessDeniedPage />} />
              <Route path="*" element={<NotFoundPage />} />
            </Routes>
          </AppShell>
        </BrowserRouter>
      </OnboardingProvider>
    </ErrorBoundary>
  );
}
