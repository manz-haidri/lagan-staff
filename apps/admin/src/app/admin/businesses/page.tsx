'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Search, Building2, MapPin, Eye, ShieldCheck, Clock, XCircle, AlertTriangle } from 'lucide-react';
import {
  AdminBusinessRecord,
  fetchAdminBusinesses,
  formatCategoryName,
} from '@/lib/business-service';

export default function AdminBusinessesPage() {
  const [businesses, setBusinesses] = useState<AdminBusinessRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [selectedCategory, setSelectedCategory] = useState('all');

  useEffect(() => {
    let isMounted = true;
    fetchAdminBusinesses({
      status: selectedStatus,
      category: selectedCategory,
      search: searchTerm,
    }).then((data) => {
      if (isMounted) {
        setBusinesses(data);
        setLoading(false);
      }
    });
    return () => {
      isMounted = false;
    };
  }, [searchTerm, selectedStatus, selectedCategory]);

  return (
    <AdminShell>
      {/* Top Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-black tracking-tight text-slate-900">
            Registered Businesses (व्यावसायिक प्रतिष्ठान)
          </h1>
          <p className="text-xs text-slate-500 font-medium">
            Ghazipur banquet lawns, caterers, tent houses, and event contractors
          </p>
        </div>
        <Link
          href="/admin/business-verifications"
          className="inline-flex items-center gap-2 rounded-lg bg-indigo-900 px-3.5 py-1.5 text-xs font-semibold text-white shadow-xs hover:bg-indigo-800 transition"
        >
          <Building2 className="h-3.5 w-3.5 text-amber-300" />
          <span>Verification Queue</span>
        </Link>
      </div>

      {/* Filters & Search Bar */}
      <div className="mt-6 flex flex-col gap-3 rounded-xl border border-slate-200 bg-white p-3.5 shadow-xs sm:flex-row sm:items-center sm:justify-between">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search business name, locality, contact person..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full rounded-lg border border-slate-300 pl-9 pr-4 py-1.5 text-xs focus:border-indigo-600 focus:outline-none"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {/* Status Select */}
          <select
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
            className="rounded-lg border border-slate-300 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 focus:border-indigo-600 focus:outline-none"
          >
            <option value="all">All Statuses (सभी स्थितियाँ)</option>
            <option value="verified">Verified (सत्यापित)</option>
            <option value="pending">Pending (समीक्षा प्रतीक्षित)</option>
            <option value="under_review">Under Review (जाँच में)</option>
            <option value="rejected">Rejected (अस्वीकृत)</option>
            <option value="suspended">Suspended (निलंबित)</option>
          </select>

          {/* Category Select */}
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="rounded-lg border border-slate-300 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 focus:border-indigo-600 focus:outline-none"
          >
            <option value="all">All Categories (सभी श्रेणियाँ)</option>
            <option value="marriage_hall">Marriage Halls</option>
            <option value="catering_agency">Catering Agencies</option>
            <option value="tent_house">Tent Houses</option>
            <option value="event_organizer">Event Organizers</option>
            <option value="dj_sound">DJ & Sound</option>
            <option value="other">Other</option>
          </select>
        </div>
      </div>

      {/* Businesses Table */}
      <div className="mt-4 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xs">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200 text-left text-xs">
            <thead className="bg-slate-50 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-4 py-3">Business Profile</th>
                <th className="px-4 py-3">Category</th>
                <th className="px-4 py-3">Location & Locality</th>
                <th className="px-4 py-3">Contact</th>
                <th className="px-4 py-3">Verification</th>
                <th className="px-4 py-3 text-center">First Job Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {loading ? (
                <tr>
                  <td colSpan={7} className="px-4 py-12 text-center text-slate-400">
                    Loading businesses directory...
                  </td>
                </tr>
              ) : businesses.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-12 text-center text-slate-400">
                    No businesses match the search or filter criteria.
                  </td>
                </tr>
              ) : (
                businesses.map((biz) => {
                  let statusBadge = null;
                  switch (biz.verification_status) {
                    case 'verified':
                      statusBadge = (
                        <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-semibold text-emerald-700 border border-emerald-200">
                          <ShieldCheck className="h-3 w-3" />
                          सत्यापित (Verified)
                        </span>
                      );
                      break;
                    case 'pending':
                    case 'under_review':
                      statusBadge = (
                        <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-semibold text-amber-700 border border-amber-200">
                          <Clock className="h-3 w-3" />
                          प्रतीक्षित (Pending)
                        </span>
                      );
                      break;
                    case 'rejected':
                      statusBadge = (
                        <span className="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-semibold text-rose-700 border border-rose-200">
                          <XCircle className="h-3 w-3" />
                          अस्वीकृत (Rejected)
                        </span>
                      );
                      break;
                    case 'suspended':
                      statusBadge = (
                        <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-700 border border-slate-300">
                          <AlertTriangle className="h-3 w-3" />
                          निलंबित (Suspended)
                        </span>
                      );
                      break;
                    default:
                      statusBadge = (
                        <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-600">
                          {biz.verification_status}
                        </span>
                      );
                  }

                  return (
                    <tr key={biz.id} className="hover:bg-slate-50/80 transition">
                      <td className="px-4 py-3.5">
                        <div className="font-semibold text-slate-900">{biz.name}</div>
                        {biz.gst_or_trade_id && (
                          <div className="font-mono text-[11px] text-slate-400">
                            ID: {biz.gst_or_trade_id}
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-3.5">
                        <span className="font-medium text-slate-800">
                          {formatCategoryName(biz.business_type)}
                        </span>
                      </td>
                      <td className="px-4 py-3.5">
                        <div className="flex items-center gap-1 text-slate-700 font-medium">
                          <MapPin className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                          <span>{biz.locality}, Ghazipur</span>
                        </div>
                      </td>
                      <td className="px-4 py-3.5">
                        <div className="text-slate-900 font-medium">
                          {biz.contact_person || 'N/A'}
                        </div>
                        <div className="font-mono text-[11px] text-slate-500">
                          {biz.contact_phone}
                        </div>
                      </td>
                      <td className="px-4 py-3.5">{statusBadge}</td>
                      <td className="px-4 py-3.5 text-center">
                        {biz.is_first_job_approved ? (
                          <span className="inline-flex rounded-full bg-emerald-100 px-2 py-0.5 text-[10px] font-bold text-emerald-800">
                            Auto-Publish Enabled
                          </span>
                        ) : (
                          <span className="inline-flex rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-600">
                            Requires 1st Job Check
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3.5 text-right">
                        <Link
                          href={`/admin/businesses/${biz.id}`}
                          className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-indigo-50 hover:text-indigo-900 transition"
                        >
                          <Eye className="h-3.5 w-3.5" />
                          <span>Inspect</span>
                        </Link>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </AdminShell>
  );
}
