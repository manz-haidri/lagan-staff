'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { fetchAdminWorkers, reviewWorker, AdminWorkerRecord } from '@/lib/worker-service';
import {
  CheckCircle2,
  Eye,
  Info,
  Search,
} from 'lucide-react';

export default function WorkerVerificationQueuePage() {
  const [workers, setWorkers] = useState<AdminWorkerRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'pending' | 'needs_attention'>('pending');
  const [searchTerm, setSearchTerm] = useState('');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  useEffect(() => {
    async function load() {
      setLoading(true);
      const data = await fetchAdminWorkers();
      setWorkers(data);
      setLoading(false);
    }
    load();
  }, []);

  const queueWorkers = workers.filter((w) => {
    if (filter === 'pending' && w.review_status !== 'not_reviewed') return false;
    if (filter === 'needs_attention' && w.review_status !== 'needs_attention') return false;
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

  const handleQuickReview = async (id: string) => {
    setActionLoading(id);
    const res = await reviewWorker(id, 'reviewed', 'Quick review approved from verification queue');
    if (res.success) {
      setWorkers((prev) =>
        prev.map((w) => (w.id === id ? { ...w, review_status: 'reviewed' } : w))
      );
    }
    setActionLoading(null);
  };

  return (
    <AdminShell>
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Worker Post-Registration Review
            </h1>
            <span className="rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-bold text-amber-900">
              {queueWorkers.length} Pending
            </span>
          </div>
          <p className="text-xs text-slate-500 font-medium">
            Post-onboarding quality inspection queue for Ghazipur temporary workforce.
          </p>
        </div>

        <Link
          href="/admin/workers"
          className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 shadow-xs"
        >
          <span>All Workers Directory</span>
        </Link>
      </div>

      {/* Policy Notice Box */}
      <div className="mt-4 rounded-xl border border-blue-200 bg-blue-50/70 p-4 shadow-xs">
        <div className="flex gap-3">
          <Info className="h-5 w-5 text-blue-700 shrink-0 mt-0.5" />
          <div className="text-xs text-blue-900 leading-relaxed">
            <span className="font-bold">LaganStaff Policy Reminder: </span>
            Workers are <strong>automatically activated upon completing registration</strong> to ensure zero delays in finding shifts in Ghazipur. This post-registration review queue allows platform administrators to audit profile photos, identity selfies, and selected skills without blocking the worker&apos;s ability to browse and accept shifts, unless suspended.
          </div>
        </div>
      </div>

      {/* Filter Tabs & Search */}
      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white p-3.5 rounded-xl border border-slate-200 shadow-xs">
        <div className="inline-flex rounded-lg border border-slate-200 bg-slate-50 p-0.5 text-xs">
          <button
            onClick={() => setFilter('pending')}
            className={`rounded-md px-3 py-1.5 text-xs font-semibold transition ${
              filter === 'pending'
                ? 'bg-white text-indigo-950 shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Not Reviewed Yet
          </button>
          <button
            onClick={() => setFilter('needs_attention')}
            className={`rounded-md px-3 py-1.5 text-xs font-semibold transition ${
              filter === 'needs_attention'
                ? 'bg-white text-amber-950 shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Flagged: Needs Attention
          </button>
        </div>

        <div className="relative w-full sm:w-72">
          <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-slate-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search worker by name, phone..."
            className="w-full rounded-lg border border-slate-300 pl-9 pr-3 py-1.5 text-xs focus:border-indigo-600 focus:outline-none"
          />
        </div>
      </div>

      {/* Review Queue List */}
      <div className="mt-4 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xs">
        {loading ? (
          <div className="p-12 text-center text-xs text-slate-500">Loading review queue...</div>
        ) : queueWorkers.length === 0 ? (
          <div className="p-12 text-center text-xs text-slate-500">
            <CheckCircle2 className="mx-auto h-8 w-8 text-emerald-500 mb-2" />
            <p className="font-semibold text-slate-700">All registered workers are reviewed!</p>
            <p className="text-slate-400 mt-0.5">No profiles currently pending quality inspection.</p>
          </div>
        ) : (
          <table className="min-w-full divide-y divide-slate-200 text-left text-xs">
            <thead className="bg-slate-50 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-4 py-3">Worker Info</th>
                <th className="px-4 py-3">Location</th>
                <th className="px-4 py-3">Skills Selected</th>
                <th className="px-4 py-3">Registered On</th>
                <th className="px-4 py-3 text-right">Review Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {queueWorkers.map((w) => (
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
                        w.skills.map((s, idx) => (
                          <span
                            key={idx}
                            className="inline-block rounded bg-indigo-50 border border-indigo-100 px-1.5 py-0.5 text-[10px] font-medium text-indigo-900"
                          >
                            {s}
                          </span>
                        ))
                      ) : (
                        <span className="text-[11px] text-slate-400">None</span>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3.5 text-slate-500">
                    {new Date(w.created_at).toLocaleDateString('en-IN', { timeZone: 'Asia/Kolkata' })}
                  </td>
                  <td className="px-4 py-3.5 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => handleQuickReview(w.id)}
                        disabled={actionLoading === w.id}
                        className="inline-flex items-center gap-1 rounded-md bg-emerald-600 px-2.5 py-1 text-xs font-semibold text-white hover:bg-emerald-700 disabled:opacity-50 shadow-xs"
                      >
                        <CheckCircle2 className="h-3 w-3" />
                        <span>Pass Review</span>
                      </button>
                      <Link
                        href={`/admin/workers/${w.id}`}
                        className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-slate-200"
                      >
                        <Eye className="h-3 w-3" />
                        <span>Inspect</span>
                      </Link>
                    </div>
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
