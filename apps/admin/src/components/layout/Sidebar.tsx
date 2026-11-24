'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  ClipboardCheck,
  Users,
  Building2,
  Briefcase,
  CalendarCheck,
  Settings,
  ShieldCheck,
  UserCheck,
  AlertOctagon,
  BarChart3,
  Layers,
  UserX,
  FileCheck2,
} from 'lucide-react';

interface SidebarProps {
  isOpen: boolean;
  onClose?: () => void;
}

interface NavItem {
  label: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: string;
  badgeColor?: string;
}

interface NavSection {
  title: string;
  items: NavItem[];
}

const navSections: NavSection[] = [
  {
    title: 'Verification Queues',
    items: [
      { label: 'Overview', href: '/admin/dashboard', icon: LayoutDashboard },
      { label: 'Business Verifications', href: '/admin/business-verifications', icon: Building2, badge: 'Queue', badgeColor: 'bg-amber-100 text-amber-800' },
      { label: 'First-Job Approvals', href: '/admin/job-approvals', icon: ClipboardCheck, badge: 'Queue', badgeColor: 'bg-indigo-100 text-indigo-800' },
      { label: 'Worker Review', href: '/admin/worker-verification', icon: FileCheck2 },
    ],
  },
  {
    title: 'Platform Records',
    items: [
      { label: 'Workers Directory', href: '/admin/workers', icon: Users },
      { label: 'Owners Directory', href: '/admin/owners', icon: UserCheck },
      { label: 'Businesses', href: '/admin/businesses', icon: Building2 },
      { label: 'Master Jobs', href: '/admin/jobs', icon: Briefcase },
      { label: 'Bookings & Shifts', href: '/admin/bookings', icon: CalendarCheck },
    ],
  },
  {
    title: 'Governance & Insights',
    items: [
      { label: 'Complaints Queue', href: '/admin/complaints', icon: AlertOctagon, badge: 'Active', badgeColor: 'bg-red-100 text-red-800' },
      { label: 'No-Show Incidents', href: '/admin/no-shows', icon: UserX },
      { label: 'Categories & Skills', href: '/admin/categories', icon: Layers },
      { label: 'Platform Analytics', href: '/admin/analytics', icon: BarChart3 },
      { label: 'Admin Settings', href: '/admin/settings', icon: Settings },
    ],
  },
];

export const Sidebar: React.FC<SidebarProps> = ({ isOpen, onClose }) => {
  const pathname = usePathname();

  return (
    <>
      {/* Backdrop for mobile */}
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/40 backdrop-blur-sm lg:hidden"
          onClick={onClose}
        />
      )}

      <aside
        className={`fixed top-0 bottom-0 left-0 z-50 flex w-64 flex-col border-r border-slate-200 bg-white transition-transform duration-200 ease-in-out lg:static lg:translate-x-0 ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Brand Header */}
        <div className="flex h-16 items-center gap-3 border-b border-slate-200 px-6">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-900 text-amber-400 shadow-sm">
            <ShieldCheck className="h-6 w-6" />
          </div>
          <div>
            <div className="font-bold text-slate-900 tracking-tight">LaganStaff</div>
            <div className="text-xs font-medium text-slate-500">Control Center</div>
          </div>
        </div>

        {/* Navigation Sections */}
        <nav className="flex-1 space-y-6 overflow-y-auto px-3 py-4">
          {navSections.map((sec) => (
            <div key={sec.title} className="space-y-1">
              <div className="px-3 pb-1 text-[11px] font-bold uppercase tracking-wider text-slate-400">
                {sec.title}
              </div>
              {sec.items.map((item) => {
                const Icon = item.icon;
                const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`);

                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={onClose}
                    className={`flex items-center justify-between rounded-lg px-3 py-2 text-xs font-medium transition-colors ${
                      isActive
                        ? 'bg-indigo-50 text-indigo-900 font-bold'
                        : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <Icon
                        className={`h-4 w-4 ${
                          isActive ? 'text-indigo-900' : 'text-slate-400'
                        }`}
                      />
                      <span>{item.label}</span>
                    </div>
                    {item.badge && (
                      <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${item.badgeColor || 'bg-slate-100 text-slate-700'}`}>
                        {item.badge}
                      </span>
                    )}
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>

        {/* Cluster Info Footer */}
        <div className="border-t border-slate-200 p-4">
          <div className="rounded-lg bg-slate-50 p-2.5 text-xs text-slate-600">
            <div className="font-semibold text-slate-900">Cluster: Ghazipur, UP</div>
            <div className="mt-0.5 text-[11px] text-slate-500">Node: ap-south-1 • Phase 8 Production</div>
          </div>
        </div>
      </aside>
    </>
  );
};
