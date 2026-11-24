'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import { fetchAdminOwnerDetail, AdminOwnerRecord } from '@/lib/owner-service';
import {
  ArrowLeft,
  User,
  Calendar,
  Briefcase,
  ArrowRight,
  MapPin,
} from 'lucide-react';

export default function AdminOwnerDetailPage() {
  const params = useParams();
  const ownerId = params.id as string;

  const [owner, setOwner] = useState<AdminOwnerRecord | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      setLoading(true);
      const data = await fetchAdminOwnerDetail(ownerId);
      setOwner(data);
      setLoading(false);
    }
    load();
  }, [ownerId]);

  if (loading) {
    return (
      <AdminShell>
        <div className="p-12 text-center text-xs text-slate-500">Loading owner profile...</div>
      </AdminShell>
    );
  }

  if (!owner) {
    return (
      <AdminShell>
        <div className="rounded-xl border border-slate-200 bg-white p-8 text-center">
          <p className="text-sm font-semibold text-slate-700">Owner profile not found.</p>
          <Link
            href="/admin/owners"
            className="mt-3 inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-700"
          >
            <ArrowLeft className="h-3.5 w-3.5" /> Back to Owners Directory
          </Link>
        </div>
      </AdminShell>
    );
  }

  return (
    <AdminShell>
      <div>
        <Link
          href="/admin/owners"
          className="inline-flex items-center gap-1 text-xs font-medium text-slate-500 hover:text-slate-800"
        >
          <ArrowLeft className="h-3.5 w-3.5" /> Back to Owners Directory
        </Link>
      </div>

      {/* Profile Card */}
      <div className="mt-4 rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <div className="flex items-center gap-4">
          <div className="flex h-14 w-14 items-center justify-center rounded-full bg-slate-100 text-slate-500 border border-slate-200">
            <User className="h-7 w-7" />
          </div>
          <div>
            <h1 className="text-xl font-black text-slate-900">{owner.full_name}</h1>
            <p className="text-xs text-slate-500 font-mono mt-0.5">{owner.mobile_number}</p>
          </div>
        </div>

        <div className="mt-6 grid grid-cols-1 sm:grid-cols-3 gap-4 border-t border-slate-100 pt-5 text-xs">
          <div>
            <span className="text-slate-400 font-medium">Platform Role:</span>
            <div className="font-semibold text-slate-800 mt-0.5">Business Owner / Employer</div>
          </div>
          <div>
            <span className="text-slate-400 font-medium">Registered Date:</span>
            <div className="font-semibold text-slate-800 flex items-center gap-1 mt-0.5">
              <Calendar className="h-3.5 w-3.5 text-slate-400" />
              {new Date(owner.created_at).toLocaleDateString('en-IN', { timeZone: 'Asia/Kolkata' })}
            </div>
          </div>
          <div>
            <span className="text-slate-400 font-medium">Marketplace Activity:</span>
            <div className="font-semibold text-slate-800 flex items-center gap-1 mt-0.5">
              <Briefcase className="h-3.5 w-3.5 text-slate-400" />
              {owner.total_jobs_posted} jobs posted across {owner.businesses_count} establishment(s)
            </div>
          </div>
        </div>
      </div>

      {/* Linked Businesses */}
      <div className="mt-6">
        <h2 className="text-sm font-bold text-slate-900">Linked Business Establishments</h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Establishments registered by this owner for event shifts and temporary staffing.
        </p>

        <div className="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
          {owner.businesses && owner.businesses.length > 0 ? (
            owner.businesses.map((b) => (
              <div
                key={b.id}
                className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-center justify-between">
                    <span className="rounded bg-slate-100 px-2 py-0.5 text-[10px] font-bold text-slate-600 uppercase">
                      {b.business_type.replace('_', ' ')}
                    </span>
                    <span
                      className={`rounded-full px-2 py-0.5 text-[10px] font-semibold ${
                        b.verification_status === 'verified'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : 'bg-amber-50 text-amber-700 border border-amber-200'
                      }`}
                    >
                      {b.verification_status}
                    </span>
                  </div>
                  <h3 className="mt-3 text-base font-bold text-slate-900">{b.name}</h3>
                  <div className="mt-1 flex items-center gap-1 text-xs text-slate-500">
                    <MapPin className="h-3.5 w-3.5 text-slate-400" />
                    <span>{b.locality}, Ghazipur</span>
                  </div>
                </div>

                <div className="mt-5 pt-3 border-t border-slate-100 flex justify-end">
                  <Link
                    href={`/admin/businesses/${b.id}`}
                    className="inline-flex items-center gap-1 text-xs font-semibold text-indigo-900 hover:text-indigo-700"
                  >
                    <span>View Business Dossier</span>
                    <ArrowRight className="h-3 w-3" />
                  </Link>
                </div>
              </div>
            ))
          ) : (
            <div className="col-span-2 rounded-xl border border-slate-200 bg-white p-8 text-center text-xs text-slate-500">
              No business records found for this owner.
            </div>
          )}
        </div>
      </div>
    </AdminShell>
  );
}
