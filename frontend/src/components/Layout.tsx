import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import {
  CreditCard,
  LayoutDashboard,
  ArrowRightLeft,
  PlayCircle,
  FileText,
  Menu,
  X,
  Wifi,
  WifiOff,
  ChevronDown,
  ChevronRight,
} from "lucide-react";
import { isOfflineMode } from "../api/client";

interface LayoutProps {
  children: React.ReactNode;
}

const navGroups = [
  {
    label: "Overview",
    items: [
      { path: "/", icon: LayoutDashboard, label: "Dashboard" },
    ],
  },
  {
    label: "Card Management",
    items: [
      { path: "/cards", icon: CreditCard, label: "Card Inquiry" },
      { path: "/cards/issue", icon: CreditCard, label: "Card Issuance" },
      { path: "/cards/activate", icon: CreditCard, label: "Card Activation" },
      { path: "/cards/status", icon: CreditCard, label: "Status Update" },
      { path: "/cards/renew", icon: CreditCard, label: "Card Renewal" },
    ],
  },
  {
    label: "Settlement",
    items: [
      { path: "/settlement", icon: ArrowRightLeft, label: "Transactions" },
      { path: "/settlement/reports", icon: FileText, label: "Reports" },
    ],
  },
  {
    label: "Operations",
    items: [
      { path: "/batch", icon: PlayCircle, label: "Batch Pipeline" },
    ],
  },
];

export default function Layout({ children }: LayoutProps) {
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [expandedGroups, setExpandedGroups] = useState<Record<string, boolean>>({
    Overview: true,
    "Card Management": true,
    Settlement: true,
    Operations: true,
  });
  const offline = isOfflineMode();

  const toggleGroup = (label: string) => {
    setExpandedGroups((prev) => ({ ...prev, [label]: !prev[label] }));
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-gradient-to-r from-red-800 via-red-700 to-red-800 text-white shadow-lg fixed top-0 left-0 right-0 z-50">
        <div className="flex items-center justify-between px-4 h-14">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="p-1.5 rounded hover:bg-red-600 transition-colors"
            >
              {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-yellow-500 rounded flex items-center justify-center font-bold text-red-900 text-sm">
                WF
              </div>
              <div>
                <h1 className="text-base font-semibold leading-tight">
                  Payments Division
                </h1>
                <p className="text-xs text-red-200 leading-tight">
                  Plastic Issuance & Settlement
                </p>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <div
              className={`flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${
                offline
                  ? "bg-yellow-600 text-yellow-100"
                  : "bg-green-600 text-green-100"
              }`}
            >
              {offline ? <WifiOff size={12} /> : <Wifi size={12} />}
              {offline ? "Offline Mode" : "Connected"}
            </div>
          </div>
        </div>
      </header>

      <div className="flex pt-14">
        {/* Sidebar */}
        <aside
          className={`fixed top-14 left-0 bottom-0 bg-white border-r border-gray-200 shadow-sm transition-all duration-300 z-40 overflow-y-auto ${
            sidebarOpen ? "w-56" : "w-0 overflow-hidden"
          }`}
        >
          <nav className="py-3">
            {navGroups.map((group) => (
              <div key={group.label} className="mb-1">
                <button
                  onClick={() => toggleGroup(group.label)}
                  className="w-full flex items-center justify-between px-4 py-1.5 text-xs font-semibold text-gray-500 uppercase tracking-wider hover:text-gray-700"
                >
                  {group.label}
                  {expandedGroups[group.label] ? (
                    <ChevronDown size={12} />
                  ) : (
                    <ChevronRight size={12} />
                  )}
                </button>
                {expandedGroups[group.label] && (
                  <div>
                    {group.items.map((item) => {
                      const isActive = location.pathname === item.path;
                      return (
                        <Link
                          key={item.path}
                          to={item.path}
                          className={`flex items-center gap-2.5 px-4 py-2 text-sm transition-colors ${
                            isActive
                              ? "bg-red-50 text-red-800 border-r-3 border-red-700 font-medium"
                              : "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
                          }`}
                        >
                          <item.icon size={16} />
                          {item.label}
                        </Link>
                      );
                    })}
                  </div>
                )}
              </div>
            ))}
          </nav>
        </aside>

        {/* Main content */}
        <main
          className={`flex-1 transition-all duration-300 ${
            sidebarOpen ? "ml-56" : "ml-0"
          }`}
        >
          <div className="p-6">{children}</div>
        </main>
      </div>
    </div>
  );
}
