'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { fetchAdminWorkers, AdminWorkerRecord } from '@/lib/worker-service';
import { Search, ShieldAlert, CheckCircle2, AlertTriangle, UserCheck, Eye } from 'lucide-react';

export default function AdminWorkersDirectoryPage() {
  const [workers, setWorkers] = useState<AdminWorkerRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'suspended'>('all');
  const [reviewFilter, setReviewFilter] = useState<'all' | 'not_reviewed' | 'reviewed' | 'needs_attention'>('all');

  useEffect(() => {
    async function load() {
      setLoading(true);
      const res = await fetchAdminWorkers();
      setWorkers(res);
      setLoading(false);
    }
    load();
  }, []);

  const filtered = workers.filter((w) => {
    if (statusFilter !== 'all' && w.account_status !== statusFilter) return false;
    if (reviewFilter !== 'all' && w.review_status !== reviewFilter) return false;
    if (searchTerm) {
      const q = searchTerm.toLowerCase();
      return (
        w.full_name.toLowerCase().includes(q) ||
        w.mobile_number.includes(q) ||
        w.locality.toLowerCase().includes(q)
      );
    }
    return true;
  });

  return (
    <AdminShell>
      {/* Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">Workers Directory</h1>
            <span className="rounded-full bg-slate-200 px-2.5 py-0.5 text-xs font-bold text-slate-700">
              {workers.length} Total
            </span>
          </div>
          <p className="text-xs text-slate-500 font-medium">
            Inspect gig workers registered across Ghazipur district, manage account statuses & review flags.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Link
            href="/admin/worker-verification"
            className="inline-flex items-center gap-1.5 rounded-lg border border-indigo-200 bg-indigo-50/80 px-3 py-1.5 text-xs font-semibold text-indigo-900 hover:bg-indigo-100 shadow-xs"
          >
            <UserCheck className="h-3.5 w-3.5 text-indigo-700" />
            <span>Post-Reg Review Queue</span>
          </Link>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white p-3.5 rounded-xl border border-slate-200 shadow-xs">
        <div className="flex flex-wrap items-center gap-2">
          {/* Account Status Tabs */}
          <div className="inline-flex rounded-lg border border-slate-200 bg-slate-50 p-0.5 text-xs">
            {(['all', 'active', 'suspended'] as const).map((s) => (
              <button
                key={s}
                onClick={() => setStatusFilter(s)}
                className={`rounded-md px-2.5 py-1 text-xs font-semibold capitalize transition ${
                  statusFilter === s
                    ? 'bg-white text-indigo-950 shadow-xs'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                {s === 'all' ? 'All Accounts' : s}
              </button>
            ))}
          </div>

          {/* Review Status Filter */}
          <select
            value={reviewFilter}
            onChange={(e) => setReviewFilter(e.target.value as AdminWorkerRecord['review_status'] | 'all')}
            className="rounded-lg border border-slate-300 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 focus:border-indigo-600 focus:outline-none"
          >
            <option value="all">All Reviews</option>
            <option value="not_reviewed">Not Reviewed</option>
            <option value="reviewed">Reviewed</option>
            <option value="needs_attention">Needs Attention</option>
          </select>
        </div>

        {/* Search Input */}
        <div className="relative w-full sm:w-72">
          <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-slate-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search by worker name, phone, locality..."
            className="w-full rounded-lg border border-slate-300 pl-9 pr-3 py-1.5 text-xs focus:border-indigo-600 focus:outline-none"
          />
        </div>
      </div>

      {/* Workers Table */}
      <div className="mt-4 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xs">
        {loading ? (
          <div className="p-12 text-center text-xs text-slate-500">Loading worker directory...</div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center text-xs text-slate-500">
            No workers match the selected criteria.
          </div>
        ) : (
          <table className="min-w-full divide-y divide-slate-200 text-left text-xs">
            <thead className="bg-slate-50 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-4 py-3">Worker Details</th>
                <th className="px-4 py-3">Locality</th>
                <th className="px-4 py-3">Skills Registered</th>
                <th className="px-4 py-3">Account Status</th>
                <th className="px-4 py-3">Post-Reg Review</th>
                <th className="px-4 py-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {filtered.map((w) => (
                <tr key={w.id} className="hover:bg-slate-50/80 transition">
                  <td className="px-4 py-3.5">
                    <div className="font-semibold text-slate-900">{w.full_name}</div>
                    <div className="font-mono text-[11px] text-slate-500">{w.mobile_number}</div>
                  </td>
                  <td className="px-4 py-3.5">
                    <span className="font-medium text-slate-800">{w.locality}</span>
                    <div className="text-[11px] text-slate-400">{w.city || 'Ghazipur'}</div>
                  </td>
                  <td className="px-4 py-3.5">
                    <div className="flex flex-wrap gap-1">
                      {w.skills && w.skills.length > 0 ? (
                        w.skills.slice(0, 2).map((s, idx) => (
                          <span
                            key={idx}
                            className="inline-block rounded bg-slate-100 px-1.5 py-0.5 text-[10px] font-medium text-slate-700"
                          >
                            {s}
                          </span>
                        ))
                      ) : (
                        <span className="text-[11px] text-slate-400">None</span>
                      )}
                      {w.skills && w.skills.length > 2 && (
                        <span className="text-[10px] text-slate-400 font-medium">
                          +{w.skills.length - 2} more
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3.5">
                    {w.account_status === 'active' ? (
                      <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-semibold text-emerald-700 border border-emerald-200">
                        <CheckCircle2 className="h-3 w-3" />
                        Active
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-semibold text-rose-700 border border-rose-200">
                        <ShieldAlert className="h-3 w-3" />
                        Suspended
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3.5">
                    {w.review_status === 'reviewed' ? (
                      <span className="inline-flex items-center gap-1 rounded-md bg-blue-50 px-2 py-0.5 text-[11px] font-medium text-blue-700 border border-blue-200">
                        <UserCheck className="h-3 w-3" />
                        Reviewed
                      </span>
                    ) : w.review_status === 'needs_attention' ? (
                      <span className="inline-flex items-center gap-1 rounded-md bg-amber-50 px-2 py-0.5 text-[11px] font-medium text-amber-700 border border-amber-200">
                        <AlertTriangle className="h-3 w-3" />
                        Needs Attention
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2 py-0.5 text-[11px] font-medium text-slate-600">
                        Not Reviewed
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3.5 text-right">
                    <Link
                      href={`/admin/workers/${w.id}`}
                      className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-indigo-50 hover:text-indigo-900 transition"
                    >
                      <Eye className="h-3 w-3" />
                      <span>Inspect</span>
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </AdminShell>
  );
}
