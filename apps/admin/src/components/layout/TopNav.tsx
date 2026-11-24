'use client';

import React from 'react';
import Link from 'next/link';
import { Menu, Bell, LogOut } from 'lucide-react';

interface TopNavProps {
  onMenuToggle: () => void;
}

export const TopNav: React.FC<TopNavProps> = ({ onMenuToggle }) => {
  return (
    <header className="sticky top-0 z-30 flex h-16 w-full items-center justify-between border-b border-slate-200 bg-white/95 px-4 backdrop-blur-sm lg:px-8">
      {/* Mobile Menu Button & Title */}
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={onMenuToggle}
          className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 lg:hidden"
          aria-label="Toggle navigation"
        >
          <Menu className="h-6 w-6" />
        </button>
        <div className="hidden items-center gap-2 rounded-full border border-slate-200 bg-slate-50 px-3 py-1 text-xs font-medium text-slate-700 sm:flex">
          <span className="h-2 w-2 rounded-full bg-emerald-500" />
          <span>Operational: Ghazipur District</span>
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-3">
        {/* Notifications */}
        <button
          type="button"
          className="relative rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-slate-700"
          title="Notifications"
        >
          <Bell className="h-5 w-5" />
          <span className="absolute top-1.5 right-1.5 flex h-2 w-2">
            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-amber-400 opacity-75" />
            <span className="relative inline-flex h-2 w-2 rounded-full bg-amber-500" />
          </span>
        </button>

        {/* Admin Profile */}
        <div className="flex items-center gap-2 border-l border-slate-200 pl-3">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-indigo-100 text-indigo-900 font-bold text-xs">
            OP
          </div>
          <div className="hidden text-left sm:block">
            <div className="text-xs font-semibold text-slate-900">Operator Lead</div>
            <div className="text-[10px] text-slate-500">Super Admin</div>
          </div>
          <Link
            href="/login"
            className="ml-2 rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 hover:text-red-600"
            title="Log Out"
          >
            <LogOut className="h-4 w-4" />
          </Link>
        </div>
      </div>
    </header>
  );
};
