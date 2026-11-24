'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import {
  Search,
  Calendar,
  Building2,
  MapPin,
  Users,
  Eye,
  Clock,
} from 'lucide-react';
import {
  AdminJobRecord,
  fetchMasterJobsList,
} from '@/lib/job-service';

export default function AdminJobsDirectoryPage() {
  const [jobs, setJobs] = useState<AdminJobRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [total, setTotal] = useState(0);

  useEffect(() => {
    let isMounted = true;
    fetchMasterJobsList({
      search: search.trim() || undefined,
      status: statusFilter,
    }).then((res) => {
      if (isMounted) {
        setJobs(res.jobs);
        setTotal(res.total);
        setLoading(false);
      }
    });
    return () => {
      isMounted = false;
    };
  }, [search, statusFilter]);

  const getStatusBadge = (status: AdminJobRecord['status']) => {
    switch (status) {
      case 'published':
        return <span className="rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-bold text-emerald-700 border border-emerald-200">Published</span>;
      case 'pending_admin_approval':
        return <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-bold text-amber-700 border border-amber-200">Pending Approval</span>;
      case 'filled':
        return <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[11px] font-bold text-blue-700 border border-blue-200">Filled</span>;
      case 'in_progress':
        return <span className="rounded-full bg-indigo-50 px-2 py-0.5 text-[11px] font-bold text-indigo-700 border border-indigo-200">In Progress</span>;
      case 'completed':
        return <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-700 border border-slate-200">Completed</span>;
      case 'cancelled':
        return <span className="rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-bold text-rose-700 border border-rose-200">Cancelled</span>;
      case 'rejected':
        return <span className="rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-bold text-rose-700 border border-rose-200">Rejected</span>;
      default:
        return <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-600">{status}</span>;
    }
  };

  return (
    <AdminShell>
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">Master Jobs Registry</h1>
            <span className="rounded-full bg-slate-200 px-2.5 py-0.5 text-xs font-bold text-slate-700">
              {total} Shifts
            </span>
          </div>
          <p className="text-xs text-slate-500 font-medium">
            Shift demand from wedding lawns, caterers, and tent houses in Ghazipur.
          </p>
        </div>

        <Link
          href="/admin/job-approvals"
          className="inline-flex items-center gap-1.5 rounded-lg bg-indigo-900 px-3.5 py-1.5 text-xs font-semibold text-white shadow-xs hover:bg-indigo-800"
        >
          <Clock className="h-3.5 w-3.5 text-amber-300" />
          <span>First-Job Review Queue</span>
        </Link>
      </div>

      {/* Filter and Search Bar */}
      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white p-3.5 rounded-xl border border-slate-200 shadow-xs">
        <div className="relative w-full sm:w-80">
          <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search job title, venue, or locality..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-lg border border-slate-300 pl-9 pr-3 py-1.5 text-xs focus:border-indigo-600 focus:outline-none"
          />
        </div>

        <div className="flex items-center gap-2">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="rounded-lg border border-slate-300 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 focus:border-indigo-600 focus:outline-none"
          >
            <option value="all">All Statuses (सभी स्थितियाँ)</option>
            <option value="published">Published (लाइव)</option>
            <option value="pending_admin_approval">Pending Approval (समीक्षा प्रतीक्षित)</option>
            <option value="filled">Filled (भर चुका)</option>
            <option value="in_progress">In Progress (प्रगति पर)</option>
            <option value="completed">Completed (पूर्ण)</option>
            <option value="cancelled">Cancelled (निरस्त)</option>
            <option value="rejected">Rejected (अस्वीकृत)</option>
          </select>
        </div>
      </div>

      {/* Jobs Table */}
      <div className="mt-4 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xs">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200 text-left text-xs">
            <thead className="bg-slate-50 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-4 py-3">Shift Title & Locality</th>
                <th className="px-4 py-3">Business Profile</th>
                <th className="px-4 py-3">Category</th>
                <th className="px-4 py-3">Shift Timing</th>
                <th className="px-4 py-3 text-center">Workers</th>
                <th className="px-4 py-3 font-semibold">Wage (₹)</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {loading ? (
                <tr>
                  <td colSpan={8} className="px-4 py-12 text-center text-slate-400">
                    Loading jobs registry...
                  </td>
                </tr>
              ) : jobs.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-4 py-12 text-center text-slate-400">
                    No jobs match the specified criteria.
                  </td>
                </tr>
              ) : (
                jobs.map((job) => (
                  <tr key={job.id} className="hover:bg-slate-50/80 transition">
                    <td className="px-4 py-3.5">
                      <div className="font-bold text-slate-900">{job.title}</div>
                      <div className="text-[11px] text-slate-400 flex items-center gap-1 mt-0.5">
                        <MapPin className="h-3 w-3 text-slate-400" />
                        {job.locality}, Ghazipur
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="font-semibold text-slate-800 flex items-center gap-1">
                        <Building2 className="h-3 w-3 text-slate-400" />
                        {job.business_name}
                      </div>
                      <div className="text-[11px] text-slate-400 font-mono">{job.contact_phone}</div>
                    </td>
                    <td className="px-4 py-3.5 text-slate-600 font-medium">
                      {job.category_name}
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex items-center gap-1 font-semibold text-slate-800">
                        <Calendar className="h-3.5 w-3.5 text-slate-400" />
                        {job.shift_date}
                      </div>
                      <div className="text-[11px] text-slate-400 mt-0.5">
                        {job.start_time.substring(0, 5)} - {job.end_time.substring(0, 5)}
                      </div>
                    </td>
                    <td className="px-4 py-3.5 text-center font-bold text-slate-900">
                      <span className="inline-flex items-center gap-1 rounded bg-slate-100 px-2 py-0.5 text-xs">
                        <Users className="h-3 w-3 text-slate-500" />
                        {job.workers_confirmed} / {job.workers_needed}
                      </span>
                    </td>
                    <td className="px-4 py-3.5 font-black text-emerald-700">
                      ₹{job.wage_amount}
                    </td>
                    <td className="px-4 py-3.5">
                      {getStatusBadge(job.status)}
                    </td>
                    <td className="px-4 py-3.5 text-right">
                      {job.status === 'pending_admin_approval' ? (
                        <Link
                          href={`/admin/job-approvals/${job.id}`}
                          className="inline-flex items-center gap-1 text-xs font-bold text-amber-700 hover:text-amber-800 bg-amber-50 px-2.5 py-1 rounded-md border border-amber-200"
                        >
                          Review →
                        </Link>
                      ) : (
                        <Link
                          href={`/admin/jobs/${job.id}`}
                          className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-indigo-50 hover:text-indigo-900 transition"
                        >
                          <Eye className="h-3 w-3" />
                          <span>Inspect</span>
                        </Link>
                      )}
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
