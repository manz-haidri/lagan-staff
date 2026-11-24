'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import {
  fetchAdminComplaints,
  formatComplaintCategory,
  AdminComplaintRecord,
} from '@/lib/complaint-service';
import {
  AlertOctagon,
  Search,
  Clock,
  CheckCircle2,
  XCircle,
  Eye,
  Calendar,
  Building2,
  User,
  AlertTriangle,
} from 'lucide-react';

export default function AdminComplaintsPage() {
  const [complaints, setComplaints] = useState<AdminComplaintRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'open' | 'under_review' | 'resolved' | 'dismissed'>('all');
  const [categoryFilter, setCategoryFilter] = useState('all');

  useEffect(() => {
    async function load() {
      setLoading(true);
      const data = await fetchAdminComplaints({
        status: statusFilter,
        category: categoryFilter,
        search: searchTerm,
      });
      setComplaints(data);
      setLoading(false);
    }
    load();
  }, [searchTerm, statusFilter, categoryFilter]);

  const getStatusBadge = (status: AdminComplaintRecord['complaint_status']) => {
    switch (status) {
      case 'open':
        return (
          <span className="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2.5 py-0.5 text-xs font-bold text-rose-700 border border-rose-200">
            <AlertOctagon className="h-3 w-3" /> Open
          </span>
        );
      case 'under_review':
        return (
          <span className="inline-flex items-center gap-1 rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-semibold text-blue-700 border border-blue-200">
            <Clock className="h-3 w-3" /> Under Review
          </span>
        );
      case 'resolved':
        return (
          <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 border border-emerald-200">
            <CheckCircle2 className="h-3 w-3" /> Resolved
          </span>
        );
      case 'dismissed':
        return (
          <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-semibold text-slate-600 border border-slate-200">
            <XCircle className="h-3 w-3" /> Dismissed
          </span>
        );
    }
  };

  return (
    <AdminShell>
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Disputes & Complaints Queue
            </h1>
            <span className="rounded-full bg-rose-100 px-2.5 py-0.5 text-xs font-bold text-rose-900">
              {complaints.length} Tickets
            </span>
          </div>
          <p className="text-xs text-slate-500 font-medium">
            Triage marketplace grievances between gig workers and business owners in Ghazipur.
          </p>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white p-3.5 rounded-xl border border-slate-200 shadow-xs">
        <div className="flex flex-wrap items-center gap-2">
          {/* Status Tabs */}
          <div className="inline-flex rounded-lg border border-slate-200 bg-slate-50 p-0.5 text-xs">
            {(['all', 'open', 'under_review', 'resolved', 'dismissed'] as const).map((s) => (
              <button
                key={s}
                onClick={() => setStatusFilter(s)}
                className={`rounded-md px-2.5 py-1 text-xs font-semibold capitalize transition ${
                  statusFilter === s
                    ? 'bg-white text-indigo-950 shadow-xs'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                {s === 'all' ? 'All Tickets' : s.replace('_', ' ')}
              </button>
            ))}
          </div>

          {/* Category Filter */}
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="rounded-lg border border-slate-300 bg-white px-2.5 py-1 text-xs font-medium text-slate-700 focus:border-indigo-600 focus:outline-none"
          >
            <option value="all">All Categories</option>
            <option value="worker_no_show">Worker No-Show</option>
            <option value="owner_cancellation">Owner Cancellation</option>
            <option value="payment_dispute">Payment Dispute</option>
            <option value="misbehaviour">Misbehaviour</option>
            <option value="incorrect_job_info">Incorrect Job Info</option>
            <option value="fake_profile">Fake Profile</option>
            <option value="other">Other</option>
          </select>
        </div>

        <div className="relative w-full sm:w-72">
          <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-slate-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search complaint description or reporter..."
            className="w-full rounded-lg border border-slate-300 pl-9 pr-3 py-1.5 text-xs focus:border-indigo-600 focus:outline-none"
          />
        </div>
      </div>

      {/* Complaints Table */}
      <div className="mt-4 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xs">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200 text-left text-xs">
            <thead className="bg-slate-50 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-4 py-3">Ticket ID & Date</th>
                <th className="px-4 py-3">Category</th>
                <th className="px-4 py-3">Reporter & Target</th>
                <th className="px-4 py-3">Grievance Summary</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Investigation</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-4 py-12 text-center text-slate-400">
                    Loading complaints queue...
                  </td>
                </tr>
              ) : complaints.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-12 text-center text-slate-400">
                    <CheckCircle2 className="mx-auto h-8 w-8 text-emerald-500 mb-2" />
                    No complaints matching current filters.
                  </td>
                </tr>
              ) : (
                complaints.map((cmp) => (
                  <tr key={cmp.id} className="hover:bg-slate-50/80 transition">
                    <td className="px-4 py-3.5 font-mono text-[11px] text-slate-500">
                      <div>{cmp.id.substring(0, 10)}...</div>
                      <div className="text-[10px] text-slate-400 mt-0.5">
                        {new Date(cmp.submitted_at).toLocaleDateString('en-IN', { timeZone: 'Asia/Kolkata' })}
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      <span className="rounded bg-slate-100 px-2 py-0.5 text-[10px] font-bold text-slate-700 uppercase">
                        {cmp.category.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="font-semibold text-slate-900 flex items-center gap-1">
                        <User className="h-3 w-3 text-slate-400" />
                        By: {cmp.submitted_by_name}
                      </div>
                      {cmp.reported_user_name && (
                        <div className="text-[11px] text-rose-600 font-medium mt-0.5">
                          Against: {cmp.reported_user_name}
                        </div>
                      )}
                    </td>
                    <td className="px-4 py-3.5 max-w-sm text-slate-700">
                      <p className="line-clamp-2">{cmp.description}</p>
                    </td>
                    <td className="px-4 py-3.5">
                      {getStatusBadge(cmp.complaint_status)}
                    </td>
                    <td className="px-4 py-3.5 text-right">
                      <Link
                        href={`/admin/complaints/${cmp.id}`}
                        className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-indigo-50 hover:text-indigo-900 transition"
                      >
                        <Eye className="h-3 w-3" />
                        <span>Inspect</span>
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
