'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { fetchAdminOwners, AdminOwnerRecord } from '@/lib/owner-service';
import { Search, Building2, Briefcase, Eye } from 'lucide-react';

export default function AdminOwnersDirectoryPage() {
  const [owners, setOwners] = useState<AdminOwnerRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    async function load() {
      setLoading(true);
      const data = await fetchAdminOwners();
      setOwners(data);
      setLoading(false);
    }
    load();
  }, []);

  const filtered = owners.filter((o) => {
    if (!searchTerm) return true;
    const q = searchTerm.toLowerCase();
    return (
      o.full_name.toLowerCase().includes(q) ||
      o.mobile_number.includes(q) ||
      o.businesses.some((b) => b.name.toLowerCase().includes(q))
    );
  });

  return (
    <AdminShell>
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">Owners Directory</h1>
            <span className="rounded-full bg-slate-200 px-2.5 py-0.5 text-xs font-bold text-slate-700">
              {owners.length} Owners
            </span>
          </div>
          <p className="text-xs text-slate-500 font-medium">
            Business accounts registered in Ghazipur creating shift opportunities.
          </p>
        </div>

        <Link
          href="/admin/businesses"
          className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 shadow-xs"
        >
          <Building2 className="h-3.5 w-3.5 text-slate-500" />
          <span>Businesses List</span>
        </Link>
      </div>

      {/* Search Bar */}
      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white p-3.5 rounded-xl border border-slate-200 shadow-xs">
        <div className="relative w-full sm:w-80">
          <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-slate-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search by owner name, phone, or business..."
            className="w-full rounded-lg border border-slate-300 pl-9 pr-3 py-1.5 text-xs focus:border-indigo-600 focus:outline-none"
          />
        </div>
      </div>

      {/* Owners Table */}
      <div className="mt-4 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xs">
        {loading ? (
          <div className="p-12 text-center text-xs text-slate-500">Loading owners directory...</div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center text-xs text-slate-500">
            No business owners match your search.
          </div>
        ) : (
          <table className="min-w-full divide-y divide-slate-200 text-left text-xs">
            <thead className="bg-slate-50 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-4 py-3">Owner Info</th>
                <th className="px-4 py-3">Linked Businesses</th>
                <th className="px-4 py-3 text-center">Businesses</th>
                <th className="px-4 py-3 text-center">Jobs Posted</th>
                <th className="px-4 py-3">Joined Date</th>
                <th className="px-4 py-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {filtered.map((o) => (
                <tr key={o.user_id} className="hover:bg-slate-50/80 transition">
                  <td className="px-4 py-3.5">
                    <div className="font-semibold text-slate-900">{o.full_name}</div>
                    <div className="font-mono text-[11px] text-slate-500">{o.mobile_number}</div>
                  </td>
                  <td className="px-4 py-3.5">
                    <div className="flex flex-col gap-1">
                      {o.businesses.length > 0 ? (
                        o.businesses.map((b) => (
                          <div key={b.id} className="flex items-center gap-1.5">
                            <Building2 className="h-3 w-3 text-slate-400 shrink-0" />
                            <span className="font-medium text-slate-800">{b.name}</span>
                            <span
                              className={`rounded px-1.5 py-0.2 text-[10px] font-semibold ${
                                b.verification_status === 'verified'
                                  ? 'bg-emerald-50 text-emerald-700'
                                  : 'bg-amber-50 text-amber-700'
                              }`}
                            >
                              {b.verification_status}
                            </span>
                          </div>
                        ))
                      ) : (
                        <span className="text-slate-400 text-[11px]">No business registered</span>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3.5 text-center font-bold text-slate-800">
                    {o.businesses_count}
                  </td>
                  <td className="px-4 py-3.5 text-center">
                    <span className="inline-flex items-center gap-1 rounded bg-slate-100 px-2 py-0.5 text-xs font-semibold text-slate-700">
                      <Briefcase className="h-3 w-3 text-slate-400" />
                      {o.total_jobs_posted}
                    </span>
                  </td>
                  <td className="px-4 py-3.5 text-slate-500">
                    {new Date(o.created_at).toLocaleDateString('en-IN', { timeZone: 'Asia/Kolkata' })}
                  </td>
                  <td className="px-4 py-3.5 text-right">
                    <Link
                      href={`/admin/owners/${o.user_id}`}
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
