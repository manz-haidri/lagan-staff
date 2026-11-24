'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { fetchAdminNoShows, AdminNoShowRecord } from '@/lib/no-show-service';
import {
  XCircle,
  AlertTriangle,
  Search,
  User,
  Building2,
  Calendar,
  Clock,
  ShieldAlert,
  Eye,
  Info,
} from 'lucide-react';

export default function AdminNoShowsPage() {
  const [noShows, setNoShows] = useState<AdminNoShowRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    async function load() {
      setLoading(true);
      const data = await fetchAdminNoShows();
      setNoShows(data);
      setLoading(false);
    }
    load();
  }, []);

  const filtered = noShows.filter((ns) => {
    if (!searchTerm) return true;
    const q = searchTerm.toLowerCase();
    return (
      ns.worker_name.toLowerCase().includes(q) ||
      ns.worker_phone.includes(q) ||
      ns.business_name.toLowerCase().includes(q) ||
      ns.job_title.toLowerCase().includes(q)
    );
  });

  return (
    <AdminShell>
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              No-Show Incidents Tracker
            </h1>
            <span className="rounded-full bg-rose-100 px-2.5 py-0.5 text-xs font-bold text-rose-900">
              {noShows.length} Incidents
            </span>
          </div>
          <p className="text-xs text-slate-500 font-medium">
            Shift abandonment audit for venue gate attendance across Ghazipur district.
          </p>
        </div>

        <Link
          href="/admin/bookings"
          className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 shadow-xs"
        >
          <span>All Bookings Roster</span>
        </Link>
      </div>

      {/* Policy Notice Box */}
      <div className="mt-4 rounded-xl border border-rose-200 bg-rose-50/70 p-4 shadow-xs">
        <div className="flex gap-3">
          <AlertTriangle className="h-5 w-5 text-rose-700 shrink-0 mt-0.5" />
          <div className="text-xs text-rose-900 leading-relaxed">
            <span className="font-bold">LaganStaff Reliability Standard: </span>
            Workers who accept shifts but fail to check in at venue gates without prior cancellation undermine banquet hall and catering operations. Workers with repeated no-show marks can be audited and suspended via their worker profile page.
          </div>
        </div>
      </div>

      {/* Search Bar */}
      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white p-3.5 rounded-xl border border-slate-200 shadow-xs">
        <div className="relative w-full sm:w-80">
          <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-slate-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search by worker name, phone, or banquet..."
            className="w-full rounded-lg border border-slate-300 pl-9 pr-3 py-1.5 text-xs focus:border-indigo-600 focus:outline-none"
          />
        </div>
      </div>

      {/* No-Shows Table */}
      <div className="mt-4 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xs">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200 text-left text-xs">
            <thead className="bg-slate-50 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-4 py-3">Worker Information</th>
                <th className="px-4 py-3">Shift & Business</th>
                <th className="px-4 py-3">Shift Date</th>
                <th className="px-4 py-3 text-center">Cumulative No-Shows</th>
                <th className="px-4 py-3">Owner Remarks</th>
                <th className="px-4 py-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-4 py-12 text-center text-slate-400">
                    Loading no-show incidents...
                  </td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-12 text-center text-slate-400">
                    No unexcused absence incidents logged.
                  </td>
                </tr>
              ) : (
                filtered.map((ns) => (
                  <tr key={ns.id} className="hover:bg-slate-50/80 transition">
                    <td className="px-4 py-3.5">
                      <div className="font-semibold text-slate-900 flex items-center gap-1">
                        <User className="h-3 w-3 text-slate-400" />
                        {ns.worker_name}
                      </div>
                      <div className="font-mono text-[11px] text-slate-500">{ns.worker_phone}</div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="font-bold text-slate-900">{ns.job_title}</div>
                      <div className="text-[11px] text-slate-500 flex items-center gap-1 mt-0.5">
                        <Building2 className="h-3 w-3 text-slate-400" />
                        {ns.business_name}
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex items-center gap-1 font-semibold text-slate-800">
                        <Calendar className="h-3.5 w-3.5 text-slate-400" />
                        {ns.shift_date}
                      </div>
                      <div className="text-[11px] text-slate-400 mt-0.5">
                        Marked: {new Date(ns.marked_at).toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata' })}
                      </div>
                    </td>
                    <td className="px-4 py-3.5 text-center">
                      <span
                        className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-black ${
                          ns.worker_total_no_shows > 1
                            ? 'bg-rose-100 text-rose-800 border border-rose-200'
                            : 'bg-amber-100 text-amber-800 border border-amber-200'
                        }`}
                      >
                        <ShieldAlert className="h-3 w-3" />
                        {ns.worker_total_no_shows} Strikes
                      </span>
                    </td>
                    <td className="px-4 py-3.5 max-w-xs text-slate-600 truncate">
                      {ns.notes || 'No remarks entered by venue operator.'}
                    </td>
                    <td className="px-4 py-3.5 text-right">
                      <Link
                        href={`/admin/workers/${ns.worker_id}`}
                        className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-rose-50 hover:text-rose-900 transition"
                      >
                        <Eye className="h-3 w-3" />
                        <span>Audit Worker</span>
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </AdminShell>
  );
}
