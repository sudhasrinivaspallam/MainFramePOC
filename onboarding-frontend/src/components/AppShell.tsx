import {
  BadgeCheck,
  Building2,
  ChevronDown,
  ClipboardCheck,
  FileSearch,
  LayoutDashboard,
  Menu,
  Plus,
  RefreshCcw,
  ShieldCheck,
  X,
} from "lucide-react";
import { useState, type ReactNode } from "react";
import { Link, NavLink } from "react-router-dom";
import { canCreate, ROLE_LABELS } from "../lib/permissions";
import { useOnboarding } from "../state/useOnboarding";

interface NavItem {
  to: string;
  label: string;
  icon: typeof LayoutDashboard;
  roles?: string[];
}

const navItems: NavItem[] = [
  { to: "/onboarding", label: "Dashboard", icon: LayoutDashboard },
  {
    to: "/onboarding/new",
    label: "New application",
    icon: Plus,
    roles: ["RELATIONSHIP_MANAGER", "OPERATIONS_ANALYST"],
  },
  {
    to: "/onboarding/approvals",
    label: "Approval queue",
    icon: ClipboardCheck,
    roles: ["APPROVER"],
  },
  { to: "/onboarding/inquiry", label: "Inquiry", icon: FileSearch },
];

export function AppShell({ children }: { children: ReactNode }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const { currentUser, users, setCurrentUser, resetDemoData } = useOnboarding();
  const visibleItems = navItems.filter(
    (item) => !item.roles || item.roles.includes(currentUser.role),
  );

  return (
    <div className="app-shell">
      <a className="skip-link" href="#main-content">
        Skip to main content
      </a>
      <header className="topbar">
        <div className="brand">
          <button
            className="icon-button mobile-menu"
            type="button"
            aria-label={menuOpen ? "Close navigation" : "Open navigation"}
            aria-expanded={menuOpen}
            onClick={() => setMenuOpen((open) => !open)}
          >
            {menuOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
          <Link to="/onboarding" className="brand-link">
            <span className="brand-mark" aria-hidden="true">
              <Building2 size={21} />
            </span>
            <span>
              <strong>Business Banking</strong>
              <small>Client onboarding</small>
            </span>
          </Link>
        </div>
        <div className="topbar-actions">
          <button
            type="button"
            className="reset-button"
            onClick={resetDemoData}
            title="Restore sample applications"
          >
            <RefreshCcw size={15} aria-hidden="true" />
            Reset demo
          </button>
          <label className="role-switcher">
            <span className="sr-only">Demo as role</span>
            <span className="user-avatar" aria-hidden="true">
              {currentUser.name
                .split(" ")
                .map((part) => part[0])
                .join("")}
            </span>
            <span className="user-copy">
              <strong>{currentUser.name}</strong>
              <small>{ROLE_LABELS[currentUser.role]}</small>
            </span>
            <select
              value={currentUser.id}
              onChange={(event) => setCurrentUser(event.target.value)}
              aria-label="Switch demo user and role"
            >
              {users.map((user) => (
                <option key={user.id} value={user.id}>
                  {user.name} — {ROLE_LABELS[user.role]}
                </option>
              ))}
            </select>
            <ChevronDown size={15} aria-hidden="true" />
          </label>
        </div>
      </header>

      <aside className={`sidebar ${menuOpen ? "sidebar-open" : ""}`}>
        <div className="environment-label">
          <ShieldCheck size={15} aria-hidden="true" />
          Secure employee portal
        </div>
        <nav aria-label="Primary navigation">
          {visibleItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === "/onboarding"}
              onClick={() => setMenuOpen(false)}
              className={({ isActive }) =>
                `nav-link ${isActive ? "nav-link-active" : ""}`
              }
            >
              <item.icon size={19} aria-hidden="true" />
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-help">
          <BadgeCheck size={19} aria-hidden="true" />
          <div>
            <strong>Need onboarding support?</strong>
            <span>Contact Client Operations</span>
          </div>
        </div>
      </aside>

      <main id="main-content" className="main-content" tabIndex={-1}>
        {children}
      </main>

      {menuOpen && (
        <button
          className="sidebar-scrim"
          type="button"
          aria-label="Close navigation"
          onClick={() => setMenuOpen(false)}
        />
      )}

      {!canCreate(currentUser.role) && currentUser.role === "AUDITOR" && (
        <div className="read-only-banner" role="status">
          Auditor view is read only. Sensitive identifiers are masked.
        </div>
      )}
    </div>
  );
}
