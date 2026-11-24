'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import {
  XCircle,
  Eye,
  CheckCircle2,
  MapPin,
  Phone,
  FileText,
  Search,
  Building2,
} from 'lucide-react';
import {
  AdminBusinessRecord,
  fetchAdminBusinesses,
  performAdminBusinessReview,
  formatCategoryName,
} from '@/lib/business-service';

export default function AdminBusinessVerificationsQueuePage() {
  const [businesses, setBusinesses] = useState<AdminBusinessRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'pending' | 'under_review' | 'verified' | 'rejected'>('pending');
  const [rejectModalBiz, setRejectModalBiz] = useState<AdminBusinessRecord | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [actionInProgress, setActionInProgress] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await fetchAdminBusinesses();
      setBusinesses(data);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let isMounted = true;
    fetchAdminBusinesses().then((data) => {
      if (isMounted) {
        setBusinesses(data);
        setLoading(false);
      }
    });
    return () => {
      isMounted = false;
    };
  }, []);

  const counts = {
    pending: businesses.filter((b) => b.verification_status === 'pending').length,
    under_review: businesses.filter((b) => b.verification_status === 'under_review').length,
    verified: businesses.filter((b) => b.verification_status === 'verified').length,
    rejected: businesses.filter((b) => b.verification_status === 'rejected').length,
  };

  const filtered = businesses.filter((b) => {
    if (b.verification_status !== activeTab) return false;
    if (!searchTerm) return true;
    const q = searchTerm.toLowerCase();
    return (
      b.name.toLowerCase().includes(q) ||
      b.locality.toLowerCase().includes(q) ||
      (b.contact_person && b.contact_person.toLowerCase().includes(q))
    );
  });

  const handleQuickApprove = async (bizId: string) => {
    setActionInProgress(bizId);
    try {
      const res = await performAdminBusinessReview({
        businessId: bizId,
        action: 'approve',
      });
      if (res.success) {
        await loadData();
      } else {
        alert(`Approve failed: ${res.error}`);
      }
    } finally {
      setActionInProgress(null);
    }
  };

  const handleRejectSubmit = async () => {
    if (!rejectModalBiz || rejectionReason.trim().length < 3) return;
    setActionInProgress(rejectModalBiz.id);
    try {
      const res = await performAdminBusinessReview({
        businessId: rejectModalBiz.id,
        action: 'reject',
        rejectionReason: rejectionReason.trim(),
      });
      if (res.success) {
        setRejectModalBiz(null);
        setRejectionReason('');
        await loadData();
      } else {
        alert(`Reject failed: ${res.error}`);
      }
    } finally {
      setActionInProgress(null);
    }
  };

  return (
    <AdminShell>
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Business Verifications Queue
            </h1>
            <span className="rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-bold text-amber-900">
              {counts.pending} Pending Review
            </span>
          </div>
          <p className="text-xs text-slate-500 font-medium">
            Audit banquet lawns, caterers, and event operators before they hire temporary staff.
          </p>
        </div>

        <Link
          href="/admin/businesses"
          className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 shadow-xs"
        >
          <Building2 className="h-3.5 w-3.5 text-slate-500" />
          <span>All Businesses Directory</span>
        </Link>
      </div>

      {/* Tabs & Search */}
      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white p-3.5 rounded-xl border border-slate-200 shadow-xs">
        <div className="inline-flex rounded-lg border border-slate-200 bg-slate-50 p-0.5 text-xs">
          <button
            onClick={() => setActiveTab('pending')}
            className={`rounded-md px-3 py-1.5 text-xs font-semibold transition ${
              activeTab === 'pending'
                ? 'bg-white text-amber-950 shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Pending ({counts.pending})
          </button>
          <button
            onClick={() => setActiveTab('under_review')}
            className={`rounded-md px-3 py-1.5 text-xs font-semibold transition ${
              activeTab === 'under_review'
                ? 'bg-white text-blue-950 shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Under Review ({counts.under_review})
          </button>
          <button
            onClick={() => setActiveTab('verified')}
            className={`rounded-md px-3 py-1.5 text-xs font-semibold transition ${
              activeTab === 'verified'
                ? 'bg-white text-emerald-950 shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Verified ({counts.verified})
          </button>
          <button
            onClick={() => setActiveTab('rejected')}
            className={`rounded-md px-3 py-1.5 text-xs font-semibold transition ${
              activeTab === 'rejected'
                ? 'bg-white text-rose-950 shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Rejected ({counts.rejected})
          </button>
        </div>

        <div className="relative w-full sm:w-72">
          <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search business name, locality..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full rounded-lg border border-slate-300 pl-9 pr-3 py-1.5 text-xs focus:border-indigo-600 focus:outline-none"
          />
        </div>
      </div>

      {/* Verification Queue List */}
      <div className="mt-4 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xs">
        {loading ? (
          <div className="p-12 text-center text-xs text-slate-500">Loading verification queue...</div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center text-xs text-slate-500">
            <CheckCircle2 className="mx-auto h-8 w-8 text-emerald-500 mb-2" />
            <p className="font-semibold text-slate-700">No applications in this tab.</p>
            <p className="text-slate-400 mt-0.5">Everything is up-to-date in this category.</p>
          </div>
        ) : (
          <div className="divide-y divide-slate-100">
            {filtered.map((biz) => (
              <div
                key={biz.id}
                className="p-5 hover:bg-slate-50/80 transition flex flex-col sm:flex-row sm:items-center justify-between gap-4"
              >
                <div className="space-y-1.5">
                  <div className="flex items-center gap-2">
                    <h3 className="text-sm font-bold text-slate-900">{biz.name}</h3>
                    <span className="rounded bg-slate-100 px-2 py-0.5 text-[10px] font-semibold text-slate-700 uppercase">
                      {formatCategoryName(biz.business_type)}
                    </span>
                  </div>

                  <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-500">
                    <span className="flex items-center gap-1">
                      <MapPin className="h-3.5 w-3.5 text-slate-400" />
                      {biz.locality}, Ghazipur
                    </span>
                    <span className="flex items-center gap-1 font-mono">
                      <Phone className="h-3.5 w-3.5 text-slate-400" />
                      +91 {biz.contact_phone} ({biz.contact_person || 'Owner'})
                    </span>
                    <span className="flex items-center gap-1">
                      <FileText className="h-3.5 w-3.5 text-slate-400" />
                      {biz.documents?.length || 0} proofs attached
                    </span>
                  </div>

                  {biz.gst_or_trade_id && (
                    <div className="text-[11px] font-mono text-slate-400">
                      Govt / Trade ID: <span className="text-slate-600">{biz.gst_or_trade_id}</span>
                    </div>
                  )}

                  {biz.rejection_reason && (
                    <div className="text-[11px] text-rose-700 bg-rose-50 p-2 rounded border border-rose-200">
                      Rejection note: {biz.rejection_reason}
                    </div>
                  )}
                </div>

                <div className="flex items-center gap-2 self-end sm:self-center">
                  <Link
                    href={`/admin/businesses/${biz.id}`}
                    className="inline-flex items-center gap-1 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 shadow-2xs"
                  >
                    <Eye className="h-3.5 w-3.5" />
                    <span>Dossier</span>
                  </Link>

                  {biz.verification_status !== 'verified' && (
                    <button
                      disabled={actionInProgress === biz.id}
                      onClick={() => handleQuickApprove(biz.id)}
                      className="inline-flex items-center gap-1 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white shadow-xs hover:bg-emerald-700 disabled:opacity-50"
                    >
                      <CheckCircle2 className="h-3.5 w-3.5" />
                      <span>Approve</span>
                    </button>
                  )}

                  {biz.verification_status !== 'rejected' && (
                    <button
                      disabled={actionInProgress === biz.id}
                      onClick={() => setRejectModalBiz(biz)}
                      className="inline-flex items-center gap-1 rounded-lg border border-rose-300 bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 hover:bg-rose-100 disabled:opacity-50"
                    >
                      <XCircle className="h-3.5 w-3.5" />
                      <span>Reject</span>
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Reject Modal */}
      {rejectModalBiz && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl border border-slate-200">
            <h3 className="text-base font-bold text-slate-900">Reject Business Verification</h3>
            <p className="text-xs text-slate-500 mt-1">
              Specify reason for rejecting <strong>{rejectModalBiz.name}</strong>.
            </p>

            <textarea
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="e.g. Invalid address proof or unconfirmed banquet venue..."
              rows={3}
              className="mt-3 w-full rounded-lg border border-slate-300 p-2.5 text-xs focus:border-rose-500 focus:outline-none"
            />

            <div className="mt-4 flex justify-end gap-2">
              <button
                onClick={() => {
                  setRejectModalBiz(null);
                  setRejectionReason('');
                }}
                className="rounded-lg border border-slate-300 px-3.5 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                disabled={actionInProgress === rejectModalBiz.id || rejectionReason.trim().length < 3}
                onClick={handleRejectSubmit}
                className="rounded-lg bg-rose-600 px-3.5 py-1.5 text-xs font-semibold text-white hover:bg-rose-700 disabled:opacity-50"
              >
                Confirm Reject
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminShell>
  );
}
